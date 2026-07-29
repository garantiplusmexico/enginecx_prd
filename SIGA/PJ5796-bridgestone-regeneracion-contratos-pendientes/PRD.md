# PRD — Bridgestone: Regeneración de contratos pendientes (administrador general)

| Campo | Detalle |
|---|---|
| Proyecto / Sistema | API de SIGA (servicio Contracts) + Landing de Bridgestone |
| Tipo | Feature (herramienta operativa) que remedia un bug de contratos huérfanos |
| Área / empresa | GarantiPlus / Bridgestone (Transversal LATAM) |
| Versión | v0.1 |
| Fecha | 2026-07-14 |
| Autores | Carlos Castellanos |
| Revisión / liderazgo | Aldo Álvarez (Dir. TI) — por confirmar |

---

## 1. Resumen del cambio

Cuando el landing de Bridgestone registra una garantía, el sistema primero guarda el snapshot del registro y la factura, y **después** crea el contrato en SIGA. Si ese segundo paso falla, el registro queda guardado pero sin contrato: el cliente no recibe su contrato y el reintento por el landing se bloquea con "el folio ya existe".

Este cambio agrega una **herramienta operativa, solo para el rol Administrador General**, que:
- **Lista** los registros de Bridgestone que quedaron sin contrato de SIGA (pendientes).
- Permite **regenerar/completar** el contrato de cada uno, reutilizando el snapshot y la factura ya guardados (sin volver a capturar datos, sin re-subir la factura), generando contrato + PDF + flyer y dejando el registro enlazado y en estatus "Registrado".

Resultado esperado: resolver el incidente actual (2 registros de El Salvador atascados) y dejar una herramienta reutilizable para casos futuros, sin depender de intervención manual en base de datos.

---

## 2. Contexto del cambio

**Cómo funciona hoy:** el alta desde el landing hace tres pasos: (1) inserta el registro en `bs_registro` (estatus "Pendiente", sin contrato) y sube la factura al almacenamiento, confirmando ese guardado; (2) crea el contrato en SIGA; (3) solo si (2) tuvo éxito, enlaza el `id_contrato` al registro y genera el flyer.

**El problema:** cuando el paso (2) falla (por ejemplo un timeout o el reinicio del contenedor del servicio), el registro y la factura ya quedaron guardados (paso 1 confirmado), pero no hay contrato en SIGA y el enlace (paso 3) nunca ocurre. El registro queda "Pendiente" sin `id_contrato`. Al reintentar desde el landing, una validación propia rechaza el envío con "el folio de factura ya fue registrado", así que el caso queda atascado.

**Frecuencia e impacto:** ocurre de forma esporádica (ligado a intermitencias del servicio), pero es de alto impacto porque el cliente final se queda sin su contrato de garantía y el distribuidor no tiene forma de resolverlo por sí mismo.

**Incidente que dispara este PRD:** reporte de soporte de Bridgestone (El Salvador, distribuidor Diparvel Constitución). Dos registros quedaron sin contrato. Se verificó en producción que efectivamente **no existe** contrato en SIGA para ninguno de los dos (no es un contrato "perdido", nunca se creó), por lo que la acción correcta es completarlos, no recrearlos desde cero.

---

## 3. Alcance del cambio

**Qué entra:**

| Elemento | Descripción |
|---|---|
| Listado de pendientes (admin) | Endpoint + sección de UI que muestran los registros de Bridgestone sin contrato de SIGA, con distribuidor, país/grupo/sucursal, folio de factura, fecha, cliente y estatus |
| Acción de regeneración (admin) | Endpoint + botón por fila que completa el contrato en SIGA a partir del registro existente, y enlaza el `id_contrato` |
| Restricción a Administrador General | Ambas funciones solo disponibles para el rol Administrador General (control real en el backend; la UI solo lo muestra a ese rol) |
| Reutilización de datos | Se reconstruye la petición a SIGA desde los datos ya guardados (registro + llantas); se genera contrato, PDF y flyer |
| Salvaguardas | No se puede regenerar dos veces el mismo registro; manejo claro de errores; el registro sigue reintenable si vuelve a fallar |

**Qué NO entra:**

| Exclusión | Justificación |
|---|---|
| Volver a capturar datos o re-subir la factura | El snapshot y la factura ya existen; se reutilizan |
| Vigencia con fecha de la venta original | SIGA no permite fecha de inicio en el pasado; el contrato regenerado inicia vigencia el día de la regeneración (decisión de negocio confirmada) |
| Landing de BMW | Tiene el mismo patrón de fallo, pero queda fuera de alcance (posible fase futura) |
| Corregir la causa raíz del fallo de creación (timeouts) | Esta es una herramienta de remediación, no un cambio al flujo de alta |

---

## 4. Requerimientos funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-01 | Listar pendientes | Mostrar los registros de Bridgestone sin contrato de SIGA, con identificador de registro, distribuidor, país/grupo/sucursal, folio de factura, fecha de creación, cliente y estatus |
| RF-02 | Regenerar contrato | A partir de un registro pendiente, crear el contrato en SIGA reutilizando sus datos y los del distribuidor almacenado, y generar PDF y flyer |
| RF-03 | Enlazar sin duplicar el registro | Al crearse el contrato, enlazar el `id_contrato` y marcar el registro como "Registrado"; nunca crear un nuevo registro ni re-subir la factura |
| RF-04 | Salvaguarda de estado | Si el registro no existe → error "no encontrado"; si ya tiene contrato → informar el contrato existente sin crear otro |
| RF-05 | Evitar duplicados por doble clic | Bloquear la ejecución concurrente/repetida del mismo registro (marca temporal "Procesando"); si otro proceso ya lo tomó, informar |
| RF-06 | Vigencia = fecha de regeneración | El contrato regenerado inicia vigencia el día en que se regenera |
| RF-07 | UI de regeneración | Sección solo para admin que lista pendientes y regenera por fila, con confirmación previa, indicador de carga, mensajes de éxito/error y actualización del listado (la fila desaparece al enlazarse) |
| RF-08 | Reporte de error accionable | Si la creación vuelve a fallar, dejar el registro reintenable y mostrar al admin el mensaje de error de SIGA; si el contrato se creó pero no se pudo enlazar, informar el `id_contrato` creado para atención manual (para no duplicar) |

---

## 5. Requerimientos no funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RNF-01 | Seguridad / permisos | Ambas funciones restringidas al rol Administrador General; el control efectivo está en el backend, la UI solo condiciona la visibilidad |
| RNF-02 | Auditoría | Registrar cada petición y respuesta en LogsMonitor (patrón obligatorio de la API de SIGA) |
| RNF-03 | Idempotencia | La misma acción no puede generar dos contratos para un registro |
| RNF-04 | Estándares de código | Cumplir CODING_GUIDELINES de la API de SIGA (código en inglés, consultas parametrizadas, configuración por Options, mensajes de usuario en español) |

---

## 6. Componentes e integraciones afectadas

| Componente / Integración | Tipo de cambio | Descripción |
|---|---|---|
| API SIGA — servicio Contracts (controller Bridgestone) | Modificación | Dos endpoints nuevos: listado de pendientes y regeneración, restringidos a Administrador General, con auditoría |
| API SIGA — servicios/consultas de Bridgestone | Nuevo / Modificación | Lector completo del registro + llantas; consulta de pendientes; servicio orquestador de regeneración; reutiliza la creación de contrato, el enlace y el flyer ya existentes |
| API Gateway (KrakenD) | Modificación | Registrar las 2 rutas nuevas en la config del gateway (`Services/ApiGateway/krakend.json`) — KrakenD declara cada endpoint explícitamente — y **redeployar el ApiGateway** en QA y PROD. Sin esto, las rutas nuevas devuelven 404 en el gateway aunque el servicio las implemente. (El gateway de dev local, YARP, usa catch-all y NO requiere cambios.) |
| Base de datos `bs_registro` / `bs_llantas` | Solo lectura + actualización de enlace | Se leen los datos guardados y se actualiza `id_contrato` + estatus del registro; no se insertan filas nuevas |
| Almacenamiento de la factura (S3) | Solo lectura | No se re-sube; el archivo ya existe |
| Landing de Bridgestone | Nuevo / Modificación | Nueva sección "Contratos pendientes / Regeneración" (listado + botón por fila), visible solo para admin; nuevos llamados a la API; indicador de versión |

---

## 7. Preguntas abiertas

| Tema | Pregunta abierta |
|---|---|
| Caso "contrato huérfano" | Riesgo (bajo, ya descartado para el incidente actual) de que exista un contrato creado en un intento previo pero no enlazado: ¿basta con la salvaguarda + verificación manual previa, o se invierte en un identificador de vehículo determinista para detectarlo automáticamente en reintentos? |
| Regeneración en lote | ¿Suficiente uno por uno (recomendado), o se requiere "regenerar todos"? |
| Comunicación de vigencia | Confirmar con negocio/soporte que la vigencia del contrato regenerado inicie el día de la regeneración (no el día de la venta) |

---

*Engine CX — Departamento de Desarrollo*
*Versión: v0.1*
