# Condensado — nota-version-vehiculo-reporte

## Decisiones
- Incluir el campo **Version del vehículo** en el reporte Excel de contratos emitidos.

## Alcance / requerimientos
- Agregar la columna **Version del vehículo** al export Excel de contratos emitidos.
- Aplica a **todos los países** (incluye ajuste al export de PaisCL).
- Verificar que el dato exista en el SP `sp_reporte_contratos` o en el modelo `contrato`.
- Posible ajuste a la query SQL si el dato no está expuesto.

## Actores
- Administración / Reportes (consumidores del reporte para análisis interno).

## Riesgos / pendientes
- Confirmar disponibilidad del dato Version en `sp_reporte_contratos` / modelo `contrato`.
- Definir posición de la columna en el Excel y su encabezado.

## Fechas / hitos
- No especificadas. Importancia: Baja | Impacto: Administración / Reportes (sin impacto en captación/fidelización).
