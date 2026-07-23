# Condensado — Notas Carga Masiva de contratos al crear una orden de pago

## Decisiones
- Habilitar carga masiva de contratos a una Orden de Pago (ODP), en lote, vía selección o importación de Excel.

## Alcance / requerimientos
- Parser de Excel para identificar/seleccionar contratos elegibles.
- Reutilizar infraestructura existente `BatchLoadFromExcel` si aplica.
- Validación de elegibilidad por contrato: estado, distribuidor, no duplicados dentro de la ODP.
- Preview de resultados (elegibles vs. rechazados) antes de confirmar.
- Creación batch de registros `poliza_ordenpago`.
- Control por flag `contratos_masivos` a nivel distribuidor: si el distribuidor no está integrado al flujo ODP, no aplica.

## Actores
- Área operativa / administración financiera que arma órdenes de pago.

## Riesgos / pendientes
- Definir criterios exactos de elegibilidad y qué campo del Excel identifica al contrato.
- Definir comportamiento del flag `contratos_masivos` (por distribuidor).
- Manejo de errores parciales (algunos contratos válidos, otros no).

## Fechas / hitos
- (No especificadas.)

## Impacto de negocio
- Importancia: Alta. Impacto: eficiencia operativa y administración financiera; ahorra horas operativas al agregar contratos en lote.
