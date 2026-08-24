# Análisis técnico y documentación de GarantiMAX — Índice

| Campo | Detalle |
|---|---|
| PRD | `PJ3896-garantimax-analisis-tecnico` |
| Plan | `../PLAN.md` |
| Avance | `../AVANCE.md` |
| Metodología | [`00-metodologia-y-evidencia.md`](00-metodologia-y-evidencia.md) |
| Versión de este índice | 0.5 |
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

**Re-verificación de cierre de Etapa A (T-28, 2026-08-24):** `origin/master` se volvió a consultar al cerrar la Fase 4 — **sigue en `3771e7f`, sin cambios** desde que se fijó el 24-08-2026. El commit que rige todo este análisis (Fases 0 a 4) es el mismo del arranque; no hubo deriva del código durante la ventana de trabajo. Se detectó una rama nueva sin mergear (`feat/escenario-agosto`), que no afecta la vigencia por no estar en `master`. Próxima re-verificación: T-38, al cierre de la Etapa B — para entonces, si `origin/master` avanzó, se documentará el salto y los cambios relevantes del período.

---

## Etapas

| | Etapa A — El proyecto por dentro | Etapa B — La plataforma |
|---|---|---|
| Estado | 🟡 Análisis completo — pendiente PUERTA 2 (revisión de Dirección) | 🔴 Bloqueada — sin fecha |
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
| 11 | [Arquitectura, patrones y buenas prácticas](11-arquitectura-y-patrones.md) | RF-12 | A — T-16 | ✅ Cerrado |
| 12 | [Seguridad](12-seguridad.md) | RF-13 | A (código) — T-17 · B (RLS real) — T-32 | 🟡 Cerrado en A, pendiente de B |
| 13 | [Rendimiento y escalabilidad](13-rendimiento-escalabilidad.md) | RF-14 | A — T-18 | ✅ Cerrado |
| 14 | [Testing, CI/CD y proceso](14-testing-cicd-proceso.md) | RF-15 | A — T-19 | ✅ Cerrado |
| 15 | [Observabilidad y operación](15-observabilidad-operacion.md) | RF-16 | A — T-20 | ✅ Cerrado |
| 16 | [Supabase vs. .NET 8](16-supabase-vs-net8.md) | RF-17 | A (estructura) — T-23 · B (peso y costo) — T-35 | 🟡 Cerrado en A, pendiente de B |
| 17 | [Escenarios de destino (E0–E4)](17-escenarios-destino.md) | RF-18, RF-20 | A (preliminar) — T-24 · B (E4 resuelto) — T-37 | 🟡 Cerrado en A, pendiente de B |
| 18 | [Opciones de PWA](18-opciones-pwa.md) | RF-19 | A — T-25 | ✅ Cerrado |
| 19 | [Dictamen y recomendación](19-dictamen.md) | RF-21 | A (preliminar) — T-26 · B (definitivo) — T-38 | 🟡 **Preliminar** — pendiente de B |
| 20 | [Resumen ejecutivo](20-resumen-ejecutivo.md) | RF-22 | A — T-27 · B (actualizado) — T-38 | 🟡 **Preliminar** — pendiente de B |
| — | [Registro de hallazgos](hallazgos.md) | RNF-09 | Transversal | ✅ Consolidado — 8 hallazgos (1 Crítico, 1 Alto, 3 Medio, 2 Bajo-Medio, 1 Bajo) |
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

## Cierre de Fase 2 (T-16 a T-21)

Los cinco capítulos de calidad (C10–C14) cerrados en su alcance de Etapa A. **6 hallazgos nuevos** en esta fase (más los 2 de Fase 1 = 8 totales, ver `hallazgos.md`): 1 Alto (cero tests de UI/componentes en todo el sistema), 2 Medio (`strict` de TypeScript apagado; sin tipos generados de Supabase), 2 Bajo-Medio (CORS abierto en 34/46 funciones; Sentry ausente del backend), 1 Bajo (límite de filas sin `.limit()` explícito en una consulta del War Room). Ninguno bloquea el avance a Fase 3.

## Cierre de Fase 3 (T-23 a T-26) — dictamen preliminar emitido

Los cinco servicios de Supabase evaluados por separado (C15), los cinco escenarios E0–E4 comparados con la misma rejilla (C16), las tres opciones de PWA (C17), y un **dictamen preliminar** (C18) derivado paso a paso del árbol de decisión del PRD. **Lectura preliminar: E4 (retención parcial por dominio) es el candidato más prometedor**, porque el Realtime — la pieza más cara de sustituir de las cinco de Supabase — se concentra justo en el dominio que E4 propone conservar. **No es una conclusión**: depende de T-35 (peso real) y T-37 (costuras resueltas) en Etapa B. E0 sigue siendo línea base seria; E2 (rehacer todo) no tiene evidencia que lo justifique hoy.

## Cierre de Fase 4 (T-27, T-28) — Etapa A con contenido completo

**T-27** — resumen ejecutivo (`20-resumen-ejecutivo.md`) emitido, sin detalle técnico, para Dirección — mismo dictamen preliminar de C18 en lenguaje no técnico.

**T-28** — re-verificación de vigencia: `origin/master` sigue en el commit fijado (`3771e7f`), sin deriva durante toda la ventana de trabajo (24-08-2026). Cobertura declarada (RNF-11), consolidada al cierre de toda la Etapa A:

| Capítulo | Estado |
|---|---|
| C1, C2, C4, C5, C6, C8, C9, C10, C12, C13, C14, C17 (12 capítulos) | ✅ 100% de su alcance en Etapa A |
| C3, C5', C11, C15, C16 (5 capítulos) | 🟡 Cerrados en Etapa A — inferido/estructural, verificación real pendiente de Etapa B |
| C18, C19 (dictamen y resumen ejecutivo) | 🟡 **Preliminares** por diseño — se reemplazan en T-38 |
| C7 (API de SIGA) | 🔴 Sin empezar — bloqueada por diseño (A3), no es un hueco |

**Los 20 capítulos tienen contenido (100%).** Ninguno quedó vacío ni con relleno sin evidencia — donde falta profundidad, está declarado explícitamente el porqué y qué tarea de Etapa B lo cierra.

---

## Pendiente para cerrar la Etapa A — requiere al programador, no a Claude Code

**T-29 (PUERTA 2 — revisión con la Dirección de TI)** no se puede ejecutar de forma autónoma: requiere una sesión real con Aldo Álvarez que registre sus preguntas y las cierre antes de dar el documento por final. Queda **pendiente de agendar**.

**T-30 (publicación final)**: antes de abrir el PR, falta la revisión de confidencialidad final (ya verificada de forma incremental en cada fase — ningún secreto ni dato personal transcrito, `hallazgos.md` revisado). **El Pull Request lo abre siempre el programador, nunca Claude Code** (`rules/version-control.md` §5) — la rama `feature/PJ3896-garantimax-analisis-tecnico` está lista y pusheada para que Javier abra el PR hacia `main` cuando lo considere oportuno, marcado como **entrega parcial** (Etapa A completa, Etapa B pendiente de accesos).
