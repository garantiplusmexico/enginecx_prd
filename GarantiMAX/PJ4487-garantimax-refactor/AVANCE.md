# Registro de Avance — Reconstrucción de GarantiMAX · Fase 1: núcleo del Asesor Farmer

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Repositorio | `garantiplusmexico/siga_alfa` |
| Rama | `feature/PJ4487-garantimax-refactor-nucleo-asesor` |
| Responsable actual | Javier Antonio Oropeza Camacho |
| Folio PRD | PJ4487 |
| ID plan (BD) | `56` (`pm_plan_desarrollo.id`) |
| Modelo / esfuerzo | `claude-sonnet-5` — esfuerzo alto |
| Última actualización | 2026-08-25 |
| Estado general | 🟡 En progreso |

---

## Resumen de estado

Repositorio `siga_alfa` inicializado: ramas `main` (pendiente, ver nota), `develop`, `pre-qa`, `qa` creadas, y rama funcional `feature/PJ4487-garantimax-refactor-nucleo-asesor` abierta desde `develop`. T-01 y T-02 completadas: andamiaje base (Vite + React 19 + TypeScript + Tailwind v4) y árbol completo de `src/` según A1 §3, con `npx tsc -b` y `npm run build` en verde. Plan `56` marcado `En curso` en BD, Fase 0 (`id 193`) marcada `En progreso`. Siguiente tarea: T-03 (React Router, TanStack Query, Zustand — ADR-006).

> ⚠️ **Nota sobre `main`:** el repositorio tiene una regla de organización (`validate-main-source-branch`) que **bloquea cualquier push directo a `main`**, incluido el primer commit — solo acepta merges vía PR desde `release`. `main` **no existe todavía como rama** en el remoto (0 refs). Es consistente con `rules/version-control.md` ("main solo se actualiza desde release, nunca commits directos"), pero es más estricto que en otros repos Engine, donde el primer commit sí se sembró directo en `main` antes de aplicar la regla. `main` se creará más adelante, cuando exista una rama `release` y se abra el primer PR `release → main` (ver Fase 4, T-72). El workflow `validate-prod-source.yml` equivalente (visto en `gp_4.0_siga`/`gp_3.0_siga_api`) deberá añadirse al repo antes de ese primer PR — pendiente, no bloquea la Fase 0.

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Fundaciones, guardarraíles y extracción de reglas** | 193 | T-01 a T-19 | 30 – 40 | 2026-08-25 | | 0 | 30 – 40 | 🟡 En progreso |
| **Fase 1 — Núcleo verificable del asesor (P1)** | 194 | T-20 a T-43 | 40 – 52 | | | 0 | 40 – 52 | ⏳ Pendiente |
| **Fase 2 — Gestión del asesor (P2)** | 195 | T-44 a T-54 | 20 – 26 | | | 0 | 20 – 26 | ⏳ Pendiente |
| **Fase 3 — Gastos y rendiciones (P3)** | 196 | T-55 a T-61 | 20 – 27 | | | 0 | 20 – 27 | ⏳ Pendiente |
| **Fase 4 — Notificaciones, verificación, auditoría y corte** | 197 | T-62 a T-72 | 32 – 42 | | | 0 | 32 – 42 | ⏳ Pendiente |
| **Total proyecto (P1+P2+P3+cierre)** | — | 72 tareas | ~142 – 187 | 2026-08-25 | | 0 | ~142 – 187 | 🟡 En progreso |
| **Solo P1 (guardarraíl del PRD)** | — | T-01 a T-43 | ~70 – 92 | 2026-08-25 | | 0 | ~70 – 92 | 🟡 En progreso |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Crear el repositorio `siga_alfa` con la estructura de ramas Engine | Claude Code | 2026-08-25 | `develop`, `pre-qa`, `qa` creadas y en remoto. `main` pendiente — ver nota en "Resumen de estado". CODEOWNERS: `* @Javier-Oropeza`. Protección de `main` con 2 aprobaciones y bloqueo de commits directos a `develop` quedan a cargo del programador en la UI de GitHub |
| T-02 | Andamiaje base de la aplicación y estructura de carpetas de A1 §3 | Claude Code | 2026-08-25 | Árbol completo de `src/` (49 carpetas con `index.ts` marcador) + `package.json`, `vite.config.ts`, `tsconfig*`, `CLAUDE.md`. `npx tsc -b` y `npm run build` en verde; verificado además con dev server sirviendo HTTP 200. Sin script `lint` todavía (llega con `eslint.config.js` en T-09) |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| | | | | |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-03 | Instalar y configurar React Router, TanStack Query y Zustand (ADR-006) | |
| T-04 | Configuración tipada y validada al arranque | `VITE_SUPABASE_ANON_KEY` real de desarrollo pendiente (no bloquea T-04, sí el arranque real de la app) |
| T-05 | Jerarquía de errores tipificados y su traducción a mensajes | |
| T-06 | Contratos transversales (ports), sin implementación | |
| T-07 | Contenedor de composición de dependencias | |
| T-08 | Implementaciones de infraestructura transversal | |
| T-09 | Reglas de linter arquitectónicas (5 guardarraíles) | |
| T-10 | Script de métricas arquitectónicas y línea base | |
| T-11 | Integración continua | |
| T-12 | PWA instalable con shell offline | |
| T-13 | Extracción de reglas: Mi Día, visitas y lobbies | |
| T-14 | Extracción de reglas: tareas, agenda, cumpleaños y bitácora | |
| T-15 | Extracción de reglas: gastos, boletas y rendiciones | |
| T-16 | Extracción de reglas: identidad, capacidades, "Ver como" y modo demo | MCP de Supabase en lectura — pendiente de autorización del programador |
| T-17 | Línea base medida de las métricas de producto | MCP de Supabase (lectura) + medición manual en dispositivo/red real — pendiente |
| T-18 | Migraciones aditivas en el repositorio actual | |
| T-19 | Sistema de componentes base adaptativo | |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| | | | |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Repositorio nuevo = `garantiplusmexico/siga_alfa` (no `garantimax-app` como nombraba el plan generado) | Repo ya creado por el responsable con ese nombre, vacío, remoto `origin` configurado | Se actualizó `PLAN.md` (6 referencias) para reflejar el nombre real |
| Plan pasado a estado `Validado` en el encabezado del `PLAN.md` | El responsable confirmó haberlo revisado y lo autorizó a arrancar | Ninguno funcional — es el semáforo de que el plan ya no es borrador |
| Idioma del código ratificado: español en el dominio, inglés en lo técnico transversal | Recomendación del propio plan (§12), ratificada por el responsable el 2026-08-25 sin cambios | Se documenta también en el `CLAUDE.md` que crea T-02 |
| Modelo de ejecución: `claude-sonnet-5`, esfuerzo alto, para toda la Fase 0 (a reevaluar al entrar a Fase 1) | Decisión del responsable frente a la recomendación mixta (Opus solo para T-13…T-16/T-05/T-06/T-07/T-09); prioriza simplicidad de trazabilidad sobre el ahorro de costo de una mezcla de modelos | Todos los commits de la Fase 0 registran `claude-sonnet-5 — esfuerzo alto` |
| `main` no se siembra en T-01; queda para el primer PR `release → main` en Fase 4 | Regla de organización `validate-main-source-branch` rechaza cualquier push directo a `main`, incluido el primero — no hay forma de rodearla sin tocar el ruleset de GitHub, que es del responsable/TI | El criterio de completitud de T-01 ("existen main, develop, pre-qa, qa") se interpreta como: las 3 ramas de trabajo existen; `main` existe como convención/regla de la organización aunque su primer commit real llegue en el corte |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `README.md` (siga_alfa) | Creado | T-01 |
| `.gitignore` (siga_alfa) | Creado | T-01 |
| `.github/CODEOWNERS` (siga_alfa) | Creado | T-01 |
| `enginecx_prd/GarantiMAX/PJ4487-garantimax-refactor/PLAN.md` | Modificado (nombre de repo, estado, ratificación de idioma) | T-01 (previo a la ejecución) |
| `enginecx_prd/GarantiMAX/PJ4487-garantimax-refactor/AVANCE.md` | Creado | T-01 |
| `src/` (siga_alfa) — 49 carpetas con `index.ts`/`index.tsx` marcador, según A1 §3 | Creado | T-02 |
| `package.json`, `package-lock.json`, `vite.config.ts`, `tsconfig.json`, `tsconfig.app.json`, `tsconfig.node.json`, `index.html` (siga_alfa) | Creado | T-02 |
| `src/main.tsx`, `src/app/App.tsx`, `src/app/container.ts`, `src/index.css`, `src/vite-env.d.ts` (siga_alfa) | Creado | T-02 |
| `CLAUDE.md`, `.env.example` (siga_alfa) | Creado | T-02 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `e4ec22e` (siga_alfa) | Andamiaje inicial del repositorio (T-01) | 2026-08-25 |
| `ad4ce83` (siga_alfa) | Andamiaje base de la aplicación y estructura de A1 §3 (T-02) | 2026-08-25 |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** T-03, instalar y configurar React Router, TanStack Query y Zustand (ADR-006). Rama activa: `feature/PJ4487-garantimax-refactor-nucleo-asesor`, ya en el remoto.
- **Contexto importante:**
  - No dupliques `supabase/` en `siga_alfa` — migraciones y Edge Functions siguen viviendo en el repo actual (`garantiplus-dashboard`).
  - `main` de `siga_alfa` no existe aún — no intentar sembrarlo directo, ver nota en "Resumen de estado".
  - `VITE_SUPABASE_ANON_KEY` real todavía no está disponible en esta máquina; T-04 se implementa y prueba con valores de configuración (reales o de relleno), la clave real solo se necesita al llegar a T-20.
  - MCP de Supabase (lectura) sigue sin autorizar en esta sesión — se necesita antes de T-16 y T-17.
- **Decisiones pendientes que requieren input del responsable:** ninguna bloquea la continuación de T-02 en adelante dentro de la Fase 0.

---

*Actualizado automáticamente por Claude Code — Engine CX*
