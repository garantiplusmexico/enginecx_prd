# Condensado — siga-issues-requests

Documento del 20 de agosto de 2026. **Para:** Javier (desarrollo). **Definición:** Juan Carlos.
**Contexto y verificación:** Pedro (agente de averías, Engine CX). Referencia: `api-contract.md` v2.8 §B.

## Decisiones

- El servicio de Issues (claims) ya está entregado y **se consume en vivo desde el 19 de julio de 2026**:
  el agente de WhatsApp crea issues reales, consulta estatus, sube evidencia y narra al cliente cuando
  su reporte se convierte en avería.
- Todo lo afirmado sobre el comportamiento actual está **probado empíricamente contra QA**, no leído
  de especificación.
- Quedan **cinco huecos**. Ninguno impide operar hoy; cada uno está tapado con un parche del lado del
  agente, y dos parches son frágiles.
- Lo nuevo se pide **como espejo de lo que ya existe** para claims, no inventando convenciones.
- El agente **nunca decide**: captura, guía, registra, consulta, notifica y escala. Convertir a avería
  es acción humana desde el panel.
- Las incidencias **no tienen folio**: solo `issueId` numérico. El folio del cliente (`INC-{issueId}`)
  lo compone y re-parsea el agente.

## Alcance / requerimientos

**Ya existe y funciona (live):** `POST CreateIssue`, `GET GetIssueById/{id}`, `GET GetIssues` (OData),
`PUT UpdateIssue/{id}`, `POST UploadIssueDocument`, `POST ConvertToClaim/{id}`.

**Petición 1 — Leer los documentos de una incidencia (prioridad alta; desbloquea al panel).**

- No hay forma de listar ni descargar los documentos de un issue. La pestaña de Evidencia del panel
  lleva meses vacía y el técnico convierte a avería sin poder ver las fotos del cliente.
- Descartado con sondas de solo lectura contra QA (11 de agosto): rutas adivinadas dan 404 de gateway;
  los endpoints de documentos de *claims* ven únicamente averías (`documentos/averias/{claimId}/…`);
  `ConvertToClaim` **no migra los documentos** (la avería CLM-151735 salió vacía).
- ⚠️ **Trampa: los espacios de ids colisionan.** Filtrar `GetClaimDocuments` por un `issueId` devuelve
  documentos de una avería vieja sin relación (PDFs de taller de un claim de 2020). Es el atajo a no tomar.
- Se pide: `GET claims/api/Issues/v1/GetIssueDocuments?$filter=issueId eq {n}` (listado con `documentId`,
  `issueId`, `documentType`, `originalFileName`, `uri`, `creationDate`) y
  `GET claims/api/Issues/v1/DownloadIssueDocument/{documentId}` (binario con su `Content-Type`, igual
  que `DownloadClaimDocument`).
- Catálogo de tipos ya existe en `GET claims/api/claims/v1/GetDocumentType`: Evidencia = 6,
  Fact. Mantenimiento = 7, Finiquito = 9, Prefactura = 12, Presupuesto = 13, Resolución = 14, Varios = 16.
  El agente solo escribe Evidencia (6).
- **No se pide almacenamiento**: SIGA ya guarda los archivos.

**Petición 2 — Campo de verdad para el motivo de cierre (prioridad media; el parche más frágil).**

- `UpdateIssue` solo acepta `{ description, status, odometer }`, así que el motivo de cierre se **anexa
  a la descripción** como línea entre corchetes: `[{acción} por {usuario} el {dd/mm/aaaa}: {detalle}]`
  (ej. `[Cerrada por Alexis el 18/08/2026: desgaste normal]`).
- Eso convirtió un campo de datos en **una convención de formato que dos repositorios respetan a ciegas**:
  el panel la escribe, el agente la parsea para narrar al cliente. Igual con `Información solicitada`.
- Riesgos: si un lado cambia el formato sin avisar, **el cliente recibe texto roto en su WhatsApp**; y la
  `description` va acumulando líneas administrativas en vez de ser solo lo que dijo el cliente.
- **Mínimo aceptable:** `closeReason`, `closedBy`, `closedAt` escribibles en `UpdateIssue` y devueltos
  en `GetIssueById`.
- **Lo que de verdad lo resuelve:** colección `annotations[]` en el issue (`text`, `author`, `createdAt`,
  `kind`), que cubre motivo de cierre **y** peticiones de información, y elimina los dos parsers.
- **Si SIGA ya tiene un concepto de anotación en otra entidad, reutilizarlo es mejor que inventar campos
  nuevos** — pregunta para JC.

**Petición 3 — Validar el estatus contra el catálogo en `UpdateIssue` (prioridad media; barato).**

- Hoy `status` es **texto libre**; hay una fila en QA cuyo estatus dice `"En revisiónnnnn"`. Un estatus
  mal escrito desde cualquier cliente llega tal cual al WhatsApp del cliente final.
- Catálogo pedido: 1 Registrada · 2 En revisión · 3 Información solicitada · 4 Convertida a avería
  (el issue lleva `claimId`) · 5 Cerrada. Un PUT con estatus inventado debe devolver **400** sin modificar nada.
- La tolerancia del agente (ignora mayúsculas/acentos, muestra lo desconocido verbatim) **se queda como
  red de seguridad**.

**Petición 4 — Observaciones de averías con fecha y hora en el GET (prioridad baja; petición del gerente).**

- Cuando la incidencia ya se convirtió, el agente encadena una consulta al claim. El gerente quiere que
  se narren también las **observaciones**, que hoy no vienen en el GET o vienen sin fecha — justo el dato
  para poder decir "la última nota es del martes".
- Se pide: observaciones del claim en el GET, cada una con **fecha, hora y autor**, ordenables por fecha.

**Petición 5 — Dos rarezas del gateway (prioridad baja; absorbidas en el agente).**

- **Casing inconsistente con castigo:** rutas de claims en minúsculas, rutas de Issues Capitalizadas.
  La variante equivocada devuelve **301**, y `HttpClient` de .NET **descarta el header `Authorization`
  al seguir un redirect** → el síntoma es un `401` inexplicable en una ruta que existe. El agente corre
  con `AllowAutoRedirect = false` por esto. Se pide normalizar el casing o declararlo en el contrato.
- **`creationDate` cambia de forma:** el `201` de `CreateIssue` la devuelve con zona
  (`2026-07-18T22:52:44.0492367Z`); `GetIssueById` la devuelve **sin zona** (`…049236`). El agente parsea
  ambas variantes. Se pide **devolver siempre la fecha con zona**.
- No se quiere que sigan siendo "folclore oral que cada nuevo integrante descubre a golpes".

## Actores

- **Pedro** — agente de averías (Engine CX); contexto y verificación. Dueño de las preguntas sobre qué
  hace el agente hoy y cómo se verifica.
- **Juan Carlos (JC)** — definición: qué se construye y en qué orden.
- **Javier** — desarrollo (destinatario del documento).
- **Ana** — panel web; hay que avisarle antes de desplegar la petición 2.
- **Alexis** — técnico que cierra incidencias desde el panel (ejemplo real de motivo de cierre).
- **Gerente** — solicitante de la petición 4 (observaciones con fecha).
- **Agente conversacional de Garantiplus** — atiende por WhatsApp, captura el reporte, valida contrato,
  recoge evidencia (fotos, notas de voz) y registra el issue.
- **Cliente final** — reporta la falla de su vehículo por WhatsApp y recibe la narración.
- **Técnico del panel web** — revisa la incidencia y decide si se convierte en avería formal.

## Riesgos / pendientes

- **Coordinación de la petición 2:** los dos repositorios (panel y agente) **tienen que migrar el mismo
  día**. Durante la ventana en que uno escribe el campo nuevo y el otro sigue leyendo la línea vieja,
  **el cliente deja de recibir la narración**. Hay que avisar a Ana antes de desplegar.
- **Trampa de colisión de ids** entre issues y claims (ver petición 1): un filtro por id equivocado
  devuelve documentos de otro cliente.
- **Todo está verificado contra SIGA QA**, incluido el agente que hoy responde WhatsApp real. No se da
  por hecho que producción se comporte igual que QA.
- **Pregunta abierta (petición 1):** ¿dónde se ven hoy los documentos de un issue dentro de SIGA? Si ya
  hay una pantalla que los muestra, el endpoint de lectura está a medio construir.
- **Pregunta abierta (petición 2):** ¿SIGA ya tiene un concepto de anotación en otra entidad que se pueda
  reutilizar? (para JC)
- **Para salir a producción hacen falta tres cosas del mismo sitio:** URL del gateway de producción,
  cuenta de servicio para el agente, y una ventana para re-verificar allí las rarezas del gateway. La
  batería de sondas de solo lectura ya existe y se puede correr en cuanto haya acceso.

## Fechas / hitos

- **19 de julio de 2026** — el agente empieza a consumir el servicio de Issues en vivo (QA).
- **18–19 de julio de 2026** — formas de cable del contrato verificadas empíricamente (`api-contract.md` §B).
- **11 de agosto de 2026** — sondas de solo lectura que descartaron las rutas de lectura de documentos.
- **20 de agosto de 2026** — fecha del documento de peticiones.
