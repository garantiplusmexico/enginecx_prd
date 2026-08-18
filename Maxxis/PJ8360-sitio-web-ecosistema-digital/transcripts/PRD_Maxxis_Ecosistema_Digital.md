| ![](data:image/png;base64...)  **DOCUMENTO DE REQUERIMIENTOS DE PRODUCTO**  Sitio Web + Ecosistema Digital Maxxis  México y América Latina    Cliente: Grupo Maxxis · Antonio (Líder de Mercadotecnia, México y LatAm)  Área responsable: Go Virtual — Oficina de Proyecto  Tipo de proyecto: Feature web/API  Versión v0.1 · 14 de julio de 2026 |
| --- |

PRD — Sitio Web + Ecosistema Digital Maxxis México/LatAm

| **Campo** | **Detalle** |
| --- | --- |
| Proyecto | Sitio Web + Ecosistema Digital — Maxxis México/LatAm |
| Área / empresa | Go Virtual (Oficina de Proyecto) — Cliente: Grupo Maxxis |
| Versión | v0.1 |
| Fecha | 14 de julio de 2026 |
| Autores | Equipo de Oficina de Proyecto, Go Virtual |
| Revisión / liderazgo | Aldo Álvarez, Director de TI |
| Tipo de proyecto | Feature web/API |

1. Resumen ejecutivo

Este proyecto consiste en el desarrollo de un sitio web propio para Grupo Maxxis, exclusivo para las operaciones de México y América Latina, que hoy no cuenta con un canal digital unificado en la región. El sitio debe servir a dos audiencias distintas: el consumidor final, con fines informativos y de generación de interés/adquisición, y el distribuidor, mediante un portal de acceso restringido orientado a capacitación continua y consulta de material de producto.

Hoy Maxxis no cuenta con un sitio adaptado a la región ni con un sistema CRM para la gestión de leads. Esta ausencia limita la trazabilidad de los contactos comerciales generados y no ofrece a los distribuidores un canal formal de capacitación y consulta de materiales. El proyecto responde a un driver de negocio concreto: Maxxis busca salir en vivo con el nuevo sitio el 30 de septiembre.

El MVP cubrirá: sitio informativo para consumidor final, **catálogo público de más de 400 artículos**, mapa interactivo de sucursales/distribuidores, portal exclusivo de distribuidor con repositorio de material descargable (documentos, videos y guías, sin seguimiento de progreso ni evaluaciones), y formularios de contacto y cotización. **Quedan para una fase posterior la integración de un CRM** y el desarrollo de una plataforma de e-learning formal con seguimiento de progreso.

El resultado esperado es que Maxxis **cuente con un ecosistema digital propio** para la región, que fortalezca la relación con distribuidores mediante capacitación centralizada, mejore la experiencia informativa del consumidor final, y siente las bases (contenido, estructura de datos, tráfico) para incorporar un CRM y una plataforma de e-learning en una fase posterior.

**Consumidor visita el sitio → Explora catálogo y mapa de sucursales → Distribuidor accede a portal restringido → Consulta material de capacitación**

2. Contexto y problema

Actualmente Maxxis no tiene un sitio web propio para México y América Latina. La información de producto y de sucursales no está centralizada en un canal digital regional, y no existe un sistema CRM para gestionar los leads generados por interés comercial.

El dolor concreto identificado es doble: (1) falta de un canal informativo adaptado a la región para el consumidor final, y (2) ausencia de un espacio formal de capacitación y consulta de material para el personal de los distribuidores, lo que hoy limita su nivel de conocimiento de producto y la consistencia de la experiencia que ofrecen.

El proyecto se resuelve ahora por un driver de negocio con fecha definida: Maxxis busca el lanzamiento del sitio el 30 de septiembre. Antonio, como líder de mercadotecnia de la región, es quien lidera la decisión, aunque importadores y distribuidores también influyen en ella.

Distinción clave del dominio: el proyecto reconoce dos audiencias con necesidades y niveles de acceso distintos dentro del mismo sitio — el consumidor final, que interactúa con contenido público orientado a la adquisición, y el distribuidor, cuyo personal accede a una zona restringida orientada a capacitación continua y consulta de material. Esta distinción determina el esquema de accesos y la arquitectura de información del sitio.

3. Objetivo del producto

Dar a Maxxis México/LatAm un **sitio web** propio que informe al consumidor final y sirva como portal de capacitación y recursos para distribuidores.

**3.1 ESTRATEGIA DE IMPLEMENTACIÓN POR FASES**

| **Fase** | **Nombre** | **Descripción** |
| --- | --- | --- |
| Fase 1 (MVP) | Sitio Web y Portal de Distribuidor | Sitio informativo para consumidor final, catálogo público de productos, mapa interactivo de sucursales, portal exclusivo de distribuidor con repositorio de material descargable, y formularios de contacto/cotización. |
| Fase 2 | CRM y Plataforma de E-learning | Integración de un sistema CRM (aún en evaluación por Maxxis) para gestión de leads, y desarrollo de una plataforma de e-learning formal con seguimiento de progreso y evaluaciones para distribuidores. |

*El MVP de este PRD corresponde a la Fase 1.*

4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Consumidor final | Visita el sitio con fines informativos y de adquisición de producto; utiliza el mapa interactivo para localizar sucursales/distribuidores. |
| Distribuidor (personal) | Accede a la zona restringida del portal para consultar material de producto y capacitación continua; el acceso es exclusivo para personal autorizado del distribuidor. |
| Maxxis (Antonio / equipo de marketing) | Provee y actualiza el contenido del sitio (información de producto, material de capacitación, datos de sucursales); cuenta con acceso de lectura sobre el contenido publicado. |
| Go Virtual (equipo de proyecto) | Carga y actualiza el contenido proporcionado por Maxxis en el sitio; cuenta con permisos de edición; ofrece mantenimiento mensual post-lanzamiento. |

5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Sitio informativo | Páginas de producto y marca orientadas al consumidor final, con fines de **generar interés y adquisición.** |
| Catálogo público de productos | **Catálogo navegable** de más de 400 artículos de Maxxis, visible a cualquier visitante del sitio. |
| Mapa interactivo de sucursales | **Localizador de sucursales/distribuidores para México y LatAm,** con datos de dirección, coordenadas, horarios, teléfono, WhatsApp, redes sociales y correo de contacto por distribuidor y departamento. |
| Portal exclusivo de distribuidor | **Zona de acceso restringido**, separada del contenido público, exclusiva para personal autorizado de distribuidores. |
| Repositorio de material de capacitación | Documentos, videos y guías descargables y organizados dentro del portal de distribuidor, sin seguimiento de progreso ni evaluaciones (no es un LMS). |
| Formularios de contacto y cotización | Captura básica de leads (nombre, contacto, mensaje/producto de interés) mediante formularios de cotización y contacto; sin integración a CRM en esta fase. |
| Gestión de contenido | Go Virtual carga y actualiza el contenido público y del portal de distribuidor proporcionado por Maxxis. |

El principio rector de este MVP prioriza contar con un canal digital propio y funcional para la región antes del 30 de septiembre, apoyado en contenido existente de Maxxis. El MVP no incorpora automatización del alta de distribuidores, no gestiona leads mediante un CRM, y no ofrece una plataforma de e-learning con seguimiento formal — estas decisiones quedan para la Fase 2. El principio rector definitivo, en términos de qué decisiones críticas no debe tomar el sistema, está pendiente de validar con Antonio (ver sección 14).

6. Fuera de alcance

* Integración de CRM: se excluye del MVP; Maxxis aún evalúa opciones. Se habilitará en la Fase 2, una vez seleccionada la herramienta.
* Plataforma de e-learning (LMS con seguimiento y evaluaciones): se excluye del MVP; el portal de distribuidor solo ofrece material descargable/organizado. El LMS completo se desarrollará en la Fase 2.
* E-commerce / compra en línea: fuera de alcance; el sitio es informativo y dirige al distribuidor físico, sin venta directa en línea.
* Automatización del alta de distribuidores: fuera de alcance en el MVP; el alta es manual/curada por Maxxis. Un flujo de aprobación automatizado podría evaluarse una vez definido el mecanismo de validación de acceso.

8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Sitio informativo público | El sitio debe mostrar contenido informativo de marca/producto orientado a consumidor final. |
| RF-02 | Catálogo público de productos | El sitio debe mostrar un catálogo navegable de los más de 400 artículos de Maxxis, visible a cualquier visitante. |
| RF-03 | Mapa interactivo de sucursales/distribuidores | El sitio debe permitir localizar sucursales/distribuidores en México y LatAm mediante un mapa interactivo, con datos de dirección, coordenadas, horarios, contacto y redes por distribuidor y departamento. |
| RF-04 | Portal de acceso restringido para distribuidores | El sitio debe contar con una zona de acceso controlado, separada del contenido público, exclusiva para personal de distribuidores. |
| RF-05 | Alta de distribuidor (manual) | El acceso al portal de distribuidor debe darse mediante alta manual/curada por Maxxis. El mecanismo exacto de validación está pendiente de definir (ver sección 14). |
| RF-06 | Repositorio de material de capacitación | Dentro del portal de distribuidor debe existir un repositorio organizado de documentos, videos y guías, sin seguimiento de progreso ni evaluaciones. |
| RF-07 | Gestión de contenido | Go Virtual debe poder cargar y actualizar el contenido que Maxxis proporciona, tanto público como del portal de distribuidor. |
| RF-08 | Formularios de contacto y cotización | El sitio debe incluir formularios de cotización y contacto que capturen datos básicos del lead (nombre, contacto, mensaje/producto de interés), sin integración a CRM en esta fase. El detalle final de estos formularios está pendiente de validar con Maxxis (ver sección 14). |

9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Disponibilidad 24/7 | El sitio público debe estar disponible de forma continua, sin ventanas de mantenimiento que afecten el acceso del consumidor final. |
| RNF-02 | Capacidad de almacenamiento | El sitio debe soportar la migración y alojamiento de aproximadamente 4TB de material existente (documentos, videos, imágenes de producto). |
| RNF-03 | Separación de acceso público/restringido | El contenido del portal de distribuidor debe estar aislado del contenido público, con un control de acceso propio. |
| RNF-04 | Privacidad de datos de distribuidor | Pendiente de definir. El portal maneja datos de personal de distribuidores (nombre, correo); se debe validar con Maxxis si aplica alguna normativa de privacidad regional (ver sección 14). |
| RNF-05 | Escalabilidad de catálogo | El catálogo debe soportar más de 400 artículos y su crecimiento futuro sin degradar el desempeño de navegación. |

10. Integraciones y datos

El MVP no integra con un sistema CRM ni con otros sistemas externos; opera de forma independiente (standalone). Maxxis se encuentra evaluando opciones de CRM para incorporar en la Fase 2.

**DATOS MÍNIMOS REQUERIDOS**

* Distribuidor: nombre y departamento
* Dirección completa, ubicación y coordenadas (para el mapa interactivo)
* Horarios de atención
* Teléfono y WhatsApp
* Redes sociales
* Correo(s) de destino para leads
* Catálogo: más de 400 artículos de producto

Esquema de permisos: Go Virtual cuenta con permisos de edición y carga de contenido sobre el sitio; Maxxis cuenta con acceso de solo lectura sobre el contenido publicado. El mecanismo de validación de acceso del distribuidor final al portal restringido está pendiente de definir (ver sección 14).

11. Eventos para BI

* catálogo\_artículo\_visto: se registra cuando un visitante abre la ficha de un producto del catálogo.
* mapa\_sucursal\_consultada: se registra cuando un visitante busca o selecciona una sucursal en el mapa interactivo.
* distribuidor\_material\_descargado: se registra cuando un distribuidor autenticado descarga un documento o video del repositorio de capacitación.
* distribuidor\_acceso\_otorgado: se registra cuando Maxxis o Go Virtual da de alta a un nuevo distribuidor en el portal restringido.

Cada evento debe incluir como mínimo: fecha/hora, identificador de usuario o sesión, identificador del recurso consultado, y resultado de la acción.

12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Cumplimiento de fecha de lanzamiento | El sitio debe salir en vivo el 30 de septiembre — métrica binaria (se cumple / no se cumple). |
| Tráfico al sitio | Medido mediante reporte de analítica web (visitas, sesiones). Línea base y meta pendientes de validar con Maxxis/BI. |
| Leads generados | Número de leads capturados vía formularios de cotización y contacto. Línea base y meta pendientes de validar. |

13. Riesgos y supuestos

**RIESGOS**

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Deadline ajustado | El levantamiento formal con Maxxis inicia esta semana y el lanzamiento es el 30 de septiembre, dejando una ventana corta para definir, desarrollar y migrar contenido. |
| Migración de material existente (~4TB) | Sin claridad sobre la organización/etiquetado del material, puede haber retrabajo en la carga y estructuración del repositorio. |
| Mecanismo de acceso de distribuidor sin definir | Puede atrasar el desarrollo del portal restringido si no se resuelve a tiempo. |
| Ausencia de CRM definido | Sin CRM, la gestión de leads generados por los formularios dependerá de procesos manuales, con riesgo de pérdida de trazabilidad. |
| Falta de experiencia previa en plataformas de e-learning | Riesgo relevante para la Fase 2; puede generar expectativas mal alineadas si no se acota bien desde ahora. |
| Disponibilidad real de material de capacitación/e-learning | Se menciona la incorporación de e-learning, pero no está confirmado que Maxxis cuente ya con el material requerido. |
| Falta de contenido gráfico personalizado | Si Maxxis no cuenta con equipo de diseño propio, puede haber dependencia de contenido genérico o de sitios de referencia de terceros. |
| Tiempos administrativos previos a implementación | El llenado del setup doc, la generación y presentación de la propuesta, y la firma de contrato pueden consumir tiempo de la ventana de implementación disponible antes del 30 de septiembre. |

**SUPUESTOS**

| **Supuesto** | **Descripción** |
| --- | --- |
| Entrega oportuna de material y setup doc | Maxxis entregará el material (~4TB) y el setup doc de distribuidores/sucursales a tiempo para cumplir el 30 de septiembre. |
| Estabilidad de alcance | No habrá integración de CRM ni cambios de alcance mayores antes del levantamiento formal que afecten el MVP aquí delineado. |
| Disponibilidad de contenido de ventas/gráfico | Se asume que existe contenido de ventas disponible y que parte del contenido gráfico puede rescatarse de sitios de referencia (Toyo Tires, Maxxis Europe) en caso de no contar con diseño propio. |

14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Acceso y permisos de distribuidor | ¿Cuál será el mecanismo definitivo de validación de acceso del distribuidor al portal restringido? Propuesta actual: alta por nombre y correo entregado por el distribuidor, contra su listado de personal activo. |
| Alcance del MVP | ¿Cuál es el principio rector del MVP — qué decisiones críticas no debe tomar el sistema en esta fase? |
| Privacidad y cumplimiento | ¿Existe algún requerimiento de privacidad o normativa regional aplicable al manejo de datos de personal de distribuidores (nombre, correo)? |
| Flujos y experiencia | ¿Cuál es el recorrido detallado del consumidor final y del distribuidor dentro del sitio (entrada, decisiones clave, manejo de excepciones de acceso)? |
| Captura de leads | ¿Cuál es el alcance detallado de los formularios de cotización y contacto (campos, destino del lead sin CRM, proceso de seguimiento manual)? |