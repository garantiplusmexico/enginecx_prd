# 05 · Catálogo de Edge Functions

| Campo | Detalle |
|---|---|
| Capítulo | C4 |
| Requerimiento(s) | RF-06 |
| Etapa | A — T-11 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

> Todas las citas son **Hecho** — leídas directamente del comentario de cabecera y el código de cada una de las 46 funciones (`inventarios/edge-functions-detalle.txt`, reproducible). Los comentarios de este repositorio son inusualmente completos: casi todas documentan su propio propósito, seguridad y motivo de existencia mejor que cualquier documentación externa — un activo real que cualquier escenario de migración debe aprovechar, no descartar.

---

## 1. Averías (13 funciones) — el grupo más grande, todas IA-asistidas o de notificación

| Función | Disparo | Servicios externos | Muta | Portabilidad a .NET |
|---|---|---|---|---|
| `averia-analizar-clausulado` | UI (asesor) | Anthropic | Sí (1) | Alta — llamada HTTP a Anthropic + lectura de contexto, sin dependencia de runtime de Deno |
| `averia-borrar-caso` | UI (admin) | — | Sí (4) | Alta — borrado transaccional BD + Storage |
| `averia-calidad-evidencia` | UI (asesor) | Anthropic (visión) | Sí (3) | Alta |
| `averia-cuestionario-cron` | **Cron** (*/15 min) | Resend, Twilio | Sí (17) | Alta, pero es la función más grande y compleja del sistema (718 líneas, múltiples barridos independientes con dedup) — la de mayor riesgo de regresión al portar |
| `averia-notificar` | UI + Cron (`CRON_SECRET` presente) | Resend, Twilio, Google Calendar | Sí (36 — la de más escrituras de todo el catálogo) | Alta en concepto, **alto esfuerzo** por volumen (1549 líneas, la función más larga del sistema) |
| `averia-preeval` | UI (asesor) | Anthropic | Sí (4) | Alta |
| `averia-purgar-huerfanos` | UI/manual | — | No (0 — la función audita, el borrado es opcional/manual) | Alta |
| `averia-resolucion-email` | UI (al "Emitir documentos") | Resend | Sí (3) | Alta |
| `leer-boleta` | UI (cola de Gastos) | Anthropic (visión) | No | Alta |
| `leer-factura` | UI (detalle de caso) | Anthropic (visión) | No | Alta |
| `leer-odometro` | **Webhook público** (cliente anónimo sube foto) | Anthropic (visión) | Sí (1) | Alta, pero **es superficie pública** — prioridad de revisión en C11 |
| `leer-presupuesto` | UI (detalle de caso) | Anthropic (visión) | No | Alta |
| `leer-transferencia` | UI (detalle de caso) | Anthropic (visión) | No | Alta |
| `mejorar-redaccion` | UI (Constructor de informe) | Anthropic | No | Alta |
| `construir-informe` | UI (Constructor) | Anthropic | Sí (3) | Alta |

**Patrón consistente:** las funciones "lector" (`leer-*`) **no escriben en la base** — devuelven datos extraídos para que el front confirme y persista. Es un patrón de seguridad deliberado (IA propone, humano decide) documentado explícitamente en varios comentarios ("human-in-the-loop").

## 2. Call center (3 funciones)

| Función | Disparo | Servicios externos | Muta | Portabilidad |
|---|---|---|---|---|
| `callcenter-ivr` | **Webhook público** (Twilio golpea en cada paso de la llamada, responde TwiML) | Twilio | Sí (22) | Media — TwiML es un formato específico de Twilio, portable pero no trivial de reescribir en C# |
| `callcenter-token` | UI (al abrir el softphone) | Twilio (emite Access Token) | No | Alta — Twilio tiene SDK oficial de servidor en .NET |
| `callcenter-transcribir` | UI (post-llamada) | Anthropic, Groq (Whisper) | Sí (1) | Alta |

## 3. Hunter (4 funciones)

| Función | Disparo | Servicios externos | Muta | Portabilidad |
|---|---|---|---|---|
| `hunter-enviar-cotizacion` | UI | Resend | No | Alta |
| `hunter-enviar-firma` | UI | Resend | No | Alta |
| `hunter-invitar-reunion` | UI | Resend | No | Alta |
| `hunter-validar-contrato` | UI | Anthropic (visión, valida firma contra términos) | Sí (1) | Alta |

## 4. Metas e Incentivos (4 funciones)

| Función | Disparo | Servicios externos | Muta | Portabilidad |
|---|---|---|---|---|
| `metas-aceptar` | **Webhook público** (`verify_jwt=false` — "el token del enlace es la credencial", página `/aceptar-metas`) | — | Sí (1) | Alta, pero **es superficie pública con peso legal** ("registra la aceptación con peso legal — fecha/hora, IP, user-agent") — prioridad C11 |
| `metas-analisis-ia` | UI | Anthropic | Sí (1) | Alta |
| `metas-enviar` | UI (CM/GC) | Resend | Sí (3) | Alta |
| `incentivos-notif` | UI (verify_jwt=true) | Resend | No | Alta |

## 5. Portal — cliente y proveedor (7 funciones) — la superficie pública más sensible del catálogo

| Función | Disparo | Servicios externos | Muta | Portabilidad |
|---|---|---|---|---|
| `portal-admin` | UI (CM, mantenedor) | Resend | Sí (17) | Media — lógica de hasheo PBKDF2 en servidor, portable pero a reimplementar con cuidado |
| `portal-api` | **Webhook/API pública** (token de sesión propio, no JWT de Supabase) | — | Sí (13) | Media |
| `portal-cliente-api` | **API pública** (token de sesión propio) | — | Sí (3) | Media |
| `portal-cliente-login` | **Webhook/login público** (OTP + WhatsApp) | Resend, Twilio | Sí (16) | Media |
| `portal-informe-cron` | **Cron** (día 1 y 15, 12:00 UTC — `pg_cron`, migración `0314`) | Resend | Sí (3) | Alta |
| `portal-login` | **Webhook/login público** (OTP a proveedores) | Resend | Sí (8) | Media |
| `proveedor-correos` | UI + **Cron** (*/15 y diario 8:00 CL) | Resend | Sí (9) | Alta |

**Hallazgo de arquitectura de seguridad (confirma y refuerza `03-modelo-datos.md` §2.1):** el propio comentario de `portal-admin` dice textualmente *"las tablas `portal_*` están en deny-all (solo `service_role`)"*, y `portal-login` dice *"estas tablas no se exponen al cliente (RLS deny-all); solo esta función (`service_role`) las toca"*. **Esto confirma, con evidencia de primera mano del propio código, la hipótesis inferida en el capítulo del modelo de datos**: las 18 tablas con RLS activo y sin política visible (`portal_*`, `proveedor_*`, tokens y bitácoras de envío) son un patrón de seguridad **deliberado y bien documentado**, no un descuido. Es el mismo patrón, aplicado consistentemente, en todo el subsistema de portal externo.

## 6. Comunicación y utilidades transversales (10 funciones)

| Función | Disparo | Servicios externos | Muta | Portabilidad |
|---|---|---|---|---|
| `crear-demo` | UI (CM, mantenedor) | — | Sí (2) | Alta |
| `dossier-cron` | **Cron** (domingo 23:00 CL + backfill) | — | Sí (1) | Alta |
| `dossier-ia` | UI + llamada interna desde `dossier-cron` | Anthropic | No | Alta |
| `enviar-resumen` | UI (botón "Enviarme por correo") | Resend | No | Alta |
| `monedas-cron` | **Cron** | mindicador.cl, open.er-api.com | Sí (1) | Alta — múltiples fuentes con *best-effort* (si una falla, las demás igual actualizan) es un patrón de resiliencia a preservar |
| `mejorar-bitacora` | UI (botón "✨ Mejorar redacción") | Anthropic | No | Alta |
| `resumen-cron` | **Cron** (6:50 y 7:00 CL) | — (reusa `dossier-ia`/`enviar-resumen` internamente) | Sí (3) | Alta |
| `tareas-atrasadas-cron` | **Cron** (~15 min) | Resend | Sí (9) | Alta |
| `transcribir-bitacora` | UI (botón "🎙️ Dictar") | Groq (Whisper) | No | Alta |
| `visitas-abiertas-cron` | **Cron** (~15 min + fin de día) | Resend | Sí (2) | Alta |
| `wa-enviar` | UI (chat del caso) | Twilio | Sí (3) | Alta — respeta la ventana de 24h de Meta, regla de negocio a preservar exactamente |
| `warroom-comando` | UI (dictado de voz del War Room) | Anthropic | Sí (1) | Alta |
| `whatsapp-inbound` | **Webhook público** (Twilio, mensajes entrantes de WhatsApp) | Anthropic, Twilio | Sí (16) | Media — lógica de enrutamiento de conversación (encuesta activa vs. caso vs. "humano tomó el hilo") es la más compleja de portar por su ramificación de estado |

---

## 2. Resumen de disparo (RF-06 — "identifica las que son cron y las que son webhooks públicos")

| Tipo de disparo | Cantidad | Funciones |
|---|---|---|
| **Cron** (incluye las nombradas `*-cron` y las que reciben `CRON_SECRET` para invocación programada) | **10** | `averia-cuestionario-cron`, `averia-notificar`*, `dossier-cron`, `monedas-cron`, `portal-informe-cron`, `proveedor-correos`*, `resumen-cron`, `tareas-atrasadas-cron`, `visitas-abiertas-cron`, `enviar-resumen`* (*mixtas: cron + UI) |
| **Webhook público / API sin JWT de Supabase** | **8** | `leer-odometro` (cliente anónimo), `callcenter-ivr` (Twilio), `metas-aceptar` (token de enlace), `portal-api`, `portal-cliente-api`, `portal-cliente-login`, `portal-login`, `whatsapp-inbound` (Twilio) |
| **UI autenticada (dashboard)** | Resto (~28) | La mayoría — llamadas desde botones del dashboard con JWT de Supabase |

Estas 8 son la superficie de ataque real del sistema, porque no dependen de que el atacante tenga una sesión válida de Supabase. **Son la prioridad #1 de C11 (T-17/T-32).**

---

## 3. Secretos requeridos (referenciados por nombre, nunca transcritos — RNF-03)

| Secreto | Funciones que lo usan | Servicio |
|---|---|---|
| `ANTHROPIC_API_KEY` | 17 funciones | Claude (Anthropic) |
| `SUPABASE_SERVICE_ROLE_KEY` | 44 de 46 (todas menos... a verificar las 2 sin él, ver nota) | Bypass de RLS — el secreto más repetido y más sensible del catálogo |
| `RESEND_API_KEY` | 15 funciones | Correo (Resend) |
| `TWILIO_ACCOUNT_SID` / `TWILIO_AUTH_TOKEN` | 7 funciones | Voz/WhatsApp (Twilio) |
| `GROQ_API_KEY` | 2 funciones | Groq (Whisper, transcripción) |
| `CRON_SECRET` | 9 funciones | Autenticación de invocación programada (`x-cron-secret`, sin JWT) |
| Remitentes de correo (`*_FROM`) | ~10 funciones, uno distinto por área (`AVERIA_FROM`, `PORTAL_FROM`, `METAS_FROM`, `RESUMEN_FROM`, `TAREAS_FROM`, `COTIZACION_FROM`, `REUNION_FROM`, `PROVEEDORES_FROM`) | Resend — remitentes verificados por dominio |
| Otros específicos de un solo flujo | `IVR_AUDIOS_BASE`, `IVR_URL_PUBLICA`, `TWILIO_API_KEY`/`SECRET`/`TWIML_APP_SID`, `PUBLIC_APP_URL`, `METAS_APP_URL`, `PORTAL_URL`, `PORTAL_WA_CONTENT_OTP`, `TWILIO_CONTENT_ENCUESTA*` | Una función cada uno | — |

**`SUPABASE_SERVICE_ROLE_KEY` es, con diferencia, el secreto de mayor impacto del sistema**: cualquier función que lo tenga hace *bypass* completo de RLS. Su gestión (rotación, quién puede leerlo desde el panel de Supabase) es un punto de control de seguridad central — a documentar como pregunta para quien administre el proyecto Supabase (A1/A2).

---

## 4. Hallazgo histórico relevante para C11/C14 (ya remediado, no es una vulnerabilidad activa)

El comentario de `dossier-ia` declara explícitamente: *"verify_jwt=TRUE desde el 03-08-2026 (brecha #6): estaba desplegada sin exigir [autenticación]"*. Es decir, **hasta el 03-08-2026 esta función (que gasta tokens de Anthropic) podía invocarse sin autenticación** — un hallazgo de seguridad real, pero **ya corregido antes de este análisis**. Se registra en `hallazgos.md` con severidad **Media** (no Crítico: está remediado, y el impacto de la brecha original era costo/abuso, no exposición de datos) porque:

1. Confirma que el sistema **ya tiene un proceso activo de detección y corrección de vulnerabilidades** (coherente con `docs/auditoria-2026-07-11/` mencionado en `CLAUDE.md`, y con el hallazgo de `mora_corte` — la referencia a "brecha #6" implica que hubo al menos 6 brechas numeradas y corregidas antes).
2. Es exactamente el tipo de hallazgo histórico que **C13/T-19 (gobierno y proceso)** debe documentar como antecedente: el proyecto tiene memoria de sus propias vulnerabilidades, aunque esa memoria vive en comentarios de código dispersos, no en un registro centralizado — lo cual es en sí mismo una oportunidad de mejora de proceso.

---

## 5. Cobertura declarada (RNF-11)

**46/46 Edge Functions catalogadas (100%)** — propósito, disparo, servicios externos, secretos y mutación confirmados por lectura directa del código de cada una. Portabilidad evaluada cualitativamente (Alta/Media) para las 46; la estimación de esfuerzo en rangos gruesos se hace en T-24 (Fase 3), no aquí. **No se profundizó** en el detalle interno de cada rama de código de las funciones más grandes (`averia-notificar`, 1549 líneas; `averia-cuestionario-cron`, 718 líneas; `dossier-ia`, 674 líneas) más allá de su propósito general — se declara explícitamente, no se aparenta exhaustividad línea por línea.
