# Plan de Desarrollo — Análisis técnico y documentación de GarantiMAX (Dashboard GarantiPLUS)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/GarantiMAX/PJ3896-garantimax-analisis-tecnico/PRD.md` (v0.1, 21-08-2026) |
| Repositorio (entregable) | `garantiplusmexico/enginecx_prd` |
| Repositorio analizado (solo lectura) | `garantiplusmexico/garantiplus-dashboard` — local en `C:\Users\JavierAntonioOropeza\Documents\Proyectos\garantimax` |
| Rama base | `main` (en `enginecx_prd`) — ⚠️ no existe `develop`, ver §12 |
| Rama | `feature/PJ3896-garantimax-analisis-tecnico` |
| Tipo | Análisis técnico / discovery — entregable documental, **no se escribe código de producto** |
| Etapas | **A** — el proyecto por dentro (arranca 24-08, solo repositorio) · **B** — la plataforma: Supabase y API de SIGA (sin fecha, arranca al recibir A1/A3). Ver §1.4 |
| Responsable | Javier Antonio Oropeza Camacho |
| Folio PRD | `PJ3896` |
| Fecha de generación | 24-08-2026 |
| Estado | Borrador |
| ID plan (BD) | `55` |
| Modelo / esfuerzo de generación | `claude-opus-5` — esfuerzo alto |

---

## 1. Resumen técnico

Este plan ejecuta un **análisis técnico de solo lectura** sobre GarantiMAX y produce **documentación en Markdown versionado con diagramas mermaid**. No crea ni modifica software, no escribe en la base y no altera configuración (RNF-01).

**Qué se crea:** 21 documentos `.md` (un archivo por capítulo C1–C19, más índice y metodología), un registro único de hallazgos priorizados, un registro de supuestos y preguntas abiertas, y una carpeta de inventarios extraídos de forma automatizada. Todo vive en `enginecx_prd/GarantiMAX/PJ3896-garantimax-analisis-tecnico/analisis/`.

**Qué se modifica:** nada del sistema analizado. La única escritura es documental, en el repositorio de PRDs.

**El plan se ejecuta en dos etapas** (ver §1.4): la **Etapa A** levanta todo lo técnico del proyecto usando solo el repositorio, y arranca hoy; la **Etapa B** cierra lo que exige accesos externos —verificación contra la base Supabase y auditoría de la API de SIGA— y arranca cuando esos accesos lleguen.

**Arquitectura aplicable:** ninguna de las de `rules/arquitectura.md` — este proyecto no despliega componentes. Lo que sí aplica es el **marco de comparación**: la evaluación de escenarios de destino se hace contra el estándar corporativo de Engine (.NET 8, ECS + Fargate, RDS PostgreSQL, Identity, SignalR, EF Core), tomado de `rules/stack.md`, `rules/infraestructura.md` y `rules/arquitectura.md` como referencia de sustitución. Ver §3.

**Stack del análisis:** Markdown + mermaid como entregable; Git para versionado; lectura del repositorio, lectura del catálogo de Postgres vía Supabase y lectura documental de la API de SIGA como fuentes. Sin runtime, sin base de datos propia, sin despliegue.

### 1.1 Línea base verificada (medida al generar este plan)

Medido sobre `origin/master` = **`3771e7f`** (2026-08-19 11:24 -0400) del repositorio analizado:

| Métrica | PRD (v0.1) | Medido real | Δ |
|---|---|---|---|
| Migraciones SQL | 355 | **364** | +9 |
| Edge Functions | 46 | **46** | ✅ |
| Módulos en `src/features/` | 24 | **24** | ✅ |
| Archivos `.ts`/`.tsx` en `src/` | 455 | **464** | +9 |
| Líneas en `src/` (ts/tsx) | ~109 000 | **113 587** | +4 587 |
| Archivos de test | 60 | **65** | +5 |
| Usos de `.channel()` (Realtime) | 11 | **11** | ✅ |

Dimensionamiento adicional levantado para estimar (aproximado, a confirmar contra el catálogo real en T-08/T-09):
- **~152** sentencias `CREATE TABLE` distintas y **3** vistas en el historial de migraciones.
- **~269** declaraciones `CREATE [OR REPLACE] FUNCTION` (incluye reemplazos: el número de RPCs vivas será menor).
- Módulos confirmados: `auth`, `averias`, `bienvenida`, `bitacora`, `callcenter`, `cobertura`, `config`, `facturacion`, `farmer`, `gastos`, `hunter`, `incentivos`, `induccion`, `mora`, `portal`, `postventa`, `productos`, `resumen`, `salas`, `solicitudes`, `unoauno`, `vendedores`, `visitas`, `warroom`.

**El baseline de Realtime del PRD (C8) queda verificado al 100%:** los 11 canales existen y están exactamente en los tres módulos y los archivos que el PRD nombra — `warroom` (`visitasRealtime.ts:29`, `useWarRoomEventos.ts:99` y `:122`, `useVisitasEnCurso.ts:42`, `WarRoomView.tsx:594`), `callcenter` (`telefonoStore.ts:268`, `TelefonoPanel.tsx:485`, `TelefonoKpis.tsx:297`) y `postventa` (`datos/casosDb.ts:1780` y `:1850`, `ChatWhatsapp.tsx:84`).

**Corrección al PRD (C13/RF-15):** el PRD plantea la duda "ausencia o presencia de pipeline propio". **Sí hay pipeline propio**: `.github/workflows/ci.yml` corre `npm ci`, `npm run lint`, `npm test` y `npm run build` en cada push y PR a `master`, sobre Node 22. El capítulo debe partir de que existe y evaluar su cobertura, no su existencia.

### 1.2 Trazabilidad capítulo → requerimiento → tarea

| Cap. | Requerimientos | Etapa A | Etapa B (cierre) |
|---|---|---|---|
| C1 Ficha tecnológica | RF-01 | T-06 | — |
| C2 Mapa de módulos, lógica y **dominio** | RF-02, RF-03 | T-07 | — |
| C3 Modelo de datos | RF-04 | T-08, T-09 *(inferido)* | **T-31, T-33** *(verificado)* |
| C4 Catálogo Edge Functions | RF-06 | T-11 | — |
| C5 Integraciones externas | RF-07 | T-12 | — |
| C5' Datos muertos | RF-05 | T-10 *(candidatos)* | **T-34** *(confirmados)* |
| C6 Uso de SIGA (Excel) | RF-08 | T-13 | — |
| C7 Cobertura API de SIGA | RF-09 | — | **T-36** |
| C8 Mapa de Realtime | RF-10 | T-14 | — |
| C9 PWA y offline | RF-11 | T-15 | — |
| C10 Arquitectura y patrones | RF-12 | T-16 | — |
| C11 Seguridad | RF-13 | T-17 *(código; RLS declarado)* | **T-32** *(RLS real)* |
| C12 Rendimiento y escalabilidad | RF-14 | T-18 | — |
| C13 Testing, CI/CD y proceso | RF-15 | T-19 | — |
| C14 Observabilidad y operación | RF-16 | T-20 | — |
| C15 Supabase vs .NET 8 — qué alberga, por dominio | RF-17 | T-23 *(estructura)* | **T-35** *(peso y costo)* |
| C16 Escenarios E0–E4 | RF-18, RF-20 | T-24 | **T-37** *(E4 resuelto)* |
| C17 Opciones de PWA | RF-19 | T-25 | — |
| C18 Dictamen | RF-21 | T-26 *(preliminar)* | **T-38** *(definitivo)* |
| C19 Resumen ejecutivo | RF-22 | T-27 | **T-38** *(actualizado)* |
| Transversal | RF-23, RF-24, RNF-01…14 | T-03, T-04, T-28, T-30 | T-38 |

> De los 20 capítulos, **12 se cierran por completo en la Etapa A** (C1, C2, C4, C5, C6, C8, C9, C10, C12, C13, C14, C17), **7 quedan a medias** esperando verificación (C3, C5', C11, C15, C16, C18, C19) y solo **1 —C7, la API de SIGA— no puede ni empezarse** sin el acceso. Ese reparto es la razón por la que arrancar hoy tiene sentido: la mayor parte del análisis técnico no depende de los permisos que faltan.

> La columna **Prioridad** no viene del PRD (que declara las tres fases como un único MVP). Se deriva aquí a partir del árbol de decisión de la §7.3 del PRD: **P1** es lo sin lo cual el dictamen no se sostiene, **P2** es profundidad que puede recortarse declarando cobertura (RNF-11), **P3** es lo que depende de un tercero.
>
> Con el calendario extendido (§13) **el alcance completo se ejecuta entero**: ya no hay recorte planificado. Las prioridades se conservan porque siguen sirviendo para dos cosas — ordenar el trabajo dentro de cada fase, y tener una palanca lista si aparece un imprevisto a mitad de camino.

### 1.3 El escenario E4: retención parcial por dominio

El PRD compara cuatro escenarios que tratan Supabase como un bloque: se conserva entero (E0) o se sustituye entero (E1/E2/E3). Falta la posibilidad intermedia, que es la que la Dirección plantea de forma explícita: **que Supabase se quede solo con la parte que le corresponde**.

La hipótesis a evaluar es que GarantiMAX contiene **dos negocios distintos** conviviendo en la misma base:

| Dominio candidato | Módulos (a confirmar en T-07) | Destino natural |
|---|---|---|
| **Comercial / seguimiento de vendedores** | `vendedores`, `salas`, `visitas`, `cobertura`, `incentivos`, `warroom`, `hunter`, `unoauno`, `bitacora`, `resumen` | No existe en SIGA ni en el ecosistema Engine. Candidato a **quedarse en Supabase**. |
| **Operación de garantías** | `averias`, `postventa`, `facturacion`, `mora`, `productos`, `portal`, `callcenter`, `solicitudes` | Solapa con SIGA — que ya es el sistema de contratos y averías. Candidato a **absorberse en .NET / SIGA**. |
| **Transversal** | `auth`, `config`, `induccion`, `bienvenida`, `gastos`, `farmer` | Se reparte o se duplica según el corte. |

Si la hipótesis se sostiene, **E4 es el escenario más barato de todos**: no migra lo que no tiene destino y sí consolida lo que hoy está duplicado con SIGA. Si no se sostiene —porque los dominios comparten tablas, RPCs o cálculos— entonces el acoplamiento interno es el hallazgo, y E4 queda descartado con evidencia en lugar de por intuición.

Esto **no es un escenario más en la lista**: cambia lo que Fase 1 tiene que producir. T-07 y T-08 dejan de ser un inventario plano y pasan a ser una **segmentación por dominio**, con la pregunta explícita de qué tablas, RPCs y cálculos cruzan la frontera. Esas costuras son lo que decide si E4 es viable, y no se pueden reconstruir después sin volver a recorrer los 24 módulos.

La **hipótesis de dominios se construye en la Etapa A** desde el código y las migraciones (que es donde vive la estructura). Lo que la Etapa B añade no es la hipótesis sino el **peso**: cuántas filas, cuántas invocaciones y cuánto costo hay a cada lado de la frontera. Se puede proponer el corte sin la base; no se puede recomendarlo.

### 1.4 Las dos etapas y por qué se separan

Dos de los seis accesos (§2.1) no están disponibles hoy: **A1**, lectura de la base Supabase —el `.env` está pendiente de entrega— y **A3**, la fuente autoritativa de la API de SIGA. En lugar de esperar, el plan se parte en dos etapas con entregable propio cada una.

| | **Etapa A — El proyecto por dentro** | **Etapa B — La plataforma** |
|---|---|---|
| **Arranca** | Ahora (24-08-2026) | Al recibir A1 / A3 |
| **Necesita** | Solo el repositorio | A1 lectura Supabase, A2 costos, A3 API de SIGA, A4 muestras Excel |
| **Fases** | 0 a 4 (T-01 a T-30) | 5 y 6 (T-31 a T-38) |
| **Estimación** | 13 – 19 días hábiles | 5 – 7 días hábiles |
| **Entrega** | Análisis técnico completo + **dictamen preliminar** | Verificación contra la base, matriz de SIGA, E4 resuelto y **dictamen definitivo** |

**Qué queda dentro de la Etapa A** (todo lo técnico del proyecto, que es lo que se pidió priorizar): stack y dependencias, los 24 módulos con sus reglas de negocio y su segmentación por dominio, el modelo de datos **inferido de las 364 migraciones**, las 46 Edge Functions, las integraciones externas, el flujo real de importación de Excel, los 11 canales de Realtime, la PWA y su offline, la evaluación de arquitectura y patrones, la seguridad **a nivel de código**, rendimiento, testing/CI-CD, observabilidad, y la comparación de los cinco escenarios con dictamen preliminar.

**Qué se aparta a la Etapa B:** solo lo que es imposible afirmar sin el acceso — el modelo de datos *verificado contra el catálogo real* (frente al inferido), las políticas RLS *reales* (frente a las declaradas en migraciones), los volúmenes y el costo, los datos muertos *confirmados*, y la matriz de cobertura de la API de SIGA.

**El caso de SIGA merece una nota,** porque el orden importa: hoy los datos entran por **importación manual de Excel**, y eso se documenta entero en la Etapa A (T-13) leyendo los parsers, que son la fuente de verdad de lo que realmente se consume. Solo cuando esa lista de campos exista se puede preguntarle algo útil a la API de SIGA — *"¿cubres estos 40 campos concretos?"* en lugar de *"¿qué tienes?"*. Así que la Etapa B no está esperando el acceso por comodidad: **necesita el resultado de la Etapa A para que la auditoría valga**.

**Lo que cuesta partirlo.** Dos etapas suman más que una sola: **18 – 26 días hábiles** contra los 15 – 22 de la versión monolítica. La diferencia es el retrabajo de volver a abrir capítulos ya escritos para reemplazar lo inferido por lo verificado. Es un precio consciente: se compra la posibilidad de arrancar hoy en lugar de esperar bloqueado, y lo que se paga son días de re-verificación, no calidad del resultado final.

**El riesgo real de este esquema** es que la Etapa B nunca llegue y el dictamen preliminar se lea como definitivo. Mitigación explícita: cada capítulo afectado lleva una marca visible de **"inferido — pendiente de verificación en Etapa B"**, y el dictamen preliminar declara en su primera línea qué conclusiones podrían cambiar cuando se verifique. Un documento que se pasa por definitivo sin serlo es peor que no tenerlo.

---

## 2. Prerequisitos

**Para la Etapa A — todo listo, se arranca hoy:**

- [ ] PRD validado por el responsable
- [x] Acceso al repositorio analizado (`garantimax` local, remoto `garantiplusmexico/garantiplus-dashboard`)
- [x] Acceso al repositorio del entregable (`garantiplusmexico/enginecx_prd`, rama `main` al día)
- [x] `CLAUDE.md` presente en el repositorio analizado
- [x] **Confirmado: la decisión de migrar NO está tomada.** El propósito del análisis es determinarla. Los cinco escenarios se evalúan con criterios idénticos y sin favorito (RNF-10). Ver §1.3 y §12 nota 5.
- [ ] **A5 — Panel de Sentry** — deseable, no bloqueante. Sin él, T-20 documenta la configuración desde el código pero no qué se captura de verdad.
- [ ] **A6 — Ventanas de conversación con los interlocutores** — deseable, no bloqueante. Sin ellas, la criticidad operativa (T-07) y la latencia exigida (T-14) se marcan como supuesto.

> **Nada de lo anterior detiene el arranque de la Etapa A.** Las cinco fases corren con el repositorio en la mano. Lo que falte se registra como pregunta abierta (T-02) en lugar de rellenarse con una estimación inventada — es el patrón que el PRD fija en su §7.1.

**Para la Etapa B — pendientes, y por eso la etapa está apartada:**

- [ ] **A1 — Lectura de la base Supabase** · ⏳ *el `.env` está pendiente de entrega*. Gobierna toda la Fase 5 (T-31 a T-35).
- [ ] **A2 — Paneles de costo y consumo de Supabase y Vercel**. Gobierna T-35 y la dimensión de costo del dictamen definitivo.
- [ ] **A3 — Fuente autoritativa de la API de SIGA**. Gobierna T-36.
- [ ] **A4 — Muestras de los reportes Excel de SIGA**. Refina T-13 (Etapa A) y alimenta T-36.

> **La Etapa B no arranca hasta que llegue A1 o A3**, y no pasa nada: su entregable es *verificación*, no descubrimiento. Mientras no lleguen, los capítulos afectados quedan marcados como **inferido — pendiente de verificación en Etapa B**, nunca como cerrados.

### 2.1 Qué se necesita exactamente, de quién y en qué forma

Detalle operativo para poder pedir los accesos sin una segunda ronda de aclaraciones. **El orden es de urgencia:** A1 y A2 se piden el día 1 porque son los que más trabajo bloquean.

**A1 — Lectura de la base Supabase** · pedir a: quien administre el proyecto Supabase (previsiblemente Fabrizio Álvarez)
- **Opción preferida:** un usuario de Postgres de **solo lectura** sobre el proyecto `jrykbalmnpymeyzdhsam`, con `CONNECT` a la base, `USAGE` en los esquemas `public` y `auth`, y `SELECT` en sus tablas y vistas. Con eso alcanza para leer `information_schema`, `pg_catalog`, `pg_policies` y `pg_proc`, y para contar filas.
- **Alternativa aceptable:** acceso al panel de Supabase con rol de lectura (permite ver el editor de tablas, las políticas RLS y el SQL editor).
- **Alternativa mínima:** que quien tenga el acceso corra un guion de introspección que yo entregue y devuelva la salida en CSV. Resuelve T-08 y T-09 pero no permite repreguntar, así que alarga el ciclo.
- **Explícitamente NO se pide** la `service_role` key: el análisis no la necesita y pedirla ampliaría la superficie de riesgo sin beneficio.
- **Si no llega:** el modelo de datos se infiere de las 364 migraciones. Queda marcado como *inferido, no verificado*, con el riesgo de describir tablas que ya no existen y volúmenes equivocados. Además **T-10 (datos muertos) pierde casi todo su valor**, porque "sin uso" no se puede afirmar sin mirar la base.

**A2 — Costos y consumo de plataforma** · pedir a: quien administre la facturación de Supabase y de Vercel
- De **Supabase**: plan contratado y costo mensual de los últimos 3–6 meses; invocaciones de Edge Functions; mensajes y conexiones concurrentes de Realtime; tamaño de la base y de Storage; egreso.
- De **Vercel**: plan y costo mensual del mismo período; ancho de banda; invocaciones y minutos de build.
- **Basta una captura o un export CSV del panel de facturación** — no hace falta acceso permanente, y así el permiso no queda abierto más tiempo del necesario.
- **Por qué importa más de lo que parece:** el costo es uno de los dos motores del proyecto, y ahora también es el criterio que decide E4. Saber *cuánto* del costo viene del dominio comercial y cuánto del operativo es lo que dice si conviene partir la plataforma.
- **Si no llega:** T-23 y T-24 documentan el **modelo** de costo y sus factores de riesgo, y la dimensión de costo se marca como no cuantificada **en los cinco escenarios por igual**, para no sesgar la comparación.

**A3 — API de SIGA** · pedir a: el equipo responsable de la API de SIGA
- La fuente autoritativa: repositorio, Swagger/OpenAPI o documentación vigente — **con cuál de las tres es la buena**, si hay más de una.
- Un contacto con nombre para validar cobertura y para responder si se pueden agregar endpoints.
- Acceso de lectura al repositorio, si la fuente es el código.
- **No se piden credenciales de ejecución:** la auditoría de T-36 es documental, no se llama la API.
- **Si no llega:** T-36 se cierra declarando el hueco, y el dictamen asume como riesgo aceptado que cualquier escenario de migración arrastra la dependencia manual de Excel.

**A4 — Muestras de reportes Excel de SIGA** · pedir a: Fabrizio Álvarez o quien ejecute la carga
- Un archivo real de cada uno de los tres: averías **ACTIVAS**, averías **CERRADAS** y **contratos**.
- Idealmente el archivo tal como se descarga de SIGA, sin editar — el encabezado en la fila 3 es parte de lo que hay que documentar.
- Y el dato operativo que no está en el archivo: **con qué frecuencia se sube y quién lo hace**.
- Los archivos contienen datos personales: se usan solo para leer estructura y se anonimizan en los ejemplos (RNF-04).
- **Si no llega:** T-13 documenta las columnas desde el código de los parsers (`parseAverias.ts`, `parseContratos.ts`), que es la fuente real de verdad de lo que se consume. Se pierde la validación de formato y la detección de columnas que llegan pero se ignoran.

**A5 — Sentry** · pedir a: quien administre la organización de Sentry
- Acceso de lectura al proyecto, o un export de: volumen de eventos del último mes, top de errores por frecuencia, y qué alertas están configuradas.
- **Si no llega:** T-20 documenta la configuración desde el código (`VITE_SENTRY_DSN`, inicialización) pero no puede decir qué se está capturando **de verdad** ni si alguien mira las alertas — que es la pregunta que importa.

**A6 — Interlocutores** · coordinar: Javier Oropeza
- **Fabrizio Álvarez** — 2 sesiones de ~1 h: una en Fase 1 para criticidad operativa por módulo y la frontera entre dominios de §1.3; otra en Fase 3 para uso real de la PWA en terreno y latencia exigida en War Room y call center.
- **Mantenedor actual** — 1 sesión de ~1 h para lógica de negocio no evidente en el código (cierres, comisiones, siniestralidad, proyecciones) y decisiones históricas.
- **Equipo de la API de SIGA** — 1 sesión de ~45 min para cobertura de endpoints y capacidad de agregarlos.
- **Aldo Álvarez** — la sesión de revisión de la PUERTA 2 (T-29), agendada desde ahora para que no sea el cuello de botella del cierre.
- **Si no hay disponibilidad:** las preguntas se agrupan y se envían por escrito; lo que no se valide se marca como supuesto en lugar de bloquear la fase.

> **Dos datos que hoy nadie tiene y que conviene empezar a levantar ya**, porque no salen de ningún panel: **cuántos asesores usan la PWA en terreno** y **qué latencia exige de verdad la operación** en War Room y call center. Sin el primero, la comparación de las tres opciones de PWA (T-25) se queda en lo cualitativo. Sin el segundo, no se puede decidir entre SignalR, polling o conservar Supabase Realtime — que es justamente la pregunta de la §12 nota 5.

---

## 3. Arquitectura del cambio

Este proyecto **no introduce arquitectura de software**. Lo que sí tiene arquitectura es el propio análisis: un flujo secuencial con dos puertas de control, tomado de la §7.1 del PRD.

```
Fase 0: habilitación          Fase 1: inventario         Fase 2: calidad
[commit fijado]               [C1..C9 con evidencia]     [C10..C14]
[accesos + método]     ──►    [inventarios/*.csv]  ──►   [hallazgos priorizados]
[esqueleto de docs]                    │                          │
                                       ▼                          ▼
                             ◄PUERTA 1: inventario      Fase 3: escenarios
                              completo y validado►      [C15..C18 + C7]
                                                                  │
                                                                  ▼
                                                        Fase 4: cierre
                                                        [C19 + vigencia]
                                                                  │
                                                                  ▼
                                                   ◄PUERTA 2: revisión
                                                    Dirección de TI►
                                                                  │
                                                                  ▼
                                              Decisión: refactor / rehacer / migrar
```

**Por qué secuencial y no paralelo:** no se juzga la calidad de lo que no está inventariado, y no se comparan escenarios sin hallazgos con evidencia. Las puertas existen porque el riesgo mayor de un análisis de este tamaño es concluir sobre una parte del sistema y descubrir después que faltaba un módulo crítico.

**Marco de comparación (para C15–C17).** El estándar corporativo contra el que se evalúa cada servicio de Supabase, tomado de las reglas de Engine:

| Servicio Supabase hoy | Referencia Engine para sustituirlo |
|---|---|
| Postgres + RLS | RDS PostgreSQL + autorización en capa .NET (`rules/stack.md`, `rules/infraestructura.md`) |
| Auth (correo/contraseña + Google) | ASP.NET Core Identity + JWT (`rules/coding-guidelines.md` §6) |
| Storage | S3 en la consola AWS correspondiente (`rules/infraestructura.md` §2) |
| Edge Functions (46) | Contenedores Docker en ECS + Fargate (`rules/arquitectura.md` §1) |
| Realtime (11 canales) | SignalR sobre ECS, o refresco por consulta donde la latencia lo permita |
| Vercel (hosting + previews) | S3 estático / ALB + ECS, DNS en Cloudflare o Route 53 |

> Este cuadro es **el punto de partida de C15, no su conclusión**. RNF-10 (neutralidad tecnológica) exige que la columna derecha se evalúe con el mismo rigor que la izquierda: cada sustitución se dimensiona en esfuerzo, riesgo y costo operativo, y el veredicto puede ser perfectamente "no conviene sustituirlo".

### 3.1 Estructura del entregable

```
enginecx_prd/GarantiMAX/PJ3896-garantimax-analisis-tecnico/
├─ PRD.md                              (existente)
├─ PLAN.md                             (este archivo)
├─ AVANCE.md                           (lo crea la ejecución)
└─ analisis/
   ├─ README.md                        Índice navegable, commit analizado, cobertura declarada
   ├─ 00-metodologia-y-evidencia.md    Severidad, formato de cita, criterio de cobertura
   ├─ 01-ficha-tecnologica.md          C1  / RF-01
   ├─ 02-mapa-modulos.md               C2  / RF-02, RF-03
   ├─ 03-modelo-datos.md               C3  / RF-04
   ├─ 04-datos-muertos.md              C5' / RF-05
   ├─ 05-edge-functions.md             C4  / RF-06
   ├─ 06-integraciones-externas.md     C5  / RF-07
   ├─ 07-uso-de-siga.md                C6  / RF-08
   ├─ 08-api-siga-cobertura.md         C7  / RF-09
   ├─ 09-mapa-realtime.md              C8  / RF-10
   ├─ 10-pwa-y-offline.md              C9  / RF-11
   ├─ 11-arquitectura-y-patrones.md    C10 / RF-12
   ├─ 12-seguridad.md                  C11 / RF-13
   ├─ 13-rendimiento-escalabilidad.md  C12 / RF-14
   ├─ 14-testing-cicd-proceso.md       C13 / RF-15
   ├─ 15-observabilidad-operacion.md   C14 / RF-16
   ├─ 16-supabase-vs-net8.md           C15 / RF-17
   ├─ 17-escenarios-destino.md         C16 / RF-18, RF-20
   ├─ 18-opciones-pwa.md               C17 / RF-19
   ├─ 19-dictamen.md                   C18 / RF-21
   ├─ 20-resumen-ejecutivo.md          C19 / RF-22
   ├─ hallazgos.md                     Registro único priorizado (RNF-09)
   ├─ preguntas-abiertas.md            Supuestos y huecos (RF-23, RNF-11)
   └─ inventarios/                     Extracciones reproducibles (módulos, tablas, RPCs, EF)
```

---

## 4. Tareas de desarrollo — Etapa A (el proyecto por dentro)

> Todas las tareas son de **lectura y redacción**. Ninguna modifica el sistema analizado (RNF-01).
> Todo hallazgo, cifra o afirmación cita su fuente: archivo y línea, consulta, configuración o interlocutor (RF-23).

### Fase 0 — Habilitación, línea base y método (24-08 → 25-08)

- [ ] **T-01** — Sincronizar el repositorio analizado y fijar el commit de vigencia
  - Archivos a crear/modificar: `analisis/README.md` (bloque "Código analizado")
  - Acción: `git fetch` + `git pull` en `garantimax` para cerrar el desfase detectado, y registrar commit y fecha exactos.
  - Contexto verificado: la copia local está en `de6ce01` (2026-08-06) y `origin/master` en `3771e7f` (2026-08-19) — **29 commits de desfase**. El supuesto del PRD *"el repositorio local está actualizado"* es falso hoy.
  - Criterio de completitud: `README.md` declara commit, fecha y hora del código analizado (RNF-14); el desfase queda documentado como incidencia de arranque.

- [ ] **T-02** — Confirmar accesos y registrar los bloqueados
  - Archivos a crear/modificar: `analisis/preguntas-abiertas.md`
  - Acción: verificar los cinco accesos de §2 (Supabase lectura, API de SIGA, muestras Excel, paneles de costo, interlocutores). Cada uno confirmado o registrado como pregunta abierta con su dueño y su impacto en capítulos.
  - Criterio de completitud: cada acceso tiene estado ✅/❌ y, si falta, nombra el capítulo que degrada y la persona a quien se le pidió.

- [ ] **T-03** — Esqueleto de la documentación e índice navegable
  - Archivos a crear: los 21 `.md` de §3.1 con cabecera de versión/fecha, más `hallazgos.md` y `preguntas-abiertas.md`
  - Criterio de completitud: `README.md` enlaza a todos los capítulos; cada archivo declara versión, fecha y estado (pendiente / en curso / cerrado). Cumple RF-24 y RNF-05.

- [ ] **T-04** — Definir y publicar el método antes de los resultados
  - Archivos a crear: `analisis/00-metodologia-y-evidencia.md`
  - Contenido: escala de severidad (crítico/alto/medio/bajo) con criterio declarado (RNF-09); formato de cita de evidencia (RF-23, RNF-02); separación estructural entre hecho y opinión (RNF-07); criterio de cobertura declarada (RNF-11); reglas de anonimización (RNF-04) y de no transcripción de secretos (RNF-03); protocolo de escalamiento inmediato si se detecta una vulnerabilidad activa.
  - Criterio de completitud: el documento se cierra **antes** de empezar Fase 2, igual que el PRD publica su árbol de decisión antes de tener resultados. Es lo que impide que el criterio se acomode al hallazgo.

- [ ] **T-05** — Extracción automatizada de inventarios base
  - Archivos a crear: `analisis/inventarios/` (módulos, migraciones, Edge Functions, dependencias, canales Realtime, archivos de test)
  - Acción: comandos de solo lectura sobre el repositorio, guardados junto a su salida para que cualquiera con los mismos accesos los reproduzca (RNF-02).
  - Criterio de completitud: las siete métricas de §1.1 quedan reproducibles con el comando que las generó, y las diferencias contra el PRD v0.1 quedan explicadas.

### Fase 1 — Inventario y mapeo (26-08 → 02-09) · **PUERTA 1 al cierre**

- [ ] **T-06** — C1: Ficha tecnológica con veredicto por dependencia *(RF-01)*
  - Archivos a crear/modificar: `analisis/01-ficha-tecnologica.md`
  - Contenido: cada dependencia relevante con versión real de `package.json`, para qué se usa, **dónde** (archivo), equivalente en el ecosistema .NET si existe, y veredicto: conservable / sustituible / riesgosa.
  - Criterio de completitud: ninguna dependencia relevante sin veredicto ni sin al menos una ubicación de uso citada.

- [ ] **T-07** — C2: Mapa de los 24 módulos y ubicación de la lógica de negocio *(RF-02, RF-03)*
  - Archivos a crear/modificar: `analisis/02-mapa-modulos.md`
  - Contenido: una ficha por módulo (los 24 listados en §1.1): propósito, pantallas, reglas de negocio, tablas y RPCs que toca, dependencias con otros módulos, criticidad operativa, y **dónde vive la lógica** (front / RPC de Postgres / Edge Function).
  - **Además — segmentación por dominio (insumo de E4, §1.3):** cada módulo se clasifica como *comercial / seguimiento de vendedores*, *operación de garantías* o *transversal*, y se marca si **solapa con SIGA**. Las dependencias entre módulos de dominios distintos se listan una por una: son las costuras que deciden si la plataforma se puede partir.
  - Criterio de completitud: 24 fichas, ninguna vacía; la criticidad operativa y la frontera entre dominios validadas con Fabrizio Álvarez y marcadas como tal. RF-03 es el dato que define el costo real de migrar el backend — si una ficha no lo resuelve, la ficha no está lista.

- [ ] **T-08** — C3: Inventario de tablas, RLS, relaciones y volúmenes *(RF-04)*
  - Archivos a crear/modificar: `analisis/03-modelo-datos.md`, `analisis/inventarios/tablas.csv`
  - Contenido: todas las tablas con propósito, dominio, claves y relaciones, volumen de filas, política RLS asociada, y módulos que la leen y escriben. Diagramas ER por dominio en mermaid.
  - **Alcance en Etapa A: reconstruido desde las 364 migraciones y desde el uso en el código**, no desde el catálogo real. El esquema se reconstruye leyendo el historial completo (`CREATE TABLE`, `ALTER TABLE`, `CREATE POLICY`), que es una fuente legítima y sorprendentemente completa — solo no es *autoritativa*, porque no revela lo que se cambió a mano fuera de las migraciones ni los volúmenes.
  - Punto de partida: ~152 `CREATE TABLE` en el historial. El número vivo se confirma en **T-31 (Etapa B)**.
  - **Además — segmentación por dominio (insumo de E4, §1.3):** cada tabla se etiqueta con su dominio (comercial / operación / transversal) y se marca si la escriben o leen módulos de **más de un** dominio. La salida crítica es la lista de **tablas, RPCs y cálculos que cruzan la frontera**: son el precio exacto de partir la plataforma, y también el argumento para no partirla. Esto **no requiere A1**: la frontera se deduce de qué módulo toca qué tabla, y eso está en el código.
  - Criterio de completitud: toda tabla hallada en las migraciones tiene ficha y dominio; toda tabla compartida entre dominios está identificada. El capítulo se cierra con la marca **inferido — pendiente de verificación en Etapa B** y con la lista de lo que solo la base puede responder (volúmenes, tablas efectivamente vivas, RLS real).

- [ ] **T-09** — C3: Inventario de RPCs *(RF-04)*
  - Archivos a crear/modificar: `analisis/03-modelo-datos.md`, `analisis/inventarios/rpcs.csv`
  - Contenido: por RPC — nombre, firma, propósito, si muta datos, `security definer` sí/no, y llamadores localizados en el código.
  - **Alcance en Etapa A:** las ~269 declaraciones `CREATE [OR REPLACE] FUNCTION` de las migraciones se colapsan por nombre para deducir la **última definición** de cada RPC, que es la que presumiblemente está viva. Los llamadores sí son definitivos: salen de buscar cada nombre en `src/` y en las Edge Functions, y eso no necesita la base.
  - Criterio de completitud: toda RPC deducida tiene firma, propósito y al menos un llamador o la marca "sin llamador localizado" (insumo directo de T-10). La confirmación de qué RPCs existen realmente y con qué `security definer` se cierra en **T-33 (Etapa B)**.

- [ ] **T-10** — C5': Candidatos a datos muertos, por ausencia de uso en el código *(RF-05)* · **P2**
  - Archivos a crear/modificar: `analisis/04-datos-muertos.md`
  - **Alcance en Etapa A:** la mitad del trabajo que **sí** se puede hacer sin la base — cruzar el inventario de T-08/T-09 contra todas las referencias en `src/` y en las 46 Edge Functions, para producir la lista de tablas, columnas y RPCs **que nadie invoca desde el código**. También las duplicidades evidentes en el historial de migraciones (tablas creadas y sustituidas, RPCs redefinidas con otro nombre).
  - Criterio de completitud: lista con nivel de confianza por ítem (*sin referencia en código* / *sospechoso* / *no concluyente*). **Ninguno se declara "muerto" en esta etapa:** una tabla sin referencia en el front puede estar escribiéndose desde un trigger, un cron o a mano. Afirmar el desuso requiere la base, y eso es **T-34 (Etapa B)** — que es exactamente por qué esta tarea sola no cierra el capítulo.

- [ ] **T-11** — C4: Catálogo de las 46 Edge Functions *(RF-06)*
  - Archivos a crear/modificar: `analisis/05-edge-functions.md`, `analisis/inventarios/edge-functions.csv`
  - Contenido: por función — propósito, tipo de disparo (UI / cron / webhook público), servicios externos que consume, secretos que requiere (referenciados por nombre, nunca transcritos — RNF-03), si muta datos, y portabilidad a .NET 8.
  - Criterio de completitud: 46 de 46 documentadas; los webhooks públicos y los cron quedan identificados explícitamente, porque son la superficie de ataque y el punto ciego de operación que alimentan C11 y C14.

- [ ] **T-12** — C5: Inventario de integraciones externas *(RF-07)*
  - Archivos a crear/modificar: `analisis/06-integraciones-externas.md`
  - Contenido: Anthropic, Groq, Resend, Twilio, mindicador.cl, open.er-api.com, Google (auth y calendario), Sentry y Vercel. Por cada una: uso, criticidad, dónde vive la llave, modelo de costo e implicación de moverla a .NET.
  - Criterio de completitud: ninguna llamada de prueba ejecutada contra servicios de pago (restricción del PRD §10); toda llave referenciada por nombre y ubicación.

- [ ] **T-13** — C6: Consumo real de SIGA por importación de Excel *(RF-08)*
  - Archivos a crear/modificar: `analisis/07-uso-de-siga.md`
  - Contenido: flujo real de `ImportarAverias.tsx` / `parseAverias.ts` y `ImportarContratos.tsx` / `parseContratos.ts` — columnas consumidas, encabezado en fila 3, transformaciones, validaciones, tabla destino del upsert, frecuencia y responsable de la carga.
  - Criterio de completitud: deja constancia explícita de que **hoy no hay consumo por API** (ninguna llamada HTTP a un host de SIGA en `src/` ni en las 46 Edge Functions), verificada de nuevo sobre el commit fijado. Alimenta directamente la matriz de T-36 (Etapa B).

- [ ] **T-14** — C8: Mapa exacto de uso de Realtime *(RF-10)*
  - Archivos a crear/modificar: `analisis/09-mapa-realtime.md`
  - Contenido: los 11 canales ya localizados en §1.1, cada uno con tabla o evento escuchado, tipo (`postgres_changes` / `broadcast`), consumidor, latencia requerida y veredicto: necesario o sustituible por refresco por consulta.
  - Criterio de completitud: 11 de 11 con veredicto. La latencia requerida se valida con la operación (War Room y call center), no se supone — es lo que define si la respuesta correcta es SignalR, polling o conservar Supabase Realtime.

- [ ] **T-15** — C9: Anatomía de la PWA y del offline *(RF-11)*
  - Archivos a crear/modificar: `analisis/10-pwa-y-offline.md`
  - Contenido: configuración de `vite-plugin-pwa` (`registerType: autoUpdate`, manifest, service worker, assets), vistas del sistema que reutiliza, alcance real del offline, almacenamiento local (`src/lib/idbStore.ts`, `visitaOffline.ts`, `miDiaCache.ts`, `bitacoraTerreno.ts`) y sincronización (`useColaVisitas.ts`, `visitaBorradorServidor.ts`).
  - Criterio de completitud: cuantifica el **grado de acoplamiento** con el sistema web y qué costaría desacoplarla. Sin ese número, C17 no puede comparar las tres opciones de PWA.

> **PUERTA 1 — Inventario completo y validado.** Antes de pasar a Fase 2: los 24 módulos, las 46 funciones, los 11 canales y el modelo de datos tienen ficha o declaración de no cobertura. Si hay huecos, se vuelve a Fase 1. No se juzga la calidad de lo que no está inventariado.

### Fase 2 — Análisis de calidad y riesgos (03-09 → 08-09)

- [ ] **T-16** — C10: Evaluación de arquitectura, patrones y buenas prácticas *(RF-12)*
  - Archivos a crear/modificar: `analisis/11-arquitectura-y-patrones.md`
  - Contenido: organización por features, separación de capas, patrones efectivamente usados (hooks, stores, repositorios de datos, el dominio en `postventa/dominio`, parsers puros), consistencia, duplicación, acoplamientos, tamaño de archivos y componentes, tipado y manejo de estado.
  - Criterio de completitud: cada juicio con al menos un ejemplo concreto citado (archivo y línea), y **ejemplos tanto de aciertos como de problemas** — un dictamen que solo lista defectos no es evaluación, es acusación, y pierde al interlocutor que más conoce el sistema (riesgo declarado en el PRD §13).

- [ ] **T-17** — C11: Auditoría de seguridad *(RF-13)*
  - Archivos a crear/modificar: `analisis/12-seguridad.md`, `analisis/hallazgos.md`
  - Contenido: uso de `anon key` vs `service_role`, secretos en Edge Functions, endpoints públicos (portal cliente, webhooks de WhatsApp), exposición y tratamiento de datos personales, esquema de roles/permisos frente al estándar de Engine (`rules/coding-guidelines.md` §6 y §11), y las **políticas RLS tal como están declaradas en las migraciones**, con las tablas que nunca reciben una política.
  - **Alcance en Etapa A:** todo lo anterior es auditable desde el código, y es donde vive la mayoría de los hallazgos serios — una llave mal usada, un webhook sin verificar o un secreto en el lugar equivocado se ven leyendo. Lo que **no** se puede afirmar sin la base es si RLS está *efectivamente activo* en cada tabla y si las políticas reales coinciden con las declaradas: eso es **T-32 (Etapa B)**.
  - Criterio de completitud: hallazgos con severidad y evidencia; las conclusiones de RLS marcadas como *declaradas, no verificadas*. **Una vulnerabilidad activa se escala a TI en el momento de detectarla, sin esperar al documento final** (acuerdo del PRD §13) — y esto aplica desde el día 1, no al cierre de la etapa.

- [ ] **T-18** — C12: Auditoría de rendimiento y escalabilidad *(RF-14)* · **P2**
  - Archivos a crear/modificar: `analisis/13-rendimiento-escalabilidad.md`, `analisis/hallazgos.md`
  - Contenido: tamaño de bundle y estrategia de `manualChunks` (incluida la regla de Recharts en chunk único, que rompe **solo en producción** si se altera, y la regla `react-vendor`), consultas pesadas, el tope de 1000 filas de PostgREST, volumen y costo de Realtime, y comportamiento ante el crecimiento de datos y usuarios.
  - Criterio de completitud: análisis estático y de lectura. **Sin pruebas de carga contra producción** (fuera de alcance, PRD §6).

- [ ] **T-19** — C13: Diagnóstico de testing, CI/CD y proceso *(RF-15)* · **P2**
  - Archivos a crear/modificar: `analisis/14-testing-cicd-proceso.md`
  - Contenido: qué cubren realmente los 65 archivos de test y qué queda sin cobertura frente a lo crítico; el pipeline `.github/workflows/ci.yml` (lint + test + build en push y PR a `master`, Node 22) y qué **no** valida; dependencia de Vercel para preview y deploy; flujo de ramas; y gobierno de migraciones — los duplicados históricos de numeración, la red de contención `src/lib/migracionesUnicas.test.ts` y el generador `npm run migracion`.
  - Criterio de completitud: parte del hecho verificado de que **el pipeline existe** (corrige la duda del PRD) y evalúa su cobertura, no su existencia. Contrasta el flujo real (rama → PR a `master`) contra el modelo de ramas de Engine (`develop`/`pre-qa`/`qa`/`main`).

- [ ] **T-20** — C14: Diagnóstico de observabilidad y operación *(RF-16)* · **P2**
  - Archivos a crear/modificar: `analisis/15-observabilidad-operacion.md`
  - Contenido: Sentry y qué captura realmente, logs de Edge Functions, alertas, tareas cron y su monitoreo, fallos silenciosos y procedimiento actual ante incidentes.
  - Criterio de completitud: los cron identificados en T-11 quedan cruzados con su monitoreo — un cron sin alarma es un fallo silencioso, y es el tipo de hallazgo que solo aparece si se cruzan los dos capítulos.

- [ ] **T-21** — Consolidar el registro de hallazgos priorizados *(RNF-09)*
  - Archivos a crear/modificar: `analisis/hallazgos.md`
  - Contenido: registro único con dimensión, severidad, descripción, evidencia (archivo/línea o consulta), impacto y recomendación, ordenado por severidad según el criterio publicado en T-04.
  - Criterio de completitud: 100% de los hallazgos con evidencia citada; ninguno sin severidad; los no verificables marcados como supuesto (RF-23).

### Fase 3 — Escenarios, pros/contras y dictamen preliminar (09-09 → 14-09)

- [ ] ~~**T-22**~~ — **trasladada a la Etapa B como T-36** (auditoría de la API de SIGA y matriz de cobertura). Requiere A3, y además necesita la lista de campos que produce T-13 para que la pregunta a SIGA sea útil. Ver §1.4.
  - Lo que **sí** queda en la Etapa A: T-13 documenta qué campos entran hoy por Excel y deja preparada la **columna vacía** de la matriz (*dato requerido → endpoint que lo cubriría*). Cuando llegue A3, T-36 solo rellena la segunda columna.

- [ ] **T-23** — C15: Supabase vs. .NET 8, servicio por servicio *(RF-17)*
  - Archivos a crear/modificar: `analisis/16-supabase-vs-net8.md`
  - Contenido: tabla por los cinco servicios (Postgres+RLS, Auth, Storage, Edge Functions, Realtime) con qué aporta hoy, sustituto en .NET 8, esfuerzo, riesgo y veredicto de convivencia. Incluye obligatoriamente **SignalR frente a Supabase Realtime** e **Identity frente a Supabase Auth**.
  - **Añadido: ¿qué alberga Supabase, por dominio?** Responder la pregunta de la Dirección con números, no con adjetivos: qué proporción de tablas, filas, invocaciones de Edge Function y mensajes de Realtime corresponde al dominio comercial y qué proporción al operativo (§1.3). Es lo que convierte E4 de intuición en escenario evaluable — y si el reparto resulta ser 90/10, el dictamen se escribe solo.
  - **Alcance en Etapa A:** el reparto se estima por **estructura** — cuántas tablas, RPCs y Edge Functions hay a cada lado de la frontera, y de qué lado están los 11 canales de Realtime (que ya se sabe: War Room, call center y postventa). Eso alcanza para una hipótesis con forma. El reparto por **peso** —filas, invocaciones, mensajes, costo— exige A1 y A2, y se cierra en **T-35 (Etapa B)**.
  - **Añadido: qué haría falta exactamente para tener ese tiempo real en .NET.** No basta con "SignalR". Se dimensiona la pieza completa: servicio SignalR en ECS + Fargate, **backplane** (Redis o Azure SignalR) porque con más de una instancia detrás del ALB los grupos no se comparten solos, afinidad de sesión en el ALB, la reescritura del lado cliente de los 11 canales, y quién publica los eventos que hoy emite Postgres solo (`postgres_changes` no tiene equivalente gratuito: hay que emitirlos a mano desde la capa .NET). Con su costo mensual estimado y su riesgo operativo.
  - Criterio de completitud: los cinco servicios con veredicto, el reparto por dominio cuantificado (o declarado no cuantificable si falta A2), y el costo de reponer el tiempo real dimensionado en infraestructura y en desarrollo. Es el capítulo central: debe prevenir el error de subestimar lo que Supabase resuelve sin costo de desarrollo (riesgo declarado en el PRD §13). Aplica RNF-10 — el veredicto "no conviene sustituirlo" es un resultado válido.

- [ ] **T-24** — C16: Comparación de los **cinco** escenarios y esfuerzo en rangos *(RF-18, RF-20)*
  - Archivos a crear/modificar: `analisis/17-escenarios-destino.md`
  - Contenido: **E0** (conservar stack + refactor incremental con gobierno en TI), **E1** (React actual + back .NET 8 API), **E2** (todo .NET 8 + Razor), **E3** (híbrido .NET 8 conservando el tiempo real) y **E4 — retención parcial por dominio** (Supabase conserva el dominio comercial / seguimiento de vendedores; el dominio de operación de garantías se absorbe en .NET o en SIGA — ver §1.3). Los cinco con criterios idénticos: esfuerzo en rangos gruesos, riesgo, encaje con el estándar de TI, impacto operativo, costo de plataforma y mantenibilidad.
  - **E4 se evalúa con dos preguntas propias**, respondidas desde T-07 y T-08: (a) ¿cuántas tablas, RPCs y cálculos cruzan la frontera entre dominios, y qué costaría desacoplarlos? (b) ¿qué parte del costo de plataforma se ahorra realmente, si el dominio que se queda es el que consume el tiempo real? Si el corte resulta imposible o el ahorro marginal, **E4 se descarta con evidencia** — que es un resultado igual de útil.
  - Criterio de completitud: los cinco con la misma rejilla, y **E0 explícitamente como línea base** contra la que se mide el beneficio neto de los otros cuatro. El criterio de estimación queda declarado con sus supuestos (RF-20). Si no hubo acceso a los paneles de costo (A2), la dimensión de costo se marca como no cuantificada en los cinco por igual — nunca estimada en unos y en blanco en otros.

- [ ] **T-25** — C17: Evaluación de las tres opciones de PWA *(RF-19)*
  - Archivos a crear/modificar: `analisis/18-opciones-pwa.md`
  - Contenido: mismo proyecto reutilizando vistas / proyecto o app separada consumiendo la misma API / app nativa o híbrida. Cada una con pros, contras, esfuerzo y riesgo, contrastada contra lo que hoy resuelve el offline de terreno (medido en T-15).
  - Criterio de completitud: las tres con dictamen. Se apoya en el grado de acoplamiento de T-15; si faltan los datos de uso real (cuántos asesores la usan, qué tan crítico es el offline), la comparación se declara cualitativa en lugar de fingir cuantificación.

- [ ] **T-26** — C18: Dictamen **preliminar** y recomendación argumentada *(RF-21)*
  - Archivos a crear/modificar: `analisis/19-dictamen.md`
  - Contenido: recomendación explícita (refactorizar, rehacer, migrar por partes o **partir la plataforma por dominio**), qué tecnología conservar y cuál abandonar, en qué orden, qué debe decidirse antes de arrancar y qué riesgos deben aceptarse explícitamente.
  - **Preliminar, y dicho en su primera línea.** El dictamen de la Etapa A se emite sobre evidencia de código y migraciones, que es suficiente para recomendar pero no para cerrar. Debe declarar **qué conclusiones concretas podrían cambiar** al verificar en Etapa B — típicamente las que dependen de volúmenes, de costo o de RLS real. El dictamen definitivo es **T-38**.
  - Criterio de completitud: la recomendación se deriva paso a paso del árbol de decisión publicado en la §7.3 del PRD, citando en cada bifurcación el hallazgo que la resuelve. Trazabilidad de decisiones (RNF-06): cada juicio con su razón, para que pueda auditarse o rebatirse.
  - **Ajuste al árbol del PRD:** su §7.3 pregunta *"¿Supabase es sustituible a costo razonable?"* como un sí/no. Con E4 sobre la mesa la respuesta admite un tercer valor —*"en parte"*— así que el árbol se republica con esa rama añadida al **inicio de Fase 3**, antes de aplicarlo. El PRD publica su árbol antes de conocer los resultados a propósito; retocarlo después sería exactamente lo que esa regla previene.

### Fase 4 — Resumen ejecutivo, revisión y cierre de la Etapa A (15-09 → 17-09) · **PUERTA 2**

- [ ] **T-27** — C19: Resumen ejecutivo para Dirección *(RF-22)*
  - Archivos a crear/modificar: `analisis/20-resumen-ejecutivo.md`
  - Contenido: documento corto derivado de todo lo anterior — hallazgos críticos, escenarios y recomendación, sin detalle técnico.
  - Criterio de completitud: comprensible para Dirección sin conocimiento del stack (RNF-08), sin contradecir ninguna cifra de los capítulos técnicos.

- [ ] **T-28** — Re-verificación de vigencia y cobertura declarada *(RNF-11, RNF-14)*
  - Archivos a crear/modificar: `analisis/README.md`, `analisis/preguntas-abiertas.md`
  - Acción: comparar el commit fijado en T-01 contra `origin/master` al cierre, listar los cambios relevantes ocurridos durante la ventana, y declarar explícitamente qué se revisó y qué no (módulos, tablas o funciones no alcanzados).
  - Criterio de completitud: nadie puede asumir exhaustividad donde no la hubo. El sistema estuvo en desarrollo activo durante el análisis — la línea base ya se movió 29 commits en 13 días antes de arrancar, así que este cierre no es un trámite.

- [ ] **T-29** — Revisión con la Dirección de TI y cierre de preguntas *(PUERTA 2)*
  - Archivos a crear/modificar: todos los capítulos con ajustes; `analisis/preguntas-abiertas.md`
  - Acción: sesión de revisión con Aldo Álvarez; registrar las dudas o vacíos que detecte y cerrarlos antes de dar el documento por final.
  - Criterio de completitud: la revisión está **dentro** del alcance, no es un paso posterior opcional — es la mitigación del riesgo "que el resultado no derive en decisión". Las preguntas de la revisión quedan contadas (es una métrica de éxito del PRD).

- [ ] **T-30** — Publicación final y confidencialidad *(RNF-12, RF-24)*
  - Archivos a crear/modificar: `analisis/README.md`; PR de `feature/PJ3896-garantimax-analisis-tecnico` → `main`
  - Acción: cerrar versiones y fechas de cada documento, verificar que **ningún secreto, llave ni dato personal quedó transcrito** (RNF-03, RNF-04), y abrir el PR para la revisión formal.
  - Criterio de completitud: el PR lo abre el programador, nunca Claude Code (`rules/version-control.md` §5). Difusión limitada a TI y Dirección. Ver la decisión de §12 sobre no publicar este documento en el repositorio de GarantiMAX. **El PR de la Etapa A se marca como entrega parcial**, con la lista de capítulos pendientes de verificación en Etapa B.

---

## 4-B. Etapa B — Supabase y API de SIGA

> **Esta etapa no tiene fechas: arranca cuando lleguen los accesos** (A1 para la Fase 5, A3 para la Fase 6), y las dos fases son independientes entre sí — si llega A3 antes que A1, se arranca por la Fase 6.
>
> **Su entregable es verificación, no descubrimiento.** Cada tarea toma un capítulo que la Etapa A dejó marcado como *inferido* y lo cierra con la fuente autoritativa, dejando constancia de **en qué se equivocaba la inferencia** — porque esa diferencia es, en sí misma, un hallazgo sobre el gobierno del sistema: mide cuánto se ha desviado la base real de sus migraciones.

### Fase 5 — Supabase verificado: modelo de datos, RLS y consumo *(requiere A1; T-35 requiere además A2)*

- [ ] **T-31** — Verificar el modelo de datos contra el catálogo real *(cierra T-08 / RF-04)*
  - Archivos a modificar: `analisis/03-modelo-datos.md`, `analisis/inventarios/tablas.csv`
  - Acción: leer `information_schema` y `pg_catalog` y contrastar contra el esquema reconstruido en T-08 — tablas que existen y no estaban, tablas inferidas que ya no existen, columnas y relaciones divergentes. Añadir el **volumen de filas** por tabla.
  - Criterio de completitud: cada tabla del catálogo real tiene ficha con volumen; las divergencias contra lo inferido están listadas una por una. Se retira la marca *inferido* del capítulo.

- [ ] **T-32** — Auditoría de RLS real por tabla *(cierra la parte diferida de T-17 / RF-13)*
  - Archivos a modificar: `analisis/12-seguridad.md`, `analisis/hallazgos.md`
  - Acción: leer `pg_policies` y el estado de `rowsecurity` por tabla, y contrastar contra las políticas declaradas en las migraciones. Identificar **tablas con RLS desactivado**, políticas más permisivas de lo que aparentan y tablas sin ninguna política.
  - Criterio de completitud: veredicto de RLS por tabla, con severidad. Es la tarea de mayor valor de seguridad de todo el plan: una tabla sin RLS con la `anon key` circulando en el navegador es un hallazgo crítico, y **no hay forma de detectarlo leyendo el repositorio**. Vulnerabilidad activa → escalamiento inmediato a TI.

- [ ] **T-33** — RPCs vivas, firmas reales y `security definer` *(cierra T-09 / RF-04)*
  - Archivos a modificar: `analisis/03-modelo-datos.md`, `analisis/inventarios/rpcs.csv`
  - Acción: leer `pg_proc` / `pg_get_functiondef` y contrastar contra las RPCs deducidas en T-09 — qué existe de verdad, con qué firma, y cuáles corren con `security definer` (que es lo que permite saltarse RLS).
  - Criterio de completitud: toda RPC viva con firma y `security definer` confirmados; las RPCs `security definer` **sin control de permisos propio** se reportan como hallazgo de seguridad.

- [ ] **T-34** — Datos muertos confirmados *(cierra T-10 / RF-05)*
  - Archivos a modificar: `analisis/04-datos-muertos.md`
  - Acción: cruzar los candidatos de T-10 (*sin referencia en código*) contra la base — volumen de filas, fecha del registro más reciente y existencia de triggers o crons que escriban en ellos. Solo entonces se declara el desuso.
  - Criterio de completitud: cada candidato pasa a *confirmado sin uso*, *en uso por vía no evidente* o *no concluyente*. Aquí un falso positivo cuesta más que un hueco: es la lista que decidirá qué no se migra.

- [ ] **T-35** — Consumo y costo por dominio *(cierra la parte diferida de T-23 / RF-17, RF-20)*
  - Archivos a modificar: `analisis/16-supabase-vs-net8.md`, `analisis/17-escenarios-destino.md`
  - Acción: cuantificar el reparto entre dominio comercial y operativo en filas, invocaciones de Edge Functions, mensajes y conexiones de Realtime, Storage y egreso; y cruzarlo con el costo mensual real de A2.
  - Criterio de completitud: la pregunta *"¿qué alberga Supabase y cuánto cuesta cada mitad?"* queda respondida con cifras y fuente. Si A2 no llega pero sí A1, se entrega el reparto de **consumo** sin el de costo, declarando el hueco.

### Fase 6 — API de SIGA, E4 y dictamen definitivo *(requiere A3; T-37 requiere la Fase 5)*

- [ ] **T-36** — Auditoría de la API de SIGA y matriz de cobertura *(era T-22 / C7, RF-09)*
  - Archivos a crear/modificar: `analisis/08-api-siga-cobertura.md`
  - Acción: sobre la lista de campos que T-13 documentó como consumidos hoy por Excel, rellenar la matriz **dato requerido → endpoint que lo cubre / no existe**, campo por campo. Cerrar con la lista de endpoints que habría que construir y con la respuesta del equipo de SIGA sobre si pueden construirse.
  - Criterio de completitud: cada campo con veredicto. **No se desarrolla ningún endpoint** (fuera de alcance, PRD §6). El resultado tiene consecuencia directa: si la API no cubre lo que entra por Excel, **todo escenario de migración arrastra la dependencia manual o suma un proyecto no contemplado** — y eso cambia la comparación de T-24.

- [ ] **T-37** — Resolver E4 con evidencia *(cierra §1.3 / RF-18)*
  - Archivos a modificar: `analisis/17-escenarios-destino.md`
  - Acción: con la frontera de dominios de la Etapa A, los volúmenes y el costo de T-35 y la cobertura de SIGA de T-36, dictaminar si partir la plataforma por dominio es viable y conveniente: qué cuesta desacoplar lo que cruza la frontera, cuánto costo se ahorra de verdad y qué queda peor que hoy.
  - Criterio de completitud: **E4 con veredicto — a favor o en contra, ambos con evidencia.** Descartarlo con la lista exacta de costuras que lo impiden es un resultado igual de útil que aprobarlo; lo inaceptable sería dejarlo en "habría que ver".

- [ ] **T-38** — Dictamen definitivo y resumen ejecutivo actualizado *(cierra T-26, T-27 / RF-21, RF-22)*
  - Archivos a modificar: `analisis/19-dictamen.md`, `analisis/20-resumen-ejecutivo.md`, `analisis/README.md`
  - Acción: reemplazar el dictamen preliminar por el definitivo, dejando **constancia de qué cambió respecto del preliminar y por qué** — que es la prueba de que la verificación valió la pena. Retirar todas las marcas de *inferido*, actualizar la cobertura declarada (RNF-11) y re-fijar el commit de vigencia (RNF-14), que a estas alturas se habrá movido otra vez.
  - Criterio de completitud: ningún capítulo queda marcado como pendiente de verificación, o los que quedan lo declaran con su causa. Segunda revisión con la Dirección de TI si el dictamen cambió de recomendación respecto del preliminar.

---

## 5. Cambios en base de datos

**Ninguno.** El análisis es de solo lectura (RNF-01).

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | — | No se crean, modifican ni eliminan tablas, columnas, índices, RPCs ni políticas RLS. |

**Lecturas requeridas sobre la base de GarantiMAX** (`jrykbalmnpymeyzdhsam`), todas con usuario de solo lectura. **Todas pertenecen a la Etapa B** — la Etapa A no toca la base en absoluto:

| Fuente | Para qué | Tarea |
|---|---|---|
| `information_schema` / `pg_catalog` | Tablas, columnas, claves y relaciones reales | T-31 |
| `pg_policies` + `rowsecurity` | Políticas RLS por tabla y si RLS está activo | T-32 |
| `pg_proc` / `pg_get_functiondef` | Firmas de RPCs y `security definer` | T-33 |
| Conteos y fecha del último registro por tabla | Volúmenes, y confirmar el desuso | T-31, T-34 |
| Métricas de consumo (Edge Functions, Realtime, Storage) | Reparto por dominio y costo | T-35 |

> **Queda bloqueado sin autorización explícita de TI:** cualquier `INSERT`/`UPDATE`/`DELETE`/DDL, ejecutar Edge Functions que muten datos o consuman servicios de pago, pruebas de carga contra producción, y extraer datos personales o secretos fuera del entorno. Si en algún momento el análisis pareciera requerir una escritura, se detiene y se pide autorización — no se resuelve por criterio propio.

---

## 6. Endpoints nuevos o modificados

**Ninguno.** Este proyecto no construye ni modifica APIs.

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| — | — | La API de SIGA se **audita documentalmente** en T-36 (Etapa B); construir endpoints está explícitamente fuera de alcance (PRD §6). | — |

---

## 7. Variables de entorno y configuración

**No se introducen variables de entorno**: el entregable es documentación, no software desplegable.

Lo que sí se requiere son **accesos de solo lectura**, que se gestionan como credenciales del analista y **nunca se transcriben en la documentación** (RNF-03) — se referencian por nombre y ubicación:

| Acceso | Descripción | Ambiente | Estado |
|---|---|---|---|
| Usuario de lectura en Supabase | Catálogo, RLS, RPCs y conteos del proyecto `jrykbalmnpymeyzdhsam` | Producción (solo lectura) | ❌ Por confirmar (T-02) |
| Repositorio / Swagger de la API de SIGA | Auditoría de cobertura | Documental | ❌ Por confirmar (T-02) |
| Panel de Vercel | Modelo de despliegue, tráfico y costo | Producción | ❌ Por confirmar (T-02) |
| Panel de Supabase (facturación) | Costo, invocaciones de Edge Functions, consumo de Realtime | Producción | ❌ Por confirmar (T-02) |
| Panel de Sentry | Qué se captura y con qué cobertura | Producción | ❌ Por confirmar (T-02) |
| Repositorio `garantiplus-dashboard` | Fuente primaria del análisis | Local | ✅ Confirmado |
| Repositorio `enginecx_prd` | Destino del entregable | Local + remoto | ✅ Confirmado |

> Las variables `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` y `VITE_SENTRY_DSN` del sistema analizado **se documentan** (en C1 y C11) pero no se usan ni se replican. La `service_role` no se solicita: el análisis no la necesita y pedirla ampliaría la superficie de riesgo sin beneficio.

---

## 8. Consideraciones de seguridad

- **Permisos IAM / AWS:** ninguno nuevo. El sistema analizado no vive en AWS (Vercel + Supabase), así que no hay cambios en consolas de Engine.
- **Políticas de autorización:** ninguna nueva. Las existentes se **auditan** en T-17 contra el estándar de Engine (`rules/coding-guidelines.md` §6).
- **Mínimo privilegio para el propio análisis:** solo lectura en la base, sin `service_role`, sin acceso de escritura a ningún panel. Si un capítulo parece exigir más privilegio, se registra como pregunta abierta en lugar de escalar el acceso.
- **Secretos:** ninguno se transcribe en la documentación (RNF-03). Se referencian por nombre y ubicación — por ejemplo "secreto `RESEND_API_KEY`, definido en las variables de la Edge Function X", nunca su valor. Esto aplica igual a los inventarios en `analisis/inventarios/`, que se revisan antes de commitear.
- **Datos personales:** los ejemplos se anonimizan (RNF-04). No se extraen ni copian fuera de la base datos de clientes, asesores o talleres. Los conteos por tabla son agregados, no muestras de filas.
- **El entregable es material sensible.** Expone arquitectura, integraciones y debilidades de seguridad de un sistema productivo (RNF-12). Vive en `enginecx_prd` (repositorio interno de la organización) con difusión limitada a TI y Dirección. Es la razón técnica por la que **no** se publica en el repositorio de GarantiMAX — ver §12.
- **Vulnerabilidad activa detectada durante la auditoría:** se escala a TI de inmediato, sin esperar al documento final, y sin publicar el detalle en un canal abierto. El protocolo se fija en T-04, antes de empezar a buscar.

---

## 9. Consideraciones de infraestructura

**Ningún servicio AWS nuevo. Ningún cambio en ECS, RDS, S3, Cloudflare ni Route 53. Costo de infraestructura del proyecto: cero.**

Lo relevante en infraestructura es que **GarantiMAX vive fuera de las seis consolas AWS de Engine**: hosting en Vercel, backend completo en Supabase. Eso significa que:

- No hay monitoreo de facturación de Engine sobre él, y AWS no aplica porque no está ahí. El techo de gasto real es desconocido (pregunta abierta del PRD).
- El análisis debe documentar **el modelo** de costo y sus factores de riesgo (invocaciones de Edge Functions, consumo de Realtime, tráfico, filas), aunque no obtenga la cifra.
- Cualquier escenario de migración (E1/E2/E3) implica dimensionar recursos nuevos en la consola AWS correspondiente al Hub Sur — que hoy no está definida en `rules/infraestructura.md` para Chile/Perú/Argentina más allá de Garanti Chile (`sa-east-1`). **Es un hueco de infraestructura que T-24 debe registrar**: no se puede estimar el costo de destino sin saber en qué consola y región aterriza.

---

## 10. Criterios de aceptación

> Los criterios se cumplen en dos cortes: al cierre de la **Etapa A** (marcados **A**) y al cierre de la **Etapa B** (marcados **B**). Un criterio **B** no cuenta como incumplimiento mientras la Etapa B no haya arrancado — cuenta como pendiente declarado.

**Etapa A — cierre del análisis técnico del proyecto**

- [ ] **A** · Los 19 capítulos (C1–C19) están entregados como archivos `.md` versionados con diagramas mermaid e índice navegable (RF-24), o declarados explícitamente como no alcanzados con su razón (RNF-11). C7 se entrega como estructura vacía a la espera de A3.
- [ ] **A** · Cada capítulo que depende de la base lleva la marca visible **inferido — pendiente de verificación en Etapa B**, y el dictamen preliminar declara en su primera línea qué conclusiones podrían cambiar.
- [ ] **A** · El modelo de datos está reconstruido desde las 364 migraciones, con la lista explícita de lo que solo la base puede responder.
- [ ] **A** · Los 24 módulos y las tablas están **segmentados por dominio**, con la lista de lo que cruza la frontera (insumo de E4).
- [ ] **A** · Los **24 módulos** tienen ficha con propósito, reglas de negocio, tablas/RPCs que tocan, criticidad y **ubicación de la lógica** (front / RPC / Edge Function).
- [ ] **A** · Las **46 Edge Functions** están catalogadas, con sus cron y sus webhooks públicos identificados.
- [ ] **A** · Los **11 canales de Realtime** tienen veredicto individual: necesario o sustituible por refresco.
- [ ] **A** · Está documentado el flujo real de importación de Excel de SIGA, con la **lista de campos consumidos** y la matriz de cobertura preparada con su segunda columna vacía.
- [ ] **A** · Las **tres opciones de PWA** están evaluadas con pros, contras, esfuerzo y riesgo.
- [ ] **A** · Los **cinco escenarios E0–E4** están evaluados con criterios idénticos y esfuerzo en rangos, con E0 funcionando como línea base.
- [ ] **A** · Los cinco servicios de Supabase tienen veredicto de sustitución/convivencia, incluidos SignalR vs. Realtime e Identity vs. Auth.
- [ ] **A** · **Está dimensionado qué haría falta para reponer el tiempo real en .NET**: servicio SignalR, backplane, afinidad de sesión, quién emite los eventos que hoy emite Postgres, y la reescritura de los 11 canales — con costo y riesgo, no solo con el nombre de la tecnología.
- [ ] **A** · El dictamen **preliminar** recomienda explícitamente un camino, derivado del árbol de decisión de la §7.3 del PRD (republicado con la rama de E4), con los riesgos que se aceptan.
- [ ] **A** · El resumen ejecutivo es comprensible para Dirección sin conocimiento del stack.
- [ ] **A** · **100% de hallazgos y afirmaciones con evidencia citada**; lo no verificable declarado como supuesto (RF-23, RNF-02).
- [ ] **A** · Todos los hallazgos tienen severidad asignada según el criterio publicado en T-04 (RNF-09).
- [ ] **A** · El commit y la fecha del código analizado están declarados, y los cambios ocurridos durante la ventana registrados (RNF-14).
- [ ] **A** · Ningún secreto, llave, cadena de conexión ni dato personal quedó transcrito en el entregable (RNF-03, RNF-04).
- [ ] **A** · El sistema analizado quedó **intacto**: sin commits, sin escrituras en la base, sin cambios de configuración (RNF-01).
- [ ] **A** · La revisión con la Dirección de TI se realizó y sus preguntas quedaron cerradas o registradas (PUERTA 2).
- [ ] **A** · **Prueba de independencia del autor original (RNF-13):** un desarrollador .NET de Engine sin contacto previo con el proyecto logra explicar el flujo de un módulo crítico y ubicar dónde vive su lógica usando solo la documentación. Es el criterio que mide si la Etapa A sirvió — y **no depende de la Etapa B**.

**Etapa B — cierre de la verificación y de la decisión**

- [ ] **B** · El modelo de datos está inventariado **contra el catálogo real**, con volúmenes por tabla y la lista de divergencias respecto de lo inferido.
- [ ] **B** · Hay **veredicto de RLS real por tabla**, incluidas las tablas con RLS desactivado y las políticas más permisivas de lo que aparentan, con severidad.
- [ ] **B** · Las RPCs vivas están confirmadas con firma y `security definer`; las `security definer` sin control de permisos propio están reportadas como hallazgo.
- [ ] **B** · Los datos muertos están **confirmados** (no solo sospechados por ausencia de referencia en código).
- [ ] **B** · **Está respondido qué alberga Supabase por dominio**, con el reparto de tablas, filas, invocaciones de Edge Function y mensajes de Realtime entre lo comercial y lo operativo, y el costo de cada mitad (o declarado no cuantificable si faltó A2).
- [ ] **B** · La **matriz de cobertura de la API de SIGA** está completa campo por campo, con la lista de endpoints que habría que construir.
- [ ] **B** · **E4 tiene veredicto sostenido en evidencia** — a favor o en contra, ambos válidos; lo inaceptable es dejarlo en "habría que ver".
- [ ] **B** · El **dictamen definitivo** reemplaza al preliminar, dejando constancia de qué cambió y por qué. No queda ningún capítulo marcado como *inferido*, o los que queden lo declaran con su causa.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| ~~El alcance completo no cabe en la ventana~~ — **mitigado dos veces**: primero extendiendo el calendario (de 10 a 22 días hábiles), luego partiendo el plan en dos etapas | — | — | **Cerrado el 24-08-2026 por decisión de la Dirección.** La Etapa A cierra entre el 09-09 y el 17-09 y no depende de accesos pendientes; la Etapa B queda sin fecha por diseño (§1.4). Las prioridades P1/P2/P3 quedan solo como palanca de reserva. |
| **El corte por dominio de E4 resulta inviable** porque los dominios comparten tablas, RPCs o cálculos | Media | Medio | No es un fracaso del análisis sino su resultado: E4 se descarta con la lista exacta de costuras que lo impiden (T-08), que además es el mejor argumento disponible para no partir la plataforma. El riesgo real sería *no medirlo* y descartarlo por intuición. |
| **Subestimar el costo de reponer el tiempo real en .NET** — creer que "SignalR" es la respuesta completa | Media | Alto | `postgres_changes` no tiene equivalente gratuito: hoy Postgres emite los eventos solo, y en .NET hay que emitirlos a mano. T-23 dimensiona la pieza entera (servicio, backplane, afinidad de sesión, reescritura de los 11 canales, quién publica los eventos), no solo la tecnología. |
| **La copia local estaba 29 commits atrás** al generar el plan (`de6ce01` vs `3771e7f`) — el supuesto del PRD "el repositorio local está actualizado" es falso | Confirmado | Medio | T-01 sincroniza y fija el commit antes de cualquier lectura. Cifras del PRD v0.1 ya corregidas en §1.1. |
| **El sistema sigue en desarrollo activo** durante el análisis — se movió 29 commits en 13 días, y la ventana ahora es más larga (hasta el 22-09) | Alta | Medio | Es la contrapartida de extender el calendario: más días son más deriva. Commit fijado y declarado (RNF-14); T-28 re-verifica al cierre y lista los cambios del período. Pregunta abierta que ahora pesa más: ¿se congela el desarrollo durante la ventana, o al menos se avisa de los cambios estructurales? |
| **Que la Etapa B nunca arranque** porque A1/A3 no llegan y la Etapa A "ya se ve completa" | **Alta** | **Alto** | Es el riesgo dominante del plan reestructurado. Quedarían sin responder las tres cosas que cierran la decisión: RLS real, costo por dominio y cobertura de la API de SIGA. Mitigación: dictamen rotulado **preliminar** en su primera línea, marca *inferido* visible en cada capítulo afectado, PR de la Etapa A como **entrega parcial**, y fecha de compromiso —aunque tentativa— para A1 y A3 desde ahora. |
| **No obtener acceso de lectura a Supabase (A1)** | Media | Alto | Ya no bloquea el arranque: la Etapa A reconstruye el esquema desde las 364 migraciones y lo marca como inferido. Lo que se pierde si nunca llega es la verificación (T-31), **el veredicto de RLS real (T-32) —el hallazgo de seguridad de mayor severidad potencial del análisis—** y la confirmación de datos muertos (T-34). |
| **No obtener acceso a los paneles de costo (A2)** | Alta | Alto | Uno de los dos drivers del proyecto queda sin cifras — y con E4 en juego, también el criterio que decide si conviene partir la plataforma por dominio. Mitigación: documentar el modelo de costo y sus factores; en T-24 la dimensión de costo se marca como no cuantificada **en los cinco escenarios por igual**, para no sesgar la comparación. |
| **La API de SIGA no cubre lo que hoy entra por Excel** | Media | Alto | Cualquier escenario de migración arrastra la dependencia manual o suma un proyecto de construcción de endpoints no contemplado. T-36 lo deja explícito en la matriz; el dictamen lo asume como riesgo aceptado si no hay acceso. |
| **Lógica de negocio crítica no documentada ni evidente en el código** (cierres, comisiones, siniestralidad, proyecciones) | Media | Alto | Podría perderse en una re-escritura. T-07 la verifica con Fabrizio Álvarez y con el mantenedor actual, y marca como supuesto lo no confirmado. |
| **Subestimar lo que Supabase resuelve sin costo de desarrollo** (RLS, Auth, Storage, Realtime, serverless) | Media | Alto | Es precisamente lo que T-23 debe prevenir: cinco servicios evaluados por separado, no "Supabase" como bloque. |
| **Sesgo hacia el estándar corporativo** — concluir "hay que rehacerlo en .NET" por homogeneidad y no por evidencia | Media | Alto | Criterios publicados antes de los resultados (T-04 y el árbol de la §7.3 del PRD), neutralidad tecnológica (RNF-10), y **E0 evaluado formalmente** para que cualquier migración tenga que justificarse contra no migrar. |
| **Detectar una vulnerabilidad activa durante la auditoría** | Media | Alto | Protocolo de escalamiento inmediato fijado en T-04, antes de empezar a buscar. Se reporta a TI al detectarla, sin desviar el foco ni esperar al documento final. |
| **Baja disponibilidad de los interlocutores** en la ventana de dos semanas | Media | Medio | Las consultas se agrupan y se envían temprano (T-02); lo no validado se marca como supuesto en lugar de bloquear. |
| **Que el análisis se lea como juicio al autor del sistema** | Media | Medio | T-16 exige ejemplos de aciertos y no solo de defectos; el documento evalúa decisiones técnicas y su contexto, no personas. |
| **Que el resultado no derive en decisión** y quede archivado | Media | Alto | PUERTA 2 (T-29) es parte del alcance, con fecha. Si la migración ya está decidida por política, conviene saberlo antes (prerequisito de §2) para no producir un documento que nadie va a usar. |
| **Fuga de información sensible en el propio entregable** (secreto o dato personal transcrito por descuido) | Baja | Alto | RNF-03/RNF-04 desde T-04; revisión explícita de secretos y PII en T-30 antes del PR; los archivos de `inventarios/` se revisan igual que los capítulos. |
| **Ninguno de los dos repositorios sigue el modelo de ramas de Engine** (no hay `develop`) | Confirmado | Bajo | Documentado en §12. Para el entregable se usa rama funcional + PR a `main`, que preserva la puerta de revisión. Para el sistema analizado es un hallazgo de T-19, no un problema de este plan. |

---

## 12. Notas para el programador

**1. Dónde vive el entregable — y por qué no en el repo de GarantiMAX.**
El PRD deja abierta la pregunta de si el documento se publica solo en `enginecx_prd` o también dentro del repositorio de GarantiMAX. Este plan la resuelve a favor de **solo `enginecx_prd`**, por una razón de seguridad y no de comodidad: el entregable expone debilidades de seguridad de un sistema productivo (RNF-12), y el repositorio principal de GarantiMAX está en una **cuenta personal de GitHub** (`fabriziolag/garantiplus-dashboard`) cuya transferencia a la organización nunca se concretó. Publicar ahí una auditoría de seguridad amplía la superficie de exposición justo en el punto que el propio PRD marca como pregunta abierta de propiedad del código. **Confirmar con Aldo Álvarez** — si TI decide que también debe vivir en el repo del sistema, conviene que sea después de regularizar la propiedad.

**2. Ninguno de los dos repositorios tiene `develop`.**
> ⚠️ No existe rama `develop` ni en `garantiplus-dashboard` ni en `enginecx_prd`. El plan se generó desde `main` (en `enginecx_prd`, único repositorio donde se escribe). Se recomienda crear `develop` antes de continuar con el flujo estándar de Engine.

Detalle relevante: `garantiplus-dashboard` no tiene `develop` **ni `main`** — su rama de integración es `master`, y su flujo propio (documentado en su `CLAUDE.md`) es rama de trabajo → PR a `master` → deploy en Vercel. No sigue el modelo `develop`/`pre-qa`/`qa`/`main` de `rules/version-control.md`. Como este plan no escribe una sola línea en ese repositorio, la divergencia no bloquea nada aquí — **es un hallazgo que T-19 debe documentar**, no un obstáculo del plan.

En `enginecx_prd` se usa rama funcional + PR a `main` en lugar de commit directo, aunque el repositorio solo tenga `main`: cumple la prohibición de commits directos a `main` (`rules/version-control.md` §7) y, más importante, le da a la PUERTA 2 un lugar natural donde ocurrir. La excepción es el commit de este `PLAN.md`, que va directo a `main` por convención del flujo de Engine para planes.

**3. El PLAN corrige cuatro cifras, una duda y un supuesto del PRD.** No es un detalle cosmético: las estimaciones de §13 salen de los números reales, no de los del PRD v0.1. Ver §1.1 — migraciones (355 → **364**), archivos (455 → **464**), tests (60 → **65**), LOC (~109k → **113 587**). El pipeline de CI **existe** (`.github/workflows/ci.yml`), contra la duda planteada en C13. Y el supuesto "el repositorio local está actualizado" era falso: 29 commits de desfase (nota siguiente y T-01). Lo que sí se confirmó exacto: 46 Edge Functions, 24 módulos y los 11 canales de Realtime en los archivos precisos que el PRD nombra — el baseline de C8 está verificado al 100% y T-14 arranca con el trabajo de localización hecho.

**4. El `CLAUDE.md` del sistema analizado está desactualizado.** Afirma que la última migración es `0128_cobertura_incentivos.sql` cuando ya existen migraciones en el rango `0350`, y describe rutas de macOS (`/Users/fabrizioalvarez/DASHBOARD`) para un repositorio que hoy se trabaja en Windows. También afirma que `origin` tiene dos push URLs (cuenta personal + organización), pero **esta copia local tiene una sola**, apuntando a `garantiplusmexico`. Nada de esto se corrige desde este plan (el análisis no toca el sistema, RNF-01), pero **es material para C13/T-19**: la documentación de arranque del proyecto es una de las cosas que se degradó, y es exactamente el síntoma que motivó este PRD.

**5. La decisión NO está tomada — y eso define el trabajo, no lo relaja.**
Confirmado por la Dirección el 24-08-2026: no hay una migración decidida por política. El propósito del análisis es **determinar** el destino, así que los cinco escenarios se evalúan con criterios idénticos y sin favorito (RNF-10). Tres consecuencias prácticas:

- **E0 y E4 son candidatos reales, no trámites.** "Que se quede donde está" y "que se quede solo con lo suyo" son resultados admisibles. Cualquier migración tiene que ganarle a los dos.
- **La pregunta central es "¿qué alberga Supabase?", y se responde con números.** Si el 90% de lo que vive ahí es seguimiento comercial de vendedores —algo que no existe en SIGA ni en ningún sistema de Engine— entonces migrarlo es construir de cero algo que ya funciona, y el dictamen se escribe casi solo. Si en cambio está lleno de contratos y averías que SIGA ya modela, la conclusión se invierte. **Ese reparto es el dato que decide el proyecto**, y hoy nadie lo tiene: es lo que T-23 debe producir.
- **El tiempo real es la pieza que más se subestima.** Los 11 canales de Realtime están concentrados en War Room, call center y el chat de postventa (§1.1) — precisamente el dominio comercial y de atención. Reponerlos en .NET no es "usar SignalR": es un servicio en ECS, un backplane porque con más de una instancia los grupos no se comparten solos, afinidad de sesión en el ALB, reescribir los 11 canales del lado cliente y —lo que casi siempre se olvida— **alguien que emita los eventos que hoy Postgres emite solo**. `postgres_changes` no tiene equivalente gratuito del otro lado. T-23 lo dimensiona completo, con costo y riesgo.

Lo que sí conviene levantar temprano es la **latencia que la operación exige de verdad** en War Room y call center. Es el dato que separa "necesitamos tiempo real" de "un refresco cada 10 segundos alcanza", y de él depende que la respuesta sea SignalR, polling o conservar Supabase. Está en A6 (§2.1) por eso.

**6. Lo que este plan deliberadamente no hace.** No escribe código, no refactoriza, no automatiza la importación de SIGA, no construye endpoints, no diseña la arquitectura destino, no hace pruebas de carga y no toma la decisión. Todo eso está fuera de alcance por el PRD §6, y la tentación de "aprovechar el viaje" para arreglar algo que se encuentre al paso es la vía más rápida a consumir el calendario extendido. Los arreglos detectados se registran como hallazgos con recomendación; ejecutarlos es el PRD posterior.

Una matización sobre el costo de plataforma: el PRD lo declara fuera de alcance cuantitativo *porque no había acceso a los paneles*. No es una exclusión de principio. Si A2 (§2.1) llega, la cifra entra en T-23 y T-24 — y conviene que entre, porque con E4 sobre la mesa el reparto del costo entre dominios pasó de ser un dato interesante a ser un criterio de decisión.

**7. Por qué el plan se partió en dos etapas (24-08-2026).**
Decisión de la Dirección: en lugar de esperar bloqueado el `.env` de Supabase y la fuente de la API de SIGA, se levanta primero todo lo técnico del proyecto desde el repositorio (**Etapa A**, arranca hoy) y se aparta la verificación de plataforma a una **Etapa B** sin fecha, que arranca cuando lleguen los accesos. Cuatro consecuencias que conviene tener presentes:

- **La mayor parte del análisis no dependía de esos accesos.** De 20 capítulos, 12 se cierran completos en la Etapa A y solo 1 (C7, la API de SIGA) no puede ni empezarse. Los otros 7 se entregan inferidos y se verifican después.
- **El orden resultó ser el correcto, no solo el posible.** Preguntarle a la API de SIGA *"¿cubres estos 40 campos concretos?"* —con la lista que produce T-13 leyendo los parsers— vale mucho más que preguntarle *"¿qué tienes?"*. La Etapa B necesita el resultado de la Etapa A para que la auditoría sirva.
- **Cuesta 3–4 días más en total** (18–26 frente a 15–22): es el retrabajo de reabrir capítulos para cambiar lo inferido por lo verificado. Precio consciente por arrancar hoy.
- **Reconstruir el esquema desde 364 migraciones es una fuente legítima, no un parche.** Da tablas, columnas, relaciones y políticas declaradas. Lo que no da es lo que se cambió a mano fuera de las migraciones, los volúmenes reales y si RLS está efectivamente activo — y esa última es justamente la que puede esconder el hallazgo más grave.

**8. Estrategia sugerida para sostener el ritmo.** El inventario (Fase 1) es la parte más mecánica y la más paralelizable: T-07 (módulos), T-08/T-09 (modelo de datos) y T-11 (Edge Functions) no dependen entre sí. Es donde un segundo recurso rinde más y donde la extracción automatizada de T-05 más ahorra. Fases 2 y 3, en cambio, son de juicio y no se paralelizan bien: partirlas entre dos personas produce dos criterios distintos, que es justo lo que RNF-07 y RNF-09 buscan evitar.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | Ventana (límite alto) | ID (BD) |
|---|---|---|---|---|---|
| **ETAPA A — El proyecto por dentro** *(arranca hoy, solo repositorio)* | | | | | |
| **Fase 0 — Habilitación, línea base y método** | Commit fijado (RNF-14), accesos A1–A6 pedidos o escalados, esqueleto de 21 documentos, metodología y escala de severidad publicadas, inventarios automatizados | T-01 a T-05 | 1 – 2 días | 24-08 → 25-08 | `186` |
| **Fase 1 — Inventario y mapeo** | C1 ficha tecnológica, C2 los 24 módulos + ubicación de la lógica **+ segmentación por dominio**, C3 modelo de datos **inferido de las 364 migraciones** + tablas que cruzan la frontera, C5' candidatos a datos muertos, C4 las 46 Edge Functions, C5 integraciones, C6 uso real de SIGA por Excel, C8 los 11 canales, C9 PWA y offline · **PUERTA 1** | T-06 a T-15 | 4 – 6 días | 26-08 → 02-09 | `187` |
| **Fase 2 — Análisis de calidad y riesgos** | C10 arquitectura y patrones, C11 seguridad **a nivel de código** (RLS declarado), C12 rendimiento, C13 testing/CI-CD, C14 observabilidad, registro de hallazgos priorizados | T-16 a T-21 | 3 – 4 días | 03-09 → 08-09 | `188` |
| **Fase 3 — Escenarios y dictamen preliminar** | C15 Supabase vs .NET 8 por servicio + reparto por **estructura** + costo de reponer el tiempo real, C16 los cinco escenarios E0–E4, C17 las tres opciones de PWA, C18 **dictamen preliminar** | T-23 a T-26 | 3 – 4 días | 09-09 → 14-09 | `189` |
| **Fase 4 — Resumen ejecutivo, revisión y cierre de Etapa A** | C19 resumen ejecutivo, re-verificación de vigencia y cobertura declarada, revisión con Dirección (**PUERTA 2**), publicación como entrega parcial | T-27 a T-30 | 2 – 3 días | 15-09 → 17-09 | `190` |
| **Subtotal Etapa A** | 12 capítulos cerrados + 7 a medias | **29 tareas** | **~13 – 19 días hábiles** | **09-09 → 17-09-2026** | — |
| **ETAPA B — La plataforma** *(sin fecha: arranca al recibir los accesos)* | | | | | |
| **Fase 5 — Supabase verificado** *(requiere A1; T-35 requiere A2)* | Modelo de datos contra el catálogo real, **RLS real por tabla**, RPCs vivas y `security definer`, datos muertos confirmados, consumo y costo por dominio | T-31 a T-35 | 3 – 4 días | — | `191` |
| **Fase 6 — API de SIGA, E4 y dictamen definitivo** *(requiere A3)* | C7 matriz de cobertura campo por campo, E4 resuelto con evidencia, **dictamen definitivo** y resumen ejecutivo actualizado | T-36 a T-38 | 2 – 3 días | — | `192` |
| **Subtotal Etapa B** | Cierra los 7 capítulos a medias + C7 | **8 tareas** | **~5 – 7 días hábiles** | — | — |
| **TOTAL PROYECTO** | 20 capítulos | **37 tareas** | **~18 – 26 días hábiles** | Etapa A al 17-09; Etapa B según accesos | — |

> **Notas sobre la tabla:**
> - **El plan se partió en dos etapas el 24-08-2026** para no quedar bloqueado esperando el `.env` de Supabase y la fuente de la API de SIGA (§1.4). La Etapa A arranca hoy con lo que hay; la Etapa B queda armada y a la espera.
> - La columna **Ventana** proyecta el límite alto de cada rango desde el 24-08-2026, contando solo días hábiles y en secuencia. Si los rangos salen por el extremo bajo, la Etapa A cierra el **miércoles 09-09**; por el extremo alto, el **jueves 17-09**. La Etapa B **no tiene ventana** a propósito: depende de cuándo lleguen A1 y A3, no de nuestra capacidad.
> - **El total sube de 15–22 a 18–26 días** respecto de la versión de una sola etapa. Los 3–4 días de diferencia son el retrabajo de reabrir capítulos para reemplazar lo inferido por lo verificado. Es el precio de arrancar hoy, y está declarado en lugar de escondido.
> - **Fase 1 baja de 5–7 a 4–6 días** y **Fase 2 de 3–5 a 3–4**, porque parte de T-08/T-09/T-10/T-17 se aparta a la Etapa B. **Fase 3 baja de 4–5 a 3–4** porque T-22 sale completa. Nada de eso es alcance perdido: es alcance movido.
> - Las prioridades P1/P2/P3 (§1.2) ya no gobiernan el alcance: ordenan el trabajo dentro de cada fase y quedan como palanca de reserva.
> - Los rangos salen del volumen medido en §1.1. Los mayores consumidores siguen siendo T-07 (24 fichas con evidencia y dominio) y T-08/T-09 (reconstruir el esquema desde 364 migraciones y colapsar ~269 declaraciones de función).
> - La duración en BD por fase redondea el **límite superior** del rango (2+6+4+4+3 en Etapa A, 4+3 en Etapa B = **26**), que es el valor del campo `dias` del plan.
> - **Las dos fases de la Etapa B son independientes.** Si llega A3 antes que A1, se arranca por la Fase 6; el único orden obligado es que T-37 (resolver E4) necesita T-35, y T-38 necesita las dos fases.

> **El riesgo que gobierna ahora es la Etapa B, no el calendario.**
>
> La Etapa A está financiada: tiene todo lo que necesita y cierra entre el 09-09 y el 17-09. Su entregable —análisis técnico completo del proyecto con dictamen preliminar— ya es útil por sí solo: permite que TI entienda y opere el sistema, que se conozca la deuda técnica y que se vea la forma de los cinco escenarios.
>
> Lo que **no** permite es cerrar la decisión, y conviene ser explícito sobre por qué. Tres conclusiones quedan fuera de alcance hasta la Etapa B:
> - **Si RLS está realmente activo en cada tabla** (T-32). Es el hallazgo de seguridad de mayor severidad potencial de todo el análisis, y no hay forma de verlo leyendo el repositorio: una tabla con RLS desactivado y la `anon key` circulando en el navegador es exposición directa de datos.
> - **Cuánto cuesta cada mitad de la plataforma** (T-35). Sin eso, E4 —que puede ser el escenario más barato— se queda en hipótesis, y el costo es uno de los dos motores del proyecto.
> - **Si la API de SIGA cubre lo que hoy entra por Excel** (T-36). Sin eso, no se sabe si migrar arrastra la dependencia manual o suma un proyecto entero de endpoints.
>
> Por eso el dictamen de la Etapa A se emite y se rotula **preliminar**, y por eso cada capítulo afectado lleva la marca *inferido — pendiente de verificación*. **El riesgo concreto es que la Etapa B nunca arranque** porque el `.env` no llega y la Etapa A "ya se ve completa". Recomendación: fijar desde ahora una fecha de compromiso para A1 y A3, aunque sea tentativa, y tratar la Etapa A como entrega parcial en el PR — nunca como cierre del PRD.

> **Calendario: extendido por decisión de la Dirección (24-08-2026).**
>
> El PRD fijaba la entrega el **viernes 04-09-2026**, lo que dejaba exactamente **10 días hábiles** desde el arranque real — cero holgura contra un alcance completo de 15 a 22 días. La Dirección resolvió **extender el calendario y ejecutar el alcance completo sin comprimirlo**, en lugar de recortar profundidad.
>
> **Nueva fecha de entrega: entre el viernes 11-09-2026 y el martes 22-09-2026**, según por dónde salgan los rangos. La desviación respecto del PRD v0.1 es de **+5 a +12 días hábiles** y queda documentada aquí como cambio de alcance temporal aceptado, no como incumplimiento (la métrica de éxito del PRD "cumplimiento de fechas de fase" se mide contra este calendario).
>
> Lo que cambia en la práctica:
> - **Ya no hay recorte planificado.** Los capítulos P2 (T-10 datos muertos, T-18 rendimiento, T-19 testing/CI-CD, T-20 observabilidad) se ejecutan con profundidad completa, no declarando cobertura parcial.
> - **La PUERTA 2 tiene aire propio.** T-29 ya no cae el mismo día de la entrega, así que las preguntas de la revisión de Dirección tienen dónde cerrarse — que era el problema estructural del cronograma original.
> - **Entra E4** (§1.3) con su costo en Fase 1 y Fase 3. Con el calendario anterior habría sido imposible; era, de hecho, el escenario que la compresión habría eliminado primero.
> - **Un segundo recurso deja de ser necesario**, aunque sigue siendo la palanca más eficaz si hiciera falta acelerar: Fase 1 es la paralelizable (T-07, T-08/T-09 y T-11 son independientes) y un segundo desarrollador ahí comprimiría esa fase un **35 – 40%** y el total un **20 – 25%**. No conviene extenderlo a Fases 2 y 3: son de juicio, y dos criterios distintos en la misma auditoría rompen RNF-07 y RNF-09.
>
> **El riesgo que queda vivo no es el calendario, son los accesos.** Cinco de los seis (A1–A6, §2.1) están sin confirmar, y A1 —lectura de la base— bloquea cuatro tareas de Fase 1. Extender el plazo no consigue los permisos: si A1 no llega en los primeros días, Fase 1 se ejecuta sobre inferencias y **T-10 pierde casi todo su valor**, con más calendario y el mismo hueco. A1 y A2 se piden el día 1 por eso.

---

*Generado por Claude Code — Engine CX*
*Modelo: `claude-opus-5` — esfuerzo: alto*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Línea base del sistema analizado: `garantiplus-dashboard` @ `3771e7f` (2026-08-19)*
