# Condensado — docs_srvicios_inventarios/service_leads_generator.md

## Decisiones
- El enrutamiento de cada lead (a qué correo/CRM llega y en qué formato) NO es fijo en código: se consulta en tiempo real a una API externa llamada **Mayam** (`DestinationClient`, autenticada vía `x-mayam-token`) usando el `vendor_id` del distribuidor/agencia.
- Según el tipo de integración que Mayam indique para ese vendor (`defaultText`, `careerApplications`, `defaultADF`, `eLead`), el sistema decide si genera un email HTML (`EmailHTMLGenerator`) o un XML ADF (`ADFGenerator`), o ambos.
- Cada envío queda auditado: se genera un `submission_id` único (hash MD5) y se guarda un registro `LeadAudit` en estado `pending` en base de datos ANTES de distribuir — esto da trazabilidad de todo lead que entra al sistema, incluso si el envío final falla.
- La extracción de destinatarios (`_extract_emails`) sigue una jerarquía de prioridades anidada dentro de la configuración de Mayam, agrupada por departamento y por "grupos de destinos".
- El HTML del correo cambia colores/logos dinámicamente según el tipo de producto (`BRICK` o `GRID`) — es decir, la plantilla ya está preparada para servir a más de una plataforma/marca de Go Virtual, no solo Autoexplora.
- `LeadMapper.to_bigquery` aplana y castea tipos del JSON original (fechas, precios a float) para que BigQuery pueda insertarlo sin problemas de schema — este es el mecanismo real detrás de cualquier reporte/dashboard de leads en BI.

## Alcance / requerimientos
- Arquitectura de 5 clases: `LeadIntegrationService` (orquestador), `DestinationClient` (API Mayam), `ADFGenerator`, `EmailHTMLGenerator`, `LeadMapper`.
- `get_undocumented_fields` (recursivo) detecta cualquier clave del JSON de entrada que no esté en el set de campos ya mapeados y la anexa como texto — mismo mecanismo de "no perder datos" descrito en adf.md.
- Extracción de metadatos ocultos en comentarios de texto libre vía RegEx (`extract_metadata`/`extract_comments`), útil cuando plataformas externas inyectan variables dentro de un textarea de "Comentarios".

## Riesgos / pendientes
- Este flujo de auditoría (`LeadAudit` en estado `pending`) es exactamente el mecanismo que podría resolver el problema histórico de "pérdida de leads silenciosa" documentado en el contexto de negocio/técnico (Intelimotor respondía "OK" sin procesar realmente) — vale la pena confirmar si ya existe un proceso que reconcilie los registros `pending` vs. confirmados, o si es un hueco a cubrir.
- La dependencia de la API de Mayam para TODO el enrutamiento es un punto único de fallo: si Mayam no responde o su configuración para un `vendor_id` está mal, el lead no sabe a dónde ir.

## Componentes técnicos involucrados
- `LeadIntegrationService`, `DestinationClient` (API Mayam), `ADFGenerator`, `EmailHTMLGenerator`, `LeadMapper` (incluye integración con BigQuery), tabla/modelo `LeadAudit`.
