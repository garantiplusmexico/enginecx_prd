# Notas — Carga Masiva de contratos al crear una orden de pago

## Problema
Para agregar contratos a una orden de pago, el proceso se realiza contrato a contrato de forma manual.

## Mejora propuesta
Habilitar carga masiva de contratos a la orden de pago, permitiendo seleccionar o importar múltiples contratos simultáneamente.

## Consideraciones para desarrollo
- Parser Excel para seleccionar contratos elegibles.
- Reutilizar infra BatchLoadFromExcel si aplica.
- Validación de elegibilidad (estado, distribuidor, no duplicados en ODP).
- Preview antes de confirmar.
- Creación batch de poliza_ordenpago.
- Flag `contratos_masivos` en distribuidor no integrado al flujo ODP.

## Importancia e impacto de negocio
- Importancia: Alta
- Impacto: Eficiencia operativa | Administración financiera
- Carga masiva a orden de pago; ahorra horas operativas al agregar contratos en lote.
