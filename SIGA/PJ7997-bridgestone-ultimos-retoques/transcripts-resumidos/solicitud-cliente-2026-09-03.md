# Condensado — solicitud-cliente-2026-09-03

## Decisiones
- Son los "últimos retoques" solicitados por el cliente sobre el ambiente Bridgestone en SIGA (módulo de averías/ajustes).

## Alcance / requerimientos
- Al registrar la avería, el campo "kilometraje" deja de ser obligatorio (se puede dejar en blanco).
- En la opción "varios" (carga de documentos), permitir omitir/quitar la carga de documentos — deja de ser obligatoria.
- Cambiar en todo el sistema (UI: menús, títulos, encabezados de tabla, labels) la palabra "avería"/"Averias" por "ajuste"/"Ajustes", en el ambiente Bridgestone. Incluye pantallas como "Registro de avería" → "Registro de ajuste" y "Averias" (listado) → "Ajustes".

## Actores
- Cliente Bridgestone (solicitante vía el usuario/PM).
- Usuarios del módulo: distribuidores/talleres que registran averías/ajustes en SIGA.

## Riesgos / pendientes
- Confirmar alcance exacto del cambio de terminología: ¿solo UI (labels visibles) o también nombres de menú/rutas/exportables (PDF, reportes)? El transcript solo referencia "pantallazos" (UI visible).
- Confirmar si "kilometraje opcional" implica seguir mostrando el campo (solo sin validación de obligatoriedad) o si se oculta.
- Confirmar si "omitir documentos en varios" aplica solo a esa opción específica o a la carga de documentos en general del flujo de registro.

## Fechas / hitos
- Solicitud recibida: 2026-09-03.
