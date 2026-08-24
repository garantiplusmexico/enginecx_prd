# 06 · Integraciones externas

| Campo | Detalle |
|---|---|
| Capítulo | C5 |
| Requerimiento(s) | RF-07 |
| Etapa | A — T-12 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

> Fuente: catálogo de Edge Functions (C4/T-11) + lectura directa de `src/lib/`. Todas las llaves referenciadas por nombre de variable de entorno, nunca transcritas (RNF-03). Ninguna llamada de prueba ejecutada contra servicios de pago (PRD §10).

---

## 1. Inventario completo

| Integración | Uso | Criticidad (hipótesis) | Dónde vive la llave | Costo/modelo |
|---|---|---|---|---|
| **Anthropic (Claude)** | IA en 17 Edge Functions: preevaluación de cobertura, calidad de evidencia, lectura de documentos (boleta/factura/presupuesto/transferencia/odómetro), redacción/mejora de textos, validación de firma de contrato, comando de voz del War Room, análisis de metas, dossier del 1:1 | **Crítica** — es el motor de IA de casi todo el sistema; una caída no bloquea la operación básica pero sí toda la asistencia de IA (que incluye pasos human-in-the-loop, no decisiones autónomas) | Secreto `ANTHROPIC_API_KEY`, solo en Edge Functions (nunca en el front, confirmado en C4) | Por consumo de tokens (pago por uso) |
| **Groq (Whisper)** | Transcripción de audio: bitácora de terreno (`transcribir-bitacora`) y llamadas del call center (`callcenter-transcribir`) | Media | Secreto `GROQ_API_KEY` | Por consumo, más económico que Anthropic para transcripción pura |
| **Resend** | Correo transaccional — 15 de las 46 Edge Functions lo usan: notificaciones de averías, portal, metas, incentivos, tareas, hunter, resumen diario | **Alta** — es el único canal de correo del sistema; su caída silencia todas las notificaciones por email (aunque muchas también notifican in-app) | Secreto `RESEND_API_KEY` + remitentes por dominio (`AVERIA_FROM`, `PORTAL_FROM`, etc. — 8 remitentes distintos, todos del dominio `garantimax.com`, ver C4) | Por volumen de envío |
| **Twilio** | Voz (call center, `@twilio/voice-sdk` en el front + Edge Functions `callcenter-*`) y WhatsApp (plantillas de Meta, `wa-enviar`/`whatsapp-inbound`) | **Alta** — call center y WhatsApp son canales de atención en vivo | Secretos `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_API_KEY`/`SECRET` (softphone), `TWILIO_FROM`, plantillas de contenido (`TWILIO_CONTENT_*`) | Por minuto de llamada + por mensaje de WhatsApp |
| **mindicador.cl** | Indicador oficial de Chile: UF y USD (`monedas-cron`) | Media — alimenta el cálculo de copago a valor presente | Sin llave (API pública gubernamental) | Gratuito |
| **open.er-api.com** | Tipo de cambio ARS, MXN, PEN vía cruce USD→CLP (`monedas-cron`, resiliente: *best-effort*, si una fuente falla las demás igual actualizan) | Media | Sin llave | Gratuito (nivel usado) |
| **Google — Auth** | Login con cuenta Google, vía OAuth de **Supabase Auth** (`supabase.auth.signInWithOAuth({ provider: 'google' })`, `AuthProvider.tsx:300`) — no es una integración directa del código con la API de Google, es Supabase quien la media | Alta (es una de las dos vías de login) | Configuración del proveedor OAuth vive en el panel de Supabase, no en el código | Sin costo directo (parte de Supabase Auth) |
| **Google Calendar** | Enlace `.ics`/calendar.google.com en notificaciones de cita de avería (`averia-notificar`) | Baja | Sin llave (son solo enlaces/adjuntos `.ics`, no llamadas API autenticadas) | Sin costo |
| **Nominatim (OpenStreetMap)** — **no documentado en el PRD original** | Geocodificación de direcciones de salas (`src/features/salas/geoSala.ts:20`) | Baja-Media | Sin llave (servicio público, sujeto a límite de uso razonable de OSM) | Gratuito, con **riesgo de rate-limit** si el volumen de altas de sala crece — Nominatim exige explícitamente uso moderado y puede bloquear IPs que abusen |
| **Sentry** | Observabilidad de errores del frontend | Media | `VITE_SENTRY_DSN`, opcional — "sin ella, la app funciona igual" (`src/lib/monitoreo.ts`) | Plan gratuito, explícitamente sin tracing de performance (`tracesSampleRate: 0`) — decisión deliberada de bajo volumen |
| **Vercel** | Hosting, build, previews por PR | **Crítica** para el despliegue (no para la operación en caliente — una vez desplegado, el front sigue funcionando si Vercel cae, salvo nuevos despliegues) | N/A (plataforma, no llave de API) | Modelo de costo pendiente de A2 |

---

## 2. Hallazgos y precisiones frente al PRD original

- **Nominatim/OpenStreetMap no estaba en el inventario del PRD** (que listaba Anthropic, Groq, Resend, Twilio, mindicador.cl, open.er-api.com, Google, Sentry, Vercel). Es una integración real, aunque de bajo volumen — se agrega aquí. Su modelo de "uso razonable" sin SLA es un riesgo a vigilar si el número de salas crece.
- **Google no es una integración de código directa**: es Supabase Auth quien media el OAuth. Esto es relevante para C15 (T-23): sustituir Supabase Auth por ASP.NET Core Identity implica reconfigurar el proveedor Google OAuth desde cero (Identity soporta proveedores externos, pero la configuración vive en otro lugar).
- **`console.groq.com`** apareció en la extracción de hosts (T-05) pero es, casi con certeza, un enlace de documentación en un comentario, no una llamada de servidor — no se cuenta como integración adicional.
- **Los enlaces `wa.me`, `waze.com`, `maps.google.com`** (detectados en T-05) son botones de salida en la UI (`<a href="wa.me/...">`, deep links de Waze/Maps), no integraciones con llamada autenticada — se excluyen de este inventario por no ser integraciones en el sentido de RF-07, quedando documentados como parte de la experiencia de usuario, no como dependencia técnica.

---

## 3. Cobertura declarada (RNF-11)

**10 integraciones reales documentadas** (7 del PRD original confirmadas + Google Auth vía Supabase + Google Calendar vía enlace + Nominatim, nuevo). Criticidad marcada como hipótesis pendiente de validar con Fabrizio Álvarez (mismo criterio que C2). Modelo de costo completo (cifras) diferido a A2/Etapa B para Twilio, Resend, Anthropic y Groq — aquí solo se documenta el modelo de facturación (por uso/consumo), no el monto.
