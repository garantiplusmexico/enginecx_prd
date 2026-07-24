# Plan de Desarrollo — Documentación obligatoria en el registro de talleres (PJ3746)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ3746-admon-talleres/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb); impacto secundario opcional en `gp_3.0_siga_api` (Claims / Workshops) |
| Rama base | `develop` |
| Rama | `feature/PJ3746-admon-talleres-documentacion-obligatoria` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ3746` |
| Fecha de generación | 2026-07-24 |
| Estado | Borrador |
| ID plan (BD) | 24 |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Agregar a **SIGA Web (Colombia)** la exigencia de **documentación obligatoria** en el alta y en la actualización de datos sensibles de talleres: RUT, Cámara de Comercio, brochure (archivos), descuentos pactados y cuenta bancaria (datos estructurados + archivo de soporte). Incluye validación de obligatoriedad al enviar, almacenamiento en S3 + metadatos en PostgreSQL, y flujo de revisión/aprobación/rechazo por el aprobador.

- **Arquitectura:** modificación sobre monolito existente SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). No se crea microservicio nuevo. Se reutiliza `IStorage` / `S3StorageService` y el patrón de metadatos de `documento_averia` / `documento_distribuidor`.
- **Stack:** .NET 8 / C#, Razor Views + jQuery, PostgreSQL (RDS Colombia), Amazon S3.
- **País:** **Garantiplus Colombia** (`CountryBase=COLOMBIA` / `HubBaseCountryCode=COL`). La UI y validaciones nuevas se condicionan a Colombia; no se exige documentación retroactiva a talleres ya activos.
- **Base existente a extender:**
  - Auto-registro público: `HomeController.RegistroTalleres` + `Views/Home/RegistroTalleres.cshtml`
  - Solicitudes / aprobación: `Areas/Averias/Controllers/TalleresController.cs` + vistas `Solicitudes` / `Solicitud` / `DetailsSolicitud`
  - Cuenta bancaria operativa: campos en `taller` + `GuardarDatosFiscalesBancariosTaller` (hoy sin archivo de soporte; histórico `datos_fiscales_bancarios_taller` mapeado en MX, **sin DbSet en COL**)
  - API pública paralela (landings): `gp_3.0_siga_api` → `Claims/WorkshopsController` (crear `registro_taller` anónimo; **sin documentos**)

**Hallazgos que cierran / acotan el PRD:**

| Tema PRD | Hallazgo en código |
|---|---|
| ¿Existe carga documental hoy? | **No.** Ni en registro público ni en solicitud/aprobación. |
| ¿“Solicitud interna”? | Bandeja `Averias/Talleres/Solicitudes` sobre `registro_taller`. El Create interno de taller está **deshabilitado**; alta ad-hoc desde avería: `RegistraTallerYAsigna` (también sin docs). |
| Cuenta bancaria | Campos `banco`, `iban` (CLABE), `cuenta`, `sucursal`, `digito` en `taller` / `registro_taller`. En alta pública se hardcodean a `"SIN INFORMACION"`. |
| Descuentos pactados | **No existen** (solo `taller.mano_obra` como tarifa). Hay que diseñar modelo + UI desde cero. |
| Tabla documentos de taller | **No existe.** Crear `documento_taller` (metadatos) + prefijo S3 nuevo. |
| Análisis cuenta bancaria | Pregunta abierta del PRD: reglas exactas **pendientes**. Fase 0 debe cerrarlas con operación antes de codificar la lógica de “análisis”. |

---

## 2. Prerequisitos

- [ ] PRD validado por el solicitante / liderazgo (Alexis Herrera)
- [ ] Acceso a `gp_4.0_siga` (y a `gp_3.0_siga_api` si se incluye el canal API)
- [ ] Rama `develop` actualizada ✅ (al generar este plan: up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente ✅
- [ ] Ambiente local con **país Colombia** (`CountryBase=COLOMBIA`, conexión BD COL, `HubBaseCountryCode=COL`)
- [ ] Bucket S3 / credenciales `FileStorage` operativos en el ambiente (ya usados por averías)
- [ ] **Cerrar preguntas abiertas del PRD §14** (Fase 0) antes de implementar validaciones de negocio del análisis bancario y campos exactos de descuentos
- [ ] Confirmar si el canal API Claims/Workshops debe exigir docs en el MVP o solo SIGA Web

---

## 3. Arquitectura del cambio

Se respeta el monolito SIGA Web (`rules/arquitectura.md`): feature sobre componentes existentes; despliegue sigue en EC2. Archivos → S3; metadatos → PostgreSQL Colombia.

```
[Taller / Operador]
  → Auto-registro (Home/RegistroTalleres)
     o Solicitud / edición interna (Averias/Talleres)
  → Validación obligatoriedad (docs + datos)
  → Upload archivos → IStorage/S3 (prefijo Documentos_Talleres)
  → Metadatos → PostgreSQL.documento_taller (+ campos estructurados)
  → Bandeja aprobador (Talleres/Solicitudes | Details)
  → Revisar docs + validar cuenta bancaria → Aprobar / Rechazar
  → Taller activo solo si documentación completa y validada
```

**Decisiones de diseño (propuestas; validar en Fase 0):**

1. **Nueva tabla `documento_taller`** (no reutilizar `documento_averia`): FK a `registro_taller` y/o `taller`, `tipo_documento`, `uri` (key S3), `nombre_original`, `mime_type`, `fecha_carga`, `cargado_por`, `estatus_validacion`, `aprobado_por`, `fecha_aprobacion`, `motivo_rechazo`.
2. **Tipos de documento (constantes):** `RUT`, `CAMARA_COMERCIO`, `BROCHURE`, `DESCUENTOS_PACTADOS`, `CUENTA_BANCARIA`.
3. **Descuentos pactados:** columnas estructuradas nuevas (tabla `descuento_taller` o campos JSON/columnas en `registro_taller`/`taller` — decidir en T-01) + archivo de soporte obligatorio del tipo `DESCUENTOS_PACTADOS`.
4. **Cuenta bancaria:** reutilizar campos existentes; dejar de hardcodear `"SIN INFORMACION"` en COL; exigir captura real + archivo soporte; al actualizar vía `GuardarDatosFiscalesBancariosTaller` (y pantalla Details/Edit) exigir soporte y registrar análisis según reglas cerradas en Fase 0.
5. **Guardarraíl de aprobación:** `Autorizar` en `TalleresController` debe fallar si falta algún tipo obligatorio o si algún documento no está en estatus aprobado/validado.
6. **Alcance país:** validaciones y UI nuevas activas solo cuando el hub/país es Colombia; MX/CHL no cambian comportamiento salvo espejo de entidad EF si se decide paridad de esquema.
7. **API Claims/Workshops:** si se incluye en MVP, multipart + mismas validaciones; si no, documentar como fuera de alcance inmediato y bloquear o advertir altas COL sin docs vía API.
8. **Sin OCR ni verificación externa** (fuera de alcance del PRD).
9. **Sin regularización retroactiva** de talleres ya activos.

---

## 4. Tareas de desarrollo

### Fase 0 — Alineación funcional y modelo (P1)

- [ ] **T-01** — Cerrar preguntas abiertas del PRD (§14) con operación / solicitante
  - Reglas exactas del **análisis de cuenta bancaria** (qué valida el aprobador vs. qué valida el sistema).
  - Campos exactos de **descuentos pactados** y **cuenta bancaria** (banco, tipo cuenta, número, titular, % descuento, vigencia, etc.).
  - **Límite de tamaño** por archivo (propuesta técnica default: 5 MB si operación no define otro).
  - Notificaciones de aprobado/rechazado (hoy rechazo de solicitud ya envía email; ¿extender a docs?).
  - ¿Canal API Claims/Workshops entra en MVP?
  - ¿`RegistraTallerYAsigna` (alta ad-hoc en avería) debe exigir docs en COL o quedar exceptuado?
  - Archivos: actualizar §12 de este plan / `AVANCE.md`
  - Criterio de completitud: respuestas documentadas; sin bloqueos abiertos para Fase 1

- [ ] **T-02** — Crear rama funcional desde `develop`
  - `feature/PJ3746-admon-talleres-documentacion-obligatoria`
  - Criterio de completitud: rama publicada en origin

- [ ] **T-03** — Diseñar esquema BD + script SQL Colombia
  - Tabla `documento_taller` (+ índices por `id_taller` / `id_solicitud` / `tipo_documento`)
  - Estructura de descuentos pactados acordada en T-01
  - Completar mapeo EF de `datos_fiscales_bancarios_taller` en **DataAccessColombia** (hoy TODO sin DbSet)
  - Archivos: script bajo `GarantiplusWeb/BD/…`, modelos en `DataAccessColombia` (y espejo en `DataAccess` si se decide paridad), `garantiplus_dbContext`
  - Criterio de completitud: script ejecutable en BD COL de desarrollo; entidades compilables

### Fase 1 — Persistencia, storage y reglas de obligatoriedad (P1)

- [ ] **T-04** — Entidades EF + repositorio/BR de documentos de taller
  - CRUD de metadatos; constantes de tipos; estados de validación (`Pendiente`, `Aprobado`, `Rechazado`)
  - Archivos: `DataAccessColombia/Models/documento_taller.cs` (+ espejo si aplica), BR nueva o parcial en `AveriasBusinessRules` / `CatalogosBusinessRules`
  - Criterio de completitud: se puede crear/leer/actualizar estatus de un documento por taller/solicitud en código

- [ ] **T-05** — Upload a S3 con prefijo de talleres
  - Reutilizar `IStorage` / `S3StorageService`
  - Config: clave `FileStorage:Documentos_Talleres` (o equivalente) en `appsettings`
  - Validar MIME/extensión: PDF, JPG, PNG; tamaño máximo (T-01)
  - Manejo de error controlado (archivo inválido / fallo S3) con mensaje en español
  - Archivos: BR/servicio de upload, `appsettings*.json` (sin secrets nuevos hardcodeados)
  - Criterio de completitud: archivo de prueba queda en S3 y metadato en BD con `uri` válida

- [ ] **T-06** — Servicio de validación de obligatoriedad
  - Regla única: no enviar / no aprobar si falta RUT, Cámara, brochure, descuentos (dato+archivo) o cuenta bancaria (dato+archivo)
  - Aplicable a alta (`registro_taller`) y a actualización de datos sensibles
  - Archivos: clase de dominio/BR reutilizable desde controllers Web (y API si aplica)
  - Criterio de completitud: tests manuales / casos: incompleto → bloqueo; completo → OK

### Fase 2 — Canales de captura (auto-registro + solicitud interna) (P1)

- [ ] **T-07** — Extender auto-registro público `RegistroTalleres`
  - UI: inputs de archivos + formulario de descuentos + datos bancarios reales (dejar de hardcodear banco)
  - POST multipart: subir a S3, guardar metadatos ligados a `id_solicitud`, validar obligatoriedad antes de confirmar
  - Condicionar a Colombia si la misma vista sirve multi-país
  - Archivos: `HomeController.cs`, `Views/Home/RegistroTalleres.cshtml`, BR
  - Criterio de completitud: no se crea solicitud COL sin los 5 elementos; archivos visibles luego en bandeja

- [ ] **T-08** — Extender bandeja / detalle de solicitud interna
  - En `Solicitud` / `DetailsSolicitud`: listar documentos, permitir carga/reemplazo si aplica, ver estatus
  - Si Create interno se rehabilita o hay captura por operador: mismos campos obligatorios
  - Archivos: `TalleresController.cs`, vistas `Areas/Averias/Views/Talleres/*`
  - Criterio de completitud: operador/aprobador ve y gestiona la documentación de la solicitud

- [ ] **T-09** — (Condicional) API Claims `Workshops` multipart
  - Solo si T-01 incluye el canal API en MVP
  - Extender `CreateWorkshopRequest` / `WorkshopsService` para docs + validación; o rechazar altas COL incompletas
  - Archivos en `gp_3.0_siga_api/Services/Claims/…`
  - Criterio de completitud: contrato documentado en Swagger; misma regla de obligatoriedad que Web
  - Si queda fuera de alcance: marcar tarea cancelada y dejar nota en §12

### Fase 3 — Aprobación, análisis bancario y actualización sensible (P1)

- [ ] **T-10** — Flujo de aprobación/rechazo con revisión documental
  - UI aprobador: revisar cada documento, marcar aprobado/rechazado con motivo, validar cuenta bancaria según reglas T-01
  - `Autorizar`: bloqueado si documentación incompleta o no validada (RF-07)
  - `Rechazar`: motivo + trazabilidad (usuario, fecha); email existente se mantiene/extiende
  - Roles: reutilizar los de autorización actuales (sin Auditor para mutaciones) salvo que T-01 defina rol “Aprobador de talleres” específico
  - Archivos: `TalleresController.cs`, vistas Solicitud/Details, BR
  - Criterio de completitud: no se crea `taller` activo sin docs validados; rechazo queda auditado

- [ ] **T-11** — Actualización de cuenta bancaria / datos sensibles con soporte
  - Extender `GuardarDatosFiscalesBancariosTaller` + `_DatosFiscalesBancariosTaller.cshtml` (COL): exigir archivo soporte; persistir histórico en COL (DbSet)
  - Aplicar “análisis” acordado (validaciones de formato / checklist del aprobador / ambos)
  - Archivos: `AveriasController.cs`, `AveriasBusinessRules.cs`, vista parcial, EF COL
  - Criterio de completitud: update bancario COL sin archivo → bloqueo; con archivo → histórico + metadato

- [ ] **T-12** — Trazabilidad y permisos (RNF-01, RNF-02, RF-10)
  - Registrar quién cargó / quién aprobó-rechazó / motivo / timestamps
  - Taller (rol) solo ve/carga lo suyo; aprobador ve todos los de la solicitud/taller
  - Criterio de completitud: auditoría visible en Details; 403 en acciones no autorizadas

### Fase 4 — Pruebas, hardening y cierre (P1)

- [ ] **T-13** — Pruebas end-to-end Colombia
  - Casos: alta pública incompleta/completa; aprobación con doc rechazado; aprobación OK → taller activo; update bancario con/sin soporte; formatos inválidos; archivo > límite
  - Verificar consistencia S3 ↔ BD (uri existe)
  - Criterio de completitud: checklist §10 pasado en ambiente COL

- [ ] **T-14** — Ajustes UX/mensajes y regresión multi-país
  - Mensajes de error en español claros
  - Verificar que MX/CHL no exigen la nueva documentación (salvo decisión contraria)
  - Criterio de completitud: smoke registro/aprobación MX sin regresiones obvias; COL cumple RF

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `documento_taller` | **Nueva** | Metadatos de documentos (tipo, uri S3, mime, fechas, usuarios, estatus, motivo rechazo); FK a `registro_taller` y/o `taller` |
| `descuento_taller` *(o columnas en taller/registro)* | **Nueva / a confirmar en T-01** | Datos estructurados de descuentos pactados |
| `taller` / `registro_taller` | Posible extensión | Campos adicionales de descuentos/bancarios si no van en tabla aparte; dejar de aceptar vacíos en COL en alta |
| `datos_fiscales_bancarios_taller` | **Mapeo EF COL** | Ya existe modelo con TODO; agregar DbSet + `ToTable` en `DataAccessColombia` |

Script SQL versionado bajo `GarantiplusWeb/BD/` con fecha. Ejecutar en BD Colombia (dev → QA → prod). Sin regularización de talleres históricos.

---

## 6. Endpoints nuevos o modificados

SIGA Web es MVC (no API REST primaria). Acciones relevantes:

| Método | Ruta / acción | Descripción | Estado |
|---|---|---|---|
| GET/POST | `~/Home/RegistroTalleres` | Alta pública + multipart documentos | Modificado |
| GET | `~/Averias/Talleres/Solicitudes` | Bandeja | Sin cambio funcional mayor |
| GET/POST | `~/Averias/Talleres/Solicitud/{id}` | Revisión, carga, aprobar/rechazar docs + taller | Modificado |
| POST | `~/Averias/Averias/GuardarDatosFiscalesBancariosTaller` | Update bancario + soporte | Modificado |
| POST *(nuevo)* | p.ej. `~/Averias/Talleres/UploadDocumento` / `ValidarDocumento` | Upload y cambio de estatus documental | Nuevo |
| POST *(condicional)* | `Claims` `api/Workshops/...` create | Multipart docs si entra en MVP | Modificado / fuera de alcance |

---

## 7. Variables de entorno y configuración

| Variable / clave | Descripción | Ambiente |
|---|---|---|
| `FileStorage:BucketName` / `Key` / `Secret` / `Region` | Ya existentes — no hardcodear secrets nuevos | Dev / QA / Prod |
| `FileStorage:Documentos_Talleres` *(nueva)* | Prefijo S3 p.ej. `talleres/` | Dev / QA / Prod |
| `WorkshopDocuments:MaxFileSizeMb` *(nueva, opcional)* | Tope de tamaño (default propuesto 5) | Dev / QA / Prod |
| `WorkshopDocuments:AllowedContentTypes` *(opcional)* | `application/pdf`, `image/jpeg`, `image/png` | Dev / QA / Prod |
| `Hub:HubBaseCountryCode` | Debe ser `COL` para validar el feature | Local COL |

Secrets: seguir usando configuración/Secrets Manager; **no** commitear claves.

---

## 8. Consideraciones de seguridad

- Autorización por roles existentes (`Administrador General`, `Gestor de Países`, `Coordinador Tecnicos`, etc.); Auditor solo lectura.
- El rol `Taller` solo carga/consulta documentación de su propio taller.
- Datos bancarios: sin cifrado especial adicional en MVP (riesgo aceptado en PRD); restringir quién ve Details.
- Validar extensión/MIME y tamaño en servidor (no solo cliente).
- URIs S3: preferir keys privadas + descarga autorizada (mismo patrón que averías), no buckets públicos.
- No registrar en logs números de cuenta completos ni archivos en base64.

---

## 9. Consideraciones de infraestructura

- Sin servicio ECS nuevo: sigue SIGA Web en EC2.
- S3: mismo bucket (o el de la consola Colombia si difiere por ambiente); nuevo prefijo de objetos → costo de almacenamiento acotado por límite de tamaño.
- RDS: una tabla (+ posible descuentos); impacto bajo.
- IAM: el rol/instancia que ya sube documentos de averías debe poder escribir el nuevo prefijo (verificar si el prefijo está cubierto por la policy actual).

---

## 10. Criterios de aceptación

- [ ] En Colombia, el auto-registro público **no permite enviar** sin RUT, Cámara de Comercio, brochure, descuentos (dato+archivo) y cuenta bancaria (dato+archivo)
- [ ] La solicitud interna / bandeja permite ver y gestionar la misma documentación
- [ ] Archivos en S3; metadatos en PostgreSQL con tipo, uri, autor, fecha, estatus
- [ ] Solo PDF / JPG / PNG; rechazo claro si formato o tamaño inválido
- [ ] El aprobador revisa cada documento, valida cuenta bancaria y aprueba o rechaza con motivo y trazabilidad
- [ ] **Ningún taller queda aprobado/activo** sin documentación obligatoria completa y validada
- [ ] Al actualizar cuenta bancaria (datos sensibles) se exige soporte antes de guardar
- [ ] Talleres ya existentes **no** son obligados a regularizar en este MVP
- [ ] MX/CHL no se rompen (no se les exige el nuevo flujo salvo decisión explícita)
- [ ] Preguntas abiertas de análisis bancario y campos estructurados quedan resueltas y reflejadas en código

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Reglas de análisis bancario indefinidas | Alta | Alto | Cerrar en T-01; si no hay reglas de sistema, limitar a checklist manual del aprobador + archivo soporte |
| `datos_fiscales_bancarios_taller` sin EF en COL | Media | Medio | Completar DbSet/mapeo en Fase 0/1 antes del update bancario |
| Canal API Workshops crea solicitudes sin docs | Media | Medio | Decidir en T-01: incluir multipart o excluir/bloquear COL |
| Alta ad-hoc `RegistraTallerYAsigna` bypasea docs | Media | Medio | Decidir excepción documentada o exigir docs también |
| Límite de tamaño no definido | Media | Medio | Default 5 MB hasta confirmación operativa |
| Inconsistencia S3 vs BD | Baja | Alto | Subir a S3 primero o compensar con borrado/transacción lógica; no aprobar si `FileExists` falla |
| Red mixta (talleres viejos sin docs) | Alta | Bajo (aceptado) | Solo nuevos + updates futuros; comunicar a operación |
| Secrets `FileStorage` en appsettings locales | Media | Medio | No tocar/rotar en este plan; no duplicar secretos en commits |

---

## 12. Notas para el programador

1. **País base:** desarrollar y probar con build Colombia. Usar skill `siga-cambio-pais-base` si el entorno local está en MX.
2. **No refactorizar** `TalleresController` / flujo de Identity al autorizar más allá de lo necesario para el guardarraíl documental.
3. **Create interno** está comentado: el PRD habla de “solicitud interna”; priorizar bandeja de `registro_taller` + registro público. Rehabilitar Create solo si operación lo pide en T-01.
4. **Descuentos pactados** son diseño nuevo: no inventar semántica de negocio — fijar campos con el solicitante en T-01.
5. **Paridad DataAccess MX/COL:** para entidades nuevas, replicar modelo/mapeo en ambos contextos si el equipo mantiene espejo; la UI/reglas de obligatoriedad solo en COL.
6. **Fuera de alcance confirmado:** OCR, verificación RUT/Cámara vs fuentes oficiales, vencimiento/renovación, validación bancaria externa, regularización retroactiva.
7. Pendiente de T-01 (dejar respuestas aquí al cerrar Fase 0):
   - Análisis cuenta bancaria =
   - Campos descuentos =
   - Campos cuenta bancaria adicionales =
   - Max file size =
   - API Workshops en MVP = sí/no
   - `RegistraTallerYAsigna` = exigir docs / exceptuar

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Alineación y modelo (P1)** | Preguntas abiertas, rama, script BD + EF COL | T-01 a T-03 | 2 – 3 días | 38 |
| **Fase 1 — Persistencia y reglas (P1)** | Entidad docs, S3, validador de obligatoriedad | T-04 a T-06 | 3 – 4 días | 39 |
| **Fase 2 — Canales de captura (P1)** | Registro público + solicitud interna (+ API condicional) | T-07 a T-09 | 3 – 5 días | 40 |
| **Fase 3 — Aprobación y updates (P1)** | Aprobar/rechazar docs, análisis bancario, update sensible, auditoría | T-10 a T-12 | 3 – 4 días | 41 |
| **Fase 4 — Pruebas y cierre (P1)** | E2E COL, UX, regresión multi-país | T-13 a T-14 | 2 – 3 días | 42 |
| **Total proyecto (alcance único = P1)** | | 14 tareas | **~13 – 19 días hábiles (≈ 3 – 4 semanas)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + … (MVP completo; el PRD no separa P2) | T-01 a T-14 | **~13 – 19 días hábiles** | — |

> **Notas:** el PRD declara alcance único (sin fases de producto). Toda la entrega es P1. T-09 puede cancelarse si el API queda fuera; eso baja ~1–2 días el rango alto.

> **Riesgo de deadline:** el PRD **no define fecha límite**. Con un desarrollador a tiempo completo, el MVP encaja en ~3–4 semanas hábiles. Si hubiera fecha &lt; 10 días hábiles, priorizar: esquema + registro público + guardarraíl de aprobación (T-03…T-07, T-10) y diferir API (T-09) y pulido de update bancario avanzado. Un segundo desarrollador en paralelo (UI registro vs. aprobación/BR) comprimiría ~30–40% el calendario.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
*Rama base: `develop`*
