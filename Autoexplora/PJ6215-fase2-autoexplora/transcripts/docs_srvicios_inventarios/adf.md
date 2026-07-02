Guía de Generación de Leads: ADF (XML) y Email HTML

Esta sección detalla cómo el sistema transforma los datos recibidos de un formulario en dos formatos esenciales: un archivo XML bajo el estándar ADF para sistemas CRM y un correo HTML diseñado para los vendedores.

1. Generación de ADF (`Auto-lead Data Format`)

El ADF es el lenguaje universal que entienden los CRMs automotrices. Utilizamos la clase ADFGenerator para construir esta estructura.

1.1 Estructura del XML

El archivo generado sigue una jerarquía estricta basada en el estándar industrial:

`<prospect>`: El nodo raíz que define el estado del lead (`normalmente status="new"`).

`<vehicle>`: Contiene el interés del cliente.

Lógica: El sistema detecta si el vehículo es `"nuevo" o "usado"` y asigna el atributo interest (`buy, lease, sell, etc.`).

Normalización: Los campos como year, make y model se limpian para evitar errores de importación.

`<customer>`: Agrupa los datos de contacto y la procedencia del lead.

Campaña: Se inyectan los metadatos de marketing (`UTM_Source, UTM_Medium, etc.`) para que el distribuidor sepa qué anuncio generó la venta.

`<vendor> y <provider>`: Identifican al distribuidor receptor y a GoVirtual como el proveedor del servicio.

1.2 El Mapper y Datos No Documentados

Dado que no todos los formularios son iguales, usamos get_undocumented_fields. Esta utilidad:

Revisa qué campos del formulario no tienen un lugar específico en el estándar ADF (`ej. "Aviso de Privacidad" o "Color Interior"`).

Los formatea como texto plano y los concatena al final del nodo `<comments>`.

Resultado: Ningún dato se pierde, incluso si el estándar XML no tiene una etiqueta para él.

2. Generación de Email HTML

Además del XML, el sistema genera un correo visualmente atractivo para que el equipo de ventas reciba una notificación inmediata.

2.1 Componentes del Email

Diseño Responsivo: Utiliza tablas compatibles con Outlook y dispositivos móviles.

Normalización de Condición: La función normalize_condition elimina acentos y estandariza términos (`ej. "seminuevo", "usado", "pre-owned"`) a una categoría única.

Formateo de Moneda: Los precios se transforman dinámicamente a formato moneda (`ej. 150000 -> $150,000.00`).

Secciones Dinámicas: El método `render_section_table` genera tablas solo para los campos que contienen datos, evitando mostrar filas vacías o con valores "N/A".

3. Extracción de Metadatos (`RegEx`)

Una pieza clave es la función extract_metadata. Muchos leads llegan con comentarios que contienen datos estructurados en formato Clave: Valor.

Uso de Expresiones Regulares: Utilizamos `re.findall(r"^([^:]+):\s*(.+)$", ...)` para escanear el bloque de comentarios.

Utilidad: Esto permite que el sistema "entienda" datos como el kilometraje o el servicio solicitado que vienen escritos dentro de un campo de texto abierto.

4. Flujo de Integración (`LeadIntegrationService`)

El servicio coordina todo el proceso:

Consulta de Configuración: Pregunta a la API de Destinos a dónde debe enviarse el lead según el distribuidor.

Generación Triple: Crea el objeto de base de datos, el archivo ADF y el cuerpo del correo HTML.

Distribución: Envía el correo y/o el XML a los puntos finales (`endpoints`) configurados.

URL del estándar ADF: https://www.adfxml.info/
Guía de expresiones regulares en Python: https://docs.python.org/3/library/re.html