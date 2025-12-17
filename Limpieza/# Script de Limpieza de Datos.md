# Script de Limpieza de Datos Antropométricos

## Descripción

Script en Python para la limpieza, validación y corrección de un dataset de antropometría alemana. Procesa mediciones corporales, tests físicos y clasificaciones, aplicando reglas de coherencia fisiológica y normalizando los datos.

## Requisitos

```bash
pip install pandas numpy openpyxl
```

## Uso

```bash
python limpieza_data.py
```

**Archivo de entrada:** `ANTROPOMETRIA_ALEMANA.xlsx`  
**Archivo de salida:** `ANTROPOMETRIA_ALEMANA_CORREGIDA.xlsx`

## Funcionalidades

### 1. Limpieza Inicial
- Carga el dataset desde Excel
- Reemplaza valores inválidos por NaN: `0`, `"-"`, `"NA"`, `"N/A"`, espacios vacíos
- Convierte columnas numéricas forzando el tipo de dato correcto

### 2. Variables Procesadas

**Pliegues cutáneos (mm):**
- PlTr (Tríceps)
- PlSubEsc (Subescapular)
- PICI (Cresta ilíaca)
- PlSup (Supraespinal)
- PlAbd (Abdominal)
- PIMM (Muslo medio)
- PlPant (Pantorrilla)

**Perímetros (cm):**
- PerBrazoRel (Brazo relajado)
- PerBrazoCon (Brazo contraído)
- PerT (Tórax)
- PerCin (Cintura)
- PerCad (Cadera)
- PerMuslo
- Perpier (Pierna)

**Tests físicos:**
- Test_Abd (Abdominales)
- Test_FlexCLS (Flexiones)
- Test_Salto (Test de Cooper)

### 3. Validación Fisiológica

**Rangos generales:**
- Pliegues: 3-60 mm
- Perímetros: 15-200 cm
- Tests físicos: 1-500 unidades

**Rangos ajustados por edad:**

*Pliegues cutáneos:*
- < 12 años: 3-40 mm
- 12-17 años: 3-45 mm
- ≥ 18 años: 5-60 mm

*Perímetros:*
- < 12 años: 30-120 cm
- 12-17 años: 40-150 cm
- ≥ 18 años: 50-200 cm

### 4. Coherencia Lógica

- El perímetro del brazo contraído no puede ser menor que el brazo relajado
- Se valida la coherencia entre valores relacionados

### 5. Imputación de Valores

Los valores NaN se rellenan con la **mediana** de cada columna para mantener la distribución y evitar sesgos.

### 6. Clasificaciones Automáticas

**Abdominales (Test_Abd → ClsAbd):**
- Deficiente: < 20 repeticiones
- Regular: 20-29
- Bueno: 30-39
- Excelente: ≥ 40

**Flexiones (Test_FlexCLS → ClsFlex):**

*Mujeres:*
- Deficiente: < 10
- Regular: 10-19
- Bueno: 20-29
- Excelente: ≥ 30

*Hombres:*
- Deficiente: < 15
- Regular: 15-29
- Bueno: 30-44
- Excelente: ≥ 45

**Test de Cooper (Test_Salto → Cls_Coop):**
- Deficiente: < 1800 m
- Regular: 1800-2199 m
- Bueno: 2200-2599 m
- Excelente: ≥ 2600 m

## Características del Procesamiento

✅ **No elimina registros:** Preserva todos los casos del dataset original  
✅ **No elimina columnas:** Mantiene la estructura completa de datos  
✅ **Validación robusta:** Aplica múltiples niveles de validación fisiológica  
✅ **Imputación inteligente:** Usa la mediana para mantener distribuciones  
✅ **Clasificaciones automáticas:** Recalcula evaluaciones según estándares  
✅ **Trazabilidad:** Marca como "No evaluado" los tests sin datos originales

## Salida

El script genera:
1. Mensajes de confirmación en consola
2. Archivo Excel corregido con todas las validaciones aplicadas
3. Dataset completo listo para análisis estadístico

## Notas Técnicas

- Los valores fuera de rango se convierten a NaN antes de la imputación
- Las clasificaciones se recalculan automáticamente después de la limpieza
- El script considera diferencias por edad y sexo en las validaciones
- La normalización de edad y sexo se realiza antes de aplicar reglas específicas

## Autor

Script de preprocesamiento para análisis de datos antropométricos y evaluación física.