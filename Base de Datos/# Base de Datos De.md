# Script de Migración - Base de Datos Deportes

## Descripción

Script SQL para migrar datos antropométricos desde una tabla plana (`ANTROPOMETRIA_ALEMANA$`) a una estructura normalizada de base de datos relacional. Transforma un diseño de tabla única en un modelo normalizado de 11 tablas con relaciones de integridad referencial.

## Requisitos

- Microsoft SQL Server (2012 o superior)
- Base de datos `deportes` creada previamente
- Tabla fuente: `ANTROPOMETRIA_ALEMANA$` con datos cargados

## Ejecución

```sql
USE [deportes]
GO

-- Ejecutar el script completo
-- O ejecutarlo por secciones según los pasos numerados
```

## Estructura de la Base de Datos Normalizada

### Diagrama Entidad-Relación

```
Persona (tabla central)
   ├── Escuela (1:1)
   ├── Brazo (1:1)
   ├── omoplato (1:1)
   ├── cintura (1:1)
   ├── cadera (1:1)
   ├── pierna (1:1)
   ├── torax (1:1)
   ├── abdomen (1:1)
   ├── Prueba (1:1)
   └── Clasificacion (1:1)
```

## Tablas Creadas

### 1. **Persona** (Tabla Central)
**Datos demográficos básicos**
- `ID` (PK): Identificador único
- `Nombre`: Nombre de la persona
- `Apellido`: Apellido
- `Sexo`: M (Masculino) / F (Femenino)
- `Edad`: Edad en años
- `Peso`: Peso en kg
- `Altura`: Altura en metros

### 2. **Escuela**
**Información institucional**
- `ID` (PK, FK): Referencia a Persona
- `Institucion`: Nombre de la institución
- `Division`: División o grado
- `Nombre_Entrenador`: Nombre del entrenador
- `Fecha_Registro`: Fecha de registro

### 3. **Brazo**
**Mediciones del brazo**
- `ID` (PK, FK): Referencia a Persona
- `PlTr`: Pliegue tríceps (mm)
- `PerBrazoRel`: Perímetro brazo relajado (cm)
- `PerBrazoCon`: Perímetro brazo contraído (cm)

### 4. **omoplato**
**Mediciones del omóplato**
- `ID` (PK, FK): Referencia a Persona
- `PlSubEsc`: Pliegue subescapular (mm)

### 5. **cintura**
**Mediciones de cintura**
- `ID` (PK, FK): Referencia a Persona
- `PICI`: Pliegue cresta ilíaca (mm)
- `PlSup`: Pliegue supraespinal (mm)
- `PerCin`: Perímetro de cintura (cm)

### 6. **cadera**
**Mediciones de cadera**
- `ID` (PK, FK): Referencia a Persona
- `PerCad`: Perímetro de cadera (cm)

### 7. **pierna**
**Mediciones de extremidades inferiores**
- `ID` (PK, FK): Referencia a Persona
- `PIMM`: Pliegue muslo medio (mm)
- `PlPant`: Pliegue pantorrilla (mm)
- `PerMuslo`: Perímetro de muslo (cm)
- `Perpier`: Perímetro de pierna (cm)

### 8. **torax**
**Mediciones del tórax**
- `ID` (PK, FK): Referencia a Persona
- `PerT`: Perímetro de tórax (cm)

### 9. **abdomen**
**Mediciones abdominales**
- `ID` (PK, FK): Referencia a Persona
- `PlAbd`: Pliegue abdominal (mm)

### 10. **Prueba**
**Resultados de tests físicos**
- `ID` (PK, FK): Referencia a Persona
- `Test_Abd`: Test de abdominales (repeticiones)
- `Test_FlexCLS`: Test de flexiones (repeticiones)
- `Test_Salto`: Test de salto (cm)
- `Test_Cooper`: Test de Cooper (metros)

### 11. **Clasificacion**
**Evaluaciones cualitativas**
- `ID` (PK, FK): Referencia a Persona
- `ClsAbd`: Clasificación abdominales
- `ClsFlex`: Clasificación flexiones
- `Clasi_salto`: Clasificación salto
- `Cls_Coop`: Clasificación Cooper

## Proceso de Migración

### Paso 1: Eliminación de Tablas
Elimina tablas existentes si las hay (operación idempotente)

### Paso 2: Creación de Estructura
Crea las 11 tablas normalizadas con:
- Claves primarias
- Claves foráneas
- Restricciones de integridad referencial

### Pasos 3-13: Inserción de Datos
Migra los datos desde la tabla fuente a cada tabla normalizada

### Paso 14: Optimización
Crea índices en columnas frecuentemente consultadas:
- `Persona`: Nombre, Apellido, Edad
- `Escuela`: Institución, División

### Paso 15: Verificación
Genera reporte con:
- Conteo de registros por tabla
- Consulta de muestra de los primeros 5 registros
- Notificaciones sobre conversiones realizadas

## Transformaciones Automáticas

### 1. Conversión de Sexo
```sql
'Hombre' → 'M'
'Mujer'  → 'F'
```

### 2. Normalización de Altura
Detecta y convierte automáticamente:
```sql
Si Altura > 10 → Altura / 100.0
-- Ejemplo: 175 cm → 1.75 m
```

### 3. Mapeo de Columnas

| Tabla Original | Tabla Destino | Nota |
|---------------|---------------|------|
| `Apelllido` | `Apellido` | Corrige triple 'l' |
| `Insititucion` | `Institucion` | Corrige falta de 't' |
| `PlCI` | `PICI` | Normaliza nombre |
| `PlMM` | `PIMM` | Normaliza nombre |
| `PerPier` | `Perpier` | Normaliza nombre |
| `Clasi_ClsAbd` | `ClsAbd` | Simplifica nombre |
| `Clasi_ClsFlex` | `ClsFlex` | Simplifica nombre |
| `Clasi_Coop` | `Cls_Coop` | Normaliza nombre |

## Ventajas de la Normalización

✅ **Eliminación de redundancia:** Datos organizados en contextos específicos  
✅ **Integridad referencial:** Relaciones garantizadas por foreign keys  
✅ **Facilidad de mantenimiento:** Actualizaciones centralizadas  
✅ **Optimización de consultas:** Índices en columnas clave  
✅ **Escalabilidad:** Estructura extensible para nuevas mediciones  
✅ **Organización lógica:** Datos agrupados por área corporal

## Consultas de Ejemplo

### Datos completos de una persona
```sql
SELECT 
    p.*,
    e.Institucion,
    b.PlTr, b.PerBrazoRel,
    pr.Test_Abd, pr.Test_Cooper,
    c.ClsAbd, c.Cls_Coop
FROM Persona p
LEFT JOIN Escuela e ON p.ID = e.ID
LEFT JOIN Brazo b ON p.ID = b.ID
LEFT JOIN Prueba pr ON p.ID = pr.ID
LEFT JOIN Clasificacion c ON p.ID = c.ID
WHERE p.ID = 1;
```

### Estadísticas por institución
```sql
SELECT 
    e.Institucion,
    COUNT(*) as Total_Estudiantes,
    AVG(p.Edad) as Edad_Promedio,
    AVG(pr.Test_Abd) as Promedio_Abdominales
FROM Persona p
INNER JOIN Escuela e ON p.ID = e.ID
INNER JOIN Prueba pr ON p.ID = pr.ID
GROUP BY e.Institucion;
```

### Clasificaciones por edad y sexo
```sql
SELECT 
    p.Sexo,
    CASE 
        WHEN p.Edad < 12 THEN 'Infantil'
        WHEN p.Edad < 18 THEN 'Juvenil'
        ELSE 'Adulto'
    END as Categoria,
    c.ClsAbd,
    COUNT(*) as Cantidad
FROM Persona p
INNER JOIN Clasificacion c ON p.ID = c.ID
GROUP BY p.Sexo, 
    CASE 
        WHEN p.Edad < 12 THEN 'Infantil'
        WHEN p.Edad < 18 THEN 'Juvenil'
        ELSE 'Adulto'
    END,
    c.ClsAbd
ORDER BY p.Sexo, Categoria, c.ClsAbd;
```

## Notas Importantes

⚠️ **Precauciones:**
- El script elimina y recrea las tablas (DROP TABLE)
- Ejecutar en entorno de prueba primero
- Hacer backup de la base de datos antes de ejecutar
- La tabla fuente `ANTROPOMETRIA_ALEMANA$` debe existir

📌 **Consideraciones:**
- Las relaciones son 1:1 (una persona = un registro en cada tabla)
- Todos los campos permiten NULL excepto los ID
- Se respeta la integridad referencial con FOREIGN KEY
- La conversión de altura es automática y detecta el formato

## Verificación Post-Migración

El script incluye verificación automática que muestra:
1. Número de registros migrados por tabla
2. Confirmación de conversiones realizadas
3. Muestra de datos migrados

## Autor

Script de migración para normalización de base de datos antropométrica deportiva.