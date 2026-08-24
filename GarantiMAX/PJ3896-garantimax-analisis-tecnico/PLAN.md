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
| Responsable | Javier Antonio Oropeza Camacho |
| Folio PRD | `PJ3896` |
| Fecha de generación | 24-08-2026 |
| Estado | Borrador |
| ID plan (BD) | *(pm_plan_desarrollo.id — lo escribe el flujo al registrar el plan)* |
| Modelo / esfuerzo de generación | `claude-opus-5` — esfuerzo alto |

---

## 1. Resumen técnico

Este plan ejecuta un **análisis técnico de solo lectura** sobre GarantiMAX y produce **documentación en Markdown versionado con diagramas mermaid**. No crea ni modifica software, no escribe en la base y no altera configuración (RNF-01).

**Qué se crea:** 21 documentos `.md` (un archivo por capítulo C1–C19, más índice y metodología), un registro único de hallazgos priorizados, un registro de supuestos y preguntas abiertas, y una carpeta de inventarios extraídos de forma automatizada. Todo vive en `enginecx_prd/GarantiMAX/PJ3896-garantimax-analisis-tecnico/analisis/`.

**Qué se modifica:** nada del sistema analizado. La única escritura es documental, en el repositorio de PRDs.

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

| Cap. | Requerimientos | Tarea | Prioridad |
|---|---|---|---|
| C1 Ficha tecnológica | RF-01 | T-06 | P1 |
| C2 Mapa de módulos y lógica | RF-02, RF-03 | T-07 | P1 |
| C3 Modelo de datos | RF-04 | T-08, T-09 | P1 |
| C4 Catálogo Edge Functions | RF-06 | T-11 | P1 |
| C5 Integraciones externas | RF-07 | T-12 | P1 |
| C5' Datos muertos | RF-05 | T-10 | P2 |
| C6 Uso de SIGA (Excel) | RF-08 | T-13 | P1 |
| C7 Cobertura API de SIGA | RF-09 | T-22 | P3 (depende de acceso) |
| C8 Mapa de Realtime | RF-10 | T-14 | P1 |
| C9 PWA y offline | RF-11 | T-15 | P1 |
| C10 Arquitectura y patrones | RF-12 | T-16 | P1 |
| C11 Seguridad | RF-13 | T-17 | P1 |
| C12 Rendimiento y escalabilidad | RF-14 | T-18 | P2 |
| C13 Testing, CI/CD y proceso | RF-15 | T-19 | P2 |
| C14 Observabilidad y operación | RF-16 | T-20 | P2 |
| C15 Supabase vs .NET 8 | RF-17 | T-23 | P1 |
| C16 Escenarios E0–E3 | RF-18, RF-20 | T-24 | P1 |
| C17 Opciones de PWA | RF-19 | T-25 | P1 |
| C18 Dictamen | RF-21 | T-26 | P1 |
| C19 Resumen ejecutivo | RF-22 | T-27 | P1 |
| Transversal | RF-23, RF-24, RNF-01…14 | T-03, T-04, T-28, T-30 | P1 |

> La columna **Prioridad** no viene del PRD (que declara las tres fases como un único MVP). Se deriva aquí a partir del árbol de decisión de la §7.3 del PRD: **P1** es lo sin lo cual el dictamen no se sostiene, **P2** es profundidad que puede recortarse declarando cobertura (RNF-11), **P3** es lo que depende de un tercero. Es la palanca que hace ejecutable el recorte de la §13.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable
- [x] Acceso al repositorio analizado confirmado (`garantimax` local, remoto `garantiplusmexico/garantiplus-dashboard`)
- [x] Acceso al repositorio del entregable confirmado (`garantiplusmexico/enginecx_prd`, rama `main` al día)
- [x] `CLAUDE.md` presente en el repositorio analizado
- [ ] **Acceso de solo lectura a la base Supabase del proyecto** (`jrykbalmnpymeyzdhsam`) — sin esto, C3/C11 solo pueden inferirse de las 364 migraciones, con riesgo de describir tablas inexistentes y volúmenes equivocados. **Bloquea T-08, T-09, T-10 y parte de T-17.**
- [ ] **Fuente autoritativa de la API de SIGA** (repositorio, Swagger o documentación) y contacto responsable. **Bloquea T-22 (C7/RF-09).**
- [ ] **Muestras de los reportes Excel de SIGA** (averías ACTIVAS, averías CERRADAS, contratos). **Bloquea el detalle de T-13.**
- [ ] **Acceso a paneles de costo de Vercel y Supabase** — declarado fuera de alcance cuantitativo en el PRD §6; sin él, T-24 compara escenarios sin la dimensión de costo real.
- [ ] Disponibilidad confirmada de interlocutores: Fabrizio Álvarez, mantenedor actual, equipo de la API de SIGA.
- [ ] Respuesta a la pregunta abierta *"¿la migración al estándar ya está decidida por política?"* — si lo está, el escenario E0 es teatro y conviene saberlo antes de invertir días en evaluarlo.

> **Ninguno de los prerequisitos abiertos detiene el arranque.** Fase 0 y la mayor parte de Fase 1 corren con solo el repositorio. Lo que falte se registra como pregunta abierta (T-02) en lugar de rellenarse con una estimación inventada — es el patrón que el PRD fija en su §7.1.

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

## 4. Tareas de desarrollo

> Todas las tareas son de **lectura y redacción**. Ninguna modifica el sistema analizado (RNF-01).
> Todo hallazgo, cifra o afirmación cita su fuente: archivo y línea, consulta, configuración o interlocutor (RF-23).

### Fase 0 — Habilitación, línea base y método (21-08 → 25-08)

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

### Fase 1 — Inventario y mapeo (25-08 → 28-08) · **PUERTA 1 al cierre**

- [ ] **T-06** — C1: Ficha tecnológica con veredicto por dependencia *(RF-01)*
  - Archivos a crear/modificar: `analisis/01-ficha-tecnologica.md`
  - Contenido: cada dependencia relevante con versión real de `package.json`, para qué se usa, **dónde** (archivo), equivalente en el ecosistema .NET si existe, y veredicto: conservable / sustituible / riesgosa.
  - Criterio de completitud: ninguna dependencia relevante sin veredicto ni sin al menos una ubicación de uso citada.

- [ ] **T-07** — C2: Mapa de los 24 módulos y ubicación de la lógica de negocio *(RF-02, RF-03)*
  - Archivos a crear/modificar: `analisis/02-mapa-modulos.md`
  - Contenido: una ficha por módulo (los 24 listados en §1.1): propósito, pantallas, reglas de negocio, tablas y RPCs que toca, dependencias con otros módulos, criticidad operativa, y **dónde vive la lógica** (front / RPC de Postgres / Edge Function).
  - Criterio de completitud: 24 fichas, ninguna vacía; la criticidad operativa validada con Fabrizio Álvarez y marcada como tal. RF-03 es el dato que define el costo real de migrar el backend — si una ficha no lo resuelve, la ficha no está lista.

- [ ] **T-08** — C3: Inventario de tablas, RLS, relaciones y volúmenes *(RF-04)*
  - Archivos a crear/modificar: `analisis/03-modelo-datos.md`, `analisis/inventarios/tablas.csv`
  - Contenido: todas las tablas con propósito, dominio, claves y relaciones, volumen de filas, política RLS asociada, y módulos que la leen y escriben. Diagramas ER por dominio en mermaid.
  - Punto de partida: ~152 `CREATE TABLE` en el historial de migraciones — el número vivo se confirma contra el catálogo real.
  - Criterio de completitud: cada tabla del catálogo real aparece o queda declarada como no alcanzada (RNF-11). **Depende del acceso de lectura a Supabase.**

- [ ] **T-09** — C3: Inventario de RPCs *(RF-04)*
  - Archivos a crear/modificar: `analisis/03-modelo-datos.md`, `analisis/inventarios/rpcs.csv`
  - Contenido: por RPC — nombre, firma, propósito, si muta datos, `security definer` sí/no, y llamadores localizados en el código.
  - Punto de partida: ~269 declaraciones `CREATE [OR REPLACE] FUNCTION` en migraciones; el número de RPCs vivas será menor por los reemplazos.
  - Criterio de completitud: toda RPC viva tiene firma, propósito y al menos un llamador o la marca explícita "sin llamador localizado" (insumo directo de T-10).

- [ ] **T-10** — C5': Detección de datos muertos *(RF-05)* · **P2**
  - Archivos a crear/modificar: `analisis/04-datos-muertos.md`
  - Contenido: tablas, columnas y RPCs sin uso, y duplicidades, cruzando el historial de las 364 migraciones contra el catálogo real y contra los llamadores hallados en T-07/T-09.
  - Criterio de completitud: lista con nivel de confianza por ítem (confirmado sin uso / sospechoso / no concluyente). Es insumo para no arrastrar basura a un sistema nuevo, así que un falso positivo cuesta más que un hueco: lo dudoso se marca dudoso.

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
  - Criterio de completitud: deja constancia explícita de que **hoy no hay consumo por API** (ninguna llamada HTTP a un host de SIGA en `src/` ni en las 46 Edge Functions), verificada de nuevo sobre el commit fijado. Alimenta directamente la matriz de T-22.

- [ ] **T-14** — C8: Mapa exacto de uso de Realtime *(RF-10)*
  - Archivos a crear/modificar: `analisis/09-mapa-realtime.md`
  - Contenido: los 11 canales ya localizados en §1.1, cada uno con tabla o evento escuchado, tipo (`postgres_changes` / `broadcast`), consumidor, latencia requerida y veredicto: necesario o sustituible por refresco por consulta.
  - Criterio de completitud: 11 de 11 con veredicto. La latencia requerida se valida con la operación (War Room y call center), no se supone — es lo que define si la respuesta correcta es SignalR, polling o conservar Supabase Realtime.

- [ ] **T-15** — C9: Anatomía de la PWA y del offline *(RF-11)*
  - Archivos a crear/modificar: `analisis/10-pwa-y-offline.md`
  - Contenido: configuración de `vite-plugin-pwa` (`registerType: autoUpdate`, manifest, service worker, assets), vistas del sistema que reutiliza, alcance real del offline, almacenamiento local (`src/lib/idbStore.ts`, `visitaOffline.ts`, `miDiaCache.ts`, `bitacoraTerreno.ts`) y sincronización (`useColaVisitas.ts`, `visitaBorradorServidor.ts`).
  - Criterio de completitud: cuantifica el **grado de acoplamiento** con el sistema web y qué costaría desacoplarla. Sin ese número, C17 no puede comparar las tres opciones de PWA.

> **PUERTA 1 — Inventario completo y validado.** Antes de pasar a Fase 2: los 24 módulos, las 46 funciones, los 11 canales y el modelo de datos tienen ficha o declaración de no cobertura. Si hay huecos, se vuelve a Fase 1. No se juzga la calidad de lo que no está inventariado.

### Fase 2 — Análisis de calidad y riesgos (28-08 → 01-09)

- [ ] **T-16** — C10: Evaluación de arquitectura, patrones y buenas prácticas *(RF-12)*
  - Archivos a crear/modificar: `analisis/11-arquitectura-y-patrones.md`
  - Contenido: organización por features, separación de capas, patrones efectivamente usados (hooks, stores, repositorios de datos, el dominio en `postventa/dominio`, parsers puros), consistencia, duplicación, acoplamientos, tamaño de archivos y componentes, tipado y manejo de estado.
  - Criterio de completitud: cada juicio con al menos un ejemplo concreto citado (archivo y línea), y **ejemplos tanto de aciertos como de problemas** — un dictamen que solo lista defectos no es evaluación, es acusación, y pierde al interlocutor que más conoce el sistema (riesgo declarado en el PRD §13).

- [ ] **T-17** — C11: Auditoría de seguridad *(RF-13)*
  - Archivos a crear/modificar: `analisis/12-seguridad.md`, `analisis/hallazgos.md`
  - Contenido: políticas RLS por tabla y huecos, uso de `anon key` vs `service_role`, secretos en Edge Functions, endpoints públicos (portal cliente, webhooks de WhatsApp), exposición y tratamiento de datos personales, y esquema de roles/permisos frente al estándar de Engine (`rules/coding-guidelines.md` §6 y §11).
  - Criterio de completitud: hallazgos con severidad y evidencia. **Una vulnerabilidad activa se escala a TI en el momento de detectarla, sin esperar al documento final** (acuerdo del PRD §13).

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

### Fase 3 — Escenarios, pros/contras y dictamen (01-09 → 03-09)

- [ ] **T-22** — C7: Auditoría de la API de SIGA y matriz de cobertura *(RF-09)* · **P3 — depende de acceso**
  - Archivos a crear/modificar: `analisis/08-api-siga-cobertura.md`
  - Contenido: matriz **dato requerido → endpoint que lo cubre / no existe**, campo por campo, derivada de los campos que T-13 documentó como consumidos hoy por Excel. Más la lista de endpoints que habría que construir.
  - Criterio de completitud: cada campo con veredicto. **No se desarrolla ningún endpoint** (fuera de alcance). Si el acceso no llega, el capítulo se cierra declarando el hueco y su dueño — y el dictamen asume que cualquier escenario de migración arrastra la dependencia manual.

- [ ] **T-23** — C15: Supabase vs. .NET 8, servicio por servicio *(RF-17)*
  - Archivos a crear/modificar: `analisis/16-supabase-vs-net8.md`
  - Contenido: tabla por los cinco servicios (Postgres+RLS, Auth, Storage, Edge Functions, Realtime) con qué aporta hoy, sustituto en .NET 8, esfuerzo, riesgo y veredicto de convivencia. Incluye obligatoriamente **SignalR frente a Supabase Realtime** e **Identity frente a Supabase Auth**.
  - Criterio de completitud: los cinco con veredicto. Es el capítulo central: debe prevenir el error de subestimar lo que Supabase resuelve sin costo de desarrollo (riesgo declarado en el PRD §13). Aplica RNF-10 — el veredicto "no conviene sustituirlo" es un resultado válido.

- [ ] **T-24** — C16: Comparación de los cuatro escenarios y esfuerzo en rangos *(RF-18, RF-20)*
  - Archivos a crear/modificar: `analisis/17-escenarios-destino.md`
  - Contenido: **E0** (conservar stack + refactor incremental con gobierno en TI), **E1** (React actual + back .NET 8 API), **E2** (todo .NET 8 + Razor), **E3** (híbrido .NET 8 conservando el tiempo real), evaluados con criterios idénticos: esfuerzo en rangos gruesos, riesgo, encaje con el estándar de TI, impacto operativo, costo de plataforma y mantenibilidad.
  - Criterio de completitud: los cuatro con la misma rejilla, y **E0 explícitamente como línea base** contra la que se mide el beneficio neto de las otras tres. El criterio de estimación queda declarado con sus supuestos (RF-20). Si no hubo acceso a los paneles de costo, la dimensión de costo se marca como no cuantificada en los cuatro por igual — nunca estimada en unos y en blanco en otros.

- [ ] **T-25** — C17: Evaluación de las tres opciones de PWA *(RF-19)*
  - Archivos a crear/modificar: `analisis/18-opciones-pwa.md`
  - Contenido: mismo proyecto reutilizando vistas / proyecto o app separada consumiendo la misma API / app nativa o híbrida. Cada una con pros, contras, esfuerzo y riesgo, contrastada contra lo que hoy resuelve el offline de terreno (medido en T-15).
  - Criterio de completitud: las tres con dictamen. Se apoya en el grado de acoplamiento de T-15; si faltan los datos de uso real (cuántos asesores la usan, qué tan crítico es el offline), la comparación se declara cualitativa en lugar de fingir cuantificación.

- [ ] **T-26** — C18: Dictamen y recomendación argumentada *(RF-21)*
  - Archivos a crear/modificar: `analisis/19-dictamen.md`
  - Contenido: recomendación explícita (refactorizar, rehacer o migrar por partes), qué tecnología conservar y cuál abandonar, en qué orden, qué debe decidirse antes de arrancar y qué riesgos deben aceptarse explícitamente.
  - Criterio de completitud: la recomendación se deriva paso a paso del árbol de decisión publicado en la §7.3 del PRD, citando en cada bifurcación el hallazgo que la resuelve. Trazabilidad de decisiones (RNF-06): cada juicio con su razón, para que pueda auditarse o rebatirse.

### Fase 4 — Resumen ejecutivo, revisión y cierre (03-09 → 04-09) · **PUERTA 2**

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
  - Criterio de completitud: el PR lo abre el programador, nunca Claude Code (`rules/version-control.md` §5). Difusión limitada a TI y Dirección. Ver la decisión de §12 sobre no publicar este documento en el repositorio de GarantiMAX.

---

## 5. Cambios en base de datos

**Ninguno.** El análisis es de solo lectura (RNF-01).

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | — | No se crean, modifican ni eliminan tablas, columnas, índices, RPCs ni políticas RLS. |

**Lecturas requeridas sobre la base de GarantiMAX** (`jrykbalmnpymeyzdhsam`), todas con usuario de solo lectura:

| Fuente | Para qué | Tarea |
|---|---|---|
| `information_schema` / `pg_catalog` | Tablas, columnas, claves y relaciones reales | T-08 |
| `pg_policies` | Políticas RLS por tabla | T-08, T-17 |
| `pg_proc` / `pg_get_functiondef` | Firmas de RPCs y `security definer` | T-09, T-17 |
| Conteos por tabla | Volúmenes para dimensionar y detectar datos muertos | T-08, T-10 |

> **Queda bloqueado sin autorización explícita de TI:** cualquier `INSERT`/`UPDATE`/`DELETE`/DDL, ejecutar Edge Functions que muten datos o consuman servicios de pago, pruebas de carga contra producción, y extraer datos personales o secretos fuera del entorno. Si en algún momento el análisis pareciera requerir una escritura, se detiene y se pide autorización — no se resuelve por criterio propio.

---

## 6. Endpoints nuevos o modificados

**Ninguno.** Este proyecto no construye ni modifica APIs.

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| — | — | La API de SIGA se **audita documentalmente** en T-22; construir endpoints está explícitamente fuera de alcance (PRD §6). | — |

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

- [ ] Los 19 capítulos (C1–C19) están entregados como archivos `.md` versionados con diagramas mermaid e índice navegable (RF-24), o declarados explícitamente como no alcanzados con su razón (RNF-11).
- [ ] Los **24 módulos** tienen ficha con propósito, reglas de negocio, tablas/RPCs que tocan, criticidad y **ubicación de la lógica** (front / RPC / Edge Function).
- [ ] Las **46 Edge Functions** están catalogadas, con sus cron y sus webhooks públicos identificados.
- [ ] Los **11 canales de Realtime** tienen veredicto individual: necesario o sustituible por refresco.
- [ ] El modelo de datos está inventariado contra el catálogo real (no solo inferido de las 364 migraciones), con RLS por tabla — o el hueco está declarado con su causa.
- [ ] Los **cuatro escenarios E0–E3** están evaluados con criterios idénticos y esfuerzo en rangos, con E0 funcionando como línea base.
- [ ] Las **tres opciones de PWA** están evaluadas con pros, contras, esfuerzo y riesgo.
- [ ] Los cinco servicios de Supabase tienen veredicto de sustitución/convivencia, incluidos SignalR vs. Realtime e Identity vs. Auth.
- [ ] El dictamen recomienda explícitamente refactor, re-escritura o migración por partes, derivado del árbol de decisión de la §7.3 del PRD, con los riesgos que se aceptan.
- [ ] El resumen ejecutivo es comprensible para Dirección sin conocimiento del stack.
- [ ] **100% de hallazgos y afirmaciones con evidencia citada**; lo no verificable declarado como supuesto (RF-23, RNF-02).
- [ ] Todos los hallazgos tienen severidad asignada según el criterio publicado en T-04 (RNF-09).
- [ ] El commit y la fecha del código analizado están declarados, y los cambios ocurridos durante la ventana registrados (RNF-14).
- [ ] Ningún secreto, llave, cadena de conexión ni dato personal quedó transcrito en el entregable (RNF-03, RNF-04).
- [ ] El sistema analizado quedó **intacto**: sin commits, sin escrituras en la base, sin cambios de configuración (RNF-01).
- [ ] La revisión con la Dirección de TI se realizó y sus preguntas quedaron cerradas o registradas (PUERTA 2).
- [ ] **Prueba de independencia del autor original (RNF-13):** un desarrollador .NET de Engine sin contacto previo con el proyecto logra explicar el flujo de un módulo crítico y ubicar dónde vive su lógica usando solo la documentación.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **El alcance completo no cabe en la ventana** — 19 capítulos, 24 módulos, 364 migraciones, 46 funciones, ~152 tablas y 113 587 líneas en **10 días hábiles** con un recurso | Alta | Alto | Es el riesgo dominante. Prioridades P1/P2/P3 de §1.2, profundidad completa solo en P1, cobertura declarada en el resto (RNF-11). Ver la nota de deadline de §13 y la opción de un segundo recurso. |
| **La copia local estaba 29 commits atrás** al generar el plan (`de6ce01` vs `3771e7f`) — el supuesto del PRD "el repositorio local está actualizado" es falso | Confirmado | Medio | T-01 sincroniza y fija el commit antes de cualquier lectura. Cifras del PRD v0.1 ya corregidas en §1.1. |
| **El sistema sigue en desarrollo activo** durante el análisis — se movió 29 commits en 13 días | Alta | Medio | Commit fijado y declarado (RNF-14); T-28 re-verifica al cierre y lista los cambios del período. Pregunta abierta: ¿se congela el desarrollo durante la ventana? |
| **No obtener acceso de lectura a Supabase** | Media | Alto | El modelo de datos se inferiría solo de las migraciones, con riesgo de describir tablas que ya no existen y volúmenes equivocados. T-02 lo escala el día 1; si no llega, T-08/T-09/T-10 se marcan como inferidos, no verificados. |
| **No obtener acceso a los paneles de costo** | Alta | Alto | Uno de los dos drivers del proyecto queda sin cifras. Mitigación: documentar el modelo de costo y sus factores; en T-24 la dimensión de costo se marca como no cuantificada **en los cuatro escenarios por igual**, para no sesgar la comparación. |
| **La API de SIGA no cubre lo que hoy entra por Excel** | Media | Alto | Cualquier escenario de migración arrastra la dependencia manual o suma un proyecto de construcción de endpoints no contemplado. T-22 lo deja explícito en la matriz; el dictamen lo asume como riesgo aceptado si no hay acceso. |
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

**3. El PLAN corrige tres cifras y un supuesto del PRD.** No es un detalle cosmético: las estimaciones de §13 salen de los números reales, no de los del PRD v0.1. Ver §1.1 — migraciones (355 → **364**), archivos (455 → **464**), tests (60 → **65**), LOC (~109k → **113 587**). Y el pipeline de CI **existe** (`.github/workflows/ci.yml`), contra la duda planteada en C13. Lo que sí se confirmó exacto: 46 Edge Functions, 24 módulos y los 11 canales de Realtime en los archivos precisos que el PRD nombra — el baseline de C8 está verificado al 100% y T-14 arranca con el trabajo de localización hecho.

**4. El `CLAUDE.md` del sistema analizado está desactualizado.** Afirma que la última migración es `0128_cobertura_incentivos.sql` cuando ya existen migraciones en el rango `0350`, y describe rutas de macOS (`/Users/fabrizioalvarez/DASHBOARD`) para un repositorio que hoy se trabaja en Windows. También afirma que `origin` tiene dos push URLs (cuenta personal + organización), pero **esta copia local tiene una sola**, apuntando a `garantiplusmexico`. Nada de esto se corrige desde este plan (el análisis no toca el sistema, RNF-01), pero **es material para C13/T-19**: la documentación de arranque del proyecto es una de las cosas que se degradó, y es exactamente el síntoma que motivó este PRD.

**5. Decidir antes de arrancar Fase 3: ¿E0 es una conclusión aceptable?**
Si la migración al estándar ya está decidida por política, evaluar E0 con rigor consume días de Fase 3 para producir una comparación que nadie usará. Está en los prerequisitos de §2 a propósito. Si la respuesta es "ya está decidido", el plan sigue siendo válido pero E0 se documenta como línea base metodológica en lugar de escenario candidato, y esos días se reasignan a profundidad en P2.

**6. Lo que este plan deliberadamente no hace.** No escribe código, no refactoriza, no automatiza la importación de SIGA, no construye endpoints, no diseña la arquitectura destino, no cuantifica el costo mensual de Supabase/Vercel, no hace pruebas de carga y no toma la decisión. Todo eso está fuera de alcance por el PRD §6, y la tentación de "aprovechar el viaje" para arreglar algo que se encuentre al paso es la vía más rápida a incumplir el 04-09. Los arreglos detectados se registran como hallazgos con recomendación; ejecutarlos es el PRD posterior.

**7. Estrategia sugerida para sostener el ritmo.** El inventario (Fase 1) es la parte más mecánica y la más paralelizable: T-07 (módulos), T-08/T-09 (modelo de datos) y T-11 (Edge Functions) no dependen entre sí. Es donde un segundo recurso rinde más y donde la extracción automatizada de T-05 más ahorra. Fases 2 y 3, en cambio, son de juicio y no se paralelizan bien: partirlas entre dos personas produce dos criterios distintos, que es justo lo que RNF-07 y RNF-09 buscan evitar.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Habilitación, línea base y método** | Commit fijado (RNF-14), accesos confirmados o escalados, esqueleto de 21 documentos, metodología y escala de severidad publicadas, inventarios automatizados | T-01 a T-05 | 1 – 2 días | |
| **Fase 1 — Inventario y mapeo (P1)** | C1 ficha tecnológica, C2 los 24 módulos + ubicación de la lógica, C3 tablas/RLS/RPCs, C5' datos muertos, C4 las 46 Edge Functions, C5 integraciones, C6 uso real de SIGA, C8 los 11 canales, C9 PWA y offline · **PUERTA 1** | T-06 a T-15 | 4 – 6 días | |
| **Fase 2 — Análisis de calidad y riesgos (P1/P2)** | C10 arquitectura y patrones, C11 seguridad, C12 rendimiento, C13 testing/CI-CD, C14 observabilidad, registro de hallazgos priorizados | T-16 a T-21 | 3 – 5 días | |
| **Fase 3 — Escenarios, pros/contras y dictamen (P1/P3)** | C7 matriz de la API de SIGA, C15 Supabase vs .NET 8 por servicio, C16 escenarios E0–E3 con esfuerzo, C17 las tres opciones de PWA, C18 dictamen | T-22 a T-26 | 3 – 4 días | |
| **Fase 4 — Resumen ejecutivo, revisión y cierre** | C19 resumen ejecutivo, re-verificación de vigencia y cobertura declarada, revisión con Dirección (**PUERTA 2**), publicación y control de confidencialidad | T-27 a T-30 | 2 – 3 días | |
| **Total proyecto (alcance completo)** | | **30 tareas** | **~13 – 20 días hábiles** (≈ 2,6 – 4 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-15 | ~5 – 8 días hábiles (≈ 1 – 1,6 semanas) | — |
| **Ruta mínima al dictamen** | P1 de las cinco fases, con P2 recortado y cobertura declarada (RNF-11) | T-01 a T-30 (profundidad reducida) | ~10 – 13 días hábiles (≈ 2 – 2,6 semanas) | — |

> **Notas sobre la tabla:**
> - Las prioridades P1/P2/P3 no vienen del PRD (que declara sus tres fases como un único MVP): se derivan en §1.2 a partir del árbol de decisión de la §7.3 del PRD. Son la palanca que hace ejecutable cualquier recorte.
> - La fila **Solo P1** respeta la definición de la plantilla (Fase 0 + Fase 1). Ojo con leerla mal: **entrega el inventario, no el dictamen** — y el dictamen es lo que el PRD promete a Dirección. Por eso se añade la fila **Ruta mínima al dictamen**, que es el guardarraíl realmente útil aquí: recorre las cinco fases sacrificando profundidad en P2 en lugar de amputar el cierre.
> - Los rangos salen del volumen medido en §1.1, no de los números del PRD v0.1. Los dos mayores consumidores son T-07 (24 fichas de módulo con evidencia) y T-08/T-09 (~152 tablas con RLS y las RPCs vivas de ~269 declaraciones): entre los tres son más de la mitad de Fase 1.
> - Fase 3 asume que T-22 puede quedar sin acceso a la API de SIGA. Si el acceso llega, sube al extremo alto del rango (4 días); si no llega, se cierra declarando el hueco y no baja del extremo bajo (3 días) porque el resto del capítulo no depende de él.

> **Riesgo de deadline.**
> Hoy es **lunes 24-08-2026** y la fecha límite del PRD es **viernes 04-09-2026**: quedan exactamente **10 días hábiles**. Coincide al día con el cronograma del PRD (3 hábiles para Fase 1 al 26-08, 4 para Fase 2 al 01-09, 3 para Fase 3 al 04-09) — es decir, **el cronograma del PRD no tiene un solo día de holgura**, y el análisis ya arrancó tres días naturales tarde respecto de su fecha de inicio (21-08).
>
> El alcance completo estimado en esta tabla es de **13 – 20 días hábiles**, entre **30% y 100% por encima** de los 10 disponibles. **El alcance completo no cabe.** Incluso la *ruta mínima al dictamen* (10 – 13 días) solo cabe en su escenario más optimista, y asumiendo cero fricción de accesos — cuando cuatro de los cinco accesos críticos están hoy sin confirmar.
>
> Recomendación, en orden:
> 1. **Ejecutar la ruta mínima al dictamen, no el alcance completo.** Profundidad completa en P1, recorte declarado en P2 (T-10, T-18, T-19, T-20) y cierre honesto de P3 (T-22) si el acceso no llega. La cobertura declarada (RNF-11) es un entregable, no una excusa: es preferible un dictamen con huecos nombrados que un inventario completo sin recomendación.
> 2. **Mover la PUERTA 2 (T-29) fuera de la ventana**, al 08-09 o 09-09. Hoy la revisión de Dirección y la fecha de entrega caen el mismo día, lo que significa que las preguntas de la revisión no tienen dónde cerrarse. Separarlas 2–3 días hábiles no retrasa la decisión: la habilita.
> 3. **Sumar un segundo desarrollador solo para Fase 1.** Es la fase paralelizable (T-07, T-08/T-09 y T-11 son independientes) y la más pesada. Un segundo recurso ahí comprimiría Fase 1 en torno al **35 – 40%** y el total en torno al **20 – 25%** — suficiente para que la ruta mínima entre con margen. No conviene extenderlo a Fases 2 y 3: son de juicio, y dos criterios distintos en la misma auditoría rompen RNF-07 y RNF-09.
>
> Si ninguna de las tres se acepta, la consecuencia previsible es entregar el 04-09 un inventario sólido con un dictamen apresurado — exactamente el resultado que el PRD identifica como riesgo *"el inventario se vuelve superficial y el dictamen pierde base"*. Conviene decidir el recorte ahora, con criterio, en lugar de sufrirlo el 03-09.

---

*Generado por Claude Code — Engine CX*
*Modelo: `claude-opus-5` — esfuerzo: alto*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Línea base del sistema analizado: `garantiplus-dashboard` @ `3771e7f` (2026-08-19)*
