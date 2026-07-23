# Nota inicial — Version Vehiculo Reporte

## Problema
El campo Version del vehiculo no se incluye en el reporte Excel de contratos exportado.

## Mejora propuesta
Incluir el campo Version del vehiculo en el reporte Excel de contratos emitidos.

## Consideraciones para desarrollo
Agregar campo Version del vehiculo al export Excel de contratos emitidos (todos los países);
verificar que el dato exista en SP sp_reporte_contratos o modelo contrato; ajustar PaisCL export
y posiblemente query SQL.

## Importancia e impacto de negocio
Importancia: Baja | Impacto: Administracion | Reportes | Campo version en export; enriquece
reportes para analisis interno sin impacto en captacion o fidelizacion.
