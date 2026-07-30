# PRD - Frontend Mesa de Control

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Frontend Mesa de Control |
| **Área / empresa** | Gplus Seguros |
| **Versión** | v0.1 |
| **Fecha** | 28 de julio de 2026 |
| **Autores** | Omar André Lara Saldaña |
| **Revisión / liderazgo** | Aldo Álvarez (Director de TI), Norma Zacarias (responsable del área) |
| **Tipo de proyecto** | Feature web |

## 1. Resumen ejecutivo

El Frontend Mesa de Control es una interfaz web interna para el equipo de Mesa de Control de Gplus Seguros (Keynor Rivas y Pati, bajo la responsabilidad de Norma Zacarias), donde cada petición que hoy llega por el formulario de Google se trabaja como un caso individual en lugar de como una fila entre miles.

Hoy las agencias levantan sus peticiones —cotizaciones, emisiones, endosos, altas de versión— a través de un formulario de Google cuyas respuestas caen en una hoja de cálculo con más de cien columnas. Sobre ese mismo archivo la mesa registra el seguimiento: quién tomó el caso, en qué proceso está, con qué aseguradora, qué folio se generó y qué observaciones acumula. Los adjuntos viven en Google Drive y la conversación con el solicitante ocurre por fuera, en correo y a veces WhatsApp. Atender una sola petición obliga a desplazarse entre columnas distantes, copiar enlaces que llegan como texto plano, salir al correo para redactar la respuesta y volver a la hoja para dejar constancia.

El costo de ese ir y venir es doble: consume el tiempo de la mesa —con ~10-15 peticiones diarias y dos o tres idas y vueltas por caso, porque casi siempre falta un documento— y arriesga la integridad del registro, ya que en una hoja de esa anchura es fácil anotar la información de un caso en la fila de otro. A esto se suma que al equipo ya se le exige reporteo semanal, que hoy se arma exportando, borrando columnas y construyendo una tabla dinámica a mano.

El MVP resuelve un solo problema, pero completo: concentrar en una pantalla todo lo que hace falta para atender un caso —los campos que sí aplican a ese trámite, sus adjuntos accesibles con un clic, la conversación con el solicitante y las notas de seguimiento— y escribir cada cambio de vuelta en la hoja de cálculo, que se conserva como fuente única de datos. Para que la conversación quede vinculada al caso sin depender de búsquedas manuales, es la herramienta la que abre el hilo de correo, con asunto normalizado (`Resolución Caso #<folio>`) y destinatario tomado del propio formulario. El reporteo automatizado queda para la Fase 2 y las peticiones de siniestros para la Fase 3.

El resultado esperado es que la mesa deje de saltar entre cuatro herramientas por cada petición, que ningún caso quede fuera de vista, que exista trazabilidad de quién cambió qué, y que todo esto ocurra sin alterar en absoluto la forma en que las agencias piden ni el método con el que Keynor genera hoy sus reportes.

**Petición en formulario** → **Caso en bandeja** → **Se toma y se abre conversación** → **Seguimiento y notas** → **Guardar cambios en la hoja** → **Cierre del caso**

## 2. Contexto y problema

**Cómo funciona hoy.** El solicitante (una agencia, propia de la financiera de Autocom o externa) llena un formulario de Google extenso que contempla todos los tipos de trámite. Cada respuesta genera una fila en una hoja de cálculo de Google con más de cien columnas, donde cada tipo de trámite tiene su propia celda de adjuntos: si es cotización el archivo cae en una columna, si es emisión en otra, si es endoso en otra. La mesa trabaja directamente sobre esa hoja: localiza la petición, abre los adjuntos en Drive, identifica al solicitante y su correo, sale a su cliente de correo para responder citando el folio, atiende el trámite con la aseguradora y regresa a la hoja a registrar estatus, semáforo, responsable, aseguradora, folio generado y observaciones. El volumen es de ~10-15 peticiones diarias y el archivo acumula años de histórico. Cuando hace falta un reporte, Keynor exporta el rango del mes, elimina las columnas que no usa y arma una tabla dinámica.

**El dolor concreto.** Los campos que se necesitan para un mismo trámite están dispersos: el de alta de versión puede estar en la columna 90, la cotización en la 30 y el correo del peticionario en la 50. Desplazarse entre ellos toma tiempo y, sobre todo, expone a perder la referencia de la fila y anotar la información de un caso en el renglón de otro. Norma ocultó las columnas vacías para aliviar la navegación, pero siguen existiendo y reaparecen al exportar. Los enlaces de Drive con frecuencia caen a la hoja como texto plano, de modo que hay que seleccionarlos, copiarlos y abrirlos aparte. La conversación con el solicitante vive fuera del registro, así que reconstruir el estado de un caso implica cruzar hoja, correo y WhatsApp. Y como casi siempre falta el checklist, la factura o un dato como el código postal, cada caso arrastra dos o tres intercambios antes de poder cerrarse.

**Por qué ahora.** Al equipo completo ya se le pide reporteo semanal, y armarlo hoy es un proceso manual sobre un archivo que no fue diseñado para eso. El tiempo que la mesa pierde saltando entre canales es tiempo que no dedica a resolver trámites. Y el área no puede crecer ni incorporar gente sobre una hoja de cálculo con años de histórico y cien columnas: el método ya llegó a su techo.

**Distinción de dominio obligatoria.** El equipo de desarrollo debe distinguir desde el día 1 dos entidades que en la conversación operativa se nombran igual:

- **Folio de petición**: el número con el que la petición llega desde el formulario (por ejemplo, 6886). Es el identificador del caso dentro de la mesa, es el que la agencia ya conoce y es el que se usa en el asunto del correo.
- **Folio de aseguradora**: el número que genera la aseguradora durante el trámite y que la mesa registra en el seguimiento del caso. No identifica el caso; es un dato de resultado y un caso puede no tenerlo.

## 3. Objetivo del producto

Dotar a la Mesa de Control de Gplus Seguros de una interfaz web propia donde cada petición recibida por el formulario de Google se trabaje como un caso individual —con sus datos relevantes, sus adjuntos, la conversación con el solicitante y las notas de seguimiento en un solo lugar—, eliminando el salto entre hoja de cálculo, correo, WhatsApp y Drive, y manteniendo el Google Sheets actual como fuente única de datos para no romper el reporteo existente.

La mejora esperada es una reducción del tiempo de atención por caso y de la carga cognitiva de la mesa, con trazabilidad de cada cambio y sin ninguna alteración en la experiencia del solicitante.

### 3.1 Estrategia de implementación por fases

| **Fase** | **Nombre** | **Descripción** |
| --- | --- | --- |
| Fase 1 | Vista de caso único (MVP) | Bandeja de casos y vista individual con los campos aplicables, adjuntos accesibles, conversación de correo iniciada y respondida desde la herramienta, notas de seguimiento y escritura explícita de vuelta a la hoja de cálculo. |
| Fase 2 | Reporteo | Sustituir el armado manual de la tabla dinámica por reportes generados desde la herramienta, apoyándose en los eventos y datos que el MVP ya produce. |
| Fase 3 | Siniestros | Adaptar o extender la herramienta al caso de las peticiones de siniestros (Juan), una vez validado el funcionamiento con la mesa. |

**La Fase 1 es el MVP de este PRD.** Las fases 2 y 3 no tienen fecha comprometida; su arranque depende de la validación operativa de la Fase 1.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Keynor Rivas (Mesa de Control) | Usuario principal. Atiende las peticiones diarias, da seguimiento con aseguradoras y solicitantes, y genera los reportes del área (por ejemplo, para comité con CAF). |
| Pati (Mesa de Control) | Usuaria de la herramienta. Atiende peticiones y continúa casos iniciados por Keynor, por lo que depende de las notas de seguimiento y de saber quién tomó cada caso. |
| Norma Zacarias (responsable del área) | Solicitante del proyecto. Define la prioridad y pone como condición que se facilite el trabajo diario sin dificultar el reporteo. |
| Juan / Juanjo (Siniestros) | Usa el mismo formulario con un volumen bajo de peticiones. Fuera del alcance del MVP, pero su presencia obliga a que las columnas de siniestros sigan existiendo en la hoja de cálculo. |
| Agencias solicitantes | Levantan las peticiones por el formulario de Google y responden por correo o WhatsApp. No usan la herramienta ni perciben su existencia. |
| Aseguradoras (Quálitas, Latino, entre otras) | Destino de los trámites; determinan los tiempos de resolución y emiten el folio de aseguradora. |
| TI Engine (Omar Lara, Aldo Álvarez) | Desarrollo, decisiones técnicas y dirección del proyecto. |
| Administrador de Google Workspace | Habilita la cuenta de servicio, los permisos sobre la hoja y la carpeta de Drive, y el consentimiento OAuth del buzón compartido. |
| Proveedor externo de la plataforma Sigma | Dueño del desarrollo de esa plataforma. Fuera del alcance del MVP; sería contraparte si en el futuro se requiere el reporte por aseguradora. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Bandeja de casos | Lista de las peticiones recibidas de 2026 en adelante, ordenadas de la más reciente a la más antigua por fecha y hora de recepción, mostrando el estatus actual de cada caso. Ningún caso queda oculto. |
| Búsqueda y filtros | Localizar casos por folio de petición, solicitante, agencia, tipo de trámite, estatus y responsable, sin recorrer la lista completa. |
| Vista de caso individual | Al abrir un caso se muestran únicamente los campos que traen dato, de modo que un trámite de cotización no arrastre las columnas de emisión, endoso o siniestros. |
| Adjuntos como enlaces | Todo enlace de Drive del caso se presenta siempre como enlace clicable, nunca como texto plano: se abre con un clic sin copiar ni pegar. |
| Captura de seguimiento | Edición de los campos que hoy llena la mesa: estatus del trámite, semáforo, responsable, aseguradora, si el solicitante podía hacerlo por su cuenta, motivo de la petición a mesa, folio de aseguradora y observaciones. |
| Guardar cambios | Los cambios se escriben en la fila correspondiente de la hoja de cálculo solo cuando la persona lo confirma explícitamente, no de forma automática mientras captura. |
| Bloqueo de caso en edición | Cuando alguien abre un caso para editarlo, queda marcado como tomado por esa persona y los demás no pueden guardar sobre él, evitando que dos personas se sobreescriban. |
| Iniciar conversación | La herramienta envía el correo de apertura del caso desde el buzón compartido de la mesa, con asunto normalizado `Resolución Caso #<folio de petición>` y destinatario tomado del formulario. La mesa no teclea ni el correo ni el asunto. |
| Hilo de correo en el caso | La conversación del caso se muestra en orden cronológico dentro de la vista, vinculada de forma persistente al caso desde el momento en que la herramienta la abre. |
| Responder en el hilo | Responder al solicitante desde el propio caso, conservando asunto y destinatarios, sin salir a otro cliente de correo. |
| Bitácora de observaciones | Registro acumulativo de notas internas con autor y fecha, para que otra persona pueda retomar un caso a medias (el uso real que hoy tiene el campo de observaciones). |
| Importación bajo demanda | Incorporar periodos anteriores a 2026 únicamente cuando se solicite de forma explícita, caso por caso o por rango. |

**Principio rector del MVP.** Cuatro cosas no se rompen: (1) la hoja de cálculo es la fuente única de datos, así que ningún seguimiento confirmado vive solo dentro de la herramienta y el reporteo de la mesa nunca depende del nuevo sistema; (2) nada cambia para el solicitante, que sigue usando el mismo formulario y recibiendo correos; (3) la herramienta no decide el trámite —no clasifica, no autoriza ni cierra casos por su cuenta—, solo concentra información y ejecuta acciones que la mesa dispara; (4) ningún caso se pierde de vista: todo caso recibido aparece en la bandeja con su estatus visible.

## 6. Fuera de alcance

- **Reporteo automatizado y sustitución de la tabla dinámica**: es el objetivo de la Fase 2. El MVP se compromete a no complicar el reporteo actual, no a reemplazarlo; se habilita cuando la Fase 1 esté validada y se defina el reporte exacto.
- **Peticiones de siniestros (Juan / Juanjo)**: Fase 3. Primero se valida que el modelo funcione con la mesa antes de adaptarlo a un flujo con dueño y volumen distintos.
- **Integración de los reportes de la plataforma Sigma**: el desarrollo de esa plataforma pertenece a un proveedor externo que debe habilitar primero el reporte con el desglose por aseguradora; sin ese reporte no hay nada que integrar.
- **Integración de WhatsApp**: toda atención derivada del formulario va por correo, y WhatsApp se usa para avisos sueltos. Se habilitaría solo si se demuestra que hay seguimiento sustantivo ocurriendo ahí.
- **Checklist de documentos obligatorios y detección de faltantes**: como el MVP muestra únicamente los campos con dato, no puede señalar un requisito que el solicitante dejó vacío. Requiere definir primero el catálogo de documentos obligatorios por tipo de trámite.
- **Portal o vista para las agencias solicitantes**: contradice el principio de no cambiar nada para el cliente, e implicaría autenticación externa y exposición pública.
- **Migración del histórico anterior a 2026**: se atiende solo a petición. Migrar años de histórico no aporta al trabajo diario y sí agrega un proyecto de datos.
- **Sustituir el formulario de Google o reducir las columnas de la hoja**: el formulario y la hoja se conservan intactos como entrada y fuente de datos. Cambiarlos afectaría al solicitante y al reporteo, y además la hoja debe seguir albergando las columnas de siniestros.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Listar casos recientes primero | El sistema lista las peticiones de 2026 en adelante ordenadas descendentemente por fecha y hora de recepción. |
| RF-02 | Buscar y filtrar | Permite localizar casos por folio de petición, solicitante, agencia, tipo de trámite, estatus y responsable. |
| RF-03 | Mostrar solo campos con dato | Al abrir un caso, muestra únicamente los campos que llegaron con información, omitiendo los vacíos. |
| RF-04 | Enlaces siempre clicables | Toda URL de Drive asociada al caso se presenta como enlace navegable, sin requerir copiar y pegar. |
| RF-05 | Editar campos de seguimiento | Permite modificar estatus, semáforo, responsable, aseguradora, si el solicitante podía hacerlo, motivo de la petición, folio de aseguradora y observaciones, usando los mismos catálogos de valores que la hoja de cálculo. |
| RF-06 | Guardado explícito a la hoja | Los cambios se escriben en la fila correspondiente de la hoja solo al confirmar la acción de guardar; no hay escritura automática durante la captura. |
| RF-07 | Bloqueo de caso en edición | Al abrir un caso para edición, el sistema lo marca como tomado por esa persona e impide que otra guarde cambios sobre él, mostrando quién lo tiene. |
| RF-08 | Iniciar conversación | Envía el correo de apertura desde el buzón compartido, con asunto `Resolución Caso #<folio de petición>` y destinatario tomado del formulario, sin captura manual de esos datos. |
| RF-09 | Vínculo persistente caso↔hilo | Al iniciar la conversación, guarda el identificador del hilo asociado al caso para recuperarlo después sin búsquedas manuales. |
| RF-10 | Mostrar el hilo del caso | Presenta los mensajes del hilo vinculado en orden cronológico dentro de la vista del caso. |
| RF-11 | Responder en el hilo | Permite enviar una respuesta dentro del hilo del caso conservando asunto y destinatarios. |
| RF-12 | Bitácora de observaciones | Registra notas internas de forma acumulativa, con autor y fecha, sin sobrescribir las anteriores. |
| RF-13 | Importación bajo demanda | Permite incorporar peticiones de periodos anteriores a 2026 cuando se solicite explícitamente. |
| RF-14 | Estatus visible de todo caso | Todo caso recibido aparece en la bandeja con su estatus actual; ninguno queda oculto por configuración de vista. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Disponibilidad 24/7 | La herramienta debe estar disponible de forma continua, con monitoreo y alertas ante caídas. El costo e infraestructura asociados deben acotarse antes de construir (ver sección 14). |
| RNF-02 | Autenticación corporativa con lista de acceso | El ingreso se hace con cuenta de Google Workspace de la organización y además contra una lista explícita de personas autorizadas: tener cuenta del dominio no basta para entrar. |
| RNF-03 | Manejo de credenciales | El acceso a Sheets y Drive usa una cuenta de servicio con permisos mínimos sobre la hoja y la carpeta involucradas; el acceso a Gmail usa el consentimiento OAuth de la cuenta del buzón compartido. Ningún secreto reside en el código ni en el repositorio. |
| RNF-04 | Trazabilidad de cambios | Cada guardado registra usuario, campos modificados, valor anterior, valor nuevo y fecha, de modo que un cambio equivocado pueda identificarse y revertirse. |
| RNF-05 | Manejo de errores sin pérdida de captura | Si la escritura a la hoja falla, la información capturada no se pierde, el error se comunica en lenguaje claro y la operación es reintentable. |
| RNF-06 | Consistencia de datos | La escritura a la hoja ocurre únicamente por acción explícita del usuario y bajo bloqueo del caso, para evitar escrituras parciales o simultáneas desde la herramienta. |
| RNF-07 | Experiencia de usuario | Trabajar un caso en la herramienta debe ser perceptiblemente más rápido que navegar la hoja de cálculo; de lo contrario la mesa volverá al método actual. |
| RNF-08 | Escalabilidad de lectura | El sistema debe sostener el crecimiento continuo de la hoja y el volumen diario (~10-15 peticiones) sin degradar la bandeja, mediante paginación y/o caché de lectura. |
| RNF-09 | Privacidad y confidencialidad | Los datos de solicitantes, vehículos, pólizas y facturas se tratan como información confidencial, accesible solo a la lista de personas autorizadas. |
| RNF-10 | Observabilidad | Se registran las operaciones contra las APIs de Google, el consumo de cuota y los fallos de token, con alerta ante expiración o revocación del consentimiento de Gmail. |
| RNF-11 | Tolerancia a cambios del formulario | La lectura de la hoja se resuelve por nombre de encabezado y no por posición de columna, para que agregar o reordenar preguntas del formulario no rompa la herramienta. |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| Google Sheets (hoja de peticiones) | Lectura de las peticiones recibidas y escritura del seguimiento en la fila del caso. Es la fuente única de datos del negocio. Acceso mediante cuenta de servicio con permiso sobre esa hoja. |
| Google Forms | Origen de las peticiones. No se integra directamente: se consume a través de las respuestas ya volcadas en la hoja de cálculo. |
| Google Drive | Ubicación de los adjuntos que carga el solicitante. Lectura y normalización de enlaces para que sean navegables desde el caso. Acceso mediante la misma cuenta de servicio. |
| Gmail (buzón compartido de la mesa) | Envío del correo de apertura, lectura del hilo del caso y envío de respuestas. Acceso mediante consentimiento OAuth de la cuenta del buzón. |
| Google Workspace (identidad) | Autenticación de los usuarios de la mesa, validada contra la lista de acceso autorizada. |
| Base de datos propia (metadatos) | Almacena únicamente lo operativo: bloqueo de casos en edición, vínculo caso↔identificador de hilo y bitácora de cambios. No duplica el seguimiento del negocio. |

**Datos mínimos para operar el MVP.** Del formulario: folio de petición, fecha y hora de recepción, tipo de trámite, nombre y correo del solicitante, agencia y su clasificación (financiera de Autocom o externa), línea de negocio (crédito o leasing), motivo de la solicitud en texto y enlaces de los adjuntos correspondientes al tipo de trámite. Del seguimiento de la mesa: estatus del trámite, semáforo, responsable asignado, aseguradora, indicador de si el solicitante podía resolverlo por su cuenta, motivo de la petición a mesa, folio de aseguradora y observaciones acumuladas. De los metadatos propios: identificador del hilo de correo, estado y dueño del bloqueo de edición, y registro de cambios con usuario y fecha.

**Esquema de permisos.** La herramienta **lee** la hoja de peticiones completa desde 2026, los adjuntos de Drive del caso y el hilo de correo del buzón compartido. **Escribe** exclusivamente en las columnas de seguimiento de la fila del caso correspondiente —nunca en las columnas que provienen del formulario, que son registro del solicitante— y envía correos únicamente al destinatario que el formulario declara, con el asunto normalizado del caso. La cuenta de servicio se limita a la hoja y la carpeta de Drive involucradas, sin acceso al resto del Drive de la organización. **Queda bloqueado sin intervención humana**: borrar filas o casos, alterar la estructura de la hoja, modificar los datos originales del formulario, enviar correo a destinatarios distintos del solicitante del caso, e importar periodos anteriores a 2026, que requiere solicitud explícita. La mesa conserva su permiso de edición directa sobre la hoja como red de seguridad; ese riesgo se asume de forma consciente (ver sección 13).

## 11. Eventos para BI

Eventos que el MVP emite, pensados como insumo del reporteo de la Fase 2 y para medir el uso real de la herramienta:

- `caso_visualizado`: se registra cuando una persona de la mesa abre la vista de un caso.
- `caso_tomado`: se registra cuando una persona abre un caso en modo edición y adquiere su bloqueo.
- `conversacion_iniciada`: se registra cuando la herramienta envía el correo de apertura del caso.
- `respuesta_enviada`: se registra cuando se envía una respuesta dentro del hilo del caso.
- `caso_guardado`: se registra cuando se confirman cambios y se escriben en la hoja de cálculo.
- `caso_cerrado`: se registra cuando el caso pasa a un estatus terminal (atendido y concluido, o no procede).
- `importacion_solicitada`: se registra cuando se solicita incorporar un periodo anterior a 2026.

**Campos mínimos de cada evento**: fecha y hora, usuario que lo origina, folio de petición, tipo de trámite, estatus resultante del caso y, cuando aplique, motivo (por ejemplo, la razón de no procedencia o del cierre).

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Casos atendidos por persona por semana | Capacidad real de la mesa antes y después de la herramienta. La línea base puede aproximarse con el histórico de la hoja de cálculo, pero debe validarse con operación antes de fijar meta. |
| Adopción de la herramienta | Proporción de casos cuyo seguimiento se registró desde la herramienta frente a los editados directamente en la hoja. Una adopción baja indica que la herramienta no está resolviendo el problema; la meta numérica queda pendiente de acordar con Norma y Keynor. |

Ambas métricas dependen de validación con operación para definir línea base y meta; este PRD no fija cifras.

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Cuotas y límites de las APIs de Google | Con lecturas de la bandeja y escrituras frecuentes, agotar cuota degradaría o interrumpiría la operación en plena jornada. |
| Edición manual de la hoja en paralelo | El bloqueo de casos solo rige dentro de la herramienta: alguien que edite la hoja directamente puede sobreescribir un cambio recién guardado. Riesgo asumido conscientemente para conservar la red de seguridad. |
| Cambios en el formulario | Agregar, quitar o reordenar preguntas puede romper la lectura de columnas y dejar campos sin mostrar o mal asociados. |
| Campos obligatorios vacíos no detectados | Al mostrar solo los campos con dato, un requisito que el solicitante dejó en blanco simplemente no aparece, y la mesa podría no notar el faltante hasta más adelante. |
| Respuestas fuera del hilo | Si el solicitante contesta abriendo un correo nuevo, esa parte de la conversación no llega al caso y la información vuelve a fragmentarse. |
| Revocación o expiración del consentimiento OAuth de Gmail | La herramienta dejaría de enviar y leer correo, interrumpiendo la funcionalidad central del MVP. |
| Costo e infraestructura del 24/7 | La disponibilidad continua exige monitoreo y redundancia cuyo costo aún no está acotado y podría exceder lo previsto. |
| Crecimiento sostenido de la hoja | A medida que la hoja crece, la lectura se vuelve más lenta y la bandeja puede degradarse. |
| Abandono de la herramienta | Si trabajar un caso resulta más lento que en la hoja, la mesa volverá al método actual y el proyecto no rendirá beneficio. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Estabilidad del formulario y de la hoja | Se asume que ni la estructura del formulario ni la de la hoja cambian sustancialmente durante el desarrollo. |
| Existencia de un buzón compartido | Se asume que existe —o se creará— un buzón de correo del área desde el cual la herramienta abrirá y responderá las conversaciones. |
| Colaboración del administrador de Workspace | Se asume que se habilitarán la cuenta de servicio, los permisos sobre la hoja y la carpeta, y el consentimiento OAuth del buzón. |
| Unicidad del folio de petición | Se asume que el folio de petición identifica sin ambigüedad cada caso de 2026 en adelante. |
| Usuarios del MVP | Se asume que Keynor y Pati son los usuarios de la Fase 1, con un único rol sin distinción de permisos entre ellos. |
| Continuidad de catálogos | Se asume que los catálogos de estatus, semáforo, responsable y aseguradora se conservan idénticos a los de la hoja actual. |
| Canal de atención | Se asume que el correo sigue siendo el canal formal de atención de las peticiones del formulario. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Bloqueo de casos | ¿Cómo se libera un bloqueo colgado (una persona que abrió un caso y cerró el navegador)? ¿Expira por tiempo, lo libera cualquiera de la mesa, o hace falta intervención de TI? |
| Correo | ¿Existe ya el buzón compartido del área o hay que crearlo? ¿Cuál es la dirección que verán las agencias? |
| Correo | ¿Qué hace la herramienta cuando el solicitante responde en un correo nuevo en lugar del hilo del caso? Se define con Keynor una vez observada la frecuencia real. |
| Correo | ¿Qué contenido base lleva el correo de apertura además del folio (plantilla, firma, si indica quién atiende)? |
| Documentación faltante | ¿Cuál es el catálogo de documentos obligatorios por tipo de trámite? Es el requisito para habilitar la detección de faltantes en una fase posterior. |
| Reporteo (Fase 2) | ¿Cuál es exactamente el reporte que se necesita y qué cortes lleva la tabla dinámica actual? Definirlo con Keynor y con quien recibe el reporte semanal. |
| Métricas | ¿Cuál es la línea base y la meta de casos atendidos por persona y de adopción? Requiere validación con Norma, Keynor y operación. |
| Infraestructura | ¿Dónde se hospeda la herramienta y cuál es el costo de sostener la disponibilidad 24/7 con monitoreo? |
| Arranque | ¿Qué se hace con los casos de 2026 que estén abiertos al momento del despliegue: se cargan todos a la bandeja o solo los posteriores a la fecha de corte? |
| Importaciones | ¿Quién solicita y quién autoriza una importación de periodos anteriores a 2026, y por qué medio? |
| Datos históricos | ¿El folio de petición es único a lo largo de todo el histórico o puede repetirse entre años, lo que afectaría una futura importación? |
| Siniestros (Fase 3) | ¿Qué tan distinto es el flujo de Juan y bajo qué criterio se decide adaptar esta herramienta o construir algo separado? |
