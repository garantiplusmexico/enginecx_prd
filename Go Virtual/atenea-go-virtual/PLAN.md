# Plan de Desarrollo — Atenea Go Virtual

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Go Virtual/atenea-go-virtual/PRD.md` (v0.4) |
| Repositorio | `garantiplusmexico/Atenea_Latam` (workspace local `Atenea-Claude-Code`) |
| Rama | `feature/atenea-go-virtual-capa-datos-y-envio-diario` |
| Tipo | Proyecto nuevo |
| Responsable | Aldo Álvarez |
| Folio PRD | *(pendiente de asignar — ver §12)* |
| Fecha de generación | 2026-08-08 |
| Estado | Borrador |
| ID plan (BD) | *(lo escribe el flujo al registrar el plan)* |

> ⚠️ No existe rama `develop` en este repositorio. El plan se generó desde `main`.
> Se recomienda crear `develop` antes de continuar con el flujo estándar de Engine.

---

## 1. Resumen técnico

Se construye la capa de datos y el reporteo diario de **Atenea Go Virtual** sobre infraestructura ya existente. No se crean servicios nuevos en AWS ni contenedores: el proyecto es un **flujo automatizado sin UI**, que por el árbol de decisión de `rules/arquitectura.md` corresponde a **N8N** con persistencia en **PostgreSQL**.

**Componentes que se crean:**

| Componente | Dónde vive | Qué es |
|---|---|---|
| Esquema `gv` | Supabase `RH_Analytics` (`onbnobxiwvppfiyjlooh`) | Catálogos, sábana de facturación, objetivos y bitácora, aislados del dominio de RH |
| Rol `atenea_bot_gv` | Supabase `RH_Analytics` | Rol Postgres de bajo privilegio, sin acceso a ninguna tabla `rh_*` fuera de las dos autorizadas |
| Funciones de agregación | Supabase `RH_Analytics` | RPCs que calculan facturado MTD, objetivo prorrateado y alcance por los tres niveles |
| `ETL_facturacion_GV` | N8N | Extracción 3x/día desde Athena con bitácora |
| `Envio_diario_ventas_GV` | N8N | Envío 3x/día por Twilio con routing por rol |
| `Atenea_v11_GV` | N8N | Agente conversacional (Fase 4) |

**Componentes existentes que se consumen sin modificar:** la vista `db-rpa.vw_ic_ventas_gv` en Athena y las tablas `rh_persona` y `rh_empresa` en Supabase.

**Stack:** PostgreSQL (default obligatorio de `rules/stack.md`), N8N (estándar de automatización), Twilio WhatsApp y AWS Athena. No aplica backend .NET ni frontend React porque el proyecto no expone UI ni API.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable
- [x] Acceso al repositorio confirmado (`Atenea_Latam`, remoto `origin`)
- [x] `CLAUDE.md` presente en el repositorio
- [x] Proyecto Supabase `RH_Analytics` accesible vía MCP
- [x] Objetivos 2026 extraídos y cuadrados (`Go Virtual/objetivos_2026_GV.csv`)
- [x] Catálogo de Centros de ingresos decidido (`Go Virtual/catalogo_centro_ingresos_GV.csv`)
- [ ] **Export completo de Athena 2026** — bloquea T-08 (el disponible tiene 100 filas de 2025)
- [ ] **Credenciales AWS accesibles desde N8N** para consultar `db-rpa` — bloquea la Fase 2
- [ ] **Número y plantillas de Twilio para Go Virtual** — bloquea la Fase 3
- [ ] **Lista de contactos** con teléfono y rol (Dirección, Equipo, Responsable) — bloquea T-24
- [ ] Confirmación de la pertenencia Responsable → Equipo, y de qué hacer con `Cesar Valverde` e `Irad Yair Bautista Sánchez`
- [ ] Decisión sobre la regla de `Intereses` (mapeo por código SAT vs corregir la vista)

---

## 3. Arquitectura del cambio

Aplica el camino **"¿Es un flujo automatizado sin UI? → N8N"** de `rules/arquitectura.md`, con PostgreSQL como capa de persistencia y cálculo. Es la misma arquitectura ya probada en Atenea México, Colombia y Chile, lo que hace que el costo marginal sea de configuración y no de diseño.

```
AWS Athena                     Supabase RH_Analytics                    N8N / Twilio
db-rpa.vw_ic_ventas_gv   →   esquema gv                          →   Envio_diario_ventas_GV
     (solo lectura)            ├── catalogo_centro_ingresos            ├── Dirección
                               ├── catalogo_equipo                     ├── Equipo
                               ├── catalogo_responsable ──┐            └── Responsable
                               ├── objetivo               │
                               ├── facturacion            │        →   Atenea_v11_GV (chat)
                               ├── contacto               │
                               └── sync_log               │
                                                          ↓
                               public.rh_persona / rh_empresa  (solo lectura)
```

**Decisión de aislamiento:** todo lo comercial vive en el esquema `gv`, no en `public`. `RH_Analytics` es un sistema de RH en producción con 19 tablas y datos de nómina (`rh_persona_sensible`); el esquema separado permite otorgar permisos al bot sin exponer ese dominio. Es la aplicación directa del principio de mínimo privilegio de `rules/infraestructura.md` §5.

**Decisión de secuencia (indicación de Aldo):** la validación contra el Tool **no se ejecuta hasta que la sábana esté respaldada al 100% en Supabase**. Por eso la validación es una fase propia (Fase 1) y no una tarea dentro de la carga. Validar contra una sábana parcial produciría diferencias que se atribuirían a la lógica de cálculo cuando en realidad serían de cobertura de datos.

---

## 4. Tareas de desarrollo

### Fase 0 — Cimientos de datos (P1)

- [ ] **T-01** — Crear el esquema `gv` en `RH_Analytics` con RLS habilitado
  - Archivos a crear/modificar: `Go Virtual/FASE_0_esquema_gv.sql`
  - Criterio de completitud: el esquema existe, `rowsecurity = true` en todas sus tablas, y `\dn` lo lista junto a `public`

- [ ] **T-02** — Crear el rol `atenea_bot_gv` de bajo privilegio
  - Archivos a crear/modificar: `Go Virtual/FASE_0_rol_atenea_bot_gv.sql`
  - Criterio de completitud: el rol puede leer `gv.*`, `public.rh_persona` y `public.rh_empresa`, y una consulta a `public.rh_persona_sensible` con ese rol devuelve `permission denied`

- [ ] **T-03** — Crear y poblar `gv.catalogo_centro_ingresos` (12 centros con sus alias)
  - Archivos a crear/modificar: `Go Virtual/FASE_0_catalogos.sql`, fuente `Go Virtual/catalogo_centro_ingresos_GV.csv`
  - Criterio de completitud: 12 filas; la función de resolución mapea los 14 literales conocidos y devuelve `-1` para cualquier otro

- [ ] **T-04** — Crear y poblar `gv.catalogo_equipo` (5 equipos)
  - Archivos a crear/modificar: `Go Virtual/FASE_0_catalogos.sql`
  - Criterio de completitud: 5 filas (Nuevos Negocios, Customer Success Manager, Brand Success Manager, CRM, Longtale)

- [ ] **T-05** — Crear y poblar `gv.catalogo_responsable`, ligado a `rh_persona.id`
  - Archivos a crear/modificar: `Go Virtual/FASE_0_catalogos.sql`
  - Criterio de completitud: cada Responsable del Tool resuelve a un `rh_persona.id` con `empresa_id = 4`; la normalización colapsa mayúsculas y acentos (caso `Montserrat` / `montserrat`); los no resueltos quedan con `id_responsable = -1` y aparecen en un reporte de excepciones, nunca en cero

- [ ] **T-06** — Crear `gv.objetivo` y cargar 2026
  - Archivos a crear/modificar: `Go Virtual/FASE_0_objetivos.sql`, fuente `Go Virtual/objetivos_2026_GV.csv`
  - Criterio de completitud: `SUM(objetivo_mxn)` = **108,219,141.95**; el mes 1 = **9,319,472.19** y el mes 7 = **9,293,066.27**

- [ ] **T-07b** — Crear y poblar `gv.catalogo_cuenta` (puente `id_gv` → Responsable)
  - Archivos a crear/modificar: `Go Virtual/FASE_0_cuentas_rol_facturacion.sql`
  - Criterio de completitud: 828 cuentas cargadas, ninguna con responsable ambiguo
  - **Tarea no prevista en el plan original.** Se descubrió al diseñar T-07: la vista de Athena no trae `Responsable`, llega hasta `id_gv`. Sin este puente toda la facturación caería al centinela y el corte por comercial sería imposible

- [ ] **T-07** — Crear `gv.facturacion` (sábana) con índices y llave de negocio
  - Archivos a crear/modificar: `Go Virtual/FASE_0_facturacion.sql`
  - Criterio de completitud: la llave de negocio impide duplicados al reejecutar; existen índices por `fecha`, `id_centro_ingresos` e `id_responsable`

- [ ] **T-08** — Cargar la sábana histórica al 100% desde el export de Athena
  - Archivos a crear/modificar: `Go Virtual/FASE_0_carga_historica.sql`
  - Criterio de completitud: la carga cubre todo 2026 hasta el mes en curso; el conteo de filas cargadas iguala al del origen; **cero** filas con `id_centro_ingresos = -1` o `id_responsable = -1` sin justificación documentada
  - ⚠️ Bloqueada por el export completo de Athena

- [ ] **T-09** — Crear `gv.sync_log` (bitácora propia)
  - Archivos a crear/modificar: `Go Virtual/FASE_0_bitacora.sql`
  - Criterio de completitud: registra inicio, fin, estado, filas leídas, filas afectadas, centinelas generados y error. Se crea propia y no se reutiliza `public.sync_log`, cuyas columnas son del dominio de RH (`vacaciones`, `ausencias`, `postulaciones`)

- [ ] **T-10** — Crear la función de cuadre jerárquico y la de cobertura vigente (RF-21, RF-23)
  - Archivos a crear/modificar: `Go Virtual/FASE_0_invariantes.sql`
  - Criterio de completitud: `gv.fn_validar_cuadre` devuelve error si la suma sobre **todos** los Responsables o Equipos no iguala al total; `gv.fn_cobertura_objetivo` separa el objetivo con titular vigente del que no lo tiene. **La suma de solo los vigentes es menor al total por diseño y no debe reportarse como falla** — tratarla como error haría que el sistema alertara todos los días

### Fase 1 — Validación contra el Tool (P1)

> Esta fase **no inicia** hasta que T-08 esté completa y la sábana respaldada al 100%.

- [ ] **T-11** — Función que reproduce las columnas del Tool por Centro de ingresos y mes
  - Archivos a crear/modificar: `Go Virtual/FASE_1_reproduccion_tool.sql`
  - Criterio de completitud: devuelve `Facturado`, `REFA`, `Cancelaciones`, `Devengado` y `Total` a partir de la `bandera`, para cualquier mes

- [ ] **T-12** — Reproducir julio 2026 y comparar contra el Tool
  - Archivos a crear/modificar: `Go Virtual/FASE_1_validacion_julio.md`
  - Criterio de completitud: comparación fila por fila contra `Go Virtual/tool_comercial_jul2026.csv`. Referencias: facturado total **5,936,719.26**, objetivo **9,293,066.27**. La comparación se hace contra **montos**, nunca contra los porcentajes de `Alcance` del Tool, que están corridos un renglón

- [ ] **T-13** — Reproducir junio y los meses previos disponibles
  - Archivos a crear/modificar: `Go Virtual/FASE_1_validacion_retroactiva.md`
  - Criterio de completitud: cada mes cerrado tiene su comparación documentada por Centro de ingresos y por Responsable

- [ ] **T-14** — Documentar la variación y fijar el parámetro de tolerancia
  - Archivos a crear/modificar: `Go Virtual/FASE_1_tolerancia.md`
  - Criterio de completitud: cada diferencia tiene causa identificada; Aldo aprueba explícitamente el umbral. **Sin este VoBo no arranca la Fase 3**

- [ ] **T-15** — Resolver la regla de clasificación de `Intereses`
  - Archivos a crear/modificar: `Go Virtual/FASE_1_regla_intereses.sql`
  - Criterio de completitud: las líneas con `clasificacion_gv` vacío y código SAT `84101700` resuelven al centro `Intereses`, o queda corregida la vista de Athena. Ninguna línea de intereses cae al centinela

### Fase 2 — ETL automatizado (P1)

- [ ] **T-16** — Preparar el refresco de snapshot en Athena (patrón México)
  - Archivos a crear/modificar: `Go Virtual/FASE_2_snapshot_athena.md`
  - Criterio de completitud: existe el paso de refresco y su ejecución es verificable de forma independiente
  - Ejecutado por Aldo en la consola de AWS

- [ ] **T-17** — Crear el workflow `ETL_facturacion_GV` en N8N
  - Archivos a crear/modificar: workflow N8N nuevo; `Go Virtual/_GV_etl_workflow.md`
  - Criterio de completitud: valida con 0 errores; **jamás se edita un workflow de GarantiPlus**

- [ ] **T-18** — Implementar el upsert idempotente y la resolución a centinelas
  - Archivos a crear/modificar: nodos Code del workflow; `Go Virtual/_GV_codenodes_etl.js`
  - Criterio de completitud: reejecutar sobre un periodo ya cargado no altera cifras de meses cerrados; las filas no resueltas caen a `-1` y se contabilizan en la bitácora

- [ ] **T-19** — Configurar el schedule y validar E2E
  - Archivos a crear/modificar: configuración del workflow
  - Criterio de completitud: corre a las **07:00 / 16:15 / 22:00** en `America/Mexico_City`; si el refresco de snapshot falla, el ETL se detiene y no extrae contra datos viejos

### Fase 3 — Funciones de agregación y Envío Diario (P1)

> No inicia sin el VoBo de tolerancia de T-14.

- [ ] **T-20** — `get_period_summary_gv` — consolidado de la organización
  - Archivos a crear/modificar: `Go Virtual/FASE_3_funcs_envio_diario.sql`
  - Criterio de completitud: devuelve facturado MTD, objetivo MTD prorrateado por **días naturales transcurridos**, alcance MTD y alcance Full Month, con desglose por Centro de ingresos

- [ ] **T-21** — `get_equipo_summary_gv` — consolidado por equipo con ranking interno
  - Archivos a crear/modificar: `Go Virtual/FASE_3_funcs_envio_diario.sql`
  - Criterio de completitud: la suma de los cinco equipos iguala al total de T-20

- [ ] **T-22** — `get_responsable_summary_gv` — corte individual
  - Archivos a crear/modificar: `Go Virtual/FASE_3_funcs_envio_diario.sql`
  - Criterio de completitud: acota los datos al alcance del Responsable **en la capa de datos**, no en el mensaje

- [ ] **T-23** — `get_responsables_ranking_gv` — ranking para Dirección
  - Archivos a crear/modificar: `Go Virtual/FASE_3_funcs_envio_diario.sql`
  - Criterio de completitud: ordena por alcance vs objetivo, excluye centinelas del orden y los reporta aparte

- [ ] **T-24** — Crear `gv.contacto` y poblarlo
  - Archivos a crear/modificar: `Go Virtual/FASE_3_contactos.sql`
  - Criterio de completitud: teléfono, `rh_persona.id`, rol y bandera de activo; solo se envía a activos

- [ ] **T-25** — Crear las plantillas de Twilio para Go Virtual
  - Archivos a crear/modificar: `Go Virtual/_GV_plantillas_twilio.md`
  - Criterio de completitud: tres plantillas aprobadas (Dirección, Equipo, Responsable); los `ContentVariables` se envían como `JSON.stringify()`, no como objeto

- [ ] **T-26** — Crear el workflow `Envio_diario_ventas_GV` con routing por rol
  - Archivos a crear/modificar: workflow N8N nuevo; `Go Virtual/_GV_codenodes_envio_diario.js`
  - Criterio de completitud: los nodos de formateo hacen **fan-out** (`$input.all().map`) y el número de mensajes enviados iguala al de contactos activos por rol; los nodos Code con múltiples items van en modo "Run Once for All Items"

- [ ] **T-27** — Prueba E2E y activación
  - Archivos a crear/modificar: configuración del workflow
  - Criterio de completitud: corre a las **09:30 / 17:00 / 22:30** en `America/Mexico_City`, después del ETL. Los tres roles reciben su mensaje. El primer mensaje muestra alcance MTD **y** Full Month (RF-22)

### Fase 4 — Chat conversacional (P2)

- [ ] **T-28** — Preparar la capa de conversación
  - Archivos a crear/modificar: `Go Virtual/FASE_4_chat_infra.sql`
  - Criterio de completitud: tabla de historial de chat propia de Go Virtual y credenciales del bot separadas de las de GarantiPlus

- [ ] **T-29** — Redactar el system prompt y las descripciones de tools
  - Archivos a crear/modificar: `Go Virtual/_GV_systemprompt.md`, `Go Virtual/_GV_tooldescription.txt`
  - Criterio de completitud: el prompt describe los 12 centros, los 5 equipos y las métricas; no incluye reglas de GarantiPlus que no aplican

- [ ] **T-30** — Crear el workflow `Atenea_v11_GV`
  - Archivos a crear/modificar: workflow N8N nuevo
  - Criterio de completitud: valida con 0 errores nuevos; responde por WhatsApp

- [ ] **T-31** — Probar el aislamiento por rol
  - Archivos a crear/modificar: `Go Virtual/FASE_4_pruebas_aislamiento.md`
  - Criterio de completitud: un Responsable que pregunta por el total de la organización o por cifras de un compañero recibe únicamente lo suyo

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `gv` (esquema) | Nueva | Aislamiento del dominio comercial dentro de `RH_Analytics` |
| `gv.catalogo_centro_ingresos` | Nueva | 12 centros canónicos con sus alias |
| `gv.catalogo_equipo` | Nueva | 5 equipos |
| `gv.catalogo_responsable` | Nueva | Responsables ligados a `rh_persona.id`, con equipo y vigencia |
| `gv.objetivo` | Nueva | Objetivo mensual 2026 por Responsable × Centro de ingresos |
| `gv.facturacion` | Nueva | Sábana de facturación con `bandera` preservada |
| `gv.contacto` | Nueva | Destinatarios del Envío Diario con rol y bandera de activo |
| `gv.sync_log` | Nueva | Bitácora del ETL |
| `gv.chat_historial` | Nueva | Historial del chat conversacional (Fase 4) |
| Índices en `gv.facturacion` | Índice | Por `fecha`, `id_centro_ingresos`, `id_responsable` |
| `public.rh_*` | **Sin cambios** | Solo lectura sobre `rh_persona` y `rh_empresa` |

---

## 6. Endpoints nuevos o modificados

No aplica. El proyecto no expone API REST; la interfaz son funciones RPC de PostgreSQL consumidas por N8N y el canal de WhatsApp.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `SUPABASE_URL_GV` | URL del proyecto `RH_Analytics` | Producción |
| `SUPABASE_KEY_GV` | Llave del rol `atenea_bot_gv` | Producción |
| `AWS_ACCESS_KEY_ID_GV` / `AWS_SECRET_ACCESS_KEY_GV` | Credenciales de lectura sobre `db-rpa` en Athena | Producción |
| `TWILIO_ACCOUNT_SID_GV` / `TWILIO_AUTH_TOKEN_GV` | Credenciales de Twilio para Go Virtual | Producción |
| `TWILIO_FROM_GV` | Número de WhatsApp de Go Virtual | Producción |

Todas viven en las credenciales de N8N o en variables de entorno. **Ninguna se escribe en el código ni se commitea** (`rules/infraestructura.md` §5).

---

## 8. Consideraciones de seguridad

- **Mínimo privilegio:** el rol `atenea_bot_gv` accede a `gv.*` y a exactamente dos tablas de RH (`rh_persona`, `rh_empresa`). Cualquier otra tabla `rh_*` —en particular `rh_persona_sensible`— queda denegada. Es la consideración más importante del plan: el proyecto convive con datos de nómina.
- **Sin `service_role`:** ni el ETL ni el bot usan la llave de servicio de Supabase, que salta RLS.
- **Aislamiento entre negocios:** credenciales, workflows y tablas separados de Atenea México, Colombia y Chile. Los workflows nuevos llevan sufijo `_GV` y **jamás se editan los existentes**.
- **RLS habilitado** en todas las tablas nuevas, consistente con el resto de `RH_Analytics`.
- **Secrets fuera del código**, en credenciales de N8N o variables de entorno.
- **Deuda heredada relevante:** Atenea México aún no tiene su rol `atenea_bot_mx` de bajo privilegio (deuda abierta desde la Sesión 24). Go Virtual arranca con el rol correcto desde el día uno para no repetirlo.

---

## 9. Consideraciones de infraestructura

- **Sin servicios AWS nuevos.** Se consume Athena en modo lectura sobre una vista que ya existe. No hay ECS, ni RDS, ni S3 adicionales, ni costo de infraestructura incremental.
- **Sin proyecto Supabase nuevo.** Se usa `RH_Analytics` (`onbnobxiwvppfiyjlooh`, us-east-1), que ya está activo y en la misma organización que los tres países de GarantiPlus. No hay costo adicional de plan.
- **N8N** corre en los VPS de Hostinger existentes. ⚠️ `rules/infraestructura.md` §3 advierte que la licencia de N8N vence en oct/nov del año en curso; dos workflows más aumentan la exposición a esa fecha.
- **Twilio** es el único costo incremental real: alta de número y mensajes de plantilla.

---

## 10. Criterios de aceptación

- [ ] El esquema `gv` existe con RLS y el rol `atenea_bot_gv` no puede leer `rh_persona_sensible`
- [ ] `gv.objetivo` suma **108,219,141.95** en 2026, con mes 1 = 9,319,472.19 y mes 7 = 9,293,066.27
- [ ] La sábana está respaldada al 100% y ninguna fila cae al centinela sin justificación documentada
- [ ] La reproducción de julio 2026 cuadra contra el Tool dentro del umbral aprobado en T-14
- [ ] La suma sobre **todos** los Responsables (vigentes y bajas) iguala a su Equipo, y la de Equipos al total, en cualquier periodo
- [ ] El mensaje de Dirección muestra explícitamente el **objetivo sin titular vigente** en lugar de absorberlo o redistribuirlo
- [ ] El ETL corre 3x/día, registra bitácora y se detiene si el snapshot falla
- [ ] Los tres roles reciben su mensaje, y el número de mensajes iguala al de contactos activos por rol
- [ ] El mensaje muestra alcance MTD prorrateado **y** Full Month, distinguibles sin ambigüedad
- [ ] Un Responsable no puede obtener, ni por el Envío Diario ni por el chat, cifras fuera de su alcance
- [ ] El reporte mensual manual del Tool deja de circularse como canal oficial

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| El export de Athena disponible no es representativo (100 filas de 2025, 4 de 12 centros, 2 de 6 banderas) | Alta | Alto | T-08 bloqueada hasta tener el export 2026 completo. Sin él no se puede validar la correspondencia `bandera` → columnas del Tool, que es el supuesto central del cálculo |
| La resolución de Responsables por texto falla en silencio | Alta | Alto | T-05 normaliza y resuelve a ID numérico; los no resueltos caen a `-1` visible. Caso ya confirmado: `Montserrat` / `montserrat` partía a una persona en dos |
| Sin credenciales de AWS para N8N, la Fase 2 se bloquea | Media | Alto | Se detecta en prerequisitos. Plan B: carga manual periódica, que degrada la promesa de visibilidad diaria pero no bloquea las Fases 0, 1 y 3 |
| El alta de número y plantillas de Twilio se vuelve camino crítico | Media | Medio | Iniciar el trámite en paralelo a la Fase 0, no al llegar a la Fase 3 |
| Los primeros días del mes muestran alcances MTD muy por encima de 100% | Alta | Medio | Es consecuencia del prorrateo lineal sobre facturación concentrada a inicio de mes. RF-22 mitiga mostrando también el Full Month; debe explicarse al equipo antes del primer envío |
| Convivencia con datos de nómina en el mismo proyecto Supabase | Baja | Alto | T-02 y RLS. Decisión aceptada explícitamente por Aldo |
| Fan-out mal implementado envía solo al primer contacto | Media | Alto | T-26 exige verificación de conteo. El bug ya ocurrió en el Envío Diario de Chile y no produjo error visible |
| Vencimiento de la licencia de N8N (oct/nov) | Media | Alto | Fuera del control del proyecto; se registra porque dos workflows más aumentan la exposición |

---

## 12. Notas para el programador

**Desviación consciente de `coding-guidelines.md` §1 (idioma del código).** La guideline exige identificadores en inglés. Este plan usa **español** en nombres de tablas, columnas y funciones. Razones: `RH_Analytics` ya usa español (`rh_persona`, `rh_empresa`, `sync_log` con `vacaciones`/`ausencias`), la familia Atenea también (`get_period_summary`, `ventas`, `objetivos`), y el dominio de origen es español (`clasificacion_gv`, `bandera`). Mezclar idiomas dentro del mismo proyecto Supabase costaría más de lo que la regla protege. **Validar esta desviación antes de ejecutar T-01.**

**Sobre `coding-guidelines.md` en general:** el documento es específico de .NET/C# (nomenclatura de clases, controladores, OData, rate limiting). De sus 12 secciones aplican §1 (idioma), §9 (logging, cubierto por la bitácora) y §11 (seguridad, cubierto por §8 de este plan). Las demás no tienen equivalente en SQL ni en nodos de N8N.

**Sobre el folio `PJ####`:** la convención real de `enginecx_prd` es `[Empresa]/PJ####-nombre-kebab/`, pero el número no lo genera este flujo. La carpeta quedó como `Go Virtual/atenea-go-virtual/`. Hay que asignarlo y renombrar antes de registrar el plan en la base de datos, porque `folio_prd` es la llave de enlace.

**Sobre la rama:** no existe `develop`. El plan parte de `main`, contra lo que marca `rules/version-control.md`. Vale la pena crear `develop` en `Atenea_Latam` antes de ejecutar, o dejar constancia de que este repositorio opera con un flujo distinto al estándar de Engine.

**Sobre el orden de ejecución:** la Fase 1 no arranca sin T-08 completa —indicación explícita de Aldo— y la Fase 3 no arranca sin el VoBo de tolerancia de T-14. Son las dos compuertas del plan; saltarlas es lo que convertiría el primer envío en un problema de credibilidad.

**Sobre lo que ya está hecho:** los objetivos 2026 y el catálogo de centros ya están extraídos y cuadrados en `Go Virtual/`. T-03 y T-06 son cargas, no extracciones.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Cimientos de datos (P1)** | Esquema `gv`, rol de bajo privilegio, catálogos, objetivos, sábana al 100%, bitácora e invariante de cuadre | T-01 a T-10 | 5 – 8 días | |
| **Fase 1 — Validación contra el Tool (P1)** | Reproducción de las columnas del Tool, validación de julio y meses previos, tolerancia aprobada, regla de Intereses | T-11 a T-15 | 3 – 5 días | |
| **Fase 2 — ETL automatizado (P1)** | Snapshot en Athena, workflow N8N, upsert idempotente, schedule 3x/día | T-16 a T-19 | 3 – 4 días | |
| **Fase 3 — Funciones y Envío Diario (P1)** | 4 RPCs, contactos, plantillas Twilio, workflow con routing de 3 roles, E2E | T-20 a T-27 | 5 – 8 días | |
| **Fase 4 — Chat conversacional (P2)** | Infra de conversación, system prompt, workflow del agente, pruebas de aislamiento | T-28 a T-31 | 4 – 6 días | |
| **Total proyecto (P1+P2)** | | 31 tareas | ~20 – 31 días hábiles (≈ 4 – 6 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 + Fase 3 | T-01 a T-27 | ~16 – 25 días hábiles (≈ 3 – 5 semanas) | — |

> **Notas sobre la tabla:**
> - El guardarraíl P1 de este proyecto son **cuatro fases**, no dos: el MVP comprometido en el PRD es "ETL + Envío Diario validado", y eso no existe hasta la Fase 3. La Fase 4 (chat) es lo único diferible.
> - Los rangos suponen **un solo desarrollador** y no incluyen los tiempos de terceros: alta de número y plantillas de Twilio, y provisión de credenciales de AWS. Ambos pueden correr en paralelo y no consumen días de desarrollo, pero sí pueden bloquear el avance.
> - La Fase 1 tiene el rango más incierto: si la variación contra el Tool resulta alta, explicar cada diferencia puede desbordar los 5 días. Es el punto donde más conviene reservar holgura.

> **Riesgo de deadline:** el PRD **no fija fecha límite**, por lo que no es posible contrastar días disponibles contra el rango estimado. Conviene definirla antes de ejecutar; sin fecha, el riesgo real no es de alcance sino de que la Fase 1 se dilate sin cierre. Si más adelante aparece una fecha comprometida y P1 no cabe, la recomendación es entregar Fases 0 a 2 con validación y **carga manual periódica**, dejando el Envío Diario automatizado para una segunda entrega — con un segundo desarrollador en paralelo, las Fases 2 y 3 son independientes entre sí y podrían comprimir el total en torno a un 25%.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
