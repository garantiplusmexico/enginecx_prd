# Plan de Desarrollo — Productos Adicionales: Garantía SIGA en Omega

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Gplus-Seguros/PJ6803-productos-adicionales-garantia-siga/PRD.md` (v0.2) |
| Repositorio | `gp_seguros` (backend) + `frontend-omega` (frontend) |
| Rama base | `develop` |
| Rama | `feature/productos-adicionales-garantia-siga` (creada y publicada en ambos repos) |
| Tipo | Feature |
| Responsable | Alexis Salvador Herrera Garcia |
| Folio PRD | PJ6803 |
| Fecha de generación | 2026-08-18 |
| Estado | Borrador |
| ID plan (BD) | *(pendiente de registrar)* |
| Modelo | claude-opus-5[1m] — esfuerzo: alto |

---

## 1. Resumen técnico

Se integra la **API REST de SIGA** al flujo de cotización y emisión de Omega para vender la garantía de llanta como producto adicional en autos nuevos. Documentación de la API: `gp_seguros/AI/docs/api-siga-integracion-contratos.md`.

Componentes que se crean:

- **`Common/SigaApiClient`** — librería compartida: cliente HTTP tipado de la API de SIGA (login con caché de token, catálogos, cotización, creación de contrato, PDF, consulta por VIN) más `SigaOptions` mapeado por `IOptions<T>`.
- **`Services/cotizador/CotizadorGarantiaSIGA/`** — par de proyectos siguiendo el patrón de los cotizadores de aseguradora: `RequestGarantiaSIGA` (DTOs) + `CotizadorGarantiaSIGAWorker` (`BackgroundService` suscrito a NATS). Nuevo microservicio en ECS.
- Tablas `cotizacion_garantia`, `contrato_garantia` y dos tablas de mapeo de catálogo (`marca_vehiculo_siga`, `modelo_vehiculo_siga`).
- Servicio de emisión de contrato dentro de `Services/polizas/emisiones`.

Componentes que se modifican:

- `Services/cotizador/cotizador_omega` — publicación del mensaje de garantía en `CreateCotizacionV2`, persistencia en `ResponseListenerWorker`, endpoint de consulta.
- `Services/polizas/emisiones` — `emisionDTO` con la decisión de garantía, enganche en `PolizasController.Emitir`, descarga de certificado y reintento.
- `Services/apigateway/krakend.json` — rutas nuevas.
- `Infrastructure/{qa,prod}` — task definition y registro del nuevo servicio.
- `frontend-omega` — `Cotizacion.vue` (costo + check) y `NuevaPolizaCotizacion.vue` / `Poliza.vue` (check en emisión y descarga del certificado).

**Arquitectura**: microservicios en ECS + Fargate con patrón Broker NATS, la misma que ya usa Omega para cotizar con las aseguradoras (`rules/arquitectura.md` §1 y §4). **Stack**: .NET 8 / C# en backend (stack existente), Vue 2.6 + Vuetify en frontend (stack existente del repo), PostgreSQL, Docker + ECS/Fargate, S3 para el PDF del certificado.

---

## 2. Prerequisitos

- [ ] PRD v0.2 validado por el responsable
- [x] Acceso a los repositorios `gp_seguros` y `frontend-omega` confirmado
- [x] `CLAUDE.md` presente en `gp_seguros` (generado en este mismo flujo) y en `frontend-omega`
- [ ] **Bloqueante:** Garantiplus entrega para QA y Producción: usuario/contraseña de la cuenta de integración, `projectId`, y perfil con permisos de **lectura de catálogos + cotización + creación de contrato + descarga de PDF** (§3 de la doc de la API — un `403` con token válido es problema de perfil)
- [ ] **Bloqueante:** Garantiplus confirma `dealerId`, `salesChannelId`, `pointOfSaleId`, `advisorId` y `productTypeId` a usar por Omega, y que ese distribuidor tenga el producto de garantía habilitado (verificable con `GetProductTypesByDealer` y `GetAvailableProducts`)
- [ ] Negocio define la **duración default** de la garantía (meses) y la cantidad de llantas default
- [ ] `frontend-omega` agregado como directorio de trabajo adicional en la sesión de Claude Code (hoy no lo está)
- [ ] Node 16.15.1 disponible vía `nvm use` para compilar el frontend
- [ ] Acceso a la BD de QA para aplicar los cambios de esquema (el repo es DB-first, sin migraciones)

---

## 3. Arquitectura del cambio

La cotización de la garantía **no se resuelve inline en el controlador**: se suma al fan-out NATS existente como un canal más, por las razones del árbol de decisión de `rules/arquitectura.md` §4 — es una consulta a un servicio externo que no puede bloquear ni condicionar la cotización de pólizas.

```
                        POST v2/cotizaciones
                                 │
                    CotizacionesController.CreateCotizacionV2
                                 │
             ┌───────────────────┼─────────────────────────────┐
             │ (por aseguradora) │  (solo si id_tipo_unidad=1) │
             ▼                   ▼                             ▼
   NATS CotizarQualitas   NATS CotizarHDI …        NATS CotizarGarantiaSIGA
             │                   │                             │
   CotizadorQualitasWorker  CotizadorHDIWorker      CotizadorGarantiaSIGAWorker
             │                   │                             │
             │ reply             │ reply                       │ reply
             ▼                   ▼                             ▼
   cotizaciones.async.responses.{idAseg}.{idCot}   cotizaciones.async.garantia.responses.{idCot}
             └───────────────────┬─────────────────────────────┘
                                 ▼
                     ResponseListenerWorker (2 suscripciones)
                                 │
              ┌──────────────────┴──────────────────┐
              ▼                                     ▼
     tabla cotizacion_aseguradora          tabla cotizacion_garantia
              │                                     │
   GET v2/cotizaciones/{id}/aseguradora/{n}   GET v2/cotizaciones/{id}/garantia
              └──────────────────┬──────────────────┘
                                 ▼
                    frontend-omega — Cotizacion.vue (polling 5s)
```

Emisión — orden estricto **póliza primero, contrato después**:

```
POST v1/polizas (emisionDTO + incluye_garantia)
        │
   PolizasController.Emitir → Emitir{Aseguradora}()  →  póliza emitida (fuente de verdad)
        │
        └─ si incluye_garantia y hay cotizacion_garantia vigente
                 │
        SigaWarrantyContractService.CreateAsync()
                 │  timeout ≥ 60s, SIN reintento automático
                 ├─ 201 → contrato_garantia (contractId, total, vigencia) + PDF a S3
                 └─ error → contrato_garantia con estatus Error  (la póliza NO se revierte)
```

**Decisión de diseño clave**: la garantía se modela con **tablas propias**, no reutilizando `cotizacion_aseguradora` ni `aseguradora`. La garantía no es una aseguradora: no tiene prima/recargos/coberturas/recibos y no debe aparecer en reportes, comisiones ni dispersiones que hoy recorren `cotizacion_aseguradora` por `id_aseguradora`. Meterla ahí contaminaría media docena de flujos existentes.

**Decisión de diseño 2**: el worker de garantía **no escribe en BD** — publica su respuesta al reply subject y `ResponseListenerWorker` persiste, igual que los workers de aseguradora. Se mantiene la separación integración / persistencia que ya existe.

---

## 4. Tareas de desarrollo

### Fase 0 — Habilitadores y cliente de SIGA

- [ ] **T-01** — Cerrar prerequisitos con Garantiplus y negocio
  - Entregables: credenciales QA/PROD, `projectId`, ids de canal (`dealerId`, `salesChannelId`, `pointOfSaleId`, `advisorId`), `productTypeId`, duración default y cantidad de llantas default. Confirmación de permisos del perfil.
  - Verificación: `Login` devuelve `200`; `GetProductTypesByDealer/{dealerId}/{projectId}` lista el tipo de garantía; `GetAvailableProducts` devuelve al menos un producto con precio para un vehículo nuevo de prueba.
  - Criterio de completitud: los valores quedan documentados y probados manualmente contra `qa-siga-api.garantiplus.com` antes de escribir código de integración.

- [ ] **T-02** — Crear la librería `Common/SigaApiClient`
  - Archivos a crear: `Common/SigaApiClient/SigaApiClient.csproj`, `Options/SigaOptions.cs`, `Interfaces/ISigaApiClient.cs`, `Services/SigaApiClient.cs`, `Services/SigaTokenProvider.cs`, `Models/Requests/*`, `Models/Responses/*`
  - Alcance: `LoginAsync` con caché de token en memoria (renovación antes de `expiresIn`), `GetAvailableProductsAsync`, `CreateContractAsync`, `GetContractPdfByIdAsync`, `FindContractsByVinAsync`, y los `GetAll*` de catálogo necesarios. `HttpClient` inyectado con timeout configurable (≥ 60s para `CreateContract`).
  - Convención: esta librería es **código nuevo**, va en inglés y PascalCase según `coding-guidelines.md`; los modelos que mapean tablas de Omega siguen el snake_case local del repo.
  - Criterio de completitud: la librería compila, no contiene secretos, y una prueba manual desde un proyecto de consola cotiza y crea un contrato en QA.

- [ ] **T-03** — Resolución y caché de catálogos SIGA
  - Archivos a crear: `Common/SigaApiClient/Services/SigaCatalogCache.cs`, `Interfaces/ISigaCatalogCache.cs`
  - Alcance: caché en memoria con refresco periódico (default 24h) de marcas, modelos por marca, estados, municipios, colonias por CP, tipos de uso y propulsión. Recorrer paginación con `pagination.next` (sin `$top` solo llegan 100 registros). La **cotización nunca se cachea**.
  - Criterio de completitud: la caché resuelve `brandId` y `modelId` a partir de los ids de mapeo, y registra un error explícito (no una excepción silenciosa) cuando no hay correspondencia.

### Fase 1 — Cotización de garantía (backend)

- [ ] **T-04** — Cambios de esquema en PostgreSQL para la cotización
  - Alcance: tablas `cotizacion_garantia`, `marca_vehiculo_siga`, `modelo_vehiculo_siga` (detalle en §5). Script SQL versionado en la carpeta del PRD, no en el repo de código.
  - Criterio de completitud: tablas creadas en la BD de QA, con FK a `cotizacion`, `marca_vehiculo` y `modelo_vehiculo`, y seed inicial de mapeo para las marcas y modelos con mayor volumen.

- [ ] **T-05** — Modelo y `DbContext` de `cotizacion_garantia` en el cotizador
  - Archivos a crear: `Services/cotizador/cotizador_omega/Models/cotizacion_garantia.cs`
  - Archivos a modificar: `Services/cotizador/cotizador_omega/Models/cotizaciones_dbContext.cs`
  - Criterio de completitud: el `DbSet` está registrado con `ToTable`/`HasKey(...).HasName("cotizacion_garantia_pkey")` y `repo.All<cotizacion_garantia>()` consulta sin error.

- [ ] **T-06** — Nuevo worker `CotizadorGarantiaSIGA`
  - Archivos a crear:
    - `Services/cotizador/CotizadorGarantiaSIGA/RequestGarantiaSIGA/RequestGarantiaSIGA.csproj`, `GarantiaSigaCotizacionRequestDTO.cs`, `GarantiaSigaCotizacionResponseDTO.cs`
    - `Services/cotizador/CotizadorGarantiaSIGA/CotizadorGarantiaSIGAWorker/{CotizadorGarantiaSIGAWorker.csproj, Program.cs, Worker.cs, appsettings.json, Dockerfile, build.ps1}`
  - Alcance: `BackgroundService` suscrito a `CotizarGarantiaSIGA`; construye los parámetros de `GetAvailableProducts` (`ProductTypeId`, `DealerId`, `BrandId`, `VehicleYear`, `RegistrationDate`, `Duration`, `TireCount`, `TireDuration`, `HasFactoryWarranty`, `ServicesOnTime`, `MonthsWithoutInterest=0`), llama a SIGA vía `SigaApiClient` y publica la respuesta (producto, precio, min/max meses) o el error en el reply subject. OpenTelemetry y `ILogger` como en `CotizadorPOTOSIWorker`.
  - Referencia: `AI/prompts/generar-nuevo-worker-aseguradora-soap.md` para la estructura (adaptando SOAP → REST).
  - Criterio de completitud: con NATS local, publicar un mensaje de prueba en `CotizarGarantiaSIGA` produce una respuesta con `productId` y `price` en el reply subject.

- [ ] **T-07** — Publicar la cotización de garantía desde `CreateCotizacionV2`
  - Archivos a modificar: `Services/cotizador/cotizador_omega/Controllers/CotizacionesController.cs`, `Services/cotizador/cotizador_omega/appsettings.json`
  - Alcance: método privado `PublicarCotizacionGarantiaAsync` que publica en `CotizacionesPublisher:CotizarGarantiaSIGASubject` **solo si** `request.id_tipo_unidad == (int)TipoUnidadEnum.TiposUnidad.Nueva`. Se inserta el registro `cotizacion_garantia` con estatus `Solicitada` antes de publicar. No se toca el flujo V1.
  - Criterio de completitud: una cotización de auto nuevo genera un registro `Solicitada` y un mensaje NATS; una de seminuevo no genera ninguno de los dos; en ambos casos la respuesta sigue siendo `202` con los mismos campos que hoy.

- [ ] **T-08** — Persistir la respuesta en `ResponseListenerWorker`
  - Archivos a modificar: `Services/cotizador/cotizador_omega/Workers/ResponseListenerWorker.cs`, `appsettings.json`
  - Alcance: segunda suscripción a `cotizaciones.async.garantia.responses.>`; actualiza `cotizacion_garantia` a `Cotizada` (con `product_id`, `product_name`, `precio`, `duracion_meses`, `min_meses`, `max_meses`) o a `Error` con el mensaje. Guarda `json_envio`/`json_recibido` sin datos personales.
  - Criterio de completitud: el registro pasa de `Solicitada` a `Cotizada` o `Error` sin afectar el procesamiento de las respuestas de aseguradora.

- [ ] **T-09** — Endpoint de consulta de la cotización de garantía
  - Archivos a modificar: `Services/cotizador/cotizador_omega/Controllers/CotizacionesController.cs`, `Services/apigateway/krakend.json`
  - Alcance: `GET v2/cotizaciones/{id}/garantia` → `200` con el detalle, `204` si sigue `Solicitada`, `404` si no aplica (seminuevo). `[Authorize]` con los mismos roles que `GetAseguradoraV2`.
  - Criterio de completitud: los tres códigos se reproducen desde el gateway, y `krakend.json` valida como JSON.

- [ ] **T-10** — Infraestructura del nuevo microservicio
  - Archivos a crear: `Infrastructure/qa/Quoter-GarantiaSIGA-task-definition.json`, `Infrastructure/prod/Quoter-GarantiaSIGA-task-definition.json`
  - Archivos a modificar: `Infrastructure/qa/deploy-services-v2.ps1`, `Infrastructure/prod/deploy-services-v2.ps1` (arreglo `$SERVICES`)
  - Alcance: servicio ECS `gp-omega-quoter-garantia-siga-service`, con las variables de SIGA inyectadas por el task definition apuntando a Secrets Manager.
  - Criterio de completitud: el script de despliegue reconoce el servicio y el contenedor arranca en QA reportando sano.

### Fase 2 — Cotización de garantía (frontend)

- [ ] **T-11** — Polling de la cotización de garantía
  - Archivos a modificar: `src/views/ventas/cotizaciones/Cotizacion.vue`
  - Alcance: en `inicializarComponentes`, si la cotización es de unidad nueva, arrancar un `_pollGarantia` con el mismo patrón que `_pollAseguradora` (5s, máx. 15 intentos) contra `v2/cotizaciones/${id}/garantia`. Estados: cargando / disponible / no disponible.
  - Criterio de completitud: la sección refleja los tres estados sin bloquear ni retrasar el render de las tarjetas de aseguradora.

- [ ] **T-12** — Tarjeta de garantía con costo y check
  - Archivos a modificar: `src/views/ventas/cotizaciones/Cotizacion.vue`
  - Alcance: `v-card` con nombre del producto, costo formateado, duración en meses y un `v-checkbox` "Incluir garantía". Si la garantía no está disponible, se muestra el aviso y el check queda deshabilitado.
  - Criterio de completitud: se ve consistente con las tarjetas existentes en desktop y móvil, y `npm run lint` pasa limpio.

- [ ] **T-13** — Arrastrar la decisión a la emisión
  - Archivos a modificar: `src/views/ventas/cotizaciones/Cotizacion.vue`, `src/store/modules/cotizaciones/index.js`
  - Alcance: al navegar a la emisión, propagar `incluye_garantia` y `id_cotizacion_garantia` por el store (no por localStorage).
  - Criterio de completitud: la pantalla de emisión abre con el check en el estado elegido en la cotización.

### Fase 3 — Emisión del contrato en SIGA (backend)

- [ ] **T-14** — Cambios de esquema para el contrato
  - Alcance: tabla `contrato_garantia` (detalle en §5), con índice por `id_poliza` y por `contract_id_siga`.
  - Criterio de completitud: tabla creada en QA con FK a `poliza`.

- [ ] **T-15** — Modelo, `DbContext` y DTO de emisión
  - Archivos a crear: `Services/polizas/emisiones/Models/contrato_garantia.cs`, `Services/polizas/emisiones/Models/DTO/cotizacion_garantiaDTO.cs`
  - Archivos a modificar: `Services/polizas/emisiones/Models/emision_dbContext.cs`, `Services/polizas/emisiones/Models/DTO/emisionDTO.cs` (campos `incluye_garantia` y `id_cotizacion_garantia`)
  - Criterio de completitud: el payload de emisión acepta los campos nuevos y una emisión sin ellos sigue funcionando igual (retrocompatible).

- [ ] **T-16** — Servicio de creación de contrato
  - Archivos a crear: `Services/polizas/emisiones/Services/SigaWarrantyContractService.cs`, `Interfaces/ISigaWarrantyContractService.cs`, `Models/Siga/WarrantyContractPayloadFactory.cs`
  - Alcance: arma los bloques `channel`, `beneficiary`, `vehicle`, `product` y `tireLines` desde `persona`, `vehiculo_poliza`, `poliza` y `cotizacion_garantia`; aplica la **convención de defaults** (`"Valor default"` para texto, `-1` para numérico) solo en campos no validados por catálogo; y **valida antes de enviar** las reglas de SIGA que se pueden verificar localmente (`personType` exactamente `Fisica`/`Moral`, VIN de 17 caracteres en mayúsculas, RFC 12–13, mayor de 18 años, `startDate` no pasada, `durationMonths` dentro de `minMonths`–`maxMonths`, año entre año actual −30 y +1).
  - Criterio de completitud: el payload generado para un caso de persona física y otro de persona moral es aceptado por `CreateContract` en QA, y las validaciones locales rechazan los casos límite con un mensaje claro antes de gastar la llamada.

- [ ] **T-17** — Enganche en `PolizasController.Emitir`
  - Archivos a modificar: `Services/polizas/emisiones/Controllers/PolizasController.cs`
  - Alcance: después de que `model != null` (póliza emitida) y antes de devolver `Created`, si `request.incluye_garantia` es `true` y existe una `cotizacion_garantia` en estatus `Cotizada` y vigente, invocar el servicio. Éxito → `contrato_garantia` con `contract_id_siga`, `total`, vigencia y `url_pdf_certificado` en S3 (usando `pdfBase64` si vino, o `GetContractPdfById` reintentando cada pocos segundos si vino `null`). Error → `contrato_garantia` con estatus `Error` y el mensaje. **En ningún caso se revierte la póliza ni se cambia el código de respuesta de la emisión**; el resultado del contrato se informa como parte del cuerpo de la respuesta.
  - Criterio de completitud: emisión con garantía crea póliza + contrato; emisión con garantía forzando error de SIGA crea la póliza igual, devuelve `201` y deja el error registrado.

- [ ] **T-18** — Descarga del certificado y reintento manual
  - Archivos a modificar: `Services/polizas/emisiones/Controllers/PolizasController.cs`, `Services/apigateway/krakend.json`
  - Alcance: `GET v1/polizas/{id}/download-certificado-garantia` (mismo patrón que `GetDownloadPolizaById`) y `POST v1/polizas/{id}/contrato-garantia/reintentar` restringido a `Administrador General,Mesa de control`. El reintento **debe verificar primero por VIN** con `FindContractsByVinAsync` y abortar si ya existe un contrato vigente que se empalma (evita el `409` y los duplicados).
  - Criterio de completitud: el reintento sobre un contrato ya creado no genera duplicado y responde con el `contractId` existente.

- [ ] **T-19** — Wire-up y configuración de emisiones
  - Archivos a modificar: `Services/polizas/emisiones/Program.cs`, `appsettings.json`, `Infrastructure/{qa,prod}/Policies-task-definition.json`
  - Alcance: registrar `ISigaApiClient`, `ISigaCatalogCache` e `ISigaWarrantyContractService` en el contenedor; `HttpClient` con timeout ≥ 60s; variables de SIGA por entorno. **Ningún secreto nuevo en `appsettings.json`.**
  - Criterio de completitud: el servicio arranca en QA leyendo la configuración de SIGA desde variables de entorno.

### Fase 4 — Emisión (frontend)

- [ ] **T-20** — Check de garantía en la pantalla de emisión
  - Archivos a modificar: `src/views/ventas/polizas/NuevaPolizaCotizacion.vue`
  - Alcance: mostrar producto y costo de la garantía, con el check en el estado heredado de la cotización y editable; agregar `incluye_garantia` e `id_cotizacion_garantia` a `objeto_insertar`.
  - Criterio de completitud: emitir con y sin garantía envía el payload correcto; si la cotización no tiene garantía, la sección no aparece.

- [ ] **T-21** — Certificado en la vista de póliza
  - Archivos a modificar: `src/views/ventas/polizas/Poliza.vue`
  - Alcance: bloque de garantía con `contractId`, vigencia, total y botón de descarga del certificado. Si el contrato quedó en error, mostrar el estado y (para Mesa de Control) el botón de reintento.
  - Criterio de completitud: la descarga entrega el PDF y el estado de error es visible sin ambigüedad.

### Fase 5 — Pruebas, observabilidad y despliegue

- [ ] **T-22** — Pruebas end-to-end en QA
  - Alcance: matriz mínima — auto nuevo con garantía cotizada y emitida; auto nuevo con garantía deseleccionada; auto seminuevo (sin garantía); SIGA caído en cotización; SIGA con `400` en creación de contrato; timeout en `CreateContract` con contrato creado (verificar que el reintento no duplica); persona física y persona moral; `pdfBase64` en `null`.
  - Criterio de completitud: los nueve escenarios documentados con evidencia en la carpeta del PRD.

- [ ] **T-23** — Eventos de BI y logging
  - Archivos a modificar: los controladores y el worker involucrados
  - Alcance: emitir los eventos de §11 del PRD (`cotizacion_garantia_solicitada/obtenida/error`, `garantia_incluida/excluida`, `contrato_garantia_emitido/error`) por el mismo `loggingService` que ya usa Omega. **Sin datos personales en logs** (RFC, domicilio, VIN completo).
  - Criterio de completitud: los eventos aparecen en el monitor de logs con `id_cotizacion`/`id_poliza`, monto y resultado.

- [ ] **T-24** — Despliegue a QA y validación
  - Alcance: secrets de SIGA en AWS Secrets Manager, task definitions aplicados, `pre-qa` → `qa` según el gitflow de Engine, y verificación de que el nuevo servicio y los modificados arrancan sanos.
  - Criterio de completitud: flujo completo validado por el responsable en el ambiente de QA.

---

## 5. Cambios en base de datos

Repo DB-first sin migraciones: los cambios se aplican con SQL en la BD y se reflejan a mano en modelos y `DbContext`.

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `cotizacion_garantia` | Nueva | `id_cotizacion_garantia` (PK), `id_cotizacion` (FK), `estatus` (`Solicitada`/`Cotizada`/`Error`), `fecha_solicitud`, `fecha_respuesta`, `product_type_id`, `product_id`, `product_name`, `precio`, `duracion_meses`, `min_meses`, `max_meses`, `error`, `json_envio`, `json_recibido`, `activo` |
| `contrato_garantia` | Nueva | `id_contrato_garantia` (PK), `id_poliza` (FK), `id_cotizacion_garantia` (FK), `contract_id_siga`, `estatus`, `fecha_registro`, `product_name`, `inicio_vigencia`, `fin_vigencia`, `total`, `url_pdf_certificado`, `error`, `json_envio`, `json_recibido` |
| `marca_vehiculo_siga` | Nueva | `id_marca` (FK a `marca_vehiculo`), `brand_id_siga`, `activo` — mapeo Omega ↔ SIGA |
| `modelo_vehiculo_siga` | Nueva | `id_modelo` (FK a `modelo_vehiculo`), `model_id_siga`, `activo` — mapeo Omega ↔ SIGA |
| `cotizacion_garantia` | Índice | Índice por `id_cotizacion` (lo consulta el polling del frontend) |
| `contrato_garantia` | Índice | Índices por `id_poliza` y por `contract_id_siga` |

`marca_vehiculo_siga` y `modelo_vehiculo_siga` no se pueden sustituir por valores default: `BrandId` afecta el precio que devuelve `GetAvailableProducts`, y `modelId` debe pertenecer al `brandId` o SIGA rechaza el contrato con `400`.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `v2/cotizaciones/{id}/garantia` | Cotización de garantía: producto, precio, vigencia, estatus. `204` mientras está en proceso, `404` si no aplica | Nuevo |
| POST | `v1/polizas` | Se agregan `incluye_garantia` e `id_cotizacion_garantia` al `emisionDTO`. Retrocompatible | Modificado |
| GET | `v1/polizas/{id}/download-certificado-garantia` | Descarga el PDF del certificado desde S3 | Nuevo |
| POST | `v1/polizas/{id}/contrato-garantia/reintentar` | Reintenta la creación del contrato verificando primero por VIN. Solo `Administrador General` y `Mesa de control` | Nuevo |

Los cuatro requieren su entrada correspondiente en `Services/apigateway/krakend.json`.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `SIGA__BaseUrlAuthentication` | Base de `/authentication` (QA: `https://qa-siga-api.garantiplus.com`) | Desarrollo / QA / Producción |
| `SIGA__BaseUrlCatalogs` | Base de `/catalogs` | Desarrollo / QA / Producción |
| `SIGA__BaseUrlContracts` | Base de `/contracts` | Desarrollo / QA / Producción |
| `SIGA__Username` | Usuario de integración — **Secrets Manager** | QA / Producción |
| `SIGA__Password` | Contraseña — **Secrets Manager** | QA / Producción |
| `SIGA__ProjectId` | `projectId` asignado por Garantiplus | Desarrollo / QA / Producción |
| `SIGA__DealerId` | Distribuidor de Omega en SIGA | Desarrollo / QA / Producción |
| `SIGA__SalesChannelId` | Canal de venta (catálogo de referencia: `1` = Nuevo) | Desarrollo / QA / Producción |
| `SIGA__PointOfSaleId` | Punto de venta (debe pertenecer al `dealerId`) | Desarrollo / QA / Producción |
| `SIGA__AdvisorId` | Asesor (debe pertenecer al `dealerId`) | Desarrollo / QA / Producción |
| `SIGA__ProductTypeId` | Tipo de producto de garantía de llanta | Desarrollo / QA / Producción |
| `SIGA__DurationMonths` | Duración default de la garantía en meses | Desarrollo / QA / Producción |
| `SIGA__TireCount` | Cantidad de llantas default (propuesto: `4`) | Desarrollo / QA / Producción |
| `SIGA__HasFactoryWarranty` | Default para auto nuevo (propuesto: `true`) | Desarrollo / QA / Producción |
| `SIGA__ServicesOnTime` | Default para auto nuevo (propuesto: `true`) | Desarrollo / QA / Producción |
| `SIGA__DefaultText` | Texto default para campos sin origen (`Valor default`) | Desarrollo / QA / Producción |
| `SIGA__DefaultNumber` | Numérico default para campos sin origen (`-1`) | Desarrollo / QA / Producción |
| `SIGA__ContractTimeoutSeconds` | Timeout de `CreateContract` (mínimo `60`) | Desarrollo / QA / Producción |
| `SIGA__CatalogCacheHours` | Refresco de la caché de catálogos (propuesto: `24`) | Desarrollo / QA / Producción |
| `CotizacionesPublisher__CotizarGarantiaSIGASubject` | Subject NATS de publicación (`CotizarGarantiaSIGA`) | Desarrollo / QA / Producción |
| `CotizacionesPublisher__GarantiaResponsesSubjectPrefix` | Prefijo de reply (`cotizaciones.async.garantia.responses`) | Desarrollo / QA / Producción |

---

## 8. Consideraciones de seguridad

- **Secrets**: `SIGA__Username` y `SIGA__Password` van exclusivamente en AWS Secrets Manager, referenciados desde el task definition. El repo ya tiene credenciales comiteadas en `appsettings.json` (deuda existente) — **no se agrega ninguna nueva** por esta feature.
- **Autorización**: `GET v2/cotizaciones/{id}/garantia` con los mismos roles que `GetAseguradoraV2`. El reintento de contrato se restringe a `Administrador General` y `Mesa de control` porque crea un contrato con costo en un sistema externo.
- **Datos personales enviados a SIGA**: RFC, domicilio completo, fecha de nacimiento, VIN y número de motor viajan en `CreateContract`. Todo sobre HTTPS. **No se registran en logs ni en `json_envio`**: el payload persistido debe guardarse enmascarado (RFC y VIN parciales, sin domicilio).
- **PDF del certificado**: se guarda en el bucket S3 de la consola de GPLUS Seguros con el mismo patrón de prefijos y permisos que las pólizas. No se expone por URL pública — se sirve por el endpoint autenticado.
- **IAM**: sin permisos nuevos más allá de `s3:PutObject`/`GetObject` sobre el prefijo del certificado para el rol de tarea del servicio de emisiones, y lectura del secret de SIGA para los roles de tarea del cotizador de garantía y de emisiones.

---

## 9. Consideraciones de infraestructura

- **Un microservicio ECS nuevo**: `gp-omega-quoter-garantia-siga-service` en el cluster `qa-apiomega` y su equivalente en producción. Es un worker sin tráfico HTTP entrante (no requiere target group en el ALB), dimensionable con la misma CPU/memoria que los cotizadores existentes — el más pequeño del cluster, ya que solo hace una llamada REST por cotización de auto nuevo.
- **Costo estimado**: incremental bajo — una tarea Fargate adicional por ambiente, del mismo tamaño que `gp-omega-quoter-potosi-service`. Sin recursos AWS de otro tipo.
- **RDS**: cuatro tablas nuevas, volumen despreciable (un registro por cotización de auto nuevo, uno por contrato emitido).
- **S3**: un PDF por contrato emitido, en el bucket existente. Sin bucket nuevo.
- **NATS**: un subject de publicación y un prefijo de reply nuevos en el broker existente (`gp_omega_nats`). Sin cambios de infraestructura del broker.
- **Cloudflare / Route 53**: sin cambios.
- ⚠️ Recordatorio de `rules/infraestructura.md`: AWS no tiene tope automático de gasto. El servicio nuevo debe quedar incluido en el monitoreo de facturación del cluster.

---

## 10. Criterios de aceptación

- [ ] Una cotización de **auto nuevo** genera además la cotización de garantía contra SIGA y el frontend muestra su producto, costo y vigencia
- [ ] Una cotización de **auto seminuevo** no genera cotización de garantía y la pantalla no muestra la sección
- [ ] Si SIGA no responde o devuelve error al cotizar, las cotizaciones de las aseguradoras se muestran normalmente y la sección de garantía indica que no está disponible
- [ ] El agente puede incluir o excluir la garantía desde la cotización, y la decisión llega correctamente a la pantalla de emisión
- [ ] Emitir con la garantía incluida produce la póliza de la aseguradora **y** el contrato en SIGA, con `contractId` y certificado en PDF descargable
- [ ] Emitir con la garantía excluida produce únicamente la póliza, sin llamada a `CreateContract`
- [ ] Si la creación del contrato falla, la póliza queda emitida y válida, la respuesta sigue siendo `201`, y el error queda registrado y visible
- [ ] El reintento de un contrato fallido verifica por VIN y nunca genera un contrato duplicado
- [ ] Los campos sin origen en Omega llegan a SIGA como `"Valor default"` o `-1`, y ningún id de catálogo se envía con `-1`
- [ ] Los eventos de BI de §11 del PRD se registran, sin datos personales en los logs
- [ ] `krakend.json` valida como JSON y todos los endpoints nuevos responden a través del gateway
- [ ] `npm run lint` pasa limpio en `frontend-omega` y todos los `.csproj` tocados compilan

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Permisos del perfil de la cuenta de SIGA incompletos (`403` con token válido) | Alta | Alto | T-01 valida el flujo completo contra QA **antes** de escribir código de integración |
| Póliza emitida sin contrato de garantía | Media | Alto | Orden póliza→contrato, error registrado, endpoint de reintento con verificación por VIN (T-18) |
| Timeout en `CreateContract` con el contrato ya creado → duplicado | Media | Alto | Timeout ≥ 60s, sin reintento automático, verificación obligatoria por VIN antes de cualquier reintento |
| Mapeo de marca/modelo incompleto → precio incorrecto o `400` | Alta | Medio | Tablas de mapeo explícitas con seed de las marcas de mayor volumen, y error explícito cuando no hay correspondencia (nunca un default silencioso) |
| `tireLines` con valores default rechazados por longitud mínima (`tireSize` mín. 5 caracteres) | Media | Medio | `"Valor default"` cumple las longitudes mínimas documentadas; validar en T-01 con una creación real en QA antes de fijar la convención |
| `GetAvailableProducts` devuelve `[]` para combinaciones válidas | Media | Medio | Registrar los parámetros enviados y el vacío como estatus `Error` con motivo, no como excepción; escalar a Garantiplus la configuración del distribuidor |
| Cambios en `PolizasController.cs` (~4,700 líneas) introducen regresión en emisión | Media | Alto | Toda la lógica nueva vive en `SigaWarrantyContractService`; en el controlador solo un bloque condicional aislado, después de la emisión exitosa. Sin refactor del código existente |
| El repo no tiene suite de pruebas automatizadas | Alta | Medio | La verificación es la matriz manual de T-22 con evidencia; considerar pruebas unitarias del `WarrantyContractPayloadFactory` (es lógica pura y testeable) |
| Paginación de catálogos SIGA truncada a 100 registros | Media | Medio | Recorrer `pagination.next` en `SigaCatalogCache` (T-03) y validar el total contra `odata_count` |
| `frontend-omega` requiere Node 16.15.1 | Baja | Bajo | `nvm use` documentado en su `CLAUDE.md`; el build falla con Node moderno |

---

## 12. Notas para el programador

- **Convención de defaults, con una excepción crítica.** La regla acordada es `"Valor default"` para texto y `-1` para numérico. Pero SIGA valida contra sus propios catálogos `dealerId`, `salesChannelId`, `pointOfSaleId`, `advisorId`, `stateId`, `municipalityId`, `brandId`, `modelId`, `usageTypeId` y `propulsionTypeId`: un `-1` ahí devuelve `400` con `"... con ID -1 no encontrado"`. Esos diez campos **siempre** llevan valores reales (configuración o mapeo). El default aplica a `tireBrand`, `tireModel`, `tireSize`, `dot`, `versionText`, `licensePlate`, `kilometers`, `horsepower` y `cubicCapacity`.
- **`BrandId` no es cosmético**: entra en el cálculo de precio de `GetAvailableProducts`. Un mapeo equivocado no falla — cotiza mal. Por eso el mapeo es tabla, no default.
- **No refactorizar** `CotizacionesController.cs` ni `PolizasController.cs` aunque estén muy por encima del límite de 200 líneas de las guidelines. Es deuda conocida y el PRD no la incluye.
- **Idioma del código**: `Common/SigaApiClient` es código nuevo y aislado → inglés/PascalCase según `coding-guidelines.md`. Los modelos que mapean tablas de Omega (`cotizacion_garantia`, `contrato_garantia`) siguen el snake_case en español del repo, porque espejan columnas de PostgreSQL. No mezclar los dos estilos dentro de un mismo archivo.
- **El flujo V1 de cotización no se toca.** La garantía existe solo en V2, que es el camino que usa el frontend actual.
- **Dos repos, una feature.** La rama `feature/productos-adicionales-garantia-siga` debe crearse también en `frontend-omega` desde su `develop`, y ambas avanzan a `pre-qa` → `qa` juntas: el frontend con el check no sirve sin el backend y viceversa.
- **`frontend-omega` no está en los directorios de trabajo de la sesión.** Hay que agregarlo antes de ejecutar las fases 2 y 4.
- **A validar antes de ejecutar**: ¿un solo `dealerId` para todo Omega, o uno por agencia/empresa? El plan asume uno solo por configuración. Si negocio quiere trazabilidad por agencia, hace falta una tabla de mapeo `empresa` → `dealerId` y sube el alcance de la Fase 0 en ~2 días.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Habilitadores y cliente de SIGA (P1)** | Prerequisitos con Garantiplus, `Common/SigaApiClient`, caché de catálogos | T-01 a T-03 | 3 – 5 días | |
| **Fase 1 — Cotización de garantía · backend (P1)** | Esquema, modelo, worker `CotizadorGarantiaSIGA`, publicación NATS, persistencia, endpoint, infraestructura ECS | T-04 a T-10 | 6 – 9 días | |
| **Fase 2 — Cotización de garantía · frontend (P2)** | Polling, tarjeta con costo y check, arrastre de la decisión | T-11 a T-13 | 3 – 4 días | |
| **Fase 3 — Emisión del contrato · backend (P2)** | Esquema, DTO, `SigaWarrantyContractService`, enganche en `Emitir`, descarga y reintento, wire-up | T-14 a T-19 | 6 – 9 días | |
| **Fase 4 — Emisión · frontend (P3)** | Check en emisión, certificado en la vista de póliza | T-20 a T-21 | 2 – 3 días | |
| **Fase 5 — Pruebas, observabilidad y despliegue (P3)** | Matriz de 9 escenarios en QA, eventos de BI, despliegue | T-22 a T-24 | 3 – 4 días | |
| **Total proyecto (P1+P2+P3)** | | 24 tareas | ~23 – 34 días hábiles (≈ 5 – 7 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-10 | ~9 – 14 días hábiles (≈ 2 – 3 semanas) | — |

> **Notas sobre la tabla:**
> - P1 entrega la cotización de garantía funcionando de punta a punta en backend y verificable por API. Es el hito que demuestra que la integración con SIGA es viable, y el que desbloquea todo lo demás.
> - P2 hace la feature visible y emitible: sin P2 no hay valor para el agente. **P1+P2 es el MVP mínimo comercializable** (~18 – 27 días hábiles).
> - P3 completa la experiencia (certificado descargable, reintento visible) y cierra el despliegue.
> - La Fase 0 incluye T-01, que es una **dependencia externa** (Garantiplus). Si las credenciales y permisos tardan, el rango se corre día por día: no hay forma de avanzar Fase 1 sin ellos.

> **Riesgo de deadline:** el PRD **no define una fecha límite**. Con un solo desarrollador el alcance completo cae en ~5 – 7 semanas de trabajo efectivo. Si negocio fija una fecha más agresiva, la recomendación es entregar **P1+P2** (cotización + emisión funcionando, ~4 – 5.5 semanas) y dejar P3 para un segundo corte. Un segundo desarrollador aportaría una compresión de aproximadamente 30–35%, no 50%: las fases 0 y 1 son mayormente secuenciales (todo depende del cliente de SIGA), pero las fases 2 y 3 sí son paralelizables — un dev en backend de emisión y otro en frontend a partir del cierre de la Fase 1.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
