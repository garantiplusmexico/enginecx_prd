# 12 · Auditoría de seguridad

| Campo | Detalle |
|---|---|
| Capítulo | C11 |
| Requerimiento(s) | RF-13 |
| Etapa | A (código, RLS declarado) — T-17 · B (RLS real) — T-32 |
| Versión | 1.0 (Etapa A — RLS declarado en migraciones, no verificado contra la base real) |
| Fecha | 2026-08-24 |
| Estado | 🟡 Cerrado en Etapa A — pendiente T-32 |

> Este capítulo consolida y referencia hallazgos ya producidos y escalados en Fase 1 (`hallazgos.md` #1, #2) más lo nuevo de T-17. La verificación de que RLS está *efectivamente activo* en la base real (no solo declarado en migraciones) es exclusiva de T-32 — ver `03-modelo-datos.md` §2.

---

## 1. `anon key` vs `service_role` — separación correcta, confirmada

- **`SUPABASE_SERVICE_ROLE_KEY` no aparece ni una sola vez en `src/`** (verificado con `grep`, 0 coincidencias) — confirma lo que `CLAUDE.md` y los propios comentarios de las Edge Functions afirman: el bypass de RLS vive exclusivamente en el servidor.
- El cliente de Supabase del frontend (`src/lib/supabase.ts`) usa únicamente `VITE_SUPABASE_ANON_KEY`, y está envuelto en un **guard de modo demo** (`src/lib/demoGuard.ts`): intercepta toda escritura si el usuario autenticado es demo, con una **lista blanca explícita de RPCs de escritura más un backstop por patrón de verbos** ("para que una RPC de escritura NUEVA quede bloqueada sola aunque nadie la agregue [a la lista]"). Es defensa en profundidad bien diseñada — no depende de que alguien recuerde actualizar una lista.

## 2. Endpoints públicos — las 8 Edge Functions sin JWT (ver C4/T-11)

Ya catalogadas: `leer-odometro`, `callcenter-ivr`, `metas-aceptar`, `portal-api`, `portal-cliente-api`, `portal-cliente-login`, `portal-login`, `whatsapp-inbound`. Todas verificadas con un mecanismo de autenticación **propio** (no JWT de Supabase): token en el path (`leer-odometro`), token de sesión hasheado en tabla `deny-all` (`portal-*`), firma de Twilio implícita en el webhook (`callcenter-ivr`, `whatsapp-inbound`), o el propio token del enlace como credencial (`metas-aceptar`, con "peso legal" según su comentario). **Ninguna de las 8 expone datos sin algún control** — el patrón es consistente y deliberado, no un descuido.

## 3. CORS — política mixta, priorizada donde más importa (hallazgo, severidad Baja-Media)

**Hecho:** de las 46 funciones, **34 responden `Access-Control-Allow-Origin: '*'`** (cualquier origen); **8 usan un patrón de validación explícita** (`ORIGEN_OK.test(origen) ? origen : 'https://www.garantimax.com'`): `crear-demo`, `dossier-ia`, `leer-odometro`, `metas-aceptar`, `portal-api`, `portal-cliente-api`, `portal-cliente-login`, `portal-login`.

**Evaluación:** el CORS abierto en funciones protegidas por JWT es de **riesgo bajo en la práctica** — CORS no elude la autenticación por token (a diferencia de auth por cookie), así que un sitio malicioso que dispare la petición desde el navegador de la víctima no tendría el JWT de sesión para autenticarse. **El patrón de restricción SÍ está aplicado, y de forma priorizada**: exactamente en las funciones administrativas (`crear-demo`), la que tuvo la brecha #6 (`dossier-ia`, ya remediada, ver `hallazgos.md` #2), y todo el subsistema de portal externo (`portal-*`) — la superficie más sensible. **No es inconsistencia accidental: es donde el equipo decidió que importaba más.** Queda como hallazgo menor: estandarizar la validación de origen en el resto no cuesta mucho y cierra el margen por completo.

## 4. Datos personales — tratamiento observado

- **Clientes:** RUT, nombre, teléfono, email, dirección viven en `clientes`, `contratos`, `av_casos` y tablas relacionadas — sin RLS ausente detectado salvo el caso ya escalado de `mora_corte` (`hallazgos.md` #1).
- **Anonimización en desarrollo/pruebas:** no se encontró evidencia de un proceso de anonimización de datos para ambientes de prueba — las tablas `portal_demo_caso`/`portal_demo_contrato` (candidatas a datos muertos, C5'/T-10) sugieren que hubo un intento de ambiente de demostración separado, pero no se confirmó si contiene datos reales anonimizados o completamente sintéticos. **Pregunta abierta para Fabrizio.**
- **Logging:** `src/lib/monitoreo.ts` (Sentry) envía `err.message` y un tag de `contexto` — no se observó envío deliberado de payloads completos de datos de negocio a Sentry, lo cual es la práctica correcta (evita que un RUT o número de contrato termine en un servicio externo de logging).

## 5. Roles y permisos — modelo simple, nativo de RLS, distinto del estándar de Engine

**Hecho:** el modelo de roles observado es **CM, GTE, FARMER, GC** (Country Manager, Gerente de Territorio/Cuentas, asesor de terreno, Gerente de Cuentas), resuelto vía `app_rol()` (función `security definer`, C3/T-08) y consumido directamente en las políticas RLS de cada tabla — no hay una capa de políticas nombradas al estilo `[Authorize(Policy = Policies.X)]` de `rules/coding-guidelines.md` §6.

**Evaluación:** es coherente con la plataforma (Supabase está diseñado para que RLS *sea* la capa de autorización) y no es, en sí, un defecto — es una arquitectura de autorización distinta a la de .NET/Identity, no una ausencia de autorización. **El costo aparece solo si se migra**: ASP.NET Core Identity no tiene un equivalente 1:1 de "una función SQL que la política de cada tabla consulta"; portar este modelo exige decidir entre políticas de autorización a nivel de controlador/handler (el patrón estándar de Engine) o replicar row-level security en la capa de datos de .NET (más caro, menos nativo). Insumo directo para C15/T-23 (Identity vs. Supabase Auth).

## 6. Consolidado de hallazgos de este capítulo

| Hallazgo | Severidad | Dónde se registró |
|---|---|---|
| `mora_corte` sin restricción de lectura | **Crítico** | `hallazgos.md` #1 (T-08/T-09, ya escalado) |
| `dossier-ia` sin JWT hasta 03-08-2026 | Medio (histórico, remediado) | `hallazgos.md` #2 (T-11, ya escalado) |
| CORS abierto en 34/46 funciones (riesgo bajo por JWT, pero inconsistente) | Bajo-Medio | Se agrega a `hallazgos.md` en este capítulo (#5) |
| Tratamiento de datos en ambiente demo no confirmado (`portal_demo_*`) | Informativo / pregunta abierta | `preguntas-abiertas.md` |

---

## 7. Cobertura declarada (RNF-11)

Cubierto con evidencia de código: separación anon/service_role, los 8 endpoints públicos, política de CORS completa (46/46 funciones clasificadas), tratamiento de datos personales observable desde el código, y el modelo de roles frente al estándar de Engine. **No cubierto en esta etapa, explícitamente diferido a T-32:** si RLS está *efectivamente* activo en cada tabla en la base real (más allá de lo declarado en migraciones), y si las políticas reales coinciden con las declaradas. **No se realizó ningún intento de explotación** — ni siquiera de las funciones públicas — más allá de la lectura de código (RNF-01, PRD §10).
