# Plan de Desarrollo — Bridgestone: causa raíz de contratos pendientes/huérfanos

> Generado por Claude Code a partir del análisis de código de `BridgestoneController` + landing de Bridgestone (sesión 2026-08-12).
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | ⚠️ **Pendiente.** Este plan nace de un análisis técnico, no de un PRD. Antecedente directo: `SIGA/PJ5796-bridgestone-regeneracion-contratos-pendientes/PRD.md` (§3 "Qué NO entra": *"Corregir la causa raíz del fallo de creación (timeouts)"*). Este plan cubre exactamente esa exclusión. |
| Repositorios | **gp_3.0_siga_api** (Contracts + ApiGateway + Infrastructure) y **bridgestone_landing** (una tarea de UX) |
| Rama base | `develop` (existe en ambos repos; verificado y actualizado en `gp_3.0_siga_api` el 2026-08-12 — sin diferencias contra `main` en los archivos afectados) |
| Ramas funcionales | `bugfix/ECX-XXX-bridgestone-contratos-huerfanos` (misma en ambos repos; sustituir `ECX-XXX` por el ticket real) |
| Tipo | **Bugfix** (corrección planificada de causa raíz en producción) |
| Responsable | Javier Oropeza |
| Fecha de generación | 2026-08-12 |
| Estado | Borrador |

---

## 1. Resumen técnico

El alta de garantía de Bridgestone (`POST /contracts/api/Bridgestone/v1/contracts/{projectId}`) hace **commit del registro `bs_registro` + factura en S3 antes de crear el contrato en SIGA**, y solo enlaza el `id_contrato` si toda la cadena posterior (contrato → PDF → relectura → base64) termina bien. Esa ventana no transaccional produce dos defectos recurrentes:

1. **Registros pendientes con contrato ya creado (huérfanos):** cualquier fallo o cancelación posterior a `VentasBusinessRules.CreateContract` devuelve error al landing aunque el contrato ya exista. El registro queda `Pendiente` y regenerarlo **duplica** el contrato.
2. **Registros pendientes sin contrato:** el request muere por latencia acumulada (LogsMonitor sin timeout, espera de PDF, flyer gRPC síncrono, base64 en memoria) sobre una task de **256 CPU / 512 MB**.

El cambio es **quirúrgico y sin refactor** (`rules/coding-guidelines.md`: no refactorizar código existente salvo solicitud explícita). Se agrupa en cuatro frentes:

- **Idempotencia:** enlazar `id_contrato` en `bs_registro` **en cuanto Ventas lo devuelve**, antes de PDF/flyer/base64, mediante un callback opcional en `IContractCreationService.CreateContractAsync`. A partir de ahí, ningún fallo posterior puede generar un huérfano.
- **Control de cancelación:** dejar de propagar `HttpContext.RequestAborted` a la ruta de escritura; usar un token con presupuesto propio configurable.
- **Latencia:** sacar flyer y PDF del request (cola en background in-process + flag para no devolver `pdfBase64`).
- **Plataforma:** rate limiting particionado por usuario, timeout en LogsMonitor, sizing de la task ECS/ALB y desbloqueo del estatus `Procesando`.

**Stack respetado:** .NET 8 + C#, PostgreSQL (SQL crudo para `bs_*`), React + Vite en el landing, ECS + Fargate (`rules/stack.md`, `rules/arquitectura.md` §1). **No se crea infraestructura nueva.**

---

## 2. Prerequisitos

- [ ] Ticket `ECX-XXX` asignado (para nombrar ramas y commits) y número de PJ real para renombrar esta carpeta (`PJ0000-…`)
- [ ] PRD formal (opcional): este plan puede ejecutarse como bugfix técnico, pero conviene registrar el PRD por trazabilidad
- [x] Acceso a ambos repositorios confirmado
- [x] Rama base `develop` disponible y actualizada en `gp_3.0_siga_api`
- [x] `CLAUDE.md` presente en `gp_3.0_siga_api`
- [ ] `CLAUDE.md` en `bridgestone_landing` — **no existe**: correr `/init` en ese repo antes de la T-12
- [ ] Acceso de solo lectura a la BD de producción para la Fase 0 (inventario de huérfanos)
- [ ] Confirmar con Aldo Álvarez el cambio de sizing de la task ECS (impacto en costo AWS — `rules/infraestructura.md` §1)
- [ ] Confirmar con negocio que el PDF del contrato deje de descargarse automáticamente al finalizar el alta (pasa a "Contratos creados")

---

## 3. Arquitectura del cambio

Se respeta la arquitectura de **microservicios en ECS** (`rules/arquitectura.md` §1) y el patrón **Frontend + Backend separados** del landing. No se introducen servicios ni patrones nuevos: la cola de trabajo diferido es **in-process** (`System.Threading.Channels` + `IHostedService`), no NATS ni SQS, porque el flyer ya tiene generación perezosa de respaldo en `GetFlyerById` → `EnsureBridgestoneFlyerAsync`.

**Flujo actual (defectuoso):**

```
Landing ──POST multipart──► KrakenD ──► Contracts
                                          1. LogRequest (HTTP externo, sin timeout)
                                          2. Build request (dealer, canal, VIN, llantas)
                                          3. INSERT bs_registro + S3  ── COMMIT ──┐
                                          4. Ventas.CreateContract ── contrato ✔  │  ventana
                                          5. gRPC PDF + polling 12 s              │  no
                                          6. GetContractById + descarga + base64  │  transaccional
                                          7. UPDATE id_contrato (solo si 4-6 OK) ─┘
                                          8. Flyer gRPC (await, genera PDF + correo)
                                          9. LogResponse (HTTP externo)
```

**Flujo objetivo:**

```
Landing ──POST multipart──► KrakenD ──► Contracts
                                          1. LogRequest (timeout 5 s)
                                          2. Build request
                                          3. INSERT bs_registro + S3 ── COMMIT
                                          4. Ventas.CreateContract ─┐
                                          5. UPDATE id_contrato ◄───┘ inmediato e idempotente
                                          6. Respuesta 201 (sin base64)
                                          7. Encolar flyer + PDF ──► BackgroundQueue (fuera del request)
```

Token de cancelación: pasos 3-6 corren con `CancellationToken` **propio** (presupuesto configurable), no con `HttpContext.RequestAborted`.

---

## 4. Tareas de desarrollo

> Nomenclatura de archivos: rutas relativas a la raíz de cada repo. Las referencias `archivo:línea` corresponden a `develop` al 2026-08-12.

### Fase 0 — Diagnóstico y saneo del backlog actual *(sin código, precede a todo)*

- [ ] **T-01** — Inventariar los pendientes reales y separar huérfanos (contrato ya creado) de fallidos (sin contrato)
  - Archivos a crear: `Services/Contracts/docs/sql/bridgestone-reconciliacion-huerfanos.sql`
  - Consulta base (100 % validada contra el esquema conocido):
    ```sql
    SELECT id_bs_registro, id_distribuidor, folio_factura, estatus,
           fecha_creacion, fecha_modificacion, correo, rfc
    FROM bs_registro
    WHERE id_contrato IS NULL
    ORDER BY fecha_creacion DESC;
    ```
  - Heurística de detección de huérfanos: el VIN de los contratos del landing es un **timestamp de 17 dígitos** (`yyyyMMddHHmmssfff`, ver `LandingVinGenerator.Generate` — con `MaxLength: 17` el prefijo `BridgeStone` se descarta), casi idéntico a `bs_registro.fecha_creacion`. Cruzar `vehiculo.vin` contra `to_char(r.fecha_creacion,'YYYYMMDDHH24MISS')` con ventana de ±120 s y mismo `contrato.id_distribuidor`.
  - ⚠️ Confirmar contra `DataAccess` el nombre real de la relación `contrato ↔ vehiculo` antes de ejecutar el cruce.
  - Criterio de completitud: lista firmada de registros clasificados en **A) huérfano con contrato**, **B) pendiente sin contrato**, **C) atascado en `Procesando`**

- [ ] **T-02** — Sanear el backlog
  - Grupo A → `UPDATE bs_registro SET id_contrato = :id, estatus = 'Registrado', fecha_modificacion = NOW() WHERE id_bs_registro = :reg AND id_contrato IS NULL;` (uno por uno, verificado en SIGA)
  - Grupo B → regenerar desde la UI de "Contratos pendientes" (herramienta del PJ5796)
  - Grupo C → `UPDATE bs_registro SET estatus = 'Pendiente' WHERE id_bs_registro = :reg AND id_contrato IS NULL AND estatus = 'Procesando';` y luego regenerar
  - Criterio de completitud: la vista de pendientes del landing queda en cero o solo con casos justificados y documentados

---

### Fase 1 — Idempotencia y control de cancelación *(núcleo del bugfix — puntos 1, 2, 4 y 8)*

- [ ] **T-03** — Enlace temprano: callback opcional en la creación de contratos
  - Archivos a modificar:
    - `Services/Contracts/Interfaces/IContractCreationService.cs`
    - `Services/Contracts/Services/ContractCreationService.cs` (:50-198)
  - Agregar **parámetro opcional** `Func<long, CancellationToken, Task>? onContractPersisted = null` a `CreateContractAsync`, invocado inmediatamente después de que `_ventasBusinessRules.CreateContract` devuelve `newContract.id_contrato` (:126-153) y **antes** de `TriggerPdfGenerationAsync` (:156).
  - Capturar el id en una variable local `long? createdContractId` y usarla en **todas** las salidas de error posteriores: `CreateContractResponse.Fail(error, createdContractId)` — incluido el `catch` general de :193-197, que hoy pierde el id.
  - Parámetro opcional ⇒ los llamadores de BMW (`Services/Contracts/Services/Bmw/*`) compilan sin cambios y su comportamiento no se altera.
  - Criterio de completitud: existe un punto único donde el id del contrato se publica antes de cualquier trabajo accesorio, y ninguna respuesta de error posterior a la creación devuelve `ContractId = null`

- [ ] **T-04** — Enlace idempotente que no traga excepciones
  - Archivos a modificar: `Services/Contracts/Services/Bs/BridgestoneRegistrationService.cs` (:151-176), `Services/Contracts/Interfaces/IBridgestoneRegistrationService.cs`
  - `LinkContractToRegistrationAsync` pasa a devolver `Task<bool>` (filas afectadas == 1) y **propaga** la excepción en lugar de tragarla (hoy `catch` + `LogError` silencioso ⇒ el usuario ve 201 y la fila sigue pendiente).
  - `UPDATE … WHERE id_bs_registro = @id AND id_contrato IS NULL` — llamarlo dos veces es inocuo (segunda llamada afecta 0 filas y no pisa un enlace previo).
  - Un reintento inmediato (1 retry) ante fallo transitorio antes de propagar.
  - Criterio de completitud: enlazar dos veces el mismo registro no cambia el estado; un fallo de UPDATE llega al controller con el `contractId` para reporte

- [ ] **T-05** — Controller: usar el callback y garantizar el enlace en toda salida
  - Archivos a modificar: `Services/Contracts/Controllers/BridgestoneController.cs` (:630-678)
  - Pasar `onContractPersisted: (id, ct) => _bridgestoneRegistrationService.LinkContractToRegistrationAsync(idBsRegistro, id, ct)` a `CreateContractAsync`.
  - Tras la llamada: si `response.ContractId.HasValue` → asegurar enlace (idempotente) **aunque `Success == false`**, y devolver el `contractId` en el payload de error con mensaje accionable en español (*"El contrato N se creó; no fue posible completar el proceso posterior. No reintentes el alta."*).
  - Si el enlace falla con contrato creado → **409/500 con el `contractId`** (nunca dejar la fila pendiente en silencio).
  - Criterio de completitud: ninguna combinación de fallos posterior a la creación deja `bs_registro.id_contrato = NULL` cuando el contrato existe

- [ ] **T-06** — Dejar de propagar `RequestAborted` a la ruta de escritura
  - Archivos a modificar:
    - `Services/Contracts/Controllers/BridgestoneController.cs` (:600-670 y :720-761)
    - `Services/Contracts/Options/` → nueva clase `ContractWriteOperationOptions` (`TimeoutSeconds`, default 180)
    - `Services/Contracts/appsettings.json` → sección `ContractWriteOperation`
    - `Services/Contracts/Program.cs` → binding `IOptions<ContractWriteOperationOptions>`
  - A partir de `InsertPendingRegistrationWithDocumentsAsync`, usar `using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(options.TimeoutSeconds))` **no vinculado** a `HttpContext.RequestAborted`. Las lecturas previas (scope, directorio, validaciones) conservan `RequestAborted`.
  - Mismo cambio en `RegeneratePendingContract` → `ResumeAsync`.
  - Revisar `WaitForPdfUriAsync` (`ContractCreationService.cs`:562-592): su `Task.Delay(ct)` es el punto exacto donde hoy revienta la cancelación del cliente.
  - Criterio de completitud: cerrar la pestaña del navegador a mitad del alta **no** aborta la creación ni deja el registro pendiente
  - ⚠️ **Fuera de alcance pero mismo defecto:** `BmwController` usa el mismo patrón. Documentar como fase futura.

- [ ] **T-07** — Claim `Procesando` con expiración
  - Archivos a modificar: `Services/Contracts/Services/Bs/BridgestoneRegistrationService.Resume.cs` (:12-28), `Services/Contracts/Options/` (`BridgestoneResumeOptions.StaleClaimMinutes`, default 10), `appsettings.json`
  - `TryClaimForResumeAsync`: `AND (estatus <> 'Procesando' OR fecha_modificacion < NOW() - (@stale_minutes || ' minutes')::interval)`
  - Criterio de completitud: un registro atascado en `Procesando` vuelve a ser regenerable pasados N minutos, sin intervención en BD

---

### Fase 2 — Latencia: sacar PDF y flyer del request *(punto 3)*

- [ ] **T-08** — Cola de trabajo en background (in-process)
  - Archivos a crear: `Services/Contracts/Services/Background/BackgroundTaskQueue.cs`, `Services/Contracts/Services/Background/QueuedHostedService.cs`, `Services/Contracts/Interfaces/IBackgroundTaskQueue.cs`
  - `Channel<Func<IServiceProvider, CancellationToken, Task>>` con cota (`BoundedChannelOptions`, p. ej. 500) + `BackgroundService` que crea **su propio scope de DI** por ítem (el `DbContext` es scoped: no se puede capturar el del request).
  - Registro en `Program.cs`: `AddSingleton<IBackgroundTaskQueue>` + `AddHostedService<QueuedHostedService>`.
  - Criterio de completitud: encolar y ejecutar una tarea de prueba con su propio scope; el apagado del contenedor drena la cola sin excepciones

- [ ] **T-09** — Flyer fuera del request
  - Archivos a modificar: `Services/Contracts/Controllers/BridgestoneController.cs` (:667-670), `Services/Contracts/Services/Bs/BridgestoneContractResumeService.cs` (:123)
  - Reemplazar `await NotifyBridgestoneFlyerAsync(...)` por un encolado. Riesgo de pérdida acotado: si el contenedor cae con ítems en cola, el flyer sigue generándose bajo demanda en `GET v1/GetFlyerById/{contractId}` (`EnsureBridgestoneFlyerAsync`); lo único que se pierde es el correo automático.
  - Criterio de completitud: el 201 del alta llega sin esperar al servicio de PDF; el flyer y el correo siguen llegando

- [ ] **T-10** — No devolver `pdfBase64` en el alta (configurable)
  - Archivos a modificar: `Services/Contracts/Services/ContractCreationService.cs` (:155-191), `Services/Contracts/Options/` (`BridgestoneLandingContractDefaults:ReturnPdfInResponse`, default **false**), `appsettings.json`
  - Con el flag en `false`: omitir `WaitForPdfUriAsync` (hasta 12 s), la descarga de S3 y el `Convert.ToBase64String` (el mayor consumo de memoria del request). El disparo gRPC del PDF (`TriggerPdfGenerationAsync`) se mantiene — es lo que genera el documento.
  - Criterio de completitud: la latencia p95 del POST baja de forma medible en QA y la respuesta sigue trayendo `contractId`, estatus, fechas y total

- [ ] **T-11** — Landing: UX cuando no llega el PDF en la respuesta
  - Repo: **bridgestone_landing** (correr `/init` antes)
  - Archivos a modificar: `src/features/warranty-registration/RegistrationPortal.tsx` (:326-344, rama `else` del `pdfBase64`), `src/features/warranty-registration/views/SuccessView.tsx`
  - Sustituir el toast informativo *"PDF no incluido en la respuesta"* (hoy suena a error) por un mensaje afirmativo con acceso directo a "Contratos creados" para descargar contrato y flyer.
  - Criterio de completitud: el alta exitosa no muestra ningún mensaje que parezca fallo; el usuario descarga el PDF en ≤ 2 clics

---

### Fase 3 — Resiliencia de plataforma *(puntos 5, 6 y 7)*

- [ ] **T-12** — Rate limiting particionado por usuario
  - Archivos a modificar: `Common/RateLimiting/Extensions/RateLimitingExtensions.cs` (:28-107), `Services/*/Program.cs` (ForwardedHeaders)
  - Hoy `AddSlidingWindowLimiter(nombre, opts)` crea **un único limitador compartido por todos los usuarios y por todos los endpoints** de esa política: `Restrictive` = 20 req/min **en total** para el POST de contratos, el flyer, la regeneración **y** los tres endpoints de directorio que el landing llama en cada selección del formulario.
  - Cambiar a `options.AddPolicy(nombre, ctx => RateLimitPartition.GetSlidingWindowLimiter(clave, …))` con `clave = sub del JWT ?? IP`. **Manteniendo los mismos límites numéricos** (solo se agrega partición).
  - ⚠️ Detrás de ALB + KrakenD, `RemoteIpAddress` es la IP del gateway ⇒ sin `UseForwardedHeaders` **todos los anónimos caerían en la misma partición**. No hay `ForwardedHeaders` configurado en ningún `Program.cs` del repo: agregarlo es parte de la tarea.
  - Mover `GET v1/directory/{countries,groups,branches}` de `Restrictive` a `Light` en `BridgestoneController.cs` (:79, :131, :191) — son lecturas de catálogo.
  - ⚠️ **Cambio transversal:** `Common/RateLimiting` lo consumen todos los microservicios. Requiere regresión mínima en Authentication, Catalogs, Claims, Invoices y Reports.
  - Criterio de completitud: un usuario saturando su cuota no bloquea a los demás; llenar el formulario ya no consume cuota de escritura

- [ ] **T-13** — Timeout explícito en LogsMonitor
  - Archivos a modificar: `Services/Contracts/Program.cs` (:307-321) y el bloque equivalente en los demás `Services/*/Program.cs`; `appsettings.json` → `LogsMonitor:TimeoutSeconds` (default 5)
  - `LoggingService` (repo hermano `LogsMonitorClient`) **ya captura sus excepciones** y devuelve `logId = 0`, así que no tumba el request; el problema es que **se espera** la llamada HTTP con el timeout por defecto de `HttpClient` (100 s), dos veces por request, en la ruta crítica.
  - Añadir `client.Timeout = TimeSpan.FromSeconds(cfg)` en el `AddHttpClient<LogsMonitorClient>`.
  - Criterio de completitud: con LogsMonitor caído o lento, el alta responde con normalidad y la degradación es ≤ 5 s por llamada

- [ ] **T-14** — Sizing de la task ECS, ALB y circuit breaker del gateway
  - Archivos a modificar: `Infrastructure/prod/Contracts-task-definition.json` (:5-6), `Infrastructure/qa/Contracts-task-definition.json`, `Services/ApiGateway/krakend.json` (:1568-1587)
  - **ECS:** `cpu 256 / memory 512` → **`512 / 1024`** (mínimo). Justificación: el request lee la factura (hasta 20 MB) a `MemoryStream`, y hoy además arma el PDF en base64 — con 512 MB el OOM-kill es plausible y mata el request **después** del commit del registro. Validar costo con Dirección de TI (`rules/infraestructura.md` §1: AWS no tiene tope automático de gasto).
  - **ALB:** fijar `idle_timeout.timeout_seconds` explícito (sugerido **120 s**) — hoy no está configurado en `Infrastructure/`, luego corre con el default de 60 s, por debajo del peor caso real del alta.
  - **KrakenD:** revisar `qos/circuit-breaker` del POST de contratos (`interval: 60, timeout: 10, max_errors: 2`): con solo 2 errores en 60 s el circuito se abre y los siguientes intentos fallan sin llegar a la API. Subir `max_errors` (sugerido 5-10) o retirarlo de ese endpoint. Confirmar contra la documentación de la versión de KrakenD desplegada antes de tocarlo.
  - Criterio de completitud: task redimensionada y desplegada en QA; una ráfaga de altas simultáneas no abre el circuito ni corta por idle timeout

---

### Fase 4 — Verificación

- [ ] **T-15** — Pruebas de fallo dirigidas en QA (matriz obligatoria)

  | # | Escenario | Resultado esperado |
  |---|---|---|
  | 1 | Cerrar la pestaña justo después de enviar el alta | Contrato creado **y** enlazado; `bs_registro` en `Registrado`; no aparece en pendientes |
  | 2 | Servicio de PDF (gRPC) apagado | 201 con `contractId`; registro enlazado; PDF/flyer se resuelven después o bajo demanda |
  | 3 | LogsMonitor apagado | Alta normal, degradación ≤ 5 s |
  | 4 | Forzar excepción en el enlace | Respuesta de error **con `contractId`** y mensaje de no reintentar |
  | 5 | Doble clic en "Regenerar" | Segundo clic → 409 "ya está en proceso"; sin contrato duplicado |
  | 6 | Fila en `Procesando` con > N minutos | Regenerable de nuevo sin tocar BD |
  | 7 | Dos usuarios llenando formularios en paralelo | Ninguno recibe 429 por culpa del otro |
  | 8 | Folio repetido tras alta exitosa | Rechazo claro (comportamiento actual, sin cambios) |

  - Criterio de completitud: los 8 escenarios pasan y quedan documentados con evidencia (logs + consulta a `bs_registro`)

- [ ] **T-16** — Consulta de verificación post-despliegue (D+1, D+7)
  - `SELECT count(*) FROM bs_registro WHERE id_contrato IS NULL AND fecha_creacion > :fecha_deploy;`
  - Criterio de completitud: cero pendientes nuevos a 7 días del despliegue en producción

---

## 5. Cambios en base de datos

Ninguna migración de esquema. Solo cambian sentencias `UPDATE` existentes (guardas `WHERE`) y se ejecutan actualizaciones puntuales de saneo en la Fase 0.

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `bs_registro` | Datos (una vez) | Saneo del backlog: enlazar huérfanos (grupo A) y liberar `Procesando` (grupo C) |
| `bs_registro` | Índice *(opcional)* | Evaluar índice en `folio_factura` si `ExistsDuplicateInvoiceFolioAsync` (scan con `TRIM`) se vuelve lento al crecer la tabla |

> **Nota multi-país** (`CLAUDE.md`): las tablas `bs_*` son de un flujo exclusivo de México (Bridgestone LATAM sobre la BD MEX). No se toca ningún modelo/`DbSet`, por lo que **no hay nada que replicar en `DataAccessColombia`**. Confirmar antes de mergear.

---

## 6. Endpoints nuevos o modificados

No hay endpoints nuevos. Cambia el **contrato de respuesta** de dos existentes:

| Método | Ruta | Cambio | Estado |
|---|---|---|---|
| POST | `Bridgestone/v1/contracts/{projectId}` | `pdfBase64` deja de venir por defecto (flag); los errores posteriores a la creación incluyen `contractId` | Modificado |
| POST | `Bridgestone/v1/registrations/{idBsRegistro}/contract` | Mismo criterio de `contractId` en errores; claim con expiración | Modificado |
| GET | `Bridgestone/v1/directory/{countries,groups,branches}` | Cambia de política de rate limit `Restrictive` → `Light` | Modificado |

⚠️ El landing ya tolera `pdfBase64 = null` (`sigaService.ts` → `normalizeCreateContractFromRaw`), así que el cambio es compatible; la T-11 solo ajusta el mensaje.

---

## 7. Variables de entorno y configuración

| Variable / clave | Descripción | Ambiente |
|---|---|---|
| `ContractWriteOperation__TimeoutSeconds` | Presupuesto de la ruta de escritura, independiente del cliente (default 180) | QA / Producción |
| `BridgestoneResume__StaleClaimMinutes` | Minutos tras los que un claim `Procesando` se considera vencido (default 10) | QA / Producción |
| `BridgestoneLandingContractDefaults__ReturnPdfInResponse` | Devolver o no `pdfBase64` en el alta (default `false`) | QA / Producción |
| `LogsMonitor__TimeoutSeconds` | Timeout del cliente HTTP de auditoría (default 5) | QA / Producción |
| `BackgroundQueue__Capacity` | Cota de la cola in-process (default 500) | QA / Producción |

Todas se declaran en `appsettings.json` y se bindean a clases de `Options/` (patrón `IOptions<T>`, `CLAUDE.md`). Las de producción se agregan al bloque `environment` de `Infrastructure/prod/Contracts-task-definition.json`. **Ningún secreto nuevo.**

---

## 8. Consideraciones de seguridad

- **Sin cambios de autorización.** Se conservan `Policies.ICanAccessBridgestone`, `Policies.IsGeneralAdmin` y el scope por distribuidor/proyecto.
- **T-12 endurece, no relaja:** el rate limiting particionado impide que un usuario consuma la cuota de todos; los límites numéricos no bajan.
- **ForwardedHeaders (T-12):** al habilitarlo, restringir `KnownProxies`/`KnownNetworks` al rango de la VPC para que un cliente no pueda falsificar su IP vía `X-Forwarded-For`.
- **Datos sensibles:** los mensajes de error que ahora devuelven `contractId` no exponen datos personales; mantener la regla de no serializar bytes de archivos en `LogRequestAsync`.
- **Secrets:** ninguno nuevo. Nota aparte (fuera de alcance, reportar a Dirección de TI): `appsettings.json` y los task definitions tienen credenciales de BD y claves JWT/API en claro dentro del repo — candidato a AWS Secrets Manager (`rules/infraestructura.md` §5).

---

## 9. Consideraciones de infraestructura

- **Sin servicios AWS nuevos.** Solo cambia el sizing de una task existente.
- **Costo:** duplicar CPU/memoria de la task de Contracts (256/512 → 512/1024) aproximadamente **duplica** el costo Fargate de ese servicio. Con 1 task, el orden de magnitud es de unos pocos USD/mes — validar el número exacto en la calculadora antes de aplicar en producción.
- **Cloudflare / Route 53:** sin cambios.
- **Despliegue:** el ApiGateway (KrakenD) requiere redeploy propio si se toca `krakend.json` (T-14).
- **Orden de despliegue sugerido:** Fase 3 (plataforma) → Fase 1 (idempotencia) → Fase 2 (background). Las fases 1 y 2 pueden ir en un solo release si QA valida la matriz completa.

---

## 10. Criterios de aceptación

- [ ] Ningún alta puede dejar `bs_registro.id_contrato = NULL` cuando el contrato ya existe en SIGA (verificado con los escenarios 1, 2 y 4 de la T-15)
- [ ] Cerrar el navegador o perder la conexión a mitad del alta no aborta la creación del contrato
- [ ] El POST de alta responde sin esperar generación de PDF ni envío de flyer
- [ ] Un fallo del servicio de PDF o de LogsMonitor **no** produce registros pendientes
- [ ] Un registro atascado en `Procesando` se libera solo tras N minutos configurables
- [ ] La saturación de cuota de un usuario no afecta a los demás; llenar el formulario no consume cuota de escritura
- [ ] La task de Contracts corre con ≥ 512 CPU / 1024 MB en QA y producción, con idle timeout del ALB explícito
- [ ] Backlog de pendientes saneado y clasificado (Fase 0) con evidencia de que ningún contrato quedó duplicado
- [ ] Cero pendientes nuevos a 7 días del despliegue en producción (T-16)
- [ ] Los servicios Authentication, Catalogs, Claims, Invoices y Reports siguen operando tras el cambio en `Common/RateLimiting`

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| `Common/RateLimiting` es transversal: romper el limitador afecta a los 6 microservicios | Media | Alto | Mantener límites numéricos idénticos; solo agregar partición; regresión mínima por servicio antes de mergear |
| Cambiar la firma de `IContractCreationService` rompe los flujos de BMW | Baja | Alto | Parámetro **opcional** con default `null`; compilar la solución completa y probar un alta BMW en QA |
| Quitar `pdfBase64` cambia la UX del alta sin aviso al usuario final | Media | Medio | Flag de configuración (reversible sin desplegar código) + T-11 en el landing + confirmación de negocio |
| La cola in-process pierde trabajo si el contenedor cae | Media | Bajo | El flyer tiene generación perezosa de respaldo en `GetFlyerById`; solo se pierde el correo automático. Si se vuelve crítico, escalar a NATS (`rules/arquitectura.md` §4) |
| Enlazar huérfanos en la Fase 0 con el contrato equivocado | Baja | Alto | Verificación manual contrato por contrato en SIGA antes de cada UPDATE; nunca ejecutar el cruce en lote |
| Tocar el circuit breaker de KrakenD sin conocer la semántica exacta de la versión desplegada | Media | Medio | Validar contra la doc de la versión y probar en QA antes de producción; el cambio es reversible |
| Subir el sizing de la task incrementa el costo AWS sin tope automático | Alta | Bajo | Aprobación previa de Dirección de TI y monitoreo de facturación |
| El backlog contiene casos donde la factura en S3 no existe | Baja | Medio | La Fase 0 verifica `uri_factura` antes de regenerar |

---

## 12. Notas para el programador

1. **Este plan no crea un PRD.** Nace del análisis de código del 2026-08-12. Si Dirección lo requiere formalmente, generarlo con `/engine-dev-flow` y enlazarlo aquí; el PRD del PJ5796 ya describe el bug en sus §2 y §3 (excluyéndolo explícitamente del alcance de aquel proyecto).
2. **Renombrar la carpeta** `PJ0000-…` con el número real de PJ y actualizar `config.json` (`prd_id`, `prd_dir`).
3. **El orden importa.** La Fase 0 va antes que todo: si primero se despliega la idempotencia, el backlog actual queda igual de ambiguo y se pierde la trazabilidad de qué huérfano venía de antes.
4. **La T-03 es el cambio que realmente cierra el bug.** Todo lo demás reduce probabilidad de fallo; solo el enlace temprano garantiza que un fallo no produzca un huérfano.
5. **BMW tiene el mismo patrón** (`BmwController` + `HttpContext.RequestAborted` + link posterior). Queda fuera de alcance por decisión de acotamiento — abrir ticket de seguimiento.
6. **No refactorizar de más** (`rules/coding-guidelines.md`): no reorganizar `ContractCreationService`, no migrar el SQL crudo de `bs_*` a EF, no tocar el flujo de BMW.
7. **No ejecutar builds ni arranques automáticos** (`CLAUDE.md`): el desarrollador compila y reinicia los servicios.
8. **Validación pendiente antes de ejecutar:** (a) FK real `contrato ↔ vehiculo` para el cruce de la T-01; (b) semántica del `qos/circuit-breaker` en la versión de KrakenD desplegada; (c) aprobación del sizing ECS.
9. **Idioma** (`CLAUDE.md`): código y logs técnicos en inglés; mensajes al usuario final (`message`, `ErrorMessage`) en español.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md` y `CLAUDE.md` de `gp_3.0_siga_api`*
