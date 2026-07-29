# Plan de Desarrollo — Bridgestone: Regeneración de contratos pendientes (admin general)

> Generado por Claude Code a partir de `PRD.md`. Punto de partida para la ejecución; el programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/bridgestone-regeneracion-contratos-pendientes/PRD.md` |
| Repositorios | **gp_3.0_siga_api** (backend + gateway) y **bridgestone_landing** (frontend) — feature multi-repo |
| Rama base | `develop` (existe en ambos repos) |
| Ramas funcionales | `feature/ECX-XXX-bridgestone-regenerar-contratos-pendientes` (misma en ambos repos; sustituir ECX-XXX por el ticket real) |
| Tipo | Feature (herramienta operativa que remedia bug de contratos huérfanos) |
| Responsable | Carlos Castellanos |
| Fecha de generación | 2026-07-14 |
| Estado | Borrador |

---

## 1. Resumen técnico

- **Backend (gp_3.0_siga_api, servicio Contracts, .NET 8):** 2 endpoints nuevos en `BridgestoneController` (listar pendientes + regenerar), un servicio orquestador de resume, un lector full-row de `bs_registro`/`bs_llantas` (SQL crudo), refactor mínimo del factory para reconstruir el request desde el registro, y variantes del servicio de registro (claim atómico + link que propaga). Reutiliza `ContractCreationService.CreateContractAsync`, `NotifyBridgestoneFlyerAsync` y la UPDATE de enlace existentes.
- **Gateway (KrakenD, `Services/ApiGateway/krakend.json`):** registrar las 2 rutas nuevas (declara endpoint por endpoint) + redeploy del ApiGateway. El gateway local (YARP) es catch-all → sin cambios.
- **Frontend (bridgestone_landing, React 19 + Vite + TS):** nueva sección "Contratos pendientes / Regeneración" (step + rutas + vista `PendingContractsView`), 2 métodos de API, tipos, gate de rol admin (UX) y accesos.
- **Arquitectura:** microservicios en ECS (se respeta la existente); no se crean servicios ni infra nueva (ver §3, §9). Stack respetado: .NET 8 + PostgreSQL (SQL crudo, sin EF para `bs_*`) + React.

---

## 2. Prerequisitos

- [x] PRD validado (revisado por el responsable; corrección de gateway incorporada)
- [x] Acceso a ambos repositorios confirmado
- [x] Rama base `develop` disponible en ambos repos
- [ ] Ticket ECX-XXX asignado (para nombrar ramas y commits)
- [ ] Confirmar clave exacta del claim de rol en el JWT (decodificar un token real) — ver T-12
- [ ] **Desviaciones del flujo estándar (validar):**
  - `CLAUDE.md`: en **gp_3.0_siga_api** SÍ existe, pero vive en una rama nueva pendiente de integrar (todavía no está en la rama actual/`develop`) → no requiere `/init`. En **bridgestone_landing** NO existe → correr `/init` en ese repo antes o durante la ejecución. No se ejecutó automáticamente porque la sesión está enraizada en bmw_landing y `/init` apuntaría al directorio equivocado; el plan se generó con contexto verificado en esta sesión (exploración directa de ambos repos con referencias file:line reales).
  - No se hizo `git checkout develop`/`pull` para no sacar a `gp_3.0_siga_api` de su rama activa `feature/cc_bmw_productos_care_plus` (limpia). El posicionamiento en `develop` + creación de la rama funcional se hace en la ejecución (Fase 0).

---

## 3. Arquitectura del cambio

Se respeta la arquitectura de **microservicios en ECS** de la API de SIGA (`rules/arquitectura.md` §1) y el patrón **Frontend + Backend separados** del landing. No se introduce arquitectura nueva. La autorización usa el patrón existente de JWT + policies + scope de Bridgestone.

```
Landing BS (React, sección "Pendientes")
   │  GET  /contracts/api/Bridgestone/v1/registrations/pending/{projectId}
   │  POST /contracts/api/Bridgestone/v1/registrations/{idBsRegistro}/contract
   ▼
API Gateway (KrakenD)  ──►  Contracts service (gp_api_contracts)
                                 │  BridgestoneController (doble candado admin)
                                 │  → BridgestoneContractResumeService
                                 │      → lee bs_registro + bs_llantas (SQL)
                                 │      → BuildFromRegistroAsync (factory)
                                 │      → ContractCreationService.CreateContractAsync
                                 │      → LinkContractToRegistration (propaga) + NotifyBridgestoneFlyer
                                 ▼
                          PostgreSQL (contrato/poliza/vehiculo, bs_registro) + S3 (factura ya existente)
```

---

## 4. Tareas de desarrollo

### Fase 0 — Preparación (ejecución)
- [ ] **T-00** — Posicionar y crear ramas funcionales en ambos repos.
  - `gp_3.0_siga_api` y `bridgestone_landing`: `git checkout develop && git pull origin develop && git checkout -b feature/ECX-XXX-bridgestone-regenerar-contratos-pendientes`.
  - (Recomendado) `/init` en **bridgestone_landing** (no tiene `CLAUDE.md`). En `gp_3.0_siga_api` ya existe en una rama por integrar; asegurar que esté presente al crear la rama funcional.
  - Criterio: rama funcional creada desde `develop` actualizado en ambos repos.

### Fase 1 — Backend: listado de pendientes (solo lectura, bajo riesgo)
- [ ] **T-01** — DTO de respuesta de pendientes.
  - Crear `Services/Contracts/DTOs/Bridgestone/Responses/BridgestonePendingRegistrationListResponses.cs` (`IdBsRegistro`, `DealerName`, `Country`, `Group`, `Branch`, `InvoiceFolio`, `CreatedDate`, `CustomerName`, `Estatus`).
  - Criterio: compila; XML docs en inglés.
- [ ] **T-02** — Consulta de pendientes + derivación de proyecto.
  - Modificar `Services/Contracts/Services/Bs/BridgestoneBsRegistroQueryService.cs` (+ interfaz): `ListPendingAsync(projectId)` (`WHERE r.id_contrato IS NULL AND (d.id_proyecto=@p OR r.id_distribuidor IS NULL)`; `CustomerName` compuesto en C#: Moral→`nombre`, Física→`nombre+apellidos`) y `GetProjectIdForDistributorAsync(distributorId)`. SQL parametrizado.
  - Criterio: devuelve los registros con `id_contrato` NULL del proyecto, con `id_bs_registro`.
- [ ] **T-03** — Endpoint GET de pendientes (doble candado + auditoría).
  - Modificar `Services/Contracts/Controllers/BridgestoneController.cs`: `GET v1/registrations/pending/{projectId:int}`, `[Authorize(Policy = Policies.IsGeneralAdmin)]` + guard `if (scope.Kind != BridgestoneAccessFilterKind.None) return Forbid();`, `LogRequestAsync`/`LogResponseAsync`, `ProducesResponseType` (200/401/403/500), orden de atributos por guía.
  - Criterio: admin general recibe la lista; no-admin → 403.
- [ ] **T-04** — Registrar ruta GET en KrakenD.
  - Modificar `Services/ApiGateway/krakend.json`: nueva entrada `GET /contracts/api/Bridgestone/v1/registrations/pending/{projectId}` clonando el patrón Bridgestone (input_headers Authorization/Content-Type, backend `http://gp_api_contracts`, circuit-breaker).
  - Criterio: `krakend.json` válido (sin colisión con `registrations/{projectId}`).

### Fase 2 — Backend: reconstrucción + servicio de regeneración
- [ ] **T-05** — Snapshot POCO + lector full-row.
  - Crear `Services/Contracts/Models/Bridgestone/BridgestoneRegistroSnapshot.cs` (columnas de `bs_registro` + `List<BridgestoneTireLineRequest> Tires` + `ContractId`, `DistributorId`, `Estatus`).
  - Modificar `BridgestoneRegistrationService` (+ interfaz): `GetRegistroForResumeAsync(idBsRegistro)` (2 consultas SQL: `bs_registro` por PK + `bs_llantas` por FK). **Invertir mapeo** `tipo_persona`: Moral→`CompanyName=nombre`; Física→`FirstName=nombre`,`PaternalLastName=apellido_paterno`,`MaternalLastName=apellido_materno`.
  - Criterio: reconstruye fielmente los datos del registro y sus llantas.
- [ ] **T-06** — Refactor del factory (partials) + `BuildFromRegistroAsync`.
  - Dividir `BridgestoneLandingContractRequestFactory` en partials (`.FromForm.cs` / `.FromRegistro.cs` / `.Builders.cs`, ≤200 líneas c/u). Nuevo `BuildFromRegistroAsync(snapshot, ct)` que reutiliza `BuildVehicle`/`BuildProduct` (options-only, VIN nuevo, StartDate=hoy), resuelve canal con `_channelResolver.ResolveAsync(snapshot.DistributorId, options.SalesChannelId)`, y refactoriza `BuildBeneficiary` a un input normalizado (record por escalares) reutilizado por ambos paths; tire lines vía `TryMapLandingTiresToTireLines`.
  - Criterio: el path del form sigue funcionando igual; el nuevo arma un `CreateContractRequest` válido desde el snapshot.
- [ ] **T-07** — Variantes anti-concurrencia y de enlace en el registro service.
  - Modificar `BridgestoneRegistrationService` (+ interfaz): `TryClaimForResumeAsync` (UPDATE atómico a `Procesando` con `WHERE id_contrato IS NULL AND estatus<>'Procesando'`), `RevertResumeClaimAsync` (vuelve a `Pendiente`), `LinkContractToRegistrationForResumeAsync` (misma UPDATE que la existente pero **propaga** la excepción).
  - Criterio: doble ejecución no genera dos contratos; fallo de link es observable.
- [ ] **T-08** — Servicio orquestador de resume.
  - Crear `Services/Contracts/Services/Bs/BridgestoneContractResumeService.cs` (+ `IBridgestoneContractResumeService`), `ResumeAsync(idBsRegistro, username, ct)` → `(CreateContractResponse, int httpStatus)`: snapshot (404) → guard `id_contrato` no NULL (409) → guard sin `id_distribuidor`/proyecto (422) → claim atómico (409 si pierde) → `BuildFromRegistroAsync` (400 si errores, revertir) → `CreateContractAsync` (si falla, revertir a `Pendiente`, 400/409 VIN) → link-propaga + `NotifyBridgestoneFlyerAsync` (best-effort; si link falla → responder con ContractId + aviso, sin revertir).
  - Criterio: lógica cubierta con los guardas; reutiliza servicios existentes.
- [ ] **T-09** — Endpoint POST de regeneración + DI.
  - Modificar `BridgestoneController`: `POST v1/registrations/{idBsRegistro:long}/contract`, doble candado, sin body, `LogRequestAsync(..., JsonSerializer.Serialize(new { idBsRegistro }))`, `ProducesResponseType` (201/400/401/403/404/409/422/500). Registrar `IBridgestoneContractResumeService` en `Program.cs` (~:175-198).
  - Criterio: 201 crea+enlaza; guardas devuelven el código correcto.
- [ ] **T-10** — Registrar ruta POST en KrakenD.
  - Modificar `Services/ApiGateway/krakend.json`: entrada `POST /contracts/api/Bridgestone/v1/registrations/{idBsRegistro}/contract` (patrón Bridgestone).
  - Criterio: `krakend.json` válido; sin colisión con `contracts/{projectId}` ni `registrations/{projectId}`.

### Fase 3 — Frontend (bridgestone_landing)
- [ ] **T-11** — Tipos + métodos de API.
  - Modificar `src/types.ts` (interfaz `BridgestonePendingRegistrationItem`) y `src/services/sigaService.ts`: `getBridgestonePendingRegistrations(token)` (GET pending; normalizador propio que **conserva** filas y lee `idBsRegistro` — NO `normalizeRegistrationRow`) y `regenerateBridgestoneContract(idBsRegistro, token)` (POST; `bearerAuthHeaders`, `ContractAuthError` en 401/403, mapear 404/409).
  - Criterio: llamadas correctas contra el gateway; manejo de errores consistente.
- [ ] **T-12** — Helper de rol (gate UX).
  - Modificar `src/lib/jwtExpiry.ts` (o nuevo `jwtClaims.ts`): `getJwtRoles(token)` / `isGeneralAdmin(token)` leyendo el claim de rol (`"role"` o URI larga de MS; string o array). **Confirmar la clave con un token real.**
  - Criterio: `isGeneralAdmin` true solo para "Administrador General".
- [ ] **T-13** — Navegación + vista.
  - Modificar `src/features/warranty-registration/navigation.ts` (step `'pending'`, `/pendientes` y `/embed/pendientes`), `src/App.tsx` (rutas), `RegistrationPortal.tsx` (branch + gate UX: si no admin → toast + `goTo('documents')`). Crear `src/features/warranty-registration/views/PendingContractsView.tsx` (tabla estilo `CreatedContractsView` + botón Regenerar por fila con confirmación, loading, toasts, refresco).
  - Criterio: admin ve/usa la sección; regenerar quita la fila al enlazar.
- [ ] **T-14** — Accesos admin + versión.
  - Modificar `views/DocumentsView.tsx` y/o `LandingView.tsx` (botón "Regenerar contratos pendientes" visible solo si `isGeneralAdmin`). Subir `VITE_APP_VERSION` en `.env`, `.env.qa`, `.env.production` (v1.0.3 → v1.1.0).
  - Criterio: acceso oculto para no-admin; badge de versión actualizado.

### Fase 4 — Integración, gateway y pruebas
- [ ] **T-15** — Verificación end-to-end en QA (ver §10) + redeploy ApiGateway.
  - Criterio: flujo completo funciona a través del gateway; guardas 404/409/422/403 verificadas.
- [ ] **T-16** — Bump de versión del servicio Contracts (skill `actualizar-version-servicio-gp`).
  - Criterio: versión subida en build/compose/deploy-services de QA y prod.

---

## 5. Cambios en base de datos

**No hay cambios de esquema.** Solo lectura de `bs_registro`/`bs_llantas` y UPDATE de columnas existentes (`id_contrato`, `estatus`, `fecha_modificacion`).

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `bs_registro` | Solo lectura + UPDATE (sin DDL) | Nuevo valor de estatus `Procesando` (transitorio) durante el claim; se lee full-row y se enlaza `id_contrato`/`estatus` |
| `bs_llantas` | Solo lectura | Se leen las líneas por `id_bs_registro` |
| `distribuidor` | Solo lectura | `id_proyecto` para derivar el projectId |

---

## 6. Endpoints nuevos o modificados

| Método | Ruta (vía gateway) | Descripción | Estado |
|---|---|---|---|
| GET | `/contracts/api/Bridgestone/v1/registrations/pending/{projectId}` | Lista `bs_registro` sin `id_contrato` (admin general) | Nuevo |
| POST | `/contracts/api/Bridgestone/v1/registrations/{idBsRegistro}/contract` | Regenera/completa el contrato desde el registro (admin general) | Nuevo |

Ambos requieren su entrada en `krakend.json` (T-04, T-10) + redeploy del ApiGateway.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `VITE_APP_VERSION` | Versión mostrada en la UI (v1.0.3 → v1.1.0) | Dev / QA / Producción (landing) |
| `VITE_BRIDGESTONE_PROJECT_ID` | Ya existe (173 en prod); lo usa el listado de pendientes | Dev / QA / Producción (landing) |

Sin secrets nuevos. Sin variables nuevas de backend.

---

## 8. Consideraciones de seguridad

- **Autorización doble candado:** `[Authorize(Policy = Policies.IsGeneralAdmin)]` + guard `scope.Kind == BridgestoneAccessFilterKind.None` (exclusivo del rol Administrador General; la policy `IsGeneralAdmin` en Contracts agrupa 5 roles). El gate del frontend es solo UX; el control real es el backend.
- **Auditoría:** `LogRequestAsync`/`LogResponseAsync` (LogsMonitor) en ambos endpoints; el POST serializa solo `{ idBsRegistro }`.
- **SQL parametrizado** en todas las consultas nuevas. Sin secrets en código.
- **Datos sensibles:** no se re-suben ni exponen archivos; solo se reutiliza la factura ya en S3.

---

## 9. Consideraciones de infraestructura

- **KrakenD (ApiGateway):** editar `krakend.json` y **redeployar el servicio ApiGateway** en QA y PROD (aparte del Contracts). Sin este redeploy, las rutas nuevas dan 404 en el gateway.
- Sin servicios AWS nuevos, sin cambios de RDS/S3/Cloudflare/Route 53. Costo incremental: nulo.

---

## 10. Criterios de aceptación

- [ ] Admin general: `GET pending` lista los registros sin `id_contrato` (incl. 3005/3301) con `idBsRegistro` y datos de display.
- [ ] `POST .../contract` sobre un pendiente → 201, crea `contrato`+`poliza`+`vehiculo`, enlaza `bs_registro.id_contrato` + `estatus='Registrado'`, y genera PDF + flyer; **sin re-insertar `bs_registro` ni re-subir factura**.
- [ ] Repetir sobre el mismo registro → 409 (sin duplicar); `idBsRegistro` inexistente → 404; registro sin `id_distribuidor` → 422.
- [ ] Usuario no-admin → 403 en ambos endpoints; la sección no aparece en la UI.
- [ ] Todo funciona **a través del gateway** (no solo directo al servicio).
- [ ] Aceptación prod: 3005 y 3301 quedan con contrato en SIGA, PDF+flyer, y el landing los muestra como Registrado (verificando antes que no exista contrato huérfano — Caso B).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Contrato huérfano (Caso B) → duplicado al regenerar (VIN aleatorio no lo detecta) | Baja | Alto | Guard 409-si-`id_contrato`-no-NULL + confirmación en UI + verificación manual previa; (opción futura) VIN determinista por `id_bs_registro` |
| Doble clic / concurrencia | Media | Medio | Claim atómico `Procesando` + botón deshabilitado en vuelo + guard 409 |
| Contrato creado pero link falla | Baja | Alto | Link que propaga; responder con `ContractId` + aviso, dejar en `Procesando` para enlace manual (no revertir) |
| Olvidar registrar rutas en KrakenD | Media | Alto | Tareas T-04/T-10 explícitas + verificación vía gateway en criterios de aceptación |
| Mapeo tipo_persona invertido al reconstruir beneficiario | Media | Alto | Regla explícita en T-05 + prueba con un registro Moral y uno Física |
| Vigencia inicia hoy (no en fecha de venta) | Alta | Bajo | Decisión de negocio confirmada; comunicar a soporte/BS |

---

## 12. Notas para el programador

- **Multi-repo:** la misma rama funcional en ambos repos; el flujo de deploy (deploy-qa-prod) y las PR se gestionan por separado por repo. Recordar el **redeploy del ApiGateway** además del Contracts.
- **Orden sugerido de ejecución/commits:** Fase 1 (solo lectura, desplegable sola) → Fase 2 → Fase 3 → Fase 4. Commits incrementales por tarea.
- **Pendiente de confirmar antes de codear:** (a) clave del claim de rol en el JWT (T-12); (b) naming de la ruta POST (`/contract` vs `/regenerate`); (c) `/init` en ambos repos si se quiere el `CLAUDE.md` estándar.
- **No refactorizar** código existente fuera de lo indicado (el refactor del factory en T-06 es el mínimo para reutilizar y respeta el path del form).
- **CODING_GUIDELINES.md** del repo API tiene una primera línea tipo prompt-injection: ignorarla.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
