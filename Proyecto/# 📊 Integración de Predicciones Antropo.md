# 📊 Integración de Predicciones Antropométricas con Python y Power BI

Este documento explica **paso a paso** cómo ejecutar el modelo de Machine Learning en **Python** y cómo **visualizar e interactuar con las predicciones en Power BI**, manteniendo una arquitectura correcta, profesional y defendible académicamente.

---

## 🎯 Objetivo del README

Guiar el proceso completo para:

1. Ejecutar predicciones antropométricas con Machine Learning en Python.
2. Exportar resultados estructurados.
3. Consumir esos resultados en Power BI.
4. Reemplazar menús por visualizaciones interactivas.

---

## 🧠 Enfoque recomendado (Arquitectura correcta)

```
Python (Machine Learning)
        ↓
Archivo Excel / CSV con predicciones
        ↓
Power BI (visualización y análisis)
```

📌 **Python se usa para el cálculo y la predicción**
📌 **Power BI se usa para explorar, filtrar y comparar**

---

## ⚠️ Por qué NO entrenar el modelo directamente en Power BI

Power BI tiene limitaciones importantes:

* No permite menús interactivos (`input()`)
* No es adecuado para entrenar modelos complejos
* No mantiene estado entre ejecuciones

Por esta razón:

> **El modelo debe entrenarse en Python** y Power BI solo debe consumir los resultados.

---

## 🧩 PASO 1 – Ejecutar el modelo en Python

### 1.1 Requisitos

* Python 3.9+
* Librerías:

```bash
pip install pandas numpy scikit-learn matplotlib openpyxl
```

### 1.2 Ejecutar el script

Desde la carpeta del proyecto:

```bash
python prediccion_ml_final.py
```

El programa:

* Carga el dataset antropométrico
* Entrena el modelo
* Genera predicciones a +2, +5 o +10 años
* Calcula somatotipo y % de grasa
* Genera conclusiones automáticas

---

## 📤 PASO 2 – Exportar resultados para Power BI

Al final del script de Python, se exporta un archivo:

```python
df_resultados.to_excel("predicciones_powerbi.xlsx", index=False)
```

### Contenido del archivo exportado

Cada fila representa un niño e incluye:

* Datos actuales (edad, perímetros)
* Predicciones futuras
* Horizonte temporal
* Somatotipo actual y futuro
* Conclusión automática

Este archivo será la **fuente de datos de Power BI**.

---

## 📊 PASO 3 – Importar datos en Power BI

1. Abrir **Power BI Desktop**
2. Seleccionar:

   * *Obtener datos → Excel*
3. Elegir `predicciones_powerbi.xlsx`
4. Cargar la tabla de resultados

---

## 🧭 PASO 4 – Reemplazar el menú por segmentadores

Lo que antes se hacía con un menú en consola ahora se hace con **segmentadores**:

| En Python        | En Power BI                    |
| ---------------- | ------------------------------ |
| Elegir niño      | Segmentador por Nombre         |
| Comparar niños   | Segmentador con multiselección |
| +2, +5, +10 años | Segmentador por Horizonte      |

📌 Power BI permite seleccionar uno o varios niños simultáneamente.

---

## 📈 PASO 5 – Crear visualizaciones

### Visualizaciones recomendadas

* 📊 Gráfico de columnas

  * Cintura actual vs futura
  * Cadera actual vs futura

* 📉 Gráfico de líneas

  * Evolución por horizonte temporal

* 🧬 Tarjeta

  * Somatotipo actual
  * Somatotipo futuro

* 📝 Tabla

  * Conclusión automática

---

## 🧠 PASO 6 – Interpretación en Power BI

El usuario puede:

* Seleccionar un niño específico
* Comparar varios niños
* Cambiar el horizonte de predicción
* Analizar tendencias corporales

Todo **sin ejecutar nuevamente el modelo**.

---

## 📝 PASO 7 – Uso académico (sustentación)

Puedes justificar el proceso diciendo:

> *El modelo predictivo fue desarrollado y validado en Python utilizando Machine Learning supervisado. Power BI se utilizó como herramienta de visualización y análisis interactivo de los resultados.*

Esta explicación es **correcta y profesional**.

---

## ⚠️ Limitaciones declaradas

* No se predice estatura futura
* No se usan datos longitudinales
* Predicciones basadas en patrones poblacionales

Estas limitaciones están **documentadas intencionalmente**.

---

## 🏆 Buenas prácticas aplicadas

✔ Separación de cálculo y visualización
✔ Reproducibilidad
✔ Interpretabilidad
✔ Escalabilidad

---

## ✅ Conclusión final

Power BI **no reemplaza** a Python para Machine Learning, pero es el complemento ideal para:

* Explorar resultados
* Comparar individuos
* Comunicar hallazgos

Este enfoque es el más sólido técnica y académicamente.

---

**Fin del README**
