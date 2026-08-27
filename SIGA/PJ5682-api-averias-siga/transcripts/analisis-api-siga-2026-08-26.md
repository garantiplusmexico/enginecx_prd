# Retomar: PRD de cambios para la API de SIGA (`api-averias-siga`)

**Escrito:** 2026-08-26 · **Actualizado:** 2026-08-26 (script v2 y segunda cuenta de pruebas) · **Autor:** Omar André Lara Saldaña (omar.lara@enginecx.com)
**Para qué sirve este documento:** permitir retomar en una conversación nueva, sin contexto previo, la formulación del PRD técnico de cambios a la API de SIGA. Contiene el estado exacto de lo hecho, la evidencia recogida, el script de verificación, lo que falta verificar y por qué importa cada punto, y el plan de redacción del PRD.

> **Cómo arrancar la próxima sesión.** Abre Claude Code en `/Users/omarsaldanna/Downloads/trabajo/averias`, pásale este archivo y di: *"retomemos el PRD de la API de SIGA según este documento"*. Luego corre el script del §4 y pega la salida.

---

## 1. Dónde estamos

### 1.1 Lo que ya está terminado y publicado

El **PRD del Copiloto de Averías** está escrito y publicado en el repo central de PRDs.

| | |
| --- | --- |
| **Ruta en el repo** | `Desarrollos_internos/PJ1544-copiloto-averias/PRD.md` |
| **Clon local** | `/Users/omarsaldanna/Documents/enginecx_prd` |
| **Versión** | v0.2 — 723 líneas, 14 secciones, 68 RF, 17 RNF, 5 diagramas mermaid, 45 preguntas abiertas |
| **Commit** | `d7d854f` en `origin/main` |
| **Copia local de respaldo** | `api-siga/PRD-averias-v0.2-copia.md` (junto a este documento) |
| **Fuentes** | 17 transcripts originales + 17 condensados en `transcripts/` y `transcripts-resumidos/` |

Ese PRD describe **qué queremos automatizar**. El PRD que falta escribir describe **qué necesitamos de la API de SIGA para poder hacerlo**. Son documentos hermanos y el segundo se deriva del primero.

### 1.2 Lo que falta: el PRD de la API

**Encargo textual del usuario:**

> Quiero un nuevo PRD igualmente partido por etapas (mismas que son nuestros bloqueos de la API de SIGA). Quiero que me ayudes a definir qué necesitamos que haga la API de SIGA para que tengamos desbloqueados todos los procesos que actualmente nos están bloqueando. Quiero un PRD técnico para el equipo de desarrollo de la API del SIGA. Quiero que sea minuciosamente planificado y escrito ese PRD, pues **una vez que se los haya pasado al equipo de desarrollo no habrá chance de modificarlo**, y con los cambios que haya hecho se va a ver demasiado mal que se los esté cambiando de último momento. Entonces, parte del PRD de averías: qué es exactamente lo que necesitamos hacer de forma que todo este proceso pueda ser automatizado, y formula un PRD para "api-averias-siga" donde digas, para cada paso de averías, qué nos falta en la API y describe qué acciones y funciones debe tener. No quiero errores. Planea al detalle. Igualmente usa `/pm-ai:pm-prd`.

**Implicaciones que hay que respetar:**

1. **Una sola entrega.** No hay iteración con el equipo de SIGA. Todo lo que se pida tiene que estar bien la primera vez.
2. **Nada se pide sin verificar.** Pedir algo que ya existe daña la credibilidad de todo el documento. De ahí el script del §4.
3. **Debe estar organizado por etapas**, las mismas cinco del PRD de averías, porque las etapas *son* los bloqueos.
4. **Es un PRD técnico**, no de producto: contratos de endpoint, métodos, rutas, cuerpos de petición y respuesta, códigos de error, permisos y criterios de aceptación.

---

## 2. Contexto imprescindible del proceso de averías

Sin esto no se puede justificar ninguna petición a la API. Resumen mínimo; el detalle está en el PRD v0.2.

### 2.1 El proceso real

1. El cliente lleva el vehículo a la agencia. En más del 90% de los casos llega **sin llamar antes**.
2. **La agencia registra la avería en SIGA** y sube evidencia. SIGA exige al menos un documento en cada uno de tres tipos —evidencias, presupuesto, fotos de odómetro— para dejarla avanzar.
3. SIGA **asigna la avería a un técnico** (round-robin; en México son dos) y **le manda un correo** con el asunto `Asignación de avería {folio} / Vin {VIN}`. **Ese correo trae solo folio y VIN.**
4. La agencia pasa la avería a **`Validación`**. Ahí arranca el compromiso de **48 horas hábiles** y solo entonces el técnico puede trabajarla.
5. El técnico descarga el certificado, revisa evidencia y **dictamina `Aceptada` o `No procede garantía`**. Es el único tramo de estatus que el área técnica puede mover.
6. Redacta la **resolución** en un machote de Word externo a SIGA, tecleando a mano datos que ya están en pantalla, y la sube. **Ese documento tiene valor legal.**
7. Si fue aceptada, la agencia mueve `Taller` → `Solucionada` y se procesa el pago.

### 2.2 Las cinco etapas del desarrollo

| Et. | Qué automatiza | Escritura en SIGA | Desbloqueo que necesita |
| :-: | --- | --- | --- |
| **1** | Dictamen de improcedencia con resolución redactada; plantilla con datos capturados para los otros dos casos; correo al técnico en el hilo | **Ninguna** | **Nada — puede arrancar hoy** |
| **2** | Lo mismo, más subir la resolución y marcar `No procede garantía` | Documento + estatus, solo improcedencias | Endpoint de resolución de averías |
| **3** | Agente de presupuesto: cobertura, que el presupuesto cuadre, comparativo, resolución de autorización, **propone autorizar**; el técnico aprueba caso por caso | `Aceptada`, **solo tras aprobación humana** | Refacciones e importes; endpoint de aceptación |
| **4** | El humano revisa un expediente ya armado: cola priorizada, aprobación en bloque, cierre hasta el pago | Igual que 3 | Ninguno nuevo; depende de exactitud ≥95% en la etapa 3 |
| **5** | Colombia y Chile operados desde México | Igual, por país | **APIs de Colombia y Chile — no existen** |

### 2.3 Los principios que no se negocian

Hay que conservarlos al redactar el PRD de la API, porque **determinan la forma de los endpoints que se piden**:

1. **El agente puede rechazar por sí mismo, nunca autorizar por sí mismo.** Un rechazo mal fundado se reclama y se corrige; una autorización mal fundada se paga. Por eso el endpoint de aceptación **debe exigir un campo de atribución del humano que aprobó**.
2. **Ningún rechazo sin resolución adjunta.** Primero el documento, después el estatus. Por eso conviene pedir que el endpoint de resolución **acepte o exija la referencia al documento**.
3. **Ningún fallo silencioso.** Los errores deben ser explícitos y distinguibles; nunca un 200 que en realidad no hizo nada, ni un filtro que devuelve vacío por nombre de propiedad mal escrito.
4. **El condicionado del contrato concreto es la única fuente normativa.** Ninguna regla de cobertura se codifica como constante.
5. **Sesgo hacia la remisión.** Ante ambigüedad, el caso va a una persona.

### 2.4 Cifras que sustentan las peticiones

De `transcripts/tablero-averias-latam-2026.md` (corte 14/08/2026):

- **México ene–jul 2026: 1 582 averías. 604 (38.2%) terminaron en `No procede garantía`.**
- De esos rechazos, **330 (54.6%)** responden a cuatro causales verificables contra el condicionado: intervalo de mantenimiento excedido **29.1%**, componente excluido **15.7%**, fuga excluida **6.8%**, sin vigencia **3.0%**. Equivale al **20.9% de todas las averías del país**.
- Causales que exigen valorar la pieza (y siempre salen como duda): **33.5% de los rechazos**.
- LATAM ene–jul 2026: México 1 582 · Chile 519 · Colombia 749 = **2 850 en 7 meses (~4 900/año)**, con **7 técnicos** (2 MX, 2 COL, 3 CL) ≈ **700 averías por persona al año**.
- Tiempo de resolución MX: mediana **4.1 días**, media 16.5, p90 **50.1**. Compromiso contractual: **48 horas hábiles**.
- **El objetivo de negocio** (instrucción directiva de Héctor, audio del 2026-08-25): consolidar Colombia y parte de Chile en México y operar el mismo volumen con **4–5 personas**, o sea **+45% a +75% de capacidad por persona**.

### 2.5 Frases textuales útiles para argumentar

- David Simancas, sobre el dolor central: *"si bien es un intervalo de mantenimientos que sabemos que no va a aplicar, hay que crear la avería, hay que bajar la información, hay que generar la resolución, hay que poner datos, hay que poner información, enviarla"*.
- David, sobre dónde quiere el resultado: *"lo ideal sería verlo en el SIGA para evitarnos todo este tema de que a nosotros nos llegue y retrabajar"*.
- David, sobre la latencia: *"al momento yo dijera… ya se nos fueron 8 horas o 9 horas"*.
- David, sobre el auto-rechazo actual de SIGA —**el antipatrón a citar**—: *"el sistema SIGA lo rechaza, pero no carga resolución, no carga información, no carga nada, simplemente cierra la avería y la rechaza de manera automática, no deja más información"*.
- David, sobre la captura manual: *"el equipo tiene que capturar esto de manera manual. Cada que generan una resolución tienen que teclear número, teclear todo"*.
- David, sobre el valor legal: *"esa resolución es una protección legal también… todo debe vivir en SIGA, rechazos, autorizaciones, todo debe estar dentro de SIGA para poder hacer auditorías"*.
- David, sobre los límites de su rol: *"nosotros o desde el área técnica los únicos estatus que podemos cambiar son el estatus de que está en validación y que pasan a aceptada o a rechazada, nada más"*.
- Gisela Aldana, sobre el orden del filtro: *"primero validamos tres cosas: que esté activo, que no sean operaciones no incluidas y que no sean exclusiones del contrato"*.

---

## 3. Evidencia ya recogida sobre la API

**Verificado el 2026-08-26** contra los OpenAPI vivos. Los specs están guardados en `api-siga/openapi-2026-08-26/`.

### 3.1 Inventario de servicios

Existen **cuatro** microservicios, y solo cuatro:

- `https://qa-siga-api.garantiplus.com/authentication/openapi/v1.json`
- `https://qa-siga-api.garantiplus.com/catalogs/openapi/v1.json`
- `https://qa-siga-api.garantiplus.com/contracts/openapi/v1.json`
- `https://qa-siga-api.garantiplus.com/claims/openapi/v1.json`

Probados y devuelven **404**: `payments`, `reports`, `notifications`, `documents`, `users`, `sales`, `policies`, `vehicles`, `workshops`, `dealers`, `audit`, `files`, `storage`, `integrations`, `webhooks`.

**Nota de acceso:** las URLs `/{servicio}/scalar/v1` son solo la cáscara de la SPA de Scalar y no sirven para leer el contrato. El JSON está en `/{servicio}/openapi/v1.json`.

Cambio detectado entre el 2026-08-24 y el 2026-08-26: únicamente `AvailableProductResponse` ganó `taxAmount` y `total`. **Superficie de rutas y esquemas sin cambios.**

### 3.2 Endpoints existentes hoy

**`claims`**
```
POST   /api/Claims/v1/CreateClaim
GET    /api/Claims/v1/GetClaims                        (OData)
GET    /api/Claims/v1/GetClaimDocuments                (OData)
POST   /api/Claims/v1/UploadClaimDocument              (multipart: file, claimId, documentType)
GET    /api/Claims/v1/DownloadClaimDocument/{documentId}
GET    /api/Claims/v1/DownloadClaimDocumentsZip/{claimId}
GET    /api/Claims/v1/GetDocumentType                  (OData)
GET    /api/Claims/v1/GetDocumentTypeById/{id}
POST   /api/Issues/v1/CreateIssue
GET    /api/Issues/v1/GetIssues                        (OData)
GET    /api/Issues/v1/GetIssueById/{id}
PUT    /api/Issues/v1/UpdateIssue/{id}                 (description, status, odometer)
DELETE /api/Issues/v1/DeleteIssue/{id}
POST   /api/Issues/v1/ConvertToClaim/{id}
POST   /api/Issues/v1/UploadIssueDocument
GET    /api/Workshops/v1/countries | states | municipalities
POST   /api/Workshops/v1/workshops | verify-email
```

**`contracts`**
```
GET    /api/Contracts/v1/GetAllContracts               (OData)
GET    /api/Contracts/v1/GetContractById/{contractId}
GET    /api/Contracts/v1/GetContractPdfById/{contractId}
GET    /api/Contracts/v1/GetContractPdfDataById/{contractId}    ← texto extraído
GET    /api/Contracts/v1/GetContractPaymentInfo/{contractId}
GET    /api/Contracts/v1/GetAvailableProducts
GET    /api/Contracts/v1/GetPaymentStatus
POST   /api/Contracts/v1/CreateContract/{projectId}
POST   /api/Contracts/v1/ActivateContract/{contractId}
POST   /api/Contracts/v1/GeneratePdf/{contractId}
POST   /api/PaymentOrders/v1/CreatePaymentOrder
```

**`authentication`**
```
POST   /api/Auth/v1/Login              (username, password → accessToken, refreshToken, expiresIn, tokenType)
POST   /api/Auth/v1/ValidateToken
POST   /api/Auth/v1/ForgotPassword
POST   /api/Auth/v1/ResetPassword
GET    /api/Roles/v1/GetAllRoles
GET    /api/Roles/v1/GetRoleById/{id}
```

**`catalogs`** — Advisor, Dealers, Locations, PointsOfSale, ProductTypes, Projects, SalesChannels, TaxCatalogs, Vehicle (marcas, modelos, propulsión, uso). Ningún catálogo de averías.

Seguridad: `Bearer` como `apiKey` en header `Authorization`, aplicado globalmente. **La autenticación sí se exige** — los listados sin token devuelven 401.

### 3.3 Esquemas relevantes, tal como están hoy

```
ClaimResponse:      claimId, policyId, contractId, description, creationDate,
                    statusId, technicianId, technicianName, registeredBy, trackingUrl
                    ← NO trae: vinOrPlate, odometer, validationDate, motivo de rechazo,
                               componente, projectId/país, productName

IssueResponse:      issueId, contractId, vinOrPlate, description, odometer,
                    status, creationDate, registeredBy, claimId
                    ← las incidencias SÍ tienen VIN y odómetro; las averías no

UpdateIssueRequest: description, status, odometer        ← el ÚNICO status escribible

ClaimDocumentQueryResponse: documentId, claimId, statusId, mimeType, date,
                    documentType (string), originalFileName, uri
                    ← NO trae documentTypeId

ContractListResponse: contractId, status, registrationDate, contractStartDate,
                    contractEndDate, dealerName, productName, total,
                    beneficiaryType, beneficiaryName, companyName, vin

ContractInfo:       contractId, status, registrationDate, paymentDate,
                    cancellationDate, paymentMethod, productName,
                    contractStartDate, contractEndDate,
                    priceWithoutTaxes, taxes, total
                    ← son importes DEL CONTRATO. NO trae límite por avería,
                      límite de contrato ni valor de venta del vehículo

VehicleInfo:        brand, model, version, year, kilometers, horsepower,
                    cubicCapacity, purchaseDate, vin, engineNumber,
                    factoryWarranty, timelyServices, usageType, propulsionType
                    ← `timelyServices` es un flag capturado en la VENTA,
                      no un historial de mantenimientos

DocumentTypeResponse: documentTypeId, documentTypeName
```

### 3.4 Ausencias confirmadas por conteo de cadenas en el spec de `claims`

Esto no es "no lo encontré", es búsqueda exhaustiva sobre el JSON completo:

| Cadena buscada | Ocurrencias | Conclusión |
| --- | :-: | --- |
| `reason` | **0** | No existe el motivo de rechazo en ninguna parte |
| `history` / `historial` | **0** | No existe historial de estatus |
| `followup` / `comment` / `seguimiento` / `observacion` | **0** | El seguimiento de la avería **no está expuesto**, aunque SIGA sí lo tiene en la interfaz y notifica por correo |
| `budget` | **1** | Solo en la prosa descriptiva del servicio; no hay endpoint de presupuesto |
| `labor` | **0** | No hay mano de obra |
| `refac` | **0** | No hay refacciones |
| `odomet` | 9 | **Todas en Issues.** Ninguna en `ClaimResponse` |

Además: **no existe `GetClaimById/{id}`**. Para incidencias sí hay singular (`GetIssueById`), para averías solo la colección.

### 3.5 Ambigüedades del propio spec — pendientes de runtime

1. **Nomenclatura OData contradictoria.** El ejemplo documentado de `GetClaims` dice `?$select=IdAveria,ContractId,VinOrPlate,Description,CreationDate`, pero el esquema `ClaimResponse` documenta `claimId` y **no declara `vinOrPlate`**. El de documentos dice `?$filter=IdAveria eq 123` y `?$select=IdDocumento,IdAveria,TipoDocumento,Fecha`, con nombres en español que no coinciden con el esquema. **No se puede pedir nada sobre esto sin saber qué devuelve de verdad.**
2. **`GetContractPdfDataById`** promete *"Returns the PDF file content as extracted text"*. Falta saber si es el certificado completo o un extracto, y si conserva la estructura suficiente para localizar cláusulas.
3. **`GetDocumentType`** — la descripción del servicio menciona *"budgets, resolutions, photographic/video evidence"*, así que probablemente ya exista un tipo "Resolución". Hay que verlo.

### 3.6 Tres argumentos a favor, tomados de la documentación de la propia API

Úsalos al redactar; son la mejor palanca porque son sus propias palabras:

1. **La API ya está diseñada para un agente de IA.** `ConvertToClaim`: *"Creates a claim (avería) from the issue's contract/VIN/description… **Human action — the agent never converts automatically**"*. `CreateIssueRequest.odometer`: *"Already converted to a number by the **conversational agent** (from text, photo, or voice note)"*. `GetIssues`: *"Useful to answer '¿cómo va mi caso?' and to feed the panel list"*. No hay que convencerlos del consumidor: ya lo previeron.
2. **Multi-país ya es el plan declarado.** Descripción de `claims` y de `contracts`: *"Multi-country support (currently MEX, expandable to other markets)"*. La etapa 5 no es un capricho.
3. **El servicio promete funciones que no entrega.** La descripción de `claims` dice: *"Enables workshops, technicians, and administrators to register claims, upload supporting documentation, and **monitor claim status**"*, *"Document management for claims (budgets, **resolutions**, photographic/video evidence)"*, *"**Claims tracking and reporting** with flexible filtering"* y *"Multi-role access control (**workshops, technicians, coordinators, administrators**)"*. Pero no hay escritura de estatus, ni historial, ni motivo, ni presupuesto. **El hueco contradice su propio enunciado de propósito**, y ese es el mejor lugar desde donde pedir.

---

## 4. El script de verificación

### 4.1 Dónde está y qué hace

**Ruta:** `/Users/omarsaldanna/Downloads/trabajo/averias/api-siga/verificar-api.py` — **versión 2**, 227 líneas, Python 3, solo biblioteca estándar.

Es de **solo lectura**. Consulta listados y catálogos; en el sondeo del paso 9 solo observa el código de respuesta **sin enviar cuerpo**, así que ninguna escritura puede ejecutarse. No imprime el token ni la contraseña.

Además **guarda las respuestas crudas** en `respuestas-<etiqueta>/`, para poder inspeccionarlas después sin volver a llamar a la API.

**Novedades de la versión 2** respecto de la primera:

- `SIGA_LABEL` para etiquetar la corrida y **comparar cuentas de distinto rol**.
- **Paso 3b — el puente incidencia → avería.** Es la adición más importante: las incidencias **sí** traen `vinOrPlate` y `odometer`, y `IssueResponse` tiene un campo `claimId`. Si toda avería nace de una incidencia, el odómetro y el VIN serían alcanzables con `GetIssues?$filter=claimId eq N`, y **G12 dejaría de ser necesario**. Ver **V12** en el §5.
- **Paso 5c** — `$select` con los nombres del ejemplo documentado (`IdAveria`, `VinOrPlate`), para cerrar la contradicción del spec por los dos lados: filtro y proyección.
- **Paso 6c** — `GetContractPaymentInfo`, que cubre el *"que esté pagado"* del filtro de call center. La etapa 1 necesita vigencia **y** pago, y esto no estaba verificado.
- **Paso 9** — sondeo ampliado de 13 a **22 rutas**, incluyendo `GetContractCoverage`, `GetContractByVin`, `AcceptClaim`, `GetClaimSpareParts` y dos variantes de refresco de token.
- **Paso 10** — cabeceras de respuesta, para ver si hay límites de tasa publicados, id de correlación o avisos de deprecación.

### 4.2 Cómo correrlo

En Claude Code conviene correrlo con el prefijo `!` para que la salida entre a la conversación. **Ojo:** el clasificador de auto mode bloquea que el asistente envíe credenciales a un servicio externo, así que **estos comandos los tiene que ejecutar la persona**, no el asistente.

**Cuenta de taller** (recomendada para la primera corrida):

```bash
cd /Users/omarsaldanna/Downloads/trabajo/averias/api-siga && \
SIGA_USER='pruebastallergpmx@outlook.com' SIGA_PASS='Pruebas1!' SIGA_LABEL='taller' \
  python3 verificar-api.py 2>&1 | tee salida-verificacion-taller.txt
```

**Cuenta de distribuidor** (para comparar alcances):

```bash
cd /Users/omarsaldanna/Downloads/trabajo/averias/api-siga && \
SIGA_USER='martin.rivero@autocom.mx' SIGA_PASS='a2%Qm5ios' SIGA_LABEL='autocom' \
  python3 verificar-api.py 2>&1 | tee salida-verificacion-autocom.txt
```

**Nota sobre la contraseña de taller:** `Pruebas1!` termina en `!`. Va entre comillas **simples**, no dobles: entre dobles, `zsh` intentaría expandir el historial y fallaría.

Correr **las dos** y comparar tiene un valor propio: si una cuenta ve registros que la otra no, queda demostrado el **filtrado por fila** por rol, y eso hay que decirlo en el PRD al pedir el rol de servicio — porque determina si una identidad de servicio necesita alcance global o basta con uno acotado.

### 4.2-bis Problemas conocidos al correr el script

**`CERTIFICATE_VERIFY_FAILED` (resuelto en la v2.1).** El Python 3.13 de python.org en esta máquina no tiene bundle de CA configurado: apunta a `/Library/Frameworks/Python.framework/Versions/3.13/etc/openssl/cert.pem`, que no existe porque nunca se corrió `Install Certificates.command`. La v2.1 del script lo resuelve sola: busca un bundle válido en este orden — `SIGA_CA_BUNDLE` (si se define), `certifi`, `/etc/ssl/cert.pem`, los de Homebrew — e imprime cuál usó en una línea `[ssl]`. **La verificación del certificado sigue activa**; en ningún caso se desactiva. Arreglo permanente si se quiere, opcional: ejecutar `/Applications/Python 3.13/Install Certificates.command`.

**HTTP 503 del entorno QA.** El 2026-08-27 a las 15:24 UTC **todo** `qa-siga-api.garantiplus.com` devolvía 503, incluidos los cuatro `openapi/v1.json` y la raíz. La cabecera era `server: awselb/2.0` con cuerpo HTML genérico de nginx: es el balanceador de AWS sin destinos sanos detrás, o sea una **caída del entorno**, ajena a este trabajo. Comprobación rápida de si ya volvió:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://qa-siga-api.garantiplus.com/claims/openapi/v1.json
```

`200` = arriba, se puede correr el script. `503` = sigue caído.

### 4.3 Credenciales disponibles y su limitación

Hay **dos cuentas del entorno de pruebas**, ambas prestadas por el usuario:

| Etiqueta | Usuario | Rol probable | Para qué sirve |
| --- | --- | --- | --- |
| `taller` | `pruebastallergpmx@outlook.com` | **Taller** — el nombre lo dice: *pruebas + taller + gp + mx* | Es el rol que **registra la avería y sube la evidencia**. Ve el expediente desde el lado que lo crea |
| `autocom` | `martin.rivero@autocom.mx` | **Distribuidor** — "GRUPO AUTOCOM" figura en el catálogo de distribuidores del tablero | Contraste de alcance frente a la de taller |

**Advertencia que hay que tener presente al leer los resultados.** Ninguna de las dos parece ser de **técnico** ni de **coordinador**, que son los roles que dictaminan. Es probable que ambas:

- solo vean contratos y averías de su propio taller o distribuidor (**filtrado por fila**), y
- reciban **403** en endpoints reservados al área técnica, en lugar de revelar la forma real de la respuesta.

Para lo que el PRD necesita —**existencia y forma de los campos, y qué rutas existen**— sirven igual, y de hecho la de taller es la mejor disponible porque es el rol que crea el expediente. Pero **no** dicen qué vería una identidad de servicio con rol de técnico.

**El paso 0 lo resuelve de inmediato.** Si en los *claims* del JWT aparece un rol de taller o distribuidor y un id de entidad, hay que **pedir a TI una cuenta de técnico o coordinador** antes de cerrar V1, V4, V6 y V9 con certeza. Esa petición conviene hacerla ya, porque además el PRD va a necesitar saber cómo se crean identidades de servicio (**G01** y **G03**).

**Consecuencia concreta si un endpoint devuelve 403 con las dos cuentas:** eso **no** prueba que el endpoint no exista ni que falte una capacidad. Solo prueba que estas cuentas no tienen permiso. En el PRD hay que distinguir con cuidado entre *"no existe"* (404/405, verificado) y *"no tenemos permiso para verlo"* (403), y **nunca pedir como nuevo algo que solo dio 403**.

### 4.4 Qué verifica cada paso

| Paso | Qué averigua |
| :-: | --- |
| **0** | Login y *claims* del JWT: rol real, país, alcance y caducidad del token |
| **1** | `GetAllRoles` — los roles que existen, para nombrar correctamente el rol de servicio que se va a pedir |
| **2** | `GetDocumentType` — si ya existe un tipo **"Resolución"** |
| **3** | `GetClaims` — los campos que **devuelve de verdad**, y presencia o ausencia de `vinOrPlate`, `odometer`, `validationDate`, `rejectionReason`, `projectId`, `productName` |
| **4** | Si el filtro OData es `claimId` o `IdAveria` (prueba las tres variantes) |
| **5** | Si `$count` y `$apply` funcionan — la agregación en servidor es clave para la cola priorizada de la etapa 4 |
| **6** | Campos reales de contratos y si `$filter=vin eq '...'` funciona |
| **7** | `GetContractById` completo y, sobre todo, si `GetContractPdfDataById` trae el **certificado completo**: mide la longitud del texto y busca los marcadores `MANTENIMIENTO`, `EXCLUSIONES`, `OPERACIONES NO INCLU`, `VIGENCIA`, `6 meses`, `10,000` |
| **8** | Campos reales de los documentos de una avería (¿viene `documentTypeId`?) |
| **9** | Sondeo de **22 rutas no documentadas**: `GetClaimById`, `GetRejectionReasons`, `GetClaimStatuses`, `GetStatuses`, `GetClaimBudget`, `GetClaimSpareParts`, `GetClaimStatusHistory`, `GetClaimFollowUp`, `GetClaimTracking`, `UpdateClaimStatus` (PATCH y PUT), `UpdateClaim` (PUT y PATCH), `RejectClaim`, `ResolveClaim`, `ApproveClaim`, `AcceptClaim`, `AddClaimFollowUp`, `GetContractCoverage`, `GetContractByVin`, `RefreshToken`, `Refresh`. Lectura de códigos: **404/405 = no existe · 400/401/403/409/415/422 = existe pero rechaza · 200 = existe y responde** |
| **10** | Cabeceras de respuesta: límites de tasa, `Retry-After`, id de correlación, `ETag`, avisos de deprecación |

Y los pasos añadidos en la versión 2:

| Paso | Qué averigua |
| :-: | --- |
| **3b** | `GetIssues` y **el puente incidencia → avería** (V12): si el odómetro y el VIN son alcanzables por la incidencia asociada, **G12 desaparece** |
| **5c** | `$select` con los nombres del ejemplo documentado, para cerrar la contradicción del spec por proyección además de por filtro |
| **6c** | `GetContractPaymentInfo`: el *"que esté pagado"* que exige el filtro de call center |

---

## 5. Los nueve pendientes de verificación, y qué cambia cada respuesta

Esta es la parte crítica: **cada pendiente cambia lo que se le pide al equipo de SIGA.** No se puede redactar el PRD sin cerrarlos.

| # | Pendiente | Si la respuesta es SÍ | Si la respuesta es NO |
| :-: | --- | --- | --- |
| **V1** | ¿`ClaimResponse` **devuelve** `vinOrPlate` y `odometer` aunque el esquema no los declare? | **No se piden los campos**; se pide solo **corregir la documentación del esquema**, que es una petición trivial y bien recibida | Se piden como campos nuevos (**G12**), con justificación: hoy hay que leer el VIN del correo y el odómetro de una fotografía |
| **V2** | ¿El filtro OData es `claimId` o `IdAveria`? | Se documenta el que funcione y se pide **homologar los ejemplos** del spec | Si **ninguno** funciona, es un problema mayor: no hay forma de consultar una avería por folio, y **la etapa 1 se cae**. Sería la petición nº 1 del PRD |
| **V3** | ¿Existe ya el tipo de documento **"Resolución"**? | **G22 desaparece.** Solo se pide confirmar por escrito el `documentTypeId` a usar | Se pide crear el tipo de documento y garantizar que `UploadClaimDocument` lo acepte. **Bloquea la etapa 2**, porque sin él no se puede cumplir "ningún rechazo sin resolución adjunta" |
| **V4** | ¿`GetContractPdfDataById` devuelve el certificado **completo y fiel**? | Se pide solo una **garantía contractual** de completitud y estabilidad del formato (**G18**), y **G19** —el condicionado estructurado— pasa a ser deseable en lugar de imprescindible | **G19 se vuelve obligatoria y bloqueante de la etapa 1.** Sin el condicionado no hay dictamen posible, ni leyendo prosa ni de ninguna otra forma |
| **V5** | ¿`GetAllContracts` acepta `$filter=vin eq '...'`? | Nada que pedir | Se pide el filtro o un `GetContractByVin`. **Bloquea la etapa 1 entera**: el VIN es la única llave que trae el correo |
| **V6** | ¿Existe alguna ruta de **escritura sobre averías** no documentada? | Cambia todo: la etapa 2 podría arrancar sin esperar a nadie. Se pediría solo documentarla y acotar permisos | Se confirma que **G21 es el bloqueo nº 1** y se especifica el endpoint completo |
| **V7** | ¿`$apply` funciona de verdad en los listados? | La cola priorizada de la etapa 4 se resuelve del lado del cliente; nada que pedir | Se pide un endpoint de resumen agregado (**G31**) para no traer miles de registros por página |
| **V8** | ¿Qué roles concretos devuelve `GetAllRoles`? | Se nombra el rol de servicio **con la nomenclatura que ellos ya usan**, lo que hace la petición mucho más fácil de aceptar | Se propone crear el rol desde cero, describiendo permisos uno por uno |
| **V9** | ¿El folio del correo de asignación coincide con el `claimId` de la API? | Nada que pedir | Se pide exponer el **folio visible** como campo consultable. **Bloquea la etapa 1**: sin correspondencia entre el folio del correo y el id de la API, no se puede localizar el caso |

| **V12** | ¿Se puede llegar al **odómetro y al VIN por la incidencia** asociada a la avería? `IssueResponse` trae `vinOrPlate`, `odometer` **y `claimId`** | **G12 desaparece** y con ella una de las peticiones del grupo 1. Se documenta el patrón `GetIssues?$filter=claimId eq N` como la vía oficial y se pide solo que quede en la documentación | Se confirma G12 y se refuerza el argumento: los mismos datos existen en la entidad hermana, así que exponerlos en la avería es coherencia del modelo, no una función nueva |

**Cómo interpretar un 403 — importante para no pedir de más.** Las dos cuentas disponibles son de taller y de distribuidor, no de técnico. Si una ruta devuelve **403**, eso significa *"existe pero esta cuenta no tiene permiso"*, **no** *"no existe"*. En el PRD hay que distinguir con rigor:

- **404 / 405** → verificado que no existe. Se puede pedir como función nueva.
- **403** → existe y está protegida. **Nunca pedirlo como nuevo**; a lo sumo pedir que el rol de servicio tenga acceso.
- **400 / 422** → existe y valida la entrada. Solo hay que documentar el contrato.

Confundir estos casos es exactamente el error que arruinaría la credibilidad del documento, y la razón por la que se pidió no equivocarse.

**Además hay tres pendientes que no resuelve el script** y que hay que preguntar a personas:

- **V10 — ¿Existe plan para las APIs de Colombia y Chile?** Alcance, fecha y responsable. Determina si la etapa 5 se pide ahora o después. Preguntar a TI / Alexis.
- **V11 — ¿El folio del correo es el mismo número que el técnico ve en pantalla?** Conviene confirmarlo con David Simancas sobre un caso real, además de verificarlo por API.
- **V13 — ¿Cómo se crea una identidad de servicio hoy?** Ninguna de las dos cuentas disponibles es de técnico, y no hay endpoint para crear usuarios ni asignar roles. Preguntar a TI: **(a)** si pueden emitir una cuenta de técnico o coordinador para QA, y **(b)** cuál es el proceso actual para dar de alta un consumidor de máquina. De la respuesta depende cómo se redactan **G01** y **G03**.

---

## 6. Inventario de huecos: 34 en 6 grupos

Está también en `api-siga/inventario-huecos-api.md`. Cada hueco se mapea a la etapa que desbloquea. Los marcados **⛔** son bloqueantes de su etapa.

### Grupo 0 — Plataforma y transversal *(habilita todas las etapas)*

| ID | Hueco | Nota |
| --- | --- | --- |
| **G01** | Identidad de máquina: flujo de credenciales de cliente | Hoy solo hay `Login` con usuario y contraseña **de persona**. Un servicio no debe usar la cuenta de un humano |
| **G02** | Endpoint de refresco de token | `LoginResponse` **emite** `refreshToken` pero **no hay dónde canjearlo**. Hoy el servicio tendría que re-autenticarse con contraseña |
| **G03** | Rol de servicio con privilegio mínimo, y forma de asignarlo | Los roles son de solo lectura; no hay endpoint para crear ni asignar |
| **G04** ⛔ | Idempotencia en escrituras (`Idempotency-Key`) | Sin ella, un reintento por timeout puede marcar dos veces o duplicar el documento. **Imprescindible desde la etapa 2** |
| **G05** | Eventos / webhooks: avería asignada, cambio de estatus, documento cargado | Hoy la única señal es un correo. Con esto la etapa 1 dejaría de depender de leer buzones de personas |
| **G06** ⛔ | Nomenclatura OData consistente y documentada | Depende de **V2**. Un filtro con nombre equivocado devuelve **vacío en silencio**, que es exactamente el fallo silencioso que el diseño prohíbe |
| **G07** | Límites de rate limiting publicados, con código y cabeceras al excederlos | El servicio dice tener *"rate limiting policies"* pero no publica los umbrales |
| **G08** | Formato de fechas y zona horaria explícitos | El SLA se mide en horas hábiles; una ambigüedad de zona horaria lo corrompe |
| **G09** | Entorno QA con datos representativos | Necesario para probar sin tocar producción |
| **G10** | Política de versionado y deprecación | El desarrollo va a depender de estos contratos por años |

### Grupo 1 — Lectura del expediente *(etapa 1)*

| ID | Hueco | Nota |
| --- | --- | --- |
| **G11** | `GetClaimById/{claimId}` | Existe para incidencias, no para averías. Hoy hay que filtrar la colección |
| **G12** | `ClaimResponse` con `vinOrPlate`, `odometer`, `projectId`/país, `productName` | Depende de **V1** y de **V12**. El odómetro solo existe en incidencias — y si son alcanzables por la incidencia asociada, este hueco **desaparece** |
| **G13** | `validationDate` y `GetClaimStatusHistory/{claimId}` | **Sin `validationDate` no se puede medir el compromiso de 48 horas hábiles**, que es el SLA contractual |
| **G14** | Catálogo de estatus de avería | Son **11** reales: `Registrada`, `Validación`, `Aceptada`, `No procede garantía`, `Taller`, `Solucionada`, `Cerrada`, `Cancelada`, `Prueba-QA`, `Excepción en revisión`, `Excepción no aprobada`. Hoy habría que quemarlos en configuración |
| **G15** ⛔ | Catálogo **normalizado** de motivos de rechazo | Hoy hay **56 valores** con duplicados y variantes de mayúsculas entre países (`Componente excluido` / `COMPONENTE EXCLUIDO DE COBERTURA` / `Elemento excluido` / `Elemento excluido de cobertura`). Sin normalizar no hay métrica comparable ni motivo que escribir |
| **G16** ⛔ | Componente y refacciones reclamadas en la avería | Es el dato central de la puerta de exclusiones. **El tablero del área ya lo consume, así que existe en la base** |
| **G17** | `documentTypeId` en la respuesta de documentos | Hoy solo viene el nombre como texto; emparejar por cadena es frágil |
| **G18** | Garantía de que el texto del certificado es completo y fiel | Depende de **V4** |
| **G19** | **Condicionado estructurado** | El de mayor valor de todo el inventario. Ver §7 |
| **G20** | Lectura del seguimiento y comentarios de la avería | SIGA lo tiene en la interfaz y **notifica por correo**; la API no lo expone |

### Grupo 2 — Escritura de improcedencia *(etapa 2)*

| ID | Hueco | Nota |
| --- | --- | --- |
| **G21** ⛔ | **Resolver una avería**: estatus + motivo + comentario | **El bloqueo nº 1.** Hoy `ClaimResponse.statusId` es de solo lectura y el único `status` escribible es de incidencias |
| **G22** | Tipo de documento "Resolución" confirmado y aceptado por la carga | Depende de **V3** |
| **G23** ⛔ | Atribución: identidad de servicio **y** persona que autorizó | Requisito derivado del principio 1. Sin este campo no se puede auditar quién decidió |
| **G24** | Corrección o reversión de un dictamen emitido | Si el sistema se equivoca, hay que poder deshacerlo por API y no por ticket a TI |
| **G25** | Auditoría consultable: quién cambió qué y cuándo | David: *"todo debe estar dentro de SIGA para poder hacer auditorías"* |

### Grupo 3 — Deliberación del caso procedente *(etapa 3)*

| ID | Hueco | Nota |
| --- | --- | --- |
| **G26** ⛔ | Presupuesto desglosado: conceptos, refacciones, mano de obra, importes | Sin esto **"que el presupuesto cuadre" no es implementable**. El tablero lo tiene |
| **G27** ⛔ | Límite por avería, límite de contrato y valor de venta del vehículo, como números con su fuente | El certificado los enuncia como *"Valor Venta Vehículo"* pero no los cuantifica; la cláusula 11 los hace decisivos |
| **G28** ⛔ | Marcar `Aceptada` con el detalle de lo autorizado | Análogo a G21 pero para el lado favorable, y con atribución humana obligatoria |
| **G29** | Histórico de casos por componente | Para el comparativo. Hoy solo existe en el tablero, por extracción manual |

### Grupo 4 — Operación de alta carga *(etapa 4)*

| ID | Hueco | Nota |
| --- | --- | --- |
| **G30** | Agregar seguimiento a la avería, disparando la notificación que SIGA ya emite | Es el mecanismo con el que hoy se le pide documentación al taller |
| **G31** | Consulta agregada por técnico, estatus y antigüedad | Depende de **V7** |
| **G32** | Estado de pago y comprobante del expediente | Para el seguimiento hasta el cierre |

### Grupo 5 — Operación regional *(etapa 5)*

| ID | Hueco | Nota |
| --- | --- | --- |
| **G33** ⛔ | Contratos y averías de Colombia y Chile, o alcance de país en la misma API | Depende de **V10**. Es el propósito de negocio del proyecto |
| **G34** | Catálogos por país, normalizados entre mercados | Colombia y Chile usan nomenclatura propia de motivos |

---

## 7. Las dos peticiones que exceden "desbloquear lo que nos bloquea"

**Decisión pendiente del usuario.** Ambas mejoran el proyecto de forma sustancial pero son trabajo real para el equipo de SIGA, y meterlas puede diluir el mensaje de las peticiones bloqueantes.

### 7.1 G19 — Condicionado estructurado *(la de mayor valor del inventario)*

**Qué es.** Un endpoint que devuelva, como **datos**, lo que hoy solo existe como prosa en el PDF del certificado:

- grupos de componentes cubiertos y excluidos,
- régimen de mantenimiento aplicable (nuevo vs. seminuevo; intervalo en meses y en kilómetros; exigencia de distribuidor autorizado),
- periodo de espera,
- ámbito geográfico,
- límite por avería, límite de contrato y valor de venta del vehículo,
- la lista de operaciones no incluidas.

Propuesta: `GET /api/Contracts/v1/GetContractCoverage/{contractId}`.

**Por qué vale tanto.** Convierte el dictamen en **determinista** en lugar de depender de que un modelo lea correctamente un PDF. El motivo de rechazo nº 1 —intervalo de mantenimiento excedido, **29.1%**— se resuelve con aritmética de fechas y kilómetros si el intervalo viene como dato, y con interpretación de prosa si no.

**Por qué puede no entrar.** Es la petición más costosa: obliga a modelar el condicionado como datos, y hoy vive como documento. Podría requerir cambios de fondo en el producto, no solo en la API.

### 7.2 G05 — Webhooks / eventos

**Qué es.** Suscripción a eventos de avería: asignada, cambio de estatus, documento cargado.

**Por qué vale.** Eliminaría por completo la dependencia de **leer los buzones de correo de personas** —que hoy exige delegación sobre cuentas nominales, un pendiente sin resolver del PRD de averías— y resolvería de paso el disparo de la pasada 2 (detectar el paso a `Validación` sin reconsultar).

**Por qué puede no entrar.** Es infraestructura nueva: registro de suscriptores, reintentos, firma de la carga, cola. Bastante más que un endpoint.

---

## 8. Plan de redacción del PRD `api-averias-siga`

### 8.1 Decisiones pendientes antes de escribir

| # | Decisión | Recomendación |
| :-: | --- | --- |
| **D1** | Ubicación en el repo central | **`SIGA / api-averias-siga`** — el destinatario es el equipo de SIGA, no Desarrollos_internos. Resolver con `resolve-id` para obtener el `PJ####` |
| **D2** | ¿Entra **G19** (condicionado estructurado)? | Pendiente del usuario. Si `V4` resulta que el texto del certificado es incompleto, **deja de ser opcional** |
| **D3** | ¿Entran **G05** (webhooks)? | Pendiente del usuario |
| **D4** | ¿Se piden los 34 huecos, o solo los bloqueantes? | Recomendado: **los 34, claramente priorizados**, para que el equipo vea el panorama completo y decida su plan. Los ⛔ marcados como bloqueantes de etapa |
| **D5** | ¿Se incluyen las etapas 3–5 aunque estén lejos? | Recomendado: **sí**. Es la única entrega; si no se piden ahora, no se piden |
| **D6** | ¿Quién firma la entrega y a quién se dirige? | Pendiente: confirmar si el interlocutor es Alexis y quién de EngineCX lo respalda |

### 8.2 Estructura propuesta del documento

Las 14 secciones de la plantilla de PM·AI, con este contenido:

1. **Resumen ejecutivo** — qué se pide, por qué, y el argumento de §3.6: la API promete funciones que no entrega.
2. **Contexto y problema** — el proceso de averías (§2.1), las cinco etapas, y el mapa de qué bloquea qué.
3. **Objetivo** — desbloquear la automatización completa del ciclo de dictamen. §3.1: fases de entrega alineadas a las cinco etapas.
4. **Usuarios y actores** — consumidores de la API: el orquestador de n8n, los dos agentes de IA, el técnico, el equipo de SIGA.
5. **Alcance** — los 34 huecos agrupados. **Aquí va el detalle técnico de cada uno** con el formato del §8.3.
6. **Fuera de alcance** — lo que **no** se pide: cambios en la interfaz de SIGA, automatizar el llenado del formato dentro de SIGA, tocar pagos, permitir dos averías por VIN.
7. **Flujos** — diagramas de cómo consume la API cada etapa, y qué llamada falta en cada punto.
8. **Requerimientos funcionales** — un RF por hueco, con la etapa que desbloquea.
9. **Requerimientos no funcionales** — idempotencia, latencia, límites, versionado, seguridad, auditoría.
10. **Integraciones y datos** — contratos de datos y el mapa dato-a-origen.
11. **Eventos y registro** — solo si entra G05.
12. **Métricas de éxito** — criterios de aceptación verificables por hueco.
13. **Riesgos y supuestos** — qué pasa si un hueco no se atiende, y qué etapa cae.
14. **Preguntas abiertas** — lo que el equipo de SIGA debe responder.

### 8.3 Plantilla para especificar cada hueco

**Usar exactamente esta estructura para los 34.** Es lo que hace al documento accionable de una sola pasada:

```markdown
#### G-NN · <Nombre> — desbloquea la etapa N  [⛔ bloqueante | ⚠ degrada]

**Paso del proceso que lo necesita:** <paso concreto del §2.1>
**Por qué es necesario:** <impacto en el negocio, con cifra si la hay>

**Estado actual verificado:** <evidencia exacta: endpoint, esquema, campo, conteo>

**Lo que se pide**
- Método y ruta: `VERBO /api/.../v1/Nombre/{param}`
- Petición: <cuerpo JSON con tipos y obligatoriedad>
- Respuesta 200: <cuerpo JSON con tipos>
- Errores: <400/401/403/404/409/422 y cuándo se devuelve cada uno>
- Permisos: <rol que puede invocarlo>
- Idempotencia: <sí/no y con qué llave>
- Efectos colaterales: <notificaciones, auditoría, cambios de estado>

**Criterios de aceptación**
1. <verificable>
2. <verificable>

**Si no se atiende:** <consecuencia concreta y qué etapa se cae>
```

### 8.4 Secuencia de trabajo de la próxima sesión

1. **Correr el script** con la cuenta de **taller** (§4.2) y pegar la salida. Si hay tiempo, correr también la de distribuidor y comparar.
2. **Revisar el paso 0.** Si el rol del JWT es de taller o distribuidor —lo esperable—, **pedir a TI una cuenta de técnico o coordinador** y repetir antes de cerrar V1, V4, V6 y V9. Mientras llega, se puede avanzar con todo lo demás.
3. **Cerrar V1 a V9 y V12** con la salida, aplicando la regla de interpretación del 403 (§5), y actualizar el inventario: quitar los huecos que ya no existen, reforzar los que se confirman.
4. **Preguntar V10, V11 y V13** a las personas (TI / Alexis y David).
5. **Resolver D1 a D6** con el usuario.
6. **Invocar `/pm-ai:pm-prd`** → opción 1 (desde cero) → unidad **EngineCX** → sistema **SIGA** → `project_id` **`api-averias-siga`**.
7. Copiar a `transcripts/` del proyecto nuevo: este documento, `inventario-huecos-api.md`, la salida de la verificación y los cuatro OpenAPI. Generar sus condensados.
8. **Redactar** con la plantilla del §8.3, presentar el borrador, y publicar solo tras confirmación.

### 8.5 Reglas del flujo de PM·AI que hay que respetar

- El chequeo del `.env` **nunca imprime valores**, solo nombres de clave.
- Todas las operaciones de git sobre `enginecx_prd` van por el bin `prd-sync` (`clone-dir`, `sync`, `list-projects`, `resolve-id`, `commit --dir --message`, `push`). **Nunca `git` a mano. Nunca force-push.**
- Flujo obligatorio: **propuesta → revisión → confirmación**. No se escribe `PRD.md` sin confirmación explícita.
- Ante cualquier ambigüedad, **preguntar con opción múltiple**, no asumir.
- Bin: `/Users/omarsaldanna/.claude/plugins/cache/engine-cx-local/pm-ai/6.6.0/packages/prd-sync/dist/cli.js`

---

## 9. Inventario de archivos

Todo en `/Users/omarsaldanna/Downloads/trabajo/averias/api-siga/`:

| Archivo | Qué es |
| --- | --- |
| `RETOMAR-PRD-API-SIGA.md` | Este documento |
| `verificar-api.py` | El script de verificación de solo lectura (§4) |
| `inventario-huecos-api.md` | Inventario de los 34 huecos con la evidencia dura |
| `PRD-averias-v0.2-copia.md` | Copia de respaldo del PRD de averías publicado |
| `openapi-2026-08-26/authentication.json` | Spec vivo, 154 KB, capturado el 2026-08-26 |
| `openapi-2026-08-26/catalogs.json` | Spec vivo, 213 KB |
| `openapi-2026-08-26/contracts.json` | Spec vivo, 195 KB |
| `openapi-2026-08-26/claims.json` | Spec vivo, 221 KB |
| `salida-verificacion-taller.txt` | **Pendiente de generar** — corrida con la cuenta de taller |
| `salida-verificacion-autocom.txt` | **Pendiente de generar** — corrida con la cuenta de distribuidor |
| `respuestas-taller/` | **Pendiente** — respuestas crudas de la corrida de taller, incluido el certificado extraído |
| `respuestas-autocom/` | **Pendiente** — respuestas crudas de la corrida de distribuidor |

Fuentes del proceso, en el repo central `Desarrollos_internos/PJ1544-copiloto-averias/transcripts/`:

- `reunion-david-simancas-2026-08-25.md` — el proceso real, los estatus, los criterios de dictamen
- `reunion-gisela-aldana-2026-08-25.md` — el orden del filtro de call center
- `audio-jefe-estado-futuro-2026-08-25.md` — la instrucción directiva de automatizar todo y centralizar
- `contrato-excellence-tt-gm-795713.pdf` — el condicionado de referencia (cláusulas 1, 9, 11, 12, 13)
- `tablero-averias-latam-2026.md` — todas las cifras
- `instrucciones-neurona.md` y los 10 documentos `gg-*` — el sistema de referencia de Garantía Global

Material original fuera del repo, en `/Users/omarsaldanna/Downloads/`:

- `tablero_averias_latam (12).html` — 4.6 MB, dataset de 16 800 averías 2021-2026. **No versionado por peso**; los agregados están en el condensado
- `795713.pdf` — el contrato de referencia
- Los dos transcripts de las juntas del 2026-08-25

---

## 10. Lo que no hay que volver a averiguar

Para no repetir trabajo en la próxima sesión:

- Las URLs `/{servicio}/scalar/v1` **no sirven** para leer el contrato: son la cáscara de la SPA. El JSON está en `/{servicio}/openapi/v1.json`.
- Existen **cuatro** servicios y solo cuatro. Ya se probaron y descartaron quince nombres más.
- La autenticación **sí se exige**: los listados sin token devuelven 401.
- **La placa no se usa.** David, textual: *"aquí no usamos la placa para nada"*. El rastreo es por VIN o por folio de avería. `licensePlate` aparece **una sola vez** en los cuatro specs, como campo de **entrada** en `CreateContractRequest`, documentado como *"optional in MEX, required in CHL"*. **No hay que volver a plantear la búsqueda por placa ni la réplica de base de datos para ello.**
- El historial de mantenimientos **no existe en el sistema**, no solo en la API. `VehicleInfo.timelyServices` es un flag capturado en la venta. La única prueba son las facturas y el carnet cargados como evidencia. Es el motivo de rechazo nº 1 y **no tiene solución por API**: hay que leer documentos.
- SIGA **no permite dos averías vigentes sobre el mismo VIN**. El área lo resuelve cerrando y reabriendo expedientes a mano. Es una petición de cambio del área, **ajena a este PRD**.
- El área técnica **solo puede mover** `Validación` → `Aceptada` / `No procede garantía`. Todo lo demás lo mueve la agencia, y algunos estatus solo TI. No tiene sentido pedir escritura sobre otros estatus.
