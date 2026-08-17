# Plan de Desarrollo — Catálogo de plantillas de productos (PJ1449)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ1449-catalogo-plantillas-productos/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web + DataAccess / DataAccessColombia; PDFGenerator **sin cambio** si se reusa la ruta actual) |
| Rama base | `develop` |
| Rama | `feature/PJ1449-catalogo-plantillas-productos` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ1449` |
| Fecha de generación | 2026-08-17 |
| Estado | Validado |
| ID plan (BD) | 47 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

Hoy cada `producto_proyecto` guarda **su propio** `.docx`: al Add/Edit Project se sube el archivo, se nombra con GUID, se copia a `Plantillas:ContratosPath` y a S3 (`FileStorage:Plantillas_contratos`). PDFGenerator lee `producto_proyecto.plantilla_contrato` (el GUID) y, si falta en disco, lo baja de S3 (`VerificaPlantilla`). No hay repositorio común.

El MVP añade un **catálogo** (CRUD de metadata + archivo) y, en la config del producto, un **selector de plantillas activas**. La carga directa se queda. Varios productos pueden apuntar al **mismo nombre de archivo** (reutilización). PDFGenerator no cambia si el archivo vive en la misma carpeta/S3.

- **Arquitectura:** catálogo nuevo en SIGA Web (mismo patrón que Documentos Adicionales) + tabla PostgreSQL. Sin microservicio.
- **Stack:** .NET 8, Razor, EF, S3 (`IStorage` Bucket_GP), SQL en `GarantiplusWeb/BD/`.

**Hallazgo técnico (cierra las preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo / decisión de plan |
|---|---|
| ¿Dónde se carga hoy? | `ProductosController.AddProject` / `EditProject`. Vista `_EditProject.cshtml` (`input file plantilla_contratos`, ya valida `extension:'docx'`). Roles escritura: **Administrador General, Gestor de Países**. |
| ¿PDFGenerator? | Usa el **filename** en `Plantillas:ContratosPath`. Si el catálogo guarda ahí + S3 con el mismo GUID, **no hay que tocarlo**. |
| ¿Documento adicional? | Otro catálogo (`documento_adicional.ruta_plantilla`) para docs extra, no para la plantilla del contrato del producto. **No reutilizar esa tabla** (campos distintos). Sí copiar el patrón de controller/S3. |
| Referencia viva vs copia | MVP **no reemplaza el .docx** (solo nombre/estatus). Asociar = escribir el mismo GUID en `plantilla_contrato`. Generación sigue funcionando si se inactiva. Si más adelante se sustituye el archivo con el mismo GUID, se propaga (viva). Documentar. |
| Multi-país / hubs | Cada hub tiene **su propia BD**. Un catálogo “único mundial” exigiría S3/BD compartidos y mezclaría plantillas COL en MX (riesgo del PRD). **Decisión:** misma feature en los tres hubs; **datos por hub**. RF-09 = código compartido, no padrón cruzado. |
| Fuente de verdad archivo | Igual que hoy: disco local de plantillas **y** S3. PDFGenerator ya reconcilia (baja de S3 si no está local). |
| Baja en uso | Inactivar = no sale en el combo. Los productos **siguen** con el GUID; los contratos se siguen generando. |
| Formato | Solo `.docx` (ya está en el producto). |
| Metadata extra | No. Nombre + activo (+ auditoría). |
| Permisos | Mismos que Productos escritura: **AG + Gestor de Países**. Auditor: listado/detalle. No rol nuevo. |
| Productos adicionales | Tienen `plantilla_contrato` en **otra** carpeta (`Plantillas:ProductosAdicionales`). **Fuera de este MVP** (otro path). |

---

## 2. Prerequisitos

- [ ] PRD validado
- [ ] `develop` actualizado; `CLAUDE.md` presente ✅
- [ ] Permiso para correr SQL en los hubs (al menos COL; MX/CHL al desplegar)
- [ ] S3 `FileStorage:Plantillas_contratos` y carpeta `Plantillas:ContratosPath` (ya usados)
- [ ] Usuario AG o Gestor para el catálogo y para Add/Edit Project
- [ ] Un `.docx` de plantilla de contrato real para probar generación
- [ ] Espejar **DataAccess y DataAccessColombia**
- [ ] No commitear `appsettings.json` locales

---

## 3. Arquitectura del cambio

```
[AG/Gestor] Catálogos → Plantillas de contrato
    Create: .docx + nombre + activo
         → disco Plantillas:ContratosPath/{guid}.docx
         → S3 FileStorage:Plantillas_contratos{guid}.docx
         → tabla plantilla_contrato_catalogo

[AG/Gestor] Producto → proyecto (Add/Edit Project)
    ├─ Seleccionar plantilla activa  → plantilla_contrato = guid del catálogo
    │                                  id_plantilla_catalogo = id
    └─ Cargar archivo (hoy)          → guid nuevo; id_plantilla_catalogo null

[PDFGenerator] producto_proyecto.plantilla_contrato  (sin cambio)
```

**Decisiones de diseño:**

1. Tabla `plantilla_contrato_catalogo` (no junction N:M: un producto tiene **una** plantilla).
2. `producto_proyecto.id_plantilla_catalogo` nullable FK. La columna `plantilla_contrato` (filename) **se mantiene** para PDFGenerator.
3. Al elegir del catálogo **no** se duplica el archivo; se reusa el GUID.
4. Carga directa: igual que hoy (GUID nuevo, FK null).
5. Inactivar: `activo = false`; no DELETE físico; no borrar S3.
6. Validar `.docx` y tamaño máximo (p. ej. 15 MB, `Plantillas:CatalogoMaxMb` en appsettings; default 15).
7. Menú en `_LeftMenuBar_{MEX,COL,CHL}` junto a Productos / Documentos Adicionales. Profiles: AG | Gestor | Auditor.
8. Catálogo **por hub**. No sync entre países.
9. No migrar plantillas ya ligadas a productos.
10. No versionado, no editor, no tokens.

---

## 4. Tareas de desarrollo

### Fase 0 — Rama

- [ ] **T-01** — `feature/PJ1449-catalogo-plantillas-productos` desde `develop`
  - Criterio de completitud: rama en origin

### Fase 1 — Persistencia (P1)

- [ ] **T-02** — SQL
  - Archivos: `GarantiplusWeb/BD/2026_08_17_plantilla_contrato_catalogo.sql`
  - Tabla `plantilla_contrato_catalogo` (`id`, `nombre`, `activo`, `nombre_archivo`, `usuario_alta`, `fecha_alta`, `usuario_modificacion`, `fecha_modificacion`)
  - `producto_proyecto.id_plantilla_catalogo` nullable FK
  - `GRANT` a `acceso_garantiplus` (mismo estilo que scripts recientes)
  - Criterio de completitud: script idempotente (`IF NOT EXISTS`); corre en COL (y se replica en MX/CHL al desplegar)

- [ ] **T-03** — EF MX y COL
  - Archivos: modelo nuevo + `DbSet` + mapeo en `DataAccess` **y** `DataAccessColombia`; FK en `producto_proyecto` (ambos)
  - Criterio de completitud: ambos contextos mapean igual

### Fase 2 — Catálogo UI (P1)

- [ ] **T-04** — CRUD catálogo
  - Archivos: `PlantillasContratoController` (o nombre en inglés del controller, textos UI en español); vistas Index/Create/Edit/Details al estilo Documentos Adicionales / Productos
  - Create: archivo obligatorio `.docx` + nombre + activo; S3 + disco (mismo patrón que `ProductosController.AddProject`)
  - Edit: nombre/estatus; **no** exigir re-subir el archivo
  - Listado filtrable por activo; sin borrado físico
  - `[Authorize]` clase AG/Gestor/Auditor; Create/Edit solo AG/Gestor
  - Criterio de completitud: AG sube y lista; Auditor no crea; archivo inválido se rechaza

- [ ] **T-05** — Menú
  - Archivos: `_LeftMenuBar_MEX.cshtml`, `_COL`, `_CHL`
  - Criterio de completitud: el ítem se ve con AG/Gestor/Auditor

### Fase 3 — Asociación a producto (P1)

- [ ] **T-06** — Selector en Add/Edit Project
  - Archivos: `_EditProject.cshtml` / `AddProject.cshtml` / `EditProject.cshtml`; `ProductosController` AddProject + EditProject; DetailsProject mostrar nombre de catálogo si hay FK
  - UI: combo “Plantilla del catálogo” (solo `activo`) **o** file input (mutuamente claros, RNF-06). Si hay combo, el file no es obligatorio
  - POST: si viene `id_plantilla_catalogo`, copiar `nombre_archivo` → `plantilla_contrato` y validar que siga activa. Si viene archivo, flujo actual y FK null
  - Criterio de completitud: dos productos pueden usar la misma plantilla; carga directa sigue funcionando; combo no lista inactivas

### Fase 4 — Validación (P1)

- [ ] **T-07** — Generar un contrato PDF con producto asociado al catálogo (S3/disco)
- [ ] **T-08** — Inactivar plantilla en uso: combo ya no la ofrece; el contrato **sí** se genera. MX/CHL: feature presente, datos propios. AG intacto en carga directa

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `plantilla_contrato_catalogo` | Nueva | Metadata + `nombre_archivo` (GUID.docx). Auditoría usuario/fecha alta y modificación. `activo` bool. |
| `producto_proyecto` | Modificación | `id_plantilla_catalogo INT NULL` FK → catálogo. `plantilla_contrato` no se elimina. |

Correr el script en **cada** hub (COL primero si es el solicitante). No hay datos seed.

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| * | `/Catalogos/PlantillasContrato/*` | CRUD catálogo | Nuevo |
| POST | `/Catalogos/Productos/AddProject` | Acepta id de catálogo o file | Modificado |
| POST | `/Catalogos/Productos/EditProject` | Igual | Modificado |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| `Plantillas:ContratosPath` | Ya existe (disco) | todos |
| `FileStorage:Plantillas_contratos` | Ya existe (S3) | todos |
| `Plantillas:CatalogoMaxMb` | Tope de subida (default 15) | todos |

No hace falta bucket nuevo.

---

## 8. Consideraciones de seguridad

- Solo AG/Gestor escriben. Validar `.docx` por extensión **y** content-type; rechazar no-docx.
- No servir path traversal: guardar solo el GUID generado, nunca el nombre original como path.
- Inactivar ≠ borrar S3 (evita romper PDF).
- No cruzar archivos entre hubs.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- SQL en RDS de cada país. S3 y disco **los que ya usa** el producto.
- Desplegar SIGA Web. PDFGenerator solo si se cambiara la ruta (este plan **no** lo cambia).
- Tres hubs: mismo binario; catálogo vacío al arrancar en cada uno.

---

## 10. Criterios de aceptación

- [ ] **RF-01 / RNF-03:** Alta `.docx` + nombre + estatus; rechazo de otro formato / archivo enorme.
- [ ] **RF-02 / RF-10:** Listado; filtro; combo de producto solo activas.
- [ ] **RF-03 / RF-04:** Editar nombre/estatus; inactivar sin delete.
- [ ] **RF-05 / RF-07:** Un GUID de catálogo en N productos.
- [ ] **RF-06 / RNF-06:** Carga directa sigue; UI distingue selector vs file.
- [ ] **RF-08 / RNF-04:** Disco + S3 + fila en BD (mismo patrón actual).
- [ ] **RF-09 / RNF-07:** Feature en los tres menús; datos **no** compartidos entre BD.
- [ ] **RNF-01:** AG/Gestor; Auditor solo lectura.
- [ ] **RNF-02:** Quedan usuario y fecha de alta/edición.
- [ ] PDF de contrato con plantilla de catálogo se genera.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Interpretar RF-09 como una sola BD mundial | Alta | Alto | Catálogo por hub (T-02 en cada RDS) |
| Duplicar archivo al asociar ( infla S3) | Media | Bajo | Reusar GUID |
| Borrar S3 al inactivar | Media | Alto | Solo `activo=false` |
| No espejar DataAccessColombia | Alta | Alto | T-03 obligatorio |
| Tocar PDFGenerator innecesariamente | Media | Medio | Misma carpeta/filename |
| Productos adicionales olvidados | Baja | Bajo | Fuera de MVP; otra carpeta |

---

## 12. Notas para el programador

1. Rol de escritura: **`Administrador General`** y **`Gestor de Países`** (no inventar “Administrador SIGA”).
2. Espejar **siempre** `DataAccess` y `DataAccessColombia`.
3. Código nuevo en inglés; UI en español.
4. No mezclar con PJ6999 (plantillas de *resolución* de averías) ni con Documentos Adicionales.
5. No refactorizar `ProductosController` más de Add/Edit Project + ViewBag del combo.
6. El SQL debe existir en el hub **antes** de desplegar la Web.
7. Independiente de PJ2613 / PJ3976 / PJ1255.
8. No commitear `appsettings` locales; sí se puede añadir solo `Plantillas:CatalogoMaxMb`.

---

## 13. Relación de tareas y tiempos

Todo el PRD es **P1**.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama** | Rama feature | T-01 | 0.25 días | 145 |
| **Fase 1 — Persistencia (P1)** | SQL + EF MX/COL | T-02 a T-03 | 0.75 – 1.5 días | 146 |
| **Fase 2 — Catálogo UI (P1)** | CRUD + menú + S3 | T-04 a T-05 | 1.5 – 2.5 días | 147 |
| **Fase 3 — Producto (P1)** | Selector + fallback | T-06 | 0.75 – 1.5 días | 148 |
| **Fase 4 — Validación (P1)** | PDF + inactivar + hubs | T-07 a T-08 | 0.75 – 1.5 días | 149 |
| **Total proyecto (P1)** | | 8 tareas | ~4 – 7.25 días hábiles (≈ 1 – 1.5 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 a Fase 4 | T-01 a T-08 | ~4 – 7.25 días hábiles | — |

> La columna **ID (BD)** la llena el flujo al registrar el plan.

> **Riesgo de deadline:** el PRD no fija fecha. Un desarrollador cubre ~4–7 días. No hay recorte P2. Si aprieta, el selector en producto (T-06) es el valor; el catálogo solo no sirve sin asociar. El SQL en COL debe ir **antes** del deploy.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
