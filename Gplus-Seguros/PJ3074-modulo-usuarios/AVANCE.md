# Registro de Avance — Módulo de Usuarios (filtrado por campo + rol en listado)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan.
> Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/ModuloUsuarios` (en `gp_seguros` y en `frontend-omega`) |
| Responsable actual | Alexis Salvador Herrera Garcia |
| Folio PRD | `PJ3074` |
| ID plan (BD) | `65` |
| Modelo / esfuerzo | claude-opus-5 — esfuerzo: alto |
| Fecha de inicio | 2026-08-28 |
| Última actualización | 2026-08-28 |
| Estado general | 🟡 En progreso |

---

## Resumen de estado

Ejecución iniciada. Ramas `feature/ModuloUsuarios` creadas desde `develop` actualizado y publicadas
en el remoto de ambos repos. Plan marcado como `En curso` en la base de datos de PM.

Pendiente: las 4 fases del plan (15 tareas).

**Desviación acordada respecto al plan:** T-02 (verificar en BD que ningún usuario tiene más de un
rol) no se puede resolver con una consulta en vivo — la BD de pruebas (`192.168.1.65`,
`gp_seguros_test`) no es alcanzable desde la máquina del desarrollador y no hay cliente de
PostgreSQL instalado. Por indicación del responsable, la verificación se hace **contra las
construcciones de base de datos que ya existen en el backend** (mapeos EF Core del `omega_dbContext`
y la lógica de escritura de roles), no contra los datos. El SQL de confirmación queda documentado
para que se corra en QA cuando haya acceso.

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Contrato de API y validación** | 230 | T-01 a T-02 | 0.5 – 1 | | | 0 | 1 | ⏳ Pendiente |
| **Fase 1 — Backend `auth`** | 231 | T-03 a T-06 | 1 – 2 | | | 0 | 2 | ⏳ Pendiente |
| **Fase 2 — Frontend `frontend-omega`** | 232 | T-07 a T-12 | 1.5 – 2.5 | | | 0 | 3 | ⏳ Pendiente |
| **Fase 3 — Integración y entrega** | 233 | T-13 a T-15 | 1 – 1.5 | | | 0 | 2 | ⏳ Pendiente |
| **Total proyecto** | — | 15 tareas | ~4 – 7 | 2026-08-28 | | 0 | 7 | 🟡 En progreso |
| **Núcleo mínimo entregable** | — | T-01 a T-08 | ~2 – 3.5 | | | 0 | 4 | ⏳ Pendiente |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| — | *(ninguna aún)* | | | |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| — | *(ninguna aún)* | | | |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-01 | Congelar el contrato del DTO de listado | |
| T-02 | Verificar la cardinalidad usuario↔rol | Sin acceso a la BD — se resuelve contra el modelo del backend |
| T-03 | Crear el DTO de listado | |
| T-04 | Proyectar `UsuariosController.Get()` al DTO | T-03 |
| T-05 | Alinear `GetCount` a la misma proyección | T-03 |
| T-06 | Compilar y probar el microservicio `auth` | T-04, T-05 |
| T-07 | Cargar el catálogo de roles en el listado | |
| T-08 | Agregar la columna Rol al listado | T-04, T-07 |
| T-09 | Habilitar filtro en Nombre y Último ingreso | |
| T-10 | Convertir Bloqueado en filtro booleano | T-04 |
| T-11 | *(Opcional)* Columna Activo con filtro booleano | Decisión del responsable |
| T-12 | Lint del frontend | T-07 a T-11 |
| T-13 | Prueba de integración manual E2E contra QA | Despliegue a QA |
| T-14 | Verificar que el gateway no requiere cambios | |
| T-15 | Commits en ambos repos y entrega | |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| | | | |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| T-02 se resuelve contra el modelo del backend, no contra los datos | La BD de pruebas no es alcanzable desde la máquina del desarrollador; indicación explícita del responsable | La verificación es estructural, no empírica. El SQL queda documentado para correrse en QA |
| Ejecución en `claude-opus-5` en lugar de familia Sonnet | El workflow pide Sonnet, pero la sesión corre en Opus 5 y el cambio de modelo no es posible desde dentro; el responsable autorizó continuar | Sólo afecta la trazabilidad registrada en los commits |
| Versionado: frontend patch, backend menor | La convención real del frontend en sus últimos 8 releases es patch sobre `VUE_APP_VERSION`; el backend usa `serviceVersion` de dos partes y esto es una feature | Frontend `1.1.29 → 1.1.30`; `auth` `1.1 → 1.2` |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `gp_seguros/CLAUDE.md` | Restaurado desde la rama hermana | Prerequisito del flujo |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `b4775dd` | `[modulo-usuarios] Plan de desarrollo generado` (enginecx_prd) | 2026-08-28 |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** Fase 0, tarea T-01.
- **Contexto clave:** el corazón del cambio es aplanar el rol en el backend con una proyección a
  DTO (`usuario_listadoDTO`). Sin eso, ni el filtro, ni el orden, ni el conteo por rol son posibles
  con el mecanismo OData que usa el frontend. Ver §1 y §3 del `PLAN.md`.
- **Trampa conocida:** si se modifica `Get()` pero no `GetCount()`, los filtros nuevos devuelven 400
  y se rompe la paginación del listado. Van juntos (T-04 y T-05).
- **Decisión pendiente del responsable:** T-11 (columna Activo) es opcional.

---

*Actualizado automáticamente por Claude Code — Engine CX*
