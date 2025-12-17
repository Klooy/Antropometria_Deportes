import pandas as pd
import numpy as np

# -----------------------------
# 1. Cargar dataset
# -----------------------------
df = pd.read_excel("ANTROPOMETRIA_ALEMANA.xlsx")

# -----------------------------
# 2. Reemplazar valores problemáticos por NaN
# -----------------------------
valores_invalidos = [0, "0", "-", "NA", "N/A", "", " "]
df.replace(valores_invalidos, np.nan, inplace=True)

# -----------------------------
# 3. Columnas por tipo
# -----------------------------
pliegues = [
    "PlTr", "PlSubEsc", "PICI", "PlSup",
    "PlAbd", "PIMM", "PlPant"
]

perimetros = [
    "PerBrazoRel", "PerBrazoCon", "PerT",
    "PerCin", "PerCad", "PerMuslo", "Perpier"
]

tests = [
    "Test_Abd", "Test_FlexCLS", "Test_Salto"
]

# -----------------------------
# 4. Forzar columnas numéricas
# -----------------------------
for col in pliegues + perimetros + tests:
    if col in df.columns:
        df[col] = pd.to_numeric(df[col], errors="coerce")

# -----------------------------
# 5. Reglas de coherencia fisiológica
# -----------------------------

# Pliegues cutáneos (mm)
for col in pliegues:
    if col in df.columns:
        df.loc[(df[col] < 3) | (df[col] > 60), col] = np.nan

# Perímetros (cm)
for col in perimetros:
    if col in df.columns:
        df.loc[(df[col] < 15) | (df[col] > 200), col] = np.nan

# Tests físicos
for col in tests:
    if col in df.columns:
        df.loc[(df[col] < 1) | (df[col] > 500), col] = np.nan

# -----------------------------
# 6. Coherencia lógica entre columnas
# -----------------------------

# Brazo contraído NO puede ser menor que relajado
if "PerBrazoCon" in df.columns and "PerBrazoRel" in df.columns:
    df.loc[df["PerBrazoCon"] < df["PerBrazoRel"], "PerBrazoCon"] = np.nan

# -----------------------------
# 7. Rellenar NaN con la MEDIANA
# -----------------------------
for col in pliegues + perimetros + tests:
    if col in df.columns:
        mediana = df[col].median()
        df[col] = df[col].fillna(mediana)

# -----------------------------
# 8. Limpiar clasificaciones si el test era NaN originalmente
# -----------------------------
clasificaciones = {
    "Test_Abd": "ClsAbd",
    "Test_FlexCLS": "ClsFlex",
    "Test_Salto": "Cls_Coop"
}

for test, cls in clasificaciones.items():
    if test in df.columns and cls in df.columns:
        df.loc[df[test].isna(), cls] = "No evaluado"

# -----------------------------
# 9. Dataset corregido listo
# -----------------------------
print("✔ Datos corregidos y coherentes sin eliminar registros ni columnas")

# -----------------------------
# 10. Guardar Excel corregido
# -----------------------------
df.to_excel(
    "ANTROPOMETRIA_ALEMANA_CORREGIDA.xlsx",
    index=False
)

print("✔ Archivo guardado como ANTOPOMETRIA_ALEMANA_CORREGIDA.xlsx")

# =========================================================
# 11. Normalizar columnas Edad y Sexo (si existen)
# =========================================================
if "Edad" in df.columns:
    df["Edad"] = pd.to_numeric(df["Edad"], errors="coerce")

if "Sexo" in df.columns:
    df["Sexo"] = df["Sexo"].astype(str).str.upper().str.strip()

# =========================================================
# 12. Ajuste de rangos según edad (pliegues y perímetros)
# =========================================================
def rango_pliegue(edad):
    if edad < 12:
        return (3, 40)
    elif edad <= 17:
        return (3, 45)
    else:
        return (5, 60)

def rango_perimetro(edad):
    if edad < 12:
        return (30, 120)
    elif edad <= 17:
        return (40, 150)
    else:
        return (50, 200)

for col in pliegues:
    if col in df.columns and "Edad" in df.columns:
        for idx, row in df.iterrows():
            if pd.notna(row[col]) and pd.notna(row["Edad"]):
                min_v, max_v = rango_pliegue(row["Edad"])
                if row[col] < min_v or row[col] > max_v:
                    df.at[idx, col] = np.nan

for col in perimetros:
    if col in df.columns and "Edad" in df.columns:
        for idx, row in df.iterrows():
            if pd.notna(row[col]) and pd.notna(row["Edad"]):
                min_v, max_v = rango_perimetro(row["Edad"])
                if row[col] < min_v or row[col] > max_v:
                    df.at[idx, col] = np.nan

# =========================================================
# 13. Rellenar NaN nuevamente con mediana
# =========================================================
for col in pliegues + perimetros:
    if col in df.columns:
        df[col] = df[col].fillna(df[col].median())

# =========================================================
# 14. Funciones de clasificación automática
# =========================================================
def clasificar_abdominales(x):
    if x < 20:
        return "Deficiente"
    elif x < 30:
        return "Regular"
    elif x < 40:
        return "Bueno"
    else:
        return "Excelente"

def clasificar_flexiones(x, sexo):
    if sexo.startswith("F"):
        limites = [10, 20, 30]
    else:
        limites = [15, 30, 45]

    if x < limites[0]:
        return "Deficiente"
    elif x < limites[1]:
        return "Regular"
    elif x < limites[2]:
        return "Bueno"
    else:
        return "Excelente"

def clasificar_cooper(x):
    if x < 1800:
        return "Deficiente"
    elif x < 2200:
        return "Regular"
    elif x < 2600:
        return "Bueno"
    else:
        return "Excelente"

# =========================================================
# 15. Recalcular clasificaciones automáticamente
# =========================================================
if "Test_Abd" in df.columns:
    df["ClsAbd"] = df["Test_Abd"].apply(clasificar_abdominales)

if "Test_FlexCLS" in df.columns and "Sexo" in df.columns:
    df["ClsFlex"] = df.apply(
        lambda x: clasificar_flexiones(x["Test_FlexCLS"], x["Sexo"]),
        axis=1
    )

if "Test_Salto" in df.columns:
    df["Cls_Coop"] = df["Test_Salto"].apply(clasificar_cooper)

print("✔ Rangos ajustados por edad/sexo y clasificaciones recalculadas")
