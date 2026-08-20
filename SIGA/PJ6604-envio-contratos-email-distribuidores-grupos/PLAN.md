# Plan de Desarrollo — Envío de contratos por email a distribuidores y grupos (PJ6604)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ6604-envio-contratos-email-distribuidores-grupos/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb + PDFGenerator + CatalogosBusinessRules + DataAccess / DataAccessColombia) |
| Rama base | `develop` |
| Rama | `feature/PJ6604-envio-contratos-email-distribuidores-grupos` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ6604` |
| Fecha de generación | 2026-08-20 |
| Estado | Validado |
| ID plan (BD) | 53 |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Extender el envío de contrato que hoy llega solo al **beneficiario** (pestaña «Correo bienvenida» del catálogo de Proyectos + gRPC `SendContractDocuments` de PDFGenerator) para que, al registrar un contrato desde la **UI de SIGA**, se envíe también a los correos configurados en el **distribuidor** y, si aplica, en el **grupo**.

- **Arquitectura:** modificación sobre el monolito SIGA Web (EC2 + .NET 8 + Razor/MVC Areas) y el servicio gRPC **PDFGenerator** que ya genera los PDF y dispara el correo al beneficiario. Sin microservicio nuevo, sin API REST nueva, sin infraestructura AWS nueva.
- **Stack:** .NET 8 / C#, Razor Views + TinyMCE (mismo patrón que Proyectos), PostgreSQL, gRPC (`Protos/PDF.proto`), proveedor de correo existente (`EmailSenderGmail` MX / `EmailSenderMS365` CO, selección por hub en `Program.cs`).
- **Alcance de código:** catálogos Distribuidores y Grupos (pestaña + persistencia), cadena de envío en PDFGenerator, flag en el proto para no disparar el envío comercial desde API / carga masiva / reenvío manual.

**Hallazgos técnicos (cierran preguntas abiertas del PRD §14):**

| Pregunta del PRD | Hallazgo en código |
|---|---|
| ¿Qué proveedor de correo usa el envío al beneficiario? | Lo dispara **PDFGenerator** vía `IEmailSender.SendEmailWithAttachmentsAsync`. MX: `EmailSenderGmail` (Gmail API). CO: `EmailSenderMS365` (Graph). El switch es por comentario en `PDFGenerator/Program.cs` y `GarantiplusWeb/Program.cs`, igual que el resto del hub. No se introduce un proveedor nuevo (RNF-01). |
| ¿El envío es síncrono? ¿Hay reintentos? | **Síncrono** dentro del RPC `SendContractDocuments`. Gmail/MS365 **no reintentan**. El contrato ya está persistido antes del gRPC; un fallo de correo no revierte el alta (el `Create` envuelve el gRPC en `try/catch`). El MVP hereda esa semántica y **no agrega reintentos**. |
| ¿Dónde viven los adjuntos? | `SendContractDocuments` genera el PDF del contrato (`GetContractPDF`) y los documentos adicionales (`ProcessDocumentsForContract`), los lee del filesystem (`DocumentosGenerados:Contratos`) y los adjunta en base64. El envío a distribuidor/grupo **reutiliza esa misma lista de adjuntos**. |
| ¿El cuerpo es HTML o texto plano? | HTML. La pestaña de Proyectos guarda `contenido_html` (textarea + TinyMCE, máx. 2 000 caracteres) y PDFGenerator lo envuelve en un layout HTML. Se replica ese formato. |
| ¿Hay asunto configurable en Proyectos? | **No.** El asunto del beneficiario está hardcodeado: `"Bienvenido(a) a Garantiplus"`. El MVP **sí** agrega asunto configurable para distribuidor y grupo (RF-05), porque el PRD lo exige. |
| ¿Hay listado de destinatarios en Proyectos? | **No.** El destinatario es el email del beneficiario de la póliza. Distribuidor/grupo necesitan un listado propio. |
| ¿Perfil exacto de administrador interno? | El save de Welcome Email está restringido a `Administrador General, Gestor de Países`. Edit de Grupos igual. Edit de Distribuidores también incluye `Administrador General Externo`. **Decisión:** pestaña y POST de envío comercial solo para `Administrador General` y `Gestor de Países`. Externo, Auditor, Usuario Distribuidor y roles comerciales **no** ven ni editan la pestaña (RF-07 / RNF-04). |
| ¿Un distribuidor pertenece a más de un grupo? | Confirmado: `distribuidor.id_grupo` es `int?` (FK simple a `grupo_distribuidor`). Como máximo un grupo; puede ser null. |
| ¿La API y la carga masiva disparan el mismo RPC? | Sí. `gp_3.0_siga_api` (`ContractCreationService.TriggerPdfGenerationAsync`) y varios flujos de SIGA Web llaman `SendContractDocuments`. La carga masiva tiene la llamada **comentada**. Para cumplir RF-16 se agrega un flag en el proto (`send_to_commercial_channels`, default `false`) y **solo** `ContratosController.Create` y `EmisionEspecial` lo encienden. |
| ¿Hay bitácora de correos? | `EmailSender` (SMTP/cola) escribe en `email_queue`; **Gmail/MS365 usados por PDFGenerator no persisten** en esa tabla. El envío al beneficiario solo deja `LogPDF` (Serilog). El MVP agrega tabla `bitacora_envio_contrato` para RF-15 / RNF-03, consultable por TI por `id_contrato`. |
| ¿`correos_proyecto` sirve para distribuidor/grupo? | No. Está keyed por `(id_proyecto, id_tipo_correo)`, no tiene destinatarios ni asunto. Se crean tablas hermanas, no se reutiliza esa fila. |

**Decisión de diseño del plan:** no se mete la lógica comercial dentro de `correos_proyecto`. Se crean `correos_distribuidor` y `correos_grupo` (mismo shape, FK reales) y una **implementación C# compartida** (RNF-08). La cadena de envío vive en PDFGenerator, que es quien ya arma el paquete de adjuntos.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante (revisión: Alexis Salvador Herrera Garcia)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — *Already up to date* con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Acceso a ejecutar scripts SQL en las BD de **México, Colombia y Chile** (mismo esquema; DataAccess vs DataAccessColombia solo en el código EF)
- [ ] Usuario de prueba **Administrador General** / **Gestor de Países** y al menos un rol no autorizado (Usuario Distribuidor, Administrador General Externo) para validar RF-07
- [ ] Distribuidor de prueba **con grupo** y otro **sin grupo**; ambos con la pestaña habilitada y correos reales/de prueba
- [ ] PDFGenerator y GarantiplusWeb corriendo en local (el envío real usa Gmail/MS365 del hub)
- [ ] No se requieren secrets ni variables de entorno **nuevas** (se reutilizan `EmailSettings` / `M365Emailing` ya existentes)

---

## 3. Arquitectura del cambio

Se respeta la arquitectura existente de SIGA Web (`rules/arquitectura.md`): feature sobre monolito + servicio gRPC ya desplegado. El árbol de decisión de infra (`rules/infraestructura.md`) indica: modificación → mantener donde ya vive (EC2 para SIGA Web, proceso PDFGenerator actual).

```
[Admin General / Gestor de Países]
  → Edit Catálogo Distribuidor / Grupo
      → Pestaña "Envío de contrato"
          → CatalogosBusinessRules (Get/Upsert compartido)
              → PostgreSQL.correos_distribuidor | correos_grupo

[Asesor / Usuario Distribuidor / …]
  → POST Contratos/Create  (o EmisionEspecial)
      → persiste contrato  (ya ocurre hoy)
      → gRPC PDFGenerator.SendContractDocuments(send_to_commercial_channels=true)
          → genera PDF + documentos adicionales   (paquete único)
          → 1) envío beneficiario (comportamiento actual, correos_proyecto / WelcomeEmail)
          → 2) si flag y config distribuidor (enviar=true y ≥1 correo) → envío
          → 3) si flag y distribuidor.id_grupo y config grupo (enviar=true y ≥1 correo) → envío
          → cada hop en try/catch propio → bitacora_envio_contrato + Serilog
          → un fallo no aborta los siguientes ni el contrato

[API SIGA / carga masiva / EnviaEmail / RegeneraEmailContrato / Upgrade / ODP]
  → SendContractDocuments(send_to_commercial_channels=false)  ← default proto
      → solo beneficiario (como hoy)
```

**Decisiones de diseño:**

1. **Tablas hermanas, no genérica única.** `correos_distribuidor` y `correos_grupo` con el mismo esquema (enviar, destinatarios, asunto, contenido_html, auditoría). Permite FK a `distribuidor` y `grupo_distribuidor`. La unicidad de implementación está en C# (RNF-08), no en una sola tabla con `tipo_entidad`.
2. **Destinatarios:** columna `TEXT` con un correo por línea (o separados por `;` / `,`). Al enviar se parsean, se recortan y se descartan vacíos. Máximo **20** correos por entidad (cierra pregunta abierta del PRD; validar en UI y al persistir). Sin tabla hija en el MVP.
3. **Habilitación + listado vacío:** se guarda tal cual (permisivo). En tiempo de envío, `enviar && destinatarios.Any()` es la única condición; si no, se omite **sin error** (RF-13). Default de `enviar` al no existir fila: **false** (no emailar hasta que un admin lo active).
4. **Asunto vacío en envío:** si hay destinatarios pero el asunto está vacío, fallback `"Contrato {id_contrato}"`. El cuerpo vacío usa un texto mínimo equivalente al default de Welcome Email, recortado al contexto comercial (no el copy de “bienvenida al cliente”).
5. **Flag proto `send_to_commercial_channels`:** default `false` para no romper consumidores (API, ODP, reenvío). Solo Create y Emisión especial lo ponen en `true`.
6. **Independencia de fallos (RF-14 / RNF-02):** extraer la generación de adjuntos del `try` único actual. Si falla la generación de PDF, no hay envíos (igual que hoy). Cada envío (beneficiario / distribuidor / grupo) tiene su propio `try/catch`; el RPC no debe devolver HTTP 500 solo porque falló un correo.
7. **Roles:** pestaña visible y POST `[Authorize(Roles = "Administrador General,Gestor de Países")]`. En Distribuidores, `Administrador General Externo` sigue editando datos generales pero **no** ve la pestaña.
8. **Países:** scripts SQL idénticos en las tres BD. Modelos EF espejo en `DataAccess` y `DataAccessColombia` (Chile comparte DataAccess con MX). El proveedor de correo sigue el hub; no se toca el switch de `Program.cs`.
9. **Sin cambios de API SIGA** (`gp_3.0_siga_api`): el default del flag ya excluye ese canal (RF-16).
10. **Código nuevo en inglés** (`coding-guidelines.md`); mensajes de UI y de error al usuario en español. No refactorizar `CatalogosBusinessRules` ni `ContratosController` más allá de lo necesario para enganchar la feature.

**Fuera de alcance (confirmado por PRD §6):** carga masiva, API, reenvío manual, envío ante modificaciones/upgrade, consola de consulta, plantillas HTML con diseño/logos, reintentos, visibilidad de rebotes.

---

## 4. Tareas de desarrollo

### Fase 0 — Modelo de datos (P1)

- [ ] **T-01** — Script SQL de configuración de envío por distribuidor y por grupo
  - Archivos a crear: `GarantiplusWeb/BD/2026-08-20_pj6604_envio_contrato_canal/01_correos_distribuidor_grupo.sql`
  - Contenido:
    - `INSERT` en `tipo_correo`: `ContractChannelEmail` (`ON CONFLICT (nombre) DO NOTHING`)
    - Tablas `correos_distribuidor` y `correos_grupo` con: `id` serial PK, FK a la entidad, `id_tipo_correo`, `enviar bool default false`, `destinatarios text not null default ''`, `asunto varchar(200) not null default ''`, `contenido_html text not null default ''`, `fecha_creacion`, `fecha_modificacion`, `id_usuario_modificacion`, `activo`, unique `(id_entidad, id_tipo_correo)`, grants a `acceso_garantiplus` (mismo patrón que `2025_12_10_cc_welcome_email.sql`)
  - Criterio de completitud: el script es idempotente (`IF NOT EXISTS` / `ON CONFLICT`) y se puede ejecutar en MX, CO y CL.

- [ ] **T-02** — Script SQL de bitácora de envíos
  - Archivos a crear: `GarantiplusWeb/BD/2026-08-20_pj6604_envio_contrato_canal/02_bitacora_envio_contrato.sql`
  - Tabla `bitacora_envio_contrato`: `id_bitacora serial PK`, `id_contrato bigint not null`, `tipo_destinatario varchar(20) not null` (`beneficiario` / `distribuidor` / `grupo`), `id_entidad int null`, `destinatarios text`, `exitoso bool not null`, `mensaje_error text null`, `fecha timestamp not null default now()`. Índice por `id_contrato`. Grants.
  - Criterio de completitud: TI puede consultar `WHERE id_contrato = ?` y ver cada hop con resultado.

- [ ] **T-03** — Modelos EF espejo (sin DbSet, igual que `correos_proyecto`)
  - Archivos a crear: `DataAccess/Models/correos_distribuidor.cs`, `DataAccess/Models/correos_grupo.cs`, `DataAccess/Models/bitacora_envio_contrato.cs` y los mismos tres en `DataAccessColombia/Models/`
  - Criterio de completitud: ambos contextos tienen el mismo shape; no hace falta registrar `DbSet` (Welcome Email tampoco lo hace; se usa SQL parametrizado).

### Fase 1 — Configuración en catálogos (P1)

- [ ] **T-04** — Servicio compartido de lectura/escritura de la configuración
  - Archivos a crear: clase nueva en `CatalogosBusinessRules` (p. ej. `ContractChannelEmailConfiguration.cs`) con `GetAsync(entityType, entityId)` y `UpsertAsync(...)` parametrizados para distribuidor y grupo. SQL parametrizado (nunca concatenar).
  - Archivos a modificar: ninguno de Welcome Email (no tocar `UpsertWelcomeEmailConfiguration`).
  - Criterio de completitud: un único código sirve a ambos catálogos; round-trip de guardar y leer en ambas entidades.

- [ ] **T-05** — Partial compartido de la pestaña (interruptor, destinatarios, asunto, cuerpo HTML)
  - Archivos a crear: `GarantiplusWeb/Areas/Catalogos/Views/Shared/_ContractChannelEmail.cshtml` (o equivalente bajo Catalogos)
  - Campos: checkbox `enviar`, textarea destinatarios (un correo por línea), input asunto, textarea `contenido_html` con TinyMCE como en `Proyectos/Edit.cshtml`. Contador 2 000 caracteres. Default `enviar` desactivado.
  - Criterio de completitud: el mismo partial se renderiza en Distribuidores y en Grupos cambiando action/id.

- [ ] **T-06** — Pestaña en catálogo de Distribuidores
  - Archivos a modificar:
    - `GarantiplusWeb/Areas/Catalogos/Views/Distribuidores/Edit.cshtml` — envolver en `<tabs>` (tab datos actuales + tab «Envío de contrato»), reutilizando el partial de país (`_EditMEX` / `_EditCOL` / `_EditCHL` / etc.) en el primer tab. **No** duplicar el formulario por país en el tab de correo.
    - `GarantiplusWeb/Areas/Catalogos/Controllers/DistribuidoresController.cs` — GET Edit carga ViewBag de la config; POST `SaveContractChannelEmail` con `[Authorize(Roles = "Administrador General,Gestor de Países")]` + anti-forgery.
  - La pestaña solo se pinta si `User.IsInRole("Administrador General") || User.IsInRole("Gestor de Países")`.
  - Criterio de completitud: Admin General / Gestor guardan la config; Usuario Distribuidor y Administrador General Externo no ven el tab ni pueden POST (403).

- [ ] **T-07** — Pestaña en catálogo de Grupos
  - Archivos a modificar:
    - `GarantiplusWeb/Areas/Catalogos/Views/Grupos/Edit.cshtml` — mismo patrón de tabs sobre `_Edit`.
    - `GarantiplusWeb/Areas/Catalogos/Controllers/GruposController.cs` — GET Edit carga config; POST gemelo con los mismos roles.
  - Criterio de completitud: paridad funcional con Distribuidores (RF-01 / RF-02).

- [ ] **T-08** — Validación de destinatarios al guardar (permisiva con el interruptor)
  - Archivos a modificar: servicio de T-04 + JS del partial (T-05)
  - Reglas: se **permite** guardar `enviar=true` con listado vacío (RF-13). Si hay correos, cada uno debe tener formato válido; máximo 20; se ignoran líneas vacías. El cuerpo/asunto no bloquean el guardado.
  - Criterio de completitud: correo mal formado muestra error en español; listado vacío + interruptor on se persiste.

### Fase 2 — Cadena de envío al registrar (P1)

- [ ] **T-09** — Flag en el contrato gRPC
  - Archivos a modificar: `Protos/PDF.proto` — agregar `bool send_to_commercial_channels = 3;` a `SendContractDocumentsRequest` (default proto3 = false). Regenerar el cliente/servidor como ya se hace en el repo.
  - Criterio de completitud: consumidores que no setean el campo siguen enviando solo al beneficiario.

- [ ] **T-10** — Extraer generación de adjuntos y aislar el envío al beneficiario
  - Archivos a modificar: `PDFGenerator/Server/PDFGenerationService.cs` (`SendContractDocuments`)
  - Separar: (a) armar `List<AttachmentFile>`, (b) envío beneficiario en `try/catch` propio, (c) no devolver `ErrorInfo` 500 por fallo de correo. Si falla la generación de PDF, se mantiene el error actual.
  - Criterio de completitud: un fallo de Gmail/MS365 en el hop del beneficiario no impide los hops siguientes y no marca el RPC como 500.

- [ ] **T-11** — Hops distribuidor y grupo
  - Archivos a modificar: `PDFGenerator/Server/PDFGenerationService.cs` (método privado dedicado, para no inflar más el archivo)
  - Flujo si `request.SendToCommercialChannels`:
    1. Resolver `id_distribuidor` e `id_grupo` del contrato (join `contrato` → `distribuidor`).
    2. Leer config distribuidor; si `enviar && hay correos` → enviar con **los mismos adjuntos**, asunto/cuerpo de la config.
    3. Si `id_grupo` tiene valor, leer config grupo; misma condición → enviar.
    4. Cada hop independiente (RF-14). Listado vacío = omitir sin error (RF-13).
  - Criterio de completitud: contrato con dealer+grupo habilitados genera 3 correos; dealer sin grupo omite el tercero; dealer deshabilitado y grupo habilitado **sí** envía al grupo (el PRD no acopla el éxito/habilitación del dealer al grupo; solo la pertenencia).

- [ ] **T-12** — Encender el flag solo en registro UI
  - Archivos a modificar: `GarantiplusWeb/Areas/Contratos/Controllers/ContratosController.cs`
    - `Create` (POST, ~L1453): `SendToCommercialChannels = true`
    - `EmisionEspecial` (POST, ~L2043): `SendToCommercialChannels = true` (también es registro individual desde UI)
  - Criterio de completitud: un alta desde Create/Emisión especial dispara la cadena.

- [ ] **T-13** — Exclusión de canales (RF-16) — verificación, no feature nueva
  - Archivos a **no** modificar (dejar el default `false`): API `ContractCreationService.TriggerPdfGenerationAsync`; `EnviaEmail`; `RegeneraEmailContrato`; `Upgrade`; bloque comentado de carga masiva (~L7116); `OrdenesPagoController` caso `"enviar_documentos_contrato"`; duplicado de contrato cancelado (~L4389).
  - Criterio de completitud: checklist en §10 cubierto; si alguien descomenta la carga masiva en el futuro, el default del proto sigue protegiendo.

### Fase 3 — Bitácora, errores y verificación (P1)

- [ ] **T-14** — Persistir cada intento en `bitacora_envio_contrato`
  - Archivos a modificar: helper de envío en PDFGenerator
  - Escribir **después** de cada hop (éxito o fallo), incluyendo el del beneficiario cuando se intentó. La escritura de bitácora va en su propio `try/catch`: si falla el INSERT, se loguea y no se altera el resultado del correo ni el contrato (RNF-02).
  - Criterio de completitud: tres hops = tres filas; hop omitido por config apagada **no** genera fila (no es un intento). Hop omitido por listado vacío tampoco.

- [ ] **T-15** — Logs técnicos en inglés (Serilog / `LogPDF`)
  - Archivos a modificar: mismo helper
  - Information: contrato, tipo de destinatario, cantidad de correos, éxito. Warning: omitido por config. Error: excepción de envío **sin** volcar el HTML del cuerpo ni adjuntos.
  - Criterio de completitud: un reclamo de “no me llegó” se diagnostica con `id_contrato` en bitácora SQL y, si hace falta, en el log de PDFGenerator.

- [ ] **T-16** — Checklist de aceptación manual (no hay proyectos de test en SIGA Web)
  - Archivos: ninguno de producto; evidencia en `AVANCE.md` al ejecutar.
  - Recorrer los criterios de §10 en local (MX) y anotar si CO/CL quedan pendientes de smoke en su hub.
  - Criterio de completitud: todos los ítems de §10 marcados o con excepción documentada.

---

## 5. Cambios en base de datos

Ejecutar los scripts en **las tres BD** (México, Colombia, Chile). No hay migraciones EF; el repo usa scripts en `GarantiplusWeb/BD/`.

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `tipo_correo` | Insert | Fila `ContractChannelEmail` |
| `correos_distribuidor` | Nueva | Config de envío por distribuidor (interruptor, destinatarios, asunto, HTML, auditoría) |
| `correos_grupo` | Nueva | Igual, por grupo |
| `bitacora_envio_contrato` | Nueva | Un registro por intento de envío (contrato, entidad, correos, resultado, fecha) |

Sin cambios a `distribuidor`, `grupo_distribuidor`, `correos_proyecto` ni `poliza`.

---

## 6. Endpoints nuevos o modificados

No hay API REST nueva. Acciones MVC y un campo gRPC:

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `Catalogos/Distribuidores/SaveContractChannelEmail` | Guarda config de envío del distribuidor | Nuevo |
| POST | `Catalogos/Grupos/SaveContractChannelEmail` | Guarda config de envío del grupo | Nuevo |
| RPC | `PDFService.SendContractDocuments` | Nuevo campo `send_to_commercial_channels` | Modificado |
| POST | `Contratos/Create` | Setea el flag en `true` | Modificado |
| POST | `Contratos/EmisionEspecial` | Setea el flag en `true` | Modificado |

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| *(ninguna nueva)* | Se reutilizan `EmailSettings:*` (MX/Gmail) y `M365Emailing:*` (CO) ya usadas por PDFGenerator | Desarrollo / QA / Producción |
| `WelcomeEmailExcludedCountries` | Existe en `PDFGenerator/appsettings.json` (`CHL`, `PER`, `MEX`) pero **no se usa** en `SendContractDocuments`. No modificarla en este MVP; el envío al beneficiario actual no la consulta. | — |

---

## 8. Consideraciones de seguridad

- **Autorización:** pestaña y POST solo `Administrador General` y `Gestor de Países`. Anti-forgery en los POST. El usuario distribuidor no puede apuntar el contrato a buzones arbitrarios (RF-07).
- **Datos sensibles:** el correo lleva PDF del contrato (datos del beneficiario y del vehículo) a buzones operativos que el admin captura. No se amplía el universo de quién *puede* ver el contrato en SIGA (supuesto del PRD); sí se envía una copia fuera del sistema. No loguear el HTML completo ni los PDF en base64.
- **Secrets:** no se agregan. Credenciales de Gmail/M365 siguen fuera del código.
- **SQL:** solo comandos parametrizados (`:param` / `@param`).
- **IAM / AWS:** sin cambios.
- **Validación:** formato de email en servidor (no solo JS). Tope de 20 destinatarios para limitar abuso.

---

## 9. Consideraciones de infraestructura

- Sin servicios AWS nuevos. SIGA Web sigue en EC2; PDFGenerator sigue donde ya corre.
- El envío es síncrono al RPC (igual que hoy). Adjuntos pesados pueden alargar el guardado (riesgo del PRD); no se introduce cola en el MVP.
- Cloudflare / Route 53 / ECS: sin cambios.
- Despliegue: coordinar **SIGA Web + PDFGenerator** (proto compartido) y ejecutar SQL **antes** de subir código que lea las tablas nuevas.

---

## 10. Criterios de aceptación

- [ ] Al editar un distribuidor, Admin General / Gestor ven la pestaña de envío con interruptor, listado, asunto y cuerpo HTML, equivalente en comportamiento a «Correo bienvenida» de Proyectos (RF-01, RF-03 a RF-06).
- [ ] Lo mismo al editar un grupo (RF-02).
- [ ] Usuario Distribuidor, Ejecutivo de Ventas, Gerente Comercial, Vendedor, Auditor y Administrador General Externo **no** ven ni pueden guardar esa pestaña (RF-07, RNF-04).
- [ ] Se puede guardar interruptor encendido con listado vacío; al registrar un contrato esa entidad **no** recibe correo y **no** hay error (RF-13).
- [ ] Alta desde `Contratos/Create` (UI): orden beneficiario → distribuidor → grupo (RF-08, RF-09). Cada correo adjunta PDF del contrato + documentos adicionales generados (RF-10).
- [ ] Distribuidor sin grupo: no hay tercer envío y no es error (RF-12).
- [ ] Distribuidor sin habilitar / sin correos: se omite su hop; si el grupo está habilitado y el dealer pertenece a él, el grupo **sí** recibe.
- [ ] Un fallo en el hop del beneficiario no impide el del distribuidor; un fallo del distribuidor no impide el del grupo; el contrato queda registrado (RF-14, RNF-02, RNF-06).
- [ ] Alta vía API SIGA, carga masiva, `EnviaEmail`, `RegeneraEmailContrato`, Upgrade y «enviar_documentos_contrato» de ODP **no** disparan hops comerciales (RF-16).
- [ ] Cada intento (no las omisiones por config) deja fila en `bitacora_envio_contrato` con contrato, tipo de entidad, correos y éxito/fallo + timestamp (RF-15, RNF-03).
- [ ] El usuario que registró el contrato no ve detalle técnico si el correo falla (RNF-06).
- [ ] Misma implementación C# para ambas entidades (RNF-08). Sin proveedor de correo nuevo (RNF-01). Scripts aplicables a MX/CO/CL (RNF-05).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Adjuntos pesados alargan el POST de Create (síncrono) | Media | Medio | Heredar latencia actual (RNF-07). No meter cola en MVP. Si un proyecto genera muchos PDF, documentar en AVANCE y no bloquear el alta. |
| Límite de tamaño del proveedor (Gmail/Graph) rechaza el correo | Media | Alto | Capturar excepción, bitácora `exitoso=false`, cadena continúa. Sin reintentos (asumido). |
| `SendContractDocuments` hoy envuelve todo en un solo try y devuelve 500 | Alta (código actual) | Medio | T-10: aislar hops. Si no se hace, un fallo de dealer abortaría el grupo y ensuciaría el RPC. |
| API / ODP / reenvío manual llaman el mismo RPC | Alta | Alto | Flag proto default false (T-09, T-13). No depender de “acordarse” de no llamar. |
| Edit de Distribuidores es un partial distinto por país | Media | Bajo | Tabs solo en `Edit.cshtml`; el tab de correo es único y no se copia a `_EditMEX/_EditCOL/_EditCHL`. |
| PDFGenerator `Program.cs` tiene Gmail hardcodeado (MS365 comentado) | Media | Medio | No cambiar el switch en este PR; respetar el hub. Validar smoke en CO cuando el binario de PDFGenerator de ese país use MS365. |
| `WelcomeEmailExcludedCountries` incluye MEX y no se usa | Baja | Bajo | No tocarlo. Evitar “activar” esa lista por accidente. |
| CatalogosBusinessRules y ContratosController son archivos enormes | Alta | Bajo | Clase nueva para config (T-04) y método privado en PDFGenerator (T-11). No refactorizar el resto. |
| TinyMCE / HTML en el cuerpo | Baja | Bajo | Replicar Proyectos; el MVP no maqueta logos (fuera de alcance). |
| Correos mal capturados / rebotes | Media | Medio | Validar formato al guardar. Rebotes siguen invisibles (riesgo aceptado del PRD). |
| Falta de consola | Alta (alcance) | Bajo | Bitácora SQL + Serilog. Documentar query de diagnóstico en §12. |

---

## 12. Notas para el programador

1. **Query de diagnóstico para TI** (sin consola):
   ```sql
   SELECT fecha, tipo_destinatario, id_entidad, destinatarios, exitoso, mensaje_error
   FROM bitacora_envio_contrato
   WHERE id_contrato = :id
   ORDER BY fecha;
   ```
2. **Create vs Emisión especial:** ambos son registro individual en UI → ambos encienden el flag. Upgrade, duplicado de cancelado y reenvío manual **no**.
3. **Grupo independiente del interruptor del dealer:** la pertenencia (`id_grupo`) es el único puente. Un dealer con envío apagado y grupo con envío prendido **sí** notifica al grupo.
4. **No tocar** `UpsertWelcomeEmailConfiguration` / `_WelcomeEmail.cshtml` salvo que un bug de paridad lo exija; el hop del beneficiario se conserva.
5. **País Chile:** mismo DataAccess que MX; hay que correr el SQL en su BD. El listado `WelcomeEmailExcludedCountries` no gobierna este envío.
6. **Despliegue:** SQL → PDFGenerator (proto) → GarantiplusWeb. Si Web sube antes que PDFGenerator, el campo proto extra se ignora (default false) y no hay envío comercial; no rompe el alta.
7. **Límite 20 correos y fallback de asunto** cierran preguntas abiertas del PRD; si Operaciones pide otro tope o asunto obligatorio, ajustar en ejecución y anotarlo en AVANCE.
8. **Código existente en español** (`enviar`, `contenido_html`, nombres de tablas): los modelos EF siguen el naming de las columnas (como `correos_proyecto`). El servicio nuevo y los logs van en inglés.
9. No commitear `appsettings.json` locales (el working tree de develop suele traer cambios de conexión).

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Modelo de datos (P1)** | Scripts SQL (config + bitácora) y modelos EF espejo MX/CO | T-01 a T-03 | 1 – 1.5 días | 177 |
| **Fase 1 — Configuración en catálogos (P1)** | Servicio compartido, partial, pestañas Distribuidores/Grupos, roles y validación | T-04 a T-08 | 2 – 3 días | 178 |
| **Fase 2 — Cadena de envío (P1)** | Flag proto, hops independientes, Create/Emisión especial, exclusión de canales | T-09 a T-13 | 2 – 3 días | 179 |
| **Fase 3 — Bitácora y verificación (P1)** | Persistencia de intentos, logs, checklist de aceptación | T-14 a T-16 | 1 – 2 días | 180 |
| **Total proyecto (P1)** | Configuración + envío (el PRD no separa P2/P3; el fuera de alcance queda fuera) | 16 tareas | ~6 – 9.5 días hábiles (≈ 1.5 – 2 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 + Fase 3 | T-01 a T-16 | ~6 – 9.5 días hábiles (≈ 1.5 – 2 semanas) | — |

> **Notas sobre la tabla:**
> - El PRD declara alcance único: configuración y envío se entregan juntos. No hay P2/P3; carga masiva, API, reenvío y consola están explícitamente fuera.
> - Los rangos salen de: SQL idempotente conocido (Fase 0 corta), UI de catálogos con partials por país y TinyMCE (Fase 1), y el riesgo real en PDFGenerator/`SendContractDocuments` + proto (Fase 2).
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD **no fija fecha límite**. Con un desarrollador, el MVP cabe en **~2 semanas hábiles**. Si apareciera un corte &lt; 5 días, no cabe el alcance completo: habría que recortar a solo catálogos (Fase 0+1), pero el propio PRD dice que eso no aporta valor. En ese caso, sumar un segundo desarrollador (UI catálogos ∥ cadena PDFGenerator) comprimiría a ~4 – 6 días (~30–40 %).

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
