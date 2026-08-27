# Inventario de huecos de la API SIGA — base del PRD api-averias-siga

**Verificado el 2026-08-26** contra los OpenAPI vivos de `qa-siga-api.garantiplus.com`.
Servicios existentes: **4** — `authentication`, `catalogs`, `contracts`, `claims`. Probados y descartados: payments, reports, notifications, documents, users, sales, policies, vehicles, workshops, dealers, audit, files, storage, integrations, webhooks (todos 404).
Cambio detectado desde el 2026-08-24: solo `AvailableProductResponse` ganó `taxAmount` y `total`. Superficie de rutas y esquemas **sin cambios**.

## Evidencia dura recogida

| Hecho | Evidencia |
| --- | --- |
| No hay escritura de estatus de avería | `ClaimResponse.statusId` es de respuesta; no existe `UpdateClaim`. El único `status` escribible es `UpdateIssueRequest.status`, que aplica a **incidencias** |
| No existe motivo de rechazo | La cadena `reason` aparece **0 veces** en todo el spec de `claims` |
| No existe historial de estatus | La cadena `history` aparece **0 veces** |
| No existe seguimiento ni comentarios | `followup`, `comment`, `seguimiento`, `observacion`: **0 ocurrencias** — aunque SIGA sí lo tiene en la interfaz y notifica por correo |
| No existe presupuesto desglosado | `budget` aparece **1 vez**, y solo en la prosa descriptiva del servicio; `labor` y refacciones: 0 |
| El odómetro solo existe en incidencias | `odometer` aparece en `CreateIssueRequest`, `IssueResponse`, `UpdateIssueRequest`. **Nunca en `ClaimResponse`** |
| No hay `GetClaimById` | Existe `GetIssueById/{id}` para incidencias, pero para averías solo la colección `GetClaims` |
| El contrato no expone límites ni valor del vehículo | `ContractInfo` trae precio, impuestos y total del **contrato**, no el límite por avería ni el valor de venta del vehículo |
| Sí se puede filtrar contrato por VIN | `ContractListResponse.vin` existe y `GetAllContracts` acepta OData |
| Sí existe el texto del certificado | `GetContractPdfDataById` — "Returns the PDF file content as extracted text" |
| Auth es de usuario humano | `POST /api/Auth/v1/Login` con `username`/`password`. `LoginResponse` trae `refreshToken` **pero no existe endpoint de refresh**. Roles de solo lectura (`GetAllRoles`, `GetRoleById`) |
| Ambigüedad de nomenclatura OData | Los ejemplos de `GetClaims` usan `IdAveria` y `VinOrPlate`; el esquema documenta `claimId` y no declara `vinOrPlate`. **Contradicción a resolver en runtime** |
| El diseño ya contempla un agente | `ConvertToClaim`: *"Human action — the agent never converts automatically"*. `CreateIssueRequest.odometer`: *"Already converted to a number by the conversational agent"* |
| El diseño ya contempla multi-país | Descripción de ambos servicios: *"Multi-country support (currently MEX, expandable to other markets)"* |
| Ya existe control por rol y rate limiting | *"Role-based authorization policies"*, *"Rate limiting policies"*, roles: workshops, technicians, coordinators, administrators |
| El servicio ya nombra "resolutions" | *"Document management for claims (budgets, resolutions, photographic/video evidence)"* — sugiere que el tipo de documento existe. **Verificar en runtime** |

## Inventario de huecos, por grupo y por etapa que desbloquea

### Grupo 0 — Plataforma y transversal *(habilita todas las etapas)*
- **G01** Identidad de máquina: flujo de credenciales de cliente, no usuario/contraseña de persona.
- **G02** Endpoint de refresco de token (el `refreshToken` se emite pero no hay dónde canjearlo).
- **G03** Rol de servicio con privilegio mínimo, y forma de asignarlo (hoy los roles son de solo lectura).
- **G04** Idempotencia en escrituras (`Idempotency-Key`).
- **G05** Eventos / webhooks: avería asignada, cambio de estatus, documento cargado.
- **G06** Nomenclatura OData consistente y documentada (`IdAveria` vs `claimId`).
- **G07** Límites de rate limiting publicados y códigos de respuesta al excederlos.
- **G08** Formato de fechas y zona horaria explícitos en el contrato.
- **G09** Entorno QA con datos representativos para pruebas automatizadas.
- **G10** Política de versionado y deprecación.

### Grupo 1 — Lectura del expediente *(desbloquea y refuerza la etapa 1)*
- **G11** `GetClaimById/{claimId}`.
- **G12** `ClaimResponse` con `vinOrPlate`, `odometer`, `projectId`/país y `productName`.
- **G13** `validationDate` y `GetClaimStatusHistory/{claimId}`.
- **G14** Catálogo de estatus de avería.
- **G15** Catálogo normalizado de motivos de rechazo.
- **G16** Componente y refacciones reclamadas en la avería.
- **G17** `documentTypeId` en la respuesta de documentos, no solo el nombre.
- **G18** Garantía contractual de que el texto del certificado es completo y fiel.
- **G19** **Condicionado estructurado**: exclusiones, régimen de mantenimiento, periodo de espera, ámbito geográfico y límites, como datos y no como prosa.
- **G20** Lectura del seguimiento y comentarios de la avería.

### Grupo 2 — Escritura de improcedencia *(desbloquea la etapa 2)*
- **G21** Resolver una avería: estatus + motivo + comentario.
- **G22** Tipo de documento "Resolución" confirmado y aceptado por la carga.
- **G23** Atribución de la escritura: identidad de servicio **y** persona que autorizó.
- **G24** Corrección o reversión de un dictamen emitido.
- **G25** Auditoría consultable: quién cambió qué y cuándo.

### Grupo 3 — Deliberación del caso procedente *(desbloquea la etapa 3)*
- **G26** Presupuesto desglosado: conceptos, refacciones, mano de obra e importes.
- **G27** Límite por avería, límite de contrato y valor de venta del vehículo, como números con su fuente.
- **G28** Marcar `Aceptada` con el detalle de lo autorizado.
- **G29** Histórico de casos por componente, para el comparativo.

### Grupo 4 — Operación de alta carga *(desbloquea la etapa 4)*
- **G30** Agregar seguimiento a la avería con la notificación que SIGA ya emite hoy.
- **G31** Consulta agregada por técnico, estatus y antigüedad (`$apply`).
- **G32** Estado de pago y comprobante del expediente.

### Grupo 5 — Operación regional *(desbloquea la etapa 5)*
- **G33** Contratos y averías de Colombia y Chile, o alcance de país en la misma API.
- **G34** Catálogos por país, normalizados entre mercados.

## Pendiente de verificación en runtime (requiere credenciales de QA)

1. ¿`GetClaims` acepta `$filter=claimId eq N` o `IdAveria eq N`?
2. ¿`ClaimResponse` devuelve `vinOrPlate` y `odometer` aunque el esquema no los declare?
3. ¿`GetDocumentType` ya incluye un tipo "Resolución"?
4. ¿`GetContractPdfDataById` devuelve el texto completo del certificado o un extracto?
5. ¿`GetAllContracts` acepta `$filter=vin eq '...'`?
6. ¿Existe alguna ruta de escritura sobre averías no documentada?
7. ¿`$apply` funciona de verdad en los listados?
8. ¿Qué roles concretos devuelve `GetAllRoles`?
9. ¿El folio del correo de asignación coincide con el `claimId` de la API?
10. ¿Se puede llegar al **odómetro y al VIN por la incidencia** asociada? `IssueResponse` trae `vinOrPlate`, `odometer` y `claimId`. Si el puente funciona, **G12 desaparece**.
11. ¿`GetContractPaymentInfo` sirve para el *"que esté pagado"* del filtro de call center?

**Regla de interpretación.** Las cuentas de prueba disponibles son de **taller** (`pruebastallergpmx@outlook.com`) y de **distribuidor** (`martin.rivero@autocom.mx`), no de técnico. Un **403** significa *"existe pero esta cuenta no tiene permiso"*, **no** *"no existe"*. Solo un **404/405** autoriza a pedir algo como función nueva.
