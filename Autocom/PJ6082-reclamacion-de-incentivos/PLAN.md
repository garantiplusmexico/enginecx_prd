# Plan de Desarrollo — Reclamación de Incentivos (MVP Fase 1)

> Generado por Claude Code a partir del PRD v0.3.
> Actualizado el 26 de agosto de 2026: Fase 1 reordenada y tareas renumeradas.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Autocom/PJ6082-reclamacion-de-incentivos/PRD.md` (v0.3, 26-ago-2026) |
| Repositorio | `garantiplusmexico/reclamacion-incentivos` (origin) · `aldoalvarez-engine/reclamacion-incentivos` (backup) |
| Rama | `feature/PJ6082-reclamacion-incentivos-mvp` |
| Tipo | Proyecto nuevo |
| Responsable | Aldo Álvarez |
| Folio PRD | PJ6082 |
| Fecha de generación | 25 de agosto de 2026 |
| Estado | En ejecución — Fase 0 |
| ID plan (BD) | 64 |
| Modelo | claude-opus-5 — esfuerzo: alto |

---

## 1. Resumen técnico

Se construye una aplicación web que valida que cada incentivo capturado en Quiter corresponda a un incentivo realmente ofertado por Hyundai, y que presenta el resultado a la dirección comercial para que lo audite y lo comente.

**Componentes que se crean:**

| Componente | Tecnología | Función |
|---|---|---|
| Aplicación web | Next.js (App Router) sobre Cloudflare Workers | Interfaz y rutas de API |
| Base de datos | Supabase (PostgreSQL) | Ventas ingeridas, catálogo de incentivos, homologaciones, resultados de validación, comentarios y bitácora |
| Autenticación | Supabase Auth + Cloudflare Zero Trust | Doble control: Zero Trust protege la liga, Supabase gestiona identidad y rol dentro de la aplicación |
| Ingesta | Supabase Edge Function (Deno) | Consulta AWS Athena firmando SigV4 y materializa el resultado en Postgres |
| Almacenamiento | Supabase Storage | Boletines y anexos originales como evidencia auditable |
| Motor de validación | TypeScript, en el servidor de Next.js | Determinista, sin IA por transacción |

**Arquitectura:** frontend + backend acoplados en Next.js, con la base de datos y la ingesta como servicios gestionados. Corresponde al patrón *"Frontend + Backend separados"* de `rules/arquitectura.md` —un solo dominio de negocio, con persistencia— resuelto sobre infraestructura gestionada en lugar de contenedores propios.

### Decisión arquitectónica y divergencia del estándar de Engine

Este plan **se aparta deliberadamente** de tres defaults de `rules/stack.md` e `infraestructura.md`:

| Capa | Estándar Engine | Este proyecto |
|---|---|---|
| Backend | .NET Core 8 / C# | Next.js (TypeScript) |
| Despliegue | ECS + Fargate | Cloudflare Workers |
| Base de datos | PostgreSQL en RDS | PostgreSQL en Supabase |
| Frontend | React | Next.js (cumple) |

**Justificación autorizada por Aldo Álvarez:** es la vía más directa, rápida y sin costo de infraestructura para poner el MVP frente a la dirección comercial y recibir retroalimentación. Zero Trust entrega el control de acceso sin construir autenticación, y Supabase entrega Postgres con Auth y RLS de entrada. Para un piloto que se comparte por liga, evita levantar VPC, ALB, ECS y RDS antes de saber si el producto acierta.

**Compromiso de reconversión:** una vez validado el MVP, la aplicación migra al entorno AWS con las reglas de los repositorios consolidados. Para que esa migración no sea una reescritura, este plan impone tres restricciones desde la primera línea de código:

1. **El motor de validación no depende de la infraestructura.** Vive en módulos puros de TypeScript, sin acceso a red ni a base de datos, que reciben datos y devuelven resultados. Es lo que se porta o se reescribe en C# sin tocar la lógica.
2. **El acceso a datos pasa por una capa de repositorio.** Ningún componente de interfaz consulta Supabase directamente; todo va por funciones con firma explícita, sustituibles por un cliente de RDS.
3. **PostgreSQL estándar.** El esquema no usa extensiones exclusivas de Supabase en las tablas de negocio. Auth, Storage y RLS sí son de Supabase y se documentan como puntos de migración conocidos.

---

## 2. Prerequisitos

- [x] PRD v0.3 validado y sincronizado al repo central
- [x] **Credenciales de Athena de larga duración** — confirmado en T-05: la llave es `AKIA`, usuario IAM de larga duración. Sirve para proceso desatendido.
- [x] **Ruta S3 de staging** — configurada y verificada en T-05
- [x] Cuenta de Cloudflare con Zero Trust habilitado — token de API verificado con permisos de Access y de Workers
- [x] Proyecto de Supabase creado — `yefkdlwnkmgkxufqjunm`, us-east-1, org Engine-CX
- [x] Boletín y anexo SA-40-26 de julio 2026 — cargados en `datos-locales/boletines/`
- [x] Repositorios creados en `garantiplusmexico` y `aldoalvarez-engine`, con las cuatro ramas
- [ ] `CLAUDE.md` presente en el repositorio (T-01 lo genera con `/init`)

---

## 3. Arquitectura del cambio

```
AWS Athena (consola Autocom)                    Documentos de HMM
  vw_full_master_view_ventas_nuevos               boletín + anexo (PDF)
  ftvenbi_pr (detalle por concepto)                      │
        │                                                │
        │ SigV4 + polling                                │ carga manual
        ▼                                                ▼
  Supabase Edge Function ──────────►  Supabase (PostgreSQL + Storage)
  "sincronizar periodo"                    ventas · catálogo · homologaciones
        ▲                                  validaciones · comentarios · bitácora
        │ invocación                                     ▲
        │                                                │ capa de repositorio
        └──────────────  Next.js en Cloudflare Workers ──┘
                          motor de validación (TS puro)
                                       ▲
                                       │ Supabase Auth (rol)
                                       │
                          Cloudflare Zero Trust (liga protegida)
                                       ▲
                                       │
                            Laura · dirección comercial · Engine
```

**Flujo del periodo:** se selecciona el mes → se cargan los PDF de la oferta → el anexo se parsea y el cuerpo del boletín se interpreta → el catálogo se aprueba y queda consultable → se sincronizan las transacciones desde Athena → se netean cancelaciones → se homologan versiones → el motor valida → la aplicación presenta conformidades, diferencias, excepciones de homologación y ventas sin incentivo → el usuario comenta.

**La sincronización no espera al catálogo, la validación sí** (RF-37): las transacciones se pueden traer y explorar en cualquier momento, pero el motor no corre sin una oferta aprobada.

---

## 4. Tareas de desarrollo

### Fase 0 — Cimientos (P1)

- [ ] **T-01** — Crear repositorio, ramas y documentación base
  - Crear `garantiplusmexico/reclamacion-incentivos` (privado) y `aldoalvarez-engine/reclamacion-incentivos` (backup)
  - Ramas obligatorias por `rules/version-control.md`: `main`, `develop`, `pre-qa`, `qa`
  - Remotos: `origin` → garantiplusmexico, `backup` → cuenta personal
  - Ejecutar `/init` para generar `CLAUDE.md`
  - Criterio: `git push origin develop` y `git push backup develop` funcionan; `CLAUDE.md` existe

- [ ] **T-02** — Andamiaje de Next.js sobre Cloudflare Workers
  - `create-next-app` con App Router y TypeScript; adaptador `@opennextjs/cloudflare`; `wrangler.toml`
  - Despliegue de una página mínima a una liga de Cloudflare
  - Criterio: la liga responde en producción con el despliegue automatizado desde `develop`

- [ ] **T-03** — Proyecto Supabase y esquema inicial
  - Crear proyecto; configurar migraciones versionadas en el repositorio
  - Tablas de arranque: `periodo`, `corrida_ingesta`, `bitacora`
  - Criterio: `supabase db push` aplica el esquema desde cero en un proyecto limpio

- [ ] **T-04** — Control de acceso de doble capa
  - Cloudflare Zero Trust delante de la liga, con política de acceso por correo
  - Supabase Auth dentro de la aplicación, con roles `admin`, `catalogo`, `operacion`, `consulta` (RNF-03)
  - RLS activo en todas las tablas de negocio
  - Criterio: un correo fuera de la política no llega ni a la pantalla de login; un usuario con rol `consulta` no puede aprobar catálogo

- [x] **T-05** — Spike de conexión a Athena *(bloqueante para la Fase 1)* — **COMPLETADA 25-ago-2026**
  - Firma SigV4 con `node:crypto` y `fetch`, sin dependencias: `StartQueryExecution`, sondeo, `GetQueryResults` paginado
  - **Resultado: viable.** Credencial `AKIA`, usuario IAM de larga duración, sirve para proceso desatendido
  - **Tres hallazgos que cambian el plan:** el workgroup exige `ClientRequestToken` (que sirve como llave de idempotencia); la vista no poda por fecha (1,008 MB por un mes contra 1,245 MB por todo); y cada consulta tarda de 40 a 50 segundos
  - Evidencia en `docs/spike-athena.md` y `scripts/spike-athena.mjs` del repositorio del proyecto

### Fase 1 — Oferta comercial y transacciones (P1)

> **Reordenada en v0.3.** El orden sigue el recorrido del usuario: primero existe la oferta contra la cual auditar, después se traen las transacciones. La ingesta pasó del inicio al final de la fase.

- [ ] **T-06** — Modelo de datos completo
  - `periodo`, `documento_oferta`, `catalogo_incentivo`, `venta`, `linea_incentivo`, `homologacion_version`, `resultado_validacion`, `comentario`, `alerta_duplicidad`, `corrida_ingesta`, `bitacora`
  - Llaves naturales que permitan reprocesar sin duplicar (RNF-06): `referencia` para la venta, `(periodo, modelo, version, variante)` para el catálogo
  - `periodo` gobierna todo y guarda su estado: documentos cargados, catálogo aprobado, última sincronización, última validación (RF-39)
  - Criterio: las migraciones aplican limpio y los índices cubren las consultas del tablero

- [ ] **T-07** — Selección del periodo y su estado (RF-39, F30)
  - Selector de mes que gobierna catálogo, ventas y alcance del motor; periodo definido por **fecha de factura**, del día 1 al último
  - Cada periodo muestra qué le falta para poder cerrarse
  - Criterio: se crea el periodo de julio 2026 y su estado refleja que no tiene documentos ni catálogo

- [ ] **T-08** — Carga de documentos de oferta comercial (RF-01)
  - Subida de boletín, anexo, actualizaciones y documentos de programas a Supabase Storage privado
  - Asociación a periodo y tipo de documento; el original se conserva íntegro como evidencia
  - Criterio: el boletín y el anexo de julio 2026 quedan cargados y descargables desde la aplicación

- [ ] **T-09** — Parser determinista del anexo (RF-35)
  - Extracción estructurada de las dos tablas, con arrastre del modelo en celdas combinadas
  - Verificación de consistencia: `round(aportación_con_IVA / 1.16) = aportación_sin_IVA`, tolerancia ±1 peso
  - Si falla en cualquier renglón, el documento se marca para revisión y no se aprueba solo
  - Criterio: las 54 filas del anexo de julio 2026 se extraen completas y pasan la verificación

- [ ] **T-10** — Interpretación del cuerpo del boletín con IA (RF-02)
  - OpenAI sobre el texto del boletín: bonos aditivos fuera de tabla, destinos permitidos del bono, programas vigentes de boletines anteriores y calendario de reclamo
  - Salida estructurada y marcada como propuesta, nunca aplicada sola (RNF-05)
  - Criterio: del SA-40-26 se obtienen el bono N Line de $5,000, los tres programas referenciados y las seis fechas del calendario

- [ ] **T-11** — Revisión y aprobación del catálogo (RF-04)
  - Pantalla que muestra lo extraído campo por campo, permite corregir y exige aprobación explícita
  - El catálogo aprobado queda versionado por vigencia; una actualización sucede a la anterior sin borrarla (RF-05)
  - Criterio: el catálogo de julio 2026 queda vigente y auditable, con registro de quién lo aprobó

- [ ] **T-12** — Consulta de la oferta comercial vigente (RF-36, F29)
  - Apartado permanente, navegable por periodo, con el vigente por omisión
  - Por modelo y versión: bono flexible, reparto marca/dealer, ambas variantes del anexo con y sin IVA, enlace al documento original y fecha de aprobación
  - Cuando el periodo tenga actualizaciones, señalar qué cambió y desde cuándo
  - Criterio: se consulta la oferta de julio 2026 sin abrir el PDF, y los importes coinciden con el anexo

- [ ] **T-13** — Ingesta desde Athena (RF-09, RF-38)
  - Edge Function que consulta la vista con **refresco completo del histórico**, no incremental: el spike probó que acotar a un mes ahorra 19%, no 97%
  - `ClientRequestToken` derivado del periodo y la corrida, no aleatorio, para que los reintentos no dupliquen consultas
  - Asíncrona en tres pasos: lanzar y persistir el `QueryExecutionId`, sondear, materializar
  - Upsert idempotente por `referencia`; registro de cada corrida con volumen, duración y resultado (RNF-08)
  - Criterio: dos corridas seguidas dejan el mismo número de filas

- [ ] **T-14** — Sincronización desde la interfaz (RF-37, RF-38)
  - Botón "Sincronizar" con avance visible; se permite en cualquier momento, con o sin catálogo aprobado
  - **La validación queda bloqueada** mientras el periodo no tenga catálogo aprobado, indicando qué falta
  - Historial de corridas y aviso visible del último corte (RNF-07)
  - Alerta ante volumen anómalamente bajo — el hueco de agosto y septiembre de 2025 es el caso que la motiva
  - Criterio: se sincroniza desde la interfaz y julio 2026 queda listo para validar

### Fase 2 — Motor de validación (P1)

> Las tareas de esta fase se implementan como **módulos puros de TypeScript**, sin acceso a red ni a base de datos, con pruebas unitarias sobre casos reales extraídos del histórico. Es la parte portable del sistema.

- [ ] **T-15** — Neteo de cancelaciones y refacturación (RF-31)
  - Reconocimiento por `bandera_cancelacion`, importe negativo espejo, `ud = -1` y referencia a la operación original
  - Neteo por unidad antes de validar
  - Criterio: las 16 cancelaciones de julio 2026 no generan discrepancia; caso de prueba con la unidad de tres movimientos que netea a un solo incentivo

- [ ] **T-16** — Homologación automática de modelo y versión (RF-08)
  - Derivación de modelo y versión del texto único de Quiter; normalización de transmisión (`TA`→`AT`, `TM`→`MT`), colapso de espacios y descarte de sufijos descriptivos
  - Distinción de híbridos y de submodelos (`CRETA` contra `CRETA GRAND`, `GRAND I10 HB` contra `SD`)
  - Criterio: ≥86% de las operaciones de julio 2026 homologadas automáticamente, verificado contra el resultado del prototipo

- [ ] **T-17** — Panel de excepciones de homologación (F28)
  - Lista de trabajo con el texto original, las versiones candidatas del periodo y selección del usuario
  - Campo de comentarios obligatorio cuando ninguna candidata aplique
  - Cada resolución se persiste y se reutiliza en periodos posteriores
  - Criterio: las 18 operaciones no homologadas de julio 2026 se resuelven desde el panel y no reaparecen al reprocesar

- [ ] **T-18** — Motor de validación de importe (RF-11, RF-12, RF-33)
  - Búsqueda en el catálogo vigente **a la fecha de factura** por modelo, versión y año
  - Comparación contra la aportación de la marca sin IVA con tolerancia de ±1 peso
  - Toda diferencia se calcula y se guarda también expresada con IVA
  - Discrepancia bidireccional: por arriba y por abajo
  - Criterio: sobre julio 2026 reproduce el resultado del prototipo (56 conformes de 81 evaluables) y las diferencias coinciden con los montos redondos ya identificados

- [ ] **T-19** — Barrido de ventas sin incentivo aplicado (RF-15)
  - Evaluación del total de ventas del periodo, no solo las que traen incentivo
  - Cuantificación del monto de aportación no reclamado por unidad, modelo y agregado
  - Criterio: reproduce las 25 operaciones por $910,550 detectadas en julio 2026

- [ ] **T-20** — Alerta de duplicidad por VIN (RF-32)
  - Detección de VINs con más de una venta activa acumulando más de un incentivo
  - Presentación de ambas operaciones lado a lado con la explicación de la sospecha; **sin resolución automática**
  - Criterio: los 9 VINs identificados en el histórico aparecen como alerta con su detalle

### Fase 3 — Presentación al negocio (P1)

- [ ] **T-21** — Reporte de conformidad (RF-29)
  - Detalle por unidad de lo que sí cuadra, con incentivo esperado, capturado y el documento que lo respalda
  - Criterio: exportable y contrastable contra el detalle de rebates de contabilidad

- [ ] **T-22** — Tablero de diferencias con comentarios (RF-30, RF-33)
  - Cada caso con diferencia sin IVA y con IVA, agrupable por monto para que los patrones salten a la vista
  - Campo de comentarios libre, atribuible y con sello de tiempo, **sin exigir cierre ni justificación**
  - Los comentarios se exportan en conjunto
  - Criterio: Laura puede comentar los 18 casos de +$25,000 en bloque y el comentario queda trazado

- [ ] **T-23** — Vista consolidada del periodo (RF-25)
  - Una sola pantalla con las ventas del periodo, su incentivo, su estatus de validación y su comentario
  - Sustituye funcionalmente la hoja de Google Drive
  - Criterio: cubre las 131 operaciones de julio 2026 sin captura manual

- [ ] **T-24** — Exportación del periodo (RF-24)
  - Excel y PDF con el detalle por VIN, el total a recuperar y el listado de pendientes
  - Criterio: el archivo abre en Excel con las columnas del control actual

- [ ] **T-25** — Bitácora de auditoría (RF-27, RNF-04)
  - Registro inmutable de cargas, aprobaciones, corridas, homologaciones resueltas y comentarios
  - Criterio: toda validación es reconstruible: qué catálogo, qué corrida, qué persona

### Fase 4 — Piloto de julio 2026 (P1)

- [ ] **T-26** — Corrida completa del periodo
  - Catálogo de julio 2026 aprobado, periodo sincronizado, validación ejecutada punta a punta
  - Criterio: los cuatro reportes (conformidad, diferencias, excepciones, ventas sin incentivo) cuadran con el prototipo

- [ ] **T-27** — Sesión de retroalimentación con la dirección comercial
  - Presentación a Laura Hernández; captura de comentarios dentro de la propia herramienta
  - Criterio: cada diferencia sin explicar queda comentada por el negocio

- [ ] **T-28** — Ajustes derivados de la retroalimentación
  - Nuevas entradas de catálogo, correcciones de homologación y ajustes de reglas que salgan de la sesión
  - Criterio: se recorre el periodo de nuevo y el porcentaje de conformidad sube de forma explicable

### Fase 5 — Operación continua (P2, posterior al piloto)

- [ ] **T-29** — Notas de crédito (RF-10, RF-16, RF-17, RF-18) — **bloqueada**
  - Depende de ubicar dónde viven las NC en Athena; el bloque 5 del guion de exploración es la vía
  - Criterio: cruce bidireccional NC ↔ incentivo por VIN con verificación de IVA

- [ ] **T-30** — Ingesta programada con `pg_cron`
  - Sustituye la sincronización manual una vez probada
  - Criterio: corrida diaria con alerta ante fallo, retraso o volumen anómalo

- [ ] **T-31** — Alertas ancladas al calendario de la marca (RF-34, RF-26)
  - Avisos derivados de las fechas de HMM, más notificación por correo
  - Criterio: la plataforma avisa antes del cierre de registro de VINs

- [ ] **T-32** — Ciclo de vida de la discrepancia y escalamiento (RF-21, RF-22, RF-23)
  - Estatus, responsable, re-validación con cierre verificado y escalamiento por antigüedad
  - Criterio: una discrepancia corregida en Quiter se cierra sola en la corrida siguiente

- [ ] **T-33** — Incentivos por regla porcentual (RF-06)
  - Comunidad coreana al 5% sobre precio de lista
  - Criterio: el importe esperado se calcula y se valida como cualquier otro incentivo

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `periodo` | Nueva | Periodo de oferta comercial con vigencia y estatus |
| `documento_oferta` | Nueva | Boletines y anexos cargados, con referencia al archivo en Storage |
| `catalogo_incentivo` | Nueva | Incentivos vigentes por modelo, versión, variante y vigencia |
| `venta` | Nueva | Operaciones ingeridas desde Athena, con VIN, modelo, importes y bandera de cancelación |
| `linea_incentivo` | Nueva | Detalle por concepto cuando se requiera más allá del total de la vista |
| `homologacion_version` | Nueva | Correspondencia texto de Quiter ↔ modelo/versión del catálogo, con estatus y comentario |
| `resultado_validacion` | Nueva | Resultado por operación: esperado, capturado, diferencia sin y con IVA, tipo y severidad |
| `comentario` | Nueva | Comentarios del negocio sobre casos, con autor y sello de tiempo |
| `alerta_duplicidad` | Nueva | VINs con más de una venta activa e incentivo acumulado |
| `corrida_ingesta` | Nueva | Bitácora de sincronizaciones con volumen, duración y resultado |
| `bitacora` | Nueva | Registro inmutable de acciones de usuario |
| — | Índices | `venta(vin)`, `venta(fec_factura)`, `venta(referencia)` único, `catalogo_incentivo(periodo, modelo, version, variante)` único |

---

## 6. Endpoints nuevos

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `/api/periodo/[id]/sincronizar` | Dispara la ingesta desde Athena | Nuevo |
| POST | `/api/documento` | Carga de boletín o anexo | Nuevo |
| POST | `/api/documento/[id]/extraer` | Parseo del anexo e interpretación del boletín | Nuevo |
| POST | `/api/catalogo/[id]/aprobar` | Aprobación humana del catálogo | Nuevo |
| POST | `/api/periodo/[id]/validar` | Ejecuta el motor sobre el periodo | Nuevo |
| GET | `/api/periodo/[id]/conformidad` | Reporte de operaciones conformes | Nuevo |
| GET | `/api/periodo/[id]/diferencias` | Operaciones con diferencia | Nuevo |
| GET | `/api/periodo/[id]/sin-incentivo` | Ventas con incentivo ofertado y no capturado | Nuevo |
| GET | `/api/periodo/[id]/excepciones` | Excepciones de homologación pendientes | Nuevo |
| POST | `/api/homologacion` | Resolución de una excepción de homologación | Nuevo |
| POST | `/api/comentario` | Comentario sobre un caso | Nuevo |
| GET | `/api/periodo/[id]/exportar` | Descarga en Excel o PDF | Nuevo |

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `SUPABASE_URL` | URL del proyecto | Todos |
| `SUPABASE_ANON_KEY` | Llave pública para el cliente | Todos |
| `SUPABASE_SERVICE_ROLE_KEY` | Llave de servicio — **solo en el servidor**, nunca expuesta al navegador | Todos |
| `AWS_ACCESS_KEY_ID` | Credencial de Athena — **solo en Supabase Vault** | Ingesta |
| `AWS_SECRET_ACCESS_KEY` | Credencial de Athena — **solo en Supabase Vault** | Ingesta |
| `AWS_REGION` | Región de la consola de Autocom | Ingesta |
| `ATHENA_WORKGROUP` | Workgroup a utilizar | Ingesta |
| `ATHENA_OUTPUT_S3` | Ruta S3 de staging de resultados | Ingesta |
| `ATHENA_DATABASE` | `db-bi-quiterqbi` | Ingesta |
| `ANTHROPIC_API_KEY` | Interpretación del cuerpo del boletín | Servidor |
| `CF_ACCESS_TEAM_DOMAIN` | Dominio de Zero Trust para validar el JWT de acceso | Producción |

---

## 8. Consideraciones de seguridad

- **Credenciales de AWS únicamente en Supabase Vault**, accesibles solo desde la Edge Function de ingesta. La aplicación web nunca las ve y nunca habla con Athena directamente.
- **Solo lectura sobre el origen** (RNF-02). Las credenciales de Athena deben limitarse a `SELECT` sobre la vista y a lectura del bucket de staging. Si las actuales tienen más permisos, solicitar unas acotadas.
- **La service role key de Supabase jamás se envía al navegador.** Todo acceso privilegiado ocurre en rutas de servidor de Next.js.
- **Doble control de acceso.** Zero Trust filtra quién llega a la liga; Supabase Auth y RLS determinan qué puede hacer cada quien una vez dentro. La aplicación valida el JWT de Cloudflare Access en el servidor y no confía solo en el perímetro.
- **Datos personales al mínimo** (RNF-09). El nombre del cliente llega en la vista pero no es necesario para validar incentivos: se ingiere solo si se justifica y queda restringido por rol.
- **Los boletines son información comercial sensible de la marca** (RNF-10). Storage privado, acceso por URL firmada de vigencia corta.
- **Bitácora no editable ni borrable** (RNF-04), garantizada por RLS sin políticas de `UPDATE` ni `DELETE`.

---

## 9. Consideraciones de infraestructura

- **Costo esperado del MVP: cercano a cero.** Cloudflare Workers y Supabase operan dentro de sus planes gratuitos para este volumen —131 operaciones al mes, unas 3,000 en todo el histórico—. El único costo variable es el escaneo de Athena, acotado por consultar un periodo a la vez, y el consumo de IA, limitado a la carga de documentos (RNF-13).
- **No se crean recursos en AWS.** El proyecto solo consume Athena y S3 de la consola de Autocom con credenciales existentes.
- **Cloudflare Zero Trust** requiere configurar una aplicación de Access con política por correo. No hay cambios en Route 53 de Engine.
- **Deuda de migración conocida y aceptada:** al reconvertir a AWS habrá que sustituir Supabase Auth por el mecanismo de Engine, Storage por S3, RLS por autorización en el backend, y la Edge Function por una Lambda o un servicio en ECS. El motor de validación y el esquema de datos se conservan.

---

## 10. Criterios de aceptación

- [ ] La aplicación es accesible en una liga de Cloudflare protegida por Zero Trust, y un correo fuera de la política no puede entrar
- [ ] El boletín y anexo de julio 2026 se cargan, se extraen y se aprueban como catálogo vigente
- [ ] El anexo se parsea sin IA y sus 54 renglones pasan la verificación de consistencia de IVA
- [ ] El periodo de julio 2026 se sincroniza desde Athena a Supabase desde la interfaz, y reprocesarlo no duplica filas
- [ ] Las cancelaciones se netean y no generan discrepancias falsas
- [ ] La homologación automática resuelve al menos el 86% de las operaciones; el resto se resuelve desde el panel de excepciones y no reaparece
- [ ] El motor reproduce el resultado del prototipo sobre julio 2026 y expresa cada diferencia con y sin IVA
- [ ] El barrido de ventas sin incentivo reproduce las 25 operaciones por $910,550
- [ ] Los 9 VINs con posible duplicidad aparecen como alerta, sin resolución automática
- [ ] La dirección comercial puede comentar cualquier caso, y los comentarios se exportan
- [ ] El periodo se exporta a Excel y PDF
- [ ] Toda validación es reconstruible desde la bitácora
- [ ] El motor de validación tiene pruebas unitarias sobre casos reales y no depende de red ni de base de datos

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Las credenciales de Athena son temporales o de SSO | Media | **Alto** | Se verifica en T-05, antes de construir la ingesta. Si lo son, se solicitan llaves de larga duración a Autocom. Es el único riesgo que puede detener la Fase 1. |
| Límites de la Edge Function al sondear Athena | Media | Medio | T-05 lo mide con datos reales. Alternativas: mover la ingesta a un Worker con Cron Trigger, o a una acción programada en el repositorio. |
| Falta el destino del bono en la fuente | **Alta** *(ya confirmada)* | Medio | El motor acepta la coincidencia con cualquiera de las dos variantes del anexo y lo declara explícitamente en el resultado. Se cierra si Autocom expone el dato (H-4 del diagnóstico). |
| Volumen alto de excepciones de homologación en periodos con modelos nuevos | Media | Medio | El panel de excepciones convierte el problema en una lista de trabajo acotada, y cada resolución se aprende. |
| El parseo del anexo falla ante un formato distinto | Media | Medio | La verificación de consistencia de IVA detecta el fallo antes de aprobar; la IA queda como respaldo (RF-02). |
| Huecos silenciosos en la fuente | Media | **Alto** | T-08 alerta ante volumen anómalamente bajo. El hueco de agosto y septiembre de 2025 es la evidencia de que ocurre. |
| Deriva del MVP respecto al estándar de Engine | Alta | Medio | Las tres restricciones de la §1 acotan la reescritura al reconvertir a AWS. |
| Expectativa de que el MVP resuelva comisiones | Media | Medio | El PRD lo excluye explícitamente; conviene reiterarlo en la sesión con la dirección comercial. |

---

## 12. Notas para el programador

**Antes de arrancar, resolver el prerequisito de credenciales.** T-05 existe precisamente para fallar temprano si las llaves de Athena no sirven para un proceso desatendido. No conviene avanzar a la Fase 1 sin ese resultado.

**El prototipo ya validado es la prueba de regresión.** Los números de julio 2026 —131 operaciones, 113 homologadas, 56 conformes de 81 evaluables, 25 sin incentivo por $910,550, y las diferencias de +$50,000 / +$25,000 / +$10,000 con IVA— son el criterio contra el que se verifica el motor. Si el sistema no los reproduce, el sistema está mal.

**No intentar cuadrar las diferencias automáticamente.** Es una decisión de producto del PRD v0.2, no una limitación técnica. El MVP las expone para que el negocio las explique.

**Sobre la ingesta:** se implementa como invocación manual desde la interfaz. El `pg_cron` es Fase 5, deliberadamente. Para el piloto no hay nada que ganar depurando corridas programadas.

**Sobre el hueco de la fuente:** la vista no devuelve agosto ni septiembre de 2025. No afecta al piloto de julio 2026, pero sí a cualquier métrica histórica que se presente.

**Pendiente de decisión:** el nombre definitivo del repositorio y la región del proyecto de Supabase.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Cimientos (P1)** | Repositorio y ramas, Next.js en Workers, Supabase, Zero Trust, spike de Athena | T-01 a T-05 | 3 – 5 días | 223 |
| **Fase 1 — Oferta comercial y transacciones (P1)** | Modelo de datos, selector de periodo, carga y parseo de documentos, aprobación y consulta del catálogo, ingesta desde Athena | T-06 a T-14 | 8 – 11 días | 224 |
| **Fase 2 — Motor de validación (P1)** | Neteo, homologación, panel de excepciones, validación de importe, barrido y duplicidad | T-15 a T-20 | 6 – 9 días | 225 |
| **Fase 3 — Presentación al negocio (P1)** | Conformidad, diferencias con comentarios, vista consolidada, exportación, bitácora | T-21 a T-25 | 5 – 7 días | 226 |
| **Fase 4 — Piloto de julio 2026 (P1)** | Corrida completa, sesión con la dirección comercial, ajustes | T-26 a T-28 | 2 – 4 días | 227 |
| **Fase 5 — Operación continua (P2)** | Notas de crédito, ingesta programada, alertas por calendario, ciclo de discrepancia, incentivos por regla | T-29 a T-33 | 7 – 11 días | 228 |
| **Total proyecto (P1+P2)** | | 33 tareas | ~31 – 47 días hábiles (≈ 6 – 9.5 semanas) | — |
| **Solo P1 (MVP del piloto)** | Fases 0 a 4 | T-01 a T-28 | ~24 – 36 días hábiles (≈ 5 – 7 semanas) | — |

> **Notas sobre la tabla:**
> - El guardarraíl no es "Fase 0 + Fase 1" como en la plantilla estándar, porque el compromiso adquirido es un MVP presentable a la dirección comercial. Ese mínimo abarca las Fases 0 a 4.
> - La Fase 5 es explícitamente posterior al piloto: su contenido puede cambiar según la retroalimentación recibida, y T-29 está bloqueada por una dependencia externa.
> - Los rangos suponen un desarrollador. Las Fases 2 y 3 son paralelizables entre sí una vez cerrada la Fase 1.

> **Riesgo de deadline.** El PRD no fija fecha límite —la deja a este ejercicio de planeación—, pero el calendario de HMM sí impone fechas reales. Contra el 25 de agosto de 2026:
>
> - **Cerrar el periodo de agosto 2026 con la herramienta no es viable.** Las fechas de HMM para ese periodo (registro de VINs a principios de septiembre, carga de documentos a mediados) dejan alrededor de 13 días hábiles, contra los 22 a 34 que exige P1. No alcanza, y forzarlo pondría en riesgo un cobro real.
> - **El piloto de julio 2026 no tiene presión de calendario**, porque es retrospectivo. Es la razón de fondo por la que se eligió como periodo de validación.
> - **Objetivo realista de operación en vivo: el periodo de octubre 2026.** Terminando P1 a finales de septiembre, octubre se opera con la herramienta desde el primer día del mes, con septiembre como mes de rodaje en paralelo al proceso manual.
> - **Un segundo desarrollador comprimiría P1 entre 25% y 35%**, paralelizando la Fase 2 (motor, en módulos puros) contra la Fase 3 (interfaz). No cambia la conclusión sobre agosto, pero aseguraría octubre con holgura.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
