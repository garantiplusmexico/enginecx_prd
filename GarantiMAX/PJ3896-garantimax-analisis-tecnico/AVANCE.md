# Registro de Avance — Análisis técnico y documentación de GarantiMAX (Dashboard GarantiPLUS)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/PJ3896-garantimax-analisis-tecnico` |
| Responsable actual | Javier Antonio Oropeza Camacho |
| Folio PRD | `PJ3896` |
| ID plan (BD) | `55` |
| Última actualización | 2026-08-24 |
| Estado general | 🟡 Etapa A con contenido completo — pendiente PUERTA 2 (T-29) y publicación (T-30), ambas a cargo del programador |
| Modelo de ejecución | `claude-sonnet-5` — esfuerzo: alto |
| Etapa activa | **Etapa A** — El proyecto por dentro (ver `PLAN.md` §1.4). La Etapa B (Fases 5–6) queda apartada sin fecha hasta que lleguen los accesos A1 (lectura Supabase, `.env` pendiente) y A3 (fuente de la API de SIGA). |

---

## Resumen de estado

Plan aprobado y registrado en BD el 24-08-2026. Rama funcional creada desde `main` de `enginecx_prd`. El repositorio analizado (`garantimax`) se sincronizó a `origin/master` = `3771e7f` (2026-08-19 11:24 -0400), que es el commit fijado de vigencia (RNF-14).

**Fases 0, 1, 2 y 3 completadas y commiteadas** (T-01 a T-26, PUERTA 1 pasada, dictamen preliminar emitido). **Fase 4 casi completa** (T-27, T-28 hechas): resumen ejecutivo emitido (`20-resumen-ejecutivo.md`), vigencia re-verificada (`origin/master` sigue en `3771e7f`, sin deriva). **Etapa A tiene contenido completo en los 20 capítulos.**

**T-29 (PUERTA 2) y T-30 (publicación/PR) no pueden completarse de forma autónoma:** T-29 requiere una sesión real con Aldo Álvarez; T-30 exige que el programador abra el PR (`rules/version-control.md` §5, Claude Code nunca lo hace). Pendiente de autorización para el commit de T-27/T-28; al autorizarse, la Etapa A queda lista para que Javier agende la revisión con Aldo y abra el PR cuando corresponda.

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **ETAPA A — El proyecto por dentro** | | | | | | | | |
| **Fase 0 — Habilitación, línea base y método** | `186` | T-01 a T-05 | 1 – 2 | 2026-08-24 | 2026-08-24 | 1 | 0 | ✅ Completada |
| **Fase 1 — Inventario y mapeo** | `187` | T-06 a T-15 | 4 – 6 | 2026-08-24 | 2026-08-24 | 1 | 0 | ✅ Completada |
| **Fase 2 — Análisis de calidad y riesgos** | `188` | T-16 a T-21 | 3 – 4 | 2026-08-24 | 2026-08-24 | 1 | 0 | ✅ Completada |
| **Fase 3 — Escenarios y dictamen preliminar** | `189` | T-23 a T-26 | 3 – 4 | 2026-08-24 | 2026-08-24 | 1 | 0 | ✅ Completada |
| **Fase 4 — Resumen ejecutivo, revisión y cierre de Etapa A** | `190` | T-27 a T-30 | 2 – 3 | 2026-08-24 | | 1 | 1-2 | 🟡 En progreso — T-27/T-28 hechas, T-29/T-30 requieren al programador |
| **Subtotal Etapa A** | — | 29 tareas | ~13 – 19 | | | 4 | 1-2 | 🟡 En progreso |
| **ETAPA B — La plataforma** *(sin fecha)* | | | | | | | | |
| **Fase 5 — Supabase verificado** | `191` | T-31 a T-35 | 3 – 4 | | | 0 | 4 | 🔴 Bloqueada (falta A1/A2) |
| **Fase 6 — API de SIGA, E4 y dictamen definitivo** | `192` | T-36 a T-38 | 2 – 3 | | | 0 | 3 | 🔴 Bloqueada (falta A3) |
| **Subtotal Etapa B** | — | 8 tareas | ~5 – 7 | | | 0 | 7 | 🔴 Bloqueada |
| **TOTAL PROYECTO** | — | 37 tareas | ~18 – 26 | | | 0 | 26 | 🟡 En progreso |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Sincronizar el repositorio analizado y fijar el commit de vigencia | Claude Code | 2026-08-24 | `garantimax` sincronizado a `origin/master` = `3771e7f`. Bloque de vigencia en `analisis/README.md` §"Código analizado". Desfase de 29 commits (`de6ce01` → `3771e7f`) registrado como incidencia. |
| T-02 | Confirmar accesos y registrar los bloqueados | Claude Code | 2026-08-24 | Los 6 accesos (A1–A6) registrados en `analisis/preguntas-abiertas.md` §1, todos ❌ pendientes salvo lo ya confirmado en `PLAN.md`. Ninguno bloquea el arranque de la Etapa A. |
| T-03 | Esqueleto de la documentación e índice navegable | Claude Code | 2026-08-24 | 20 capítulos + `hallazgos.md` + `preguntas-abiertas.md` creados en `analisis/`, cada uno con cabecera de versión/fecha/estado. `README.md` enlaza a los 22 archivos. |
| T-04 | Definir y publicar el método antes de los resultados | Claude Code | 2026-08-24 | `analisis/00-metodologia-y-evidencia.md` cerrado: escala de severidad, formato de cita, separación hecho/opinión, criterio de cobertura, reglas de anonimización y secretos, protocolo de escalamiento de vulnerabilidad activa. |
| T-05 | Extracción automatizada de inventarios base | Claude Code | 2026-08-24 | 7 comandos documentados y reproducidos en `analisis/inventarios/`. Confirmado exacto: 24 módulos, 364 migraciones, 46 Edge Functions, 65 archivos de test, 11 canales Realtime. Depurar en T-12: 6 hosts que son enlaces de UI, no integraciones de servidor. |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|

---

## Tareas completadas ✅ (Fase 1)

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-06 | Ficha tecnológica con veredicto por dependencia | Claude Code | 2026-08-24 | `analisis/01-ficha-tecnologica.md`. 14 dependencias de producción con veredicto. Hallazgo: `xlsx` viene de un CDN externo, no de npm; su superficie de uso (22 archivos) es mucho mayor de lo que documentaba el PRD original. |
| T-07 | Mapa de los 24 módulos + segmentación por dominio | Claude Code | 2026-08-24 | `analisis/02-mapa-modulos.md`. Hallazgo mayor: `CLAUDE.md` no documenta 7 de 24 módulos, incluido `postventa` (el más grande, 87 archivos). Segmentación por dominio refinada con evidencia (productos/solicitudes pasan a transversal; `callcenter` identificado como costura por `av_casos`). `bitacora` confirmado como carpeta vacía mal documentada en `CLAUDE.md`. |
| T-08 | Inventario de tablas (inferido de 364 migraciones) | Claude Code | 2026-08-24 | `analisis/03-modelo-datos.md`. 152 tablas creadas, 16 eliminadas, 136 vivas. Corrección de método propia documentada: el primer grep de RLS/policies tenía falsos negativos por espacios múltiples y bloques PL/pgSQL dinámicos (`foreach...array`) — corregido iterando los 7 archivos que usan ese patrón. |
| T-09 | Inventario de RPCs (inferido) | Claude Code | 2026-08-24 | `analisis/03-modelo-datos.md` §5. 262 RPCs únicas de 422 declaraciones. Firma exacta y `security definer` diferidos a T-33 (Etapa B) con la razón declarada. |
| T-10 | Candidatos a datos muertos | Claude Code | 2026-08-24 | `analisis/04-datos-muertos.md`. 14 tablas sin referencia en código (candidatas, no confirmadas). De 95 RPCs sin llamada `.rpc()` directa, 26 son triggers, 15 helpers de RLS y 54 se invocan función-a-función — **0 genuinamente huérfanas** tras la clasificación completa. Confirmados los 15 duplicados de numeración de migraciones que declara `CLAUDE.md`. |
| T-11 | Catálogo de las 46 Edge Functions | Claude Code | 2026-08-24 | `analisis/05-edge-functions.md`. 8 funciones son webhooks/API públicas sin JWT de Supabase (prioridad de C11). Confirmación de primera mano (comentario de `portal-admin`) de que las tablas `portal_*` están en deny-all a propósito. Hallazgo histórico Medio registrado (`dossier-ia`, brecha #6 ya remediada). |
| T-12 | Integraciones externas | Claude Code | 2026-08-24 | `analisis/06-integraciones-externas.md`. 10 integraciones reales (las 7 del PRD + Google Auth vía Supabase + Google Calendar por enlace + Nominatim/OpenStreetMap, no documentada antes). |
| T-13 | Uso real de SIGA (Excel) | Claude Code | 2026-08-24 | `analisis/07-uso-de-siga.md`. 40 campos documentados (22 de contratos + 18 de averías) desde los parsers reales. Confirmado: cero consumo por API, hoy y en el PRD original. Dato nuevo: el Excel de contratos pesa 21-22 MB (~70 000 filas) y crece con el tiempo. |
| T-14 | Mapa exacto de uso de Realtime | Claude Code | 2026-08-24 | `analisis/09-mapa-realtime.md`. 11/11 canales confirmados con archivo:línea, tabla/evento, consumidor y veredicto de necesidad. 2 de 11 sustituibles por refresco por consulta. Segmentados por dominio: 8/11 comercial, 3/11 (postventa) cruzan hacia operación — insumo directo de E4. |
| T-15 | Documentación de la PWA y su offline | Claude Code | 2026-08-24 | `analisis/10-pwa-y-offline.md`. Confirmado con evidencia de código que la PWA y el offline de datos son mecanismos independientes (Workbox vs. IndexedDB propio). Acoplamiento con el resto del sistema cuantificado: es el mismo bundle/build, un `if` en `App.tsx`. |

---

## Tareas completadas ✅ (Fase 2)

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-16 | Evaluación de arquitectura y patrones | Claude Code | 2026-08-24 | `analisis/11-arquitectura-y-patrones.md`. Acierto confirmado: `postventa/dominio` es una capa de dominio genuina y testeada. Hallazgo: `CasoDetalle.tsx` (3525 líneas) y `casosDb.ts` (3070 líneas) — 58 archivos > 500 líneas en total. `strict: true` no está activado en ningún tsconfig. |
| T-17 | Auditoría de seguridad (código, RLS declarado) | Claude Code | 2026-08-24 | `analisis/12-seguridad.md`. Confirmado: `SERVICE_ROLE_KEY` nunca en el frontend; guard de modo demo con lista blanca + backstop por patrón. CORS abierto (`'*'`) en 34/46 funciones, restringido en las 8 más sensibles. |
| T-18 | Auditoría de rendimiento y escalabilidad | Claude Code | 2026-08-24 | `analisis/13-rendimiento-escalabilidad.md`. Confirma la regla de `manualChunks` de `CLAUDE.md`. Hallazgo Bajo: una consulta del War Room sin `.limit()` explícito, expuesta al límite de 1000 filas de PostgREST. |
| T-19 | Diagnóstico de testing, CI/CD y proceso | Claude Code | 2026-08-24 | `analisis/14-testing-cicd-proceso.md`. Hallazgo Alto: cero tests de componentes/UI en todo el sistema (sin `@testing-library`, `playwright` ni `cypress`); 12 de 22 módulos sin ningún test. CI confirmado (contradice la duda del PRD). |
| T-20 | Diagnóstico de observabilidad y operación | Claude Code | 2026-08-24 | `analisis/15-observabilidad-operacion.md`. Hallazgo: Sentry no tiene ninguna presencia en las 46 Edge Functions — el backend no reporta errores a ningún sistema centralizado. |
| T-21 | Consolidar el registro de hallazgos priorizados | Claude Code | 2026-08-24 | `analisis/hallazgos.md` v1.0. 8 hallazgos consolidados y ordenados por severidad, 100% con evidencia citada. Lectura agregada: solo 1 es exposición de datos activa; el resto es deuda técnica de proceso con causa raíz común (redes de seguridad automatizadas solo en la lógica de dominio pura, no en UI/integración/infraestructura). |

---

## Tareas completadas ✅ (Fase 3)

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-23 | Supabase vs. .NET 8, servicio por servicio | Claude Code | 2026-08-24 | `analisis/16-supabase-vs-net8.md`. Los cinco servicios con veredicto estructural. Realtime identificado como el más caro/riesgoso de sustituir (backplane, afinidad de sesión, reponer la emisión de `postgres_changes`). Reparto por dominio a nivel estructural (sin peso, T-35 pendiente). |
| T-24 | Comparación de los cinco escenarios (E0–E4) | Claude Code | 2026-08-24 | `analisis/17-escenarios-destino.md`. Árbol de decisión republicado con la rama de E4. Los cinco evaluados con la misma rejilla de 6 criterios; E0 como línea base explícita. |
| T-25 | Evaluación de las tres opciones de PWA | Claude Code | 2026-08-24 | `analisis/18-opciones-pwa.md`. Matriz de decisión ligada a qué escenario de backend/front se elija y a los datos pendientes de A6. |
| T-26 | Dictamen preliminar y recomendación | Claude Code | 2026-08-24 | `analisis/19-dictamen.md`. Recomendación preliminar: E4 como candidato más prometedor (el Realtime, la pieza más cara, coincide con el dominio que E4 conserva), E0 como línea base seria, E2 sin evidencia que lo justifique. Marcado preliminar en título y en cada sección relevante. |

---

## Tareas completadas ✅ (Fase 4, parcial)

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-27 | Resumen ejecutivo para Dirección | Claude Code | 2026-08-24 | `analisis/20-resumen-ejecutivo.md`. Sin detalle técnico, mismo dictamen preliminar en lenguaje de negocio. Marcado preliminar, se reemplaza en T-38. |
| T-28 | Re-verificación de vigencia y cobertura declarada | Claude Code | 2026-08-24 | `analisis/README.md` actualizado. `origin/master` re-consultado: sigue en `3771e7f`, sin deriva durante toda la ventana de trabajo. Cobertura consolidada de los 20 capítulos publicada. |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-29 | Revisión con la Dirección de TI (PUERTA 2) | Requiere sesión real con Aldo Álvarez — no ejecutable de forma autónoma |
| T-30 | Publicación final y confidencialidad (PR) | El PR lo abre siempre el programador (`rules/version-control.md` §5) — no Claude Code |
| T-31 a T-35 | Fase 5 (Etapa B) | A1 (lectura Supabase) y A2 (paneles de costo) |
| T-36 a T-38 | Fase 6 (Etapa B) | A3 (fuente de la API de SIGA) |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| T-31 a T-35 | Fase 5 — Supabase verificado | Falta A1 (`.env` de lectura a Supabase, proyecto `jrykbalmnpymeyzdhsam`) y A2 (paneles de costo Vercel/Supabase) | Quien administre el proyecto Supabase (Fabrizio Álvarez, previsiblemente) |
| T-36 a T-38 | Fase 6 — API de SIGA, E4 y dictamen definitivo | Falta A3 (fuente autoritativa de la API de SIGA: repo, Swagger o doc, más contacto) | Equipo responsable de la API de SIGA |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Plan partido en dos etapas (A/B) el 24-08-2026 | A1 y A3 no estaban disponibles al generar el plan; se decidió arrancar con lo que el repositorio permite en lugar de esperar bloqueado (ver `PLAN.md` §1.4) | Etapa A entrega análisis técnico completo + dictamen preliminar; Etapa B verifica contra la base y cierra el dictamen definitivo |
| Ejecución en `claude-sonnet-5`, esfuerzo alto | El plan se generó en `claude-opus-5`; el desarrollador cambió el modelo de sesión antes de ejecutar, siguiendo la convención del workflow (`ejecutar-plan.md` usa Sonnet) | Trazabilidad: los commits de esta etapa declaran `claude-sonnet-5`, distinto del modelo de generación del plan |
| Rama funcional creada en `enginecx_prd` (no en `garantimax`) | El repositorio analizado se lee, nunca se escribe (RNF-01); el entregable documental vive en `enginecx_prd` | `garantimax` permanece en `master` sin ramas ni commits nuevos durante todo el proyecto |
| Corrección de método en la extracción de RLS/policies (T-08) | El primer grep literal producía falsos negativos masivos por espacios múltiples de alineación y por bloques PL/pgSQL dinámicos (`foreach t in array...execute format(...)`) que ocultan el nombre de tabla tras un `%I` | De 45 tablas "sin RLS" (falso) a 0 tras la corrección — documentado explícitamente en `03-modelo-datos.md` §1 por transparencia de método (RNF-02) |
| Hallazgo de seguridad Crítico (`mora_corte`) escalado fuera de orden, durante T-08/T-09 en vez de esperar a T-17/Fase 2 | El protocolo de `00-metodologia-y-evidencia.md` §3 exige escalar una vulnerabilidad al detectarla, no al cierre de fase | Registrado en `hallazgos.md` #1 y comunicado al desarrollador en el mismo turno en que se detectó |
| No se ejecutó `npm install`/`npm run build`/`npm test` en ningún momento de Fase 2 | Instalar dependencias toca red y filesystem fuera del repositorio versionado — excede el alcance de solo lectura sin autorización adicional (RNF-01) | Tamaño real de bundle y cobertura de línea de tests quedan como pendiente explícito en C12/C13, no estimados ni fabricados |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `AVANCE.md` | Creado | Paso 3 (ejecutar-plan.md) |
| `analisis/README.md` | Creado | T-01, T-03 |
| `analisis/00-metodologia-y-evidencia.md` | Creado | T-04 |
| `analisis/01-ficha-tecnologica.md` a `20-resumen-ejecutivo.md` (20 archivos) | Creados (esqueleto) | T-03 |
| `analisis/hallazgos.md` | Creado (vacío) | T-03 |
| `analisis/preguntas-abiertas.md` | Creado | T-02, T-03 |
| `analisis/inventarios/00-comandos-de-extraccion.md` | Creado | T-05 |
| `analisis/inventarios/modulos.txt`, `migraciones.txt`, `edge-functions.txt`, `dependencias.txt`, `archivos-test.txt`, `canales-realtime.txt`, `hosts-externos.txt` | Creados | T-05 |
| `analisis/01-ficha-tecnologica.md`, `02-mapa-modulos.md`, `03-modelo-datos.md`, `04-datos-muertos.md`, `05-edge-functions.md`, `06-integraciones-externas.md`, `07-uso-de-siga.md`, `09-mapa-realtime.md`, `10-pwa-y-offline.md` | Completados (contenido) | T-06 a T-15 |
| `analisis/inventarios/tablas-*.txt`, `rpcs-*.txt`, `edge-functions-detalle.txt`, `dependencias-entre-modulos.txt`, `tablas-rpcs-por-modulo.txt` (~20 archivos) | Creados | T-07 a T-11 |
| `analisis/hallazgos.md` | Actualizado (2 hallazgos) | T-08/T-09, T-11 |
| `analisis/README.md` | Actualizado (índice, PUERTA 1) | Cierre de Fase 1 |
| `analisis/11-arquitectura-y-patrones.md`, `12-seguridad.md`, `13-rendimiento-escalabilidad.md`, `14-testing-cicd-proceso.md`, `15-observabilidad-operacion.md` | Completados (contenido) | T-16 a T-20 |
| `analisis/inventarios/archivos-grandes-500mas.txt` | Creado | T-16 |
| `analisis/hallazgos.md` | Consolidado v1.0 (8 hallazgos) | T-17 a T-21 |
| `analisis/README.md` | Actualizado (índice, cierre Fase 2) | Cierre de Fase 2 |
| `analisis/16-supabase-vs-net8.md`, `17-escenarios-destino.md`, `18-opciones-pwa.md`, `19-dictamen.md` | Completados (contenido) | T-23 a T-26 |
| `analisis/README.md` | Actualizado (índice, cierre Fase 3, dictamen preliminar) | Cierre de Fase 3 |
| `analisis/20-resumen-ejecutivo.md` | Completado (contenido) | T-27 |
| `analisis/README.md` | Actualizado (vigencia re-verificada, cobertura de los 20 capítulos, cierre de Fase 4 parcial) | T-28 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `4609986` | `[PJ3896-garantimax-analisis-tecnico] Fase 0 - Habilitacion, linea base y metodo` | 2026-08-24 |
| `4617417` | `[PJ3896-garantimax-analisis-tecnico] Fase 1 - Inventario y mapeo (PUERTA 1)` | 2026-08-24 |
| `0629d14` | `[PJ3896-garantimax-analisis-tecnico] Fase 2 - Analisis de calidad y riesgos` | 2026-08-24 |
| `3e54bd2` | `[PJ3896-garantimax-analisis-tecnico] Fase 3 - Escenarios y dictamen preliminar` | 2026-08-24 |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** T-27 y T-28 completas, pendiente de autorización de commit. Al autorizarse, **la Etapa A queda con contenido completo en sus 20 capítulos** — lo único que falta es acción humana: T-29 (agendar y realizar la revisión con Aldo Álvarez) y T-30 (abrir el PR, siempre responsabilidad del programador).
- **El dictamen es preliminar y debe leerse como tal:** `analisis/19-dictamen.md` y `analisis/20-resumen-ejecutivo.md` recomiendan E4 como candidato más prometedor, pero lo dicen explícitamente sujeto a T-35 (peso real por dominio) y T-37 (costuras resueltas) en Etapa B.
- **Contexto importante:** el repositorio analizado (`garantimax`) está fijado en `origin/master` = `3771e7f` (2026-08-19), re-verificado sin cambios al cierre de Fase 4 (T-28, 2026-08-24). Si se retoma días después de esto, volver a verificar si `origin/master` avanzó (RNF-14 — no re-sincronizar sin registrar el salto).
- **Hallazgo Crítico pendiente de verificación en cuanto llegue A1:** `mora_corte` (`hallazgos.md` #1) — es la primera tabla a revisar en T-32.
- **Decisión pendiente del solicitante:** fecha de compromiso (aunque sea tentativa) para A1 (`.env` de Supabase) y A3 (fuente de la API de SIGA), para poder planificar cuándo arranca la Etapa B — y agendar la sesión de T-29 con Aldo Álvarez.
- **No tocar:** `garantimax` es de solo lectura durante todo el proyecto. Cualquier necesidad de escritura ahí requiere autorización explícita de TI (RNF-01).

---

*Actualizado automáticamente por Claude Code — Engine CX*
