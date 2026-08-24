# Análisis técnico y documentación de GarantiMAX — Índice

| Campo | Detalle |
|---|---|
| PRD | `PJ3896-garantimax-analisis-tecnico` |
| Plan | `../PLAN.md` |
| Avance | `../AVANCE.md` |
| Metodología | [`00-metodologia-y-evidencia.md`](00-metodologia-y-evidencia.md) |
| Versión de este índice | 0.2 |
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
| Estado | 🟡 En progreso (Fase 0) | 🔴 Bloqueada — sin fecha |
| Necesita | Solo el repositorio | A1 (lectura Supabase) + A3 (API de SIGA) |
| Entrega | Análisis técnico completo + dictamen **preliminar** | Verificación contra la base + dictamen **definitivo** |

Detalle completo en `PLAN.md` §1.4. Estado de accesos en [`preguntas-abiertas.md`](preguntas-abiertas.md).

---

## Índice de capítulos

| # | Capítulo | Requerimiento | Etapa | Estado |
|---|---|---|---|---|
| 00 | [Metodología y criterio de evidencia](00-metodologia-y-evidencia.md) | — | A — T-04 | ✅ Cerrado |
| 01 | [Ficha tecnológica y de dependencias](01-ficha-tecnologica.md) | RF-01 | A — T-06 | ⏳ Pendiente |
| 02 | [Mapa de módulos y lógica de negocio](02-mapa-modulos.md) | RF-02, RF-03 | A — T-07 | ⏳ Pendiente |
| 03 | [Modelo de datos](03-modelo-datos.md) | RF-04 | A (inferido) — T-08/T-09 · B (verificado) — T-31/T-33 | ⏳ Pendiente |
| 04 | [Datos muertos](04-datos-muertos.md) | RF-05 | A (candidatos) — T-10 · B (confirmados) — T-34 | ⏳ Pendiente |
| 05 | [Catálogo de Edge Functions](05-edge-functions.md) | RF-06 | A — T-11 | ⏳ Pendiente |
| 06 | [Integraciones externas](06-integraciones-externas.md) | RF-07 | A — T-12 | ⏳ Pendiente |
| 07 | [Uso de SIGA — Excel](07-uso-de-siga.md) | RF-08 | A — T-13 | ⏳ Pendiente |
| 08 | [API de SIGA — matriz de cobertura](08-api-siga-cobertura.md) | RF-09 | B — T-36 (bloqueada por A3) | 🔴 Bloqueada |
| 09 | [Mapa de Realtime](09-mapa-realtime.md) | RF-10 | A — T-14 | ⏳ Pendiente |
| 10 | [PWA y offline](10-pwa-y-offline.md) | RF-11 | A — T-15 | ⏳ Pendiente |
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
| — | [Registro de hallazgos](hallazgos.md) | RNF-09 | Transversal | ⏳ Vacío |
| — | [Accesos y preguntas abiertas](preguntas-abiertas.md) | RF-23, RNF-11 | Transversal | 🟡 En curso |

---

## Inventarios reproducibles

Comandos y salidas de la extracción automatizada (T-05) en [`inventarios/`](inventarios/00-comandos-de-extraccion.md).

---

## Cobertura declarada (RNF-11)

*(Se actualiza al cierre de cada fase. Al 2026-08-24: Fase 0 en progreso — sin capítulos de contenido cerrados todavía.)*
