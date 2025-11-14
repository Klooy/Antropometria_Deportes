/*******************************
 Script: Antropometria Data Warehouse (T-SQL para SQL Server)
 Genera:
  - Base de datos AntropometriaDW
  - Esquemas: staging, dw
  - Dimensiones: DimDate, DimInstitution, DimCategory, DimPerson (SCD2)
  - Dimensional/metrics tables: DimAnthropometry, DimPerimeters, DimTests
  - Fact: FactMeasurements
  - Staging, logs, helper objects
  - Funciones, procedimientos MERGE, vistas para Power BI
*********************************/

-- 1) Crear Base de datos
IF DB_ID(N'AntropometriaDW') IS NULL
BEGIN
    CREATE DATABASE AntropometriaDW
    ON PRIMARY (
        NAME = N'AntropometriaDW_data',
        FILENAME = N'%PROGRAMFILES%\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AntropometriaDW.mdf' -- editar ruta si es necesario
    )
    LOG ON (
        NAME = N'AntropometriaDW_log',
        FILENAME = N'%PROGRAMFILES%\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AntropometriaDW_log.ldf'
    );
END
GO

USE AntropometriaDW;
GO

-- 2) Esquemas
IF SCHEMA_ID('staging') IS NULL EXEC('CREATE SCHEMA staging');
IF SCHEMA_ID('dw') IS NULL EXEC('CREATE SCHEMA dw');
GO

-- 3) Tabla DimDate (Calendario)
IF OBJECT_ID('dw.DimDate') IS NOT NULL DROP TABLE dw.DimDate;
CREATE TABLE dw.DimDate(
    DateKey        INT         NOT NULL PRIMARY KEY, -- YYYYMMDD
    [Date]         DATE        NOT NULL,
    YearNum        INT         NOT NULL,
    MonthNum       INT         NOT NULL,
    MonthName      NVARCHAR(20) NOT NULL,
    Day            INT         NOT NULL,
    WeekOfYear     INT         NOT NULL,
    IsWeekend      BIT         NOT NULL
);
GO

-- Poblar DimDate (ejemplo 2000-01-01 a 2030-12-31)
DECLARE @d DATE = '2000-01-01';
WHILE @d <= '2030-12-31'
BEGIN
    INSERT INTO dw.DimDate(DateKey, [Date], YearNum, MonthNum, MonthName, Day, WeekOfYear, IsWeekend)
    VALUES (
        CONVERT(INT, FORMAT(@d,'yyyyMMdd')),
        @d,
        YEAR(@d),
        MONTH(@d),
        DATENAME(MONTH,@d),
        DAY(@d),
        DATEPART(ISO_WEEK,@d),
        CASE WHEN DATEPART(WEEKDAY,@d) IN (1,7) THEN 1 ELSE 0 END
    );
    SET @d = DATEADD(DAY,1,@d);
END
GO

-- 4) DimInstitution
IF OBJECT_ID('dw.DimInstitution') IS NOT NULL DROP TABLE dw.DimInstitution;
CREATE TABLE dw.DimInstitution(
    InstitutionKey INT IDENTITY(1,1) PRIMARY KEY,
    InstitutionCode NVARCHAR(50) UNIQUE,
    InstitutionName NVARCHAR(200),
    City NVARCHAR(100),
    Region NVARCHAR(100),
    Country NVARCHAR(100)
);
GO

-- 5) DimCategoryRanges (configurable)
IF OBJECT_ID('dw.CategoryRanges') IS NOT NULL DROP TABLE dw.CategoryRanges;
CREATE TABLE dw.CategoryRanges(
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    CategoryName NVARCHAR(50) NOT NULL,
    AgeFrom INT NOT NULL, -- inclusive
    AgeTo INT NOT NULL,   -- inclusive
    SortOrder INT NOT NULL DEFAULT 1
);
-- Valores por defecto (ejemplo). Modifica según tus reglas.
INSERT INTO dw.CategoryRanges (CategoryName, AgeFrom, AgeTo, SortOrder)
VALUES
('U-10',0,10,1),
('U-12',11,12,2),
('U-14',13,14,3),
('U-16',15,16,4),
('U-18',17,18,5),
('Senior',19,120,6);
GO

-- 6) DimPerson (SCD Type 2 simple)
IF OBJECT_ID('dw.DimPerson') IS NOT NULL DROP TABLE dw.DimPerson;
CREATE TABLE dw.DimPerson(
    PersonKey INT IDENTITY(1,1) PRIMARY KEY,
    NaturalPersonID NVARCHAR(100), -- ID proporcionado por la institución/entrenador (documento)
    FirstName NVARCHAR(150),
    LastName NVARCHAR(150),
    Sex CHAR(1) CHECK (Sex IN ('M','F')), -- 'M' masculino, 'F' femenino
    BirthDate DATE,
    CurrentAge AS DATEDIFF(YEAR, BirthDate, GETDATE()) PERSISTED,
    CategoryID INT NULL, -- FK a dw.CategoryRanges
    InstitutionKey INT NULL, -- FK a dw.DimInstitution
    EffectiveFrom DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    EffectiveTo DATETIME2 NULL,
    IsCurrent BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_DimPerson_Category FOREIGN KEY (CategoryID) REFERENCES dw.CategoryRanges(CategoryID),
    CONSTRAINT FK_DimPerson_Institution FOREIGN KEY (InstitutionKey) REFERENCES dw.DimInstitution(InstitutionKey)
);
CREATE INDEX IX_DimPerson_NaturalID ON dw.DimPerson(NaturalPersonID);
GO

-- 7) DimAnthropometry (medidas y calculos)
IF OBJECT_ID('dw.DimAnthropometry') IS NOT NULL DROP TABLE dw.DimAnthropometry;
CREATE TABLE dw.DimAnthropometry(
    AnthroKey INT IDENTITY(1,1) PRIMARY KEY,
    WeightKg DECIMAL(6,2) NULL,
    HeightCm DECIMAL(6,2) NULL,
    HeightM AS (CASE WHEN HeightCm IS NOT NULL THEN HeightCm/100.0 ELSE NULL END) PERSISTED,
    BMI AS (CASE WHEN HeightM IS NULL OR HeightM = 0 THEN NULL ELSE ROUND(WeightKg / (HeightM * HeightM),2) END) PERSISTED, -- IMC
    PlTriceps_mm DECIMAL(6,2) NULL,
    PlSubEsc_mm DECIMAL(6,2) NULL,
    PlCrestaIliaca_mm DECIMAL(6,2) NULL,
    PlSupraespinal_mm DECIMAL(6,2) NULL,
    PlAbdominal_mm DECIMAL(6,2) NULL,
    PlPant_mm DECIMAL(6,2) NULL,
    SumaPliegues AS (ROUND(
        ISNULL(PlTriceps_mm,0) + ISNULL(PlSubEsc_mm,0) + ISNULL(PlCrestaIliaca_mm,0) + ISNULL(PlSupraespinal_mm,0) + ISNULL(PlAbdominal_mm,0) + ISNULL(PlPant_mm,0)
    ,2)) PERSISTED,
    AgeAtMeasurement INT NULL, -- se llenará desde staging/fact
    SexFlag AS (CASE WHEN  SexForCalc IS NULL THEN NULL WHEN SexForCalc='M' THEN 1 ELSE 0 END) PERSISTED, -- 1 male, 0 female
    SexForCalc CHAR(1) NULL, -- duplicar sexo aquí para cálculos independientes si es necesario
    PercentFat_Deurenberg AS (CASE 
        WHEN BMI IS NULL OR AgeAtMeasurement IS NULL OR SexFlag IS NULL THEN NULL
        ELSE ROUND((1.2 * BMI) + (0.23 * AgeAtMeasurement) - (10.8 * SexFlag) - 5.4,2)
    END) PERSISTED,
    WaistCm DECIMAL(6,2) NULL,
    HipCm DECIMAL(6,2) NULL,
    WaistHipRatio AS (CASE WHEN WaistCm IS NULL OR HipCm IS NULL OR HipCm = 0 THEN NULL ELSE ROUND(WaistCm / HipCm,4) END) PERSISTED,
    ConicityIndex AS (CASE 
        WHEN WaistCm IS NULL OR WeightKg IS NULL OR HeightM IS NULL OR HeightM = 0 THEN NULL
        ELSE ROUND(WaistCm / (0.109 * SQRT(WeightKg / HeightM)),4)
    END) PERSISTED
);
CREATE INDEX IX_DimAnthropometry_BMI ON dw.DimAnthropometry(BMI);
GO

-- 8) DimPerimeters (opcional: si quieres separar, si no, puedes usar DimAnthropometry)
IF OBJECT_ID('dw.DimPerimeters') IS NOT NULL DROP TABLE dw.DimPerimeters;
CREATE TABLE dw.DimPerimeters(
    PerimKey INT IDENTITY(1,1) PRIMARY KEY,
    ArmRelaxCm DECIMAL(6,2) NULL,
    ArmFlexCm DECIMAL(6,2) NULL,
    ChestCm DECIMAL(6,2) NULL,
    ThighCm DECIMAL(6,2) NULL,
    CalfCm DECIMAL(6,2) NULL
);
GO

-- 9) DimTests (resultados y clasificaciones)
IF OBJECT_ID('dw.DimTests') IS NOT NULL DROP TABLE dw.DimTests;
CREATE TABLE dw.DimTests(
    TestKey INT IDENTITY(1,1) PRIMARY KEY,
    TestAbd_Count INT NULL,
    ClassAbd NVARCHAR(50) NULL,
    Pushup_Count INT NULL,
    ClassPushup NVARCHAR(50) NULL,
    Jump_cm DECIMAL(6,2) NULL,
    ClassJump NVARCHAR(50) NULL,
    Cooper_m INT NULL,
    ClassCooper NVARCHAR(50) NULL
);
GO

-- 10) Tabla de Hechos: FactMeasurements
IF OBJECT_ID('dw.FactMeasurements') IS NOT NULL DROP TABLE dw.FactMeasurements;
CREATE TABLE dw.FactMeasurements(
    FactID BIGINT IDENTITY(1,1) PRIMARY KEY,
    PersonKey INT NOT NULL,
    DateKey INT NOT NULL, -- FK a DimDate.DateKey
    InstitutionKey INT NULL,
    AnthroKey INT NULL,
    PerimKey INT NULL,
    TestKey INT NULL,
    RawSourceFile NVARCHAR(260) NULL,
    EntryBy NVARCHAR(150) NULL,
    EntryDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Notes NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Fact_Person FOREIGN KEY (PersonKey) REFERENCES dw.DimPerson(PersonKey),
    CONSTRAINT FK_Fact_Date FOREIGN KEY (DateKey) REFERENCES dw.DimDate(DateKey),
    CONSTRAINT FK_Fact_Institution FOREIGN KEY (InstitutionKey) REFERENCES dw.DimInstitution(InstitutionKey),
    CONSTRAINT FK_Fact_Anthro FOREIGN KEY (AnthroKey) REFERENCES dw.DimAnthropometry(AnthroKey),
    CONSTRAINT FK_Fact_Perim FOREIGN KEY (PerimKey) REFERENCES dw.DimPerimeters(PerimKey),
    CONSTRAINT FK_Fact_Test FOREIGN KEY (TestKey) REFERENCES dw.DimTests(TestKey)
);
GO

-- 11) Staging table (igual al Excel esperado). 
-- Incluye columna NaturalPersonID para identificar a la persona (documento o id interno).
IF OBJECT_ID('staging.StgMeasurements') IS NOT NULL DROP TABLE staging.StgMeasurements;
CREATE TABLE staging.StgMeasurements(
    StgID BIGINT IDENTITY(1,1) PRIMARY KEY,
    LoadDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    RawSourceFile NVARCHAR(260),
    NaturalPersonID NVARCHAR(100), -- id externo/documento
    FirstName NVARCHAR(150),
    LastName NVARCHAR(150),
    Sex CHAR(1), -- 'M' or 'F'
    BirthDate DATE,
    MeasurementDate DATE,
    WeightKg DECIMAL(6,2),
    HeightCm DECIMAL(6,2),
    PlTriceps_mm DECIMAL(6,2),
    PlSubEsc_mm DECIMAL(6,2),
    PlCrestaIliaca_mm DECIMAL(6,2),
    PlSupraespinal_mm DECIMAL(6,2),
    PlAbdominal_mm DECIMAL(6,2),
    PlPant_mm DECIMAL(6,2),
    ArmRelaxCm DECIMAL(6,2),
    ArmFlexCm DECIMAL(6,2),
    ChestCm DECIMAL(6,2),
    WaistCm DECIMAL(6,2),
    HipCm DECIMAL(6,2),
    ThighCm DECIMAL(6,2),
    CalfCm DECIMAL(6,2),
    TestAbd_Count INT,
    ClassAbd NVARCHAR(50),
    Pushup_Count INT,
    ClassPushup NVARCHAR(50),
    Jump_cm DECIMAL(6,2),
    ClassJump NVARCHAR(50),
    Cooper_m INT,
    ClassCooper NVARCHAR(50),
    InstitutionCode NVARCHAR(50),
    EntryBy NVARCHAR(150),
    Notes NVARCHAR(MAX)
);
GO

-- 12) Logs table
IF OBJECT_ID('dw.LoadLogs') IS NOT NULL DROP TABLE dw.LoadLogs;
CREATE TABLE dw.LoadLogs(
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    LoadDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    SourceFile NVARCHAR(260),
    RowsProcessed INT,
    RowsInserted INT,
    RowsRejected INT,
    ErrorMessage NVARCHAR(MAX)
);
GO

-- 13) Función para obtener categoría según edad (usa dw.CategoryRanges)
IF OBJECT_ID('dw.fn_GetCategoryByAge') IS NOT NULL DROP FUNCTION dw.fn_GetCategoryByAge;
GO
CREATE FUNCTION dw.fn_GetCategoryByAge(@age INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @category NVARCHAR(50);
    SELECT TOP 1 @category = CategoryName
    FROM dw.CategoryRanges
    WHERE @age BETWEEN AgeFrom AND AgeTo
    ORDER BY SortOrder;
    RETURN @category;
END
GO

-- 14) Procedimiento almacenado para merge desde staging al DW
-- Nota: Este procedimiento asume que los datos ya fueron cargados a staging.StgMeasurements (por ejemplo, vía SSIS).
IF OBJECT_ID('dw.usp_MergeStagingToDW') IS NOT NULL DROP PROCEDURE dw.usp_MergeStagingToDW;
GO
CREATE PROCEDURE dw.usp_MergeStagingToDW
    @SourceFile NVARCHAR(260) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 14.1 Insertar nuevas instituciones desde staging
        INSERT INTO dw.DimInstitution (InstitutionCode, InstitutionName)
        SELECT DISTINCT s.InstitutionCode, s.InstitutionCode
        FROM staging.StgMeasurements s
        LEFT JOIN dw.DimInstitution i ON i.InstitutionCode = s.InstitutionCode
        WHERE s.InstitutionCode IS NOT NULL
          AND i.InstitutionKey IS NULL;

        -- 14.2 Insertar / actualizar DimPerson (SCD Type 2 simple)
        -- Para cada NaturalPersonID en staging, si no existe, insert new current row.
        -- Si existe y hay cambio en nombre/sex/birthdate/institution, expire la anterior y cree nueva fila.
        DECLARE @PersonCursor CURSOR;
        DECLARE @natID NVARCHAR(100), @fn NVARCHAR(150), @ln NVARCHAR(150), @sex CHAR(1), @bdate DATE, @instCode NVARCHAR(50);
        SET @PersonCursor = CURSOR FOR
            SELECT DISTINCT NaturalPersonID, FirstName, LastName, Sex, BirthDate, InstitutionCode
            FROM staging.StgMeasurements
            WHERE NaturalPersonID IS NOT NULL;
        OPEN @PersonCursor;
        FETCH NEXT FROM @PersonCursor INTO @natID, @fn, @ln, @sex, @bdate, @instCode;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- resolve institution key
            DECLARE @instKey INT = NULL;
            SELECT @instKey = InstitutionKey FROM dw.DimInstitution WHERE InstitutionCode = @instCode;

            IF NOT EXISTS (SELECT 1 FROM dw.DimPerson WHERE NaturalPersonID = @natID AND IsCurrent = 1)
            BEGIN
                INSERT INTO dw.DimPerson (NaturalPersonID, FirstName, LastName, Sex, BirthDate, CategoryID, InstitutionKey, EffectiveFrom, IsCurrent)
                VALUES (
                    @natID, @fn, @ln, @sex, @bdate,
                    (SELECT TOP 1 CategoryID FROM dw.CategoryRanges WHERE DATEDIFF(YEAR,@bdate,GETDATE()) BETWEEN AgeFrom AND AgeTo),
                    @instKey, SYSUTCDATETIME(), 1
                );
            END
            ELSE
            BEGIN
                -- compare values with current row
                DECLARE @curFirst NVARCHAR(150), @curLast NVARCHAR(150), @curSex CHAR(1), @curBirth DATE, @curInst INT;
                SELECT TOP 1 @curFirst = FirstName, @curLast = LastName, @curSex = Sex, @curBirth = BirthDate, @curInst = InstitutionKey
                FROM dw.DimPerson WHERE NaturalPersonID = @natID AND IsCurrent = 1;

                IF ISNULL(@curFirst,'') <> ISNULL(@fn,'') OR ISNULL(@curLast,'') <> ISNULL(@ln,'') OR ISNULL(@curSex,'') <> ISNULL(@sex) OR ISNULL(@curBirth, '1900-01-01') <> ISNULL(@bdate,'1900-01-01') OR ISNULL(@curInst,-1) <> ISNULL(@instKey,-1)
                BEGIN
                    -- expire old
                    UPDATE dw.DimPerson
                    SET EffectiveTo = SYSUTCDATETIME(), IsCurrent = 0
                    WHERE NaturalPersonID = @natID AND IsCurrent = 1;

                    -- insert new
                    INSERT INTO dw.DimPerson (NaturalPersonID, FirstName, LastName, Sex, BirthDate, CategoryID, InstitutionKey, EffectiveFrom, IsCurrent)
                    VALUES (
                        @natID, @fn, @ln, @sex, @bdate,
                        (SELECT TOP 1 CategoryID FROM dw.CategoryRanges WHERE DATEDIFF(YEAR,@bdate,GETDATE()) BETWEEN AgeFrom AND AgeTo),
                        @instKey, SYSUTCDATETIME(), 1
                    );
                END
            END

            FETCH NEXT FROM @PersonCursor INTO @natID, @fn, @ln, @sex, @bdate, @instCode;
        END
        CLOSE @PersonCursor;
        DEALLOCATE @PersonCursor;

        -- 14.3 Insert para DimAnthropometry, DimPerimeters, DimTests y FactMeasurements
        DECLARE @rowsProcessed INT = 0, @rowsInserted INT = 0, @rowsRejected INT = 0;
        INSERT INTO dw.LoadLogs (SourceFile, RowsProcessed, RowsInserted, RowsRejected, ErrorMessage)
        VALUES (@SourceFile, 0, 0, 0, NULL); -- log base, se actualizará después
        DECLARE @logId BIGINT = SCOPE_IDENTITY();

        DECLARE stg_cursor CURSOR FOR
            SELECT StgID, NaturalPersonID, FirstName, LastName, Sex, BirthDate, MeasurementDate,
                   WeightKg, HeightCm,
                   PlTriceps_mm, PlSubEsc_mm, PlCrestaIliaca_mm, PlSupraespinal_mm, PlAbdominal_mm, PlPant_mm,
                   ArmRelaxCm, ArmFlexCm, ChestCm, WaistCm, HipCm, ThighCm, CalfCm,
                   TestAbd_Count, ClassAbd, Pushup_Count, ClassPushup, Jump_cm, ClassJump, Cooper_m, ClassCooper,
                   InstitutionCode, EntryBy, Notes, RawSourceFile = @SourceFile
            FROM staging.StgMeasurements
            WHERE (@SourceFile IS NULL OR RawSourceFile = @SourceFile);

        OPEN stg_cursor;
        DECLARE @StgID BIGINT;
        DECLARE @MeasurementDate DATE;
        DECLARE @Weight DECIMAL(6,2), @Height DECIMAL(6,2);
        DECLARE @pl1 DECIMAL(6,2), @pl2 DECIMAL(6,2), @pl3 DECIMAL(6,2), @pl4 DECIMAL(6,2), @pl5 DECIMAL(6,2), @pl6 DECIMAL(6,2);
        DECLARE @ArmRelax DECIMAL(6,2), @ArmFlex DECIMAL(6,2), @Chest DECIMAL(6,2), @Waist DECIMAL(6,2), @Hip DECIMAL(6,2), @Thigh DECIMAL(6,2), @Calf DECIMAL(6,2);
        DECLARE @TestAbd INT, @ClassAbd NVARCHAR(50), @Pushup INT, @ClassPush NVARCHAR(50), @Jump DECIMAL(6,2), @ClassJump NVARCHAR(50), @Cooper INT, @ClassCooper NVARCHAR(50);
        DECLARE @nat NVARCHAR(100), @fn NVARCHAR(150), @ln NVARCHAR(150), @sex CHAR(1), @bdate DATE, @instCode NVARCHAR(50), @entryBy NVARCHAR(150), @notes NVARCHAR(MAX), @rawFile NVARCHAR(260);

        FETCH NEXT FROM stg_cursor INTO @StgID, @nat, @fn, @ln, @sex, @bdate, @MeasurementDate,
                                     @Weight, @Height,
                                     @pl1, @pl2, @pl3, @pl4, @pl5, @pl6,
                                     @ArmRelax, @ArmFlex, @Chest, @Waist, @Hip, @Thigh, @Calf,
                                     @TestAbd, @ClassAbd, @Pushup, @ClassPush, @Jump, @ClassJump, @Cooper, @ClassCooper,
                                     @instCode, @entryBy, @notes, @rawFile;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @rowsProcessed = @rowsProcessed + 1;

            BEGIN TRY
                -- validations (example)
                IF @MeasurementDate IS NULL
                BEGIN
                   THROW 51000, 'MeasurementDate is NULL', 1;
                END

                IF @Weight IS NOT NULL AND (@Weight < 10 OR @Weight > 300)
                BEGIN
                    THROW 51001, 'Weight out of range', 1;
                END

                IF @Height IS NOT NULL AND (@Height < 50 OR @Height > 250)
                BEGIN
                    THROW 51002, 'Height out of range', 1;
                END

                -- find current PersonKey
                DECLARE @PersonKey INT = NULL;
                SELECT TOP 1 @PersonKey = PersonKey FROM dw.DimPerson WHERE NaturalPersonID = @nat AND IsCurrent = 1;

                -- if still null, try to insert minimal person
                IF @PersonKey IS NULL
                BEGIN
                    INSERT INTO dw.DimPerson (NaturalPersonID, FirstName, LastName, Sex, BirthDate, CategoryID, EffectiveFrom, IsCurrent)
                    VALUES (@nat, @fn, @ln, @sex, @bdate, (SELECT TOP 1 CategoryID FROM dw.CategoryRanges WHERE DATEDIFF(YEAR,@bdate,GETDATE()) BETWEEN AgeFrom AND AgeTo), SYSUTCDATETIME(), 1);
                    SET @PersonKey = SCOPE_IDENTITY();
                END

                -- date key
                DECLARE @DateKey INT = CONVERT(INT, FORMAT(@MeasurementDate,'yyyyMMdd'));
                IF NOT EXISTS (SELECT 1 FROM dw.DimDate WHERE DateKey = @DateKey)
                BEGIN
                    -- optional: insert date into dimdate
                    INSERT INTO dw.DimDate(DateKey,[Date],YearNum,MonthNum,MonthName,Day,WeekOfYear,IsWeekend)
                    VALUES (@DateKey, @MeasurementDate, YEAR(@MeasurementDate), MONTH(@MeasurementDate), DATENAME(MONTH,@MeasurementDate), DAY(@MeasurementDate), DATEPART(ISO_WEEK,@MeasurementDate), CASE WHEN DATEPART(WEEKDAY,@MeasurementDate) IN (1,7) THEN 1 ELSE 0 END);
                END

                -- insert into DimAnthropometry and get AnthroKey
                INSERT INTO dw.DimAnthropometry (WeightKg, HeightCm, PlTriceps_mm, PlSubEsc_mm, PlCrestaIliaca_mm, PlSupraespinal_mm, PlAbdominal_mm, PlPant_mm, AgeAtMeasurement, SexForCalc, WaistCm, HipCm)
                VALUES (@Weight, @Height, @pl1, @pl2, @pl3, @pl4, @pl5, @pl6, DATEDIFF(YEAR,@bdate,@MeasurementDate), @sex, @Waist, @Hip);

                DECLARE @AnthroKey INT = SCOPE_IDENTITY();

                -- insert perimeters
                INSERT INTO dw.DimPerimeters (ArmRelaxCm, ArmFlexCm, ChestCm, ThighCm, CalfCm)
                VALUES (@ArmRelax, @ArmFlex, @Chest, @Thigh, @Calf);
                DECLARE @PerimKey INT = SCOPE_IDENTITY();

                -- insert tests
                INSERT INTO dw.DimTests (TestAbd_Count, ClassAbd, Pushup_Count, ClassPushup, Jump_cm, ClassJump, Cooper_m, ClassCooper)
                VALUES (@TestAbd, @ClassAbd, @Pushup, @ClassPush, @Jump, @ClassJump, @Cooper, @ClassCooper);
                DECLARE @TestKey INT = SCOPE_IDENTITY();

                -- resolve InstitutionKey
                DECLARE @InstitutionKey INT = NULL;
                SELECT @InstitutionKey = InstitutionKey FROM dw.DimInstitution WHERE InstitutionCode = @instCode;

                -- final insert into FactMeasurements
                INSERT INTO dw.FactMeasurements (PersonKey, DateKey, InstitutionKey, AnthroKey, PerimKey, TestKey, RawSourceFile, EntryBy, EntryDate, Notes)
                VALUES (@PersonKey, @DateKey, @InstitutionKey, @AnthroKey, @PerimKey, @TestKey, @rawFile, @entryBy, SYSUTCDATETIME(), @notes);

                SET @rowsInserted = @rowsInserted + 1;
            END TRY
            BEGIN CATCH
                SET @rowsRejected = @rowsRejected + 1;
                DECLARE @err NVARCHAR(MAX) = ERROR_MESSAGE();
                -- Agregar en log de errores por row (aquí solo actualizamos conteo; podrías insertar detalles por fila en tabla aparte)
                PRINT 'Error procesando StgID=' + CONVERT(NVARCHAR(50),@StgID) + ' : ' + @err;
            END CATCH

            FETCH NEXT FROM stg_cursor INTO @StgID, @nat, @fn, @ln, @sex, @bdate, @MeasurementDate,
                                         @Weight, @Height,
                                         @pl1, @pl2, @pl3, @pl4, @pl5, @pl6,
                                         @ArmRelax, @ArmFlex, @Chest, @Waist, @Hip, @Thigh, @Calf,
                                         @TestAbd, @ClassAbd, @Pushup, @ClassPush, @Jump, @ClassJump, @Cooper, @ClassCooper,
                                         @instCode, @entryBy, @notes, @rawFile;
        END

        CLOSE stg_cursor;
        DEALLOCATE stg_cursor;

        -- Actualizar log
        UPDATE dw.LoadLogs
        SET RowsProcessed = @rowsProcessed, RowsInserted = @rowsInserted, RowsRejected = @rowsRejected
        WHERE LogID = @logId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(MAX) = ERROR_MESSAGE();
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        INSERT INTO dw.LoadLogs (SourceFile, RowsProcessed, RowsInserted, RowsRejected, ErrorMessage)
        VALUES (@SourceFile, NULL, NULL, NULL, @ErrMsg);
        THROW;
    END CATCH
END
GO

-- 15) Vistas para Power BI
IF OBJECT_ID('dw.vw_FactMeasurementsDetail') IS NOT NULL DROP VIEW dw.vw_FactMeasurementsDetail;
GO
CREATE VIEW dw.vw_FactMeasurementsDetail
AS
SELECT
    f.FactID,
    f.EntryDate,
    f.RawSourceFile,
    p.NaturalPersonID,
    p.FirstName,
    p.LastName,
    p.Sex,
    p.BirthDate,
    d.[Date] AS MeasurementDate,
    di.InstitutionName,
    cr.CategoryName,
    a.WeightKg,
    a.HeightCm,
    a.BMI AS IMC,
    a.SumaPliegues,
    a.PercentFat_Deurenberg AS PercentFat,
    a.WaistCm,
    a.HipCm,
    a.WaistHipRatio AS WaistHipRatio,
    a.ConicityIndex AS ConicityIndex,
    per.ArmRelaxCm,
    per.ArmFlexCm,
    per.ChestCm,
    per.ThighCm,
    per.CalfCm,
    t.TestAbd_Count,
    t.ClassAbd,
    t.Pushup_Count,
    t.ClassPushup,
    t.Jump_cm,
    t.ClassJump,
    t.Cooper_m,
    t.ClassCooper,
    f.Notes
FROM dw.FactMeasurements f
LEFT JOIN dw.DimPerson p ON f.PersonKey = p.PersonKey
LEFT JOIN dw.DimDate d ON f.DateKey = d.DateKey
LEFT JOIN dw.DimInstitution di ON f.InstitutionKey = di.InstitutionKey
LEFT JOIN dw.DimAnthropometry a ON f.AnthroKey = a.AnthroKey
LEFT JOIN dw.DimPerimeters per ON f.PerimKey = per.PerimKey
LEFT JOIN dw.DimTests t ON f.TestKey = t.TestKey
LEFT JOIN dw.CategoryRanges cr ON p.CategoryID = cr.CategoryID;
GO

-- 16) Índices recomendados (dependiendo de consultas Power BI)
CREATE INDEX IX_FactMeasurements_PersonDate ON dw.FactMeasurements(PersonKey, DateKey);
CREATE INDEX IX_FactMeasurements_Date ON dw.FactMeasurements(DateKey);
CREATE INDEX IX_FactMeasurements_Institution ON dw.FactMeasurements(InstitutionKey);
GO

-- 17) Ejemplo: cómo insertar en staging (simulación)
-- INSERT INTO staging.StgMeasurements (RawSourceFile, NaturalPersonID, FirstName, LastName, Sex, BirthDate, MeasurementDate, WeightKg, HeightCm, PlTriceps_mm, ...)
-- VALUES ('archivo1.xlsx','ABC123','Juan','Perez','M','2008-05-02','2025-10-01',52.3,165,12.5,8.1,10.2,9.0,14.3,7.2, ... );
-- Luego ejecutar:
-- EXEC dw.usp_MergeStagingToDW @SourceFile = 'archivo1.xlsx';

/* FIN DEL SCRIPT */
