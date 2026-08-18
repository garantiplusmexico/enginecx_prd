# PRD - Ajustes al módulo de Averías para el proyecto Bridgestone (captura de llantas)

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Ajustes al módulo de Averías para el proyecto Bridgestone (captura de llantas) |
| **Área / empresa** | Garantiplus México |
| **Versión** | v0.1 |
| **Fecha** | 2026-08-18 |
| **Autores** | Javier Antonio Oropeza — TI Garantiplus México |
| **Revisión / liderazgo** | Aldo Álvarez — Director de TI |
| **Tipo de proyecto** | Feature web o API |

## 1. Resumen ejecutivo

Bridgestone es un proyecto de garantía cuyo objeto asegurado es **exclusivamente la llanta**. A diferencia del resto de los proyectos que opera SIGA (armadoras, distribuidores multimarca, garantías extendidas de vehículo completo), en Bridgestone no existe variedad de refacciones ni mano de obra facturable: toda avería se resuelve reponiendo una llanta. Sin embargo, el módulo de Averías presenta hoy al distribuidor/taller la misma pantalla genérica que a cualquier otro proyecto, con catálogos completos de refacciones, captura de mano de obra, número de parte y selección libre de impuesto.

Esa generalidad, que en otros proyectos es una virtud, en Bridgestone es una fuente de error de captura: el usuario puede elegir un tipo de costo, una refacción o un esquema de impuesto que no corresponden al producto, y esos errores se detectan tarde —en la revisión o aprobación de la avería— generando retrabajo, rechazos y correcciones manuales sobre el presupuesto.

El MVP de este PRD **restringe la pantalla de captura de refacciones y presupuesto del módulo de Averías cuando la avería pertenece al proyecto Bridgestone**, dejando los valores correctos preseleccionados y en solo lectura, y ocultando los campos que no aplican. No se agregan pantallas, reportes ni flujos nuevos: es un ajuste de comportamiento condicionado por proyecto sobre vistas ya existentes.

El resultado esperado es que la captura de una avería Bridgestone sea prácticamente a prueba de error: el distribuidor/taller solo decide cantidad y precio de la llanta, y el presupuesto se calcula siempre bajo el esquema de I.V.A. cero. Los demás proyectos —incluido BMW, que ya tiene su propia variante por UAT— quedan sin cambio alguno.

**Avería en proyecto Bridgestone** → **Tipo fijo "Refacción" + Refacción fija "Llanta"** → **captura solo cantidad y precio** → **presupuesto con I.V.A. cero (fijo)** → **avería lista para aprobación**

## 2. Contexto y problema

**Cómo funciona hoy.** En el módulo de Averías, la pantalla de edición de una avería incluye la sección **"Refacciones y mano de obra"** (partial `_RefaccionesServiciosDealer`) y la sección **"Presupuesto"** (partial `_PresupuestoDealer`), que el distribuidor o el taller usa para desglosar el costo de la reparación:

- El selector **"Tipo"** (`tipo_costo`) ofrece dos opciones: `Refacción` y `M.O.`. Su selección determina qué campos se muestran: al elegir `Refacción` aparecen **Refacción**, **No. Parte**, **M.O.** y **Precio**; al elegir `M.O.` aparece **Servicio** y **Precio**.
- El selector **"Refacción"** (`pieza`) se llena con el catálogo completo de refacciones del país.
- La sección **Presupuesto** incluye un selector de **impuesto** (`id_impuesto`) alimentado con el catálogo `impuesto` del país, que el usuario elige libremente y que determina cómo se calcula el total del presupuesto.

**El dolor concreto.** Bridgestone solo cubre llantas, pero la pantalla no lo sabe. El capturista debe recordar, en cada avería, que el tipo siempre es "Refacción", que la refacción siempre es "Llanta", que no debe capturar mano de obra ni número de parte, y que el impuesto siempre es I.V.A. cero. Cada desviación produce un presupuesto mal formado que hay que corregir después, con costo de tiempo para el taller y para el equipo que aprueba averías, y con riesgo de que un monto incorrecto avance en el flujo de autorización.

**Por qué resolverlo ahora.** El ajuste es de bajo costo y alto retorno operativo, y ya existe en el sistema el mecanismo exacto para hacerlo bien: el proyecto **BMW** resolvió una necesidad análoga (capturar refacciones por UAT en lugar de M.O./Precio) mediante una configuración por proyecto —`ClaimBudgetRequirements`, expuesta a la vista como `ViewBag.IsBmwUat`— resuelta en `PaisesService`. Aprovechar ese mismo patrón evita introducir una segunda forma de resolver el mismo problema.

**Distinciones de dominio que el equipo debe tener claras desde el día 1:**

- **"Selector de presupuesto"** (como se le nombró en la solicitud) **es el selector de impuesto** de la sección Presupuesto: el campo `id_impuesto` del catálogo `impuesto`. No existe un catálogo llamado "presupuesto".
- **"M.O." aparece con dos significados distintos** en la misma pantalla: (a) una **opción del selector "Tipo"** que conmuta la captura hacia servicios de mano de obra, y (b) un **campo de importe** que acompaña a cada refacción capturada. Este PRD interviene ambos, pero son cosas distintas.
- **Proyecto ≠ país.** El comportamiento se condiciona por **proyecto** (Bridgestone), no por país; el catálogo del que se toman los valores fijos sí está filtrado por país.

## 3. Objetivo del producto

Lograr que la captura de refacciones y presupuesto de una avería del proyecto Bridgestone quede acotada a lo único que ese producto cubre —una llanta, bajo esquema de I.V.A. cero—, eliminando de la pantalla toda opción que no aplique y fijando en solo lectura los valores que no deben variar. El usuario objetivo es el **distribuidor/taller** que captura la avería; el beneficio directo es para él (menos decisiones, menos error) y para el **equipo de aprobación de averías** de Garantiplus México (menos rechazos y correcciones por captura inválida).

Es un alcance único, sin fases: el conjunto de ajustes descrito en la sección 5 constituye el entregable completo.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Distribuidor / taller Bridgestone | Usuario principal afectado. Captura la avería, registra la llanta (cantidad y precio) y consulta el presupuesto resultante. Es quien deja de tomar decisiones que ya no aplican. |
| Administrador de averías / analista de aprobación (Garantiplus México) | Revisa y aprueba las averías Bridgestone desde la vista administrativa. No cambia su pantalla, pero recibe presupuestos consistentes. |
| Área de Postventa / Operación Bridgestone | Dueño operativo del proyecto. Valida que la restricción refleje la cobertura real del producto. |
| TI Garantiplus México | Implementa el ajuste y parametriza los identificadores de refacción "Llanta" e impuesto "I.V.A. cero". |
| Catálogos / Administración de SIGA | Mantiene los catálogos `refaccion` e `impuesto` de los que se toman los valores fijos; un cambio suyo puede invalidar la configuración. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Detección del proyecto Bridgestone | La pantalla de edición de la avería determina si la avería pertenece al proyecto Bridgestone (identificado hoy por `PaisMX.BridgestoneProjectId = 173`) y activa a partir de ahí todo el comportamiento descrito abajo. Fuera de Bridgestone, nada cambia. |
| "Tipo" fijo en "Refacción" | El selector "Tipo" (`tipo_costo`) llega preseleccionado en `Refacción` y queda en solo lectura: el usuario no puede cambiarlo a `M.O.`. Al estar preseleccionado, la lógica existente que muestra los campos de refacción a partir del tipo se dispara sola, sin que el usuario tenga que elegir nada. |
| "Refacción" fija en "Llanta" | El selector "Refacción" (`pieza`) llega preseleccionado en el registro "Llanta" del catálogo de refacciones y queda en solo lectura. El registro se identifica por **ID configurado**, no por nombre. |
| Ocultamiento de "No. de parte" | El campo `no_parte` deja de mostrarse en la captura de Bridgestone. |
| Ocultamiento del campo "M.O." (importe) | El campo de importe de mano de obra (`mano_obra`) que acompaña a la refacción deja de mostrarse en la captura de Bridgestone. |
| Ocultamiento de la captura de mano de obra | Al no poder seleccionarse el tipo `M.O.`, se oculta también el selector "Servicio". Bridgestone no captura mano de obra. |
| Tabla "Servicios (Mano de obra)" condicional | La tabla de servicios se oculta por omisión. Se muestra —solo lectura— únicamente si la avería ya tiene registros de mano de obra capturados previamente, para no perder visibilidad de montos que siguen sumando al presupuesto. |
| Persistencia de campos ocultos | Al registrar la refacción, `no_parte` se guarda vacío/nulo y `mano_obra` se guarda en `0.00`. El total del presupuesto se compone únicamente de refacciones (y diversos, si se capturan). |
| Impuesto fijo en "I.V.A. cero" | En la sección Presupuesto, el selector de impuesto (`id_impuesto`) llega preseleccionado en "I.V.A. cero" y queda en solo lectura. El registro se identifica por **ID configurado**. |
| Refuerzo en servidor | Las acciones que reciben la captura (`AddSpareDealer` para refacciones y `AssignBudget` para presupuesto) fuerzan/validan los valores en averías Bridgestone, de modo que un envío manipulado no pueda registrar mano de obra ni un impuesto distinto. |
| Parametrización por proyecto | Los identificadores de la refacción "Llanta" y del impuesto "I.V.A. cero" quedan configurados por proyecto, siguiendo el patrón ya existente de reglas de presupuesto por proyecto (`ClaimBudgetRequirements` en `PaisesService`), en lugar de quedar dispersos en la vista. |

**Principio rector del MVP:** el ajuste es **aditivo y condicionado**. Ninguna avería de un proyecto distinto a Bridgestone puede cambiar de comportamiento, y ninguna regla de negocio de cálculo de presupuesto, autorización o cierre de avería se modifica: lo único que cambia es qué puede capturar el usuario en la pantalla de Bridgestone y qué se acepta en el servidor para ese proyecto.

## 6. Fuera de alcance

- **La vista administrativa de aprobación de refacciones (`_RefaccionesServiciosAdmin`)**: no se ajusta en este MVP. Ahí el administrador revisa y acepta montos, incluida la columna M.O.; ocultarla podría impedir revisar averías previas. Se habilitaría si operación confirma que ninguna avería Bridgestone puede tener M.O.
- **Las vistas de Colombia y otras variantes de país (`_RefaccionesServiciosDealerCOL`)**: Bridgestone se opera en México; extender la restricción a otro país requiere confirmar que el proyecto existe ahí y con qué identificador.
- **PDF y reportes de la avería**: no se modifican columnas ni campos en los documentos generados, aunque muestren "No. Parte" o "M.O." vacíos. Se abordaría si el área lo pide como ajuste cosmético posterior.
- **Migración o limpieza de averías Bridgestone ya capturadas**: los registros históricos que tengan mano de obra o un impuesto distinto se dejan tal cual. Corregirlos es una decisión de operación, no de este cambio.
- **Un catálogo o pantalla de configuración para administrar estas reglas por proyecto**: la parametrización se resuelve al nivel que ya usa el sistema para BMW. Un administrador de reglas por proyecto es un proyecto propio.
- **Restringir el campo "Diversos" del presupuesto**: sigue siendo capturable en Bridgestone; la solicitud no lo menciona.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Identificar averías del proyecto Bridgestone | La pantalla de edición de la avería debe poder determinar si la avería pertenece al proyecto Bridgestone a partir del proyecto de la póliza/producto de la avería, y exponer ese indicador a las vistas de refacciones y presupuesto. |
| RF-02 | Preseleccionar "Tipo" en "Refacción" | En averías Bridgestone, el selector `tipo_costo` debe cargarse con el valor `Refacción` ya seleccionado. |
| RF-03 | Bloquear "Tipo" | En averías Bridgestone, el selector `tipo_costo` no debe permitir cambiar el valor (solo lectura), conservando el valor al enviar el formulario. |
| RF-04 | Disparar la vista de refacción sin intervención | Con "Tipo" preseleccionado, los campos correspondientes a refacción deben quedar visibles al cargar la pantalla, sin requerir que el usuario interactúe con el selector. |
| RF-05 | Preseleccionar "Refacción" en "Llanta" | En averías Bridgestone, el selector `pieza` debe cargarse con el registro "Llanta" ya seleccionado, identificado por el ID configurado para el proyecto. |
| RF-06 | Bloquear "Refacción" | En averías Bridgestone, el selector `pieza` no debe permitir cambiar el valor (solo lectura), conservando el valor al enviar el formulario. |
| RF-07 | Ocultar "No. de parte" | En averías Bridgestone, el campo `no_parte` no debe mostrarse en el formulario de captura. |
| RF-08 | Ocultar el importe "M.O." | En averías Bridgestone, el campo de importe `mano_obra` no debe mostrarse en el formulario de captura. |
| RF-09 | Ocultar la captura de servicios | En averías Bridgestone, el selector "Servicio" (`servicio`) no debe mostrarse, al no existir la opción de capturar mano de obra. |
| RF-10 | Mostrar la tabla de Servicios solo con historial | En averías Bridgestone, la tabla "Servicios (Mano de obra)" debe ocultarse cuando la avería no tiene registros de mano de obra, y mostrarse en modo consulta cuando sí los tiene. |
| RF-11 | Persistir campos ocultos con valor neutro | Al registrar una refacción en una avería Bridgestone, `no_parte` debe guardarse vacío/nulo y `mano_obra` debe guardarse en `0.00`. |
| RF-12 | Preseleccionar el impuesto en "I.V.A. cero" | En averías Bridgestone, el selector `id_impuesto` de la sección Presupuesto debe cargarse con el registro "I.V.A. cero" ya seleccionado, identificado por el ID configurado. |
| RF-13 | Bloquear el selector de impuesto | En averías Bridgestone, el selector `id_impuesto` no debe permitir cambiar el valor (solo lectura), conservando el valor al enviar el formulario y al recalcular el presupuesto. |
| RF-14 | Validar la captura de refacciones en servidor | La acción que registra refacciones (`AddSpareDealer`) debe, para averías Bridgestone, forzar tipo `Refacción`, refacción "Llanta", `no_parte` vacío y `mano_obra` en cero, independientemente de lo que reciba. |
| RF-15 | Validar el presupuesto en servidor | La acción que asigna presupuesto (`AssignBudget`) debe, para averías Bridgestone, forzar el impuesto "I.V.A. cero" independientemente de lo que reciba. |
| RF-16 | Rechazar la captura de mano de obra en servidor | La acción que registra servicios de mano de obra debe rechazar o ignorar solicitudes correspondientes a averías Bridgestone. |
| RF-17 | Configurar los valores fijos por proyecto | Los identificadores de la refacción "Llanta" y del impuesto "I.V.A. cero" deben resolverse desde la configuración de reglas por proyecto, no estar embebidos en la vista. |
| RF-18 | No alterar otros proyectos | Para cualquier avería que no pertenezca a Bridgestone, la sección de refacciones y la de presupuesto deben comportarse exactamente igual que hoy, incluida la variante UAT de BMW. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | No regresión | El cambio no debe alterar el comportamiento de ningún proyecto distinto de Bridgestone. Debe validarse explícitamente contra un proyecto estándar y contra BMW (variante UAT), que comparte las mismas vistas. |
| RNF-02 | Bloqueo efectivo, no cosmético | El "solo lectura" de la interfaz no se considera control de seguridad: la validación en servidor (RF-14 a RF-16) es la que garantiza la integridad del dato. Un envío manipulado no debe poder registrar mano de obra ni otro impuesto en Bridgestone. |
| RNF-03 | Envío correcto de campos bloqueados | Los campos en solo lectura deben seguir viajando en el formulario con su valor fijo; no deben quedar deshabilitados de forma que se envíen vacíos y rompan la validación existente. |
| RNF-04 | Degradación segura ante configuración faltante | Si el ID de refacción "Llanta" o el de impuesto "I.V.A. cero" no existe o está inactivo en el catálogo del país, la pantalla no debe fallar: debe registrar el error y presentar un mensaje claro al usuario en lugar de guardar un valor incorrecto. |
| RNF-05 | Trazabilidad sin cambios | El registro de logs y bitácora de la avería (captura, actualización de presupuesto, cambios de estatus) debe seguir operando igual, con el mismo detalle que hoy. |
| RNF-06 | Consistencia con el patrón existente | La configuración por proyecto debe implementarse siguiendo el mecanismo ya usado para BMW (reglas de presupuesto por proyecto en `PaisesService`), para no introducir una segunda forma de resolver lo mismo. |
| RNF-07 | Sin impacto de rendimiento | La resolución de las reglas del proyecto no debe agregar consultas costosas por render; debe apoyarse en las consultas de configuración ya existentes en la carga de la pantalla. |
| RNF-08 | Permisos sin cambio | El cambio no altera roles, permisos ni el flujo de autorización de averías. Ningún usuario gana o pierde acceso. |
| RNF-09 | Experiencia de usuario clara | Los campos bloqueados deben verse evidentemente como no editables, para que el usuario entienda que es una restricción del producto y no un error de la pantalla. |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| Catálogo `proyecto` (SIGA) | Lectura. Determinar a qué proyecto pertenece la avería (vía póliza → producto → proyecto) para activar el comportamiento. |
| `PaisesService` — reglas por país/proyecto | Lectura. Resolver las reglas de captura de presupuesto del proyecto, incluidos los identificadores de refacción e impuesto fijos. Es donde ya vive el equivalente para BMW. |
| Catálogo `refaccion` (SIGA, filtrado por país) | Lectura. Obtener el registro "Llanta" que se preselecciona en el selector. |
| Catálogo `impuesto` (SIGA, filtrado por país) | Lectura. Obtener el registro "I.V.A. cero" que se preselecciona en el selector de la sección Presupuesto. |
| Tablas de la avería (`averia`, `refaccion_averia`, `mano_obra_averia`) | Lectura y escritura. Escritura de refacciones con los valores forzados; escritura del impuesto y montos del presupuesto; lectura de mano de obra existente para decidir si se muestra la tabla de servicios. |

**Datos mínimos requeridos:**

- Identificador del proyecto de la avería (`id_proyecto`) y la constante del proyecto Bridgestone.
- `id_refaccion` del registro "Llanta" para México.
- `id_impuesto` del registro "I.V.A. cero" para México.
- Campos de captura de refacción: `cantidad`, `tipo_costo`, `pieza` (`id_refaccion`), `no_parte`, `mano_obra`, `precio`.
- Campos de presupuesto: `id_impuesto`, `importe_mo`, `importe_refacciones`, `importe_diversos`, `presupuesto`.
- Existencia de registros en `mano_obra_averia` para la avería (para RF-10).

**Esquema de permisos.** El cambio es de lectura sobre catálogos y de escritura sobre las mismas entidades que ya escribe el módulo de Averías, con los mismos roles. Lo que **se restringe** es qué valores acepta el servidor para averías Bridgestone: la elección de tipo de costo, de refacción y de impuesto deja de estar en manos del usuario y pasa a estar determinada por la configuración del proyecto. No se agregan credenciales, servicios externos ni almacenamiento nuevo, por lo que no hay impacto de costo de infraestructura.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Averías Bridgestone con refacción distinta a "Llanta" | Debe ser 0 a partir de la liberación. Se mide sobre `refaccion_averia` de averías del proyecto Bridgestone creadas después del despliegue. |
| Averías Bridgestone con impuesto distinto a "I.V.A. cero" | Debe ser 0 a partir de la liberación. Se mide sobre el campo `id_impuesto` de las averías del proyecto. |
| Averías Bridgestone con mano de obra capturada | Debe ser 0 a partir de la liberación. Se mide sobre `mano_obra_averia` y sobre el campo `mano_obra` de las refacciones. |
| Rechazos/correcciones de averías Bridgestone por captura inválida | Debe reducirse respecto al periodo previo. Línea base y meta numérica pendientes de validar con operación/BI. |
| Tiempo promedio de captura de una avería Bridgestone | Se espera reducción al eliminar decisiones y campos. Línea base pendiente de validar con operación. |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Los IDs de "Llanta" e "I.V.A. cero" cambian o se desactivan en catálogos | La preselección deja de funcionar y la captura se bloquea o guarda un valor incorrecto. Mitiga RNF-04, pero exige coordinar cualquier cambio de catálogo con TI. |
| Las vistas ajustadas son compartidas con todos los proyectos | Un error de condicionamiento afecta a proyectos ajenos, incluido BMW, que ya introduce su propia bifurcación en la misma vista. Requiere pruebas de regresión explícitas. |
| Averías Bridgestone previas con mano de obra capturada | Sus montos siguen sumando al presupuesto aunque la sección esté oculta por omisión; de ahí RF-10. Si operación decide corregirlas, es un trabajo aparte. |
| El bloqueo solo en interfaz es evadible | Sin la validación en servidor, un envío manipulado o un formulario en caché podría registrar datos inválidos. Mitiga RF-14 a RF-16. |
| Bridgestone amplía su cobertura más adelante | Si el producto llegara a cubrir algo distinto de llantas, la restricción tendría que revertirse o parametrizarse a nivel de catálogo. La parametrización por proyecto (RF-17) reduce el costo de ese cambio. |
| Campos deshabilitados que no se envían | Un `disabled` en lugar de un mecanismo que conserve el valor rompería la validación existente de campos requeridos. Mitiga RNF-03. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Bridgestone es un único proyecto identificable | Se asume que `PaisMX.BridgestoneProjectId = 173` identifica al único proyecto Bridgestone vigente en México. |
| Existe un registro "Llanta" en el catálogo de refacciones de México | Se asume que hay un único registro que representa la llanta; si hubiera variantes (por medida, posición o tipo), la regla tendría que revisarse. |
| Existe un registro "I.V.A. cero" en el catálogo de impuestos de México | Se asume que el esquema fiscal de Bridgestone corresponde a un registro ya existente en el catálogo. |
| La captura de averías Bridgestone ocurre en la vista de distribuidor/taller | Se asume que no hay un flujo alterno de captura fuera de `_RefaccionesServiciosDealer` / `_PresupuestoDealer`. |
| El cálculo del presupuesto no requiere cambios | Se asume que la lógica existente de cálculo con impuesto cero ya produce el total correcto y no necesita ajuste. |
| Bridgestone opera únicamente en México | Se asume que no hay que contemplar otras variantes de país en este alcance. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Catálogo de refacciones | ¿Cuál es el `id_refaccion` exacto del registro "Llanta" en el catálogo de México, y es único o existen variantes que haya que distinguir? |
| Catálogo de impuestos | ¿Cuál es el `id_impuesto` exacto del registro "I.V.A. cero" en el catálogo de México, y cómo se llama literalmente el registro? |
| Parametrización | ¿Los identificadores se fijan como constantes en la configuración por proyecto de `PaisesService` (como `BmwProjectId`) o se prefiere una tabla de configuración administrable? |
| Alcance por país | ¿Bridgestone opera o va a operar en algún otro país donde deba aplicar la misma restricción? |
| Vista administrativa | ¿La pantalla de aprobación (`_RefaccionesServiciosAdmin`) debe ocultar también la columna "M.O." para Bridgestone, o se deja para poder revisar averías previas? |
| Documentos generados | ¿El PDF y los reportes de la avería deben dejar de mostrar "No. Parte" y "M.O." para Bridgestone, o es aceptable que salgan vacíos/en cero? |
| Histórico | ¿Se requiere corregir las averías Bridgestone ya capturadas con mano de obra o con un impuesto distinto, o se dejan como están? |
| Campo Diversos | ¿El campo "Diversos" del presupuesto debe seguir siendo capturable en Bridgestone o también se restringe? |
| Planeación | ¿Cuál es la fecha objetivo de liberación y en qué release entra este ajuste? |
