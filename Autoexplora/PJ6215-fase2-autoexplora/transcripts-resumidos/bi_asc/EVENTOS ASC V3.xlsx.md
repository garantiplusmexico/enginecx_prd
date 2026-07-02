# Condensado — EVENTOS ASC V3.xlsx

Selección curada por Go Virtual de 13 eventos del estándar ASC (de los 35+ disponibles) que se implementan de forma estándar en sus sitios, incluido Autoexplora — con el detalle específico de parámetros para 4 de ellos.

## Decisiones
- Eventos ASC seleccionados como estándar de medición (nombre → qué mide):
  1. `asc_form_submission` — Envío de formularios generales.
  2. `asc_form_submission_sales` — Envío de formularios de cotización.
  3. `asc_form_submission_service` — Envío de formularios de servicio.
  4. `asc_form_submission_sales_appt` — Envío de formularios de prueba de manejo.
  5. `asc_form_submission_trade` — Envío de formularios de venta (usuario vende su auto al dealer).
  6. `asc_form_engagement` — Interacción en formularios (todos, no es evento de conversión).
  7. `asc_click_to_call` — Interacciones en enlaces de click-to-call.
  8. `asc_cta_interaction` — Interacciones en botones/enlaces/CTAs en general (incluye WhatsApp, comparar, descargar).
  9. `asc_media_interaction` — Interacciones en imágenes con enlace (aplica solo a galería de inventario).
  10. `asc_page_view` — Al visitar una página.
  11. `asc_menu_interaction` — Interacciones con el menú de navegación.
  12. `asc_element_configuration` — Interacciones con elementos que modifican visualmente un componente principal (filtros/búsqueda de inventario, tabs de modelbars).
  13. `asc_special_offer` — Interacciones en la página de promociones.
- Detalle de mapeo confirmado para formularios (`asc_form_submission*`): `form_name`/`form_type` distinguen "cotizar" (ventas), "agendar_prueba_de_manejo" (sales_appt), "vender" (trade/avalúo), "agendar_servicio" (service_appt), "contactar" (contact). El botón de envío usa `element_text` con el texto real mostrado (ej. "Cotiza", "Agendar", "Enviar").
- `asc_cta_interaction` para WhatsApp: `element_type = contact_tool`, `element_color = green`, `event_action_result = redirect`, `link_url` apunta al enlace de WhatsApp específico (ejemplo de referencia de otro sitio Go Virtual, no un dato de Autoexplora).
- `asc_cta_interaction` para "Comparar": `element_text = "Comparar"`, `element_type = compare_tool`, `element_color = blue`, `event_action_result = compare`.
- `asc_cta_interaction` para "Descargar": `element_type = download_tool`, `event_action_result = download`.
- `asc_element_configuration` (Interacciones Widgets): aplica a "cualquier click" en componentes visuales de un widget principal, con ejemplo de uso en colorpicker y hero banner.

## Alcance / requerimientos
- Todos los eventos de item/vehículo comparten el mismo set de parámetros: `item_id` (VIN), `item_number`, `item_price`, `item_condition`, `item_year`, `item_make`, `item_model`, `item_variant`, `item_color`, `item_type`, `item_category`, `item_fuel_type`, `item_inventory_date` — cuando no aplica al tipo de formulario/interacción, se marca explícitamente como "NA" en vez de omitirse.
- `submission_id` en los formularios se resuelve con el `ga_client_id` (ID de Google Analytics del usuario), no con un ID propio del formulario.
- Hoja "Relación Eventos - Parámetros" confirma qué parámetros aplican a cada uno de los 9 eventos principales (todos comparten `page_type`, `event_action_result`, `event_action`, `product_name`, `event_owner` como base).

## Riesgos / pendientes
- Los valores de ejemplo de la hoja de WhatsApp (número, dominio "1001carros.com") son de referencia de otro proyecto de Go Virtual, no datos reales de Autoexplora — deben sustituirse por los números y URLs reales de las agencias de Autoexplora al implementar.
- Los campos `event_action`, `event_action_result`, `event_owner`, `product_name` están marcados como "No estamos seguros que se agreguen" en la hoja de formularios — pendiente de confirmar con el equipo si se incluyen finalmente.

## Componentes técnicos involucrados
- Hojas del archivo: `Eventos` (catálogo), `Parámetros y valores` (diccionario completo), `Relación Eventos - Parámetros` (matriz de aplicabilidad), y hojas de detalle por evento: formularios, WhatsApp, botones CTA, interacciones de widgets.
