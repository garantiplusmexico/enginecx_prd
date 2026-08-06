# Plan de Desarrollo — Administración de talleres y documentación obligatoria (PJ3746)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.
>
> **Actualización 2026-08-06:** se incorporan características adicionales no contempladas en el PRD v0.1
> (`actualizacion_plan_PJ3746-admon-talleres.txt`): módulo de administración post-alta, catálogo de documentos
> requeridos/opcionales, flujo de validación con correo a validadores, roles `taller-administracion` /
> `taller-averias`, almacenamiento dual (servidor + S3) y compuerta configurable al subir factura de avería.
>
> **Actualización 2026-08-06 (v0.2.1):** el alcance aplica a **todos los países** (México, Colombia y Chile),
> no solo a Colombia. El catálogo de documentos se seedéa / filtra por país.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ3746-admon-talleres/PRD.md` (+ addendum de alcance 2026-08-06) |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb); impacto secundario opcional en `gp_3.0_siga_api` (Claims / Workshops) |
| Rama base | `develop` |
| Rama | `feature/PJ3746-admon-talleres` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ3746` |
| Fecha de generación | 2026-07-24 |
| Fecha de actualización | 2026-08-06 |
| Estado | Aprobado (replanificado) |
| ID plan (BD) | 24 |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal (plan original); actualización por Cursor Grok |

---

## 1. Resumen técnico

Extender **SIGA Web** para que, tras el alta/aprobación de un taller (que ya crea el registro + usuario con rol `Taller`), exista un **módulo de administración del taller** donde el propio taller gestione su información administrativa y documentos, con un **flujo de validación** por usuarios internos configurables. Además, se refuerza la **documentación obligatoria** en el alta (alcance original del PRD) y se agrega una **compuerta configurable** al subir factura de avería si la información/documentos del taller no están validados.

- **Arquitectura:** modificación sobre monolito existente SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). No se crea microservicio nuevo. Almacenamiento **dual** (disco servidor + bucket S3), mismo patrón que contratos/documentos de averías (`FileStorage` + `DocumentosGenerados` / `IStorage`).
- **Stack:** .NET 8 / C#, Razor Views + jQuery, PostgreSQL, Amazon S3 + filesystem local.
- **País:** **México, Colombia y Chile** (alcance multi-país confirmado). Feature activo en los tres hubs; el **catálogo de documentos** (tipos requeridos/opcionales y etiquetas) varía por `HubBaseCountryCode` / país. Entidades EF nuevas con **paridad** en `DataAccess` (MX) y `DataAccessColombia` (COL); Chile según el DataAccess que use el build.
- **Base existente a extender:**
  - Auto-registro público: `HomeController.RegistroTalleres` + `Views/Home/RegistroTalleres.cshtml`
  - Aprobación → crea `taller` + Identity user rol `Taller` + `usuario_taller`: `Areas/Averias/Controllers/TalleresController.cs` (`Autorizar`)
  - Portal taller / averías: `AveriasController`, `TallerExternoController`, helpers `RoleGroupExtensions`
  - Cuenta bancaria: campos en `taller` (`banco`, `iban`/CLABE, `cuenta`, `sucursal`, …) + `GuardarDatosFiscalesBancariosTaller`
  - Carga de factura en avería: `_CerrarAveria.cshtml` / Edit avería (PDF+XML) — punto de inserción de la compuerta
  - Storage: `FileStorage:*`, `DocumentosGenerados:*`, `S3StorageService` / `IStorage`

**Alcance unificado (PRD + addendum):**

| Bloque | Qué cubre |
|---|---|
| A. Alta con docs | Exigir documentación (catálogo) en auto-registro / solicitud; no aprobar taller sin docs validados (PRD original) |
| B. Módulo administración | Pantalla post-alta para editar datos del taller + subir/reemplazar documentos; UI de estatus y faltantes |
| C. Catálogo documentos | Tabla que define qué documentos se piden (requerido/opcional); no hardcodear solo RUT/Cámara/brochure |
| D. Validación | Al subir/actualizar → estatus validación + email a validadores (settings, 1..N); auditoría de quién validó qué y cuándo; validador ve autor y fecha de carga |
| E. Roles | `Taller-Administracion` (admin + ver averías sin mutar) y `Taller-Averias` (crear/seguimiento averías, sin admin); el rol `Taller` actual mantiene/admin+averías según decisión Fase 0 |
| F. Compuerta factura | Si taller sin info/docs validados al subir factura de pago → bloquear y pedir completar administración; **flag en settings** |
| G. Storage dual | Guardar en servidor + bucket; `uri` en metadato; descarga con fallback servidor↔bucket y mensaje si no existe |

**Hallazgos de código que acotan el diseño:**

| Tema | Hallazgo |
|---|---|
| Alta aprobada | `TalleresController.Autorizar` ya crea `taller` + usuario Identity rol `"Taller"` + `usuario_taller` |
| ¿Carga documental hoy? | **No** en registro ni solicitud |
| Catálogo docs taller | **No existe** — crear `tipo_documento_taller` (catálogo) + `documento_taller` (instancias) |
| Descuentos pactados (PRD) | **No existen** como modelo; decidir si siguen en MVP o se modelan como tipo de documento/dato del catálogo |
| Storage contratos | Prefijo S3 (`FileStorage:Contratos`) + ruta local (`DocumentosGenerados:Contratos`) — replicar patrón para talleres |
| Roles taller | Hoy `"Taller"` y `"Usuario Distribuidor-Taller"`; nuevos roles Identity a crear y cablear en `[Authorize]` / menús |

---

## 2. Prerequisitos

- [ ] PRD validado por el solicitante / liderazgo (Alexis Herrera)
- [ ] **Addendum de alcance** (`actualizacion_plan_PJ3746-admon-talleres.txt`) aceptado; idealmente reflejado en una actualización del `PRD.md`
- [ ] Acceso a `gp_4.0_siga` (y a `gp_3.0_siga_api` si se incluye el canal API)
- [ ] Rama `develop` actualizada
- [ ] `CLAUDE.md` presente ✅
- [ ] Ambiente local: probar al menos un país; planificar smoke en MX, COL y CHL antes del cierre
- [ ] Bucket S3 + rutas locales `FileStorage` / `DocumentosGenerados` operativos **por ambiente/país**
- [ ] **Cerrar preguntas abiertas** (Fase 0 / §12), en especial **seed del catálogo por país**
- [ ] Confirmar si el canal API Claims/Workshops entra en MVP

---

## 3. Arquitectura del cambio

```
[Registro / Solicitud]
  → Carga docs según catálogo (requeridos)
  → S3 + filesystem + metadatos documento_taller (estatus Pendiente)
  → Aprobador autoriza solo si docs requeridos validados
  → Crea taller + usuario (rol Taller y/o roles nuevos)

[Usuario taller-administracion | Taller]
  → Módulo Administración del taller
       · Datos: nombre_taller, rfc, cp, municipio, colonia, direccion,
         telefonos, observaciones, clabe/iban, banco, sucursal, numero cuenta
       · Documentos: subir / reemplazar según catálogo
       · Dashboard: subidos | pendientes de validación | faltantes
  → Cualquier cambio de info/docs → estatus Validación + email a Validadores (settings)

[Usuario validador (settings)]
  → Bandeja de cambios pendientes
  → Ve: autor de carga/cambio + fecha/hora
  → Aprueba/rechaza documento o dato → guarda validador, qué se validó, fecha/hora

[Usuario taller-averias | Taller]
  → Averías: crear / seguimiento (como hoy)
  → Al subir factura de pago:
       si WorkshopAdmin:EnforceValidatedProfileOnInvoice = true
       y perfil/docs no validados → bloqueo + mensaje para completar administración

[Descarga documento]
  → Intentar servidor local → si no, bucket → si no, "documento no se encuentra"
```

**Decisiones de diseño (propuestas; validar en Fase 0):**

1. **`tipo_documento_taller`** (catálogo): `codigo`, `nombre`, `requerido` (bool), `activo`, `orden`, **`pais`** (`MEX` / `COL` / `CHL` o equivalente). Seed por país (p. ej. RUT/Cámara/Brochure en COL; RFC/Constancia/equivalentes en MX; RUT/equivalentes en CHL — cerrar lista en T-01).
2. **`documento_taller`** (instancias): FK `id_taller` y/o `id_solicitud`, FK `id_tipo_documento`, `uri`, `ruta_local` (opcional), `nombre_original`, `mime_type`, `fecha_carga`, `cargado_por`, `estatus_validacion`, `validado_por`, `fecha_validacion`, `motivo_rechazo`.
3. **Estatus del taller administrativo:** campo(s) en `taller` (p.ej. `estatus_administrativo`: `CompletoValidado` / `PendienteValidacion` / `Incompleto`) o cálculo derivado de docs requeridos + datos obligatorios.
4. **Auditoría de datos (no solo archivos):** al cambiar campos administrativos sensibles, registrar historial (quién, qué campo/bloque, cuándo) para que el validador vea el cambio; mínimo viable: bitácora por “envío a validación” + snapshot o diff de campos bancarios/fiscales.
5. **Validadores:** lista en `appsettings` (emails y/o userIds), p.ej. `WorkshopAdmin:ValidatorEmails` / `WorkshopAdmin:ValidatorUserIds` (1..N); puede diferir por ambiente/país.
6. **Compuerta factura:** `WorkshopAdmin:EnforceValidatedProfileOnInvoice` (bool, default `false` en primer deploy); configurable por ambiente/país.
7. **Roles Identity nuevos:**
   - `Taller-Administracion`: módulo admin (datos+docs); listado y detalle de averías **solo lectura** (sin crear/editar/acciones).
   - `Taller-Averias`: crear y dar seguimiento a averías; **sin** acceso al módulo admin.
   - Rol histórico `Taller`: definir en Fase 0 si sigue con acceso completo (admin+averías) o se migra.
8. **Vinculación 1 taller:** usuarios de estos roles siguen ligados vía `usuario_taller` (un solo taller).
9. **Storage:** nuevas claves `FileStorage:Documentos_Talleres` (prefijo S3) y ruta local espejo (p.ej. bajo `DocumentosGenerados` o `FileStorage:DocumentosTalleresLocal`); cada upload escribe ambos y persiste `uri` (key S3) + ruta relativa local.
10. **Feature activo en MX, COL y CHL** — no condicionar el módulo a un solo `CountryBase`; solo el contenido del catálogo y etiquetas de campos varían por país.
11. **Sin OCR / sin verificación externa** (fuera de alcance PRD).
12. **Sin regularización masiva retroactiva** de talleres ya activos (PRD); el módulo admin sí les permite completar docs de forma voluntaria; la compuerta de factura puede forzarlos si el flag está ON.

---

## 4. Tareas de desarrollo

### Fase 0 — Alineación funcional y modelo (P1)

- [ ] **T-01** — Cerrar preguntas abiertas (PRD §14 + addendum) con operación / solicitante
  - **Confirmado:** alcance MX + COL + CHL. Cerrar **seed del catálogo de documentos por país**.
  - Campos exactos editables en administración vs. solo lectura post-alta (homologar labels por país: RFC vs RUT, CLABE vs cuenta, etc.).
  - ¿Descuentos pactados del PRD siguen en MVP o se modelan como tipo de documento/dato del catálogo?
  - Reglas del análisis de cuenta bancaria (sistema vs. checklist manual del validador).
  - Comportamiento del rol histórico `Taller` vs. los dos roles nuevos (¿conviven? ¿migración?).
  - Nombres exactos de roles Identity (casing) y menús visibles.
  - Límite de tamaño por archivo (default técnico propuesto: 5 MB).
  - ¿Canal API Claims/Workshops en MVP?
  - ¿`RegistraTallerYAsigna` exige docs o queda exceptuado?
  - Default del flag `EnforceValidatedProfileOnInvoice` en QA/Prod (por país si aplica).
  - Archivos: actualizar §12 de este plan / `AVANCE.md`
  - Criterio de completitud: respuestas documentadas; sin bloqueos abiertos para Fase 1

- [ ] **T-02** — Crear / alinear rama funcional desde `develop`
  - `feature/PJ3746-admon-talleres` (renombrar/recrear si la rama anterior era solo “documentacion-obligatoria”)
  - Criterio de completitud: rama publicada en origin

- [ ] **T-03** — Diseñar esquema BD + script SQL
  - Tablas: `tipo_documento_taller`, `documento_taller`, bitácora de validación / cambios administrativos (nombre final en T-01)
  - Campos de estatus administrativo en `taller` si aplica
  - Completar mapeo EF de `datos_fiscales_bancarios_taller` en DataAccessColombia (y MX) si se usa
  - **Paridad obligatoria** de entidades nuevas en `DataAccess` y `DataAccessColombia` (Chile según DataAccess del build)
  - Seed SQL del catálogo para MEX, COL y CHL
  - Archivos: script `GarantiplusWeb/BD/…`, modelos EF, `garantiplus_dbContext`
  - Criterio de completitud: script ejecutable en BD de desarrollo de cada país; entidades compilables en ambos DataAccess

### Fase 1 — Persistencia, storage, catálogo y reglas (P1)

- [ ] **T-04** — Entidades EF + BR de catálogo e instancias de documentos
  - CRUD metadatos; estados `Pendiente` / `Aprobado` / `Rechazado`
  - Seed/consulta de tipos requerido/opcional
  - Archivos: `DataAccess*/Models/…`, BR en `AveriasBusinessRules` o librería dedicada
  - Criterio de completitud: crear/leer/actualizar documento y listar tipos activos por país

- [ ] **T-05** — Upload dual (filesystem + S3) y descarga con fallback
  - Reutilizar `IStorage` / `S3StorageService` + escritura local (patrón contratos)
  - Config: prefijo S3 + ruta base local en `appsettings`
  - Validar MIME/extensión (PDF, JPG, PNG) y tamaño
  - Descarga: local → S3 → mensaje “El documento no se encuentra”
  - Criterio de completitud: archivo de prueba en disco y bucket; metadato con `uri`; descarga OK; fallo controlado si falta en ambos

- [ ] **T-06** — Servicio de completitud / obligatoriedad
  - Regla: faltan tipos `requerido=true` sin archivo válido, o datos administrativos mínimos incompletos → incompleto
  - Usado en: envío de alta, envío a validación del módulo admin, guardarraíl de aprobación, compuerta de factura
  - Criterio de completitud: casos incompleto→bloqueo / completo→OK reutilizables desde controllers

- [ ] **T-07** — Notificación a validadores + auditoría de validación
  - Al subir/actualizar info o docs → estatus PendienteValidacion + email a lista de settings
  - Al validar: persistir `validado_por`, entidad/documento validado, `fecha_validacion`, motivo si rechazo
  - Exponer al validador: `cargado_por` / usuario del cambio + fecha/hora
  - Criterio de completitud: correo disparado en ambiente de prueba; auditoría visible en UI/API interna

### Fase 2 — Alta con documentación y bandeja de solicitud (P1)

- [ ] **T-08** — Extender auto-registro público `RegistroTalleres`
  - UI según catálogo del país del hub (requeridos/opcionales) + datos bancarios/fiscales reales (dejar de hardcodear `"SIN INFORMACION"` donde aplique)
  - POST multipart → storage dual + metadatos; validar obligatoriedad
  - Activo en MX, COL y CHL (catálogo/labels según país)
  - Archivos: `HomeController.cs`, `Views/Home/RegistroTalleres.cshtml`, BR
  - Criterio de completitud: no se crea solicitud sin docs requeridos del catálogo del país

- [ ] **T-09** — Extender bandeja / detalle de solicitud interna
  - Listar documentos, estatus, permitir carga/reemplazo; ver autor y fecha
  - Archivos: `TalleresController.cs`, vistas `Areas/Averias/Views/Talleres/*`
  - Criterio de completitud: operador/aprobador gestiona documentación de la solicitud

- [ ] **T-10** — Guardarraíl de `Autorizar` + creación de usuario/roles
  - No autorizar si docs requeridos incompletos o no validados
  - Mantener creación de `taller` + usuario; asignar rol(es) acordados en T-01 (`Taller` y/o nuevos)
  - Criterio de completitud: no existe taller activo sin documentación requerida validada (MX / COL / CHL)

- [ ] **T-11** — (Condicional) API Claims `Workshops` multipart
  - Solo si T-01 incluye API en MVP; si no, cancelar y anotar en §12
  - Criterio de completitud: misma regla de obligatoriedad o rechazo explícito en altas incompletas (todos los países)

### Fase 3 — Módulo de administración del taller (P1)

- [ ] **T-12** — Módulo nuevo “Administración del taller”
  - Pantalla(s) para editar: `nombre_taller`, `rfc`, `cp`, `municipio`, `colonia`, `direccion`, `telefonos`, `observaciones`, CLABE/`iban`, `banco`, `sucursal`, número de cuenta
  - Sección documentos: ya subidos + estatus validación + faltantes (requeridos/opcionales)
  - Guardar → marca validación pendiente + notifica validadores
  - Autorización: roles `Taller-Administracion` y, si aplica, `Taller` (no `Taller-Averias`)
  - Archivos: nuevo controller/vistas bajo `Areas/Averias` o `Areas/Catalogos` (decidir ubicación en T-01), menú lateral
  - Criterio de completitud: taller ve dashboard claro de completitud; cambio dispara correo y estatus

- [ ] **T-13** — Bandeja / detalle del validador
  - Listar talleres/cambios pendientes; detalle con datos + docs; autor y fecha de cada carga/cambio
  - Acciones aprobar/rechazar por documento (y por bloque de datos si se acordó)
  - Roles: validadores internos (no Auditor para mutaciones) según settings + roles SIGA existentes
  - Criterio de completitud: validación queda auditada; taller vuelve a ver estatus actualizado

### Fase 4 — Roles, compuerta de factura y actualización sensible (P1)

- [ ] **T-14** — Roles Identity `Taller-Administracion` y `Taller-Averias`
  - Crear roles en BD (script/seed); vincular usuarios a un solo taller (`usuario_taller`)
  - Ajustar `[Authorize]`, menús y `RoleGroupExtensions` / checks equivalentes
  - `Taller-Administracion`: admin sí; averías listado+detalle **sin** mutaciones
  - `Taller-Averias`: averías sí; admin **no**
  - Criterio de completitud: pruebas de acceso por rol (matriz permitidos/denegados)

- [ ] **T-15** — Compuerta al subir factura de avería (configurable)
  - En el flujo de carga de factura para pago: si flag ON y taller sin perfil/docs validados → bloquear con mensaje en español orientando al módulo admin
  - Settings: `WorkshopAdmin:EnforceValidatedProfileOnInvoice`
  - Archivos: `AveriasController` / parciales de cierre-factura, BR
  - Criterio de completitud: flag OFF = comportamiento actual; flag ON = bloqueo verificable

- [ ] **T-16** — Actualización de datos sensibles / cuenta bancaria con soporte
  - Extender `GuardarDatosFiscalesBancariosTaller` para exigir soporte documental del tipo correspondiente del catálogo y reentrar al flujo de validación
  - Criterio de completitud: update sin soporte → bloqueo; con soporte → histórico + metadato + pendiente de validación

### Fase 5 — Pruebas, hardening y cierre (P1)

- [ ] **T-17** — Pruebas end-to-end
  - Alta incompleta/completa; autorización bloqueada/OK; módulo admin; validación; descarga local/S3/missing; roles; factura con flag ON/OFF; formatos inválidos; archivo > límite
  - Criterio de completitud: checklist §10 pasado a fondo en al menos un país; catálogo correcto verificado para MX, COL y CHL

- [ ] **T-18** — UX/mensajes y regresión multi-país / multi-rol
  - Mensajes en español claros (faltantes, rechazo, documento no encontrado, compuerta factura); labels según país
  - Smoke en MX, COL y CHL (registro/admin/roles) sin regresiones obvias
  - Criterio de completitud: los tres países cumplen RF del feature; roles OK

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `tipo_documento_taller` | **Nueva** | Catálogo: nombre/código, requerido/opcional, activo, orden, **`pais`** (MEX/COL/CHL) |
| `documento_taller` | **Nueva** | Instancias: uri S3, ruta local, mime, fechas, `cargado_por`, estatus, `validado_por`, `fecha_validacion`, motivo rechazo; FK taller y/o solicitud + tipo |
| `bitacora_validacion_taller` *(o equivalente)* | **Nueva / a confirmar** | Quién validó qué (documento o bloque de datos), cuándo, resultado |
| `taller` / `registro_taller` | Posible extensión | `estatus_administrativo` u homologable; dejar de aceptar vacíos bancarios en alta (todos los países) |
| `aspnetroles` / asignaciones | **Datos** | Roles `Taller-Administracion`, `Taller-Averias` |
| `datos_fiscales_bancarios_taller` | Mapeo EF COL si aplica | Completar DbSet si el país lo usa |
| `descuento_taller` | **Condicional** | Solo si T-01 mantiene descuentos pactados del PRD como dato estructurado |

Script SQL versionado bajo `GarantiplusWeb/BD/` con fecha. Sin regularización masiva de históricos.

---

## 6. Endpoints nuevos o modificados

SIGA Web es MVC (no API REST primaria). Acciones relevantes:

| Método | Ruta / acción | Descripción | Estado |
|---|---|---|---|
| GET/POST | `~/Home/RegistroTalleres` | Alta pública + multipart docs (catálogo) | Modificado |
| GET/POST | `~/Averias/Talleres/Solicitud/{id}` | Revisión/carga/validación docs de solicitud | Modificado |
| POST | `~/Averias/Talleres/Autorizar` | Guardarraíl docs + roles al crear usuario | Modificado |
| GET/POST | `~/Averias/TallerAdmin/…` *(nombre final T-01)* | Módulo administración del taller | **Nuevo** |
| POST | `~/Averias/TallerAdmin/UploadDocumento` | Upload dual + metadato | **Nuevo** |
| GET | `~/Averias/TallerAdmin/DownloadDocumento/{id}` | Descarga local→S3→error | **Nuevo** |
| POST | `~/Averias/TallerAdmin/Validar…` | Aprobar/rechazar doc o bloque (validador) | **Nuevo** |
| POST | `~/Averias/Averias/GuardarDatosFiscalesBancariosTaller` | Update bancario + soporte + validación | Modificado |
| POST | Carga factura avería (cerrar/editar) | Compuerta si perfil no validado | Modificado |
| POST *(condicional)* | `Claims` `api/Workshops/...` | Multipart docs si entra en MVP | Condicional |

---

## 7. Variables de entorno y configuración

| Variable / clave | Descripción | Ambiente |
|---|---|---|
| `FileStorage:BucketName` / `Key` / `Secret` / `Region` | Ya existentes — no hardcodear secrets | Dev / QA / Prod |
| `FileStorage:Documentos_Talleres` *(nueva)* | Prefijo S3 p.ej. `talleres/documentos/` | Dev / QA / Prod |
| `FileStorage:DocumentosTalleresLocal` o `DocumentosGenerados:DocumentosTalleres` *(nueva)* | Ruta base en servidor | Dev / QA / Prod |
| `WorkshopAdmin:ValidatorEmails` *(nueva)* | Lista 1..N de correos a notificar | Dev / QA / Prod |
| `WorkshopAdmin:ValidatorUserIds` *(opcional)* | Ids de usuarios validadores | Dev / QA / Prod |
| `WorkshopAdmin:EnforceValidatedProfileOnInvoice` *(nueva)* | Compuerta al subir factura (`true`/`false`) | Dev / QA / Prod |
| `WorkshopDocuments:MaxFileSizeMb` *(opcional)* | Tope de tamaño (default 5) | Dev / QA / Prod |
| `WorkshopDocuments:AllowedContentTypes` *(opcional)* | pdf / jpeg / png | Dev / QA / Prod |
| `Hub:HubBaseCountryCode` | País del ambiente bajo prueba | Local |

Secrets: seguir Secrets Manager / config existente; **no** commitear claves.

---

## 8. Consideraciones de seguridad

- Autorización por roles: `Taller-Administracion` / `Taller-Averias` / `Taller` / roles internos de validación; Auditor solo lectura.
- Usuario de taller solo ve/edita **su** taller (`usuario_taller`).
- Validadores solo mutan estatus de validación; no impersonar carga del taller.
- Datos bancarios: sin cifrado adicional en MVP (riesgo aceptado en PRD); restringir quién ve Details.
- Validar extensión/MIME y tamaño en servidor.
- URIs S3 privadas + descarga autorizada; no buckets públicos.
- No loguear números de cuenta completos ni archivos en base64.
- La lista de validadores vive en settings (sin hardcode en controllers).

---

## 9. Consideraciones de infraestructura

- Sin servicio ECS nuevo: sigue SIGA Web en EC2.
- S3 + disco local: nuevo prefijo y carpeta; costo acotado por límite de tamaño.
- RDS: 2–3 tablas nuevas; impacto bajo.
- IAM: verificar que el rol/instancia pueda escribir el nuevo prefijo S3.
- Correo: reutilizar `IEmailSender` existente (Gmail/MS365 según país).

---

## 10. Criterios de aceptación

- [ ] Tras aprobar una solicitud, se crea taller + usuario (comportamiento actual) y el usuario puede acceder según rol asignado
- [ ] Existe módulo de administración del taller con los campos administrativos listados en el addendum
- [ ] Existe catálogo de documentos (requerido/opcional); el taller sube conforme al catálogo
- [ ] Al subir/actualizar información o documentos, el taller queda en estatus de validación y se notifica por correo a los validadores configurados
- [ ] Al validar se guarda quién validó, qué validó y cuándo
- [ ] El validador ve quién subió/cambió y la fecha/hora del cambio
- [ ] UI del taller muestra claramente: documentos subidos, estatus de validación y faltantes (docs e información)
- [ ] Archivos en **servidor + bucket**; metadato con `uri`; descarga con fallback; mensaje si no existe en ninguno
- [ ] Rol `Taller-Administracion`: admin + ver averías sin actuar sobre ellas
- [ ] Rol `Taller-Averias`: crear/seguimiento de averías; sin acceso a administración
- [ ] Con `EnforceValidatedProfileOnInvoice=true`, no se puede subir factura de pago si el taller no tiene información/documentos validados; con `false`, no bloquea
- [ ] En **MX, COL y CHL**, no se aprueba/activa taller nuevo sin documentación requerida validada (principio del PRD)
- [ ] Formatos PDF/JPG/PNG; rechazo claro si inválido o excede tamaño
- [ ] Talleres históricos no se obligan a regularizar en masa; la compuerta de factura puede forzarlos si el flag está activo
- [ ] Preguntas abiertas de Fase 0 cerradas y reflejadas en código/config

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Seed de catálogo incompleto o incorrecto por país (MX/COL/CHL) | Alta | Alto | Cerrar lista exacta de docs por país en T-01; smoke de alta en los tres hubs |
| Rol `Taller` legacy vs roles nuevos rompe menús/autorizaciones | Alta | Alto | Matriz de permisos en T-14; smoke de portal taller |
| Reglas de análisis bancario indefinidas | Alta | Medio | Checklist manual del validador + archivo soporte si no hay reglas de sistema |
| Dual storage inconsistente (local vs S3) | Media | Alto | Escribir ambos en la misma operación; descarga con fallback; no validar si falta archivo |
| Compuerta factura bloquea operación real si flag ON prematuro | Media | Alto | Default OFF; activar por ambiente tras talleres piloto |
| Canal API Workshops bypasea docs | Media | Medio | Decidir en T-01 incluir o bloquear |
| `RegistraTallerYAsigna` bypasea docs | Media | Medio | Excepción documentada o exigir docs |
| Catálogo mal seedado (requeridos incorrectos) | Media | Medio | Seed revisado por operación; UI admin de catálogo puede diferirse |
| Secrets `FileStorage` en appsettings locales | Media | Medio | No rotar/duplicar en este plan |

---

## 12. Notas para el programador

1. **Fuente de verdad del alcance ampliado:** PRD v0.2.1 + addendum. Alcance **multi-país** (MX, COL, CHL).
2. **País base al desarrollar:** el feature debe funcionar en los tres; usar skill `siga-cambio-pais-base` para rotar el ambiente local y validar catálogo/labels por país.
3. **No refactorizar** Identity / menús / `AveriasController` más allá de lo necesario para roles y la compuerta.
4. **Create interno** de taller sigue comentado: priorizar bandeja `registro_taller` + registro público + módulo admin post-alta.
5. **Paridad DataAccess MX/COL (obligatoria):** replicar entidades nuevas en ambos contextos; Chile según el DataAccess del build. Scripts SQL en las tres BDs.
6. **Fuera de alcance confirmado (PRD):** OCR, verificación contra fuentes oficiales, vencimiento/renovación automática, validación bancaria externa, regularización masiva.
7. Pendiente de T-01 (dejar respuestas aquí al cerrar Fase 0):
   - Países MVP = **MX + COL + CHL** (confirmado)
   - Seed catálogo documentos (por país) =
   - Descuentos pactados en MVP = sí/no / cómo
   - Análisis cuenta bancaria =
   - Rol `Taller` legacy =
   - Nombres exactos roles Identity =
   - Max file size =
   - API Workshops en MVP = sí/no
   - `RegistraTallerYAsigna` =
   - Default `EnforceValidatedProfileOnInvoice` =

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Alineación y modelo (P1)** | Preguntas abiertas, rama, script BD + EF | T-01 a T-03 | 2 – 3 días | 38 |
| **Fase 1 — Persistencia, storage y reglas (P1)** | Catálogo, docs, dual storage, completitud, notificaciones/auditoría | T-04 a T-07 | 4 – 5 días | 39 |
| **Fase 2 — Alta y solicitud (P1)** | Registro público, bandeja, Autorizar+roles, API condicional | T-08 a T-11 | 3 – 5 días | 40 |
| **Fase 3 — Módulo administración (P1)** | UI taller + bandeja validador | T-12 a T-13 | 4 – 5 días | 41 |
| **Fase 4 — Roles, factura y bancarios (P1)** | Roles nuevos, compuerta factura, update sensible | T-14 a T-16 | 3 – 4 días | 42 |
| **Fase 5 — Pruebas y cierre (P1)** | E2E, UX, regresión | T-17 a T-18 | 2 – 3 días | 81 |
| **Total proyecto (alcance PRD + addendum)** | | 18 tareas | **~18 – 25 días hábiles (≈ 4 – 5 semanas)** | — |
| **Solo P1 mínimo (guardarraíl)** | Catálogo+storage+alta+Autorizar+módulo admin básico+validación (T-01…T-07, T-08…T-10, T-12…T-13) | — | **~14 – 18 días hábiles** | — |

> **Notas:** el alcance dejó de ser “solo docs en el alta”. El addendum agrega ~1–1.5 semanas. T-11 puede cancelarse si el API queda fuera (~1–2 días menos). Fases re-sincronizadas en BD (plan id 24, días=25; fase nueva id 81).

> **Riesgo de deadline:** el PRD **no define fecha límite**. Con un desarrollador a tiempo completo, el alcance completo encaja en ~4–5 semanas hábiles. Si hubiera presión &lt; 15 días: priorizar esquema + storage + módulo admin + validación + guardarraíl `Autorizar` (T-03…T-07, T-10, T-12…T-13); diferir API (T-11), roles granulares finos (dejar solo `Taller` + admin) y activar la compuerta de factura después. Un segundo desarrollador (UI admin vs. BR/storage/roles) comprimiría ~30–40% el calendario.

---

## 14. Mapeo addendum → tareas

| # | Característica (addendum) | Tareas |
|---|---|---|
| 1 | Alta aprobada crea taller + usuario rol Taller | T-10 (existente; se mantiene/extiende) |
| 2 | Usuario ve admin + averías como hoy; se habilita admin | T-12, T-14 |
| 3 | Módulo nuevo con datos administrativos del taller | T-12 |
| 4 | Tabla catálogo documentos requerido/opcional | T-03, T-04 |
| 5 | Cambio → estatus validación + correo a validadores (settings) | T-07, T-12 |
| 6 | Auditoría de validación (quién, qué, cuándo) | T-07, T-13 |
| 7 | Validador ve autor y fecha de carga/cambio | T-07, T-13 |
| 8 | Compuerta factura si no validado (configurable) | T-15 |
| 9 | Guardar en servidor + bucket; uri; ruta base en settings | T-05 |
| 10 | Descarga local/bucket o “no se encuentra” | T-05 |
| 11 | UI: subidos, estatus, faltantes | T-12 |
| 12 | Roles `Taller-Administracion` y `Taller-Averias` | T-14 |

---

*Generado por Claude Code — Engine CX*
*Actualizado para incorporar addendum de alcance — 2026-08-06*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Rama base: `develop`*
