# Condensado — correo-david-simancas-cambios-averias-bridgestone

## Decisiones
- Autocompletar el campo "Refacción" cuando el tipo de concepto sea "LLANTA" (sin captura manual del usuario).
- Eliminar los campos "No. Parte" y "M.O." del registro de avería para la operación Bridgestone.
- Eliminar el campo "IVA": el distribuidor capturará el costo final con impuestos incluidos (sin desglose de IVA).

## Alcance / requerimientos
- Cambios sobre el módulo/formulario de captura de aver��as (SIGA) para la operación Bridgestone.
- Autocompletado condicionado al tipo de concepto seleccionado.
- Remoción de campos que hoy existen en el formulario.

## Actores
- David Simancas — Gerente de Averías (solicitante/patrocinador).
- Distribuidor — quien captura el costo final con impuestos incluidos.

## Riesgos / pendientes
- Multi-país: cada país maneja un % de impuestos distinto — motivo explícito para eliminar el campo IVA en vez de parametrizarlo por país.
- Pendiente confirmar si "No. Parte" y "M.O." se eliminan solo para Bridgestone o si el cambio es global al módulo (afectaría a otros distribuidores/marcas).

## Fechas / hitos
- (No se mencionan fechas en el correo.)
