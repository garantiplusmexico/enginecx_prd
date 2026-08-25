# Condensado — gg-campana-samanta-documentos

Campaña puntual de corrección masiva de documentos ya emitidos. **No es parte del proceso de
averías**; se conserva porque aporta un patrón de trabajo por lotes con control.

## Decisiones
- El paso que clasifica **nunca modifica** los documentos: es puro diagnóstico y produce dos
  listados, el de control y el de candidatos firmes a corregir.
- Solo se considera candidato firme el documento con **una única coincidencia exacta**; cualquier
  ambigüedad se marca como revisión manual y **el proceso nunca decide por su cuenta**.
- Se revalida la condición justo antes de modificar cada archivo, no solo al clasificar.

## Alcance / requerimientos
- Proceso por lotes reanudable: al arrancar lee el registro y se salta lo ya completado con
  éxito; los errores no bloquean, se reintentan en la siguiente ejecución.
- Registro por elemento con resultado y motivo, para poder auditar y cuadrar el lote.
- Resultado de la única ejecución registrada: 484 candidatos, 481 corregidos, 3 en error.

## Riesgos / pendientes
- **El script de la fase que realmente modificaba los documentos no quedó guardado**: si hay que
  repetir la campaña, se reconstruye desde cero. Lección: el código de un proceso que escribe en
  producción tiene que estar versionado.
- Los casos en error y los marcados como revisión manual se resolvieron a mano sin registro.
