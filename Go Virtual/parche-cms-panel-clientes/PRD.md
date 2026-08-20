# PRD — Parche CMS: Panel de Clientes (Go Virtual)

| Campo | Detalle |
|---|---|
| Proyecto / Sistema | `govirtual-api` — Panel CMS de Go Virtual |
| Tipo | Feature |
| Área / empresa | Go Virtual |
| Versión | v0.1 |
| Fecha | 2026-08-20 |
| Autores | Javier Antonio Oropeza Camacho (análisis y redacción) · Sharon Mendoza (solicitante, Go Virtual) |
| Revisión / liderazgo | Aldo Álvarez (Director de TI) |
| Insumos | Reunión 2026-08-19 (transcripción + resumen), `Requerimientos - parche CMS (grid).docx`, documento de validación del equipo Go Virtual (2026-08-20) |

---

## 1. Resumen del cambio

El panel CMS de Go Virtual (`govirtual-api`) es hoy una herramienta exclusivamente interna: todas las cuentas que entran pertenecen a Go Virtual y tienen acceso a la totalidad de la información de todos los dealers y grupos. Este cambio lo convierte en una herramienta compartida con el cliente, donde cada grupo de agencias y cada agencia individual administra únicamente su propia información.

El cambio se compone de cuatro bloques: (1) rediseñar el sistema de permisos y construir la separación de datos por ámbito, que hoy no existe en ninguna capa; (2) extender banners y promociones a un modelo de tres niveles —marca, grupo y dealer— donde el contenido de nivel superior se hereda hacia abajo sin poder alterarse; (3) construir tres módulos que no existen en el panel (thank you pages, pop-ups y lead driver) bajo el mismo modelo de niveles; y (4) habilitar el acceso autenticado del cliente a Duda para blog, landings y auditoría de SEO.

El resultado esperado es que Go Virtual conserve el control total sobre el contenido de marca y la configuración crítica del sistema, mientras el cliente gana autonomía sobre su contenido local, sin posibilidad técnica de ver ni modificar información de otro dealer o grupo.

---

## 2. Contexto del cambio

**Cómo funciona hoy:**

- El panel asume que todo usuario autenticado es personal de Go Virtual. El `PermissionsGuard` valida si el usuario tiene permiso para entrar a una sección, pero ninguna consulta filtra por propietario del dato: `req.user.dealerId` viaja en el JWT desde el login y no se consume en ningún servicio.
- Existen únicamente tres permisos (`super.admin.all`, `admin.all`, `admin.content.editors`) para aproximadamente treinta secciones del panel. El permiso más bajo (`admin.content.editors`) habilita crear y editar dealers, grupos, marcas, modelos, precios, versiones, banners, promociones, accesorios, ref-data y regiones, además de listar todos los usuarios.
- Banners y promociones están asociados exclusivamente a `brandId`. No existe concepto de contenido local ni campo de orden. El feed que alimenta los sitios (`GET /grid/banners/:brandCode`) responde por marca, no por dealer ni por sitio.
- El vínculo entre un usuario y su grupo está mal construido: el virtual `group` de `UserSchema` resuelve por `dealerId` en lugar de `groupId`, por lo que nunca devuelve resultado.
- Dos controladores autenticados no declaran ningún permiso (`grid/sites` y `grid/templates`). Como el guard devuelve `true` cuando no hay metadata, quedan accesibles para cualquier cuenta autenticada.
- No existen pruebas automatizadas de autorización.

**Qué dispara el cambio:**

Go Virtual necesita que sus clientes administren su propio contenido local (banners, promociones y los módulos nuevos) sin depender del equipo de soluciones para cada cambio, conservando Go Virtual la gestión del contenido de marca y el servicio de cambios comerciales mensuales. En paralelo, el área señala como riesgo operativo que prácticamente todas las cuentas actuales operan con perfil de super administrador, incluyendo acceso al mapeo de leads, donde un cambio accidental rompe la captura de formularios de los sitios en producción.

**Distinción conceptual relevante para el equipo de desarrollo:**

| Concepto | Qué es | Colección |
|---|---|---|
| **Dealer** | Registro de la agencia (razón social, marcas, grupo, información de contacto) | `dealers` |
| **Grupo** | Agrupación de dealers; admite anidamiento vía `parentGroupId` (grupo → subgrupo) | `groups` |
| **Usuario** | Cuenta de acceso al panel, con rol y ámbito | `users` |

Dar de alta un dealer y dar de alta un usuario son operaciones distintas y con reglas distintas. Ambas quedan restringidas a Go Virtual (ver RF-13 y RF-14).

---

## 3. Alcance del cambio

### Qué entra

| Elemento | Descripción |
|---|---|
| **F0 — Cierre de riesgos** | Corrección del vínculo usuario↔grupo, cierre del comportamiento *fail-open* del guard de permisos, protección de los controladores expuestos y cierre de las vías de escalada de privilegios en el alta y edición de usuarios |
| **F1 — Roles y ámbito** | Rediseño del catálogo de permisos con granularidad por módulo; campo `scopeLevel` en roles; capa reutilizable de filtrado por ámbito aplicada a los módulos compartidos; resolución recursiva grupo→dealers; ámbito en la bitácora; pruebas de autorización |
| **F2 — Banners y promociones** | Modelo de tres niveles (marca / grupo / dealer) con herencia descendente, asignación de elementos a destinos, orden por nivel, vistas separadas en el panel y adecuación del feed que consumen los sitios |
| **F3 — Módulos nuevos** | Thank you pages (TYP), pop-ups y lead driver, disponibles a nivel grupo y dealer bajo el mismo modelo de la F2 |
| **F4 — Acceso a Duda** | Acceso autenticado desde el panel hacia el CMS de Duda para blog, landings y auditoría de SEO |

### Qué NO entra

| Exclusión | Justificación |
|---|---|
| Alta de grupos y dealers por parte del cliente | Decisión expresa del equipo Go Virtual (2026-08-20). Es un ajuste respecto a lo planteado inicialmente: el alta de grupos y dealers queda exclusivamente bajo Go Virtual |
| Alta de cuentas de acceso por parte del cliente | El costo de licenciamiento se factura por usuario. La creación de cuentas queda como función administrativa de Go Virtual |
| Que un dealer oculte, elimine o reordene contenido heredado de grupo o de marca | Definido explícitamente en las reglas de herencia. Simplifica el modelo: no se requieren sobreescrituras por dealer |
| Que un grupo oculte, elimine o reordene contenido heredado de marca | Misma regla de herencia aplicada un nivel arriba |
| Que un usuario cuente con más de un ámbito | Una cuenta pertenece a un solo grupo o a un solo dealer. Un dealer fuera de grupo se maneja como acceso independiente de nivel dealer |
| Migración del blog y las landings al panel | Permanecen en Duda; el panel solo enlaza a ellos (F4) |
| Baja o migración del módulo `home-contents` | Se mantiene sin cambios en la API; se oculta desde el front |
| Refactor del stack existente | Se respeta NestJS + MongoDB por tratarse de una feature sobre sistema en producción |

---

## 4. Requerimientos funcionales

### Fase 0 — Cierre de riesgos

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-01 | Corregir el vínculo usuario↔grupo | El virtual `group` de `UserSchema` debe resolver por `groupId`, no por `dealerId`. Sin esto el ámbito de grupo no puede operar |
| RF-02 | Cerrar el comportamiento *fail-open* del guard | Un endpoint sin declaración de permisos debe denegar el acceso por defecto. La exposición pública o interna debe declararse de forma explícita |
| RF-03 | Proteger los controladores sin permisos declarados | `grid/sites` (creación de sitios en Duda, individual y por lote) y `grid/templates` (sincronización de plantillas) deben exigir permiso de Go Virtual |
| RF-04 | Cerrar las vías de escalada de privilegios en usuarios | El alta y la edición de usuarios no deben permitir asignar un rol de mayor jerarquía que la del solicitante, ni modificar `isStaff`, ni cambiar el ámbito sin permiso específico |

### Fase 1 — Roles y ámbito

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-05 | Catálogo de permisos con granularidad por módulo | Sustituir los tres permisos actuales por un catálogo que permita habilitar cada sección de forma independiente, conforme al reparto Go Virtual / compartido definido en el anexo A |
| RF-06 | Nivel de ámbito en el rol | El rol debe declarar su nivel (`gv`, `group`, `dealer`). El front lo consulta para determinar qué referencia solicitar en el alta de usuarios; el backend lo valida |
| RF-07 | Roles de cliente | Cuatro roles: Editor Dealer, Admin Dealer, Editor Grupo y Admin Grupo. El editor se orienta a marketing (promociones, campañas, pop-ups); el admin agrega la información operativa de la agencia (horarios, dirección, ficha de Google My Business) |
| RF-08 | Ámbito único por cuenta | Una cuenta de cliente pertenece a un solo grupo **o** a un solo dealer, nunca a ambos ni a varios. El alta debe exigir exactamente una referencia según el `scopeLevel` del rol y rechazar combinaciones incoherentes |
| RF-09 | Filtrado por ámbito en consultas | Toda consulta de listado y de detalle sobre módulos compartidos debe restringirse al ámbito del solicitante, derivado del token y nunca de parámetros enviados por el cliente |
| RF-10 | Comportamiento seguro ante ámbito ausente | Una cuenta de cliente sin ámbito resuelto no debe devolver información. La ausencia de ámbito nunca puede interpretarse como ausencia de filtro |
| RF-11 | Resolución recursiva de grupos | El ámbito de una cuenta de grupo debe abarcar los dealers de su grupo y los de todos sus subgrupos descendientes |
| RF-12 | Ámbito en la bitácora de cambios | El registro de cambios debe permitir filtrar por dealer o grupo, de modo que un cliente vea los movimientos de su propio equipo y no los de otros |
| RF-13 | Alta de cuentas restringida a Go Virtual | La creación de cuentas de acceso corresponde a un rol de administrador de Go Virtual. El cliente no dispone de módulo de usuarios |
| RF-14 | Alta de grupos y dealers restringida a Go Virtual | La creación y edición de grupos y dealers corresponde a Go Virtual. El cliente los consulta dentro de su ámbito, sin poder crearlos |
| RF-15 | Emisión del ámbito en el token | El token de acceso debe transportar el ámbito completo de la cuenta, incluyendo la referencia de grupo, que hoy no se emite |

### Fase 2 — Banners y promociones en tres niveles

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-16 | Nivel de propiedad del elemento | Cada banner y cada promoción pertenece a uno de tres niveles: **marca** (administra Go Virtual), **grupo** (administra Go Virtual y el admin del grupo) o **dealer** (administra Go Virtual y el admin del dealer) |
| RF-17 | Asignación de elementos a destinos | Un elemento de nivel marca puede asignarse a cualquier sitio de la marca; uno de nivel grupo, al conjunto de dealers del grupo; uno de nivel dealer, únicamente a su propia agencia |
| RF-18 | Herencia descendente inalterable | Un dealer no puede ocultar, eliminar ni reordenar elementos heredados de grupo o de marca. Un grupo no puede ocultar, eliminar ni reordenar elementos heredados de marca. Cada nivel administra exclusivamente los elementos que le pertenecen |
| RF-19 | Orden de aparición por nivel | El orden de despliegue sigue la prioridad marca → grupo → dealer. Dentro de cada nivel, el orden lo define quien administra ese nivel |
| RF-20 | Vistas diferenciadas en el panel | El panel debe distinguir visualmente el contenido heredado del propio, de forma que el cliente identifique qué puede administrar y qué solo puede consultar |
| RF-21 | Visibilidad de Go Virtual sobre el contenido local | Go Virtual debe poder consultar y administrar el contenido de nivel grupo y dealer, para sostener el servicio de cambios comerciales mensuales |
| RF-22 | Aislamiento del contenido local entre agencias | El contenido de nivel dealer es individual de cada agencia. Ni las demás agencias del grupo ni el admin del grupo lo consultan o editan |
| RF-23 | Adecuación del feed hacia los sitios | El feed que consumen los sitios debe resolver el contenido aplicable a cada sitio combinando los tres niveles y respetando el orden de RF-19. Hoy responde por marca y debe pasar a responder por sitio o dealer |

### Fase 3 — Módulos nuevos

Los tres módulos operan bajo el mismo modelo de niveles de la Fase 2, disponibles a nivel **grupo** y **dealer**: el nivel grupo asigna elementos comunes a todos los dealers de su grupo; el nivel dealer cubre las particularidades de cada agencia.

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-24 | Módulo TYP — catálogo precargado | Las páginas de agradecimiento de los formularios que provee Go Virtual quedan dadas de alta por defecto con información base, modificables a demanda. Se replica el patrón de catálogo precargado de *lead destinations* |
| RF-25 | Módulo TYP — campos | Título (obligatorio), subtítulo (obligatorio), slug (obligatorio) y apartado de CTAs (opcional, hasta tres botones, cada uno con texto y enlace) |
| RF-26 | Módulo pop-up — campos | Título (obligatorio), imagen mobile y desktop (obligatorias), enlace (obligatorio), vigencia (opcional) y página donde se muestra (obligatorio) |
| RF-27 | Módulo pop-up — capacidad | El módulo debe soportar la creación de al menos diez pop-ups |
| RF-28 | Módulo lead driver — campos base | Imagen mobile y desktop (obligatorias) y un selector de funcionamiento con dos modalidades: enlace o despliegue de formulario |
| RF-29 | Módulo lead driver — modalidad enlace | Enlace del banner (obligatorio) |
| RF-30 | Módulo lead driver — modalidad formulario | Selector de tipo de formulario (obligatorio), título (obligatorio), subtítulo (opcional) y texto del CTA (opcional) |
| RF-31 | Módulo lead driver — activación | Control de activo/inactivo. Al activarse, el elemento se muestra en la página de inventario del sitio |

### Fase 4 — Acceso a Duda

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-32 | Acceso autenticado a Duda | Desde el panel, el cliente accede a la edición de posts de blog, landings y auditoría de SEO en Duda sin necesidad de iniciar sesión nuevamente. Referencia: `https://developer.duda.co/docs/partner-api-introduction` |

---

## 5. Requerimientos no funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RNF-01 | Aislamiento verificable entre ámbitos | Debe existir cobertura de pruebas automatizadas que compruebe que una cuenta de un ámbito no accede a información de otro, tanto en listados como en detalle por identificador |
| RNF-02 | El ámbito no viaja por parámetro | El ámbito aplicado a cada consulta se deriva siempre del token. Ningún parámetro de consulta enviado por el cliente puede ampliarlo |
| RNF-03 | Caché segmentada por ámbito | Las respuestas cacheadas deben diferenciarse por ámbito. Una clave de caché que no lo contemple expondría información entre clientes |
| RNF-04 | Denegación por defecto | Un endpoint sin declaración explícita de permisos deniega el acceso |
| RNF-05 | Compatibilidad del contenido existente | Los banners y promociones actuales deben quedar clasificados como nivel marca sin interrupción del servicio en los sitios en producción |
| RNF-06 | Continuidad del feed hacia los sitios | El cambio de contrato del feed debe permitir una transición sin caída de los sitios ya publicados durante la reconfiguración |
| RNF-07 | Trazabilidad | Toda operación de creación, edición y baja realizada por un cliente debe quedar registrada en la bitácora, identificando autor y ámbito |
| RNF-08 | Respeto del stack existente | La implementación se realiza sobre NestJS y MongoDB, conforme a la regla de Engine de no migrar tecnología en features sobre sistemas en producción |

---

## 6. Componentes e integraciones afectadas

| Componente / Integración | Tipo de cambio | Descripción |
|---|---|---|
| Catálogo de permisos (`PermissionsEnum`) | Modificación | Sustitución de los tres permisos actuales por un catálogo granular por módulo |
| Guard de permisos | Modificación | Denegación por defecto y capacidad de expresar acceso alternativo (Go Virtual **o** cliente) en módulos compartidos |
| Módulo `roles` | Modificación | Alta del nivel de ámbito en el rol y de los cuatro roles de cliente |
| Módulo `users` | Modificación | Validación de ámbito único, coherencia rol↔ámbito, bloqueo de escalada de privilegios y filtro de listado por grupo |
| Módulo `auth` | Modificación | Emisión del ámbito completo en el token de acceso |
| Capa de ámbito | Nuevo | Componente reutilizable que resuelve el ámbito del solicitante y lo aplica a las consultas, incluida la resolución recursiva de grupos |
| Módulo `groups` | Modificación | Resolución recursiva de subgrupos; restricción de alta a Go Virtual |
| Módulo `dealers` | Modificación | Filtrado por ámbito; restricción de alta a Go Virtual |
| Módulo `banners` | Modificación | Nivel de propiedad, asignación a destinos y orden |
| Módulo `promotions` | Modificación | Nivel de propiedad, asignación a destinos y orden |
| Módulo `audit-logs` | Modificación | Incorporación del ámbito para permitir el filtro por equipo |
| Módulos TYP, pop-up y lead driver | Nuevo | Tres módulos nuevos con el modelo de niveles de la Fase 2 |
| Feed hacia los sitios (`grid`) | Modificación | Cambio de contrato de por marca a por sitio o dealer para banners y promociones |
| **External Collections de Duda** | Configuración externa | Reconfiguración del origen de datos en cada sitio publicado. Es trabajo operativo del equipo de Go Virtual, no solo de desarrollo |
| API de Duda | Nuevo | Integración para el acceso autenticado del cliente (Fase 4) |
| Caché (Redis) | Modificación | Segmentación de claves por ámbito en los servicios afectados |
| Almacenamiento de imágenes (S3) | Sin cambio de arquitectura | Los módulos nuevos reutilizan el manejo de imágenes existente |

---

## 7. Preguntas abiertas

| Tema | Pregunta abierta |
|---|---|
| Destino de asignación | Las reglas describen que el nivel marca asigna a **sitios** y el nivel grupo asigna a **dealers**. ¿Se normaliza a un único tipo de destino, o el destino cambia según el nivel? Un grupo puede tener sitios de agencia y además un sitio de grupo, por lo que la diferencia es relevante |
| Sitio de grupo | Cuando un grupo tiene sitio propio que centraliza la información de sus agencias, ¿qué contenido de nivel dealer se muestra en él, si alguno? |
| Referencia de TYP | El patrón *lead destinations* citado como referencia no corresponde a un módulo con ese nombre en la API. ¿Se refiere al catálogo precargado de tipos de integración de leads (`lead_integration_types` + `lead_mappings`)? |
| Listado de formularios | Pendiente de recibir el listado de formularios existentes que Go Virtual provee, base para la precarga de las páginas de agradecimiento |
| Lead driver y pop-ups | Sesión pendiente de agendar para revisar ambos módulos a detalle antes de iniciar la Fase 3 |
| Pop-up — página destino | ¿La página donde se muestra el pop-up se elige de un catálogo de páginas del sitio, o se captura como texto libre? |
| Lead driver — tipos de formulario | ¿De dónde proviene el catálogo de tipos de formulario del selector? |
| Migración de contenido actual | ¿Los banners y promociones existentes quedan todos como nivel marca, o alguno debe reclasificarse a nivel grupo o dealer? |
| Licenciamiento de Duda | ¿El acceso autenticado requiere una cuenta de Duda por usuario cliente? Impacta el mismo criterio de costo por el que el alta de cuentas queda centralizada |
| Folio del proyecto | Pendiente de asignar el folio `PJ####` para el enlace con el tablero de planes |

---

## Anexo A — Reparto de módulos por ámbito

| Módulo | Go Virtual | Grupo | Dealer |
|---|---|---|---|
| Precios | Administra | — | — |
| Marcas | Administra | — | — |
| Modelos | Administra | — | — |
| Versiones | Administra | — | — |
| MRPs | Administra | — | — |
| Accesorios | Administra | — | — |
| Ref data | Administra | — | — |
| Lista blanca de dominios | Administra | — | — |
| Mapeo de leads | Administra | — | — |
| Inventory settings | Administra | — | — |
| Plantillas | Administra | — | — |
| Grupos | Administra | Consulta | Consulta |
| Dealers | Administra | Consulta | Consulta |
| Banners | Administra los tres niveles | Administra nivel grupo; hereda marca | Administra nivel dealer; hereda grupo y marca |
| Promociones | Administra los tres niveles | Administra nivel grupo; hereda marca | Administra nivel dealer; hereda grupo y marca |
| Bitácora de cambios | Consulta total | Consulta su ámbito | Consulta su ámbito |
| Thank you pages | Administra | Administra nivel grupo | Administra nivel dealer |
| Pop-ups | Administra | Administra nivel grupo | Administra nivel dealer |
| Lead driver | Administra | Administra nivel grupo | Administra nivel dealer |
| Usuarios | Administra | — | — |
| Acceso a Duda | — | Accede | Accede |
| Home contents | Sin cambios; oculto en el panel | — | — |

---

*Engine CX — Departamento de Desarrollo*
*Versión: v0.1*
