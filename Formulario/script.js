let registros = [];

function guardarRegistro() {
  const campos = [
    "ID","Insititucion","Nombre","Apelllido","Edad","Peso","Altura","PlTr","PlSubEsc","PlCI","PlSup",
    "PlAbd","PlMM","PlPant","PerBrazoRel","PerBrazoCon","PerT","PerCin","PerCad","PerMuslo","PerPier",
    "Test_Abd","Clasi_ClsAbd","Test_FlexCLS","Clasi_ClsFlex","Test_Salto","Clasi_salto","Test_Cooper","Clasi_Coop"
  ];

  let registro = {};
  campos.forEach(c => registro[c] = document.getElementById(c)?.value || "");

  // Fecha (de DimTiempo)
  registro.Fecha = document.getElementById("Fecha").value;

  registros.push(registro);
  document.getElementById("contador").innerText = `Registros guardados: ${registros.length}`;
  alert("✅ Registro guardado correctamente.");

  // Limpiar campos
  document.querySelectorAll("input").forEach(i => i.value = "");
}

function exportarExcel() {
  if (registros.length === 0) {
    alert("No hay registros para exportar.");
    return;
  }

  const wb = XLSX.utils.book_new();
  const ws = XLSX.utils.json_to_sheet(registros);
  XLSX.utils.book_append_sheet(wb, ws, "ANTROPOMETRIA_ALEMANA");
  XLSX.writeFile(wb, "ANTROPOMETRIA_ALEMANA.xlsx");
}
