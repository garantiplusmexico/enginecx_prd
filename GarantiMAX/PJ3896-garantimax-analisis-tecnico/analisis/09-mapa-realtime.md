# 09 · Mapa de Realtime

| Campo | Detalle |
|---|---|
| Capítulo | C8 |
| Requerimiento(s) | RF-10 |
| Etapa | A — T-14 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

> Todas las citas son **Hecho** (archivo:línea, commit `3771e7f`). Baseline verificado al generar `PLAN.md`: 11 canales, 3 módulos. Confirmado aquí con lectura completa de cada uno.

---

## 1. Los 11 canales, uno por uno

### `warroom` (5 canales)

| # | Canal | Archivo:línea | Tabla(s) / evento | Consumidor | Qué dispara |
|---|---|---|---|---|---|
| 1 | `war_room_visitas` | `visitasRealtime.ts:29` | `visitas` (`INSERT`, `UPDATE`) | Multiplexor compartido — ver nota abajo | Feed de eventos y contadores del War Room |
| 2 | `war_room_visitas_en_curso` | `useVisitasEnCurso.ts:42` | `visitas_en_curso` (`*`, incluye `DELETE`) | Panel "asesores en sala ahora mismo" | Check-in/check-out en vivo |
| 3 | `war_room_interacciones` | `useWarRoomEventos.ts:99` | `interacciones_vendedor` (`INSERT`) | Feed de eventos (columna 3 del War Room) | Lobby, tarea cumplida, otras interacciones |
| 4 | `war_room_sala_vendedores` | `useWarRoomEventos.ts:122` | `sala_vendedores` (`*`) | Feed de eventos | Asignación/remoción de vendedor, cambio de jefe de sala |
| 5 | `warroom-comando` | `WarRoomView.tsx:594` | `tv_dashboard_state` (`UPDATE`) | Tablero público `/tv` (kiosko 4K, `CLAUDE.md`) | Comando remoto enviado al War Room público — patrón "control remoto", no dato de negocio |

**Hallazgo de buena práctica (para C10):** `visitasRealtime.ts` documenta explícitamente en su propio comentario que consolidó **dos canales redundantes** en uno (`useVisitasRecientes` y `useWarRoomEventos` abrían cada uno su propio websocket a la misma tabla `visitas` en el kiosko 24/7). El archivo implementa un patrón *canal único + subscribers internos* para evitar duplicar conexiones. Es exactamente el tipo de optimización que cualquier escenario de destino (SignalR incluido) debe preservar — de lo contrario el "ahorro" de migrar se pierde reintroduciendo el problema que ya se resolvió aquí.

### `callcenter` (3 canales)

| # | Canal | Archivo:línea | Tabla(s) / evento | Consumidor | Qué dispara |
|---|---|---|---|---|---|
| 6 | `softphone_llamadas` | `telefonoStore.ts:268` | `cc_llamadas` (`INSERT`, `UPDATE`) | Widget flotante de alertas (todo agente conectado) | Cliente entrando al IVR en vivo — alerta sonora + visual |
| 7 | `cc_presencia_panel` | `TelefonoPanel.tsx:485` | `cc_presencia` (`*`) | Panel de presencia del Country Manager | Recarga la lista de quién está conectado (dispara un `SELECT`, no consume el payload del evento) |
| 8 | `cc_kpi_vivo` | `TelefonoKpis.tsx:297` | `cc_presencia` (`*`) + `cc_llamadas` (`*`) | Panel de KPIs en vivo | Recarga el snapshot vía RPC `cc_kpi_vivo` |

**Hallazgo (para C12/rendimiento):** `TelefonoKpis.tsx` combina Realtime **con un polling de respaldo cada 15 segundos** (`setInterval(..., 15_000)`) sobre la misma función. Es decir, el "vivo" no depende exclusivamente de Realtime — hay una red de seguridad por si el canal se cae o se pierde un evento. Dato relevante para C16/T-24: si se sustituyera Realtime por polling puro, la latencia máxima ya está acotada de facto a 15s en este panel, aunque el promedio hoy sea sub-segundo.

**Patrón repetido en #7 y #8:** ninguno de los dos consume el `payload` del evento — ambos lo usan solo como disparador para volver a pedir los datos (`() => void cargar()`). Esto es relevante para el veredicto de sustituibilidad: son candidatos naturales a **refresco por consulta** (polling corto) sin pérdida de funcionalidad, a diferencia de #1 y #6, que sí consumen el payload directamente.

### `postventa` (3 canales)

| # | Canal | Archivo:línea | Tabla(s) / evento | Consumidor | Qué dispara |
|---|---|---|---|---|---|
| 9 | `av-cuestionario-${casoId}` | `casosDb.ts:1780` | `av_cuestionarios` (`*`, filtrado por `caso_id`) | Vista del SAC sobre un caso | El SAC ve lo que el cliente está escribiendo en el cuestionario **antes de que lo envíe** — es el único canal de los 11 con ese requisito específico (ver el propio comentario del código) |
| 10 | `av-caso-${casoId}` | `casosDb.ts:1850` | `av_casos` (`UPDATE`, filtrado) + `av_eventos_caso` (`INSERT`, filtrado) | Detalle de un caso de avería | Cualquier cambio de estado o evento (fotos, transición, cuestionario) refresca el detalle |
| 11 | `wa_caso_${casoId}` | `ChatWhatsapp.tsx:84` | `av_wa_mensajes` (`INSERT`, `UPDATE`, filtrado por `caso_id`) | Chat de WhatsApp embebido en el caso | Mensajes entrantes/salientes de WhatsApp en vivo |

**Patrón de canal por instancia:** a diferencia de `warroom` y `callcenter` (canales fijos, uno por tipo de dato), los 3 canales de `postventa` se abren **por `casoId`** — un canal nuevo por cada caso que un agente tiene abierto. Relevante para dimensionar el costo de Realtime en C15/T-23: el número de conexiones concurrentes escala con casos abiertos simultáneamente, no con un techo fijo de 11.

---

## 2. Veredicto de necesidad y sustituibilidad

| Canal | Latencia que exige el caso de uso | Veredicto |
|---|---|---|
| `war_room_visitas`, `war_room_visitas_en_curso` | Alta — es el propósito del kiosko 24/7 (el propio código **ya optimizó** para esto, consolidando canales) | **Necesario.** Sustituirlo por polling reintroduciría el problema de carga que el propio código ya resolvió una vez. |
| `war_room_interacciones`, `war_room_sala_vendedores` | Alta — feed en vivo del War Room | **Necesario**, mismo argumento. |
| `warroom-comando` | Baja frecuencia, pero latencia de control percibida como inmediata (es un "control remoto" para un tablero público) | **Necesario, pero de bajísimo volumen** — un evento por comando enviado, no por actividad de negocio. |
| `softphone_llamadas` | Alta — alerta de cliente entrando al IVR en vivo, con audio | **Necesario.** |
| `cc_presencia_panel`, `cc_kpi_vivo` | Ya conviven con polling de 15s de respaldo | **Sustituible por refresco por consulta** sin pérdida funcional relevante — son los dos candidatos más claros de los 11 para no migrar como Realtime si el escenario de destino no lo trae "gratis". |
| `av-cuestionario-${casoId}` | Alta — requisito explícito de ver la escritura en vivo del cliente | **Necesario**, y es el caso más específico: sin Realtime (o un mecanismo equivalente de push), esta funcionalidad concreta desaparece, no se degrada. |
| `av-caso-${casoId}`, `wa_caso_${casoId}` | Media-alta — experiencia de chat y de detalle de caso en vivo | **Necesario para la experiencia actual**, aunque de los tres canales de postventa son los que más tolerarían un polling corto (2-3s) sin que el agente lo perciba como degradación severa. |

**Resultado agregado:** de los 11 canales, **2 (`cc_presencia_panel`, `cc_kpi_vivo`) son sustituibles hoy mismo por refresco por consulta sin cambio de UX perceptible** — ya conviven con un fallback de polling. Los otros **9 requieren push real** para no perder funcionalidad o degradar visiblemente la experiencia, con **`av-cuestionario-${casoId}`** como el caso más estricto (ver escritura en tiempo real, no solo el resultado final).

**Cobertura:** 11/11 canales localizados, documentados y con veredicto (100%, RNF-11). No se identificaron canales adicionales fuera de estos tres módulos al re-verificar contra `3771e7f`.

---

## 3. Insumo para C15/T-23 (Supabase vs. .NET 8 — costo de reponer Realtime)

- **9 de 11 canales necesitan equivalente funcional real** (no solo polling) si se sustituye Supabase Realtime.
- Los canales de `postventa` (3 de 11) escalan **por caso abierto**, no por un número fijo — relevante para dimensionar cuántas conexiones concurrentes de SignalR/backplane se necesitarían en horas pico.
- El propio código ya resolvió un problema de canales duplicados una vez (`visitasRealtime.ts`) — cualquier reimplementación en .NET debe partir de ese mismo cuidado (un hub compartido por tabla, no un hub por componente), o el costo de infraestructura sube sin necesidad.
- Los 2 canales sustituibles (`cc_presencia_panel`, `cc_kpi_vivo`) son candidatos a **no migrar como tiempo real** en ningún escenario, reduciendo en algo la superficie de "qué hay que reponer".

## 4. Segmentación por dominio (insumo de E4, ver `PLAN.md` §1.3)

**Los 11 canales están, sin excepción, en los dos dominios "comercial / atención"**, no en "operación de garantías" en el sentido de back-office:

- `warroom` (5 canales) → dominio **comercial / seguimiento de vendedores**.
- `callcenter` (3 canales) → dominio **comercial / atención**, transversal.
- `postventa` (3 canales) → dominio de **atención al cliente sobre casos de avería** — toca datos de `av_casos`, que es tabla del dominio "operación de garantías" (ver C2/C3), pero el *canal en sí* sirve a la experiencia de atención en vivo, no al cálculo o cierre de la avería.

**Implicación directa para E4:** si el corte de dominio separara "comercial" de "operación", los canales de `postventa` quedarían del lado que cruza la frontera — es una de las costuras que T-08 debe listar explícitamente. El realtime de `warroom` y `callcenter` (8 de 11 canales) sí caería limpiamente del lado comercial.
