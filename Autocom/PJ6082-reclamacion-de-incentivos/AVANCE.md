# Registro de Avance — Reclamación de Incentivos (PJ6082)

> Este documento se crea tarde a propósito. El proyecto se ejecutó de corrido
> hasta tener el MVP en producción, y la bitácora fina del día a día vivió
> —y sigue viviendo— en `session.md` dentro del repositorio de código, que
> es donde el desarrollador la consulta al abrir sesión. Este archivo es el
> resumen para quien mire el proyecto desde fuera: qué fases están cerradas,
> qué decisiones se tomaron fuera del plan y por dónde seguir.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/PJ6082-reclamacion-incentivos-mvp` |
| Responsable actual | Aldo Álvarez |
| Folio PRD | PJ6082 |
| ID plan (BD) | *(pendiente de recuperar con `pm-db.mjs plan-get --folio PJ6082`)* |
| Última actualización | 27 de agosto de 2026 |
| Estado general | 🟡 En progreso — Fases 0 a 3 y 5 cerradas; falta la Fase 4 (piloto) |

---

## Resumen de estado

El MVP está **desplegado y operando sobre datos reales**:
<https://reclamacion-incentivos.aldo-alvarez.workers.dev>. Julio 2026 se
recorrió punta a punta —oferta cargada, catálogo aprobado con 54 entradas,
2,986 operaciones sincronizadas desde Athena, 121 unidades validadas tras
netear— y las cifras **reproducen exactamente las del prototipo**.

Cerradas las Fases 0, 1, 2, 3 y 5. Lo que falta es la **Fase 4**: la sesión
con la dirección comercial, hoy bloqueada porque falta el correo de Laura
Hernández para darla de alta en Cloudflare Access.

Un hallazgo de infraestructura marcó el proyecto y conviene que se sepa:
el plan **Free** de Cloudflare Workers limita a 10 ms de CPU por invocación
y leer un PDF cuesta cerca de un segundo. El Worker moría sin dejar rastro
—no llega como excepción de JavaScript— y costó tres sesiones diagnosticarlo.
La cuenta pasó al plan de pago el 27-ago-2026 y `wrangler.jsonc` declara
`limits.cpu_ms: 30000`.

---

## Relación de tareas y tiempos (seguimiento)

> Los días ejecutados son estimados: el trabajo se hizo en jornadas
> concentradas del 25 al 27 de agosto de 2026, no en días hábiles sueltos,
> así que la comparación contra el rango del plan es orientativa. El
> proyecto va **muy por delante** de lo estimado.

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Cimientos (P1)** | 223 | T-01 a T-05 | 3 – 5 | 2026-08-25 | 2026-08-26 | 2 | 0 | ✅ Completada |
| **Fase 1 — Oferta comercial y transacciones (P1)** | 224 | T-06 a T-14 | 8 – 11 | 2026-08-26 | 2026-08-26 | 1 | 0 | ✅ Completada |
| **Fase 2 — Motor de validación (P1)** | 225 | T-15 a T-20 | 6 – 9 | 2026-08-26 | 2026-08-27 | 1 | 0 | ✅ Completada |
| **Fase 3 — Presentación al negocio (P1)** | 226 | T-21 a T-25 | 5 – 7 | 2026-08-26 | 2026-08-27 | 1 | 0 | ✅ Completada |
| **Fase 4 — Piloto de julio 2026 (P1)** | 227 | T-26 a T-28 | 2 – 4 | 2026-08-27 | | 1 | 2 | 🔴 Bloqueada |
| **Fase 5 — Identidad visual (P1)** | — | T-34 a T-40 | — | 2026-08-26 | 2026-08-26 | 1 | 0 | ✅ Completada |
| **Fase 6 — Operación continua (P2)** | 228 | T-41 a T-45 | 7 – 11 | | | 0 | 11 | ⏳ Pendiente |
| **Solo P1 (guardarraíl del PRD)** | — | T-01 a T-28 y T-34 a T-40 | ~28 – 42 | 2026-08-25 | | 4 | 2 | 🟡 En progreso |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 a T-04 | Repositorio, Next.js en Workers, Supabase, Zero Trust | Claude Code | 2026-08-25/26 | |
| T-05 | Spike de conexión a Athena | Claude Code | 2026-08-25 | Vista `vw_full_master_view_ventas_nuevos_grupo_autocom`. Escanea 1,245 MB todo el histórico y no poda por fecha: la ingesta es refresco completo, no incremental |
| T-06 a T-08 | Modelo de datos, selección de periodo, carga de documentos | Claude Code | 2026-08-26 | |
| T-09 | Parser determinista del anexo | Claude Code | 2026-08-26 | 54 renglones, 9 modelos, 0 advertencias sobre el anexo real de julio |
| T-10 | Interpretación del boletín con IA | Claude Code | 2026-08-26 | OpenAI con esquema estricto. La IA **no toca importes**: solo prosa, programas y calendario |
| T-11 a T-12 | Aprobación y consulta del catálogo | Claude Code | 2026-08-26 | La oferta se muestra con y sin IVA para poder cuadrarla contra el boletín cifra por cifra |
| T-13 a T-14 | Ingesta desde Athena y sincronización | Claude Code | 2026-08-26 | 2,986 operaciones; de 40 a 50 s por consulta, por eso es asíncrona |
| T-15 | Neteo de cancelaciones y refacturación | Claude Code | 2026-08-26 | 131 operaciones de julio → 121 unidades |
| T-16 a T-17 | Homologación automática y panel de excepciones | Claude Code | 2026-08-26 | |
| T-18 a T-20 | Motor de importe, barrido sin incentivo, duplicidad | Claude Code | 2026-08-26 | Módulos puros de TypeScript, sin red ni base de datos: es lo que se porta a C# |
| T-21 | Reporte de conformidad | Claude Code | 2026-08-27 | Vista «Coinciden» más la hoja *Conformidad* del Excel |
| T-22 | Tablero de diferencias con comentarios | Claude Code | 2026-08-27 | Partido en «se dio de más» y «se dio de menos»: son dos conversaciones distintas |
| T-23 | Vista consolidada del periodo | Claude Code | 2026-08-27 | Vista «Todas» con estatus y comentario por unidad |
| T-24 | Exportación del periodo | Claude Code | 2026-08-27 | `.xlsx` de siete hojas y vista de impresión para el PDF |
| T-25 | Bitácora de auditoría | Claude Code | 2026-08-27 | La tabla se escribía desde el día uno; faltaba la pantalla |
| T-26 | Corrida completa del periodo | Aldo Álvarez | 2026-08-27 | 51 conformes, 29 sin cuadrar, 30 sin capturar, 11 sin versión. **Cuadra con el prototipo** |
| T-34 a T-40 | Identidad visual completa | Claude Code | 2026-08-26 | |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| T-27 | Sesión de retroalimentación con la dirección comercial | Falta el correo de Laura Hernández para darla de alta en la política de Cloudflare Access y crear su fila en `perfil`. Rol acordado: `catalogo` | Aldo Álvarez |
| T-28 | Ajustes derivados de la retroalimentación | Depende de T-27 | — |
| T-41 | Notas de crédito | No se ha encontrado dónde viven las notas de crédito en Athena | Autocom |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| **Plan de pago de Cloudflare Workers** (5 USD/mes) | El plan Free limita a 10 ms de CPU por invocación y leer un PDF cuesta ~1 s. El Worker moría sin excepción atrapable: no quedaba ni el documento marcado como fallido ni un mensaje | Desbloquea el procesamiento de documentos, que era una lotería. `wrangler.jsonc` declara `limits.cpu_ms: 30000` |
| **`unpdf` en lugar de `pdfjs-dist`** | El runtime de Workers no tiene `DOMMatrix`, `Path2D` ni `ImageData`. El mismo código funcionaba en Node y reventaba en producción | Regla general del proyecto: probar en Node no prueba nada sobre producción |
| **Escritor de `.xlsx` propio** en vez de biblioteca | `xlsx` (SheetJS) lleva años sin publicarse en npm y arrastra CVE; `exceljs` depende de flujos y `Buffer` de Node — el mismo riesgo que ya obligó a cambiar de PDF | ~200 líneas sobre `fflate`. Verificado en workerd: 6,262 bytes en 9 ms |
| **PDF por vista de impresión**, no generado en servidor | `pdf-lib` no entiende HTML: habría que maquetar coordenada por coordenada, con peor resultado. Decidido con el solicitante | Si algún día hay que **adjuntar** el PDF a un correo automático, habrá que generarlo en servidor |
| **Categoría «sin promoción»** | El motor solo distinguía «homologada» de «nadie la resolvió». Una versión que sencillamente no trae promoción caía en el segundo cajón y reaparecía como excepción cada corrida | Nuevo valor `sin_promocion` en `tipo_resultado`. No hizo falta estado nuevo en `estatus_homologacion`: `sin_correspondencia` ya significaba eso |
| **Desglose del monto en diferencia** | Un solo número no decía qué hacer con él | Se parte en «se dio de más» y «se dio de menos», y lo facturado sin capturar se separa con su propia lectura: dinero perdido u oportunidad no capitalizada |
| **Borrado de periodo con confirmación escrita** | Rehacer un mes cargado con información equivocada exigía correr un script | Se lleva documentos, catálogo y resultados; **no** toca ventas ni homologaciones |
| **No declarar `NODE_ENV` ni usar `next/font`** | Ambos rompen el build de producción con `output: standalone`, con un error engañoso sobre `<Html>` | Documentado en `CLAUDE.md` |
| **Se conserva la rama `feature/PJ6082-…`** en vez de abrir una nueva desde `develop` | El PR contra `develop` sigue abierto: ramificar desde ahí habría dejado fuera todo el MVP | Divergencia consciente del flujo estándar de Engine |

---

## Notas para quien retome el trabajo

**Por dónde continuar.** Lo primero es leer `CLAUDE.md` y `session.md` del
repositorio de código, en ese orden: ahí está el protocolo de sesión y la
bitácora fina, con los fallos **no resueltos** y su evidencia.

**Contexto que no es obvio:**

- **La plataforma detecta y alerta; no corrige.** No escribe en Quiter, no
  emite documentos contables y no cuadra diferencias por inferencia.
- **El motor de validación no toca infraestructura.** Son módulos puros de
  TypeScript en `src/lib/dominio/`. Es lo que se porta a C# al reconvertir a
  AWS, y por eso el acceso a datos pasa siempre por `src/lib/datos/`.
- **Ningún dato de producción entra al repositorio.** Ver
  `docs/manejo-de-datos.md`.
- **`homologacion_version` no tiene periodo.** El texto de Quiter es el mismo
  todos los meses, así que resolver uno cambia la lectura de cualquier periodo
  que lo contenga.
- El repositorio central **no tiene rama `main`**: su cadena es
  `feature/*` → `develop` → `pre-qa` → `qa`.

**Decisiones pendientes de input:**

- **El correo de Laura Hernández**, que bloquea toda la Fase 4.
- **Historial y corrección de homologaciones.** Hoy se resuelve una y
  desaparece de la vista: no hay cómo verla, corregirla ni saber qué decía
  antes. Ya causó un reinicio de datos completo el 27-ago-2026.
- **Preguntas abiertas del PRD §14:** destino del bono, campo separado de
  versión, hueco de agosto y septiembre 2025, y origen de los programas de
  +$50,000, +$25,000 y +$10,000.
- **Separar «dinero perdido» de «oportunidad no capitalizada»** en las
  unidades sin monto capturado. Hoy la distinción vive en un comentario de
  texto libre; si el negocio quiere sumarlas por separado hace falta un campo
  declarado en el renglón.

---

*Actualizado por Claude Code — Engine CX*
