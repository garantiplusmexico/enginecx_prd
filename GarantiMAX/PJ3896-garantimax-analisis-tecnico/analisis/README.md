# Análisis técnico y documentación de GarantiMAX — Índice

| Campo | Detalle |
|---|---|
| PRD | `PJ3896-garantimax-analisis-tecnico` |
| Plan | `../PLAN.md` |
| Avance | `../AVANCE.md` |
| Metodología | [`00-metodologia-y-evidencia.md`](00-metodologia-y-evidencia.md) |
| Versión de este índice | 0.3 |
| Última actualización | 2026-08-24 |

---

## Código analizado (T-01, RNF-14)

| Campo | Detalle |
|---|---|
| Repositorio | `garantiplusmexico/garantiplus-dashboard` |
| Commit fijado | `3771e7f1c97129149b049685c05977b3f8a64189` |
| Fecha del commit | 2026-08-19 11:24:23 -0400 |
| Fecha de sincronización local | 2026-08-24 |

**Incidencia de arranque:** al generar `PLAN.md` (24-08-2026), la copia local del repositorio estaba en `de6ce01` (2026-08-06) — **29 commits detrás** de `origin/master`. El supuesto del PRD *"el repositorio local está actualizado"* era falso en ese momento. Se corrigió con `git pull` antes de iniciar la lectura de código (Fase 0, T-01); el commit `3771e7f` es el que rige todo el análisis hasta que se re-verifique en T-28 (cierre de la Etapa A) y T-38 (cierre de la Etapa B).

Si al retomar el trabajo `origin/master` avanzó de nuevo, **no re-sincronizar sin registrar el salto aquí** — el objetivo es que la vigencia del documento sea rastreable, no que sea siempre el código más nuevo.

---

## Etapas

| | Etapa A — El proyecto por dentro | Etapa B — La plataforma |
|---|---|---|
| Estado | 🟡 En progreso (Fase 1 cerrada — PUERTA 1 pasada) | 🔴 Bloqueada — sin fecha |
| Necesita | Solo el repositorio | A1 (lectura Supabase) + A3 (API de SIGA) |
| Entrega | Análisis técnico completo + dictamen **preliminar** | Verificación contra la base + dictamen **definitivo** |

Detalle completo en `PLAN.md` §1.4. Estado de accesos en [`preguntas-abiertas.md`](preguntas-abiertas.md).

---

## Índice de capítulos

| # | Capítulo | Requerimiento | Etapa | Estado |
|---|---|---|---|---|
| 00 | [Metodología y criterio de evidencia](00-metodologia-y-evidencia.md) | — | A — T-04 | ✅ Cerrado |
| 01 | [Ficha tecnológica y de dependencias](01-ficha-tecnologica.md) | RF-01 | A — T-06 | ✅ Cerrado |
| 02 | [Mapa de módulos y lógica de negocio](02-mapa-modulos.md) | RF-02, RF-03 | A — T-07 | ✅ Cerrado |
| 03 | [Modelo de datos](03-modelo-datos.md) | RF-04 | A (inferido) — T-08/T-09 · B (verificado) — T-31/T-33 | 🟡 Cerrado en A, pendiente de B |
| 04 | [Datos muertos](04-datos-muertos.md) | RF-05 | A (candidatos) — T-10 · B (confirmados) — T-34 | 🟡 Cerrado en A, pendiente de B |
| 05 | [Catálogo de Edge Functions](05-edge-functions.md) | RF-06 | A — T-11 | ✅ Cerrado |
| 06 | [Integraciones externas](06-integraciones-externas.md) | RF-07 | A — T-12 | ✅ Cerrado |
| 07 | [Uso de SIGA — Excel](07-uso-de-siga.md) | RF-08 | A — T-13 | ✅ Cerrado |
| 08 | [API de SIGA — matriz de cobertura](08-api-siga-cobertura.md) | RF-09 | B — T-36 (bloqueada por A3) | 🔴 Bloqueada |
| 09 | [Mapa de Realtime](09-mapa-realtime.md) | RF-10 | A — T-14 | ✅ Cerrado |
| 10 | [PWA y offline](10-pwa-y-offline.md) | RF-11 | A — T-15 | ✅ Cerrado |
| 11 | [Arquitectura, patrones y buenas prácticas](11-arquitectura-y-patrones.md) | RF-12 | A — T-16 | ⏳ Pendiente |
| 12 | [Seguridad](12-seguridad.md) | RF-13 | A (código) — T-17 · B (RLS real) — T-32 | ⏳ Pendiente |
| 13 | [Rendimiento y escalabilidad](13-rendimiento-escalabilidad.md) | RF-14 | A — T-18 | ⏳ Pendiente |
| 14 | [Testing, CI/CD y proceso](14-testing-cicd-proceso.md) | RF-15 | A — T-19 | ⏳ Pendiente |
| 15 | [Observabilidad y operación](15-observabilidad-operacion.md) | RF-16 | A — T-20 | ⏳ Pendiente |
| 16 | [Supabase vs. .NET 8](16-supabase-vs-net8.md) | RF-17 | A (estructura) — T-23 · B (peso y costo) — T-35 | ⏳ Pendiente |
| 17 | [Escenarios de destino (E0–E4)](17-escenarios-destino.md) | RF-18, RF-20 | A (preliminar) — T-24 · B (E4 resuelto) — T-37 | ⏳ Pendiente |
| 18 | [Opciones de PWA](18-opciones-pwa.md) | RF-19 | A — T-25 | ⏳ Pendiente |
| 19 | [Dictamen y recomendación](19-dictamen.md) | RF-21 | A (preliminar) — T-26 · B (definitivo) — T-38 | ⏳ Pendiente |
| 20 | [Resumen ejecutivo](20-resumen-ejecutivo.md) | RF-22 | A — T-27 · B (actualizado) — T-38 | ⏳ Pendiente |
| — | [Registro de hallazgos](hallazgos.md) | RNF-09 | Transversal | 🟡 En curso — 1 Crítico, 1 Medio |
| — | [Accesos y preguntas abiertas](preguntas-abiertas.md) | RF-23, RNF-11 | Transversal | 🟡 En curso |

---

## Inventarios reproducibles

Comandos y salidas de la extracción automatizada (T-05) en [`inventarios/`](inventarios/00-comandos-de-extraccion.md).

---

## PUERTA 1 — Inventario completo y validado (cierre de Fase 1)

Los 24 módulos, las 46 Edge Functions, las 136 tablas vivas (inferidas) y los 11 canales de Realtime tienen ficha o declaración de cobertura. **PUERTA 1 pasada el 24-08-2026** con las siguientes salvedades explícitas, no huecos silenciosos:

- La criticidad operativa de los 24 módulos es una **hipótesis estructural**, pendiente de validar con Fabrizio Álvarez (A6).
- El modelo de datos (C3) y los datos muertos (C5') están completos **como inferencia de migraciones**; su verificación contra el catálogo real es explícitamente de la Etapa B (T-31/T-33/T-34).
- Durante T-08/T-09 se detectó y escaló un hallazgo de seguridad **Crítico** (`mora_corte`, ver `hallazgos.md` #1) y uno **Medio histórico ya remediado** (`dossier-ia`, ver `hallazgos.md` #2) — ninguno bloquea el cierre de la fase, ambos quedan trazados.
- C7 (API de SIGA) permanece bloqueada por diseño (A3) — no es un hueco de esta fase, es la Etapa B.

Se avanza a Fase 2 (análisis de calidad y riesgos) con esta base.

---

## Cobertura declarada (RNF-11)

**Fase 0 y Fase 1 cerradas (24-08-2026).** 12 de 20 capítulos cerrados por completo en Etapa A (C1, C2, C4, C5, C6, C8, C9, C10 pendiente en Fase 2, C12–C14 pendientes en Fase 2, C17 pendiente en Fase 3). De los ya cerrados: C1, C2, C4, C5, C6, C8, C9 (7 capítulos) al 100% de su alcance en Etapa A. C3 y C5' cerrados en su alcance de Etapa A, con su mitad de Etapa B explícitamente pendiente. C7 sin empezar, bloqueada por diseño. Detalle de qué falta por capítulo en cada archivo, sección "Cobertura declarada" propia.
