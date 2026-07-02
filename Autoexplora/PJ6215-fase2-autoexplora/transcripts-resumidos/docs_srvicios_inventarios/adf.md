# Condensado — docs_srvicios_inventarios/adf.md

## Decisiones
- El sistema genera, para cada lead recibido, dos salidas en paralelo: un XML bajo el estándar ADF (Auto-lead Data Format, estándar universal de CRMs automotrices) y un correo HTML para el equipo de ventas.
- Normalización aplicada antes de generar cualquier salida: condición del vehículo ("seminuevo"/"usado"/"pre-owned" → categoría única), formato de moneda (150000 → $150,000.00), y limpieza de year/make/model para evitar errores de importación en el CRM destino.
- Ningún dato se pierde aunque el estándar ADF no tenga una etiqueta para él: los campos no documentados (ej. "Aviso de Privacidad", "Color Interior") se formatean como texto plano y se concatenan al nodo `<comments>` (función `get_undocumented_fields`).
- El email HTML solo dibuja secciones/filas que tienen datos reales (`render_section_table`), evitando mostrar campos vacíos o "N/A".
- Metadatos ocultos dentro de comentarios de texto libre (ej. kilometraje, servicio solicitado escrito en formato "Clave: Valor") se extraen vía RegEx (`extract_metadata`), permitiendo capturar información aunque no venga en un campo estructurado.

## Alcance / requerimientos
- Estructura del XML ADF: `<prospect>` (estado del lead, ej. status="new"), `<vehicle>` (interés: buy/lease/sell, condición nuevo/usado), `<customer>` (contacto + metadatos UTM de campaña), `<vendor>`/`<provider>` (distribuidor receptor y Go Virtual como proveedor).
- El flujo de integración (`LeadIntegrationService`) coordina: consulta de configuración de destino según distribuidor → generación triple (objeto BD + XML ADF + HTML) → distribución a los endpoints configurados.

## Riesgos / pendientes
- Cualquier campo nuevo que se agregue a futuros formularios y no esté mapeado en el estándar ADF caerá automáticamente en `<comments>` como texto plano — relevante si se evalúa que un campo debería tener tratamiento estructurado propio en el CRM destino.

## Componentes técnicos involucrados
- `ADFGenerator` (construcción del XML), normalización de condición y moneda, `render_section_table` (email HTML), `extract_metadata`/RegEx, `LeadIntegrationService` (orquestador).
- Referencias externas: estándar ADF (adfxml.info), documentación RegEx de Python.
