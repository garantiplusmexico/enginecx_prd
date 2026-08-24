# 11 · Evaluación de arquitectura, patrones y buenas prácticas

| Campo | Detalle |
|---|---|
| Capítulo | C10 |
| Requerimiento(s) | RF-12 |
| Etapa | A — T-16 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

> Metodología §4 (`00-metodologia-y-evidencia.md`): este capítulo separa **inventario** (lo observado) de **evaluación** (lo juzgado, con su razón), y presenta tanto aciertos como problemas con ejemplos concretos — un dictamen que solo lista defectos no es evaluación, es acusación.

---

## 1. Organización por features — inventario

24 carpetas bajo `src/features/`, cada una con sus propios componentes, hooks y acceso a datos. No hay una carpeta `components/` ni `services/` centralizada que mezcle todo — la organización es **vertical por dominio de negocio**, no por tipo técnico. Dentro de los módulos más maduros aparecen subcarpetas por responsabilidad: `postventa/dominio` (lógica de negocio pura), `postventa/datos` (acceso a datos), `postventa/etl`, `postventa/informe`, `postventa/pdf`, `postventa/publico`; `hunter/cotizador`.

**Evaluación (acierto):** `postventa/dominio` es una capa de dominio genuina, no cosmética — 22 archivos, cada uno con su `.test.ts` correspondiente co-localizado: máquina de estados del caso (`maquina.ts`), cálculo de copago (`copago.ts`), reloj de SLA (`slaCaso.ts`), validador de informe (`validadorInforme.ts`), matcheo de pagos (`matchPago.ts`). Es lógica de negocio pura, sin dependencia de React ni de Supabase, testeable de forma aislada. **Es exactamente el patrón que facilita una migración**: esta capa se podría portar a C# casi 1:1, porque ya está separada de la UI y de la infraestructura. Contraste explícito con `chileGeo.ts`/`lugaresChile.ts` en la misma carpeta: son datos estáticos (división político-administrativa), no lógica — mezclados en la misma carpeta que la lógica real, un desvío menor de la separación que el resto de la carpeta sí respeta.

---

## 2. Patrones de estado — sin librería externa, por decisión

**Hecho:** cero uso de Zustand, Redux o Jotai (`grep` sobre `package.json`, 0 coincidencias). El estado compartido se resuelve con **módulos "store" hechos a mano** — closures a nivel de módulo con un `Set` de subscribers, el mismo patrón documentado explícitamente en `visitasRealtime.ts` (C8/T-14): `telefonoStore.ts`, `useFacturacion.ts`, `useSalas.ts`, `bitacoraTerreno.ts`, `miDiaCache.ts`, entre otros.

**Evaluación:** es una decisión de minimalismo deliberada — cero dependencia externa para algo que React + closures ya resuelve. Es coherente con el resto del stack (evitar dependencias que no se necesitan, ver C1/T-06). El costo es que la disciplina para mantenerlo consistente recae enteramente en el equipo (no hay una librería que fuerce un patrón único); el hallazgo de "canal Realtime duplicado" que el propio código documentó y corrigió en `visitasRealtime.ts` (C8) es evidencia de que ese costo **es real y ya se materializó una vez**, y de que el equipo lo detecta y corrige cuando aparece.

---

## 3. Tipado — menos estricto de lo que "TypeScript" sugiere (hallazgo)

**Hecho:** ni `tsconfig.json` ni `tsconfig.app.json` declaran `"strict": true`. Sin esa bandera, TypeScript no activa `strictNullChecks` ni `noImplicitAny` por defecto — dos de las protecciones de mayor impacto del lenguaje quedan **apagadas**. Lo que sí está activo explícitamente: `noUnusedLocals`, `noUnusedParameters`, `noFallthroughCasesInSwitch`, `erasableSyntaxOnly`. ESLint usa `tseslint.configs.recommended` (no `recommendedTypeChecked` ni `strict`).

**Evaluación:** es un hallazgo real, no catastrófico — el proyecto sí tiene higiene de lint (variables no usadas, switches sin `break`), pero **no la protección de nulabilidad que un lector asumiría al ver "TypeScript" en la ficha tecnológica**. En un sistema de 113 587 líneas con lógica financiera (facturación, incentivos, pagos), la ausencia de `strictNullChecks` es la clase de hueco que produce errores en producción del tipo "no se esperaba `null` aquí" — silenciosos hasta que ocurren. Se traslada a `hallazgos.md` con severidad **Media**: no es explotable ni es una brecha de seguridad, pero es deuda técnica con probabilidad de materializarse, no solo teórica.

---

## 4. Tamaño de archivos y componentes — el hallazgo más contundente de este capítulo

**Hecho** (medido, `find src -name "*.ts" -o -name "*.tsx" | xargs wc -l`):

| Archivo | Líneas | Módulo |
|---|---|---|
| `CasoDetalle.tsx` | **3525** | `postventa` |
| `casosDb.ts` | **3070** | `postventa` |
| `WelcomeScreen.tsx` | 1754 | `bienvenida` |
| `NuevaVisita.tsx` | 1562 | `visitas` |
| `generarCierrePptx.ts` | 1293 | `facturacion` |
| `GastosView.tsx` | 1261 | `gastos` |
| `SalaDetalle.tsx` | 1143 | `salas` |

**58 archivos superan las 500 líneas; 32 superan las 800.** `CasoDetalle.tsx` por sí solo es el **3,1% de todo el código fuente del sistema** (113 587 líneas totales) en un único archivo.

**Evaluación:** esto contrasta directamente con `rules/coding-guidelines.md` de Engine (§3: "máximo 200 líneas por archivo, si supera, refactorizar") — no porque GarantiMAX deba seguir esa regla hoy (es un proyecto React, no .NET, y la regla es del estándar corporativo), sino porque **es la vara con la que este análisis mide "calidad interna que permite construir sobre lo existente"** (árbol de decisión del PRD, §7.3). `CasoDetalle.tsx` y `casosDb.ts` son, no por casualidad, los dos archivos del **módulo más grande y más crítico del sistema** (`postventa`, C2/T-07). Un componente de 3525 líneas es difícil de entender, de testear y de modificar con confianza — es exactamente el tipo de hallazgo que **pesa en la decisión entre refactorizar y rehacer** (si `postventa` se conserva, esta es la primera candidata a descomponer; si se rehace, es una razón más a favor).

---

## 5. Consistencia y duplicación

- **Patrón *staging → aplicar* repetido con criterio**, no accidental: `contratos_staging`/`aplicar_contratos_staging` (facturación, C3) es el mismo patrón de "cargar crudo, validar/aplicar después" que se ve también en la separación entre `postventa/etl` y `postventa/dominio`. Es un patrón consistente entre módulos distintos, lo cual es un acierto de diseño.
- **Duplicidad puntual confirmada** (ya señalada en C1/T-06 y C5'/T-10): `hunter/cotizador/cotizacionPdf.ts` y `cotizacionPdfV2.ts` coexisten — 2 generadores de PDF para el mismo propósito.
- **Nomenclatura mixta español/inglés** dentro del mismo archivo es la norma en todo el repositorio (nombres de variable en español, tipos y patrones en inglés) — consistente en sí misma a lo largo de las 24 carpetas, no es un caos: es una convención local estable, distinta de `rules/coding-guidelines.md` de Engine (que exige inglés), y sería un costo de re-trabajo si algún escenario exigiera homogeneizar con el estándar corporativo.
- **Auto-corrección visible en el propio historial de commits** (evidencia adicional, `git log`): commits como *"renombrar variables del bloque de materiales para no sombrear las del body"* muestran un equipo que revisa y corrige su propio código activamente, no solo que lo escribe.

---

## 6. Manejo de estado y tipado en la capa de datos

El acceso a Supabase se hace mayormente con **tipado manual de la respuesta** (`as Record<string, unknown>`, `as TipoEspecifico`) en lugar de tipos generados automáticamente desde el esquema de la base (Supabase soporta generar tipos con su CLI, `supabase gen types`). **No se encontró evidencia de un archivo de tipos generado** durante esta etapa. Esto es coherente con la ausencia de `strictNullChecks` (§3): sin tipos generados y sin verificación estricta de null, la forma real de los datos que vuelven de Postgres depende de la disciplina de quien escribe cada `interface` a mano — un cambio de columna en una migración no rompe la compilación del front, solo se descubre en tiempo de ejecución. Se registra como hallazgo de severidad **Media**, ligado al de tipado (§3).

---

## 7. Cobertura declarada (RNF-11)

Evaluación con evidencia directa de código sobre: organización por features, capa de dominio (`postventa/dominio`), patrón de estado, tipado (tsconfig + eslint), tamaño de archivos (medido en las 113 587 líneas completas), duplicidad conocida y consistencia de patrones entre módulos. **No se profundizó** en un catálogo módulo-por-módulo de "archivos > 500 líneas" más allá del top 15 mostrado — la lista completa de 58 queda en `inventarios/` si se necesita para C12 (rendimiento) o para dimensionar el refactor en C16. Los dos hallazgos de tipado (§3 y §6) se trasladan a `hallazgos.md` con severidad Media.
