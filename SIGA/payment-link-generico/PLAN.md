# Plan de Desarrollo — Link de pago genérico (sacar `payment-link` de BmwController)

> Generado por Claude Code. **Sin PRD de origen** — decisión explícita del responsable (30-ago-2026): se generó el plan directo a partir del análisis técnico del código, para desbloquear a Omega.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | *(ninguno)* — ver §12. Antecedente relacionado: `SIGA/PJ9124-bmw-link-pago-blindar-reintentos/PRD.md` |
| Repositorio | `gp_3.0_siga_api` (API de SIGA) |
| Rama | `feature/payment-link-generico` |
| Tipo | Feature |
| Responsable | Juan Carlos Castellanos Solis |
| Folio PRD | `PJ5311` — ⚠️ **PROVISIONAL E INVENTADO**. No hay PRD ni folio real; se eligió un folio libre solo porque el registro en BD lo exige como llave de enlace. Si más adelante se levanta el PRD formal, reemplazar el folio aquí y en `pm_plan_desarrollo`. |
| Fecha de generación | 2026-08-30 |
| Estado | Borrador |
| ID plan (BD) | `66` |
| Rama base | `develop` |
| Modelo | claude-opus-5 — esfuerzo: alto |

---

## 1. Resumen técnico

Hoy la generación del link de pago de OpenPay solo se puede pedir por
`POST /contracts/api/Bmw/v1/{projectId}/contracts/{contractId}/payment-link`, en
`BmwController`, detrás de la policy `ICanAccessBmw`. Cualquier otro proyecto —Omega,
GarantiPlus, Bridgestone— no puede pedirlo aunque el contrato sea suyo.

El trabajo consiste en **mover la capacidad a un endpoint genérico en `ContractsController`**,
acotado por el scope de contrato que ya existe (`IContractAccessService`), y **dejar la ruta de
BMW como wrapper delgado** que delega en el servicio genérico sin cambiar su ruta, su contrato
ni sus códigos de estado.

No es un rediseño: la lógica de negocio ya es genérica. `GetPaymentGatewayLink` vive en
`IVentasBusinessRules` (OpenpayGP), el candado anti doble cobro vive en
`_contractsService.GetContractPaymentInfoAsync` (`CanRegenerate` / `BlockReason`), y la bitácora
de regeneración también es genérica. Solo cuatro cosas atan el método a BMW, y las cuatro tienen
sustituto ya construido en el repositorio.

**Componentes que se crean:**
- `Services/Contracts/Interfaces/IPaymentLinkService.cs`
- `Services/Contracts/Services/PaymentLinkService.cs` (+ partial si supera 200 líneas)
- `Services/Contracts/DTOs/Contracts/Requests/CreatePaymentLinkRequest.cs`
- `Services/Contracts/DTOs/Contracts/Responses/CreatePaymentLinkResponse.cs`

**Componentes que se modifican:**
- `Services/Contracts/Controllers/ContractsController.cs` (endpoint nuevo)
- `Services/Contracts/Controllers/BmwController.cs` (la acción existente pasa a delegar)
- `Services/Contracts/Services/Bmw/BmwPaymentService.cs` (`GeneratePaymentLinkAsync` delega)
- `Services/Contracts/Program.cs` (registro DI + policy)
- `Services/ApiGateway/krakend.json` (ruta nueva)

**Stack:** .NET Core 8 / C# — el que ya usa el servicio. Sin cambios de base de datos, sin
cambios de infraestructura, sin secrets nuevos.

---

## 2. Prerequisitos

- [x] `CLAUDE.md` presente en `gp_3.0_siga_api`
- [x] Rama `develop` existe y está al día
- [x] Análisis de acoplamiento a BMW completado (ver §3)
- [x] Responsable confirmado: Juan Carlos Castellanos Solis
- [ ] Confirmar si `payment-method` también se generaliza (Fase 5, §12 punto 3)
- [ ] Confirmar la regla de MSI cuando un contrato tiene varias pólizas (§12 punto 2)
- [ ] Ambiente de QA arriba para validar (ojo: QA se apaga a las 19:00)
- [ ] Distribuidor y usuario de Omega dados de alta en QA (T-017) para probar el caso multi-proyecto

---

## 3. Arquitectura del cambio

Arquitectura vigente: **microservicios en ECS + Fargate** (`rules/arquitectura.md` §1). No se
crea servicio nuevo; el cambio vive dentro del microservicio `Contracts` que ya existe. La
decisión correcta aquí es *no* mover nada de contenedor: es una reubicación de responsabilidad
**dentro** del mismo servicio.

### 3.1 Estado actual

```
bmw_landing ─┐
             ├─► KrakenD ─► Contracts ─► BmwController.CreatePaymentLink
Omega ───────┘                              │  [Authorize(ICanAccessBmw)]
  (BLOQUEADO)                               ▼
                                     BmwPaymentService.GeneratePaymentLinkAsync
                                        ├─ EnsureContractInScopeAsync  ← BmwDirectoryAccessScope
                                        ├─ GetContractPaymentInfoAsync ← YA GENÉRICO
                                        ├─ ResolveMsiCapAsync          ← JOIN a bmw_registro
                                        └─ GetPaymentGatewayLink       ← YA GENÉRICO (OpenpayGP)
```

### 3.2 Estado objetivo

```
bmw_landing ─► KrakenD ─► Contracts ─► BmwController.CreatePaymentLink   (WRAPPER, ruta intacta)
                                              │  delega
Omega ───────► KrakenD ─► Contracts ─► ContractsController.CreatePaymentLink
GarantiPlus ─┘                                │  [Authorize(ICanCreateContract)]
Bridgestone ─┘                                ▼
                                     PaymentLinkService.CreateAsync
                                        ├─ IContractAccessService.EvaluateContractAccessAsync  ← YA EXISTE
                                        ├─ GetContractPaymentInfoAsync                          ← se reusa
                                        ├─ ResolveMsiCapAsync (vía contrato→poliza→producto)     ← NUEVO
                                        └─ GetPaymentGatewayLink                                 ← se reusa
```

### 3.3 Precedente que se replica

**`ContractsController.GetContractPaymentInfo` (línea 119) ya resolvió exactamente este mismo
problema de forma genérica** y es la plantilla a copiar, no a inventar:

- Ruta `v1/[action]/{contractId:long}` en `ContractsController`, sin `projectId` en la ruta.
- Scope con `_contractAccess.EvaluateContractAccessAsync(User, contractId, ...)`, que mapea
  `Forbidden → 403` y `NotFound → 404`.
- Su XML doc dice literalmente *"Generic (any project: BMW, Bridgestone, SIGA, etc.)"*.
- **La landing BMW ya lo consume** (`bmw_landing/src/services/sigaService.ts:1057`), lo que prueba
  que el front puede pegarle a rutas genéricas de `Contracts` sin fricción.

El endpoint nuevo debe ser simétrico a ése en ruta, manejo de scope, logging y códigos de estado.

### 3.4 Los cuatro acoplamientos y su sustituto

| # | Acoplamiento hoy | Dónde | Sustituto genérico |
|---|---|---|---|
| 1 | Scope vía `BmwDirectoryAccessScope` / `EnsureContractInScopeAsync` | `BmwPaymentService.cs` | `IContractAccessService.EvaluateContractAccessAsync` — deriva el proyecto de `contrato.id_distribuidor → distribuidor.id_proyecto` |
| 2 | `ResolveMsiCapAsync` llega a `producto_proyecto.max_msi` con `INNER JOIN bmw_registro` | `BmwPaymentService.cs` | Ir por `contrato → poliza → id_producto`, y el proyecto por `distribuidor.id_proyecto` |
| 3 | `CountryCodeMexico` como constante | `BmwPaymentService.cs` | Leer `CountryCode` de `appsettings` (ya existe y lo usa `ProductService`) |
| 4 | DTOs `BmwPaymentLinkRequest` / `BmwPaymentLinkResponse` | `DTOs/Bmw/` | `CreatePaymentLinkRequest` / `CreatePaymentLinkResponse` en `DTOs/Contracts/`; los de BMW se conservan como alias del wrapper |

### 3.5 Hallazgo que desactiva el mayor riesgo percibido

`ICanAccessBmw`, `ICanAccessBridgestone`, `ICanCreateContract` y `ICanQuoteProducts` exigen
**exactamente los mismos 8 roles**:

```
IsGeneralAdmin, IsExternalGeneralAdministrator, IsCountryManager, IsDistributorUser,
IsDistributorWorkshopUser, IsSalesExecutive, IsCommercialManager, IsSalesman
```

Es decir: **`ICanAccessBmw` nunca fue una compuerta de BMW.** El acotamiento real siempre lo hizo
el scope, no la policy. Consecuencia práctica: cambiar la policy del endpoint genérico a
`ICanCreateContract` **no le quita acceso a ningún usuario que hoy lo tenga**, y no le abre la
puerta a ningún rol nuevo. Esto debe verificarse en la Fase 0 antes de apoyarse en ello.

---

## 4. Tareas de desarrollo

### Fase 0 — Red de seguridad (antes de tocar una línea)

- [ ] **T-01** — Congelar el comportamiento actual del endpoint de BMW como baseline.
  - Archivos: `docs/` o el `AVANCE.md` del plan
  - Registrar, contra QA y con un contrato BMW real de contado: request exacto, respuesta 200,
    y las respuestas de error 400 / 403 / 409 / 422 con el mensaje textual de cada una.
  - Criterio de completitud: existe una tabla de "entrada → salida esperada" con al menos un caso
    por código de estado documentado en el endpoint. Es el contrato contra el que se compara al final.

- [ ] **T-02** — Verificar en código que `ICanAccessBmw` e `ICanCreateContract` tienen los mismos roles.
  - Archivos: `Services/Contracts/Program.cs` (líneas ~360 y ~410)
  - Criterio de completitud: confirmado rol por rol y anotado en el `AVANCE.md`. **Si difieren, se
    detiene el plan y se replantea la policy del endpoint genérico** (§11, riesgo R-1).

- [ ] **T-03** — Inventariar todos los consumidores de la ruta BMW de `payment-link`.
  - Archivos: `bmw_landing/src/services/sigaService.ts`, `Services/ApiGateway/krakend.json`
  - Criterio de completitud: lista cerrada de quién llama la ruta hoy (a la fecha: solo la landing
    BMW, línea 1068). Sin esta lista no se puede afirmar que el wrapper no rompe a nadie.

### Fase 1 — Servicio genérico (P1)

- [ ] **T-04** — Crear los DTOs genéricos.
  - Archivos a crear: `Services/Contracts/DTOs/Contracts/Requests/CreatePaymentLinkRequest.cs`,
    `Services/Contracts/DTOs/Contracts/Responses/CreatePaymentLinkResponse.cs`
  - Campos idénticos a los de BMW (`PaymentType` con `[Range(1,2)]`, `Msi` opcional con
    `[Range(3,12)]`; respuesta con `PaymentUrl`), para que el wrapper sea un mapeo 1:1.
  - Criterio de completitud: compila y los DTOs de BMW se pueden mapear a éstos sin perder ni un campo.

- [ ] **T-05** — Crear `IPaymentLinkService` con la firma genérica.
  - Archivos a crear: `Services/Contracts/Interfaces/IPaymentLinkService.cs`
  - Firma: recibe `ClaimsPrincipal`, `contractId`, el request y el `requestedBy`; **no recibe
    `projectId`** (el proyecto se deriva del contrato) ni `BmwDirectoryAccessScope`.
  - Devuelve la misma tupla `(Result, ErrorMessage, StatusCode)` que hoy, para no alterar el
    mapeo de errores.
  - Criterio de completitud: interfaz documentada con XML docs en inglés (`coding-guidelines.md` §1).

- [ ] **T-06** — Implementar la resolución genérica del tope de MSI.
  - Archivos a crear/modificar: `Services/Contracts/Services/PaymentLinkService.cs`
  - Reemplaza el `INNER JOIN bmw_registro` por `contrato → poliza → producto_proyecto`, tomando el
    proyecto de `distribuidor.id_proyecto`, y conservando el filtro `COALESCE(pp.pago_pasarela,0) = 1`.
  - Criterio de completitud: para un contrato BMW de contado devuelve **el mismo `max_msi`** que
    devuelve hoy la versión que pasa por `bmw_registro`. Se compara contra al menos 3 contratos reales.

- [ ] **T-07** — Implementar `PaymentLinkService.CreateAsync` con el resto de la lógica.
  - Archivos a modificar: `Services/Contracts/Services/PaymentLinkService.cs`
  - Porta tal cual, sin cambiar semántica: guard de contrato `Cancelado`/`Caduco` → 409; guard
    `CanRegenerate` → 409 con `BlockReason`; bitácora `RecordPaymentLinkRegeneration`; y el
    `MapPaymentGatewayException` con sus tres ramas (409 pagado / en ODP, 422 no pagable, resto).
  - El `countryCode` sale de configuración, no de constante.
  - Criterio de completitud: archivo ≤200 líneas efectivas o dividido en `partial`
    (`coding-guidelines.md` §3); registrado en DI en `Program.cs`.

### Fase 2 — Endpoint genérico (P1)

- [ ] **T-08** — Agregar la acción `CreatePaymentLink` a `ContractsController`.
  - Archivos a modificar: `Services/Contracts/Controllers/ContractsController.cs`
  - Ruta `[HttpPost("v1/[action]/{contractId:long}")]`, simétrica a `GetContractPaymentInfo`.
    Policy `ICanCreateContract`. Rate limit `Restrictive` (igual que el de BMW).
  - Scope con `_contractAccess.EvaluateContractAccessAsync` → 403 / 404, **con los mismos cuerpos
    de error que ya usa `GetContractPaymentInfo`** para no inventar un formato nuevo.
  - `LogRequestAsync` con `JsonSerializer.Serialize(request)` por ser POST con body
    (regla de 4 argumentos del repositorio).
  - Criterio de completitud: responde 200 con un contrato en scope y 403 con uno fuera de scope,
    probado con dos usuarios distintos.

- [ ] **T-09** — Dar de alta la ruta nueva en KrakenD.
  - Archivos a modificar: `Services/ApiGateway/krakend.json`
  - Ruta: `/contracts/api/Contracts/v1/CreatePaymentLink/{contractId}`.
  - Criterio de completitud: la ruta responde a través del gateway en QA, no solo directo al
    contenedor. **Sin este paso el endpoint da 404 aunque el servicio esté bien.**

### Fase 3 — BMW como wrapper (P1)

- [ ] **T-10** — Convertir `BmwPaymentService.GeneratePaymentLinkAsync` en delegación.
  - Archivos a modificar: `Services/Contracts/Services/Bmw/BmwPaymentService.cs`
  - El método conserva su firma pública (incluido el `BmwDirectoryAccessScope`, aunque ya no lo
    use para autorizar) y delega en `IPaymentLinkService`. Se elimina la lógica duplicada, **no**
    el método.
  - Criterio de completitud: `BmwController` sigue compilando sin cambios en su firma, y los casos
    del baseline T-01 siguen dando el mismo código y el mismo mensaje.

- [ ] **T-11** — Decidir y aplicar el manejo del `projectId` en el wrapper.
  - Archivos a modificar: `Services/Contracts/Controllers/BmwController.cs`
  - El endpoint de BMW recibe `projectId` en la ruta; el genérico no. El wrapper debe **seguir
    validando** que el contrato pertenece a ese `projectId` para no relajar el comportamiento
    actual (hoy un contrato de otro proyecto da 403).
  - Criterio de completitud: pedir el link de un contrato que NO es del `projectId` de la ruta
    sigue devolviendo 403, igual que hoy.

- [ ] **T-12** — Verificar que la landing BMW no requiere ningún cambio.
  - Archivos: `bmw_landing/src/services/sigaService.ts` (solo lectura)
  - Criterio de completitud: la landing corre contra QA sin tocar una línea y el flujo de contado
    completo (crear contrato → link → pagar) cierra igual que antes.

### Fase 4 — Validación y despliegue (P1)

- [ ] **T-13** — Regresión del flujo BMW en QA contra el baseline de T-01.
  - Criterio de completitud: **los 5 códigos de estado del baseline se reproducen idénticos**
    (200, 400, 403, 409, 422), con el mismo texto de mensaje. Cualquier diferencia se corrige
    antes de avanzar; ésta es la tarea que protege PROD.

- [ ] **T-14** — Probar el endpoint genérico con el usuario de Omega.
  - Depende de T-017 (alta de Omega en QA).
  - Criterio de completitud: `UsuarioOMEGA` obtiene el link de pago de un contrato suyo, y recibe
    403 al pedir el de un contrato de otro distribuidor.

- [ ] **T-15** — Desplegar a QA y luego a PROD siguiendo la skill `deploy-qa-prod`.
  - Incluye redesplegar **ApiGateway** en ambos ambientes por el cambio de `krakend.json`.
  - Criterio de completitud: ruta genérica viva en PROD y flujo BMW de contado sin regresión.

### Fase 5 — `payment-method` genérico (P2, condicionada)

> Solo si se confirma que Omega lo necesita (§12 punto 3). Se documenta para dejar el camino
> trazado; no se implementa junto con P1.

- [ ] **T-16** — Replicar el mismo patrón para `POST .../contracts/{contractId}/payment-method`.
  - Archivos: `BmwController.cs` (línea ~1486), `ContractsController.cs`, `krakend.json`
  - Criterio de completitud: mismos criterios que T-08 a T-13, aplicados a `SetPaymentMethod`.

---

## 5. Cambios en base de datos

**Ninguno.** El cambio no crea ni altera tablas, columnas ni índices. Solo cambia por dónde se
consulta `producto_proyecto.max_msi` (de `bmw_registro` a `poliza`), que es una consulta de
lectura sobre tablas existentes.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `/contracts/api/Contracts/v1/CreatePaymentLink/{contractId}` | Genera el link de pago de cualquier contrato en el scope del usuario. Genérico para todos los proyectos. | **Nuevo** |
| POST | `/contracts/api/Bmw/v1/{projectId}/contracts/{contractId}/payment-link` | Pasa a ser wrapper del genérico. **Ruta, request, response y códigos sin cambio.** | Modificado (interno) |
| POST | `/contracts/api/Contracts/v1/SetPaymentMethod/{contractId}` | Fija medio de pago. Solo si se aprueba la Fase 5. | Nuevo (P2, condicional) |

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `CountryCode` | Ya existe en `appsettings` del servicio `Contracts`. Se **empieza a usar** en el flujo de link de pago, en lugar de la constante `CountryCodeMexico`. No se crea nada nuevo. | Desarrollo / QA / Producción |

Sin secrets nuevos. Las credenciales de OpenPay siguen viviendo donde ya viven, en OpenpayGP.

---

## 8. Consideraciones de seguridad

- **Autorización:** el endpoint genérico usa `ICanCreateContract` (los mismos 8 roles que hoy
  exige `ICanAccessBmw`, ver §3.5) más el acotamiento por scope de `IContractAccessService`. El
  scope es la defensa real: un `Usuario Distribuidor` solo alcanza contratos de los distribuidores
  ligados en `usuario_distribuidor`.
- **Riesgo de ampliación de superficie:** al quitar el gate de BMW, cualquier proyecto podrá pedir
  links de pago. Es el objetivo, pero obliga a que el scope se valide en **todas** las rutas de
  entrada. T-08 y T-11 son las tareas que lo garantizan.
- **Doble cobro:** el candado `CanRegenerate` es lo que impide que existan dos cargos pagables
  sobre el mismo contrato. Se porta tal cual, sin relajarlo. **No debe quedar del lado del
  cliente.**
- **Rate limiting:** se conserva `Restrictive` en el endpoint genérico. Es un endpoint que mueve
  dinero; no bajarlo a `Light` por comodidad.
- **Datos sensibles:** ninguno nuevo. El link de OpenPay ya se persiste en
  `contrato.link_pago_pasarela`.
- Sin cambios de IAM.

---

## 9. Consideraciones de infraestructura

- Sin servicios AWS nuevos y sin costo adicional.
- Se redespliegan dos contenedores ECS existentes: `Contracts` y `ApiGateway`.
- **ApiGateway es obligatorio** en QA y en PROD por el cambio de `krakend.json`; si se despliega
  solo `Contracts`, la ruta nueva responde 404.
- ⚠️ Al reconstruir la imagen para PROD, verificar `git diff --stat release origin/pre-qa -- Services/Contracts/`
  y usar **etiqueta de ECR nueva** si difiere. Reusar etiqueta sobreescribe la imagen de QA en silencio.

---

## 10. Criterios de aceptación

- [ ] Omega obtiene el link de pago de un contrato suyo por el endpoint genérico, sin pertenecer a BMW.
- [ ] Un usuario obtiene 403 al pedir el link de un contrato fuera de su scope, y 404 si no existe.
- [ ] La ruta de BMW responde **exactamente igual que antes**: misma ruta, mismo request, mismo
      response y los mismos 5 códigos de estado con el mismo texto (verificado contra el baseline de T-01).
- [ ] La landing `bmw_landing` funciona sin ningún cambio de código.
- [ ] El tope de MSI resuelto por la vía genérica coincide con el que resolvía la vía `bmw_registro`
      en al menos 3 contratos reales.
- [ ] El candado anti doble cobro sigue devolviendo 409 cuando el cargo vigente aún es pagable.
- [ ] La ruta nueva responde a través de KrakenD en QA y en PROD, no solo directo al contenedor.
- [ ] No hay cambios en base de datos.

---

## 11. Riesgos técnicos identificados

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|---|
| R-1 | `ICanAccessBmw` e `ICanCreateContract` no resultan tener los mismos roles y el cambio le quita acceso a alguien | Baja | Alto | **T-02 lo verifica antes de escribir código.** Si difieren, se detiene y se define una policy propia (`ICanCreatePaymentLink`) con la unión de roles |
| R-2 | La resolución genérica de MSI devuelve un tope distinto al de `bmw_registro` y cambia los meses ofrecidos al cliente | Media | Alto | T-06 compara contra contratos reales antes de conectar nada. Un contrato con varias pólizas es el caso a definir (§12 punto 2) |
| R-3 | Se despliega `Contracts` sin `ApiGateway` y la ruta nueva da 404 | Media | Medio | Está escrito como parte de T-15 y en §9. Es un error conocido y recurrente del repositorio |
| R-4 | El wrapper deja de validar el `projectId` de la ruta y relaja el 403 actual | Media | Alto | T-11 lo cubre explícitamente y T-13 lo verifica contra el baseline |
| R-5 | Cambia el texto de algún mensaje de error y la landing —que hace matching por texto— deja de reaccionar bien | Media | Medio | El baseline de T-01 guarda los mensajes **textuales**; T-13 los compara uno a uno |
| R-6 | Regresión en PROD sobre un flujo que mueve dinero | Baja | **Muy alto** | Fases 0 y 4 existen únicamente para esto. Nada llega a PROD sin la regresión completa de T-13 en QA |
| R-7 | La validación en QA se cae por el apagado automático de las 19:00 | Media | Bajo | Agendar las pruebas antes de esa hora; un 503 a esa hora es el apagado, no un bug |

---

## 12. Notas para el programador

1. **Este plan no tiene PRD.** Se generó por decisión explícita del responsable para desbloquear a
   Omega. Si el trabajo crece más allá de lo aquí descrito —sobre todo si entra la Fase 5 o la
   cancelación de cargos en OpenPay— conviene levantar el PRD formal y asignarle folio. La carpeta
   se llamó `payment-link-generico` sin folio `PJ####` a propósito, siguiendo el precedente de
   `Go Virtual/atenea-go-virtual` y `Gplus-Seguros/omega-endpoint-cotizaciones-error`.

2. **Decisión pendiente — MSI con varias pólizas.** Hoy BMW resuelve el tope tomando el
   `bmw_registro` más reciente (`ORDER BY r.id_registro DESC LIMIT 1`), lo que funciona porque un
   registro BMW equivale a una póliza. Un contrato genérico puede tener **varias pólizas con
   productos distintos y topes de MSI distintos**. Hay que definir la regla antes de T-06:
   ¿el `max_msi` más alto, el más bajo, o el de la póliza de mayor importe? Recomendación: **el más
   bajo**, porque es el único que no ofrece al cliente una mensualidad que algún producto del
   contrato no soporta. Confirmarlo antes de codificar.

3. **Decisión pendiente — `payment-method`.** El flujo de contado de BMW no solo pide el link:
   también fija el medio con `POST .../payment-method` (`BmwController` línea 1486). Falta saber si
   Omega necesita las dos cosas o solo el link. Si necesita ambas, la Fase 5 deja de ser opcional y
   el plan crece entre 1 y 2 días.

4. **`GetContractPaymentInfo` es la plantilla.** No inventar formato de error, de ruta ni de
   logging: copiar el de esa acción. Ya está en PROD, ya lo consume la landing BMW y ya resolvió el
   mismo problema de scope genérico.

5. **No refactorizar de paso.** `rules/coding-guidelines.md` es explícito: el código existente no se
   refactoriza salvo petición. `BmwPaymentService` tiene otras cosas mejorables
   (`BmwPaymentService.Billing.cs`, el PDF de ODP); quedan fuera de este plan.

6. **`BmwDirectoryAccessScope` no se borra.** Lo siguen usando el directorio, el sales-team y las
   registrations de BMW. Este plan solo deja de usarlo para autorizar el link de pago.

7. **Relación con T-018 y T-017 del tablero.** Este plan es T-018. Su validación completa
   (T-14) depende de que T-017 haya dejado a Omega operando en QA.

8. **Antecedente que conviene leer antes de arrancar:** `SIGA/PJ9124-bmw-link-pago-blindar-reintentos/PRD.md`.
   Explica por qué existe el candado `CanRegenerate` y por qué un intento anterior de regenerar el
   link en cada clic **se revirtió por riesgo de doble cobro**. Ese candado no se toca.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Red de seguridad** | Baseline de comportamiento, verificación de policies, inventario de consumidores | T-01 a T-03 | 1 – 2 días | 236 |
| **Fase 1 — Servicio genérico (P1)** | DTOs genéricos, `IPaymentLinkService`, MSI por póliza, `PaymentLinkService` | T-04 a T-07 | 2 – 3 días | 237 |
| **Fase 2 — Endpoint genérico (P1)** | Acción en `ContractsController`, policy, rate limit, ruta en KrakenD | T-08 a T-09 | 1 – 2 días | 238 |
| **Fase 3 — BMW como wrapper (P1)** | Delegación, validación de `projectId`, verificación de la landing | T-10 a T-12 | 1 – 2 días | 239 |
| **Fase 4 — Validación y despliegue (P1)** | Regresión contra baseline, prueba con Omega, deploy QA + PROD | T-13 a T-15 | 2 – 3 días | 240 |
| **Fase 5 — `payment-method` genérico (P2)** | Mismo patrón para `SetPaymentMethod` | T-16 | 1 – 2 días | 241 |
| **Total proyecto (P1+P2)** | | 16 tareas | ~8 – 14 días hábiles (≈ 2 – 3 semanas) | — |
| **Solo P1 (mínimo que desbloquea a Omega)** | Fase 0 + Fase 1 + Fase 2 + Fase 3 + Fase 4 | T-01 a T-15 | ~7 – 12 días hábiles (≈ 1.5 – 2.5 semanas) | — |

> **Notas sobre la tabla:**
> - Las Fases 0 y 4 concentran 3 – 5 días de los 7 – 12 de P1. **No son relleno:** son el costo de
>   tocar un endpoint productivo que mueve dinero, y son lo que hace que "no romper nada" sea
>   verificable en vez de una intención.
> - Los rangos salen de la complejidad real de cada tarea. La Fase 1 es la más ancha porque T-06
>   (resolución de MSI) depende de una decisión de negocio todavía abierta (§12 punto 2).
> - La columna **ID (BD)** la llena el flujo al registrar el plan; no editarla a mano.

> **Riesgo de deadline:** no hay fecha límite comprometida, porque no hay PRD que la fije. El
> disparador real es Omega, que está esperando. Si esa espera aprieta, el recorte correcto es
> **dejar la Fase 5 fuera** (`payment-method`) y entregar solo P1: el link de pago genérico
> desbloquea a Omega en ~7 – 12 días hábiles. Lo que **no** se debe recortar son las Fases 0 y 4:
> quitarlas ahorra ~3 – 5 días a cambio de exponer a producción un flujo de cobro sin red de
> seguridad, y el propio antecedente de PJ9124 ya documenta una reversión previa por exactamente
> ese tipo de prisa. Un segundo desarrollador aportaría poco: las fases son secuenciales y
> dependen unas de otras; a lo sumo podría paralelizar la Fase 0 con la Fase 1, comprimiendo
> ~15%.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
