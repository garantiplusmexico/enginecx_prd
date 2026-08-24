# Registro único de hallazgos

| Campo | Detalle |
|---|---|
| Requerimiento(s) | RNF-09 (priorización por severidad) |
| Versión | 0.3 |
| Fecha | 2026-08-24 |
| Estado | 🟡 En curso — 1 Crítico escalado (T-08/T-09) + 1 Medio registrado (T-11), ambos adelantados de Fase 2 |

> Escala de severidad y protocolo de escalamiento en `00-metodologia-y-evidencia.md` §3. Ordenado por severidad descendente; dentro de cada severidad, por capítulo.

| # | Severidad | Dimensión | Capítulo | Descripción | Evidencia | Impacto | Recomendación | Etapa que lo confirma |
|---|---|---|---|---|---|---|---|---|
| 1 | **Crítico** | Seguridad | C11 (adelantado desde T-08/T-09) | La tabla `mora_corte` tiene RLS **activo** pero su política de lectura (`mora_corte_select`) es `for select using (true)` **sin ninguna condición** — ni `to authenticated`, ni `auth.uid() is not null`, ni `app_rol()`. No hay ningún `revoke` sobre esta tabla en el historial de migraciones (a diferencia de otras tablas sensibles del mismo repositorio, que sí lo tienen — ver evidencia). Con el comportamiento por defecto de Supabase (el rol `anon` recibe `GRANT` sobre tablas nuevas de `public` salvo revocación explícita, y no se encontró ningún `ALTER DEFAULT PRIVILEGES` que cambie eso), esto significa que **la `anon key` — pública, embebida en el bundle del frontend — puede leer la tabla completa sin autenticación**. | `supabase/migrations/0221_mora_aging_historico.sql:40-42` (única definición de la política, nunca redefinida — verificado con `grep -rn "mora_corte_select" supabase/migrations/*.sql`, un solo resultado). Contraste: `supabase/migrations/0146_solicitudes_fase1.sql:416-418`, `0152_portal_proveedor_login.sql:39-40`, `0184_hardening_solicitudes_tareas.sql:556` — mismo repositorio revocando `anon` explícitamente en otras tablas. **Migración 0329 (`tablas_sensibles_por_capacidad.sql`) endureció `mora_clientes` y `mora_vinculos` por el mismo motivo — su comentario dice que "espeja el gate que ya tenía `mora_corte`" — pero `mora_corte` en sí quedó sin tocar.** | `mora_corte` contiene, por cliente: monto vencido, monto total, tramo de mora, **`bloqueado`**, **`dicom`** (lista negra crediticia en Chile) y **`cobranza_externa`**. Es información financiera y crediticia de clientes reales, expuesta sin autenticación si el análisis es correcto. | **Verificar contra la base real en T-32 (Etapa B) con máxima prioridad** — es la primera tabla a revisar en cuanto llegue A1. Si se confirma: aplicar de inmediato el mismo patrón de `0329` (gate por `app_rol() in ('CM','GTE')` o capacidad `cobranza`) y/o `revoke all on public.mora_corte from anon`. | **A (código) — confirmado por lectura directa del SQL; B (T-32) verifica que la base productiva coincide con la migración** |
| 2 | **Medio (histórico, ya remediado)** | Seguridad / Proceso | C4/C11/C13 (adelantado desde T-11) | La Edge Function `dossier-ia` (genera el briefing del 1:1 con IA, con costo de tokens de Anthropic) estuvo desplegada **sin exigir autenticación** (`verify_jwt=false`) hasta el 03-08-2026. El propio comentario del código la identifica como "brecha #6", lo que implica que hubo al menos 5 brechas numeradas anteriores, corregidas pero sin registro centralizado. | `supabase/functions/dossier-ia/index.ts` (comentario de cabecera, líneas 1-9): *"verify_jwt=TRUE desde el 03-08-2026 (brecha #6): estaba desplegada sin exigir [autenticación]"*. | Ya remediado — no es explotable hoy. El impacto de la brecha original habría sido costo/abuso de la API de Anthropic por invocación no autenticada, no exposición de datos de negocio. | No requiere acción correctiva (ya corregida). **Recomendación de proceso:** centralizar el registro de brechas encontradas y corregidas (hoy disperso en comentarios de código) en un documento de bitácora de seguridad — insumo para C13/C14. | **A (código) — el propio comentario documenta la fecha y el motivo de la corrección** |

---

## Nota sobre este hallazgo (T-04 §3 — protocolo de escalamiento)

Detectado el 24-08-2026 durante T-08/T-09 (reconstrucción del modelo de datos), **antes** de tener acceso de lectura a la base (A1 pendiente). La evidencia es 100% del código SQL versionado — no se ejecutó ninguna consulta contra la base productiva, y no se intentó verificar la explotabilidad real (el análisis no toca el sistema, RNF-01). Se notifica a Javier Oropeza en el mismo mensaje que reporta este avance, para que él escale a Aldo Álvarez el mismo día, según el protocolo. No se profundiza más de lo necesario para describir el hallazgo — coherente con el paso 1 del protocolo de `00-metodologia-y-evidencia.md`.

---

*(Hallazgos de C10–C14, según lo previsto, comienzan a registrarse en Fase 2. Este es el primero, adelantado por su severidad.)*
