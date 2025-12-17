import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

# ==================================================
# 1. Cargar dataset
# ==================================================
df = pd.read_excel("ANTROPOMETRIA_ALEMANA_CORREGIDA.xlsx")

# ==================================================
# 2. Normalizar sexo
# ==================================================
df["Sexo"] = df["Sexo"].astype(str).str.strip().str.upper()

df["Sexo_norm"] = df["Sexo"].replace({
    "M": "M", "MASCULINO": "M", "H": "M", "HOMBRE": "M", "1": "M",
    "F": "F", "FEMENINO": "F", "MUJER": "F", "2": "F"
})

df = df[df["Sexo_norm"] == "M"].reset_index(drop=True)

if df.empty:
    raise ValueError("No hay registros masculinos disponibles.")

# ==================================================
# 3. Codificar sexo
# ==================================================
le = LabelEncoder()
df["Sexo_cod"] = le.fit_transform(df["Sexo_norm"])

# ==================================================
# 4. Columnas predictoras
# ==================================================
X_cols = [
    "Edad", "Sexo_cod",
    "PerCin", "PerCad",
    "PlTr", "PlAbd", "PlSubEsc",
    "Test_Abd", "Test_FlexCLS"
]

# ==================================================
# 5. Función somatotipo (robusta)
# ==================================================
def estimar_somatotipo(row):

    pliegues = [row[c] for c in ["PlTr", "PlAbd", "PlSubEsc"]
                if c in row.index and pd.notna(row[c])]

    perimetros = [row[c] for c in
                  ["PerBrazoCon", "PerMuslo", "PerPier", "Perpier", "PerPierna"]
                  if c in row.index and pd.notna(row[c])]

    if not pliegues or not perimetros:
        return "No determinado"

    suma_pliegues = sum(pliegues)
    indicador_muscular = np.mean(perimetros)

    if suma_pliegues < 40 and indicador_muscular < 45:
        return "Ectomorfo"
    elif suma_pliegues < 55:
        return "Mesomorfo"
    else:
        return "Endomorfo"

# ==================================================
# 6. Función % grasa estimado
# ==================================================
def grasa_estim(pltr, plabd, plsub):
    return 0.105 * (pltr + plabd + plsub) + 2.58

# ==================================================
# 7. Entrenar modelos ML
# ==================================================
targets = {
    "PerCin": "Perímetro de cintura (cm)",
    "PerCad": "Perímetro de cadera (cm)"
}

modelos = {}
X = df[X_cols]

for target in targets:
    y = df[target]

    X_train, _, y_train, _ = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    model = RandomForestRegressor(
        n_estimators=200,
        random_state=42
    )
    model.fit(X_train, y_train)
    modelos[target] = model

# ==================================================
# 8. Función de conclusiones automáticas
# ==================================================
def generar_conclusion(
    nombre,
    edad_actual,
    edad_futura,
    cintura_actual,
    cintura_futura,
    cadera_actual,
    cadera_futura,
    grasa_actual,
    grasa_futura,
    somatotipo_actual,
    somatotipo_futuro
):
    conclusion = f"Conclusión automática ({nombre}):\n"

    if cintura_futura - cintura_actual > 3:
        conclusion += "- Aumento relevante de cintura.\n"
    elif cintura_futura > cintura_actual:
        conclusion += "- Aumento leve de cintura.\n"
    else:
        conclusion += "- Cintura estable.\n"

    if grasa_futura - grasa_actual > 2:
        conclusion += "- Incremento significativo de grasa corporal.\n"
    elif grasa_futura > grasa_actual:
        conclusion += "- Incremento moderado de grasa corporal.\n"
    else:
        conclusion += "- Grasa corporal estable.\n"

    if somatotipo_actual != somatotipo_futuro:
        conclusion += f"- Cambio de somatotipo: {somatotipo_actual} → {somatotipo_futuro}.\n"
    else:
        conclusion += f"- Somatotipo se mantiene: {somatotipo_actual}.\n"

    conclusion += f"- Recomendación: seguimiento antropométrico y hábitos saludables a los {edad_futura} años.\n"

    return conclusion

# ==================================================
# 9. MENÚ PRINCIPAL
# ==================================================
print("\nMENÚ PRINCIPAL")
print("1. Predicción de UN niño")
print("2. Comparar VARIOS niños")

modo = input("Seleccione opción: ")

print("\nHorizonte de predicción:")
print("1. +2 años")
print("2. +5 años")
print("3. +10 años")

anos_map = {"1": 2, "2": 5, "3": 10}
anos_futuro = anos_map.get(input("Opción: "), 5)

print("\nListado de niños disponibles (primeros 20):")
print(df[["Edad", "PerCin", "PerCad"]].head(20))

# ==================================================
# 10. Selección de índices
# ==================================================
if modo == "1":
    indices = [int(input("\nIngrese índice del niño: "))]
else:
    indices = input("\nIngrese índices separados por coma (ej: 0,3,7): ")
    indices = [int(i.strip()) for i in indices.split(",")]

# ==================================================
# 11. PROCESAMIENTO + EXPORTACIÓN
# ==================================================
resultados_powerbi = []

for idx in indices:

    sujeto = df.loc[idx]
    edad_actual = sujeto["Edad"]
    edad_futura = edad_actual + anos_futuro

    print("\n==============================================")
    print(f"SUJETO ÍNDICE {idx}")

    nombre = sujeto["Nombre"] if "Nombre" in df.columns else f"Sujeto_{idx}"

    print(f"Nombre: {nombre}")
    print(f"Edad actual: {edad_actual}")
    print(f"Edad futura: {edad_futura}")

    som_act = estimar_somatotipo(sujeto)
    print(f"Somatotipo actual: {som_act}")

    sujeto_futuro = sujeto.copy()
    sujeto_futuro["Edad"] = edad_futura

    factor = 1 + (0.01 * anos_futuro)
    sujeto_futuro["PlTr"] *= factor
    sujeto_futuro["PlAbd"] *= factor
    sujeto_futuro["PlSubEsc"] *= factor

    X_fut = pd.DataFrame([sujeto_futuro[X_cols]], columns=X_cols)

    pred_percin = modelos["PerCin"].predict(X_fut)[0]
    pred_percad = modelos["PerCad"].predict(X_fut)[0]

    grasa_actual = grasa_estim(
        sujeto["PlTr"], sujeto["PlAbd"], sujeto["PlSubEsc"]
    )
    grasa_futura = grasa_estim(
        sujeto_futuro["PlTr"],
        sujeto_futuro["PlAbd"],
        sujeto_futuro["PlSubEsc"]
    )

    som_fut = estimar_somatotipo(sujeto_futuro)

    print(f"Cintura futura estimada: {pred_percin:.2f} cm")
    print(f"Cadera futura estimada: {pred_percad:.2f} cm")
    print(f"% Grasa futura estimada: {grasa_futura:.2f}")
    print(f"Somatotipo futuro: {som_fut}")

    for valor, etiqueta in [
        ([sujeto["PerCin"], pred_percin], "Perímetro de cintura"),
        ([sujeto["PerCad"], pred_percad], "Perímetro de cadera"),
        ([grasa_actual, grasa_futura], "% Grasa corporal")
    ]:
        plt.figure()
        plt.plot([edad_actual, edad_futura], valor, marker="o")
        plt.xlabel("Edad")
        plt.ylabel(etiqueta)
        plt.title(f"{etiqueta} – Proyección")
        plt.show()

    resultados_powerbi.append({
        "Nombre": nombre,
        "Edad_Actual": edad_actual,
        "Edad_Futura": edad_futura,
        "Horizonte_Anios": anos_futuro,
        "PerCin_Actual": sujeto["PerCin"],
        "PerCin_Futura": round(pred_percin, 2),
        "PerCad_Actual": sujeto["PerCad"],
        "PerCad_Futura": round(pred_percad, 2),
        "Grasa_Actual": round(grasa_actual, 2),
        "Grasa_Futura": round(grasa_futura, 2),
        "Somatotipo_Actual": som_act,
        "Somatotipo_Futuro": som_fut,
        "Conclusion": generar_conclusion(
            nombre, edad_actual, edad_futura,
            sujeto["PerCin"], pred_percin,
            sujeto["PerCad"], pred_percad,
            grasa_actual, grasa_futura,
            som_act, som_fut
        )
    })

# ==================================================
# 12. EXPORTAR EXCEL PARA POWER BI
# ==================================================
df_powerbi = pd.DataFrame(resultados_powerbi)
df_powerbi.to_excel("predicciones_powerbi.xlsx", index=False)

print("\n📁 Archivo 'predicciones_powerbi.xlsx' generado correctamente.")
print("\n✔ Proceso finalizado correctamente")
