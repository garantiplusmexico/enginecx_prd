# Plan de Desarrollo — Plantillas para resoluciones de averías (PJ6999)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ6999-plantillas-resoluciones-averias/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web + AveriasBusinessRules + PDFGenerator + Protos) |
| Rama base | `develop` |
| Rama | `feature/PJ6999-plantillas-resoluciones-averias` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ6999` |
| Fecha de generación | 2026-08-17 |
| Estado | Validado |
| ID plan (BD) | 42 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

Hoy, para emitir una **resolución manual**, el técnico debe **subir un Word/PDF que armó fuera de SIGA** (`tipo_documento = "Resolución"`) y luego pulsar **Procede / No procede**. El proyecto genera ese documento **dentro de SIGA**: plantilla procedente o no procedente, prellenada con datos de la avería + texto del técnico, PDF vía el **mismo motor Word→PDF de contratos/resoluciones**, guardado en `documento_averia`. Vía alterna: descargar Word prellenado, completar fuera, **resubir** (reemplaza el final). **No se envía al cliente.**

- **Arquitectura:** feature sobre SIGA Web (EC2) + servicio **PDFGenerator** (gRPC, ya usado). Sin microservicio nuevo.
- **Stack:** .NET 8, Razor, OpenXml (placeholders en `.docx`), conversión PDF ya existente (LibreOffice / MS Graph según ambiente), `documento_averia` + disco `documentos/averias/{id}/`.

**Hallazgo técnico (cierra preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en `develop` |
|---|---|
| ¿Dónde escribe el técnico la resolución? | `_ResolucionPanel.cshtml` (estatus **Validación**, refacciones y MO validadas). Solo botones Procede / No procede. **No hay textarea.** |
| ¿Ya exige un documento? | `AveriasBusinessRules.Resolucion`: si no hay `documento_averia` con tipo **Resolución**, no deja emitir. Ese archivo hoy lo sube el técnico a mano (`AddFiles`). |
| ¿Hay motor de plantillas? | **Sí.** `PDFResolucionAutomatica` (gRPC `MakeAutoResolutionForClaim`): copia `.docx`, reemplaza `[ID_AVERIA]`, `[VIN]`, etc., convierte a PDF, inserta `documento_averia` tipo Resolución y **manda correo**. Eso es la **resolución automática**, no la manual. |
| ¿Plantillas actuales? | Config `Plantillas:AutorizacionAveria` y `Plantillas:RechazoAveria{tipo_cobertura}` (PDFGenerator). No hay UI para Coordinador. Catálogo de plantillas de **contratos** (`DocumentosAdicionales` / Productos) es AG/Gestor, no Coordinador. |
| ¿Mismo almacén que evidencias? | **Sí.** `AddFiles` → `documentos/averias/{id}/` + fila `documento_averia`. Descarga: `DownloadFile`. Dropzone **15 MB**. |
| ¿Campos de plantilla? | El área no entregó diseño. Lista tentativa = placeholders ya usados en auto-resolución **más** `[TEXTO_RESOLUCION]`. El Coordinador sube el `.docx` final con branding. |
| ¿Word resubido → PDF? | **No definido.** MVP: el archivo subido **es** el final (Word o PDF). Sin conversión extra. |
| ¿Enviar al cliente? | Fuera de alcance. No reutilizar `SendResolutionEmail` de la automática en este flujo. El email al taller que ya manda `Resolucion()` **se deja**. |

**Implicación:** no inventar otro generador. Extender el pipeline OpenXml + conversión de `PDFResolucionAutomatica` con texto del técnico, **sin** correo al cliente. La UI nueva vive en `_ResolucionPanel`. Hace falta **desplegar PDFGenerator** junto con la Web.

---

## 2. Prerequisitos

- [ ] PRD validado
- [ ] `develop` actualizado; `CLAUDE.md` presente ✅
- [ ] Acceso a desplegar **PDFGenerator** (gRPC) además de SIGA Web
- [ ] LibreOffice o MS Graph de conversión PDF **ya operativos** en el host de PDFGenerator (mismo que contratos)
- [ ] Coordinador Técnico entrega (o valida) dos `.docx`: procedente y no procedente, con los placeholders de §12. Si no llegan a tiempo: se arranca con plantillas mínimas (placeholders + `[TEXTO_RESOLUCION]`) y se reemplazan por UI
- [ ] Avería de prueba en **Validación**, piezas/MO validadas, técnico asignado
- [ ] No commitear `appsettings.json` locales ni secrets

---

## 3. Arquitectura del cambio

```
[Técnico / Coordinador]  Edit avería (Validación)
        │
        ├─ textarea texto_resolucion  (se guarda en averia)
        ├─ Generar PDF  ──gRPC──► PDFGenerator.MakeManualClaimResolution
        │                              plantilla procedente | no procedente
        │                              OpenXml placeholders + [TEXTO_RESOLUCION]
        │                              Word→PDF (mismo convertidor que contratos)
        │                              INSERT documento_averia tipo=Resolución
        │                              NO envía correo al cliente
        ├─ Descargar Word prellenado  (mismo RPC, convert_to_pdf=false)
        └─ Subir Word/PDF             AddFiles tipo=Resolución (reemplaza el final)

[Procede / No procede]  Resolucion() como hoy (exige que ya exista Resolución)
```

**Decisiones de diseño:**

1. **No tocar** resolución automática (`MakeAutoResolutionForClaim`, correo automático, `tipo_resolucion` Aprobación/Rechazo automático).
2. **Plantilla según dictamen:** radio/botones en el panel (Procedente / No procedente) **antes** de generar. Los botones Procede/No procede actuales siguen cerrando el dictamen; si aún no hay PDF, se puede generar en el mismo click usando el sentido del botón (procedente ↔ Procede). Preferencia: generar explícito + que Procede/No procede siga exigiendo el documento (hoy).
3. **Reemplazo (RF-06):** al generar o al subir una nueva Resolución, las filas previas del mismo tipo en esa avería se conservan para auditoría; `Resolucion()` y la UI “documento final” usan la **más reciente** (`ORDER BY fecha DESC`). Ajustar el `FirstOrDefault` actual si hace falta.
4. **Permisos:** panel ya es Tecnico + Coordinador Tecnicos. Mantener ambos (el Coordinador ya emite resoluciones). Taller no genera.
5. **Catálogo Coordinador:** pantalla simple (2 plantillas) con upload `.docx` a disco + S3 (`FileStorage`, mismo patrón que plantillas de contrato). Authorize: `Coordinador Tecnicos, Administrador General`.
6. **Texto persistido** en `averia.texto_resolucion` para no perderlo si falla el PDF (RNF-05).
7. **Conversión Word resubido:** no en MVP.
8. Código nuevo en inglés; mensajes al usuario en español.

---

## 4. Tareas de desarrollo

### Fase 0 — Rama

- [ ] **T-01** — Rama `feature/PJ6999-plantillas-resoluciones-averias` desde `develop` (`gp_4.0_siga`)
  - Criterio de completitud: rama en origin

### Fase 1 — Persistencia y plantillas (P1)

- [ ] **T-02** — Columna `texto_resolucion` en `averia`
  - Archivos: `GarantiplusWeb/BD/2026-08-17_plantillas_resolucion_averia/01_texto_resolucion.sql`; `DataAccess/Models/averia.cs` + `garantiplus_dbContext.cs`; espejo `DataAccessColombia/`
  - SQL: `ALTER TABLE averia ADD COLUMN IF NOT EXISTS texto_resolucion text;`
  - Criterio de completitud: EF MX/COL mapean el campo; script listo para los tres hubs

- [ ] **T-03** — Dos plantillas `.docx` + config
  - Archivos: `plantillas/resoluciones/procedente.docx`, `no_procedente.docx` (placeholders de §12); keys `Plantillas:ResolucionProcedente` / `Plantillas:ResolucionNoProcedente` en **PDFGenerator** (documentar; no commitear paths locales)
  - Criterio de completitud: un replace OpenXml de prueba deja `[TEXTO_RESOLUCION]` visible

- [ ] **T-04** — UI Coordinador: reemplazar plantillas
  - Archivos: controller/vista bajo Catalogos o Averias (`PlantillasResolucionController`), menú `_LeftMenuBar_{MEX,COL,CHL}` para `Coordinador Tecnicos`
  - Upload `.docx` → path local + S3 (copiar patrón `DocumentosAdicionalesController` / `VerificaPlantilla`)
  - Criterio de completitud: un Coordinador sube la plantilla procedente y PDFGenerator la ve en el siguiente generate

### Fase 2 — Motor PDF/Word (P1)

- [ ] **T-05** — gRPC nuevo (no reusar el automático que envía mail)
  - Archivos: `Protos/PDF.proto`; implementación en `PDFGenerator` (clase nueva o extensión de `PDFResolucionAutomatica` **sin** `SendResolutionEmail`)
  - Request: `id_averia`, `resolution_text`, `proceeding` (bool), `convert_to_pdf` (bool)
  - Response: `path` relativo + `ErrorInfo`
  - Insert `documento_averia` tipo `Resolución`, mime pdf o docx, uri bajo `DocumentosGenerados:DocumentosAverias` (igual que la automática)
  - Conversión: **reutilizar** el convertidor de contratos (MS Graph / local), no copiar a ciegas `loffice_wrapper.sh` si el ambiente ya usa Graph
  - Criterio de completitud: llamada gRPC con avería de prueba produce PDF en disco y fila en BD; no sale correo al cliente

- [ ] **T-06** — Cliente en AveriasBusinessRules / AveriasController
  - Inyectar `PDFServiceClient` en el controller si hace falta (las rules ya lo tienen para auto-resolución)
  - Criterio de completitud: SIGA Web invoca el RPC y persiste `texto_resolucion` **antes** de llamar (si el RPC falla, el textarea sigue)

### Fase 3 — UI del técnico (P1)

- [ ] **T-07** — Sección de texto + selección procedente/no procedente
  - Archivos: `_ResolucionPanel.cshtml`, `Edit.cshtml` JS, POST `SaveResolutionText`
  - Visible con la misma condición actual del panel (Validación + todo validado)
  - Criterio de completitud: el técnico guarda texto, recarga la página y el texto sigue ahí

- [ ] **T-08** — Generar PDF y descargar Word prellenado
  - Acciones: `GenerateResolutionPdf`, `DownloadPrefilledResolutionWord`
  - Errores en español, sin borrar el texto
  - Criterio de completitud: PDF aparece en la tabla de documentos; Word descarga con datos y texto; Procede/No procede ya no exige un upload manual si el PDF existe

### Fase 4 — Recarga, reemplazo y descarga (P1)

- [ ] **T-09** — Resubir Word/PDF como documento final
  - Reutilizar `AddFiles` tipo Resolución (ya existe en Validación para no-taller)
  - Validar extensión `.doc/.docx/.pdf` y tamaño ≤ 15 MB (igual que dropzone)
  - “Reemplaza el final” = el más reciente; no borrar históricos
  - Criterio de completitud: subir un PDF nuevo; `DownloadFile` de esa fila es lo que el técnico envía; `Resolucion()` adjunta el más reciente

- [ ] **T-10** — Eventos `log_averia` (BI)
  - `resolucion_generada`, `resolucion_plantilla_descargada`, `resolucion_documento_resubido`, `resolucion_documento_descargado` (este último en `DownloadFile` si tipo Resolución)
  - Campos: usuario, id_averia, procedente/no, resultado
  - Criterio de completitud: cada acción deja una fila

### Fase 5 — Validación (P1)

- [ ] **T-11** — Camino feliz: texto → PDF → Procede; texto → Word → resubir PDF → No procede
- [ ] **T-12** — No-regresión: resolución automática intacta; dropzone evidencias igual; sin plantilla/RPC caído el texto no se pierde; Coordinador puede cambiar `.docx`

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `averia` | Modificación | `texto_resolucion text` |
| `documento_averia` | Sin esquema | Nuevas filas tipo `Resolución` (ya existe el tipo) |
| `log_averia` | Sin esquema | Eventos BI |

SQL a mano en MX / COL / CHL. Espejo EF.

No hace falta tabla de plantillas si se versionan como archivos (S3 + path). Si se quiere auditoría de quién subió la plantilla, un log basta para el MVP.

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `/Averias/Averias/SaveResolutionText/{id}` | Persiste `texto_resolucion` | Nuevo |
| POST | `/Averias/Averias/GenerateResolutionPdf/{id}` | gRPC → PDF + `documento_averia` | Nuevo |
| GET | `/Averias/Averias/DownloadPrefilledResolutionWord/{id}` | Word prellenado | Nuevo |
| POST | `/Averias/Averias/AddFiles` | Resubida Resolución (reemplazo lógico) | Modificado (regla latest) |
| GET | `/Averias/Averias/DownloadFile/{id}` | Ya existe; log si es Resolución | Modificado (log) |
| gRPC | `MakeManualClaimResolution` | PDFGenerator | Nuevo |
| CRUD | `/Catalogos/PlantillasResolucion` (nombre final) | Upload 2 plantillas | Nuevo |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| `Plantillas:ResolucionProcedente` | Path/nombre del `.docx` procedente (PDFGenerator) | local / QA / prod |
| `Plantillas:ResolucionNoProcedente` | Path/nombre del `.docx` no procedente | idem |
| `FileStorage:Plantillas_resoluciones` (o reusar `Plantillas_contratos` con subcarpeta `resoluciones/`) | Prefijo S3 | idem |
| `DocumentosGenerados:DocumentosAverias` | Ya existe | idem |

Sin secrets nuevos.

---

## 8. Consideraciones de seguridad

- Generar/subir solo Tecnico o Coordinador Tecnicos; validar en servidor (no solo ocultar el panel).
- Preferible exigir que el Tecnico sea el `id_tecnico` de la avería; el Coordinador queda exento (supervisión).
- Validar MIME/extensión y 15 MB en resubida.
- No enviar el PDF a destinatarios distintos de los que ya usa `Resolucion()` (taller).
- Plantillas: solo Coordinador / AG; no path traversal en el nombre de archivo.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- **Desplegar PDFGenerator** con el proto nuevo a la vez que SIGA Web (si no, el gRPC rompe).
- Plantillas en S3 para que el pod/EC2 de PDFGenerator las baje (mismo `VerificaPlantilla` que contratos).
- LibreOffice/MS Graph: sin cambio de infra si ya generan contratos.
- Disco `documentos/averias` compartido o copiado como hoy entre Web y PDFGenerator (`DocumentosAverias`). Si en prod el PDF queda en un path que la Web no sirve, reutilizar el mismo truco de uri `/documentos/averias/...` que la automática.

---

## 10. Criterios de aceptación

- [ ] **RF-01:** Textarea en la avería cuando hay problema/solución (panel Validación actual).
- [ ] **RF-02:** Plantilla procedente vs no procedente según lo elegido.
- [ ] **RF-03:** PDF/Word salen con folio, vehículo, cliente, taller, fechas, texto del técnico (placeholders §12).
- [ ] **RF-04:** PDF con el motor existente; no un generador paralelo.
- [ ] **RF-05:** Descarga Word prellenado.
- [ ] **RF-06:** Subida Word/PDF; el más reciente es el final.
- [ ] **RF-07 / RNF-02:** Queda en `documento_averia` (quién = usuario de la acción, cuándo = `fecha`).
- [ ] **RF-08:** `DownloadFile` como el resto de evidencias.
- [ ] **RNF-01:** Taller no genera; SIGA no manda al cliente en este flujo.
- [ ] **RNF-03 / RNF-04:** OpenXml + plantilla del Coordinador.
- [ ] **RNF-05 / RNF-06:** Fallo de PDF no borra texto; 15 MB / Word+PDF.
- [ ] Resolución **automática** y Procede/No procede (con documento ya existente) siguen igual.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Diseño de plantilla no entregado | Alta | Alto | Placeholders fijos + UI de reemplazo; no bloquear código |
| Path `DocumentosAverias` distinto Web vs PDFGenerator | Alta | Alto | Misma convención uri que `PDFResolucionAutomatica` |
| Convertidor LibreOffice vs Graph | Media | Medio | Usar el de contratos del ambiente, no el shell viejo si Graph está on |
| Proto desfasado si no se despliega PDFGenerator | Alta | Alto | Deploy conjunto; feature flag no hace falta si el botón no se pulsa |
| `FirstOrDefault` Resolución toma el archivo viejo | Media | Medio | T-09 latest by fecha |
| Placeholders partidos en varios `<w:t>` de Word | Alta | Medio | Documentar al Coordinador que cada tag vaya en un solo run; mejorar replace si hace falta |

---

## 12. Notas para el programador

**Placeholders tentativos** (los de `PDFResolucionAutomatica` + texto). El área puede añadir más en el `.docx` si el replace es genérico:

`[ID_AVERIA]` `[ID_CONTRATO]` `[NOMBRE_MARCA]` `[NOMBRE_MODELO]` `[NOMBRE_PRODUCTO]` `[VIN]` `[VIGENCIA_INICIAL]` `[KM_CONTRATO]` `[FECHA_REGISTRO]` `[KM_AVERIA]` `[FECHA_ACTUAL]` `[NOMBRE_BENEFICIARIO]` `[RFC_BENEFICIARIO]` `[NOMBRE_TALLER_REPARADOR]` `[RFC_TALLER_REPARADOR]` `[TEXTO_RESOLUCION]`

Opcionales de la automática (`[LISTA_REFACCIONES]`, montos) si caben en la plantilla del área.

1. Rol exacto: `Coordinador Tecnicos` (sin acento).
2. No mezclar con PJ0288 (pago) ni con estatus 12 En Aprobación.
3. No refactorizar `AveriasController` más de lo necesario; extraer llamadas gRPC a un helper si el action se infla.
4. Espejar DataAccess MX/COL.
5. El MVP **no** registra “enviado al cliente”.

---

## 13. Relación de tareas y tiempos

Todo el PRD es **P1**. Envío al cliente, catálogo por marca y firma legal son fuera de alcance (no hay P2 en este plan).

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama** | Rama feature | T-01 | 0.25 días | 121 |
| **Fase 1 — Persistencia y plantillas (P1)** | SQL, docx, UI Coordinador | T-02 a T-04 | 1.5 – 2.5 días | 122 |
| **Fase 2 — Motor PDF/Word (P1)** | Proto + PDFGenerator + cliente | T-05 a T-06 | 2 – 3 días | 123 |
| **Fase 3 — UI técnico (P1)** | Textarea, generar PDF, Word | T-07 a T-08 | 1.5 – 2 días | 124 |
| **Fase 4 — Recarga y eventos (P1)** | AddFiles latest + logs | T-09 a T-10 | 0.75 – 1.5 días | 126 |
| **Fase 5 — Validación (P1)** | Feliz + no-regresión automática | T-11 a T-12 | 1 – 1.5 días | 125 |
| **Total proyecto (P1)** | | 12 tareas | ~7 – 11 días hábiles (≈ 1.5 – 2.5 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 a Fase 5 | T-01 a T-12 | ~7 – 11 días hábiles (≈ 1.5 – 2.5 semanas) | — |

> La columna **ID (BD)** la llena el flujo al registrar el plan.

> **Riesgo de deadline:** el PRD no fija fecha. Un desarrollador cubre ~7–11 días **si las plantillas del área llegan en Fase 1**; si no, se sale con docx mínimos y el Coordinador las cambia después (T-04). El cuello de botella técnico es **PDFGenerator + proto** (Fase 2), no la UI. Recorte si aprieta: T-04 (plantillas solo por archivo en disco) y T-10 (eventos BI).

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
