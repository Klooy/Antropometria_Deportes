# 📊 Sistema de Predicción Antropométrica con Machine Learning

Este proyecto implementa un **sistema de análisis y proyección antropométrica** orientado a contextos educativos y deportivos. A partir de un dataset antropométrico depurado, el sistema permite **predecir variables corporales futuras**, **clasificar somatotipo**, **comparar individuos** y **generar conclusiones automáticas**, utilizando técnicas de *Machine Learning supervisado (regresión)*.

---

## 🎯 Objetivo del proyecto

Desarrollar una herramienta que permita:

* Analizar datos antropométricos actuales.
* Proyectar variables corporales a **+2, +5 o +10 años**.
* Comparar uno o varios niños.
* Estimar el **somatotipo** (ectomorfo, mesomorfo, endomorfo).
* Generar **conclusiones automáticas interpretables**.

> ⚠️ Importante: las predicciones representan **proyecciones poblacionales**, no diagnósticos clínicos individuales.

---

## 🧠 Enfoque metodológico

* **Tipo de modelo:** Machine Learning supervisado (Regresión)
* **Algoritmo:** Random Forest Regressor
* **Tipo de datos:** Transversales (no longitudinales)
* **Horizonte temporal:** Simulación del envejecimiento (+2, +5, +10 años)

---

## 📥 Dataset requerido

Archivo obligatorio:

```
ANTROPOMETRIA_ALEMANA_CORREGIDA.xlsx
```

### Columnas mínimas esperadas

**Datos generales**

* `Nombre` (opcional)
* `Edad`
* `Sexo`

**Perímetros (cm)**

* `PerCin`
* `PerCad`
* `PerBrazoCon`
* `PerMuslo`
* `PerPier` / `PerPierna`

**Pliegues cutáneos (mm)**

* `PlTr`
* `PlAbd`
* `PlSubEsc`

**Tests físicos**

* `Test_Abd`
* `Test_FlexCLS`

El código es **robusto** ante nombres alternativos o columnas faltantes.

---

## ⚙️ Requisitos del sistema

* Python **3.9 o superior** (compatible con 3.13)
* Librerías:

```bash
pip install pandas numpy matplotlib scikit-learn openpyxl
```

---

## ▶️ Ejecución del programa

Desde la carpeta del proyecto:

```bash
python prediccion_ml_final.py
```

---

## 🧭 Flujo del programa

1. **Menú principal**

   * Predicción de un solo niño
   * Comparación de varios niños

2. **Selección del horizonte temporal**

   * +2 años
   * +5 años
   * +10 años

3. **Selección de sujetos**

   * Por índice del dataset

4. **Procesamiento automático**

   * Entrenamiento del modelo
   * Predicciones futuras
   * Estimación de % grasa corporal
   * Clasificación de somatotipo

5. **Visualización**

   * Gráficas por variable proyectada

6. **Conclusión automática por niño**

---

## 📈 Variables predichas

* **Perímetro de cintura futuro (cm)**
* **Perímetro de cadera futuro (cm)**
* **Porcentaje de grasa corporal estimado**
* **Somatotipo futuro estimado**

---

## 🧬 Somatotipo (estimado)

El somatotipo se calcula mediante un **método heurístico** basado en:

* Suma de pliegues cutáneos (adiposidad)
* Promedio de perímetros musculares

Clasificaciones:

* **Ectomorfo:** baja adiposidad y bajo desarrollo muscular
* **Mesomorfo:** desarrollo muscular predominante
* **Endomorfo:** mayor adiposidad relativa

> Basado en principios del método **Heath–Carter**, con fines educativos.

---

## 📝 Conclusiones automáticas

Para cada niño, el sistema genera automáticamente un texto interpretativo que incluye:

* Evolución del perímetro de cintura
* Evolución del perímetro de cadera
* Cambios en el porcentaje de grasa corporal
* Cambio o estabilidad del somatotipo
* Recomendación general preventiva

Ejemplo:

> *Se proyecta un aumento significativo del perímetro de cintura, lo que podría indicar incremento de adiposidad central...*

---

## 📊 Resultados gráficos

Para cada sujeto se generan:

* Gráfica de cintura actual vs futura
* Gráfica de cadera actual vs futura
* Gráfica de % grasa corporal

Cada gráfica se muestra de forma individual para facilitar el análisis.

---

## ⚠️ Limitaciones del modelo

* No predice crecimiento óseo ni estatura futura.
* No reemplaza evaluación clínica.
* Basado en patrones poblacionales, no genéticos.

Estas limitaciones están **documentadas y justificadas académicamente**.

---

## 🏆 Alcance académico

Este proyecto es adecuado para:

* Sustentaciones SENA
* Proyectos de analítica de datos
* Introducción al Machine Learning aplicado a salud y deporte
* Ejercicios de validación y proyección antropométrica

---

## 👨‍💻 Autor

Proyecto desarrollado por estudiantes del SENA con apoyo de IA para fines **educativos y formativos** en análisis de datos, antropometría y Machine Learning.

---

## ✅ Estado del proyecto

✔ Funcional
✔ Documentado
✔ Reproducible
✔ Defendible académicamente

---

**Fin del README**
