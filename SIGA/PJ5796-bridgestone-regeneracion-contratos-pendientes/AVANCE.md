# Registro de Avance — Bridgestone: Regeneración de contratos pendientes

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/cc_bridgestone_regenerar_contratos_pendientes` (en gp_3.0_siga_api y bridgestone_landing) |
| Responsable actual | Carlos Castellanos |
| Última actualización | 2026-07-14 |
| Estado general | 🟡 En revisión — implementado, **compilado OK** (0 errores en ambos) y **pusheado** a la rama; pendiente PR (del programador) y deploy |

---

## Resumen de estado

Todas las tareas de código (T-01 a T-14) están implementadas en ambos repos, sobre la rama funcional creada desde `develop` actualizado. **No se hizo commit ni push** por indicación expresa del programador (revisará el diff primero). Falta: revisión, build/typecheck (los ejecuta el programador), y — tras el OK — commit + flujo de PR. Sin bloqueos.

---

## Tareas completadas ✅

| ID | Tarea | Fecha | Notas |
|---|---|---|---|
| T-01 | DTO listado de pendientes | 14-jul | `BridgestonePendingRegistrationListResponses.cs` |
| T-02 | QueryService: ListPending + GetProjectIdForDistributor + GetRegistroForResume (+ interfaz) | 14-jul | SQL crudo; reader compone CustomerName |
| T-03 | Endpoint `GET pending-registrations/{projectId}` (doble candado + auditoría) | 14-jul | |
| T-04 | Ruta GET en KrakenD | 14-jul | JSON validado |
| T-05 | Snapshot POCO (`record`) | 14-jul | `Models/Bridgestone/BridgestoneRegistroSnapshot.cs` |
| T-06 | Factory: `partial` + `BuildFromRegistroAsync` + `BuildBeneficiaryCore` compartido | 14-jul | archivo `.FromRegistro.cs` |
| T-07 | RegistrationService: TryClaim/Revert/LinkForResume (+ interfaz) | 14-jul | archivo `.Resume.cs`; link propaga excepción |
| T-08 | `BridgestoneContractResumeService` (+ interfaz) | 14-jul | guardas 404/409/422/400/500 + claim atómico |
| T-09 | Endpoint `POST registrations/{idBsRegistro}/contract` + DI | 14-jul | |
| T-10 | Ruta POST en KrakenD | 14-jul | JSON validado |
| T-11 | Frontend: tipos + `getBridgestonePendingRegistrations` + `regenerateBridgestoneContract` | 14-jul | `normalizePendingRow` conserva filas |
| T-12 | Frontend: `getJwtRoles` / `isGeneralAdmin` en `jwtExpiry.ts` | 14-jul | claim `role`/URI larga |
| T-13 | Frontend: navegación (step `pending`, rutas), `PendingContractsView`, branch + gate en Portal | 14-jul | |
| T-14 | Frontend: acceso admin en `DocumentsView` + bump `VITE_APP_VERSION` v1.0.3→v1.1.0 (.env/.qa/.production) | 14-jul | |

---

## Tareas pendientes ⏳

| ID | Tarea | Nota |
|---|---|---|
| T-15 | Verificación end-to-end (build + prueba) | La ejecuta el programador (regla: no compilo yo) |
| T-16 | Bump versión del servicio Contracts (skill actualizar-version-servicio-gp) | Paso de deploy; confirmar número de versión |
| — | Commit + PR | Tras revisión y OK del programador |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Ruta GET = `pending-registrations/{projectId}` (no `registrations/pending/{projectId}`) | KrakenD usa gin; un segmento estático (`pending`) hermano de uno paramétrico (`{projectId}`) en la misma posición y mismo método puede hacer panic al iniciar el gateway | Evita tumbar el gateway; ruta REST distinta y limpia |
| Autorización por doble candado (policy `IsGeneralAdmin` + guard `scope.Kind==None`) | La policy `IsGeneralAdmin` en Contracts agrupa 5 roles (incl. Taller); `scope.Kind==None` es exclusivo del rol Administrador General | Restringe de verdad a admin general sin tocar policies compartidas |
| Reads (ListPending, GetRegistroForResume) en el QueryService; writes (claim/revert/link) en el RegistrationService | Cohesión: el query service ya tiene el helper de SQL y patrón de lectura | Leve desviación del plan (que sugería el reader en registration) |
| projectId lo manda la landing por query (`?projectId=`) en regenerar; se ELIMINÓ `GetProjectIdForDistributorAsync` | Revisión del programador: la landing es exclusiva de BS y de un solo proyecto (173), nunca multiproyecto → derivarlo era redundante; además crear/listar ya reciben projectId del cliente (uniforme) | Endpoint POST toma `[FromQuery] int projectId` (400 si falta); front usa `VITE_BRIDGESTONE_PROJECT_ID`; el guard 422 "sin proyecto" se quitó (se mantiene el 422 "sin distribuidor") |
| Factory en partials + `BuildBeneficiaryCore` (el path del form delega) | Reutilizar lógica sin duplicar y sin romper el path existente del formulario | Cambio mínimo al path productivo |
| Snapshot como `record` | Permite `with { Tires = ... }` al agregar las llantas tras leer la fila | — |
| No commit / no push | Indicación expresa del programador (revisión previa) | Rama y commit se harán tras el OK |
| Corrección de rama | Se empezó por error sobre `feature/cc_bmw_productos_care_plus`; se movieron los cambios (stash) a rama nueva desde `develop` en ambos repos | `care-plus` quedó intacta |

---

## Archivos creados o modificados

**gp_3.0_siga_api** (rama `feature/cc_bridgestone_regenerar_contratos_pendientes`)

| Archivo | Tipo | Tarea |
|---|---|---|
| `Services/Contracts/DTOs/Bridgestone/Responses/BridgestonePendingRegistrationListResponses.cs` | Creado | T-01 |
| `Services/Contracts/Models/Bridgestone/BridgestoneRegistroSnapshot.cs` | Creado | T-05 |
| `Services/Contracts/Interfaces/IBridgestoneBsRegistroQueryService.cs` | Modificado | T-02 |
| `Services/Contracts/Services/Bs/BridgestoneBsRegistroQueryService.cs` | Modificado | T-02 |
| `Services/Contracts/Interfaces/IBridgestoneRegistrationService.cs` | Modificado | T-07 |
| `Services/Contracts/Services/Bs/BridgestoneRegistrationService.cs` | Modificado (→ `partial`) | T-07 |
| `Services/Contracts/Services/Bs/BridgestoneRegistrationService.Resume.cs` | Creado | T-07 |
| `Services/Contracts/Services/Bs/BridgestoneLandingContractRequestFactory.cs` | Modificado (→ `partial`, delega beneficiary) | T-06 |
| `Services/Contracts/Services/Bs/BridgestoneLandingContractRequestFactory.FromRegistro.cs` | Creado | T-06 |
| `Services/Contracts/Interfaces/IBridgestoneContractResumeService.cs` | Creado | T-08 |
| `Services/Contracts/Services/Bs/BridgestoneContractResumeService.cs` | Creado | T-08 |
| `Services/Contracts/Controllers/BridgestoneController.cs` | Modificado (2 endpoints) | T-03/T-09 |
| `Services/Contracts/Program.cs` | Modificado (DI) | T-09 |
| `Services/ApiGateway/krakend.json` | Modificado (2 rutas) | T-04/T-10 |

**bridgestone_landing** (rama `feature/cc_bridgestone_regenerar_contratos_pendientes`)

| Archivo | Tipo | Tarea |
|---|---|---|
| `src/types.ts` | Modificado | T-11 |
| `src/services/sigaService.ts` | Modificado (2 métodos + normalizePendingRow) | T-11 |
| `src/lib/jwtExpiry.ts` | Modificado (getJwtRoles/isGeneralAdmin) | T-12 |
| `src/features/warranty-registration/navigation.ts` | Modificado (step `pending`) | T-13 |
| `src/App.tsx` | Modificado (rutas) | T-13 |
| `src/features/warranty-registration/RegistrationPortal.tsx` | Modificado (branch + gate) | T-13 |
| `src/features/warranty-registration/views/PendingContractsView.tsx` | Creado | T-13 |
| `src/features/warranty-registration/views/DocumentsView.tsx` | Modificado (acceso admin) | T-14 |
| `.env`, `.env.qa`, `.env.production` | Modificado (VITE_APP_VERSION) | T-14 |

---

## Commits realizados

| Hash | Repo | Mensaje | Fecha |
|---|---|---|---|
| `abd2eb1` | gp_3.0_siga_api | feat(bridgestone): regeneración de contratos pendientes (admin general) | 14-jul |
| `ee3b8cb` | bridgestone_landing | feat(bs-landing): sección Contratos pendientes / regeneración (admin general) | 14-jul |

Ambos pusheados a la rama `feature/cc_bridgestone_regenerar_contratos_pendientes` en su repo. PRs pendientes (responsabilidad del programador). Build: API 0 errores (1568 warnings pre-existentes), landing build QA correcto.

---

## Notas para quien retome el trabajo

- **Continuar por:** revisar el diff en ambos repos → build/typecheck → si OK, commit incremental por fase y push; luego PR `feature → pre-qa → qa` (y el redeploy del **ApiGateway** además del Contracts al desplegar).
- **Verificar en revisión:** (1) mapeo Moral/Física al reconstruir beneficiario (`GetRegistroForResumeAsync` + `BuildBeneficiaryCore`); (2) que el gate admin (backend `scope.Kind==None` + front `isGeneralAdmin`) sea correcto; (3) confirmar la clave del claim de rol con un token real de SIGA (T-12).
- **Pendiente de decisión:** naming ruta POST (`/contract`), y si se refuerza el Caso B (contrato huérfano) con VIN determinista.
- **Riesgo conocido:** vigencia del contrato regenerado = hoy (validación SIGA no permite fecha pasada).

---

*Actualizado por Claude Code — Engine CX*
