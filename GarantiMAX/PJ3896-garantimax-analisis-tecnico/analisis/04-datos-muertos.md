# 04 · Datos muertos

| Campo | Detalle |
|---|---|
| Capítulo | C5' |
| Requerimiento(s) | RF-05 |
| Etapa | A (candidatos) — T-10 · B (confirmados) — T-34 |
| Versión | 1.0 (Etapa A — candidatos por ausencia de referencia en código, no confirmados contra la base) |
| Fecha | 2026-08-24 |
| Estado | 🟡 Cerrado en Etapa A — ningún ítem se declara "muerto"; eso exige T-34 |

> **Ningún hallazgo de este capítulo se afirma como "dato muerto".** Todo se marca **candidato**, con su nivel de confianza. Confirmar el desuso real requiere la base (volumen de filas, fecha del último registro, triggers/crons que escriban ahí) — exclusivo de T-34 (Etapa B). Publicar esta lista como "muerto" sin esa verificación sería precisamente el error que RF-05 busca evitar: arrastrar una conclusión falsa a un sistema nuevo.

---

## 1. Tablas sin ninguna referencia en `src/` ni en las 46 Edge Functions

Método: cada una de las 136 tablas vivas (`03-modelo-datos.md`) se buscó como palabra completa en todo `src/` y `supabase/functions/`. **14 no aparecen ni una vez:**

| Tabla | Familia | Lectura |
|---|---|---|
| `americar_vendedor_sucursal` | `americar_*` | Su tabla hermana `americar_siga_real` sí tiene 1 referencia. Candidato a esquema abandonado a medio construir. |
| `av_decisiones` | `av_*` | Tiene RLS y política (bloque dinámico de `0199`), pero cero uso en código — el flujo de "decisiones" del caso pudo migrar a otra tabla (`av_resoluciones`, que sí se usa). |
| `av_planillas_pago` | `av_*` | Con RLS pero sin política propia identificada (§2.1 de `03-modelo-datos.md`) — doble señal de posible abandono. |
| `av_pvc_puertas` | `av_*` | Nombre muy específico ("PVC puertas") — sugiere un producto o proceso particular que pudo discontinuarse. |
| `av_reclamos` | `av_*` | Tiene tabla de firmantes asociada (`hunter_contrato_firmante` no, pero sí aparece en `0311` junto a las demás `av_*` activas) — candidato a funcionalidad reemplazada. |
| `av_sla_relojes` | `av_*` | Sugiere un sistema de SLA con temporizador que no llegó a consumirse desde el front, o se consume solo vía trigger/cron interno (no descartable sin la base). |
| `fotos_herencia` | maestro | Del bloque original de RLS (`0002`) — de las tablas más antiguas del sistema, candidata a esquema de una versión anterior de "herencia de fotos" entre casos. |
| `incentivo_evento` | `incentivo_*` | Su tabla hermana `incentivo_envio` sí se usa — posible registro de auditoría que se dejó de escribir desde el front (podría escribirse vía trigger). |
| `notas_historicas` | maestro | Igual que `fotos_herencia`: parte del esquema original de `0002`, sin uso detectado. |
| `portal_demo_caso` | `portal_*` | El nombre ("demo") sugiere que es infraestructura de ambiente de demostración, no de producción — candidato de baja prioridad. |
| `portal_demo_contrato` | `portal_*` | Mismo caso que la anterior. |
| `salas_meta_revision` | `salas_*` | Su tabla hermana `salas_meta` y `salas_meta_analisis` sí se usan — sugiere una etapa intermedia de revisión que se simplificó. |
| `tarea_comentarios` | `tarea_*` | El flujo de solicitudes tiene comentarios (`solicitud_comentar` como RPC) — puede que los comentarios de tarea se resolvieran de otra forma. |
| `usuario_grupos` | `usuario_*` | `usuario_areas` y `usuario_roles` sí se usan — candidato a un tercer eje de permisos (grupos) que no se terminó de conectar al front. |

**Nivel de confianza:** *sospechoso* para las 14 — ninguna se marca *confirmado sin uso*, porque una tabla sin `.from()` en el front puede seguir escribiéndose desde un trigger, un cron, o leerse solo por una Edge Function con un patrón que el grep no capturó. **T-34 confirma con: conteo de filas y fecha del último registro.**

---

## 2. RPCs — de 262 a un panorama mucho más sano de lo que la primera pasada sugería

**Primera pasada (ingenua):** 262 RPCs únicas, solo **168 con llamada directa `.rpc('nombre')`** encontrada en `src/`/Edge Functions → **95 "sin uso"**. Publicar esa cifra sin más análisis habría sido un error de método — la mayoría de esas 95 sí se usan, solo que no desde JavaScript.

**Segunda pasada — clasificación de las 95:**

| Categoría | Cantidad | Cómo se confirmó |
|---|---|---|
| Funciones de **trigger** (`CREATE TRIGGER ... EXECUTE FUNCTION`) | 26 | Se ejecutan automáticamente ante `INSERT`/`UPDATE`/`DELETE`, nunca se llaman desde JS por diseño — no son candidatas a nada. |
| **Helpers de política RLS** (usadas dentro de `USING`/`WITH CHECK` de una `CREATE POLICY`) | 15 | Mismo caso: son parte de la infraestructura de seguridad, se ejecutan en cada consulta que pasa por RLS. |
| Llamadas **función-a-función** (invocadas dentro del cuerpo de otra función SQL) | **54** | Se verificó contando ocurrencias de `nombre(` en todo el SQL y restando su propia declaración — las 54 restantes aparecen invocadas desde dentro de otra RPC. Ej.: `norm_rut`/`norm_nombre` (normalización, usadas dentro de `vendedor_por_rut` y similares), `incentivos_calc` (dentro de `incentivos_generar`), `org_set_*` (dentro de `organigrama`). |
| **Sin ningún uso encontrado, en ningún nivel** | **0** | Tras las tres capas de verificación, no queda ninguna RPC vigente sin al menos una invocación localizada en el propio código SQL. |

**Lectura honesta de este resultado:** "0 RPCs huérfanas" es una **buena señal de higiene de código a nivel estático**, pero tiene un límite real: esta verificación confirma que cada función *es llamada por algo*, no que esa cadena de llamadas termine en un flujo que un usuario real ejecuta hoy. Una función podría llamar a otra que a su vez nunca se dispara en la práctica (cadena de funciones "vivas" pero colectivamente muertas). Esa profundidad — frecuencia de invocación real — solo la da `pg_stat_user_functions` o los logs, **fuera de alcance de este análisis** (no es RNF-01 lo que lo impide, es que ni siquiera con A1 hay acceso a estadísticas de ejecución garantizado; se declara como límite metodológico, no como pendiente de T-34).

---

## 3. Duplicidades

### 3.1 Numeración de migraciones (confirma `CLAUDE.md`)
**15 números de migración duplicados** entre las 364 (`0184`, `0185`, `0187`, `0188`, `0198`, y 10 más) — exactamente lo que `CLAUDE.md` declara ("al 25-07-2026 había 15 números duplicados entre 328 migraciones"). **El número se mantuvo en 15 pese a que el conteo total subió de 328 a 364** — confirma que la red de contención (`src/lib/migracionesUnicas.test.ts`, que bloquea duplicados nuevos desde el 0316) está funcionando: no se sumaron duplicados nuevos en los 36 archivos más recientes. Los históricos se dejan como están, según la propia decisión documentada del proyecto (la base identifica cada migración por su timestamp de aplicación, no por el nombre del archivo).

### 3.2 Código de aplicación
- **`hunter/cotizador/cotizacionPdf.ts` y `cotizacionPdfV2.ts`** (`01-ficha-tecnologica.md`, T-06): dos generadores de PDF de cotización coexistiendo. Candidato a duplicidad de mantenimiento — a menos que `v1` siga en uso deliberado para un caso específico (a confirmar con el mantenedor actual).
- **Tablas espejo/original en `hunter`:** `espejo_plan`/`espejo_precio`/`espejo_tramo` frente al catálogo de `productos`. No es una duplicidad accidental — el propio nombre ("espejo") y su política de RLS separada (`0323`) indican que es un diseño intencional para cotizar sin tocar el maestro. Se documenta aquí para que quede explícito que **no** es candidato a limpieza.

---

## 4. Cobertura declarada (RNF-11)

- **136/136 tablas vivas** cruzadas contra el código (100%). 14 candidatas a sin uso, ninguna confirmada.
- **262/262 RPCs únicas** clasificadas en 4 categorías (100%). 0 sin ninguna invocación localizada, con el límite metodológico declarado en §2.
- **Duplicidad de migraciones:** confirmada y cuantificada (15/364), consistente con la documentación previa del propio repositorio.
- **No se profundizó** en duplicidad de columnas dentro de una misma tabla (ej. dos columnas con semántica equivalente) — no se encontró evidencia de ese patrón durante la lectura de este capítulo, pero tampoco se buscó exhaustivamente columna por columna; se declara como no cubierto, no como "no existe".
