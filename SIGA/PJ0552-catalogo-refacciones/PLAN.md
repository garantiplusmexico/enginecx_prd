# Plan de Desarrollo — Catálogo de Refacciones (PJ0552)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ0552-catalogo-refacciones/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb) |
| Rama base | `develop` |
| Rama | `feature/PJ0552-catalogo-refacciones-mantenimiento` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ0552` |
| Fecha de generación | 2026-07-23 |
| Estado | Borrador |
| ID plan (BD) | *(pm_plan_desarrollo.id — lo escribe el flujo al registrar el plan)* |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Extender el CRUD existente de refacciones en **SIGA Web** (`GarantiplusWeb`, Area Averías) para que el área operativa autorizada mantenga el catálogo de forma autónoma: alta/edición individual reforzada, **carga masiva por Excel** (carga parcial + reporte de rechazos) y **validación de impacto** sobre la relación refacción↔producto (permitidas / no permitidas).

- **Arquitectura:** modificación sobre monolito existente SIGA Web (EC2 + .NET 8 + Razor/MVC). No se crea microservicio nuevo ni API externa.
- **Stack:** .NET 8 / C#, Razor Pages + MVC Areas, jQuery/DataTables, PostgreSQL (RDS), EPPlus (`OfficeOpenXml`) ya referenciado en el proyecto.
- **Base reutilizable:** `RefaccionesController`, `RefaccionesBusinessRules`, entidades `refaccion`, `refaccion_permitida_producto`, `refaccion_no_permitida_amplia`; patrón de importación Excel en `Catalogos/Autos.cs` (`CargarAutos`).
- **Sin servicios externos.** Todo dentro de SIGA México.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante (Alexis Salvador Herrera García)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] **Confirmar con operación el rol SIGA autorizado** para crear/editar (pregunta abierta del PRD §13)
- [ ] **Definir plantilla Excel** (columnas, reglas de duplicado, si incluye relaciones producto)
- [ ] Ambiente local apuntando a BD México con datos de refacciones / productos de prueba
- [ ] No se requieren secrets nuevos ni variables de entorno nuevas para el MVP (salvo path opcional de plantilla/temp si se decide configurar)

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature sobre componente existente, sin desplegar servicio nuevo.

```
[Usuario operativo] 
    → [GarantiplusWeb / Areas/Averias/RefaccionesController]
        → [RefaccionesBusinessRules / AveriasBusinessRules]
            → [GarantiplusRepository / EF Core]
                → [PostgreSQL: refaccion, refaccion_permitida_producto, refaccion_no_permitida_amplia]
```

**Carga masiva:**

```
[Excel .xlsx] → [Parse EPPlus fila a fila] → [Validar rol]
  → [Validar campos + duplicados + relación producto]
  → filas OK → Create/Update en BD
  → filas KO → acumular motivo → [Reporte en pantalla / Excel de rechazos]
```

**Decisión de diseño:** la lógica de validación y persistencia de la carga masiva vive en `AveriasBusinessRules` (o clase parcial nueva bajo el mismo ensamblado), no duplicada en el controller. El controller solo orquesta HTTP/UI. Se extiende `RefaccionesController`; no se crea un segundo CRUD.

---

## 4. Tareas de desarrollo

### Fase 0 — Alineación funcional y modelo real (P1)

- [ ] **T-01** — Resolver preguntas abiertas del PRD contra código y operación
  - Confirmar rol(es) autorizados para escritura (hoy el controller permite: `Administrador General`, `Administrador General Externo`, `Gestor de Países`, `Auditor`, `Coordinador Tecnicos` en Create/Edit; Index ya oculta botones a Auditor).
  - Confirmar campos Excel y regla de duplicados (por `nombre_refaccion` normalizado vs. `id_refaccion` en actualización).
  - Confirmar alcance de RF-06: ¿solo validar que no se rompan FKs/relaciones existentes, o también alta de vínculos producto en la misma carga?
  - Archivos a crear/modificar: nota en `PLAN.md` / `AVANCE.md` (sin código aún)
  - Criterio de completitud: respuestas documentadas en §12 de este plan o en AVANCE; sin bloqueos abiertos para Fase 1–2

- [ ] **T-02** — Documentar modelo de datos real de `refaccion` y relaciones
  - Campos actuales: `id_refaccion`, `nombre_refaccion`, `codigo_pais`, `codigo_moneda`, `precio_minimo`, `precio_maximo`, `consumible` (0/1); N:M vía `refaccion_permitida_producto` (cobertura limitada) y `refaccion_no_permitida_amplia` (cobertura amplia)
  - Archivos a revisar: `DataAccess/Models/refaccion.cs`, controllers Permitidas/NoPermitidas
  - Criterio de completitud: plantilla Excel propuesta (columnas + ejemplo) acordada con solicitante

### Fase 1 — Permisos, alta/edición individual y validación producto (P1)

- [ ] **T-03** — Ajustar control de acceso lectura vs. escritura
  - Separar roles de consulta (Index/Listado/Details/Exportar) de roles de Create/Edit (y de carga masiva)
  - `Auditor` y perfiles no autorizados: solo consulta; sin botón Registrar / Cargar / eliminar en UI
  - Archivos: `RefaccionesController.cs`, `Views/Refacciones/Index.cshtml`, Create/Edit views si aplica
  - Criterio de completitud: usuario sin rol de escritura recibe 403 en POST Create/Edit/Import; ve listado si tiene rol de lectura

- [ ] **T-04** — Endurecer alta/edición individual (RF-01, RF-02, RF-06)
  - Validaciones de negocio: nombre obligatorio, rangos de precio (`precio_minimo` ≤ `precio_maximo` si ambos vienen), `consumible` ∈ {0,1}, `codigo_pais`/`codigo_moneda` del proyecto actual
  - Duplicados: rechazar alta con mismo nombre normalizado en el mismo `codigo_pais` (regla a confirmar en T-01)
  - Al editar: si la refacción tiene relaciones producto, validar que el cambio no deje inconsistencias (p. ej. no permitir operaciones que orphanen FKs; rechazar si se intenta estado inválido)
  - Preferir usar `RefaccionesBusinessRules` en lugar de repositorio directo en el controller donde sea viable sin refactor amplio
  - Archivos: `RefaccionesController.cs`, `RefaccionesBusinessRules.cs` (+ interfaz si existe), vistas `_Edit.cshtml` / Create / Edit
  - Criterio de completitud: Create/Edit individual pasan validaciones; mensajes de error claros en español para el usuario

- [ ] **T-05** — Validación explícita refacción ↔ producto en individual
  - Método de negocio que, dado un `id_refaccion` (y opcionalmente productos del Excel/form), verifique consistencia con `refaccion_permitida_producto` / `refaccion_no_permitida_amplia` y existencia de `producto`
  - Si el MVP no incluye asignación de productos en el form individual, al menos: al guardar, comprobar que las relaciones existentes siguen resolviendo (producto vigente) y reportar conflicto
  - Archivos: `AveriasBusinessRules/.../RefaccionesBusinessRules.cs`, posible clase helper de validación
  - Criterio de completitud: caso de prueba manual con refacción ligada a producto; conflicto rechazado con mensaje entendible

### Fase 2 — Carga masiva Excel (P1 / núcleo del MVP)

- [ ] **T-06** — Definir e implementar plantilla Excel + descarga
  - Endpoint GET para descargar plantilla (headers + fila ejemplo)
  - Columnas mínimas propuestas (ajustables en T-01): `id_refaccion` (vacío=alta / con valor=edición), `nombre_refaccion`, `precio_minimo`, `precio_maximo`, `consumible` (0|1 o texto), y si aplica columnas de producto (`id_producto`, `tipo_relacion` permitida|no_permitida)
  - Archivos: `RefaccionesController.cs`, vista Index (botón Descargar plantilla), posible recurso estático
  - Criterio de completitud: usuario autorizado descarga `.xlsx` usable en Excel

- [ ] **T-07** — Parser y validación fila a fila (RF-03, RNF-02, RNF-03)
  - POST multipart: leer con EPPlus; no abortar el lote por error de una fila
  - Motivos de rechazo tipados: vacío, formato inválido, duplicado, producto inexistente, conflicto relación, sin permiso (ya filtrado antes)
  - Archivos: servicio/reglas en AveriasBusinessRules; DTOs internos (p. ej. `SpareBulkRowResult`)
  - Criterio de completitud: archivo de prueba con filas mixtas produce N OK / M rechazadas sin excepción no controlada

- [ ] **T-08** — Persistencia parcial + reporte de resultado (RF-04, RNF-04)
  - Aplicar solo filas válidas (alta o update)
  - UI: resumen “X cargadas / Y rechazadas” + tabla o descarga Excel de rechazos con columna Motivo
  - Archivos: `RefaccionesController.cs`, nueva vista parcial o modal en Index, posible `ExportarRechazos`
  - Criterio de completitud: operador no técnico entiende qué falló y por qué; filas OK visibles en el listado

- [ ] **T-09** — Integrar validación producto en el flujo masivo (RF-06)
  - Misma regla que T-05 aplicada por fila antes de persistir
  - Archivos: reglas de T-05/T-07
  - Criterio de completitud: fila con producto inválido o relación inconsistente va a rechazados; no se escribe en BD

### Fase 3 — UI, eliminación fuera de alcance y cierre

- [ ] **T-10** — Ajustes de UI en Index (botones Cargar Excel / Plantilla; mensajes)
  - Reutilizar estilo de `action-button` / cards existente
  - Ocultar acciones de escritura según rol (alineado a T-03)
  - Archivos: `Views/Refacciones/Index.cshtml`, Create/Edit si hace falta
  - Criterio de completitud: flujo operable end-to-end desde el menú Averías → Refacciones

- [ ] **T-11** — Alinear eliminación con fuera de alcance del PRD
  - PRD: no eliminación física como parte del MVP / no romper históricos
  - Acción: restringir `Delete` a roles TI (p. ej. solo `Administrador General`) o deshabilitar en UI operativa; no implementar soft-delete en este MVP
  - Archivos: `RefaccionesController.Delete`, Index (columna delete)
  - Criterio de completitud: área operativa no puede borrar; históricos de averías no se rompen por uso normal del catálogo

- [ ] **T-12** — Pruebas manuales y checklist de aceptación
  - Matriz: rol autorizado / no autorizado; alta; edición; Excel 100% OK; Excel mixto; Excel con conflicto producto; duplicados
  - Criterio de completitud: todos los criterios de la §10 marcados; hallazgos críticos cerrados

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `refaccion` | Sin cambio de esquema (esperado) | Se reutiliza el modelo actual |
| `refaccion_permitida_producto` | Sin cambio (esperado) | Validación / posible escritura de vínculos solo si T-01 lo confirma |
| `refaccion_no_permitida_amplia` | Sin cambio (esperado) | Igual que arriba |

> Si T-01 exige auditoría de cargas (bitácora), queda **fuera de alcance MVP** (PRD §6). No crear tablas nuevas salvo decisión explícita del programador.

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/Averias/Refacciones` | Listado (permisos lectura) | Modificado |
| POST | `/Averias/Refacciones/Listado` | DataTables | Modificado (auth lectura) |
| GET/POST | `/Averias/Refacciones/Create` | Alta individual | Modificado (validaciones + roles escritura) |
| GET/POST | `/Averias/Refacciones/Edit/{id}` | Edición individual | Modificado |
| POST | `/Averias/Refacciones/Delete/{id}` | Eliminar | Modificado (restringir / alinear PRD) |
| GET | `/Averias/Refacciones/DescargarPlantilla` | Plantilla Excel | **Nuevo** |
| POST | `/Averias/Refacciones/CargarMasiva` | Import Excel parcial + reporte | **Nuevo** |
| GET/POST | `/Averias/Refacciones/Exportar` | Export existente | Sin cambio funcional relevante |

> No son APIs REST versionadas: son acciones MVC del Area Averías (patrón SIGA Web).

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| *(ninguna nueva obligatoria)* | EPPlus y connection string ya existen | — |
| `ImportarRefacciones:MaxFileSizeMb` (opcional) | Tope de tamaño de Excel | Desarrollo / QA / Prod |
| `ImportarRefacciones:MaxRows` (opcional) | Tope de filas por carga | Desarrollo / QA / Prod |

Secrets: no aplica. Connection string sigue en configuración existente (nunca hardcodear).

---

## 8. Consideraciones de seguridad

- Autorización por roles ASP.NET Identity ya usada en SIGA; no crear roles nuevos (PRD §6)
- Separar lectura/escritura; `Administrador General` con acceso total
- Validar AntiForgeryToken en POSTs de Create/Edit/Carga
- Validar tipo/contenido del archivo (`.xlsx`), tamaño máximo y número de filas
- No ejecutar fórmulas peligrosas: leer valores de celdas, no macros
- No registrar datos personales sensibles en logs (el catálogo no es PII, pero evitar dumps de archivos completos)

---

## 9. Consideraciones de infraestructura *(si aplica)*

- **Sin recursos AWS nuevos.** El cambio vive en SIGA Web (EC2 existente).
- Sin cambios en ECS, RDS schema (esperado), S3, Cloudflare o Route 53.
- Despliegue: pipeline/proceso habitual de SIGA Web México.

---

## 10. Criterios de aceptación

- [ ] Rol autorizado puede crear una refacción nueva desde la UI (RF-01)
- [ ] Rol autorizado puede editar una refacción existente (RF-02)
- [ ] Rol no autorizado solo consulta; Create/Edit/Carga responden 403 o UI sin acciones (RF-05, RNF-01)
- [ ] Carga Excel aplica filas válidas y omite inválidas/duplicadas (RF-03, RNF-02)
- [ ] Al terminar la carga se muestra total cargadas + detalle/motivo de rechazadas (RF-04, RNF-03, RNF-04)
- [ ] Alta/edición individual y masiva validan impacto en relación refacción↔producto y rechazan inconsistencias (RF-06)
- [ ] No se introduce eliminación física operativa que rompa históricos (alineado a fuera de alcance)
- [ ] Se reutiliza `RefaccionesController` / reglas existentes sin CRUD paralelo (RNF-05)
- [ ] Código nuevo en inglés; mensajes de usuario en español (`coding-guidelines.md`)

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Rol autorizado no definido / mal asignado | Alta | Alto | T-01 bloqueante; no liberar escritura amplia hasta confirmación de operación |
| Formato Excel indefinido retrasa adopción | Alta | Medio | Plantilla descargable + ejemplo; validar con Alexis antes de cerrar Fase 2 |
| Validación producto mal especificada (permitida vs no permitida) | Media | Alto | Documentar reglas en T-01; reutilizar controllers Permitidas/NoPermitidas como referencia de dominio |
| Carga masiva grande bloquea request HTTP | Media | Medio | Tope de filas; procesar en request síncrono acotado; si crece, diferir a job (fuera de MVP) |
| Delete actual rompe históricos si operación lo usa | Media | Alto | T-11 restringe delete; no exponer a rol operativo |
| Duplicar lógica vs. Autos.CargarAutos | Baja | Medio | Extraer patrón limpio en BusinessRules; no copiar Console.WriteLine / rutas hardcodeadas |

---

## 12. Notas para el programador

1. **Preguntas abiertas del PRD (deben cerrarse en T-01):**
   - ¿Qué rol exacto es “área autorizada”? Candidato probable por menú actual: `Coordinador Tecnicos` (+ admins). Confirmar con Alexis.
   - ¿Duplicado = mismo `nombre_refaccion` (case-insensitive, trim) por país, o solo por `id_refaccion`?
   - ¿La carga masiva solo mantiene el catálogo `refaccion`, o también escribe en `refaccion_permitida_producto` / `refaccion_no_permitida_amplia`?
   - Consumidores en averías: rol pendiente; no bloquea MVP de mantenimiento.

2. **Estado actual del código (hallazgos al planear):**
   - CRUD y export Excel ya existen; **falta import** y endurecer validaciones/permisos.
   - Create/Edit hoy usan repositorio directo en el controller; `RefaccionesBusinessRules` ya tiene `AddSpare`/`UpdateSpare` poco usados desde este controller.
   - Index ya diferencia UI para Auditor (sin botón registrar).

3. **No refactorizar** el Area Averías completa ni migrar a API de SIGA; solo el alcance del PRD.

4. **País:** feature orientada a Garantiplus México; respetar `codigo_pais` del proyecto actual (multi-país del monorepo).

5. **Fuera de alcance explícito:** auditoría/bitácora de cargas, soft-delete, reportes BI, nuevos roles, limpieza masiva del catálogo histórico.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Alineación (P1)** | Cierre de rol, plantilla Excel, alcance RF-06 | T-01 a T-02 | 1 – 2 días | |
| **Fase 1 — Permisos + CRUD individual (P1)** | Roles lectura/escritura, validaciones, relación producto | T-03 a T-05 | 2 – 3 días | |
| **Fase 2 — Carga masiva Excel (P1)** | Plantilla, parseo, carga parcial, reporte, validación producto | T-06 a T-09 | 3 – 5 días | |
| **Fase 3 — UI y cierre** | Botones, restricción delete, pruebas aceptación | T-10 a T-12 | 1 – 2 días | |
| **Total proyecto (P1 completo)** | Entrega única del MVP | 12 tareas | **~7 – 12 días hábiles (≈ 1.5 – 2.5 semanas)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 (núcleo MVP); Fase 3 es cierre del mismo P1 | T-01 a T-09 (+ T-10–12 recomendadas) | **~7 – 12 días hábiles** | — |

> El PRD declara **entrega única sin fases de producto** y **sin fecha límite**. Toda la funcionalidad MVP es P1; las “fases” anteriores son solo desglose técnico de ejecución.
>
> **Riesgo de deadline:** no hay fecha límite en el PRD. Con un desarrollador, el rango realista es **7–12 días hábiles**. El mayor riesgo de desvío es T-01 (rol + plantilla + alcance de relación producto). Si operación tarda en responder, Fase 0 puede alargar el calendario sin avance de código. Un segundo desarrollador en paralelo aportaría poca compresión (UI vs. reglas comparten el mismo cuello de botella de dominio); priorizar cerrar T-01 antes de paralelizar.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
