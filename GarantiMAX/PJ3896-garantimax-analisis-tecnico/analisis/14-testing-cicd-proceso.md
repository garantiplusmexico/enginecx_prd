# 14 · Auditoría de testing, CI/CD y proceso

| Campo | Detalle |
|---|---|
| Capítulo | C13 |
| Requerimiento(s) | RF-15 |
| Etapa | A — T-19 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

---

## 1. Qué cubren realmente los 65 archivos de test

**Hecho — distribución por módulo:**

| Módulo | Archivos de test |
|---|---|
| `postventa` | 15 |
| `visitas` | 10 |
| `hunter` | 8 |
| `gastos` | 8 |
| `facturacion` | 6 |
| `salas` | 3 |
| `averias` | 3 |
| `warroom` | 2 |
| `unoauno` | 1 |
| `solicitudes` | 1 |
| (resto, en `src/lib`/`src/utils`) | ~8 |

**12 de los 22 módulos con código tienen 0 archivos de test:** `auth`, `bienvenida`, `callcenter`, `cobertura`, `config`, `incentivos`, `induccion`, `mora`, `portal`, `productos`, `resumen`, `vendedores`.

**Hallazgo más importante de este capítulo, confirmado con evidencia directa (`package.json` + `grep`): cero tests de componentes.** No hay `@testing-library/react`, `playwright` ni `cypress` en las dependencias del proyecto. Los 65 archivos de test son **exclusivamente pruebas de lógica pura** — parsers (`parseAverias.test.ts`, `parseContratos.test.ts`), la capa de dominio de `postventa` (`maquina.test.ts`, `copago.test.ts`, `slaCaso.test.ts`, `validadorInforme.test.ts`, `matchPago.test.ts`, `gatesIntake.test.ts`, `producto.test.ts`), el auditor de gastos (`auditor.test.ts`), offline (`visitaOffline.test.ts`, `miDiaCache.test.ts`, `bitacora.test.ts`) y la guarda de migraciones (`migracionesUnicas.test.ts`). **Ningún test renderiza un componente ni simula una interacción de usuario.**

**Evaluación:** este patrón no es aleatorio — es coherente con el acierto ya señalado en C10 (`postventa/dominio` como capa aislada y testeable). La cobertura está exactamente donde la lógica es más aislable y crítica de calcular bien (copago, SLA, siniestralidad, matcheo de pagos). **Pero el sistema completo — 24 módulos, componentes de hasta 3525 líneas (`CasoDetalle.tsx`, C10) — no tiene ninguna red de seguridad si se rompe la interacción de UI**, solo si se rompe el cálculo subyacente. Es una cobertura de "el motor" sin cobertura de "el tablero", con dos consecuencias concretas: (1) un refactor de componentes grandes como `CasoDetalle.tsx` no tiene tests que avisen si algo visual/interactivo se rompió; (2) los módulos sin ningún test (`incentivos` — cálculo de compensación; `mora` — donde vive el hallazgo Crítico; `portal` — la superficie pública) son precisamente los que más se beneficiarían de al menos pruebas de lógica.

## 2. Pipeline de CI/CD — existe, corrige la duda que plantea el PRD original

**Confirmado, contradice la pregunta abierta del PRD** ("ausencia o presencia de pipeline propio"): `.github/workflows/ci.yml` corre en cada `push` y `pull_request` a `master`: `npm ci` → `npm run lint` → `npm test` → `npm run build`, sobre Node 22. El propio comentario del archivo lo explica: *"si el lint, los tests o la compilación fallan, GitHub marca el commit con una ✗ roja... Vercel despliega por su lado; este check es la alarma de calidad."*

**Evaluación:** el pipeline valida lint + test + build, pero **no incluye ningún paso de seguridad automatizado** (sin `npm audit`, sin escaneo de secretos, sin SAST) y, coherente con el hallazgo de §1, **no puede atrapar una regresión de UI** porque no hay tests que la ejerciten. Es un CI real y útil, pero angosto en lo que puede detectar.

## 3. Dependencia de Vercel para preview y deploy

Confirmado por `CLAUDE.md` y la estructura del repositorio: cada PR genera una preview URL en Vercel; el deploy a producción también es Vercel. **No hay pipeline de despliegue propio** (fuera de GitHub Actions para validación) — la entrega física del build depende enteramente de un proveedor externo, coherente con el resto del stack (Supabase + Vercel como plataforma completa).

## 4. Flujo de ramas — diverge del estándar de Engine, por diseño propio del proyecto

**Hecho:** el repositorio no tiene `develop`, `pre-qa` ni `qa` — su flujo (documentado en su propio `CLAUDE.md`) es rama de trabajo → PR a `master` → deploy en Vercel. `rules/version-control.md` de Engine espera `develop`/`pre-qa`/`qa`/`main`. Esto ya se registró como nota operativa en `PLAN.md` §12 nota 2; se confirma aquí como hallazgo de gobierno, no de calidad de código: el flujo es simple y funciona para un equipo pequeño con Vercel, pero no calza con la maquinaria de promoción por ambientes que usa el resto de Engine (SIGA, Omega).

## 5. Gobierno de migraciones — mecanismo de contención real y verificado en T-10

Ya confirmado en C5'/T-10: **15 números de migración duplicados** de 364 (histórico, se dejan como están por decisión documentada — la base identifica por timestamp, no por nombre de archivo). La red de contención, `src/lib/migracionesUnicas.test.ts`, es un test que vive en `src/` (no en `supabase/`) por una razón técnica explícita en su propio comentario: *"vitest solo mira `src/**`"*. Arranca en el archivo 316 (`DESDE = 316`), dejando los históricos fuera a propósito. **Funciona**: 0 duplicados nuevos entre el 316 y el 364 actual — confirmado en T-10.

**Evaluación:** es un ejemplo claro de deuda técnica reconocida y contenida con una prueba automatizada, en vez de dejada sin control. El propio comentario documenta la limitación honesta del mecanismo: *"dos sesiones creando a la vez todavía pueden empatar"* — el test atrapa el duplicado en el PR, no lo previene en el momento de crear el archivo.

## 6. Cobertura declarada (RNF-11)

Cubierto con evidencia completa: distribución de tests por módulo (100% de los 22 módulos con código verificados), confirmación de la ausencia total de tests de componentes/UI (`package.json` + búsqueda de patrones), el pipeline de CI completo, la dependencia de Vercel, el flujo de ramas real, y el mecanismo de contención de migraciones duplicadas. **No se ejecutó la suite de tests** (`npm test`) — requeriría instalar dependencias (`npm install`), fuera del alcance de solo lectura sin autorización adicional; el análisis de cobertura es por inventario de archivos, no por porcentaje de líneas cubiertas real (`coverage`, si existiera, tampoco se generó).
