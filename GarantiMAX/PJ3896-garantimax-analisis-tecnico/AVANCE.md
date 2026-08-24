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
| Estado general | 🟡 En progreso |
| Modelo de ejecución | `claude-sonnet-5` — esfuerzo: alto |
| Etapa activa | **Etapa A** — El proyecto por dentro (ver `PLAN.md` §1.4). La Etapa B (Fases 5–6) queda apartada sin fecha hasta que lleguen los accesos A1 (lectura Supabase, `.env` pendiente) y A3 (fuente de la API de SIGA). |

---

## Resumen de estado

Plan aprobado y registrado en BD el 24-08-2026. Rama funcional creada desde `main` de `enginecx_prd`. El repositorio analizado (`garantimax`) se sincronizó a `origin/master` = `3771e7f` (2026-08-19 11:24 -0400), que es el commit fijado de vigencia (RNF-14).

**Fase 0 completada y commiteada** (T-01 a T-05). **Fase 1 completada** (T-06 a T-15) — **PUERTA 1 pasada**: los 24 módulos, las 46 Edge Functions, las 136 tablas vivas (inferidas) y los 11 canales de Realtime tienen ficha o declaración de cobertura. Durante T-08/T-09 se detectó y escaló un hallazgo de seguridad **Crítico** (`mora_corte` sin restricción de lectura — `hallazgos.md` #1) y durante T-11 uno **Medio, histórico y ya remediado** (`dossier-ia` sin JWT hasta el 03-08-2026 — `hallazgos.md` #2). Pendiente de autorización para el commit de cierre de Fase 1; al autorizarse, arranca Fase 2 (T-16).

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **ETAPA A — El proyecto por dentro** | | | | | | | | |
| **Fase 0 — Habilitación, línea base y método** | `186` | T-01 a T-05 | 1 – 2 | 2026-08-24 | 2026-08-24 | 1 | 0 | ✅ Completada |
| **Fase 1 — Inventario y mapeo** | `187` | T-06 a T-15 | 4 – 6 | 2026-08-24 | 2026-08-24 | 1 | 0 | ✅ Completada |
| **Fase 2 — Análisis de calidad y riesgos** | `188` | T-16 a T-21 | 3 – 4 | | | 0 | 4 | ⏳ Pendiente |
| **Fase 3 — Escenarios y dictamen preliminar** | `189` | T-23 a T-26 | 3 – 4 | | | 0 | 4 | ⏳ Pendiente |
| **Fase 4 — Resumen ejecutivo, revisión y cierre de Etapa A** | `190` | T-27 a T-30 | 2 – 3 | | | 0 | 3 | ⏳ Pendiente |
| **Subtotal Etapa A** | — | 29 tareas | ~13 – 19 | | | 0 | 19 | 🟡 En progreso |
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

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-16 a T-21, T-23 a T-30 | Fases 2 a 4 (Etapa A) | Autorización de commit de cierre de Fase 1 |
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

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `4609986` | `[PJ3896-garantimax-analisis-tecnico] Fase 0 - Habilitacion, linea base y metodo` | 2026-08-24 |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** Fase 1 completa (PUERTA 1 pasada), pendiente de autorización de commit. Al autorizarse, arranca Fase 2 (T-16 — arquitectura y patrones).
- **Contexto importante:** el repositorio analizado (`garantimax`) está fijado en `origin/master` = `3771e7f` (2026-08-19). Si se retoma días después, verificar si `origin/master` avanzó y decidir si re-sincronizar o mantener el commit fijado (el PRD exige declarar vigencia, RNF-14 — no re-sincronizar a mitad de análisis sin registrar el salto).
- **Hallazgo Crítico pendiente de verificación en cuanto llegue A1:** `mora_corte` (`hallazgos.md` #1) — es la primera tabla a revisar en T-32.
- **Decisión pendiente del solicitante:** fecha de compromiso (aunque sea tentativa) para A1 (`.env` de Supabase) y A3 (fuente de la API de SIGA), para poder planificar cuándo arranca la Etapa B.
- **No tocar:** `garantimax` es de solo lectura durante todo el proyecto. Cualquier necesidad de escritura ahí requiere autorización explícita de TI (RNF-01).

---

*Actualizado automáticamente por Claude Code — Engine CX*
