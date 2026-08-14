# Condensado — OP-01: Permitir nuevo formato de patentes (Placa) para Chile

## Decisiones
- El campo patente debe aceptar exactamente DOS formatos válidos y rechazar cualquier otro.
  - Formato 1 (actual): 4 letras + 2 números → `LLLL-NN`.
  - Formato 2 (nuevo): 5 letras + 1 número → `LLLLL-N`.

## Alcance / requerimientos
- Actualizar la validación del campo **patente** en el módulo de **emisión** (SIGA, Chile).
- Hoy solo se valida `LLLL-NN`; se debe agregar el nuevo formato `LLLLL-N`.
- Rechazar explícitamente cualquier formato distinto a los dos permitidos.

## Actores
- Usuario que emite/captura contratos en el módulo de emisión (Chile).
- Ministerio de Transportes de Chile (origen del nuevo formato de matriculación).

## Riesgos / pendientes
- Definir si el guion es obligatorio/opcional y el manejo de mayúsculas/espacios.
- Confirmar si aplica a otros módulos además de emisión (búsqueda, averías, reportes).
- Convivencia de ambos formatos (vehículos antiguos con LLLL-NN siguen siendo válidos).

## Fechas / hitos
- Nuevo formato entra en vigor 2H 2026; matriculación inicia a partir de **agosto 2026**.
- Urgente por la entrada en vigor inminente.
