# Condensado — estado-colonia-chile-notas

## Decisiones
- Renombrar headers/etiquetas SOLO para Chile (PaisCL): Estado Beneficiario → Region
  Beneficiario; Colonia → Comuna; RFC → RUT.
- No modificar exports de México ni Colombia.

## Alcance / requerimientos
- Reporte Excel/CSV de contratos de Chile: renombrar los 3 encabezados.
- Ajustar también etiquetas en vistas donde aparezcan "Estado Beneficiario" y "Colonia"
  (principalmente en archivos de descarga/exportación).
- Validar si los headers provienen del SP `sp_reporte_contratos`.

## Actores
- Solicita: Operaciones / Chile.
- Revisión técnica: Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx).
- Consumidores: usuarios internos de Administración / Reportes (Chile).

## Riesgos / pendientes
- Confirmar origen de los headers (SP `sp_reporte_contratos` vs. capa de aplicación/export).
- Delimitar qué "vistas" además del export están afectadas.
- Asegurar que el cambio quede aislado a Chile (no tocar MX/CO).

## Fechas / hitos
- No especificadas. Importancia: Baja.
