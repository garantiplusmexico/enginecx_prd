# Plan de Desarrollo — Módulo de Siniestros (Omega)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Omega/PJ9840-modulo-siniestros/PRD.md` (v0.2, 2026-07-28) |
| Repositorio | `gp_seguros` (backend) + `frontend-omega` (frontend) |
| Rama | `feature/PJ9840-modulo-siniestros` (misma en ambos repos) |
| Tipo | Feature (módulo nuevo dentro de un sistema existente) |
| Responsable | Alexis Salvador Herrera Garcia |
| Folio PRD | PJ9840 |
| Fecha de generación | 2026-07-29 |
| Estado | Borrador |
| Rama base | `develop` (verificada y actualizada en ambos repos) |
| ID plan (BD) | *(lo escribe el flujo al registrar el plan)* |

---

## 1. Resumen técnico

Se construye un **módulo de siniestros nuevo dentro del ecosistema Omega**, sin tocar los dominios existentes (cotización, emisión, clientes, vehículos). El MVP de la Fase 1 del PRD se traduce en cinco componentes nuevos y dos modificaciones de integración:

**Backend (`gp_seguros`, .NET 8 + PostgreSQL):**

1. `Services/siniestros/SiniestrosApi/` — microservicio Web API: CRUD de siniestros, bitácora de seguimiento, gestión documental, bandeja de avisos pendientes y exportación a Excel.
2. `Services/siniestros/AvisoSiniestroParsers/` — biblioteca de clases con el DTO canónico del aviso y un parser por aseguradora (GNP, Qualitas, HDI, La Latino, El Potosí, Chubb), más el resolver que elige cuál aplica.
3. `Services/siniestros/AvisosSiniestroWorker/` — worker `IHostedService` que sondea el buzón compartido de Gmail, separa avisos agrupados, invoca el parser correspondiente, cae a extracción por LLM cuando no hay parser determinista aplicable, y degrada a revisión manual cuando ninguna vía alcanza confianza suficiente.
4. `Common/proyectos_auxiliares/MigracionExpedientesSiniestros/` — consola de ejecución única para migrar el acervo histórico de Google Drive a S3.
5. `Services/apigateway/krakend.json` — publicación de las rutas nuevas bajo `/api/v1/siniestros*`.

**Frontend (`frontend-omega`, Vue 2 + Vuetify):** área nueva `src/views/siniestros/` con listado, detalle (datos / bitácora / documentos), y bandeja de avisos pendientes de revisión; más el registro en router, sidebar y store.

**Arquitectura:** microservicios en contenedores sobre ECS + Fargate, con NATS para el desacople entre la ingesta de correo y el registro del siniestro — exactamente el patrón que Omega ya usa para cotizaciones (`rules/arquitectura.md` §1 y §4). **Stack:** .NET Core 8 / C# en backend, Vue 2 + Vuetify en frontend (se respeta el stack existente de Omega, `rules/stack.md`), PostgreSQL, Docker + ECS/Fargate, S3 para documentos.

**Alcance explícitamente excluido** (PRD §6): vínculo automático con pólizas de Omega, portal de tickets para distribuidores, integración con "la financiera" y módulo de cobranza. El sistema **captura y organiza; no decide** sobre procedencia, montos ni cierre (PRD §5).

---

## 2. Prerequisitos

Bloqueantes — sin esto no arranca la Fase 2 (ingesta):

- [ ] **Buzón compartido de siniestros aprovisionado** en Google Workspace (ej. `siniestros@...`). Es riesgo abierto en el PRD §13 y pregunta abierta §14. Sin él no hay fuente de avisos para desarrollar ni probar.
- [ ] **Credenciales OAuth / cuenta de servicio de Google** con delegación a nivel dominio y scope `https://www.googleapis.com/auth/gmail.readonly` sobre ese buzón. El proyecto existente `Common/proyectos_auxiliares/GeneradorTokenGmail` solo tiene `GmailService.Scope.GmailSend` — hay que emitir credenciales nuevas con scope de lectura.
- [ ] **Corpus de avisos reales** (mínimo 10-15 por aseguradora, incluyendo casos degradados: imagen, PDF escaneado, correo con varios avisos en CC) para desarrollar y validar los parsers. Hoy solo se cuenta con capturas de pantalla y un PDF de El Potosí.
- [ ] **Acceso de solo lectura al Excel de bitácora vigente** (hojas: avisos, pérdidas totales, devoluciones de primas) — pregunta abierta del PRD §14. Define el contrato exacto del export (RF-09).

Bloqueantes de Fase 3 (migración):

- [ ] **Dimensionamiento del acervo en Google Drive** (número de expedientes, GB, años cubiertos, estructura de carpetas). Pregunta abierta del PRD §14 y riesgo directo sobre la estimación de la Fase 3.
- [ ] **Credenciales de Google Drive API** (scope `drive.readonly`) sobre las carpetas del acervo.

Infraestructura y accesos:

- [ ] Bucket S3 para expedientes de siniestros creado, con cifrado SSE-KMS y política de retención a 10 años (RNF-03).
- [ ] Credenciales de API de Anthropic para la extracción por LLM, en AWS Secrets Manager.
- [ ] Base de datos PostgreSQL de desarrollo accesible con la cadena `ConnectionStrings__GPSeguros_Connection`.
- [ ] `CLAUDE.md` presente en ambos repositorios — ✅ generado el 2026-07-29 como parte de este flujo.
- [ ] Repositorios en `develop` actualizado — ✅ verificado.

⚠️ **Hallazgo de seguridad previo, a resolver antes de tocar el proyecto de Gmail:** `Common/proyectos_auxiliares/GeneradorTokenGmail/credentials.json` y `token.json` **están versionados en git**, junto con tres archivos `*credentials.zip` (invarat, seguros, siga). Contraviene `rules/coding-guidelines.md` §11 y `rules/infraestructura.md` §5. Deben rotarse las credenciales expuestas, purgarse del historial y moverse a AWS Secrets Manager antes de reutilizar ese proyecto como base. Se aborda en **T-02**.

---

## 3. Arquitectura del cambio

Se aplica **microservicios en contenedores** (`rules/arquitectura.md` §1): siniestros es un dominio de negocio independiente de cotización y emisión, con su propio ciclo de vida y sus propios usuarios. Se suma el **patrón broker NATS** (§4) para que la ingesta de correo no bloquee ni acople al API: si el worker de avisos cae, el registro manual de siniestros sigue operando, y viceversa.

```
                    ┌───────────────────────────┐
Gmail (buzón        │ AvisosSiniestroWorker      │
compartido) ──poll─►│  1. lee correos no leídos  │
                    │  2. separa avisos en CC    │
                    │  3. resolver de parser     │──► AvisoSiniestroParsers
                    │  4. fallback LLM (Claude)  │      (GNP/Qualitas/HDI/
                    │  5. publica resultado      │       Latino/Potosí/Chubb)
                    └────────────┬───────────────┘
                                 │ NATS  siniestros.aviso.recibido
                                 ▼
frontend-omega          ┌──────────────────┐         ┌──────────────┐
(Vue+Vuetify) ──HTTPS──►│    KrakenD       │────────►│ SiniestrosApi│
                        │ /api/v1/siniestros│         └──────┬───────┘
                        └──────────────────┘                │
                                                    ┌───────┴────────┐
                                                    ▼                ▼
                                            PostgreSQL          S3 (expedientes,
                                            (Aurora RDS)         SSE-KMS, 10 años)
```

**Decisiones de diseño y su porqué:**

| Decisión | Justificación |
|---|---|
| Microservicio propio, no extender `generales` ni `polizas` | Dominio independiente; permite desplegar y escalar sin tocar el cotizador. Además `generales` arrastra hoy una `ProjectReference` con ruta absoluta a otro repo que rompe su build. |
| Parsers deterministas primero, LLM como respaldo | 5 de 6 aseguradoras envían campos etiquetados: un parser determinista es más barato, más rápido y auditable. El LLM cubre imágenes, PDFs escaneados y formatos no reconocidos. |
| Parsers en biblioteca separada del worker | Permite probarlos con `dotnet test` sin levantar Gmail ni NATS, y reutilizarlos desde el API para el reprocesamiento de un aviso. Espeja el patrón `RequestQualitas` / `CotizadorQualitasWorker` ya existente. |
| Tabla `aviso_siniestro` separada de `siniestro` | El PRD distingue explícitamente (§2) entre el *aviso* crudo y el *siniestro registrado*. Guardar el crudo permite reprocesar cuando se corrija un parser, sin volver a Gmail. |
| NATS entre worker y API | RNF-05 exige operación 24/7; si el API está en despliegue, los avisos se encolan en JetStream en lugar de perderse. |
| S3 con Object Lock + lifecycle | RNF-03 obliga a 10 años de retención; Object Lock en modo governance evita borrado accidental. |

---

## 4. Tareas de desarrollo

### Fase 0 — Cimientos (base de datos, esqueleto de servicio, seguridad)

- [ ] **T-01** — Diseñar y crear el esquema de base de datos del módulo
  - Archivos: `Common/reportesSQL/siniestros/001_schema_siniestros.sql` (script versionado); entidades EF en `Services/siniestros/SiniestrosApi/Models/`
  - Detalle: 12 tablas (ver §5), catálogos semilla de estatus y tipos, índices sobre `numero_poliza`, `numero_siniestro_aseguradora` y `fecha_ocurrencia`
  - Criterio de completitud: script aplicado en BD de desarrollo; `dotnet ef dbcontext scaffold` o el `siniestros_dbContext` a mano reflejan el esquema y compilan

- [ ] **T-02** — Rotar y sacar del repositorio las credenciales de Gmail expuestas
  - Archivos: `Common/proyectos_auxiliares/GeneradorTokenGmail/{credentials.json,token.json,*.zip}`, `.gitignore`
  - Detalle: revocar en Google Cloud Console las credenciales comprometidas, emitir nuevas, purgarlas del historial de git, añadirlas a `.gitignore` y documentar su carga desde AWS Secrets Manager
  - Criterio de completitud: `git log --all -- <ruta>` no devuelve el contenido de los secretos; el proyecto lee credenciales de variable de entorno

- [ ] **T-03** — Crear el esqueleto del microservicio `SiniestrosApi`
  - Archivos a crear: `Services/siniestros/SiniestrosApi/{SiniestrosApi.csproj,Program.cs,Dockerfile,build.ps1,appsettings.json,appsettings.Development.json}`
  - Detalle: copiar el wire-up estándar de `Services/generales/Program.cs` — `AddControllers` con `AuthorizeFilter` global, `AddOData(Select/Filter/OrderBy/Expand/Count, SetMaxTop(null))`, `ReferenceHandler.IgnoreCycles`, Swagger, `AddHealthChecks()`, OpenTelemetry con `serviceName = "GPSeguros.Omega.Siniestros"`, `AddEnvironmentVariables()`, `AddDbContext(UseNpgsql(...).UseNodaTime())`, JWT Bearer. Referenciar `Common/DecoratorControllerBase` y `Common/S3Access`
  - Criterio de completitud: `dotnet run` levanta, `/healthz` responde 200 y Swagger lista el servicio sin controllers

- [ ] **T-04** — Definir roles, políticas de autorización y catálogo de estatus
  - Archivos: `Services/siniestros/SiniestrosApi/Options/`, `Program.cs`, script semilla de `estatus_siniestro`
  - Detalle: RNF-01 — solo José Juan y Norma con permiso de escritura en el MVP. Política `SiniestrosEscritura` sobre un rol nuevo `Operador Siniestros`; lectura restringida al mismo rol hasta que negocio amplíe permisos (PRD §10)
  - Criterio de completitud: un usuario sin el rol recibe 403 en escritura; con el rol, 200

- [ ] **T-05** — Publicar el servicio en KrakenD y en la infraestructura local
  - Archivos: `Services/apigateway/krakend.json`, `Infrastructure/{local,qa,prod}/docker-compose.yml`
  - Detalle: host `http://gp_omega_claims`, prefijo `/api/v1/siniestros*`. Validar el JSON tras editarlo (`node -e "JSON.parse(require('fs').readFileSync('krakend.json','utf8'))"`)
  - Criterio de completitud: `docker compose up` en `Infrastructure/local` levanta el servicio y KrakenD enruta correctamente

### Fase 1 — Registro y seguimiento manual (núcleo operativo)

- [ ] **T-06** — DTOs y contratos de la API (API First)
  - Archivos: `Services/siniestros/SiniestrosApi/DTOs/Siniestros/{Requests,Responses}/`
  - Detalle: `rules/coding-guidelines.md` §5 — definir contratos antes de implementar. `CreateClaimRequest`, `UpdateClaimRequest`, `ClaimResponse`, `ClaimListItemResponse`, `AddCommentRequest`, `ChangeStatusRequest`, `UploadDocumentsRequest`
  - Criterio de completitud: contratos revisados y estables; documentación XML completa

- [ ] **T-07** — CRUD de siniestros (RF-05, RF-10)
  - Archivos: `Services/siniestros/SiniestrosApi/Controllers/ClaimsController.cs`, `Services/ClaimService.cs`, `Interfaces/IClaimService.cs`
  - Detalle: `GET /v1/claims` (OData + `/cnt` para paginación server-side, tal como espera `TablaOmega`), `GET /v1/claims/{id}`, `POST /v1/claims`, `PUT /v1/claims/{id}`. Registra tanto el folio interno como el número de siniestro de la aseguradora (RF-10)
  - Criterio de completitud: alta manual completa desde Swagger con todos los campos de PRD §10; el listado filtra y pagina vía OData

- [ ] **T-08** — Bitácora de comentarios y cambio de estatus (RF-06, RF-07, RNF-02)
  - Archivos: `Controllers/ClaimsController.cs` (acciones), `Services/ClaimTrackingService.cs`, `Models/` de bitácora
  - Detalle: `POST /v1/claims/{id}/comments`, `PATCH /v1/claims/{id}/status`. Cada cambio de estatus escribe en la tabla de auditoría con usuario, fecha/hora, estatus anterior y nuevo. El cierre exige resultado `procedió` / `no procedió`
  - Criterio de completitud: la línea de tiempo del siniestro reconstruye todos los cambios; no es posible cerrar sin resultado

- [ ] **T-09** — Gestión documental sobre S3 (RF-08, RNF-03)
  - Archivos: `Services/siniestros/SiniestrosApi/Controllers/ClaimDocumentsController.cs`, `Services/ClaimDocumentService.cs`
  - Detalle: carga masiva multipart, un registro por archivo con usuario y timestamp; almacenamiento vía `Common/S3Access` con clave `siniestros/{anio}/{folio}/{guid}-{nombre}`; descarga con URL prefirmada de vigencia corta. Validar tipo MIME y tamaño
  - Criterio de completitud: subida de 10 archivos en una sola llamada; los objetos aparecen en S3 y la descarga funciona con URL temporal

- [ ] **T-10** — Exportación a Excel (RF-09)
  - Archivos: `Services/siniestros/SiniestrosApi/Controllers/ClaimReportsController.cs`, `Services/ClaimExportService.cs`
  - Detalle: reutilizar `Common/ExcelUtils`. Replicar las hojas del Excel vigente (avisos, pérdidas totales, devoluciones de primas) — **el layout exacto depende del prerequisito de acceso a la bitácora actual**. Filtros por rango de fechas, aseguradora y estatus
  - Criterio de completitud: el archivo generado se abre en Excel y contiene las columnas que negocio reporta hoy hacia CAF

- [ ] **T-11** — Frontend: listado de siniestros
  - Archivos: `frontend-omega/src/views/siniestros/Siniestros.vue`, `src/store/modules/siniestros/index.js`, `src/store/store.js`, `src/router/default.js`, `src/store/modules/sidebar/data.js`
  - Detalle: usar `Components/TablaOmega` con paginación server-side vía `construir_URL_opciones` + endpoint `/cnt`; filtros por estatus, aseguradora y fechas. Llamar `limpia_filtros()` al montar (el objeto de filtros es estado global compartido)
  - Criterio de completitud: el listado pagina, filtra y ordena contra el API real

- [ ] **T-12** — Frontend: detalle del siniestro con pestañas
  - Archivos: `frontend-omega/src/views/siniestros/Siniestro.vue` y subcomponentes de pestaña
  - Detalle: pestañas Datos generales / Vehículo y ubicación / Coberturas / Bitácora / Documentos. Alta y edición manual; cambio de estatus con confirmación; carga masiva con arrastrar y soltar
  - Criterio de completitud: se puede dar de alta un siniestro manualmente de principio a fin, comentarlo, subirle documentos y cerrarlo desde la UI

- [ ] **T-13** — Frontend: botón de exportación y descarga
  - Archivos: `frontend-omega/src/views/siniestros/Siniestros.vue`
  - Detalle: usar `operacion_generica.obtener_reporte(url)`, que ya devuelve `responseType: 'blob'`
  - Criterio de completitud: la descarga respeta los filtros activos del listado

### Fase 2 — Ingesta automatizada de avisos

- [ ] **T-14** — Modelo canónico del aviso y contrato de parser
  - Archivos: `Services/siniestros/AvisoSiniestroParsers/{AvisoSiniestroParsers.csproj,Models/ClaimNotice.cs,Interfaces/IClaimNoticeParser.cs,Services/ClaimNoticeParserResolver.cs}`
  - Detalle: `ClaimNotice` cubre la unión de todos los campos observados (PRD §10 + condensado de formatos): identificación, contacto, tipo y causa, fechas, ubicación desglosada, vehículo completo, coberturas afectadas con montos, cabinero/ajustador. Cada parser expone `CanParse(mensaje)` y `Parse(mensaje)` devolviendo el DTO más un nivel de confianza y la lista de campos no resueltos
  - Criterio de completitud: la biblioteca compila de forma independiente y tiene proyecto de pruebas asociado

- [ ] **T-15** — Parsers de aseguradoras con campos etiquetados (GNP, Qualitas, HDI, La Latino)
  - Archivos: `AvisoSiniestroParsers/Services/{GnpClaimNoticeParser,QualitasClaimNoticeParser,HdiClaimNoticeParser,LaLatinoClaimNoticeParser}.cs`
  - Detalle: parseo de HTML/tabla anclado en las etiquetas de campo, no en posiciones. Normalización de fechas, teléfonos y nombres de aseguradora
  - Criterio de completitud: pruebas unitarias con avisos reales de cada aseguradora extraen el 100% de los campos etiquetados

- [ ] **T-16** — Parser de El Potosí (PDF estructurado)
  - Archivos: `AvisoSiniestroParsers/Services/PotosiClaimNoticeParser.cs`
  - Detalle: extracción de texto del PDF adjunto y parseo por secciones (datos generales, ubicación, datos del siniestro, vehículos afectados, historial de cobro, coberturas afectadas, observaciones)
  - Criterio de completitud: el PDF de muestra `Alerta_Siniestro_948764_AUIN-00021118-000007.pdf` se extrae completo, incluidas coberturas y montos

- [ ] **T-17** — Parser posicional de Chubb ⚠️ *mayor riesgo técnico del proyecto*
  - Archivos: `AvisoSiniestroParsers/Services/ChubbClaimNoticeParser.cs`, `Options/ChubbFieldMap.cs`
  - Detalle: Chubb envía una tabla de texto plano **sin nombres de campo**, solo valores en orden fijo. El mapeo posicional debe vivir en configuración (no hardcodeado), validarse con reglas por campo (una fecha debe parsear como fecha, una serie debe cumplir longitud) y **degradar a revisión manual en cuanto una validación falle** — así un cambio de plantilla de Chubb se detecta en lugar de producir datos silenciosamente incorrectos
  - Criterio de completitud: con el aviso de muestra extrae correctamente; con un aviso alterado a propósito (columnas movidas) marca revisión manual en lugar de aceptar datos erróneos

- [ ] **T-18** — Extracción por LLM como respaldo (imágenes, PDF escaneado, formatos nuevos)
  - Archivos: `AvisoSiniestroParsers/Services/LlmClaimNoticeExtractor.cs`, `Options/AnthropicOptions.cs`
  - Detalle: cliente de la API de Anthropic con modelo `claude-opus-5`. Usar **structured outputs** (`output_config.format` con `json_schema` derivado de `ClaimNotice`) para garantizar forma de salida; imágenes y PDF se envían como bloques de contenido nativos, sin OCR previo. Aplicar `cache_control: {type:"ephemeral"}` sobre el prompt de sistema + esquema (estable entre llamadas; el mínimo cacheable en Opus 5 es 512 tokens). `effort` en `medium` — es extracción rutinaria, no razonamiento profundo. Manejar `stop_reason == "refusal"` antes de leer `content`. Clave de API desde AWS Secrets Manager, nunca en código
  - Criterio de completitud: un aviso en imagen produce un `ClaimNotice` válido contra el esquema; el volumen esperado (200-250/mes) queda dentro del costo estimado en §9

- [ ] **T-19** — Worker de ingesta: Gmail, deduplicación y separación de avisos agrupados (RF-01, RF-03)
  - Archivos: `Services/siniestros/AvisosSiniestroWorker/{AvisosSiniestroWorker.csproj,Program.cs,Worker.cs,Dockerfile,build.ps1}`, `Services/GmailIngestionService.cs`
  - Detalle: sondeo del buzón compartido con scope `gmail.readonly` (reutilizar el patrón OAuth de `GeneradorTokenGmail`, con credenciales nuevas de T-02, y MimeKit para el MIME). Deduplicar por `Message-Id` de Gmail contra la tabla `aviso_siniestro`. Detectar y separar correos con varios avisos agrupados en CC (RF-03). Persistir siempre el crudo antes de intentar parsear. `Program.cs` sigue el patrón de `CotizadorQualitasWorker` (host genérico + OpenTelemetry + `IS3Access`)
  - Criterio de completitud: el worker procesa el buzón sin duplicar avisos entre ejecuciones y separa correctamente un correo con 3 avisos agrupados

- [ ] **T-20** — Orquestación: resolver → parser → LLM → registro o revisión manual (RF-02, RF-04, RNF-04)
  - Archivos: `AvisosSiniestroWorker/Worker.cs`, `Services/ClaimNoticeProcessingService.cs`; consumidor NATS en `SiniestrosApi`
  - Detalle: cadena de responsabilidad — parser determinista, si no aplica o falla validación se intenta LLM, y si tampoco alcanza confianza el aviso queda en `pendiente_revision` (nunca se descarta, RNF-04). Publicar en NATS `siniestros.aviso.procesado`; el API consume y crea el siniestro en estatus `Registrado`
  - Criterio de completitud: un aviso legible produce un siniestro automáticamente; uno ilegible queda en la bandeja de pendientes con el crudo consultable

- [ ] **T-21** — Frontend: bandeja de avisos pendientes de revisión
  - Archivos: `frontend-omega/src/views/siniestros/BandejaAvisos.vue`, `AvisoRevision.vue`, router y sidebar
  - Detalle: listado de avisos en `pendiente_revision` mostrando el correo original (o el adjunto) junto al formulario precargado con lo que sí se pudo extraer, para que José Juan complete y confirme. Al confirmar se crea el siniestro
  - Criterio de completitud: un aviso pendiente se resuelve desde la UI sin salir del sistema ni abrir Gmail

### Fase 3 — Migración del acervo histórico

- [ ] **T-22** — Inventario y mapeo del acervo en Google Drive (RF-11)
  - Archivos: `Common/proyectos_auxiliares/MigracionExpedientesSiniestros/Services/DriveInventoryService.cs`
  - Detalle: recorrer las carpetas con Drive API (`drive.readonly`), producir un CSV de inventario (ruta, nombre, tamaño, fecha, siniestro/cliente/aseguradora inferido) y **reportar los expedientes cuya asociación no se pueda inferir** antes de mover nada
  - Criterio de completitud: inventario completo generado y revisado con negocio; se conoce el volumen real (hoy es un riesgo abierto del PRD)

- [ ] **T-23** — Migración Drive → S3 con verificación de integridad
  - Archivos: `Common/proyectos_auxiliares/MigracionExpedientesSiniestros/{Program.cs,Services/MigrationService.cs}`
  - Detalle: consola idempotente y reanudable, con verificación por hash y bitácora por archivo. Preserva la asociación siniestro/cliente/aseguradora del inventario
  - Criterio de completitud: se puede volver a ejecutar sin duplicar; el conteo y los hashes coinciden entre origen y destino

- [ ] **T-24** — Vincular expedientes migrados a los siniestros del sistema
  - Archivos: `Common/proyectos_auxiliares/MigracionExpedientesSiniestros/Services/ClaimLinkingService.cs`
  - Detalle: crear los registros de `siniestro_documento` correspondientes; para expedientes sin siniestro previo en el sistema, dar de alta el siniestro histórico en estatus `Cerrado (histórico)`
  - Criterio de completitud: los expedientes migrados son visibles desde la pestaña Documentos del siniestro correspondiente

### Fase 4 — Eventos de BI, endurecimiento y despliegue

- [ ] **T-25** — Emisión de eventos para BI (PRD §11)
  - Archivos: `Services/siniestros/SiniestrosApi/Services/ClaimEventPublisher.cs`
  - Detalle: los siete eventos del PRD (`aviso_recibido`, `aviso_capturado_automaticamente`, `aviso_pendiente_revision`, `siniestro_registrado`, `siniestro_estatus_cambiado`, `documento_cargado`, `siniestro_cerrado`), cada uno con fecha/hora, usuario responsable (o `sistema`), número de siniestro, aseguradora y resultado/motivo
  - Criterio de completitud: los siete eventos se emiten y quedan consultables

- [ ] **T-26** — Endurecimiento de seguridad y privacidad (RNF-01, RNF-03, RNF-06)
  - Archivos: `Program.cs`, políticas IAM, configuración del bucket
  - Detalle: SSE-KMS en el bucket, política de ciclo de vida a 10 años con Object Lock en modo governance, IAM de mínimo privilegio para el worker (solo lectura de Gmail, solo escritura del prefijo del bucket), CORS restrictivo, y verificación de que no se registran datos personales en logs (`rules/coding-guidelines.md` §9)
  - Criterio de completitud: revisión de seguridad pasada; ningún secreto en el código ni en `appsettings`

- [ ] **T-27** — Pruebas de extremo a extremo y validación con negocio
  - Archivos: proyecto de pruebas de `AvisoSiniestroParsers`
  - Detalle: recorrido completo aviso → registro → seguimiento → documentos → cierre → export, con avisos reales de las seis aseguradoras. Validación del export con José Juan y Norma contra el Excel vigente
  - Criterio de completitud: negocio confirma que el export sustituye al Excel sin trabajo adicional

- [ ] **T-28** — Empaquetado, publicación de imágenes y despliegue a QA
  - Archivos: `Dockerfile` y `build.ps1` de ambos proyectos nuevos, `Infrastructure/qa/docker-compose.yml`, `.github/workflows` si aplica
  - Detalle: crear los repositorios ECR (`gp_seguros_siniestros`, `gp_seguros_avisos_worker`), publicar imágenes y desplegar. Recordar el flujo real de ramas: `feature/* → develop → pre-qa → qa` (la CI bloquea PRs a `qa` que no vengan de `pre-qa`)
  - Criterio de completitud: módulo operando en el ambiente de QA con datos de prueba

---

## 5. Cambios en base de datos

Todas las tablas son nuevas. Nomenclatura en `snake_case` minúsculo, siguiendo la convención existente del esquema de Omega.

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `siniestro` | Nueva | Entidad principal: folio interno, número de siniestro de la aseguradora, aseguradora, número de póliza / inciso / certificado, tipo, causa, fecha y hora de ocurrencia y de reporte, estatus, resultado (procedió / no procedió), auditoría de alta y modificación |
| `siniestro_ubicacion` | Nueva | Estado, ciudad, municipio, colonia, calle, entre calles, referencias |
| `siniestro_vehiculo` | Nueva | Marca, tipo, modelo, año, color, número de serie, placas, número de motor, valor comercial |
| `siniestro_contacto` | Nueva | Asegurado, conductor y quien reporta (rol + nombre + teléfonos) |
| `siniestro_cobertura_afectada` | Nueva | Cobertura, suma asegurada, deducible, monto estimado, moneda |
| `siniestro_ajuste` | Nueva | Cabinero, ajustador asignado, teléfono, fechas de asignación / llegada / término |
| `siniestro_comentario` | Nueva | Bitácora de seguimiento: usuario, fecha/hora, comentario (RF-06) |
| `siniestro_historial_estatus` | Nueva | Auditoría: estatus anterior, nuevo, usuario, fecha/hora, motivo (RNF-02) |
| `siniestro_documento` | Nueva | Nombre, tipo MIME, tamaño, clave S3, hash, usuario y fecha de carga, bandera de origen histórico (RF-08, RF-11) |
| `estatus_siniestro` | Nueva (catálogo) | Registrado, En seguimiento, En espera de documentos, Cerrado, Cerrado (histórico) |
| `aviso_siniestro` | Nueva | Aviso crudo: `message_id` de Gmail, remitente, asunto, fecha, aseguradora detectada, formato, cuerpo crudo, estatus de extracción, JSON extraído, confianza, campos no resueltos, intentos, siniestro generado |
| `aviso_siniestro_adjunto` | Nueva | Adjuntos del aviso (clave S3, tipo, tamaño) |
| `evento_bi_siniestro` | Nueva | Eventos de PRD §11 con su payload |

**Índices requeridos:** `siniestro(numero_poliza)`, `siniestro(numero_siniestro_aseguradora)`, `siniestro(fecha_ocurrencia)`, `siniestro(id_estatus_siniestro)`, `aviso_siniestro(message_id)` **único** (deduplicación), `aviso_siniestro(estatus_extraccion)`.

---

## 6. Endpoints nuevos o modificados

Expuestos por KrakenD bajo `/api/v1/...`. Todos son nuevos.

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/api/v1/siniestros` | Listado con OData (filtro, orden, paginación) | Nuevo |
| GET | `/api/v1/siniestros/cnt` | Conteo para paginación server-side | Nuevo |
| GET | `/api/v1/siniestros/{id}` | Detalle completo del siniestro | Nuevo |
| POST | `/api/v1/siniestros` | Alta manual de siniestro (RF-05) | Nuevo |
| PUT | `/api/v1/siniestros/{id}` | Actualización de datos del siniestro | Nuevo |
| POST | `/api/v1/siniestros/{id}/comentarios` | Agregar comentario de seguimiento (RF-06) | Nuevo |
| PATCH | `/api/v1/siniestros/{id}/estatus` | Cambio de estatus, con resultado al cerrar (RF-07) | Nuevo |
| GET | `/api/v1/siniestros/{id}/historial` | Bitácora de auditoría del caso (RNF-02) | Nuevo |
| POST | `/api/v1/siniestros/{id}/documentos` | Carga masiva multipart (RF-08) | Nuevo |
| GET | `/api/v1/siniestros/{id}/documentos` | Listado de documentos del caso | Nuevo |
| GET | `/api/v1/siniestros/documentos/{idDocumento}/descarga` | URL prefirmada de descarga | Nuevo |
| DELETE | `/api/v1/siniestros/documentos/{idDocumento}` | Baja lógica de documento | Nuevo |
| GET | `/api/v1/siniestros/exportacion` | Exportación a Excel con filtros (RF-09) | Nuevo |
| GET | `/api/v1/avisos-siniestro` | Bandeja de avisos, filtrable por estatus de extracción | Nuevo |
| GET | `/api/v1/avisos-siniestro/cnt` | Conteo de la bandeja | Nuevo |
| GET | `/api/v1/avisos-siniestro/{id}` | Aviso crudo + datos extraídos, para revisión | Nuevo |
| POST | `/api/v1/avisos-siniestro/{id}/confirmacion` | Confirmar y convertir el aviso en siniestro (RF-04) | Nuevo |
| POST | `/api/v1/avisos-siniestro/{id}/reproceso` | Reintentar extracción tras corregir un parser | Nuevo |
| GET | `/api/v1/catalogos/estatus-siniestro` | Catálogo de estatus | Nuevo |

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `ConnectionStrings__GPSeguros_Connection` | Cadena de conexión a PostgreSQL | Desarrollo / QA / Producción |
| `Kestrel__EndPoints__Http__Url` | `http://0.0.0.0:80` dentro del contenedor | QA / Producción |
| `SIGNING_KEY` | Clave de validación del JWT emitido por `auth` | Todos |
| `FileStorage__BucketName` | Bucket S3 de expedientes de siniestros | Todos |
| `FileStorage__Region` | Región del bucket | Todos |
| `FileStorage__Key` / `FileStorage__Secret` | Credenciales S3 — preferir rol de tarea de ECS sobre llaves | Todos |
| `Gmail__UserEmail` | Dirección del buzón compartido de siniestros | Todos |
| `Gmail__CredentialsSecretName` | Nombre del secreto en AWS Secrets Manager con las credenciales OAuth | Todos |
| `Gmail__PollingIntervalSeconds` | Frecuencia de sondeo del buzón | Todos |
| `Consumer__BrokerUrl` | `nats://gp_omega_nats:4222` | Todos |
| `Consumer__SiniestrosStream` | Stream de JetStream para avisos | Todos |
| `Consumer__AvisosSubject` | Subject de publicación/consumo de avisos | Todos |
| `Anthropic__ApiKeySecretName` | Secreto con la clave de API de Anthropic | Todos |
| `Anthropic__Model` | `claude-opus-5` | Todos |
| `Drive__CredentialsSecretName` | Credenciales de Drive API para la migración (solo Fase 3) | Desarrollo |

---

## 8. Consideraciones de seguridad

- **Secretos**: ninguno en código ni en `appsettings`. Credenciales de Gmail, Drive y Anthropic en AWS Secrets Manager (`rules/coding-guidelines.md` §11, `rules/infraestructura.md` §5). **T-02 es prerequisito**: hoy hay credenciales de Gmail versionadas en el repositorio y deben rotarse.
- **IAM de mínimo privilegio**: el worker solo necesita lectura del buzón (`gmail.readonly`) y escritura del prefijo `siniestros/` del bucket. El API solo necesita lectura/escritura de ese mismo prefijo. Ningún componente requiere permisos amplios de cuenta.
- **Autorización**: `[Authorize]` a nivel de controlador y política `SiniestrosEscritura` a nivel de método para altas, modificaciones, cambios de estatus y cierre (RNF-01). Ampliar permisos exige validación explícita con negocio (PRD §10).
- **Datos personales** (RNF-06): nombre, teléfonos, causa del siniestro y documentos del asegurado. Cifrado en reposo con SSE-KMS, TLS en tránsito, URLs de descarga prefirmadas de vigencia corta, y prohibición de registrar estos datos en logs.
- **Retención legal** (RNF-03): 10 años. Política de ciclo de vida en S3 con transición a almacenamiento de acceso poco frecuente y Object Lock en modo governance para impedir el borrado accidental. La baja de documentos en el API es lógica, nunca física.
- **Clave de API de LLM**: `rules/infraestructura.md` §5 exige restricción donde la plataforma lo permita. Adicionalmente, configurar alerta de facturación y un tope de gasto mensual, dado que un bucle de reproceso podría disparar el consumo.
- **Superficie de entrada no confiable**: los avisos vienen de correo externo. Validar y sanear todo antes de persistir; tratar los adjuntos como no confiables (validación de tipo MIME y tamaño, sin ejecución) y no renderizar HTML crudo del correo en el frontend sin sanear.

---

## 9. Consideraciones de infraestructura

- **ECS + Fargate**: dos servicios nuevos (`gp_omega_claims` para el API, `gp_omega_claims_worker` para la ingesta). El API puede iniciar con el mismo dimensionamiento que `generales` (0.5 vCPU / 250 MB). El worker es de baja carga (250 avisos/mes) pero debe correr 24/7 por RNF-05.
- **ECR**: dos repositorios nuevos de imágenes.
- **S3**: bucket nuevo para expedientes. Volumen desconocido hasta completar T-22 — es el principal hueco de dimensionamiento del proyecto.
- **RDS PostgreSQL**: sin instancia nueva; se usa la base existente de Omega. Crecimiento estimado modesto (250 siniestros/mes con sus tablas satélite).
- **Costo del LLM**: con 200-250 avisos/mes y solo los casos de respaldo llegando al LLM, el consumo esperado es de decenas de dólares al mes como máximo. El costo se dispararía únicamente ante un reproceso masivo — de ahí el tope de gasto recomendado en §8.
- **KrakenD**: sin infraestructura nueva, solo configuración.
- ⚠️ `rules/infraestructura.md` §1 marca la región de la consola AWS de GPLUS Seguros como *por definir*; los recursos existentes de Omega viven en `us-east-1` (cuenta `322202710699`). Confirmar con el Director de TI antes de crear el bucket y los repositorios de ECR.

---

## 10. Criterios de aceptación

- [ ] José Juan puede dar de alta, dar seguimiento, documentar y cerrar un siniestro completo desde Omega, sin usar el Excel.
- [ ] Un aviso de cada una de las seis aseguradoras (GNP, Qualitas, HDI, La Latino, El Potosí, Chubb) se captura automáticamente y genera un siniestro en estatus `Registrado`.
- [ ] Un correo con varios avisos agrupados en CC genera un registro por aviso (RF-03).
- [ ] Un aviso ilegible o incompleto **nunca se pierde**: aparece en la bandeja de pendientes con su contenido original consultable (RF-04, RNF-04).
- [ ] Todo cambio de estatus y toda carga de documento quedan registrados con usuario, fecha y hora (RNF-02).
- [ ] La carga masiva de documentos funciona y los archivos quedan en S3 con retención configurada a 10 años (RF-08, RNF-03).
- [ ] La exportación a Excel reproduce la información que hoy se reporta manualmente hacia CAF, validada por negocio (RF-09).
- [ ] El acervo histórico de Drive está migrado y accesible desde el siniestro correspondiente (RF-11).
- [ ] Solo los usuarios con el rol de siniestros pueden crear, modificar y cerrar; el resto recibe 403 (RNF-01).
- [ ] Los siete eventos de BI del PRD §11 se emiten correctamente.
- [ ] El worker de ingesta opera de forma continua y se recupera solo tras un reinicio, sin reprocesar avisos ya vistos (RNF-05).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Chubb cambia el orden de su plantilla sin aviso y rompe el mapeo posicional | Alta | Alto | Mapeo en configuración, no en código; validación por tipo de dato en cada campo; degradar a revisión manual ante cualquier fallo de validación en lugar de aceptar datos. Alerta cuando la tasa de fallos de Chubb suba |
| El buzón compartido no se aprovisiona a tiempo | Media | Alto | Fase 2 depende de él. Mitigación: desarrollar los parsers contra un corpus de archivos `.eml` guardados, de modo que solo la conexión a Gmail quede bloqueada, no el resto |
| El acervo en Drive es mucho mayor de lo esperado (sin dimensionar) | Media | Medio | T-22 es un inventario previo separado de la migración; permite reestimar la Fase 3 antes de comprometerse. La migración es reanudable |
| Calidad variable de PDF/imagen limita la extracción automática | Alta | Medio | El respaldo manual es parte del diseño, no una excepción. El PRD §6 ya excluye explícitamente la automatización infalible. Medir el % de automatización real y priorizar mejoras por aseguradora según volumen |
| El corpus de avisos disponible es insuficiente (hoy solo capturas de pantalla y un PDF) | Alta | Alto | Es prerequisito bloqueante de la Fase 2. Sin avisos reales por aseguradora, los parsers se construyen a ciegas y la estimación de T-15 a T-17 no es confiable |
| El layout exacto del export hacia CAF no está definido | Media | Medio | Depende del acceso a la bitácora Excel vigente (pregunta abierta del PRD §14). T-10 puede quedar bloqueada; mitigación: implementar el export genérico y ajustar columnas después |
| Credenciales de Gmail expuestas en el historial de git | Confirmada | Alto | T-02 antes de cualquier trabajo sobre Gmail: rotar, purgar del historial y mover a Secrets Manager |
| Servicio nuevo mal aislado degrada el desempeño de Omega | Baja | Medio | Contenedor y despliegue independientes; sin cambios en los servicios existentes salvo la configuración de KrakenD |
| Región de la consola AWS de GPLUS Seguros sin definir | Media | Bajo | Confirmar con Dirección de TI antes de crear bucket y repositorios de ECR |

---

## 12. Notas para el programador

- **Rama base confirmada:** `develop` existe y está actualizada en ambos repositorios. La rama funcional `feature/PJ9840-modulo-siniestros` debe crearse en los dos.
- **El flujo de ramas real no es el del README.** La CI de ambos repos bloquea los PR a `qa` que no vengan de `pre-qa`, y los PR a `main` que no vengan de `release`. El README describe un Gitflow clásico que ya no aplica.
- **No refactorizar código existente.** Los servicios actuales instancian `GPSegurosRepository` directamente en el constructor del controlador en lugar de inyectar el repositorio. Para el módulo nuevo se aplica `rules/coding-guidelines.md` (inyección por constructor, interfaces con prefijo `I`, campos privados con `_camelCase`, código en inglés), pero **sin tocar los servicios existentes**.
- **Choque de convenciones a resolver una sola vez:** el repositorio nombra las entidades en `snake_case` minúsculo (`estado`, `codigo_postal`) para espejear las tablas de PostgreSQL, mientras que las guías de Engine piden `PascalCase` en inglés. La propuesta de este plan es **tablas en `snake_case` español** (consistencia del esquema, que es compartido) y **clases en `PascalCase` inglés** con mapeo explícito por `[Table]`/`[Column]` en EF. Confirmar este criterio antes de T-01 — cambiarlo después es caro.
- **`generales` no compila sin otro repositorio.** `generales.csproj` referencia por ruta absoluta `C:\Proyectos\Garantiplus\gpmx_3.0\Common\Emailing\Emailing.csproj`. No copiar ese patrón en los proyectos nuevos.
- **Todo endpoint nuevo requiere entrada en `krakend.json`** o el frontend recibirá 404 aunque el microservicio lo tenga. Validar el JSON tras editarlo.
- **En el frontend, `src/api/index.js` es código muerto** del template Vuely. El cliente HTTP real es `src/constants/operacion-generica.js`. Su objeto `filtros` es estado global compartido entre vistas: llamar `limpia_filtros()` al montar cada listado.
- **Sobre la extracción por LLM:** usar structured outputs con `json_schema` en lugar de pedir JSON en el prompt y parsearlo — la validación ocurre del lado del API y evita respuestas malformadas. Verificar `stop_reason` antes de leer `content`. El prompt de sistema y el esquema son estables entre llamadas, así que conviene marcarlos con `cache_control`.
- **Orden de ejecución sugerido:** las Fases 0 y 1 no dependen de ningún prerequisito externo bloqueante y entregan valor por sí solas (sustituyen el Excel con captura manual). La Fase 2 sí depende del buzón y del corpus de avisos. Si esos prerequisitos se retrasan, conviene arrancar de todos modos por Fase 0 y 1 en lugar de esperar.
- **Estimación con un solo desarrollador.** Las Fases 1 (frontend + API) y 2 (parsers) son paralelizables entre dos personas con poco acoplamiento.

---

## 13. Relación de tareas y tiempos

**Supuesto de la estimación: dos desarrolladores trabajando en paralelo.** Los rangos de esta tabla ya incorporan la compresión del ~30% que aporta el segundo recurso. El rango con un solo desarrollador se conserva en la última columna como referencia, para no perder la trazabilidad de dónde salió el número.

| Fase | Incluye | Tareas | Días hábiles (2 devs) | ID (BD) | *Ref. 1 dev* |
|---|---|---|---|---|---|
| **Fase 0 — Cimientos** | Esquema de BD (12 tablas), esqueleto del microservicio, roles y políticas, alta en KrakenD, rotación de credenciales expuestas | T-01 a T-05 | 6 – 8 días | | *8 – 12* |
| **Fase 1 — Registro y seguimiento manual (P1)** | Contratos de API, CRUD, bitácora y estatus, documentos en S3, export a Excel, listado y detalle en frontend | T-06 a T-13 | 10 – 14 días | | *15 – 20* |
| **Fase 2 — Ingesta automatizada (P2)** | Modelo canónico, 6 parsers por aseguradora, respaldo por LLM, worker de Gmail, orquestación, bandeja de revisión | T-14 a T-21 | 13 – 18 días | | *18 – 25* |
| **Fase 3 — Migración histórica (P3)** | Inventario de Drive, migración verificada a S3, vinculación a siniestros | T-22 a T-24 | 4 – 6 días | | *5 – 9* |
| **Fase 4 — BI, endurecimiento y despliegue** | Eventos de BI, seguridad y retención, pruebas de extremo a extremo, publicación de imágenes y despliegue a QA | T-25 a T-28 | 4 – 6 días | | *5 – 8* |
| **Total proyecto (P1+P2+P3)** | | 28 tareas | ~37 – 52 días hábiles (≈ 7.5 – 10.5 semanas) | — | *51 – 74* |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-13 | ~16 – 22 días hábiles (≈ 3 – 4.5 semanas) | — | *23 – 32* |

> **Notas sobre la tabla:**
> - **Mapeo con la numeración del PRD:** todo este plan corresponde a la **Fase 1 (MVP)** del PRD. Las Fases 2 y 3 del PRD (vínculo con pólizas, autoservicio) **no** están en este plan. Las fases numeradas arriba son fases *de ejecución* internas de este MVP, no las del PRD.
> - La Fase 3 tiene el rango más incierto de todos: su esfuerzo real depende del inventario de Drive (T-22), que aún no existe. Si el acervo resulta ser de decenas de miles de archivos, esta fase puede duplicarse.
> - Las estimaciones asumen **dos desarrolladores de tiempo completo** y que los prerequisitos bloqueantes se resuelven antes de que la fase correspondiente arranque. Con un solo desarrollador, aplicar la columna de referencia.
> - El paralelismo real está entre el frontend de la Fase 1 y los parsers de la Fase 2. Las Fases 0 y 4 son secuenciales por naturaleza: el segundo recurso aporta poco ahí, y por eso la compresión es del ~30% y no del 50%.

> **Riesgo de deadline:** el PRD **no tiene fecha límite comprometida** — la sección §14 lo declara explícitamente en fase de discovery, y deja abierta la definición de si el desarrollo es interno o con proveedor externo. Por lo tanto no hay un contraste posible contra días hábiles disponibles, y el riesgo no es de calendario sino de **prerequisitos**: el buzón compartido, el corpus de avisos reales y el dimensionamiento del acervo de Drive son los tres frenos reales del proyecto.
>
> Recomendación: **comprometer primero Fase 0 + Fase 1 (~16-22 días hábiles)**, que no dependen de ningún prerequisito externo y ya eliminan el Excel como sistema de registro. Arrancar la Fase 2 solo cuando el buzón esté aprovisionado y exista corpus de avisos por aseguradora.
>
> ⚠️ **Los tiempos comprometidos en la tabla asumen dos desarrolladores en paralelo.** Si el proyecto se asigna a una sola persona, el total vuelve a 51-74 días hábiles (≈ 10-15 semanas) y el guardarraíl a 23-32 días. Confirmar la asignación de recursos antes de comunicar fechas a negocio.

---

*Generado por Claude Code — Engine CX*
*Modelo: claude-opus-5 — esfuerzo: alto*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
