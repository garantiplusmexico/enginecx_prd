# Plan de Desarrollo — Gerentes Comerciales — Consulta de Averías

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ8394-gerentes-comerciales-averias/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb) |
| Rama | `feature/PJ8394-gerentes-comerciales-averias-consulta` |
| Tipo | Feature sobre proyecto existente |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ8394` |
| Fecha de generación | 2026-07-24 |
| Rama base | `develop` (actualizada con `git pull`) |
| Estado | Borrador |
| ID plan (BD) | *(pm_plan_desarrollo.id — lo escribe el flujo al registrar el plan)* |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal |

---

## 1. Resumen técnico

Habilitar (y **cerrar en modo lectura**) la consulta de averías para el rol **Gerente Comercial** en SIGA Web (México). El módulo `AveriasController` y el filtro por `usuario_distribuidor` **ya existen**; el menú Averías **ya incluye** al rol. El trabajo real no es “abrir todo”, sino **auditar la matriz de permisos**, **completar huecos de lectura** si aparecen, y **restringir explícitamente** escritura (aprobación, carga de documentos) y export.

**Hallazgos del análisis sobre `develop` (2026-07-24):**

| Capacidad | Estado actual para Gerente Comercial |
|---|---|
| `[Authorize]` a nivel de clase en `AveriasController` | Incluido |
| `Index`, `ListadoRegistradas`, `ListadoCerradas` | Autorizados; filtro `usuario_distribuidor` aplicado |
| `Details` | Autorizado; filtro por distribuidores del usuario |
| `Edit` (GET) | Redirige a `Details` (lectura) |
| Menú Averías (`_LeftMenuBar_MEX`, `_NavigationGPMX`) | Ya incluye el rol |
| Tabs “Sin atender / taller” (`Listado48hrs`, `ListadoTaller`) | `[Authorize]` **excluye** al rol; tabs ocultas en `Index` — correcto |
| `ExportaAveriasActivas` / `ExportaAveriasCerradas` | **Aún autorizados** + botón “Descargar” visible en listados |
| `Aprobacion` | Autorizado (necesario: `Details` redirige si estatus 12/13) |
| `AprobarRechazarAveria` | Sin rol; gate por emails `AutorizacionAverias` — riesgo si el email del GC está en la lista |
| `AddFiles` / `DeleteFile` / observaciones / otras escrituras | Heredan auth de clase → el rol **puede invocar** el endpoint aunque la UI no lo muestre |
| `DownloadFile` / `Documentos` | Lectura sin filtro de distribuidor en descarga → riesgo de fuga por ID |

- **Arquitectura:** sin cambio. Feature sobre SIGA Web monolítico (EC2 + .NET 8 + Razor/jQuery). Ver `rules/arquitectura.md` §5.
- **Stack:** el existente (C#/.NET 8, Razor, PostgreSQL). No hay API nueva ni despliegue ECS.
- **BD / env:** sin migraciones ni variables nuevas.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable
- [ ] Acceso de escritura al repo `gp_4.0_siga`
- [ ] Usuario de prueba con rol **Gerente Comercial** y filas en `usuario_distribuidor` (QA/dev)
- [ ] Averías de prueba pertenecientes a sus distribuidores y al menos una de otro distribuidor (para probar aislamiento)
- [ ] Avería en estatus 12/13 (para validar redirección a `Aprobacion` en solo lectura)
- [ ] `CLAUDE.md` presente en el repositorio ✅

---

## 3. Arquitectura del cambio

Sin componentes nuevos. Solo permisos, UI y endurecimiento de endpoints existentes.

```
[Gerente Comercial] → Login (ASP.NET Identity)
        │
        ├── Menú Averías (ya visible) → Index
        │         ├── Listado Activas/Cerradas  → filtro usuario_distribuidor
        │         └── (sin tabs 48hrs / taller; sin Export)
        │
        └── Details / Aprobacion (lectura)
                  ├── estatus, historial, adjuntos (DownloadFile acotado)
                  └── escritura bloqueada (Approve / AddFiles / Export → 403)
```

**País:** el PRD es Garantiplus México. `AveriasController` es compartido entre países; los cambios de autorización aplican al controller. La verificación de menú se centra en `_LeftMenuBar_MEX` / `_NavigationGPMX` (COL/CHL ya listan el rol en Averías; no se amplía alcance a menos que se pida).

---

## 4. Tareas de desarrollo

### Fase 0 — Auditoría y matriz de permisos (P1)

- [ ] **T-01** — Inventariar acciones de `AveriasController` y clasificarlas como Lectura / Escritura / Export
  - Archivos: `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` (análisis; documento en §12 o comentario en el plan)
  - Criterio: matriz completa (acción → `[Authorize]` actual → tratamiento para Gerente Comercial: permitir / denegar / solo lectura)

- [ ] **T-02** — Verificar menú Averías para Gerente Comercial (Remake MEX + navegación legacy)
  - Archivos: `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_MEX.cshtml`, `GarantiplusWeb/Views/Shared/_NavigationGPMX.cshtml`
  - Criterio: con usuario GC se ve “Averías → Listado”; no se muestran catálogos (Técnicos, Talleres, etc.). Si ya cumple, marcar verificado sin cambio.

### Fase 1 — Lectura segura + bloqueo de escritura/export (P1)

- [ ] **T-03** — Quitar Gerente Comercial de export y ocultar UI de descarga
  - Archivos a modificar:
    - `AveriasController.cs` — `[Authorize]` de `ExportaAveriasActivas` y `ExportaAveriasCerradas` (quitar `Gerente Comercial`)
    - `Areas/Averias/Views/Averias/_ListadoAbiertas.cshtml`, `_ListadoCerradas.cshtml` (+ variantes Mitsu si aplica) — excluir GC del bloque del `export-button`
  - Criterio: GC no ve “Descargar”; POST a export responde 403

- [ ] **T-04** — Bloquear endpoints de escritura para Gerente Comercial
  - Archivos: `AveriasController.cs`
  - Acciones mínimas a restringir (quitar GC del auth de método o añadir deny explícito al inicio): `AddFiles`, `DeleteFile`, `CreateObs` / `CreateObsAgencia` / `ObsToDealer`, `AprobarRechazarAveria`, y cualquier otra de la matriz T-01 marcada Escritura que herede auth de clase
  - Criterio: POST con rol GC → 403/JSON de no autorización; sin modificar datos

- [ ] **T-05** — Vista detalle / aprobación en modo lectura para Gerente Comercial
  - Archivos: `Areas/Averias/Views/Averias/Details.cshtml`, `Aprobacion.cshtml`, parciales de edición/documentos usados ahí (`_Edit.cshtml` si aplica vía otras rutas)
  - Tratar GC como rol de solo consulta (análogo a `Usuario Distribuidor` donde corresponda): sin botones de aprobar/rechazar, sin carga/eliminación de documentos, sin formularios de escritura
  - Criterio: en estatus normales y en 12/13, GC ve información (estatus, historial, adjuntos) sin controles de modificación

- [ ] **T-06** — Aislar descarga de documentos por distribuidor
  - Archivos: `AveriasController.cs` — `DownloadFile`, y si aplica `DownloadAllDocuments` / `Documentos`
  - Criterio: GC solo descarga adjuntos de averías cuyo `id_distribuidor` esté en su `usuario_distribuidor`; ID ajeno → 404/403

- [ ] **T-07** — Confirmar filtro `usuario_distribuidor` en listado y detalle (sin regresiones)
  - Archivos: mismos bloques ya existentes en `ListadoRegistradas`, `ListadoCerradas`, `Details`, `Aprobacion`
  - Criterio: listado solo muestra averías de sus distribuidores; detalle de avería ajena → NotFound. Si el filtro ya es correcto, documentar y no tocar lógica salvo bugs encontrados.

### Fase 2 — Validación funcional (P1)

- [ ] **T-08** — Checklist de aceptación manual con usuario GC de prueba
  - Criterio: todos los ítems de §10 marcados; sin regresiones para Tecnico / Usuario Distribuidor / Coordinador Tecnicos en smoke breve

---

## 5. Cambios en base de datos

No aplica. El rol “Gerente Comercial” y `usuario_distribuidor` ya existen. Sin migraciones ni seeds.

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | — | Sin cambios de esquema |

---

## 6. Endpoints nuevos o modificados

No hay endpoints REST nuevos (SIGA Web MVC). Acciones MVC afectadas:

| Método | Acción | Descripción | Estado |
|---|---|---|---|
| POST | `ExportaAveriasActivas` / `ExportaAveriasCerradas` | Quitar rol Gerente Comercial | Modificado |
| POST | `AddFiles`, `DeleteFile`, obs., `AprobarRechazarAveria`, … | Denegar Gerente Comercial | Modificado |
| GET | `DownloadFile` (+ zip/docs si aplica) | Filtro por distribuidores del GC | Modificado |
| GET | `Index`, `Details`, `Aprobacion`, listados | Verificar / mantener lectura + filtro | Verificado |

---

## 7. Variables de entorno y configuración

Ninguna nueva. Revisar que el email del usuario GC de prueba **no** esté en `AutorizacionAverias:{pais}` (si estuviera, T-04 debe denegar por rol antes del gate de email).

| Variable | Descripción | Ambiente |
|---|---|---|
| — | Sin cambios | — |

---

## 8. Consideraciones de seguridad

- Principio de mínimo privilegio: GC = **solo lectura** de averías de **sus** distribuidores.
- Defensa en profundidad: ocultar UI **y** denegar en servidor (no confiar en ocultar botones).
- `AprobarRechazarAveria` hoy solo valida email en config → T-04 debe denegar por rol para GC.
- `DownloadFile` sin filtro de ownership → T-06 obligatorio (fuga por ID enumerable).
- Sin secrets nuevos; sin cambios IAM/AWS.

---

## 9. Consideraciones de infraestructura

Ninguna. Despliegue = release habitual de SIGA Web en EC2. Sin ECS/RDS/S3/Cloudflare nuevos.

---

## 10. Criterios de aceptación

- [ ] RF-01: GC accede a listado y detalle de averías
- [ ] RF-02: menú muestra Averías para GC
- [ ] RF-03: listado solo con averías de sus clientes (`usuario_distribuidor`)
- [ ] RF-04: detalle en solo lectura (estatus, historial, adjuntos visibles; sin edición)
- [ ] RF-05: GC no puede aprobar, cargar/eliminar documentos ni exportar (UI + HTTP)
- [ ] RNF-02: detalle/descarga de avería ajena denegados
- [ ] Sin regresión evidente en roles Tecnico, Coordinador Tecnicos, Usuario Distribuidor

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Endpoints de escritura heredan auth de clase y quedan abiertos | Alta | Alto | T-01 + T-04 exhaustivos |
| `DownloadFile` sin ownership | Media | Alto | T-06 |
| Email GC en `AutorizacionAverias` habilita aprobar | Baja | Alto | Deny por rol en T-04; revisar config en prueba |
| Cambios en vistas rompen UI de otros roles | Media | Medio | Condicionar solo `Gerente Comercial`; smoke T-08 |
| PRD asume “~15% faltante de consulta” pero el gap real es restricción | — | — | Plan prioriza cierre de escritura/export; habilitación de menú/lectura se verifica, no se reescribe |

---

## 12. Notas para el programador

1. **No refactorizar** `AveriasController` completo (~4k líneas). Solo atributos `[Authorize]`, guards al inicio de acciones y condiciones `IsInRole` en vistas.
2. **Preguntas abiertas del PRD (§14) resueltas en análisis:**
   - El “~15%” no es un bloque único de consulta faltante: Index/Details/listados principales ya están; el gap es **export + escritura heredada + descarga sin filtro**.
   - Adjuntos: `DownloadFile` usa S3/local con auth de clase; requiere **ownership check**, no cambio de bucket.
3. Mantener `Aprobacion` accesible en lectura (redirect desde `Details` en estatus 12/13); solo bloquear botones y `AprobarRechazarAveria`.
4. Export queda **fuera de MVP** (PRD §6); se bloquea ahora y se podrá reabrir en fase posterior.
5. Alcance país: México. Si en ejecución se detecta menú MEX distinto al Remake, ajustar el archivo que realmente renderiza el sidebar en el ambiente.
6. Regla anti-refactor Engine: no normalizar namespaces ni “limpiar” el controller.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Auditoría y menú (P1)** | Matriz de permisos + verificación de navegación | T-01 a T-02 | 0.5 – 1 día | |
| **Fase 1 — Lectura segura + bloqueos (P1)** | Export off, deny escritura, UI read-only, filtro descarga, confirmar filtro listado/detalle | T-03 a T-07 | 1.5 – 2.5 días | |
| **Fase 2 — Validación (P1)** | Checklist aceptación + smoke otros roles | T-08 | 0.5 – 1 día | |
| **Total proyecto (P1)** | | 8 tareas | ~2.5 – 4.5 días hábiles (≈ 0.5 – 1 semana) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 | T-01 a T-08 | ~2.5 – 4.5 días hábiles (≈ 0.5 – 1 semana) | — |

> **Notas:** alcance completo = P1 (no hay P2/P3 en el PRD; export queda diferido). Sin fecha límite en el PRD.
>
> **Riesgo de deadline:** no hay deadline declarado. Con un desarrollador el MVP cabe en menos de una semana hábil. No se requiere segundo recurso salvo bloqueos de ambiente/datos de prueba.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
