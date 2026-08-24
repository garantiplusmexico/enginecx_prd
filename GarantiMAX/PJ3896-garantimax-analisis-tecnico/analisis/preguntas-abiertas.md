# Registro de accesos y preguntas abiertas

| Campo | Detalle |
|---|---|
| Requerimiento(s) | RF-23, RNF-11 |
| Versión | 0.1 |
| Fecha | 2026-08-24 |
| Estado | 🟡 En curso — se actualiza en cada fase |

---

## 1. Estado de accesos (T-02)

Detalle completo de cada acceso — a quién se pide, en qué forma, alternativas — en `PLAN.md` §2.1. Aquí solo el estado y la fecha de cada movimiento.

| ID | Acceso | Estado al 2026-08-24 | Bloquea | Pedido a |
|---|---|---|---|---|
| A1 | Lectura de la base Supabase (`jrykbalmnpymeyzdhsam`) | ❌ Pendiente — `.env` de lectura pendiente de entrega | Fase 5 completa (T-31 a T-35) | Quien administre el proyecto Supabase (Fabrizio Álvarez, previsiblemente) |
| A2 | Paneles de costo y consumo de Supabase y Vercel | ❌ Pendiente | T-35, dimensión de costo del dictamen | Quien administre la facturación |
| A3 | Fuente autoritativa de la API de SIGA + contacto | ❌ Pendiente | Fase 6 completa (T-36 a T-38) | Equipo responsable de la API de SIGA |
| A4 | Muestras de reportes Excel de SIGA (ACTIVAS, CERRADAS, contratos) | ❌ Pendiente | Detalle de T-13 (no bloquea el capítulo: se documenta desde los parsers) | Fabrizio Álvarez o quien ejecute la carga |
| A5 | Panel de Sentry | ❌ Pendiente | Detalle de T-20 (no bloquea: se documenta desde el código) | Quien administre la organización de Sentry |
| A6 | Ventanas de conversación con interlocutores (Fabrizio, mantenedor, equipo SIGA, Aldo) | ❌ Pendiente de agendar | Validación de T-07, T-14, T-25; PUERTA 2 (T-29) | Javier Oropeza coordina |

**Ninguno de los seis detiene el arranque de la Etapa A** (PLAN.md §2). A1 y A3 sí gobiernan por completo la Etapa B: mientras no lleguen, las Fases 5 y 6 permanecen `🔴 Bloqueada` en `AVANCE.md`.

**Recomendación pendiente de respuesta del solicitante:** fijar una fecha de compromiso, aunque sea tentativa, para A1 y A3 — es el riesgo dominante identificado en `PLAN.md` §13 ("El riesgo que gobierna ahora es la Etapa B, no el calendario").

---

## 2. Preguntas abiertas heredadas del PRD (§14)

| Tema | Pregunta | Estado | Nota |
|---|---|---|---|
| Costos de plataforma | ¿Quién administra Supabase/Vercel y puede dar acceso al costo, tráfico, invocaciones y consumo de Realtime? | Abierta | = A2 |
| Costos de plataforma | ¿Existe un techo de costo o política corporativa de gasto en servicios externos? | Abierta | Sin dueño asignado aún |
| API de SIGA | ¿Cuál es la fuente autoritativa y quién es el contacto? | Abierta | = A3 |
| API de SIGA | ¿La API expone hoy contratos y averías con el detalle que consumen los importadores actuales? | Abierta | Se responde en T-36, requiere A3 y la lista de campos de T-13 |
| Propiedad del código | ¿Regularizar la propiedad de `fabriziolag/garantiplus-dashboard` es parte de la decisión de TI y con qué urgencia? | Abierta | Relevante para la decisión de dónde publicar el entregable (`PLAN.md` §12 nota 1) |
| Continuidad operativa | ¿Se congela el desarrollo de GarantiMAX durante el análisis? | Abierta | El sistema se movió 29 commits entre el 06-08 y el 19-08; sin congelar, el riesgo de deriva es alto (`PLAN.md` §11) |
| Alcance del dictamen | ¿Es aceptable para TI concluir "conservar el stack actual" (E0), o la migración ya está decidida por política? | **Resuelta el 24-08-2026** | Confirmado por la Dirección: **no está decidida**. E0 y E4 son candidatos reales (`PLAN.md` §12 nota 5) |
| Requisitos no negociables | ¿Hay requisitos corporativos que cualquier escenario deba cumplir (datos en infraestructura propia, SSO, on-premise, residencia de datos)? | Abierta | Pendiente de validar con Dirección — afecta a los cinco escenarios por igual |
| Alcance funcional futuro | ¿Los 24 módulos se conservarían todos, o hay módulos que la operación ya no usa? | Abierta | Se cruza con T-07 (criticidad operativa) y T-10 (datos muertos) |
| Duplicidad con SIGA | ¿Hay funcionalidad de GarantiMAX que debería absorber SIGA en lugar de reconstruirse? | **En investigación activa** | Es la pregunta que motiva el escenario E4 (`PLAN.md` §1.3) — se responde con evidencia en T-07/T-08 (segmentación por dominio) y se cuantifica en T-35/T-37 (Etapa B) |
| PWA | ¿Cuántos usuarios de terreno la usan y qué tan crítico es el offline real? | Abierta | = A6, dato que no sale de ningún panel |
| PWA | ¿Hay requisitos de dispositivo que la PWA no cubra hoy (cámara avanzada, push nativo, geolocalización en segundo plano, biometría)? | Abierta | Se valida en T-25 con Fabrizio |
| Realtime | ¿Qué latencia exige realmente War Room y call center? | Abierta | = A6, decide entre SignalR, polling o conservar Supabase Realtime (`PLAN.md` §12 nota 5) |
| Datos personales | ¿Qué clasificación normativa aplica en Chile, Perú y Argentina? | Abierta | Sin dueño asignado; relevante para C11 |
| Recursos futuros | ¿Con qué equipo y dedicación contaría una eventual migración? | Abierta | Necesaria para traducir el esfuerzo en rangos a tiempo calendario, fuera del alcance de este PRD |
| Publicación | ¿El documento final se publica solo en `enginecx_prd` o también en el repositorio de GarantiMAX? | **Resuelta en el plan, pendiente de confirmar con Aldo** | Este plan resuelve *solo en `enginecx_prd`* por razones de seguridad (`PLAN.md` §12 nota 1) — requiere el visto bueno explícito de Aldo Álvarez |

---

*Se actualiza en cada fase conforme se cierran o surgen preguntas nuevas.*
