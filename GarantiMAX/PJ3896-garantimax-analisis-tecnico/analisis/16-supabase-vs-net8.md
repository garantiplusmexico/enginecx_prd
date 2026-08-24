# 16 · Supabase vs. .NET 8 — qué puede convivir y qué conviene

| Campo | Detalle |
|---|---|
| Capítulo | C15 |
| Requerimiento(s) | RF-17 |
| Etapa | A (estructura) — T-23 · B (peso y costo) — T-35 |
| Versión | 1.0 (Etapa A — estructura; peso, costo real y veredicto final dependen de T-35) |
| Fecha | 2026-08-24 |
| Estado | 🟡 Cerrado en Etapa A — pendiente T-35 |

> Aplica RNF-10 (neutralidad tecnológica): cada servicio se evalúa por lo que aporta hoy y lo que costaría reponerlo, sin partir de que .NET 8 es la respuesta. El veredicto "no conviene sustituirlo" es tan válido como el contrario.

---

## 1. Los cinco servicios, uno por uno

### 1.1 Postgres + RLS

| | Detalle |
|---|---|
| **Qué aporta hoy** | Base de datos relacional completa (136 tablas vivas inferidas, C3) + **autorización a nivel de fila nativa** (RLS) — la seguridad "vive en la base", no en cada endpoint. |
| **Sustituto en .NET 8** | RDS PostgreSQL (mismo motor — Engine ya lo usa, `rules/stack.md`) + EF Core. **El motor de base de datos no cambia**; lo que cambia es dónde vive la autorización. |
| **Esfuerzo** | Bajo para migrar el esquema (mismo Postgres); **alto** para migrar la autorización — cada política RLS (118 tablas con política, C3 §2) tendría que convertirse en lógica de autorización explícita en cada endpoint/handler de .NET, o replicarse como RLS en el mismo RDS Postgres (técnicamente posible, pero no es el patrón estándar de EF Core/Identity). |
| **Riesgo** | Alto si se subestima — es precisamente el riesgo que el PRD identifica como el más peligroso: "un escenario de migración parece viable en el papel y en ejecución resulta mucho más caro". |
| **Veredicto de convivencia** | **El motor conviene conservar** (mismo Postgres, cero fricción). **La autorización no se puede "llevar" a .NET sin reescribirla** — es trabajo real, no una migración de conector. |

### 1.2 Auth

| | Detalle |
|---|---|
| **Qué aporta hoy** | Login por correo/contraseña + OAuth de Google (mediado por Supabase, C6/T-12), gestión de sesión, JWT. Modelo de roles simple (CM/GTE/FARMER/GC) resuelto vía `app_rol()` (C11/T-17). |
| **Sustituto en .NET 8** | ASP.NET Core Identity + JWT (estándar de `rules/coding-guidelines.md` §6). Identity soporta proveedores externos (Google incluido). |
| **Esfuerzo** | Medio — Identity es maduro, pero exige reconfigurar el proveedor OAuth de Google desde cero (hoy vive en el panel de Supabase, no en código) y migrar usuarios/contraseñas (requiere estrategia de reseteo, ya que los hashes de Supabase Auth no son directamente compatibles con Identity). |
| **Riesgo** | Medio — es de los servicios más "estándar" de reemplazar; el riesgo principal es la migración de credenciales existentes, no la arquitectura. |
| **Veredicto de convivencia** | **Sustituible con esfuerzo moderado y bien acotado.** De los cinco servicios, es el más parecido en ambos lados (JWT + roles), y Engine tiene experiencia con Identity. |

### 1.3 Storage

| | Detalle |
|---|---|
| **Qué aporta hoy** | Al menos **9 buckets identificados**: `averia-evidencias`, `boletas`, `wa-media`, `hunter-docs`, `hunter-contratos`, `llamadas` (grabaciones), `asesor-fotos`, `lobby-adjuntos`, `tarea-adjuntos`. Varios son **privados** con acceso mediado por Edge Functions (`leer-boleta`, `leer-factura`, etc., C4). |
| **Sustituto en .NET 8** | S3, en la consola AWS correspondiente al Hub Sur (`rules/infraestructura.md` — nota: hoy no hay una consola AWS definida para Chile/Perú/Argentina más allá de Garanti Chile, hueco ya señalado en `PLAN.md` §9). |
| **Esfuerzo** | Bajo-Medio — mover archivos de bucket a bucket es mecánico; la parte no trivial es replicar el control de acceso (URLs firmadas, capability-por-path como en `leer-odometro`, C4/C11) con las primitivas de S3 (pre-signed URLs cumplen el mismo rol). |
| **Riesgo** | Bajo — es el servicio más desacoplado de lógica de negocio específica de Supabase. |
| **Veredicto de convivencia** | **Sustituible, esfuerzo bajo-medio.** Requiere definir primero la consola/región AWS del Hub Sur (pregunta abierta transversal). |

### 1.4 Edge Functions

| | Detalle |
|---|---|
| **Qué aporta hoy** | 46 funciones (C4/T-11): serverless en Deno, con `SUPABASE_SERVICE_ROLE_KEY` para bypass de RLS, 17 con IA (Anthropic), 15 con correo (Resend), 7 con Twilio, 10 cron. |
| **Sustituto en .NET 8** | Contenedores Docker en ECS + Fargate (`rules/arquitectura.md` §1) — un contenedor por función o agrupadas en un servicio de API, más un scheduler (ECS Scheduled Tasks o EventBridge) para los 10 cron. |
| **Esfuerzo** | Alto en volumen (46 funciones), pero **desigual por función** — ya evaluado individualmente en C4 (mayoría "Alta" portabilidad, algunas "Media": `callcenter-ivr` por TwiML, `whatsapp-inbound` por su ramificación de estado). |
| **Riesgo** | Medio — el mayor riesgo no es técnico sino de **superficie**: 46 funciones autocontenidas en Deno se convierten en, como mínimo, un servicio .NET con 46 endpoints o varios microservicios — una decisión de arquitectura por sí sola (monolito modular vs. microservicios, `rules/arquitectura.md`). |
| **Veredicto de convivencia** | **Sustituible, con la salvedad de que "portar 46 funciones" es un proyecto de tamaño no trivial**, no una tarea mecánica — cada una lleva su propia lógica de negocio (ver detalle por función en C4). |

### 1.5 Realtime

| | Detalle |
|---|---|
| **Qué aporta hoy** | 11 canales (C8/T-14) — 9 de 11 necesarios funcionalmente, 2 ya sustituibles hoy por polling. Los 3 de `postventa` escalan por caso abierto, no por techo fijo. |
| **Sustituto en .NET 8** | **SignalR frente a Supabase Realtime** — obligatorio evaluar (RF-17). |
| **Esfuerzo y costo — el más subestimable de los cinco (ver `PLAN.md` §12 nota 5)** | No es "cambiar de librería". Requiere: **(a)** un servicio SignalR desplegado en ECS + Fargate; **(b)** un **backplane** (Redis o Azure SignalR) porque con más de una instancia de ECS detrás del ALB, los grupos de SignalR no se comparten solos entre instancias; **(c)** afinidad de sesión en el ALB (sticky sessions) para las conexiones WebSocket; **(d)** reescribir los 11 canales del lado cliente (`.channel()` → conexión y grupos de SignalR); **(e)** — la pieza que casi siempre se olvida — **`postgres_changes` no tiene equivalente gratuito del otro lado**: hoy Postgres emite el evento solo cuando cambia una fila; en .NET, algo tiene que **emitir explícitamente** ese evento al hub de SignalR (típicamente desde el mismo código que hace el `UPDATE`/`INSERT`, o vía un listener de `LISTEN/NOTIFY` de Postgres que alguien tiene que construir y operar). |
| **Riesgo** | **Alto** — es el servicio donde subestimar el esfuerzo produce el mayor error de estimación de todo el proyecto. |
| **Veredicto de convivencia** | **Depende enteramente de la latencia real que exige la operación** (pregunta abierta A6, `PLAN.md` §12 nota 5) — si War Room y call center toleran unos segundos de polling, gran parte del costo de §1.5 desaparece; si exigen sub-segundo real, el costo completo de (a)-(e) aplica. **No se puede dar un veredicto único sin ese dato.** |

---

## 2. Reparto por dominio — estructura (T-23), sin peso (T-35)

Con la segmentación de C2/T-07 y C3, el reparto **estructural** (cuántas tablas/RPCs/funciones hay a cada lado, no cuánto pesan en filas o costo):

| | Comercial | Operación de garantías | Transversal |
|---|---|---|---|
| Tablas (familias, C3 §3) | `salas_*` (12), `hunter_*` (9), `incentivo_*` (6), `visitas_*`/`americar_*` (5) | `av_*` (23), `mora_*` (3), `cc_*` (6, costura) | `portal_*` (9), `proveedor_*` (5), `usuario_*`/`grupos_*`/`gasto_*`/`tarea_*`/`solicitud_*` (resto) |
| RPCs (familias, C3 §5) | `salas_*`/`cierre_salas_*` (~19), `hunter_*` (~12), `incentivos_*` (~9), `vendedor_*` (~11) | `av_*` (~40), `facturacion_*` (~8) | `solicitud_*`/`tarea_*`/`proveedor_*` (~15), `cc_kpi_*` (5) |
| Edge Functions (C4) | Hunter (4), Metas/Incentivos (4) | Averías (15), Portal (7) | Comunicación/utilidades (10), Call center (3) |
| Canales Realtime (C8) | 8 de 11 (`warroom`, `callcenter`) | 3 de 11 (`postventa`) | — |

**Lectura estructural (sin peso real):** el dominio de **operación de garantías** concentra la mayor densidad de RPCs por tabla (`av_*`: 23 tablas, ~40 RPCs — casi 2 RPCs por tabla) y las Edge Functions más numerosas y complejas (averías: 15 funciones, incluidas las dos más largas del sistema, C4). El dominio **comercial** es más ancho en tablas y módulos (C2) pero con RPCs más repartidas. **Sin el peso real en filas/costo (T-35), no se puede concluir si E4 conviene** — la estructura sugiere que operación de garantías es más "pesada" en lógica, pero eso no dice nada sobre el costo de infraestructura, que depende de volumen y tráfico, no de cantidad de funciones.

---

## 3. Cobertura declarada (RNF-11)

Los cinco servicios evaluados con veredicto estructural (100%). **SignalR vs. Realtime** e **Identity vs. Auth** cubiertos explícitamente como exige RF-17. **No cubierto en esta etapa, explícitamente diferido a T-35:** el reparto por *peso* (filas, invocaciones, mensajes, costo real) entre dominios — la pregunta central de la Dirección ("¿qué alberga Supabase?") solo se responde con números en Etapa B, no aquí.
