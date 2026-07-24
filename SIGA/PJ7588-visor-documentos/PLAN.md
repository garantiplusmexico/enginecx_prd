# Plan de Desarrollo — Visor de Documentos en Averías

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ7588-visor-documentos/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web / Garantiplus) |
| Rama base | `develop` |
| Rama | `feature/PJ7588-visor-documentos-averias` |
| Tipo | Feature (proyecto existente) |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ7588` |
| Fecha de generación | 2026-07-24 |
| Estado | Validado |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal |
| ID plan (BD) | 30 |

---

## 1. Resumen técnico

Implementar un **visor modal (overlay)** en la pantalla de Averías de SIGA Web para previsualizar soportes (PDF, imágenes, video; Office según decisión de Fase 0) **sin descargarlos**, reutilizando la cascada de obtención **servidor temporal → S3 → no encontrado** que hoy usa la descarga.

- **Arquitectura:** modificación del monolito existente SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). No se crea microservicio nuevo.
- **Stack:** backend C# / ASP.NET Core 8; frontend jQuery + Bootstrap 3 (el que ya usa Averías); almacenamiento S3 vía `IStorage` / `Bucket_GP` (`FileStorage:*`); PostgreSQL sin cambios de esquema esperados.
- **Componentes:**
  - Extraer/unificar helper de resolución de bytes de `documento_averia` (hoy `DownloadFile`, ZIP y facturas divergen; el check local usa `Directory.Exists` sobre ruta de archivo).
  - Endpoint de preview (inline / streaming) que **no** force `Content-Disposition: attachment`.
  - Partial + JS reutilizable del visor (desacoplado de Averías para Fase 2 de producto).
  - Integración en vistas Edit / Details (/ Aprobación si aplica).
  - Eventos de telemetría para BI (hoy no existen para descarga).

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / liderazgo (Alexis Salvador Herrera García)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Credenciales S3 de `FileStorage` operativas en el ambiente de desarrollo (lectura bucket)
- [ ] Decisión de alcance Office (ver §12): diferir o implementar en P2
- [ ] Inventario real de extensiones en Averías (query BD o muestra operativa) — se cierra en Fase 0
- [ ] `CLAUDE.md` presente en el repositorio ✅

---

## 3. Arquitectura del cambio

Se mantiene la arquitectura actual de **SIGA Web** (UI + backend en el mismo proceso en EC2). El archivo **nunca** se resuelve con credenciales en el navegador: el backend sirve bytes (o stream con rangos) tras validar autenticación/roles de descarga.

```
[Usuario Averías]
    → [Vista Averías: botón Vista previa]
    → [GET PreviewDocument / stream]
    → [AuthZ: roles de descarga existentes]
    → [DocumentFileResolver: local → S3]
    → [Visor modal: PDF | img | video | Office*]
    → [Log evento BI]
```

\*Office solo si se confirma mecanismo en Fase 0; si no, mensaje + descarga (RF-08).

**Decisiones alineadas a reglas Engine:**
- Feature sobre proyecto existente → no cambiar stack ni despliegue (sigue EC2).
- Secrets S3 solo en settings/backend (RNF-01).
- Código nuevo en inglés; mensajes de usuario en español.
- No refactorizar fuera de lo necesario para el helper de obtención y el componente del visor.

### Hallazgos del código actual (ancla)

| Pieza | Ubicación |
|---|---|
| Descarga individual | `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` → `DownloadFile` |
| ZIP (solo S3) | `AveriasBusinessRules` → `GetDocumentFileBytesAsync` / `DownloadClaimDocumentsZip` |
| S3 Averías | `storageFactory("Bucket_GP")` → `FileStorage:Key/Secret/Region/BucketName` |
| UI listado | `_Edit.cshtml`, `Edit.cshtml`, `Details.cshtml` |
| Extensiones upload | Dropzone: `.mp4,.mov,.jpg,.jpeg,.png,.xls,.xlsx,.pdf,.doc,.docx,.ppt,.pptx` (máx. 15 MB) |
| BI descarga | **No existe** hoy |

---

## 4. Tareas de desarrollo

### Fase 0 — Discovery y diseño técnico (P1 prep)

- [ ] **T-01** — Inventariar formatos reales de soportes en Averías (extensiones / `mime_type` más frecuentes y outliers).
  - Archivos a crear/modificar: nota en `PLAN.md` §12 o query documentada; sin cambio de producto aún.
  - Criterio de completitud: lista priorizada de formatos in-scope vs “solo descarga”.

- [ ] **T-02** — Decidir mecanismo Office (Word/Excel/PPT): conversión a PDF en backend (p. ej. servicio Azure Word→PDF existente), LibreOffice, o diferir a P2 con UX RF-08.
  - Archivos a crear/modificar: decisión registrada en §12 de este plan.
  - Criterio de completitud: decisión escrita con impacto en T-12/T-13 y estimación §13 ajustada si se difiere.

- [ ] **T-03** — Diseñar contrato del componente reutilizable (params: URL de stream, MIME, nombre, callbacks de error/cierre/BI) y del endpoint de preview (ruta, códigos HTTP, headers de rango).
  - Archivos a crear/modificar: diseño breve en §12 / comentario de arquitectura en AI si el equipo lo pide; sin código aún.
  - Criterio de completitud: contrato acordado (params + códigos 200/403/404/415).

### Fase 1 — Backend: resolución de archivo y endpoint de preview (P1)

- [ ] **T-04** — Extraer helper `DocumentFileResolver` (o equivalente) que unifique: local (`File.Exists` correcto, no `Directory.Exists`) → S3 (`uri` normalizada) → not found; reutilizar desde descarga y preview.
  - Archivos a crear/modificar: p. ej. `AveriasBusinessRules` o `Common/Storage` helper; `AveriasController.DownloadFile`; opcionalmente ZIP BR.
  - Criterio de completitud: `DownloadFile` y preview usan el mismo resolver; test manual local+S3+missing.

- [ ] **T-05** — Alinear keys/paths S3 vs `uri` BD vs `FileStorage:Documentos_Averias` / `DocumentosAverias` (inconsistencia detectada en upload vs download). Documentar override de ambiente si aplica; no romper prod.
  - Archivos a crear/modificar: `appsettings*.json` (solo si hace falta clave faltante), código de upload/download según hallazgo.
  - Criterio de completitud: un documento subido en el ambiente de prueba se resuelve tanto en descarga como en preview.

- [ ] **T-06** — Implementar endpoint de preview (p. ej. `GET /Averias/Averias/PreviewFile/{id}`) que sirva el archivo con disposición **inline**, soporte de `Accept-Ranges` / rangos para video y archivos grandes, y mensajes claros 404/415.
  - Archivos a crear/modificar: `AveriasController.cs` (+ posible action filter o service).
  - Criterio de completitud: PDF/imagen/video abren en el navegador vía URL del endpoint; no fuerza descarga; sin credenciales S3 en respuesta.

- [ ] **T-07** — Heredar permisos de descarga: mismos roles del `[Authorize]` de Averías; sin esquema nuevo. (Opcional endurecimiento: validar que el documento pertenece a una avería visible al usuario — solo si no rompe flujos actuales.)
  - Archivos a crear/modificar: `AveriasController.cs`.
  - Criterio de completitud: usuario sin rol de Averías → 401/403; con rol → preview OK; botón no visible sin permiso (UI en Fase 2).

### Fase 2 — Frontend: visor modal en Averías (P1)

- [ ] **T-08** — Crear partial/componente del modal de preview (Bootstrap 3) + JS parametrizable (`openDocumentPreview({ url, mime, fileName, downloadUrl })`), desacoplado de la lógica de negocio de Averías.
  - Archivos a crear/modificar: p. ej. `Views/Shared/_DocumentPreviewModal.cshtml`, `wwwroot/js/document-preview.js` (nombres finales a convenir), inclusión en layout o vistas Averías.
  - Criterio de completitud: el modal abre/cierra sin recargar; API JS usable con params mínimos.

- [ ] **T-09** — Render PDF (iframe o PDF.js si el navegador no basta), imágenes (`<img>`), video (`<video controls>` con URL de stream).
  - Archivos a crear/modificar: JS del visor; vendor PDF.js solo si se decide en T-03.
  - Criterio de completitud: un PDF, un JPG/PNG y un MP4 de prueba se ven correctamente en Chrome/Edge (navegadores objetivo de SIGA).

- [ ] **T-10** — Integrar acción “Vista previa” junto a cada soporte en Edit / Details (y Aprobación si muestra la misma tabla); ocultar si el formato no es previsualizable o mostrar con mensaje RF-08 + link de descarga.
  - Archivos a crear/modificar: `_Edit.cshtml`, `Edit.cshtml`, `Details.cshtml`, `Aprobacion.cshtml` (si aplica).
  - Criterio de completitud: clic abre modal; descarga existente intacta; formato no soportado informa y ofrece descarga.

- [ ] **T-11** — UX de errores: archivo no encontrado, fallo de render, formato no soportado; botón/link de descarga desde el modal (RF-11).
  - Archivos a crear/modificar: JS + partial del visor.
  - Criterio de completitud: los tres casos muestran mensaje en español y no rompen la pantalla de Averías.

### Fase 3 — Office y hardening de entrega (P2)

- [ ] **T-12** — Implementar previsualización Office según decisión T-02 (conversión → PDF stream, o diferir con RF-08).
  - Archivos a crear/modificar: service de conversión / integración Azure o stub diferido; endpoint preview.
  - Criterio de completitud: `.docx` (y los formatos acordados) se previsualizan o se documenta diferido con UX de “no soportado”.

- [ ] **T-13** — Streaming por rangos y límites de tamaño/tiempo para video y archivos grandes (RNF-03); timeout y mensajes claros.
  - Archivos a crear/modificar: endpoint preview / middleware de file result.
  - Criterio de completitud: video seek funciona; archivo > umbral acordado rechaza o avisa sin tumbar el worker.

### Fase 4 — Telemetría BI y cierre MVP (P1)

- [ ] **T-14** — Registrar eventos `documento_previsualizado` y `previsualizacion_fallida` (campos mínimos del PRD §11). Evaluar si existe evento de descarga reutilizable; si no, registrar `documento_descargado` en el flujo de descarga actual o dejar hook documentado para BI.
  - Archivos a crear/modificar: controller/JS + canal de log acordado (Serilog estructurado / tabla / lo que use BI hoy).
  - Criterio de completitud: preview OK y fallos generan evento con usuario, id_averia, id_documento, tipo, origen, resultado.

- [ ] **T-15** — Pruebas de aceptación manual del MVP en Averías (matriz formatos × orígenes local/S3 × permisos) y checklist §10.
  - Archivos a crear/modificar: ninguno de producto; evidencia en AVANCE al ejecutar.
  - Criterio de completitud: checklist §10 marcado; sin regresión en descarga/ZIP/upload.

### Fase 5 — Preparación reutilización otras áreas (P3 — fuera del MVP de producto)

- [ ] **T-16** — Documentar cómo integrar el componente en otra área (params, endpoint patrón) y extraer de Averías cualquier acoplamiento residual descubierto en la integración.
  - Archivos a crear/modificar: doc breve bajo `GarantiplusWeb/AI/` o nota en este plan; ajustes menores al JS/partial.
  - Criterio de completitud: otra área podría adoptar el modal sin copiar lógica de Averías (integración real = PRD Fase 2, otro plan).

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | Ninguno previsto | Se reutiliza `documento_averia` (`id_documento`, `uri`, `mime_type`, `nombre_original`). |
| (opcional) evento BI | Nueva / externa | Solo si BI exige persistencia en tabla propia; preferir canal de logging existente. Confirmar en T-14. |

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/Averias/Averias/PreviewFile/{id}` | Sirve bytes/stream del soporte para preview (inline, rangos). `id` = `id_documento`. | Nuevo |
| GET | `/Averias/Averias/DownloadFile/{id}` | Descarga existente; pasar a usar el mismo resolver. | Modificado (interno) |
| GET | `/Averias/Averias/DownloadAllDocuments/{id}` | ZIP; opcionalmente alinear resolución de bytes. | Modificado (opcional) |

No aplica versionado REST tipo API de SIGA: es MVC Area del monolito web.

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable / clave | Descripción | Ambiente |
|---|---|---|
| `FileStorage:Key` / `Secret` / `BucketName` / `Region` | Acceso S3 `Bucket_GP` (ya existe) | Dev / QA / Prod |
| `FileStorage:DocumentosAverias` / `Documentos_Averias` | Paths locales / prefijo S3 — alinear en T-05 | Dev / QA / Prod |
| (opcional) límite tamaño preview | Umbral MB para permitir preview | Si se introduce en T-13 |
| (opcional) URL/credencial convertidor Office | Solo si T-02 elige conversión externa | Según decisión |

No se exponen secrets al cliente. No se requieren recursos AWS nuevos para el MVP.

---

## 8. Consideraciones de seguridad

- Credenciales S3 solo en backend/settings (RNF-01).
- Preview y descarga comparten el mismo esquema de roles; no crear permiso nuevo (RNF-02 / RF-10).
- No emitir URLs firmadas de S3 de larga duración al navegador salvo diseño explícito y TTL corto; preferir proxy/stream por el backend.
- Validar `id_documento` y existencia; evitar path traversal al construir rutas locales desde `uri`.
- Preview es solo lectura: no escritura, edición ni borrado desde el visor.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- **Sin** servicio ECS nuevo: el cambio vive en SIGA Web (EC2).
- Posible aumento de **egress S3** por previsualizaciones (riesgo del PRD); monitorear tras go-live.
- Si Office requiere LibreOffice/contenedor de conversión → **fuera del MVP por defecto**; solo si T-02 lo aprueba con costo/ops claros.
- El convertidor Word→PDF en Azure (legado SIGA) puede reutilizarse solo para Word si se valida disponibilidad y licencia.

---

## 10. Criterios de aceptación

- [ ] En Edit/Details, cada soporte con permiso de descarga muestra “Vista previa” cuando el formato es soportado.
- [ ] El modal muestra PDF, JPG/PNG y MP4 sin abandonar la pantalla de Averías.
- [ ] La cascada local → S3 → “archivo no encontrado” se comporta igual que la descarga corregida.
- [ ] Formato no soportado: mensaje claro + alternativa de descarga.
- [ ] Descarga individual y ZIP siguen funcionando (sin regresión).
- [ ] Credenciales S3 no aparecen en HTML/JS/network del cliente.
- [ ] Roles sin acceso a Averías no pueden previsualizar.
- [ ] Eventos BI de preview éxito/fallo se registran con campos mínimos del PRD.
- [ ] El componente JS/partial es parametrizable (listo para Fase 2 de producto).
- [ ] Office: implementado según T-02 **o** explícitamente diferido con UX RF-08 documentada.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Office exige infra/costo alto | Alta | Alto | Decidir en T-02; diferir a P2/P3 con RF-08 |
| Bug `Directory.Exists` + keys S3 desalineadas | Alta | Medio | T-04 + T-05 antes del UI |
| Archivos grandes / video sin rangos | Media | Medio | T-06 + T-13 streaming |
| Egress S3 aumenta | Media | Medio | Monitoreo post-release; cache local si aplica |
| Variedad real de formatos desconocida | Media | Medio | Inventario T-01 |
| PDF.js u otra lib aumenta peso front | Baja | Bajo | Preferir iframe nativo; lib solo si hace falta |
| AuthZ solo por rol (sin pertenencia a avería) | Media | Medio | Mantener paridad con descarga; endurecer solo si negocio lo pide |

---

## 12. Notas para el programador

1. **Rama base:** `develop` (actualizada al generar el plan). Rama funcional a crear al ejecutar: `feature/PJ7588-visor-documentos-averias`.
2. **No tocar** API de SIGA (`gp_3.0_siga_api`) salvo que más adelante se quiera exponer preview a landings — fuera de este PRD.
3. **P1 (guardarraíl MVP):** Fases 0–2 + telemetría mínima (T-14) + aceptación (T-15). Office completo y reutilización en otras áreas son P2/P3.
4. **Decisión abierta crítica (Office):** cerrar en T-02 antes de comprometer T-12. Recomendación inicial del plan: P1 = PDF + imágenes + video; Office con mensaje + descarga hasta validar convertidor.
5. **PRD sin fecha límite explícita** en el documento; el riesgo de deadline de §13 asume calendario a confirmar con Operaciones/liderazgo.
6. Responsable confirmado: **Alejandro Govea Hernandez**.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Discovery y diseño (P1 prep)** | Inventario formatos, decisión Office, contrato componente/endpoint | T-01 a T-03 | 1 – 2 días | 60 |
| **Fase 1 — Backend preview (P1)** | Resolver unificado, alineación S3/paths, endpoint inline+rangos, permisos | T-04 a T-07 | 2 – 3.5 días | 61 |
| **Fase 2 — Frontend visor Averías (P1)** | Modal reutilizable, PDF/img/video, integración vistas, UX errores | T-08 a T-11 | 2.5 – 4 días | 62 |
| **Fase 3 — Office + hardening (P2)** | Preview Office según T-02, streaming/límites | T-12 a T-13 | 2 – 5 días | 63 |
| **Fase 4 — BI y cierre MVP (P1)** | Eventos preview/fallo, matriz aceptación | T-14 a T-15 | 1 – 2 días | 64 |
| **Fase 5 — Prep. reutilización (P3)** | Doc de integración / desacoplar residual | T-16 | 0.5 – 1 día | 65 |
| **Total proyecto (P1+P2+P3)** | | 16 tareas | ~9 – 17.5 días hábiles (≈ 2 – 3.5 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 + Fase 4 | T-01 a T-11, T-14, T-15 | ~6.5 – 11.5 días hábiles (≈ 1.5 – 2.5 semanas) | — |

> **Notas sobre la tabla:**
> - P1 = MVP usable en Averías con PDF/imágenes/video + permisos + cascada + BI básico.
> - P2 = Office + hardening de archivos grandes (puede comprimirse si T-02 difiere Office).
> - P3 = solo preparación; la integración en otras áreas es el **Fase 2 de producto** del PRD (otro plan).
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite. Con un desarrollador a tiempo completo, el **P1** (~6.5–11.5 días hábiles) es realista en ~2 semanas. Si hay deadline &lt; 10 días hábiles, priorizar P1 y **diferir Office (T-12) y Fase 5**. Un segundo desarrollador en paralelo (backend T-04–T-07 + frontend T-08–T-11) podría comprimir el P1 ~30–40%.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 — esfuerzo: normal*
