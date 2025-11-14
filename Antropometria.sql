-- ===========================================================
--  DATA WAREHOUSE: ANTROPOMETRÍA ALEMANA
--  Esquema tipo estrella
-- ===========================================================

CREATE DATABASE IF NOT EXISTS DW_Antropometria;
USE DW_Antropometria;

-- ===========================================================
-- DIMENSIONES
-- ===========================================================

-- 1️⃣ Dimensión Persona
CREATE TABLE DimPersona (
    ID INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Apelllido VARCHAR(100)
);

-- 2️⃣ Dimensión Institución
CREATE TABLE DimInstitucion (
    id_institucion INT PRIMARY KEY AUTO_INCREMENT,
    Insititucion VARCHAR(150)
);

-- 3️⃣ Dimensión Antropometría (pliegues cutáneos)
CREATE TABLE DimAntropometria (
    id_antropometria INT PRIMARY KEY AUTO_INCREMENT,
    PlTr DECIMAL(5,2),
    PlSubEsc DECIMAL(5,2),
    PlCI DECIMAL(5,2),
    PlSup DECIMAL(5,2),
    PlAbd DECIMAL(5,2),
    PlMM DECIMAL(5,2),
    PlPant DECIMAL(5,2)
);

-- 4️⃣ Dimensión Perímetros
CREATE TABLE DimPerimetros (
    id_perimetros INT PRIMARY KEY AUTO_INCREMENT,
    PerBrazoRel DECIMAL(5,2),
    PerBrazoCon DECIMAL(5,2),
    PerT DECIMAL(5,2),
    PerCin DECIMAL(5,2),
    PerCad DECIMAL(5,2),
    PerMuslo DECIMAL(5,2),
    PerPier DECIMAL(5,2)
);

-- 5️⃣ Dimensión Pruebas Físicas
CREATE TABLE DimPruebasFisicas (
    id_pruebas INT PRIMARY KEY AUTO_INCREMENT,
    Test_Abd DECIMAL(5,2),
    Clasi_ClsAbd VARCHAR(50),
    Test_FlexCLS DECIMAL(5,2),
    Clasi_ClsFlex VARCHAR(50),
    Test_Salto DECIMAL(5,2),
    Clasi_salto VARCHAR(50),
    Test_Cooper DECIMAL(6,2),
    Clasi_Coop VARCHAR(50)
);

-- 6️⃣ Dimensión Tiempo (opcional)
CREATE TABLE DimTiempo (
    id_tiempo INT PRIMARY KEY AUTO_INCREMENT,
    Fecha DATE,
    Año INT,
    Mes INT,
    Dia INT
);

-- ===========================================================
-- TABLA DE HECHOS
-- ===========================================================

CREATE TABLE Hechos_Persona (
    ID INT PRIMARY KEY,
    Edad INT,
    Peso DECIMAL(5,2),
    Altura DECIMAL(5,2),

    id_institucion INT,
    id_antropometria INT,
    id_perimetros INT,
    id_pruebas INT,
    id_tiempo INT,

    FOREIGN KEY (ID) REFERENCES DimPersona(ID),
    FOREIGN KEY (id_institucion) REFERENCES DimInstitucion(id_institucion),
    FOREIGN KEY (id_antropometria) REFERENCES DimAntropometria(id_antropometria),
    FOREIGN KEY (id_perimetros) REFERENCES DimPerimetros(id_perimetros),
    FOREIGN KEY (id_pruebas) REFERENCES DimPruebasFisicas(id_pruebas),
    FOREIGN KEY (id_tiempo) REFERENCES DimTiempo(id_tiempo)
);
