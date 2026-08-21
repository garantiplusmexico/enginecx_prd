# Peticiones al servicio de Issues (SIGA)

**Para:** Javier (desarrollo) · **Definición:** Juan Carlos · **Contexto y verificación:** Pedro (agente de averías, Engine CX)
**Fecha:** 20 de agosto de 2026 · **Referencia:** `api-contract.md` v2.8 §B

---

## 1. Contexto en un minuto

Hay un **agente conversacional de Garantiplus** que atiende por WhatsApp a clientes que reportan una falla de su vehículo. El agente captura el reporte, valida el contra­to, recoge evidencia (fotos, notas de voz) y **registra una incidencia en SIGA**. Después, un técnico revisa esa incidencia desde un panel web y decide si se convierte en una avería formal. El agente nunca decide: captura, guía, registra, consulta, notifica y escala.

La incidencia vive en SIGA como un **Issue**, dentro del servicio de claims. Ese servicio ya está entregado y **lo consumimos en vivo desde el 19 de julio**: el agente crea issues reales, consulta su estatus, sube evidencia y narra al cliente cuando su reporte se convierte en avería. Todo lo que se afirma en este documento sobre el comportamiento actual está **probado empíricamente contra QA**, no leído de una especificación.

Lo que queda abierto son **cinco huecos**. Ninguno impide que el sistema funcione hoy, pero cada uno está tapado con un parche de nuestro lado, y dos de esos parches son frágiles de una forma que conviene entender antes de tocarlos. Este documento explica cada hueco, la forma exacta que esperamos en el cable, cómo lo vamos a verificar, y **qué parche nuestro desaparece cuando llegue** — ese último punto importa: en varios casos el arreglo no es cosmético, elimina una convención que hoy tienen que respetar dos repositorios distintos.

---

## 2. Lo que ya existe y funciona

Esto es el terreno actual. Sirve como referencia de estilo: donde pedimos algo nuevo, lo pedimos **como espejo de lo que ya hay**, no inventando convenciones.

| Operación | Ruta | Estado |
|---|---|---|
| Crear incidencia | `POST claims/api/Issues/v1/CreateIssue` | Live, consumida por el agente |
| Consultar incidencia | `GET claims/api/Issues/v1/GetIssueById/{id}` | Live |
| Listar incidencias | `GET claims/api/Issues/v1/GetIssues` (OData) | Live |
| Actualizar incidencia | `PUT claims/api/Issues/v1/UpdateIssue/{id}` | Live, usada por el panel |
| Subir evidencia | `POST claims/api/Issues/v1/UploadIssueDocument` | Live, consumida por el agente |
| Convertir a avería | `POST claims/api/Issues/v1/ConvertToClaim/{id}` | Live, acción humana desde el panel |

Forma de un issue tal como lo devuelve `GetIssueById`:

```json
{
  "issueId": 34,
  "contractId": 669521,
  "vinOrPlate": "MA6CB6CD3LT001316",
  "description": "El motor pierde potencia…",
  "odometer": 62300,
  "status": "Registrada",
  "creationDate": "2026-07-18T22:52:44.049236",
  "registeredBy": "SigaWeb",
  "claimId": null
}
```

Dos notas de vocabulario que se usan más abajo:

- Las incidencias **no tienen folio**. Solo hay un `issueId` numérico; el folio que ve el cliente (`INC-{issueId}`) lo compone el agente y lo vuelve a parsear al recibirlo.
- `claimId` se llena cuando un humano convierte la incidencia. A partir de ahí el agente narra al cliente "tu reporte se convirtió en la avería CLM-{claimId}".

---

## 3. Petición 1 — Leer los documentos de una incidencia

**Prioridad: alta.** Es la que desbloquea al panel.

### El problema

El agente **sube evidencia y funciona bien**: descarga la foto que el cliente mandó por WhatsApp y la envía a `UploadIssueDocument` como multipart, con `documentTypeId 6` (Evidencia). SIGA guarda el archivo y responde `201 { documentId, issueId, "Documento guardado." }`. Verificado en vivo. **No estamos pidiendo almacenamiento**: SIGA ya guarda los archivos y el agente no necesita ninguno propio.

Lo que no existe es la puerta para volver a leerlos. **No hay forma de listar ni descargar los documentos de un issue.** Consecuencia directa: el panel tiene una pestaña de Evidencia que lleva meses vacía, y el técnico toma la decisión irreversible de convertir una incidencia en avería **sin poder ver las fotos que mandó el cliente**.

### Lo que ya descartamos (sondas de solo lectura contra QA, 11 de agosto)

Esto no es una suposición; agotamos los caminos antes de pedir el endpoint:

1. **Rutas adivinadas** — `GetIssueDocuments`, `DownloadIssueDocument` y cinco variantes más → 404 de gateway en texto plano, o sea que no están mapeadas.
2. **Los endpoints de documentos de _claims_ ven únicamente averías.** `GET claims/api/claims/v1/GetClaimDocuments` funciona perfectamente, pero todos sus `uri` son `documentos/averias/{claimId}/…` y no hay una sola fila de agosto pese a las subidas del agente.
3. **`ConvertToClaim` no migra los documentos.** Convertimos un issue con evidencia y la avería resultante (CLM-151735) salió vacía.

Conclusión: los documentos de issues aterrizan en un almacén aparte, sin superficie de lectura.

### ⚠️ Trampa importante: los espacios de ids colisionan

**No resuelvas esto filtrando documentos de claims por el id del issue.** Los ids de issue y de claim son secuencias independientes que se solapan, así que:

```
GET claims/api/claims/v1/GetClaimDocuments?$filter=claimId eq 430
```

…cuando 430 es un **issueId**, devuelve los documentos de una **avería vieja sin ninguna relación** — en nuestra prueba, PDFs de taller de un claim de 2020. Parece que funciona, devuelve archivos, y son de otro cliente. Es el atajo que hay que no tomar.

### Lo que pedimos

El espejo de lo que ya existe para claims, que es la forma que el panel sabe consumir.

**Listado:**

```
GET claims/api/Issues/v1/GetIssueDocuments?$filter=issueId eq {n}
```

```json
{
  "value": [
    {
      "documentId": 34,
      "issueId": 265,
      "documentType": "Evidencia",
      "originalFileName": "evidencia-ME3a1b2c3.jpg",
      "uri": "documentos/issues/265/evidencia-ME3a1b2c3.jpg",
      "creationDate": "2026-08-20T10:14:22Z"
    }
  ],
  "pagination": { }
}
```

**Descarga:**

```
GET claims/api/Issues/v1/DownloadIssueDocument/{documentId}
```

→ el binario con su `Content-Type`, igual que `DownloadClaimDocument`.

El catálogo de tipos ya existe en `GET claims/api/claims/v1/GetDocumentType` (ruta en minúsculas): Evidencia = 6, Fact. Mantenimiento = 7, Finiquito = 9, Prefactura = 12, Presupuesto = 13, Resolución = 14, Varios = 16. El agente solo escribe Evidencia.

### Cómo lo verificamos

Subimos una foto conocida a un issue de QA, la listamos por `issueId` y la descargamos; los bytes tienen que coincidir con el original. El guión ya está escrito de nuestro lado.

### Pregunta abierta que puede acortar este trabajo

**¿Dónde se ven hoy los documentos de un issue dentro de SIGA?** El servicio responde "Documento guardado", así que los archivos existen en algún lado. Si ya hay una pantalla que los muestra, el endpoint de lectura está a medio construir y no hay que empezar de cero.

---

## 4. Petición 2 — Un campo de verdad para el motivo de cierre

**Prioridad: media.** Es el parche más frágil que tenemos.

### El problema

Cerrar una incidencia sin convertirla ya funciona desde el panel: `UpdateIssue` pone el estatus en `"Cerrada"`. El problema es **dónde queda el motivo**. Como el request es solo:

```json
{ "description": "…", "status": "…", "odometer": 0 }
```

…no hay campo donde ponerlo. Así que el motivo se **anexa a la descripción del issue** como una línea entre corchetes:

```
[{acción} por {usuario} el {dd/mm/aaaa}: {detalle}]
```

Por ejemplo: `[Cerrada por Alexis el 18/08/2026: desgaste normal]`.

Eso convirtió un campo de datos en **una convención de formato que dos repositorios distintos tienen que respetar a ciegas**: el panel la escribe, y el agente la parsea para narrarle al cliente por qué se cerró su caso. Lo mismo pasa con `Información solicitada`, donde el comentario del técnico pidiendo más datos viaja por el mismo canal y el agente se lo lee al cliente por WhatsApp.

Dos consecuencias de eso:

- Si cualquiera de los dos lados cambia el formato sin avisar al otro, **el cliente recibe texto roto en su WhatsApp**.
- La `description` debería ser lo que dijo el cliente y nada más. Hoy va acumulando líneas administrativas.

### Lo que pedimos

**Mínimo aceptable:** `closeReason` (texto), `closedBy` y `closedAt` como campos del issue, escribibles en `UpdateIssue` y devueltos en `GetIssueById`.

**Lo que de verdad lo resuelve:** una colección de anotaciones en el issue, algo como:

```json
"annotations": [
  {
    "text": "desgaste normal",
    "author": "Alexis",
    "createdAt": "2026-08-18T16:40:00Z",
    "kind": "Cerrada"
  }
]
```

Con eso se cubren de una vez el motivo de cierre **y** las peticiones de información, y los dos parsers desaparecen en lugar de mudarse de sitio.

**Si SIGA ya tiene un concepto de anotación en otra entidad, reutilizarlo es mejor que inventar campos nuevos.** Esa es una pregunta para JC.

### Cómo lo verificamos

Cerrar un issue de QA con motivo, leerlo de vuelta en el GET, y confirmar que la `description` quedó limpia.

### Qué muere de nuestro lado

El parser del agente y el del panel, y la contaminación de la descripción. **Ojo con la coordinación:** los dos repositorios tienen que migrar el mismo día, porque durante la ventana en que uno escribe en el campo nuevo y el otro sigue leyendo la línea vieja, el cliente deja de recibir la narración. Hay que avisar a Ana (panel) antes de desplegar.

---

## 5. Petición 3 — Validar el estatus contra el catálogo en `UpdateIssue`

**Prioridad: media.** Barato y elimina una clase entera de error.

### El problema

Hoy el `status` del issue es **texto libre**: `UpdateIssue` acepta cualquier cadena. Hay una fila de prueba en QA cuyo estatus dice literalmente `"En revisiónnnnn"`.

El agente lo resuelve de forma tolerante —reconoce los nombres conocidos sin distinguir mayúsculas ni acentos, y lo desconocido lo muestra verbatim con una guía genérica— precisamente porque no puede confiar en la escritura exacta. Eso está bien como red de seguridad, pero significa que **un estatus mal escrito desde cualquier cliente llega tal cual al WhatsApp del cliente final**.

### Lo que pedimos

Que `UpdateIssue` acepte solo los valores del catálogo y rechace el resto con 400:

| statusId | statusName | Significado |
|---|---|---|
| 1 | Registrada | Capturada por el agente, pendiente de revisión |
| 2 | En revisión | Un técnico o gerente la está revisando |
| 3 | Información solicitada | Se le pidieron datos o evidencia adicional al cliente |
| 4 | Convertida a avería | Procedió, se creó una avería formal (el issue lleva `claimId`) |
| 5 | Cerrada | No procede, cerrada sin convertir |

### Cómo lo verificamos

Un PUT con un estatus inventado debe devolver 400 y no modificar nada.

### Qué muere de nuestro lado

Nada: la tolerancia del agente se queda como red de seguridad. Lo que desaparece es la posibilidad de que un cliente lea un estatus con una errata.

---

## 6. Petición 4 — Observaciones de averías con fecha y hora en el GET

**Prioridad: baja.** Petición del gerente.

Cuando una incidencia ya se convirtió en avería, el agente encadena una segunda consulta al claim para narrarle al cliente el estatus real de su caso. El gerente quiere que además se narren las **observaciones** de la avería, y hoy no vienen en la respuesta del GET, o vienen sin fecha — que es justo el dato que hace falta para poder decir "la última nota es del martes".

**Lo que pedimos:** las observaciones del claim en el GET, cada una con su fecha, hora y autor.

**Cómo lo verificamos:** un claim de QA con dos observaciones debe devolverlas ordenables por fecha.

---

## 7. Petición 5 — Dos rarezas del gateway

**Prioridad: baja.** Ninguna nos bloquea, las dos están absorbidas en el código del agente. Las traemos para que se decida si se normalizan o se documentan formalmente — lo que no queremos es que sigan siendo folclore oral que cada nuevo integrante descubre a golpes.

### El casing es inconsistente y castiga con un redirect

Las rutas de **claims van en minúsculas** y las de **Issues van Capitalizadas**. Escribir la variante equivocada no devuelve 404: devuelve **301**, y `HttpClient` de .NET **descarta el header `Authorization` al seguir un redirect**. O sea que el síntoma que ve quien lo padece es un `401` inexplicable en una ruta que existe. El agente corre con `AllowAutoRedirect = false` exactamente por esto.

**Lo que pedimos:** normalizar el casing, o declararlo explícitamente en el contrato para que quede escrito.

### `creationDate` cambia de forma según por dónde salga

El `201` de `CreateIssue` la devuelve con zona (`2026-07-18T22:52:44.0492367Z`); `GetIssueById` la devuelve **sin zona** (`2026-07-18T22:52:44.049236`). El agente parsea las dos variantes para no romperse.

**Lo que pedimos:** devolver siempre la fecha con zona.

**Cómo lo verificamos:** la misma ruta en ambos casings responde igual, y el GET y el POST devuelven el mismo formato de fecha.

---

## 8. Nota final: la pista de producción

Todo lo anterior está verificado contra **SIGA QA**. El agente que hoy responde WhatsApp real corre contra QA también. Para que exista una salida a producción hacen falta tres cosas que conviene pedir juntas porque vienen del mismo sitio: la **URL del gateway de producción**, una **cuenta de servicio** para el agente, y una **ventana para re-verificar allí las rarezas de arriba** — no damos por hecho que producción se comporte igual que QA. La batería de sondas de solo lectura ya existe y se puede correr en cuanto haya acceso.

---

## 9. Referencias

- `api-contract.md` §B — el contrato completo del servicio de Issues, con las formas de cable verificadas empíricamente entre el 18 y el 19 de julio.
- `api-contract.md` §B6 — la convención de línea de auditoría descrita en la petición 2, incluida la advertencia de que es un contrato entre dos repositorios.
- `api-contract.md` §B3 — el detalle de las sondas del 11 de agosto que descartaron las rutas de lectura de documentos.

Cualquier duda sobre lo que hace el agente hoy o sobre cómo verificamos algo, con Pedro. Las decisiones de qué se construye y en qué orden, con Juan Carlos.
