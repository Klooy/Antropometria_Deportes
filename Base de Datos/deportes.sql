-- =============================================
-- MIGRACI�N COMPLETA: Base de Datos Deportes
-- De tabla plana a estructura normalizada
-- =============================================

USE [deportes]
GO

-- =============================================
-- PASO 1: ELIMINAR TABLAS SI EXISTEN
-- =============================================
IF OBJECT_ID('dbo.DimClasificacion', 'U') IS NOT NULL DROP TABLE dbo.DimClasificacion;
IF OBJECT_ID('dbo.DimPrueba', 'U') IS NOT NULL DROP TABLE dbo.DimPrueba;
IF OBJECT_ID('dbo.Dimabdomen', 'U') IS NOT NULL DROP TABLE dbo.Dimabdomen;
IF OBJECT_ID('dbo.Dimtorax', 'U') IS NOT NULL DROP TABLE dbo.Dimtorax;
IF OBJECT_ID('dbo.Dimpierna', 'U') IS NOT NULL DROP TABLE dbo.Dimpierna;
IF OBJECT_ID('dbo.Dimcadera', 'U') IS NOT NULL DROP TABLE dbo.Dimcadera;
IF OBJECT_ID('dbo.Dimcintura', 'U') IS NOT NULL DROP TABLE dbo.Dimcintura;
IF OBJECT_ID('dbo.Dimomoplato', 'U') IS NOT NULL DROP TABLE dbo.Dimomoplato;
IF OBJECT_ID('dbo.DimBrazo', 'U') IS NOT NULL DROP TABLE dbo.DimBrazo;
IF OBJECT_ID('dbo.DimEscuela', 'U') IS NOT NULL DROP TABLE dbo.DimEscuela;
IF OBJECT_ID('dbo.HechosPersona', 'U') IS NOT NULL DROP TABLE dbo.HechosPersona;
GO

-- =============================================
-- PASO 2: CREAR TABLAS NORMALIZADAS
-- =============================================

-- Tabla: Persona
CREATE TABLE [dbo].[HechosPersona](
    [ID] [int] NOT NULL PRIMARY KEY,
    [Nombre] [nvarchar](100) NULL,
    [Apellido] [nvarchar](100) NULL,
    [Sexo] [char](1) NULL,
    [Edad] [int] NULL,
    [Peso] [float] NULL,
    [Altura] [float] NULL
);

-- Tabla: Escuela
CREATE TABLE [dbo].[DimEscuela](
    [ID] [int] NOT NULL PRIMARY KEY,
    [Institucion] [nvarchar](100) NULL,
    [Division] [nvarchar](50) NULL,
    [Nombre_Entrenador] [nvarchar](100) NULL,
    [Fecha_Registro] [date] NULL,
    CONSTRAINT [FK_DimEscuela_HechosPersona] FOREIGN KEY([ID]) REFERENCES [dbo].[HechosPersona]([ID])
);

-- Tabla: Brazo
CREATE TABLE [dbo].[DimBrazo](
    [ID] [int] NOT NULL PRIMARY KEY,
    [PlTr] [float] NULL,
    [PerBrazoRel] [float] NULL,
    [PerBrazoCon] [float] NULL,
    CONSTRAINT [FK_DimBrazo_HechosPersona] FOREIGN KEY([ID]) REFERENCES [dbo].[HechosPersona]([ID])
);

-- Tabla: omoplato
CREATE TABLE [dbo].[Dimomoplato](
    [ID] [int] NOT NULL PRIMARY KEY,
    [PlSubEsc] [float] NULL,
    CONSTRAINT [FK_Dimomoplato_HechosPersona] FOREIGN KEY([ID]) REFERENCES [dbo].[HechosPersona]([ID])
);

-- Tabla: cintura
CREATE TABLE [dbo].[Dimcintura](
    [ID] [int] NOT NULL PRIMARY KEY,
    [PICI] [float] NULL,
    [PlSup] [float] NULL,
    [PerCin] [float] NULL,
    CONSTRAINT [FK_Dimcintura_HechosPersona] FOREIGN KEY([ID]) REFERENCES [dbo].[HechosPersona]([ID])
);

-- Tabla: cadera
CREATE TABLE [dbo].[Dimcadera](
    [ID] [int] NOT NULL PRIMARY KEY,
    [PerCad] [float] NULL,
    CONSTRAINT [FK_Dimcadera_HechosPersona] FOREIGN KEY([ID]) REFERENCES [dbo].[HechosPersona]([ID])
);

-- Tabla: pierna
CREATE TABLE [dbo].[Dimpierna](
    [ID] [int] NOT NULL PRIMARY KEY,
    [PIMM] [float] NULL,
    [PlPant] [float] NULL,
    [PerMuslo] [float] NULL,
    [Perpier] [float] NULL,
    CONSTRAINT [FK_Dimpierna_HechosPersona] FOREIGN KEY([ID]) REFERENCES [dbo].[HechosPersona]([ID])
);

-- Tabla: torax
CREATE TABLE [dbo].[Dimtorax](
    [ID] [int] NOT NULL PRIMARY KEY,
    [PerT] [float] NULL,
    CONSTRAINT [FK_Dimtorax_HechosPersona] FOREIGN KEY([ID]) REFERENCES [dbo].[HechosPersona]([ID])
);

-- Tabla: abdomen
CREATE TABLE [dbo].[Dimabdomen](
    [ID] [int] NOT NULL PRIMARY KEY,
    [PlAbd] [float] NULL,
    CONSTRAINT [FK_Dimabdomen_HechosPersona] FOREIGN KEY([ID]) REFERENCES [dbo].[HechosPersona]([ID])
);

-- Tabla: Prueba
CREATE TABLE [dbo].[DimPrueba](
    [ID] [int] NOT NULL PRIMARY KEY,
    [Test_Abd] [float] NULL,
    [Test_FlexCLS] [float] NULL,
    [Test_Salto] [float] NULL,
    [Test_Cooper] [float] NULL,
    CONSTRAINT [FK_DimPrueba_HechosPersona] FOREIGN KEY([ID]) REFERENCES [dbo].[HechosPersona]([ID])
);

-- Tabla: Clasificacion
CREATE TABLE [dbo].[DimClasificacion](
    [ID] [int] NOT NULL PRIMARY KEY,
    [ClsAbd] [nvarchar](50) NULL,
    [ClsFlex] [nvarchar](50) NULL,
    [Clasi_salto] [nvarchar](50) NULL,
    [Cls_Coop] [nvarchar](50) NULL,
    CONSTRAINT [FK_DimClasificacion_HechosPersona] FOREIGN KEY([ID]) REFERENCES [dbo].[HechosPersona]([ID])
);

GO

-- =============================================
-- PASO 3: INSERTAR DATOS - PERSONA
-- =============================================

INSERT INTO [dbo].[HechosPersona] (ID, Nombre, Apellido, Sexo, Edad, Peso, Altura)
SELECT 
    ID,
    Nombre,
    Apellido,  -- Nota: tiene triple 'l' en la tabla original
    CASE 
        WHEN Sexo = N'Masculino' THEN 'M'
        WHEN Sexo = N'Femenino' THEN 'F'
        ELSE NULL
    END,
    Edad,
    Peso,
    CASE 
        WHEN Altura > 10 THEN Altura / 100.0  -- Convertir cm a metros
        ELSE Altura
    END
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 4: INSERTAR DATOS - ESCUELA
-- =============================================

INSERT INTO [dbo].[DimEscuela] (ID, Institucion, Division, Nombre_Entrenador, Fecha_Registro)
SELECT 
    ID,
    Insititucion,  -- Nota: falta 't' en la tabla original
    Division,
    NULL,  -- No hay datos de entrenador
    NULL   -- No hay datos de fecha
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 5: INSERTAR DATOS - BRAZO
-- =============================================

INSERT INTO [dbo].[DimBrazo] (ID, PlTr, PerBrazoRel, PerBrazoCon)
SELECT 
    ID,
    PlTr,
    PerBrazoRel,
    PerBrazoCon
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 6: INSERTAR DATOS - OMOPLATO
-- =============================================

INSERT INTO [dbo].[Dimomoplato] (ID, PlSubEsc)
SELECT 
    ID,
    PlSubEsc
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 7: INSERTAR DATOS - CINTURA
-- =============================================

INSERT INTO [dbo].[Dimcintura] (ID, PICI, PlSup, PerCin)
SELECT 
    ID,
    PlCI,
    PlSup,
    PerCin
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 8: INSERTAR DATOS - CADERA
-- =============================================

INSERT INTO [dbo].[Dimcadera] (ID, PerCad)
SELECT 
    ID,
    PerCad
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 9: INSERTAR DATOS - PIERNA
-- =============================================

INSERT INTO [dbo].[Dimpierna] (ID, PIMM, PlPant, PerMuslo, Perpier)
SELECT 
    ID,
    PlMM,
    PlPant,
    PerMuslo,
    PerPier
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 10: INSERTAR DATOS - TORAX
-- =============================================

INSERT INTO [dbo].[Dimtorax] (ID, PerT)
SELECT 
    ID,
    PerT
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 11: INSERTAR DATOS - ABDOMEN
-- =============================================

INSERT INTO [dbo].[Dimabdomen] (ID, PlAbd)
SELECT 
    ID,
    PlAbd
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 12: INSERTAR DATOS - PRUEBA
-- =============================================

INSERT INTO [dbo].[DimPrueba] (ID, Test_Abd, Test_FlexCLS, Test_Salto, Test_Cooper)
SELECT 
    ID,
    Test_Abd,
    Test_FlexCLS,
    Test_Salto,
    Test_Cooper
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 13: INSERTAR DATOS - CLASIFICACION
-- =============================================

INSERT INTO [dbo].[DimClasificacion] (ID, ClsAbd, ClsFlex, Clasi_salto, Cls_Coop)
SELECT 
    ID,
    Clasi_ClsAbd,
    Clasi_ClsFlex,
    Clasi_salto,
    Clasi_Coop
FROM [dbo].[ANTROPOMETRIA_ALEMANA$]
WHERE ID IS NOT NULL;

GO

-- =============================================
-- PASO 14: CREAR �NDICES PARA OPTIMIZACI�N
-- =============================================

CREATE INDEX IX_HechosPersona_Nombre ON [dbo].[HechosPersona]([Nombre]);
CREATE INDEX IX_HechosPersona_Apellido ON [dbo].[HechosPersona]([Apellido]);
CREATE INDEX IX_HechosPersona_Edad ON [dbo].[HechosPersona]([Edad]);
CREATE INDEX IX_DimEscuela_Institucion ON [dbo].[DimEscuela]([Institucion]);
CREATE INDEX IX_DimEscuela_Division ON [dbo].[DimEscuela]([Division]);

GO

-- =============================================
-- PASO 15: VERIFICACI�N DE DATOS
-- =============================================

PRINT '============================================='
PRINT 'MIGRACION COMPLETADA'
PRINT '============================================='
PRINT ''
PRINT 'Registros migrados por tabla:'
PRINT ''
PRINT 'HechosPersona:  ' + CAST((SELECT COUNT(*) FROM HechosPersona) AS VARCHAR(10))
PRINT 'DimEscuela:     ' + CAST((SELECT COUNT(*) FROM DimEscuela) AS VARCHAR(10))
PRINT 'DimBrazo:          ' + CAST((SELECT COUNT(*) FROM DimBrazo) AS VARCHAR(10))
PRINT 'Dimomoplato:       ' + CAST((SELECT COUNT(*) FROM Dimomoplato) AS VARCHAR(10))
PRINT 'Dimcintura:        ' + CAST((SELECT COUNT(*) FROM Dimcintura) AS VARCHAR(10))
PRINT 'Dimcadera:         ' + CAST((SELECT COUNT(*) FROM Dimcadera) AS VARCHAR(10))
PRINT 'Dimpierna:         ' + CAST((SELECT COUNT(*) FROM Dimpierna) AS VARCHAR(10))
PRINT 'Dimtorax:          ' + CAST((SELECT COUNT(*) FROM Dimtorax) AS VARCHAR(10))
PRINT 'DimAbdomen:        ' + CAST((SELECT COUNT(*) FROM Dimabdomen) AS VARCHAR(10))
PRINT 'DimPrueba:      ' + CAST((SELECT COUNT(*) FROM DimPrueba) AS VARCHAR(10))
PRINT 'DimClasificacion:  ' + CAST((SELECT COUNT(*) FROM DimClasificacion) AS VARCHAR(10))
PRINT ''
PRINT '============================================='
PRINT 'NOTA: Las alturas en centimetros fueron'
PRINT 'convertidas automaticamente a metros'
PRINT '============================================='

-- Consulta de verificacion - primeros 5 registros
SELECT TOP 5
    p.ID,
    p.Nombre,
    p.Apellido,
    p.Sexo,
    p.Edad,
    e.Institucion,
    e.Division
FROM HechosPersona p
INNER JOIN DimEscuela e ON p.ID = e.ID
ORDER BY p.ID;

GO