# 15 · Auditoría de observabilidad y operación

| Campo | Detalle |
|---|---|
| Capítulo | C14 |
| Requerimiento(s) | RF-16 |
| Etapa | A — T-20 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

---

## 1. Qué se monitorea hoy — el frontend, y solo el frontend

**Hecho:** `src/lib/monitoreo.ts` centraliza el reporte de errores del **frontend** vía Sentry (`@sentry/react`), opt-in por variable de entorno (`VITE_SENTRY_DSN`), sin tracing de performance (`tracesSampleRate: 0`, plan gratuito según su propio comentario). El wrapper `reportarError(contexto, err)` se usa **138 veces** en todo `src/` — adopción consistente y disciplinada del patrón en el código de la aplicación.

**Hallazgo (confirmado, no solo inferido):** **Sentry no tiene ninguna presencia en las 46 Edge Functions** (`grep` sobre `supabase/functions/`, 0 coincidencias de "sentry"). Todo el backend serverless —incluidos los 10 cron jobs que envían notificaciones, calculan indicadores financieros y disparan IA— **no reporta errores a ningún sistema centralizado**. El patrón real observado (`tareas-atrasadas-cron/index.ts:592`, representativo del resto): un `try/catch` de nivel superior que devuelve `{ ok: false, error: String(e) }` con código 500 — la información del error existe, pero **solo llega a quien inspeccione la respuesta HTTP**, y en una invocación de cron (`pg_cron`) nadie la inspecciona en el momento salvo que alguien revise los logs de Supabase manualmente.

## 2. Logs de Edge Functions

No hay logging estructurado propio observado más allá de lo que Deno/Supabase capturan por defecto en sus logs de plataforma (fuera del alcance de este análisis de código — viven en el panel de Supabase, requieren A1/A2 para inspeccionarse). El código no implementa un logger propio ni envía logs a un servicio externo (no hay integración con Logtail, Datadog, etc.).

## 3. Alertas y tareas cron — mecanismo de negocio robusto, mecanismo de infraestructura ausente

**Distinción importante que este capítulo debe marcar con claridad:** el sistema tiene **alertas de negocio muy bien construidas** (avisos a usuarios cuando algo requiere su atención — tareas atrasadas, visitas abiertas, casos sin gestión) pero **cero alertas de infraestructura** (avisar a un humano técnico cuando un cron falla).

- **Alertas de negocio (fuertes):** `tareas-atrasadas-cron` avisa al responsable y escala; `visitas-abiertas-cron` avisa y cierra automáticamente tras un umbral; `averia-cuestionario-cron` tiene múltiples barridos con dedup explícito por tabla (`av_notificaciones`) para no duplicar avisos. Es notificación al **usuario de negocio**, bien diseñada.
- **Alertas de infraestructura (ausentes):** no existe un mecanismo que avise a Javier/TI si uno de los 10 cron jobs deja de ejecutarse, empieza a fallar sistemáticamente, o si `monedas-cron` no logra actualizar ninguna moneda (su propio diseño *best-effort* significa que puede fallar en silencio para todas las fuentes sin que nadie se entere, más allá del propio código intentándolo de nuevo en la siguiente corrida programada).

## 4. Fallos silenciosos — el patrón de "brecha numerada" como evidencia indirecta

El hallazgo ya registrado en `hallazgos.md` #3 (`dossier-ia`, "brecha #6") es evidencia de que **existe un proceso de detección de problemas**, pero es **manual y no queda documentado en un solo lugar** — vive disperso en comentarios de código de las funciones donde se corrigió cada brecha. No hay un archivo `SECURITY.md`, changelog de seguridad, o bitácora de incidentes centralizada en el repositorio. **Esto es, en sí mismo, un hallazgo de proceso**, ya escalado con su recomendación en `hallazgos.md` #3.

## 5. Procedimiento actual ante incidentes

No se encontró documentación de un procedimiento formal de respuesta a incidentes (runbook, escalamiento, on-call) en el repositorio. La operación parece depender del conocimiento del mantenedor actual — coherente con el problema central que motiva todo este PRD ("TI no lo conoce, no lo gobierna").

## 6. Cobertura declarada (RNF-11)

Cubierto con evidencia directa: alcance real de Sentry (frontend únicamente, confirmado por ausencia en Edge Functions), patrón de manejo de errores en crons, distinción entre alertas de negocio (fuertes) y de infraestructura (ausentes), y la falta de un registro centralizado de incidentes de seguridad. **No cubierto, fuera de alcance de este análisis de código:** logs reales de ejecución de Edge Functions y su volumen de fallos — viven en el panel de Supabase (A1/A2, Etapa B, aunque ni siquiera T-35 lo cubre explícitamente por no ser su foco de costo/consumo; se deja como pregunta abierta si se necesita profundizar).

---

## Cierre de Fase 2

Con este capítulo se completa la Fase 2 (T-16 a T-20 + consolidación en T-21). Los cinco capítulos de calidad (C10-C14) están cerrados en su alcance de Etapa A, con **6 hallazgos nuevos** registrados en esta fase (más los 2 de Fase 1): 1 Alto (testing UI), 2 Medio (tipado), 1 Bajo-Medio (CORS), 1 Bajo (límite de filas), 1 hallazgo de proceso (bitácora de seguridad, dentro del #3).
