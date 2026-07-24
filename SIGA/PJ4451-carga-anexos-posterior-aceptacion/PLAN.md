# Plan de Desarrollo — Carga de anexos posterior a la aceptación (PJ4451)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ4451-carga-anexos-posterior-aceptacion/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb; DataAccess / DataAccessColombia) |
| Rama base | `develop` |
| Rama | `feature/PJ4451-carga-anexos-posterior-aceptacion` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ4451` |
| Fecha de generación | 2026-07-24 |
| Estado | Borrador |
| ID plan (BD) | 26 |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Habilitar la **carga de anexos** (`documento_averia`) en averías **aceptadas y no cerradas**, para roles de **operación/postventa** y **taller**, reutilizando S3 y el flujo Dropzone actual, con **validación server-side**, **trazabilidad (usuario)** y **notificación** a operación/analista.

- **Arquitectura:** modificación sobre monolito existente SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). No se crea microservicio ni API REST nueva.
- **Stack:** .NET 8 / C#, Razor + Dropzone (jQuery), PostgreSQL, S3 (`S3StorageService` / `Bucket_GP`), `IEmailSender`.
- **Alcance multi-país:** misma lógica en MEX / COL / CHL; cambios de entidad deben replicarse en `DataAccess` y `DataAccessColombia`.

**Hallazgo técnico (cierra preguntas abiertas del PRD §14 — estados / restricción / taller):**

| Pregunta PRD | Hallazgo en código |
|---|---|
| ¿Dónde está la restricción post-aceptación? | **Principalmente UI.** En `_Edit.cshtml` (~488–498), estatus `aceptada` solo ofrece docs de pago (Finiquito, cuenta bancaria, CSF, opinión) y **solo** a Agencia/Taller/Ejecutivo. Roles de operación (`Tecnico`, `Coordinador Tecnicos`, etc.) quedan con select vacío → no pueden cargar. |
| ¿El server bloquea post-aceptación? | **No.** `AddFiles` (~2097) solo exige `!cerrada`. No valida estatus, rol ni tipo. |
| ¿Nombres de “aceptada” y “cierre”? | Aceptación: `nombre_estatus` = `"aceptada"` (id típico **10**). Cierre: flag `averia.cerrada` (+ estatus con `cierra_averia`, p. ej. Cerrada id **5**). |
| ¿El taller carga en SIGA? | Sí: rol `Taller` / `Usuario Agencia` en `Averias/Edit` (mismo Dropzone). No hay portal aparte de anexos en `SeguimientoController` (ese es link público del beneficiario). |
| ¿Trazabilidad usuario? | `documento_averia` tiene `fecha` + `id_estatus` al cargar; **no tiene campo `usuario`**. Al eliminar sí se deja traza en `seguimiento_averia`. |
| ¿Notificación al cargar? | Parcial: taller → email al técnico asignado; docs de pago → `EmailPagos`. **No** hay aviso genérico “anexo post-aceptación → operación/analista”. |
| ¿Validación tipo/tamaño? | Solo cliente (Dropzone `maxFilesize: 15`, extensiones). Server: solo `Length > 0`. |

**Decisión de diseño (MVP):**

1. **Levantar la restricción UI** en estatus post-aceptación (como mínimo `aceptada`; también `taller` / `solucionada` si aplica al flujo) para permitir tipos de evidencia libre (`Evidencia`, `Varios`, u otros acordados) a operación y taller, **sin quitar** los docs de pago ya existentes en Aceptada.
2. **Endurecer `AddFiles`** (server-side): avería no cerrada; rol autorizado; tipo permitido según ventana post-aceptación; tipo MIME/extensión y tamaño máximo; mensajes claros en español.
3. **Trazabilidad:** agregar `usuario` (y opcionalmente `tamaño`) a `documento_averia` en MX y CO; mostrar en listado UI.
4. **Notificación:** canal dedicado (patrón similar a `NotifyUploadedFilesForPayment`) cuando la carga ocurra en ventana post-aceptación → destinatarios configurables (técnico asignado / operación / `EmailPagos` según acuerdo en T-02).
5. **Eventos BI:** log estructurado / traza en `seguimiento_averia` para `anexo_cargado_post_aceptacion` y `anexo_carga_rechazada` (sin infraestructura BI nueva).
6. **No** edición/borrado ampliado; **no** carga tras cierre; **no** rediseño del visor.

**Relación con PJ3931:** PJ3931 notifica al taller el **listado de documentos obligatorios** en cambios de estatus. PJ4451 habilita la **carga real de anexos** post-aceptación. Coordinar si ambas ramas tocan `_Edit.cshtml` / `AddFiles` en paralelo.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante (Operación / Postventa; revisión Aldo Álvarez — por confirmar en PRD)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] **Validar con operación** (T-02): roles exactos, tipos de anexo permitidos post-aceptación, tamaño máximo (¿15 MB Dropzone o 5 MB texto UI?), destinatarios de notificación, si video se mantiene
- [ ] Ambiente local con S3/config `FileStorage` y correo de prueba
- [ ] Coordinación con PJ3931 si ambas features se desarrollan en paralelo (mismo `_Edit.cshtml` / `AddFiles`)

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature sobre componente existente, sin servicio nuevo (`rules/infraestructura.md` — mantiene EC2; S3 existente).

```
[Usuario operación/taller en Averias/Edit]
  → UI: select tipo_documento (post-aceptación ampliado) + Dropzone
      → POST AddFiles(id, archivo, tipo_documento)
          → Validar: !cerrada, ventana post-aceptación, rol, tipo, MIME/tamaño
          → Disco local + S3 (esquema actual Documentos_Averias)
          → Create documento_averia (+ usuario, id_estatus, fecha)
          → Seguimiento / log evento anexo_cargado_post_aceptacion
          → Notificar operación/analista (si post-aceptación)
          → Si rechazo → mensaje + log anexo_carga_rechazada
```

**Ventana de carga (MVP):**

```
… → Aceptada (id≈10) → Taller → Solucionada → … → Cerrada (cerrada=true)
         └────────── carga anexos permitida ──────────┘
```

Criterio server: `!averia.cerrada` **y** el estatus actual es ≥ aceptación en el flujo (por nombre/`id_estatus` acordado en T-02; como mínimo incluir `aceptada` y no limitar solo a ella si el expediente sigue abierto en `taller`/`solucionada`).

---

## 4. Tareas de desarrollo

### Fase 0 — Alineación y rama (P1)

- [ ] **T-01** — Crear rama funcional desde `develop`
  - `feature/PJ4451-carga-anexos-posterior-aceptacion`
  - Criterio de completitud: rama en `origin` tracking `develop` actualizado

- [ ] **T-02** — Congelar reglas de negocio con operación
  - Roles Identity exactos (operación/postventa ↔ `Tecnico` / `Coordinador Tecnicos` / otros; taller ↔ `Taller` / `Usuario Agencia`)
  - Tipos de documento post-aceptación (¿mantener docs de pago + agregar `Evidencia`/`Varios`?)
  - Estatus incluidos en la ventana (¿solo `aceptada` o también `taller`/`solucionada`?)
  - Tamaño máximo y si video (mp4/mov) queda permitido
  - Destinatarios y canal de notificación (técnico asignado, lista fija, `EmailPagos`, etc.)
  - Criterio de completitud: decisiones anotadas en AVANCE / §12; sin “inventar” límites

### Fase 1 — UI + validación + persistencia (P1)

- [ ] **T-03** — Ampliar opciones de carga en `_Edit.cshtml` para ventana post-aceptación
  - Archivos: `GarantiplusWeb/Areas/Averias/Views/Averias/_Edit.cshtml` (~442–498)
  - Incluir tipos de anexo libre para roles autorizados en `aceptada` (y otros estatus acordados), sin eliminar opciones de pago existentes
  - Mensaje claro si avería cerrada / sin permiso (si el formulario sigue visible)
  - Criterio de completitud: operación y taller ven Dropzone usable en Aceptada (y estatus acordados) con tipos correctos

- [ ] **T-04** — Endurecer `AddFiles` (autorización, estado, tipo, tamaño/MIME)
  - Archivos: `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` (`AddFiles` ~2097–2175)
  - Rechazar: cerrada, rol no autorizado, tipo no permitido, extensión/MIME no permitidos, tamaño excedido
  - Respuestas con mensaje en español (Dropzone debe mostrar el error)
  - Criterio de completitud: POST directo no bypasea las reglas UI; casos de rechazo cubiertos

- [ ] **T-05** — Trazabilidad: campo `usuario` en `documento_averia` (+ UI listado)
  - Archivos: `DataAccess/Models/documento_averia.cs`, `DataAccessColombia/Models/documento_averia.cs`, mapeo DbContext MX/CO, script SQL / nota de migración, `AddFiles`, listado en `_Edit.cshtml` / `Details.cshtml`
  - Guardar `User.Identity.Name` (o id/email consistente con el resto de SIGA) al crear
  - Opcional MVP: columna `tamaño` (bytes) si operación lo pide en T-02
  - Criterio de completitud: cada anexo nuevo muestra quién y cuándo; `id_estatus` sigue registrándose

- [ ] **T-06** — Alinear Dropzone cliente con límites server
  - Archivos: `GarantiplusWeb/Areas/Averias/Views/Averias/Edit.cshtml` (Dropzone ~188–211)
  - Unificar `maxFilesize` / `acceptedFiles` con whitelist server; corregir inconsistencia 5 MB (texto) vs 15 MB (config)
  - Criterio de completitud: cliente y servidor rechazan lo mismo

### Fase 2 — Notificación, eventos y verificación (P1/P2)

- [ ] **T-07** — Notificación de carga post-aceptación
  - Extender/crear método junto a `NotifyUploadedFilesForPayment` (~2177) o en AveriasBusinessRules
  - Destinatarios desde config/`appsettings` (T-02); no romper emails actuales de docs de pago ni email taller→técnico
  - Fallo de correo **no** revierte la carga; log + traza
  - Criterio de completitud: al subir anexo post-aceptación llega aviso a destinatarios acordados

- [ ] **T-08** — Eventos / bitácora (`anexo_cargado_post_aceptacion`, `anexo_carga_rechazada`)
  - Insert en `seguimiento_averia` y/o log Serilog con campos: fecha, usuario, id_averia, estado, tipo, tamaño, motivo rechazo
  - Criterio de completitud: éxito y rechazo quedan consultables en expediente o logs

- [ ] **T-09** — Pruebas manuales (matriz)
  - Casos: pre-aceptación sin regresión; Aceptada operación carga Evidencia/Varios; Aceptada taller carga; docs de pago siguen; cerrada bloquea con mensaje; rol no autorizado rechaza; archivo inválido/grande rechaza; notificación enviada; listado muestra usuario/fecha/estatus
  - Verificar MEX; smoke COL/CHL si hay ambiente (misma lógica UI)
  - Criterio de completitud: checklist §10 marcado; evidencias en AVANCE

- [ ] **T-10** — Commit final de la feature en la rama funcional
  - Mensaje: `[PJ4451-carga-anexos-posterior-aceptacion] …`
  - Criterio de completitud: push a `origin` de la rama feature (sin crear PR — lo hace el programador)

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `documento_averia` | Modificación | Agregar columna `usuario` (texto/varchar, nullable para históricos). Opcional: `tamaño` (bigint). Replicar en esquemas MEX y COL. |
| `seguimiento_averia` | Sin cambio de esquema | Nuevos inserts de observación para eventos de carga/rechazo. |

> Script SQL a aplicar en ambientes (no hay migraciones EF formales en SIGA). Históricos quedan con `usuario` NULL.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `Averias/Averias/AddFiles?id={id}` | Validación reforzada + trazabilidad + notificación post-aceptación | Modificado |
| — | — | Sin API REST nueva en `gp_3.0_siga_api` | N/A |

---

## 7. Variables de entorno y configuración

| Variable / sección | Descripción | Ambiente |
|---|---|---|
| `FileStorage:*` / `Documentos_Averias` | Prefijo S3 existente (revisar alineación con `DocumentosAverias` en appsettings) | Ya existente |
| `ClaimPostAcceptanceAttachments` (nombre final en T-02/T-07) | Roles permitidos, tipos MIME/extensiones, max MB, destinatarios de notificación, estatus de la ventana | Desarrollo / QA / Producción |
| `EmailPagos` | Posible destinatario/fallback (ya usado en docs de pago) | Existente |

Secrets: ninguno nuevo. S3 y correo usan configuración vigente.

---

## 8. Consideraciones de seguridad

- Autorización **server-side** obligatoria (hoy el control fino es solo Razor → bypass por POST).
- Roles: mínimo privilegio; no ampliar delete (`DeleteFile` ya restringe Agencia).
- Archivos: whitelist de extensiones/MIME + tope de tamaño; no confiar solo en `ContentType` del cliente.
- S3: mismas políticas del bucket actual; no exponer URLs públicas nuevas.
- Logs: no volcar binarios ni PII innecesaria; sí id avería, usuario, tipo, motivo rechazo.
- Secrets de S3/SMTP fuera del código.

---

## 9. Consideraciones de infraestructura

- Sin servicios AWS nuevos. Despliegue habitual SIGA Web en EC2.
- S3: posible aumento de volumen por video; mitigar con límite de tamaño (T-02).
- Sin cambios ECS / Cloudflare / Route 53.
- Cambio de esquema PostgreSQL en BD de averías por país (script coordinado con TI).

---

## 10. Criterios de aceptación

- [ ] En avería **aceptada y no cerrada**, roles de operación/postventa y taller pueden adjuntar anexos (RF-01, RF-05).
- [ ] Se aceptan tipos acordados (JPG/PNG/PDF/Office/video según T-02); se rechazan el resto y los que excedan tamaño, con mensaje claro (RF-02, RF-07).
- [ ] El binario queda en S3 (esquema actual) y la referencia en `documento_averia` (RF-03).
- [ ] Cada carga registra usuario, fecha/hora y estatus de la avería; visibles en el detalle (RF-04, RF-08).
- [ ] Al cargar un anexo post-aceptación se notifica a los destinatarios acordados (RF-06).
- [ ] Avería **cerrada**: no permite carga; mensaje explicativo (RF-07).
- [ ] Docs de pago en Aceptada y flujos pre-aceptación **sin regresión**.
- [ ] Rechazos y cargas exitosas dejan traza/evento consultable (RNF-02, §11 PRD).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Conflicto de merge con PJ3931 en `_Edit.cshtml` / `AddFiles` | Media | Medio | Coordinar ramas; cambios UI mínimos y localizados |
| Roles “operación/postventa” no mapean 1:1 a Identity | Alta | Alto | Congelar lista en T-02 antes de codificar |
| Costo S3 por video sin tope | Media | Medio | Definir max MB; opcional deshabilitar video en MVP |
| Bypass actual de UI sin validación server | Alta (hoy) | Alto | T-04 obligatorio en P1 |
| Históricos sin `usuario` | Baja | Bajo | Columna nullable; solo nuevos registros |
| Doble correo (pago + anexo genérico) | Media | Bajo | Distinguir tipos: docs pago → flujo actual; anexos libres → nuevo |
| Prefijo S3 `Documentos_Averias` vs `DocumentosAverias` | Media | Bajo–Medio | No “arreglar” a ciegas; verificar en T-04/T-09 si keys quedan donde se esperan |

---

## 12. Notas para el programador

1. **El “Seguimiento de Averías” del PRD** = edición/detalle de averías (`Areas/Averias`), no el `SeguimientoController` público del beneficiario.
2. **Archivos clave:**
   - `GarantiplusWeb/Areas/Averias/Views/Averias/_Edit.cshtml` (~442–498)
   - `GarantiplusWeb/Areas/Averias/Views/Averias/Edit.cshtml` (Dropzone)
   - `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` — `AddFiles`, `NotifyUploadedFilesForPayment`, `Documentos`, `DeleteFile`
   - `DataAccess/Models/documento_averia.cs` (+ espejo Colombia + DbContext)
   - `Common/Storage/S3StorageService.cs` (sin cambio salvo bug de path)
3. **No refactorizar** AveriasController de forma amplia; cambios quirúrgicos en upload/UI/notificación.
4. Código nuevo en inglés; mensajes de usuario en español (`rules/coding-guidelines.md`). En SIGA legado, **respetar namespaces/estilo del archivo** que se edita (no normalizar el monolito).
5. El programador gestiona PRs (`feature` → `pre-qa` → `qa`); Claude no crea PRs.
6. Preguntas del PRD aún abiertas hasta T-02: límite exacto, video sí/no, destinatarios exactos, patrocinio/revisión Aldo.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Alineación y rama (P1)** | Rama feature + reglas con operación | T-01 a T-02 | 0.5 – 1.5 días | 46 |
| **Fase 1 — UI + validación + BD (P1)** | Vista, `AddFiles`, columna `usuario`, Dropzone | T-03 a T-06 | 2.5 – 4 días | 47 |
| **Fase 2 — Notificación, eventos y QA (P1/P2)** | Correo, bitácora, pruebas, commit | T-07 a T-10 | 1.5 – 2.5 días | 48 |
| **Total proyecto (P1+P2)** | | 10 tareas | **~4.5 – 8 días hábiles (≈ 1 – 1.5 semanas)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + notificación mínima (T-07) | T-01 a T-07 | **~3.5 – 6.5 días hábiles (≈ 1 semana)** | — |

> **Notas sobre la tabla:**
> - P1 = poder cargar con control (UI + server + trazabilidad + notificación básica).
> - P2 = eventos BI pulidos + matriz de pruebas completa + commit.
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite explícita. Con ~4.5–8 días hábiles el alcance es acotado. El cuello crítico es **T-02** (roles/límites/destinatarios): sin eso no se implementan reglas inventadas. Un segundo desarrollador aporta poca compresión (mismo cuello UI/controller); priorizar T-02 el día 1. Si hay conflicto con PJ3931, serializar merges en `_Edit.cshtml`.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
*
