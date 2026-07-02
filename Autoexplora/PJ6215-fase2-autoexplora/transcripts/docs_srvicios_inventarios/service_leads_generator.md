# Documentación del Servicio: Leads Integration & Generators

## Descripción General
El módulo de `Leads` concentra toda la lógica de negocio para la captura, transformación y enrutamiento de prospectos comerciales. Su objetivo principal es recibir un JSON estandarizado, consultar las reglas de ruteo y configuración del concesionario desde una API externa (Mayam), formatear la información en el estándar requerido (**XML ADF** o **HTML**), mapear los datos para análisis (BigQuery) y preparar la auditoría para la base de datos.

---

## Arquitectura del Módulo

El código está dividido en 5 responsabilidades clave (Clases):

1.  **`LeadIntegrationService`**: Orquestador principal que consolida todo el flujo.
2.  **`DestinationClient`**: Cliente HTTP para interactuar con la API de configuración externa.
3.  **`ADFGenerator`**: Generador del estándar XML (Auto Dealer Format) para CRMs automotrices.
4.  **`EmailHTMLGenerator`**: Generador de plantillas HTML dinámicas para correos electrónicos.
5.  **`LeadMapper`**: Herramienta de transformación de datos (BigQuery y utilidades).

---

## Componentes Principales

### 1. `LeadIntegrationService` (Orquestador)
Servicio principal consumido por el controlador (`submit_lead`).

*   **`prepare_and_save_audit(session, form_json)`**:
    *   **Flujo:** 
        1. Genera un ID de seguimiento único (`submission_id`) vía hash MD5.
        2. Llama a `DestinationClient` para obtener las reglas de ruteo del `vendor_id`.
        3. Identifica el tipo de integración requerida (`defaultText`, `careerApplications`, `defaultADF`, `eLead`).
        4. Si es texto/HTML, delega la creación a `EmailHTMLGenerator`. Si es ADF, delega a `ADFGenerator`.
        5. Extrae la lista de destinatarios basándose en el departamento (`_extract_emails`).
        6. Crea y guarda el registro `LeadAudit` en estado `pending` en la base de datos.
    *   **Retorna:** Tupla con `(audit_object, payload_generado, lista_emails, is_html_boolean)`.

### 2. `DestinationClient`
*   Realiza peticiones `GET` a la API de Mayam (`DESTINATIONS_ENDPOINT`) enviando el `vendor_id` y validando acceso vía `x-mayam-token`. Retorna el JSON de configuración para determinar adónde y en qué formato se enviará el lead.

### 3. Generadores de Formato

#### `ADFGenerator`
Crea el estándar XML ADF v1.0, fuertemente utilizado en la industria automotriz para inyección directa a CRMs (Seekop, eLead, etc.).
*   **Construcción del Nodo:** Genera dinámicamente los nodos `<prospect>`, `<vehicle>`, `<customer>`, `<vendor>` y `<provider>`.
*   **Inyección de Datos No Mapeados:** Utiliza `get_undocumented_fields` para encontrar campos extraños en el JSON original y los adjunta como texto plano dentro de la etiqueta `<comments>`. Esto garantiza que nunca se pierda información (ej. preguntas personalizadas de formularios).

#### `EmailHTMLGenerator`
Genera una plantilla de correo profesional en formato HTML.
*   **Renderizado Dinámico:** Implementa la función interna `render_section_table` que solo dibuja en el HTML las filas que contienen información válida (ignora campos `null`, `n/a`, vacíos).
*   **Estilos y Logos:** Cambia dinámicamente los colores y logotipos basándose en el tipo de producto (`BRICK` o `GRID`).
*   **Normalización de Textos:** Implementa `normalize_condition()` para estandarizar etiquetas (ej. detecta "used", "seminuevo", "preowned" y los normaliza a "Seminuevo").

### 4. `LeadMapper`
Clase encargada de la transformación y preparación de datos sin procesar.

*   **`to_bigquery(form_data)`**: Convierte la estructura anidada del JSON original a un diccionario plano estandarizado. Realiza el cast de tipos (ej. parsea fechas, float en precios) para que Google BigQuery pueda insertar las filas sin problemas de schema.
*   **`get_undocumented_fields(form_data)`**: Función recursiva vital. Mantiene un Set de claves conocidas (`already_mapped`). Recorre todo el JSON, detecta claves que no están en el Set, y las devuelve formateadas en texto.

### 5. Utilidades Independientes
*   **`extract_metadata(raw_text)` / `extract_comments(raw_text)`**: Expresiones regulares multilínea (`^([^:]+):\s*(.+)$` y lookaheads) utilizadas para separar el cuerpo de un comentario de metadatos ocultos formateados como `Key: Value`. Útil cuando plataformas externas inyectan variables invisibles dentro del textarea de "Comentarios".

---

## Lógica de Enrutamiento (Routing Rules)

La extracción de correos (`_extract_emails`) utiliza una jerarquía de prioridades anidada desde la configuración de Mayam:

1.  Determina el **módulo principal** habilitado (Ej. `defaultADF` o `careerApplications`).
2.  Itera sobre los **grupos de destinos** (`destinations