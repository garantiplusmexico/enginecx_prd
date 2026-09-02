# Hallazgos de la exploración de producción — 2026-09-01

Cuenta `SigaWeb`, rol **Administrador General**. Base de producción: `https://siga-api.garantiplus.com`.
La misma cuenta autentica también contra QA (`https://qa-siga-api.garantiplus.com`).
**Toda la exploración fue de solo lectura**: el único POST ejecutado fue el login.

## Lo que el PLAN.md daba por bueno y es falso

| # | El plan asumía | La realidad |
|---|---|---|
| 1 | `POST /api/Authentication/v1/Login` | `POST /authentication/api/Auth/v1/Login`. Cada servicio tiene su prefijo: `/authentication`, `/claims`, `/contracts`, `/catalogs` |
| 2 | Las listas devuelven un arreglo | Devuelven `{ value: [...], pagination: { total, pageSize, currentPage, totalPages, next, previous } }` |
| 3 | Sin límite de página | **`$top` está capado a 100.** Pedir 300 devuelve 100 sin avisar |
| 4 | El caso se identifica por `folio` (texto) | Se identifica por **`claimId` (entero)**. No existe ningún campo llamado folio |
| 5 | Se localiza el contrato **por VIN** | `ClaimResponse` **no trae VIN**. El puente al contrato es `contractId`, que sí viene en la avería |
| 6 | `claim.status` es un nombre legible | Es **`statusId`**, una cadena numérica (`"1"`…`"11"`) sin catálogo que la traduzca |
| 7 | El tipo de documento *Resolución* hay que pedirlo | **Ya existe: `documentTypeId` 14.** Una dependencia menos para la etapa 2 |
| 8 | La suficiencia se evalúa por `documentType` | Los tipos son 16 y genéricos. **No alcanzan** (ver abajo) |

## Lo que sí funciona como se esperaba

- **`GetContractById/{id}`** devuelve el expediente completo del contrato: `vehicle` (brand, model, version, year, kilometers, vin, engineNumber, factoryWarranty, timelyServices, usageType), `beneficiary`, `channel` y `contract` con fechas y montos.
- **`GetContractPdfDataById/{id}`** devuelve `{ fileName, contentType, content }` con el **texto del certificado**: 39 399 caracteres en el caso probado. El habilitador clave del proyecto está confirmado.
- **`GetDocumentType`** devuelve los 16 tipos con id estable.
- El filtro OData `$filter=claimId eq N` funciona en `GetClaims` y en `GetClaimDocuments`.
- `$orderby=claimId desc` funciona (hay que codificar el espacio en la URL).

## Riesgos nuevos, no contemplados en el PRD ni en el plan

### R1 — El filtro OData con un campo inexistente falla en silencio

`$filter=IdAveria eq 7` devuelve **HTTP 200 con `value: []` y sin `pagination`**, en vez de un error. Un typo en un nombre de campo produce «no hay resultados», que es indistinguible de «no existe el caso». Todo filtro necesita verificación en tiempo de arranque.

### R2 — El 44% de las averías recientes no resuelve su contrato

Medido sobre las 100 averías más recientes (claimId 160447–163021, del 20-ago al 1-sep):

| | resuelve / total |
|---|---|
| Eduardo Álvarez | 27 / 49 |
| Miguel Ángel Rodríguez | 27 / 49 |
| Juan Carlos Forero (Colombia) | 2 / 2 |
| **Total** | **56 / 100** |

Las que fallan son sistemáticamente **las más recientes** (163021, 162988, 162889, 162824, 162790…). Los contratos que sí resuelven aparecen con estatus `Activo` (55) y `Cancelado` (1). El contrato 57227 de la avería 163021 devuelve 404 en `GetContractById` y 0 resultados en `GetAllContracts`.

**Sin contrato no hay expediente**: no hay VIN, ni vigencia, ni vehículo, ni certificado. Es el riesgo más serio para la etapa 1.

### R3 — La capa 0 no puede decidir con metadatos

Los 16 tipos de documento son genéricos (`Evidencia`, `Presupuesto`, `Varios`, `Doc. Taller`, `Peritacion`…). El nombre del archivo a veces salva y a veces no:

- Avería **162988**: `Presion.jpeg`, `Codigo de fallo.jpeg`, `Carnet.jpeg`, `Servicios.jpeg`, `Serie.jpeg`, `Odomtro.jpeg` *(con typo)* — todos con tipo `Evidencia` o `Varios`.
- Avería **162955**: siete archivos llamados `WhatsApp Image 2026-09-01 at 10.30.38 AM (n).jpeg` — opacos por completo.

El evaluador de suficiencia **tiene que abrir los documentos y clasificarlos por contenido**, con visión sobre las imágenes y extracción sobre los PDFs. La Task 9 del plan, que hace *matching* por nombre y tipo, no es implementable contra esta realidad.

### R4 — No hay forma de saber cuándo una avería entró a `Validación`

Ni fecha de cambio de estatus, ni bitácora. Confirma lo que el PRD hermano de SIGA pide, y de momento el SLA de 48 horas no es medible.

## Mapa de estatus inferido — NO CONFIRMADO

No existe catálogo por API (probadas 8 rutas, todas 404). Inferido sobre 300 averías (claimId 155563–163021) cruzando edad mediana, número de documentos y presencia de un documento tipo *Resolución*:

| statusId | n | edad mediana | con Resolución | docs | lectura propuesta |
|---:|---:|---:|---:|---:|---|
| 1 | 20 | 12 d | 0/6 | 3 | **Registrada** |
| 2 | 20 | 6 d | 0/6 | 9 | **Validación** ← el estatus trabajable |
| 3 | 14 | 23 d | 6/6 | 15 | posterior al dictamen |
| 4 | 26 | 20 d | 6/6 | 13 | posterior al dictamen |
| 5 | 22 | 21 d | 4/6 | 11 | posterior al dictamen |
| 6 | 102 | 18 d | 6/6 | 16 | el más frecuente |
| 10 | 90 | 15 d | 6/6 | 12 | segundo más frecuente |
| 11 | 6 | 17 d | 2/6 | 4 | marginal |

Lo sólido: **1 y 2 son los estados previos al dictamen** —ninguno de los muestreados tiene Resolución— y **2 es el más fresco**, lo que encaja con `Validación`. El reparto entre 6 y 10 podría corresponder a aceptada / no procede (el tablero registra 38.2% de rechazo y aquí 10 pesa 30% y 6 pesa 34%), pero **es especulación y no debe codificarse sin confirmación**.

## Datos operativos confirmados

- **17 160 averías** y **233 593 contratos** en producción.
- Reparto de carga exacto entre los dos técnicos de México: **49 y 49** de las 100 más recientes. Round-robin confirmado.
- `technicianName` viene como nombre («EDUARDO ALVAREZ NARVAEZ»), **no como correo**. El reporte matutino necesita el mapeo nombre → buzón.
- `description` (la falla reportada) viene con texto útil en **56 de 100** averías. En las demás llega vacía.
- `GetContractById` expone **datos personales del beneficiario**: nombre, RFC, dirección, teléfono y correo. La anonimización de la Task 11 es obligatoria antes de cualquier salida, y el patrón de RFC ya está cubierto.

## Bloqueo: los correos

No hay forma de leerlos todavía. El MCP de n8n solo expone tres workflows (`Accesos Seguros`, `Darwin AI Govirtual`, `SIIGO - Backfill Histórico`), ninguno relacionado con averías, y no permite crear workflows. Las credenciales *Averías | México | Eduardo Álvarez* y *Averías | México | Miguel Angel* existen en n8n pero ningún flujo las usa. El buzón de `omar.lara@enginecx.com` no recibe copia de los correos de asignación.

---

# Segunda tanda — los correos y el puente al contrato

## El catálogo de correos, resuelto

Construido el flujo **«Copiloto de averías»** (`nJm48fpQLOM0V5nT`) en n8n como webhook de exploración de solo lectura sobre el buzón de Miguel Ángel. Se activó, se leyó y **se dejó desactivado**. 40 correos de los últimos 5 días.

**El remitente es `plataforma@garantiplus.mx`** — no `Contacto@garantiplus.co` como sugería la captura que citaba el PRD. Ese ejemplar era de Colombia, como se sospechaba.

23 de los 40 correos son de la plataforma, en **cuatro tipos**:

| Tipo | Asunto | Cuerpo |
|---|---|---|
| **Asignación** | `Asignación de avería {ID} / Vin {VIN}` | «Se le ha asignado la atención de la avería registrada con **folio {ID}** correspondiente al vehículo con VIN {VIN}.» |
| **Carga de archivo** | `Carga de archivo en avería {ID} / Vin {VIN}` | «Se ha registrado un nuevo archivo (**{NOMBRE} / {TIPO}**) para la avería {ID} del vehículo con VIN {VIN}.» |
| **Observaciones** | `Observaciones sobre avería {ID} / Vin {VIN}` | «Se han registrado las siguientes observaciones por parte de la agencia: *{TEXTO LIBRE}*» |
| **Pago** | `Pago de avería {ID} / {Marca}` | — **sin VIN en el asunto** |

### Tres regalos que el correo trae y la API no

1. **`folio` == `claimId`.** El cuerpo de la asignación dice literalmente «folio 163087» y ese es el `claimId` de la API. Queda cerrada la pregunta abierta del PRD.
2. **El correo de carga nombra el archivo y su tipo**: `SERIE.jpeg / Varios`. Se puede saber qué se subió sin llamar a la API.
3. **El correo de observaciones trae la descripción de la falla en texto libre.** Compensa que el campo `description` de la API venga vacío en el 44% de los casos: *«Durante la inspección se identificó corte localizado en el costado exterior del neumático, presentando fuga de aire en dicha zona.»*

### R5 — Un caso puede generar 18 correos en 14 minutos

La avería **163087** produjo, el 1 de septiembre: 1 asignación (19:38), **16 cargas de archivo** entre las 19:47:55 y las 19:49:52, y 1 de observaciones (19:51).

Confirma con crudeza la política de silencio del PRD (RF-81) y añade un requisito que el plan no tenía: **agrupar eventos en una ventana temporal**. Reevaluar la suficiencia dieciséis veces en cuatro minutos es tirar dinero de modelo y, con la clasificación por visión, mucho más. Hay que esperar a que el goteo se detenga antes de evaluar.

### El canal humano existe y es ruidoso

Los otros 17 correos son personas: agencias escribiendo directo (`garantias@bmwcancun.mx`, `Garantias@mitsubishimerida.com.mx`), reenvíos entre técnicos, «Solicitud de reconsideración – Avería 157279 / Contrato 771162», hilos `RE:`/`Fwd:` sobre averías concretas. El parser debe filtrar por remitente `plataforma@garantiplus.mx`, no solo por patrón de asunto.

## R2 resuelto a medias: el centinela 57227

Las **44** averías que no resolvían contrato tenían **todas** el mismo `contractId`: **57227**. No es un contrato: es un valor centinela. `GetContractById/57227` da 404 y aparece en **3 358 de las 17 160 averías (19.6%)** de la base.

**El `policyId` es el puente alterno.** Donde `contractId` trae el centinela, `GetAllContracts?$filter=contractId eq {policyId}` sí resuelve.

| Estrategia | Cobertura sobre las 100 averías más recientes |
|---|---|
| Solo `contractId` | 55% |
| `contractId` → `policyId` | **71%** |

El 29% restante son **todas de Mitsubishi** (VIN con prefijo `MMB`). Existen 492 contratos Mitsubishi en la base, pero los muestreados están «Caduco» y son antiguos. Buscar por VIN tampoco los rescata. **Queda como pregunta para el equipo de SIGA o de negocio**, no se resuelve excavando.

## Proyectos dados de alta en producción

`GetProjects` devuelve 13, y cambian el mapa del alcance regional del PRD:

| id | nombre | país |
|---:|---|---|
| 1 | MITSUBISHI | MEX |
| 3 | Garantiplus MX | MEX |
| 4 | Garantiplus Light | MEX |
| 5 | GARANTIPLUS GO | MEX |
| 6 | MOTORNATION | MEX |
| 7 | Garantiplus Perú | PER |
| 8 | Costa Rica | CRI |
| 41 | Ecuador | ECU |
| 74 | Panamá | PAN |
| 107 | Guatemala | GTM |
| **140** | **Argentina** | **ARG** |
| 173 | Bridgestone | MEX |
| 206 | BMW | MEX |

**Argentina existe como proyecto** — dato que el PRD daba por desconocido. Y aparecen **Perú, Costa Rica, Ecuador, Panamá y Guatemala**, que el PRD no contempla en ninguna etapa. No aparecen Colombia ni Chile, lo que confirma que operan en instalaciones aparte.

## Estado del flujo de n8n

`Copiloto de averías` (`nJm48fpQLOM0V5nT`) quedó **desactivado**, con cinco nodos de exploración: `Webhook → Buzon → Gmail → Recorte → Responder`. El respaldo del esqueleto original está en `respaldo-copiloto-averias-original.json`. Credenciales vinculadas: `e1AHIA134O0p0PzN` (Miguel) y `oR0aKRNKwvNBmy2Q` (Eduardo).

El nodo Gmail v2.2 con `simple: false` **ya normaliza** `from`, `to`, `subject`, `date`, `messageId`, `text`, `html` y `attachments` en la raíz del item: no hace falta parsear `payload.headers`.
