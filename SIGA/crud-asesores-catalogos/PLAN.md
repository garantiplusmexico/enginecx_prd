# Plan de Desarrollo — CRUD de asesores en el servicio Catalogs

> Generado por Claude Code. **Sin PRD de origen** — decisión explícita del responsable (31-ago-2026): plan directo a partir del análisis del código, para desbloquear a Omega.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | *(ninguno)* — ver §12 |
| Repositorio | `gp_3.0_siga_api` (API de SIGA) — servicio `Catalogs` |
| Rama | `feature/crud-asesores-catalogos` |
| Tipo | Feature |
| Responsable | Juan Carlos Castellanos Solis |
| Folio PRD | `PJ5478` — ⚠️ **PROVISIONAL E INVENTADO**. No hay PRD ni folio real; se eligió un folio libre solo porque el registro en BD lo exige como llave. Si se levanta el PRD formal, reemplazarlo aquí y en `pm_plan_desarrollo`. |
| Fecha de generación | 2026-08-31 |
| Estado | Borrador |
| ID plan (BD) | `67` |
| Rama base | `develop` |
| Modelo | claude-opus-5 — esfuerzo: alto |

---

## 1. Resumen técnico

Hoy la API de SIGA **puede leer asesores pero no puede crearlos, editarlos ni darlos de baja**.
`Catalogs/Controllers/AdvisorController.cs` ya expone `GetAllAdvisors` (con OData) y
`GetAdvisorById`, ambos genéricos y acotados por scope. Falta la escritura, y sin ella Omega no
puede operar: `ChannelInfoRequest.AdvisorId` es `[Required]` en el alta de contrato, así que un
distribuidor sin asesores no puede vender.

El trabajo consiste en **completar el CRUD sobre la tabla `asesor`** dentro del servicio
`Catalogs`, con tres operaciones nuevas: crear, actualizar y **desactivar** (el `DELETE` es un
borrado lógico, `activo = false`; la fila nunca se borra).

**Lo que hace este plan distinto de un CRUD cualquiera** es que `Catalogs` es hoy un servicio de
**solo lectura**: sus 32 endpoints son `[HttpGet]` sin una sola excepción y sus policies se llaman
`ICanRead*`. Estas serían sus primeras escrituras, así que además del CRUD hay que introducir una
policy de escritura que no existe y la estructura de carpetas que el servicio nunca necesitó.

**Componentes que se crean:**
- `Services/Catalogs/Interfaces/IAdvisorService.cs`
- `Services/Catalogs/Services/AdvisorService.cs`
- `Services/Catalogs/DTOs/Advisors/CreateAdvisorRequest.cs`
- `Services/Catalogs/DTOs/Advisors/UpdateAdvisorRequest.cs`
- `Services/Catalogs/DTOs/Advisors/AdvisorDeactivationResponse.cs`

**Componentes que se modifican:**
- `Services/Catalogs/Controllers/AdvisorController.cs` (tres acciones nuevas; **no se toca la lectura**)
- `Services/Catalogs/Program.cs` (policy de escritura + registro DI)
- `Services/ApiGateway/krakend.json` (tres rutas nuevas)

**Stack:** .NET Core 8 / C#, el que ya usa el servicio. **Sin cambios de base de datos**, sin
infraestructura nueva, sin secrets.

---

## 2. Prerequisitos

- [x] `CLAUDE.md` presente en `gp_3.0_siga_api`
- [x] Rama `develop` existe y está al día
- [x] Campos del CRUD confirmados contra la pantalla real de SIGA (captura de `/Catalogos/Asesores/Edit/3111`)
- [x] Alcance de países confirmado: **solo México** (§3.5)
- [x] Responsable confirmado: Juan Carlos Castellanos Solis
- [x] Confirmado (31-ago): *Administrador General Externo* **sí** puede crear asesores (§12 punto 2). **No quedan decisiones abiertas.**
- [ ] Ambiente de QA arriba para validar (ojo: QA se apaga a las 19:00)
- [ ] Distribuidor y usuario de Omega dados de alta en QA (T-017) para probar el scope con un usuario real

---

## 3. Arquitectura del cambio

Arquitectura vigente: **microservicios en ECS + Fargate** (`rules/arquitectura.md` §1). No se crea
servicio nuevo; todo vive dentro de `Catalogs`.

### 3.1 Estado actual

```
Omega ──► KrakenD ──► Catalogs ──► AdvisorController
                                     ├─ GET  GetAllAdvisors   ✅ existe, genérico, con scope
                                     ├─ GET  GetAdvisorById   ✅ existe, genérico, con scope
                                     ├─ POST                  ❌ no existe
                                     ├─ PUT                   ❌ no existe
                                     └─ DELETE                ❌ no existe
```

### 3.2 Estado objetivo

```
Omega ──► KrakenD ──► Catalogs ──► AdvisorController ──► IAdvisorService ──► asesor
                                     ├─ GET    GetAllAdvisors        (sin cambio)
                                     ├─ GET    GetAdvisorById        (sin cambio)
                                     ├─ POST   CreateAdvisor         [ICanManageAdvisors]
                                     ├─ PUT    UpdateAdvisor/{id}    [ICanManageAdvisors]
                                     └─ DELETE DeactivateAdvisor/{id}[ICanManageAdvisors]  → activo = false
```

### 3.3 Dónde vive la lógica

`AdvisorController` hoy consulta la base **directamente desde el controlador**
(`_dbContext.Set<asesor>()`), sin capa de servicio — es la convención local de `Catalogs`, que
nunca tuvo lógica que encapsular.

`rules/coding-guidelines.md` es explícito en dos puntos que aquí chocan con esa convención: el
código **nuevo** siempre sigue la guía (§3: `Services/` para lógica de negocio, `Interfaces/` para
contratos, máximo 200 líneas por archivo), y el código **existente** no se refactoriza.

**Decisión: la escritura va en `AdvisorService`, la lectura se queda donde está.** Razones:

- Las tres operaciones nuevas comparten validaciones no triviales (RFC único por distribuidor,
  distribuidor dentro del scope). Ponerlas en el controlador las duplicaría tres veces.
- `AdvisorController` ya tiene 230 líneas. Sumarle tres acciones con sus validaciones lo llevaría
  muy por encima del límite de 200.
- No se toca la lectura, así que no hay refactor de código existente.

### 3.4 La tabla es `asesor`, **no** `bmw_asesor`

⚠️ **El CRUD de sales-team de BMW no es reusable.** `BmwRegistrationService.SalesTeam.cs` opera
sobre **`bmw_asesor`**, que es una tabla *distinta* con `id_ejecutivo_fi` e `id_gerente`. La tabla
genérica es **`asesor`**, y es contra la que valida el alta de contrato
(`ContractValidationService.ValidateAdvisorAsync`). Confundirlas produciría asesores que la API
acepta pero que el alta de contrato rechaza.

Lo que **sí** se reutiliza de BMW es el **patrón** del borrado lógico (§3.6), que ya está escrito y
probado.

### 3.5 Alcance de países y el campo `Rfc`

El CRUD se implementa **para México**. El campo del request se llama `Rfc`, pero **su
documentación XML debe listar el nombre que ese mismo dato recibe en cada país**, porque el
endpoint es global aunque la validación sea mexicana.

Los nombres salen de la fuente de verdad de SIGA — `GarantiplusWeb/Resources/{PAIS}.json`, clave
`datofiscalRFC`:

| País | Etiqueta |
|---|---|
| MEX | R.F.C. |
| CHL | RUT |
| COL | N.I.T. |
| ARG | CUIT |
| PER / ECU / PAN | R.U.C. |
| CRI | R.U.T. |
| GTM | N.I.T. |

En Colombia además depende del tipo de persona: **NIT** si es Jurídica, **Cédula de identidad** si
es Natural (constantes `ColAsesorLblNit` / `ColAsesorLblCedula`, `AsesoresController.cs:30-31`).

⚠️ **`tipo_persona` no se expone.** En el modelo `asesor.cs` está marcado `[NotMapped]`: es un campo
de formulario que SIGA usa solo para elegir el mensaje de error del identificador en Colombia. No
se persiste. Meterlo al DTO haría creer que se guarda y se perdería en silencio.

### 3.6 El `DELETE` es borrado lógico

En SIGA el `Delete` de `AsesoresController.cs:279-292` es un **stub vacío**
(`// TODO: Add delete logic here`) que solo redirige al índice. La baja real siempre se hizo desde
`Edit`, moviendo el dropdown *Activo* a *No*. O sea que el borrado lógico ya es el comportamiento
de facto; este plan lo formaliza en un endpoint.

El patrón a replicar sobre `asesor` viene de `BmwRegistrationService.SalesTeam.cs`
(`DeleteAdvisorAsync`), que ya está en producción:

```sql
UPDATE asesor
SET activo = FALSE, updated_at = NOW()
WHERE id_asesor = @id AND activo = TRUE
```

Devuelve `{ id, active: false }`, y **404** con *"El asesor no existe o ya está inactivo."* cuando
no existe o ya estaba inactivo. El `AND activo = TRUE` es lo que hace la operación idempotente y
distingue "no existe" de "ya estaba dado de baja".

---

## 4. Tareas de desarrollo

### Fase 0 — Cimientos del servicio (P1)

- [ ] **T-01** — Crear la estructura de carpetas que `Catalogs` nunca tuvo.
  - Archivos a crear: `Services/Catalogs/Interfaces/` y `Services/Catalogs/Services/`
  - Criterio de completitud: las carpetas existen y el `.csproj` compila sin cambios (los proyectos
    .NET incluyen archivos por convención, no hace falta declararlos).

- [ ] **T-02** — Definir la policy de escritura en `Program.cs`.
  - Archivos a modificar: `Services/Catalogs/Program.cs` (bloque de `AddPolicy`, ~línea 130)
  - Nombre propuesto: `ICanManageAdvisors`. Hoy `Catalogs` solo tiene `IsGeneralAdmin`, `ICanEdit`,
    `ICanReadProductTypes`, `ICanViewReports` e `ICanViewCatalogs`; ninguna sirve, porque todas son
    de lectura o demasiado amplias.
  - Roles (lista cerrada, §12 punto 2): los mismos de `ICanReadProductTypes` **menos `Auditor`** —
    `IsGeneralAdmin`, `IsExternalGeneralAdministrator`, `IsCountryManager`, `IsDistributorUser`,
    `IsDistributorWorkshopUser`, `IsSalesExecutive`, `IsCommercialManager`, `IsSalesman`.
  - Criterio de completitud: la policy existe, está documentada con un comentario que explica de
    qué pantalla de SIGA salen sus roles, y **`Auditor` recibe 403** al intentar escribir.

- [ ] **T-03** — Crear `IAdvisorService` con las tres operaciones de escritura.
  - Archivos a crear: `Services/Catalogs/Interfaces/IAdvisorService.cs`
  - Cada método recibe el `ClaimsPrincipal` y devuelve la tupla `(Result, ErrorMessage, StatusCode)`,
    igual que los servicios de escritura que ya existen en `Contracts`, para que el controlador solo
    mapee y no decida.
  - Criterio de completitud: interfaz con XML docs **en inglés** (`coding-guidelines.md` §1) y
    registrada en DI (`builder.Services.AddScoped<IAdvisorService, AdvisorService>()`).

### Fase 1 — Validaciones compartidas (P1)

- [ ] **T-04** — Implementar la validación de scope del distribuidor destino.
  - Archivos a crear/modificar: `Services/Catalogs/Services/AdvisorService.cs`
  - El usuario solo puede crear o mover asesores a distribuidores **dentro de su scope**. Se reusa
    el mismo switch por rol que ya aplica `AdvisorController` en la lectura: `IsGeneralAdmin` sin
    filtro; `IsExternalGeneralAdministrator` / `IsCountryManager` por `proyecto_usuario`; el resto
    por `usuario_distribuidor`.
  - ⚠️ **Se valida en el servidor.** En SIGA el dropdown ya viene acotado (`SetupBags`), pero un
    cliente de API manda el `id_distribuidor` que quiera.
  - Criterio de completitud: un `Usuario Distribuidor` recibe **403** al crear un asesor en un
    distribuidor que no es suyo, aunque el id exista.

- [ ] **T-05** — Implementar la validación de RFC único por distribuidor.
  - Archivos a modificar: `Services/Catalogs/Services/AdvisorService.cs`
  - Porta `CheckRFC` (`AsesoresController.cs:297`): comparación **trim + lower**, acotada al
    distribuidor, **no global**. Mensaje: *"Ya existe un asesor con el mismo R.F.C. para el
    distribuidor especificado"*.
  - Aplica al crear **y** al actualizar; al actualizar debe **excluir el propio `id_asesor`**, o
    guardar un asesor sin cambiarle el RFC fallaría contra sí mismo.
  - Criterio de completitud: crear un duplicado da **409**; guardar un asesor existente sin tocarle
    el RFC da **200**.

### Fase 2 — Las tres operaciones (P1)

- [ ] **T-06** — `CreateAdvisorRequest` + `POST CreateAdvisor`.
  - Archivos a crear: `DTOs/Advisors/CreateAdvisorRequest.cs`; modificar `AdvisorController.cs`
  - Campos: `Name`, `FirstLastName`, `SecondLastName` (opcional), `Rfc`, `DealerId`. `Active` **no**
    se recibe: un asesor nace activo.
  - **No se exponen** `numero_empleado`, `clabe` ni `numero_tarjeta` (§12 punto 3).
  - El `summary` de `Rfc` lleva la tabla de nombres por país de §3.5.
  - `LogRequestAsync` con `JsonSerializer.Serialize(request)` por ser POST con body (regla de 4
    argumentos del repositorio).
  - Criterio de completitud: crea el asesor, devuelve **201** con el `id`, y el asesor recién creado
    **sirve para dar de alta un contrato** (`ValidateAdvisorAsync` lo encuentra).

- [ ] **T-07** — `UpdateAdvisorRequest` + `PUT UpdateAdvisor/{id}`.
  - Archivos a crear: `DTOs/Advisors/UpdateAdvisorRequest.cs`; modificar `AdvisorController.cs`
  - Mismos campos que el create **más `Active`**, porque en SIGA la reactivación de un asesor se
    hace justamente por aquí (el dropdown Activo del `Edit`).
  - Debe validar el scope **del distribuidor actual y del nuevo** si el asesor se mueve de
    distribuidor; si no, un usuario podría sacar un asesor de su scope o meter uno ajeno al suyo.
  - Criterio de completitud: actualiza y devuelve **200**; da **404** si el asesor no existe y
    **403** si cae fuera de scope por cualquiera de los dos lados.

- [ ] **T-08** — `DELETE DeactivateAdvisor/{id}` (borrado lógico).
  - Archivos a crear: `DTOs/Advisors/AdvisorDeactivationResponse.cs`; modificar `AdvisorController.cs`
  - Implementa el patrón de §3.6: `UPDATE ... SET activo = FALSE, updated_at = NOW() WHERE
    id_asesor = @id AND activo = TRUE`.
  - Devuelve `{ id, active: false }`; **404** con *"El asesor no existe o ya está inactivo."*
  - Criterio de completitud: desactiva y devuelve 200; **la fila sigue existiendo en la base** con
    `activo = false`; una segunda llamada da 404; y el asesor desactivado **ya no sirve** para dar
    de alta un contrato.

### Fase 3 — Exposición y validación (P1)

- [ ] **T-09** — Dar de alta las tres rutas en KrakenD.
  - Archivos a modificar: `Services/ApiGateway/krakend.json`
  - Criterio de completitud: las tres responden **a través del gateway** en QA, no solo directo al
    contenedor. **Sin este paso los endpoints dan 404 aunque el servicio esté bien.**

- [ ] **T-10** — Matriz de pruebas de autorización y scope en QA.
  - Probar con al menos tres usuarios: `Administrador General`, `Usuario Distribuidor` (el de Omega)
    y `Auditor`.
  - Criterio de completitud: existe una tabla usuario × operación × resultado esperado, ejecutada y
    con todos los casos en verde. Como mínimo: Auditor recibe 403 en las tres escrituras; el usuario
    de Omega solo puede tocar asesores de su distribuidor; el Administrador General puede todo.

- [ ] **T-11** — Prueba de extremo a extremo con Omega.
  - Depende de T-017 (alta de Omega en QA).
  - Criterio de completitud: `UsuarioOMEGA` crea un asesor, lo edita, **da de alta un contrato
    usándolo**, lo desactiva, y confirma que un contrato nuevo con ese asesor ya es rechazado.

- [ ] **T-12** — Desplegar a QA y luego a PROD con la skill `deploy-qa-prod`.
  - Incluye redesplegar **ApiGateway** en ambos ambientes por el cambio de `krakend.json`.
  - Criterio de completitud: las tres rutas vivas en PROD y la lectura de asesores sin regresión.

---

## 5. Cambios en base de datos

**Ninguno.** La tabla `asesor` ya tiene todo lo necesario, incluida la columna `activo` (`NOT NULL`,
default `true`) y `updated_at`. No hay migraciones, ni índices nuevos, ni `GRANT` que otorgar.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `/catalogs/api/Advisor/v1/CreateAdvisor` | Alta de asesor. Nace activo. | **Nuevo** |
| PUT | `/catalogs/api/Advisor/v1/UpdateAdvisor/{id}` | Edición, incluida la reactivación vía `Active`. | **Nuevo** |
| DELETE | `/catalogs/api/Advisor/v1/DeactivateAdvisor/{id}` | **Borrado lógico**: `activo = false`. No borra la fila. | **Nuevo** |
| GET | `/catalogs/api/Advisor/v1/GetAllAdvisors` | **Sin cambio.** | Sin tocar |
| GET | `/catalogs/api/Advisor/v1/GetAdvisorById/{id}` | **Sin cambio.** | Sin tocar |

> Las rutas siguen el patrón `v1/[action]` que ya usa `AdvisorController`, no kebab-case REST. Es
> una divergencia consciente respecto a `coding-guidelines.md` §5: dentro de un controlador
> existente manda la consistencia local, porque mezclar los dos estilos en el mismo controlador es
> peor que cualquiera de los dos.

---

## 7. Variables de entorno y configuración

**Ninguna.** No se agregan variables ni secrets.

---

## 8. Consideraciones de seguridad

- **Esta es la primera superficie de escritura de `Catalogs`.** Hasta hoy el servicio no podía
  modificar nada; después de esto sí. La policy `ICanManageAdvisors` y la validación de scope de
  T-04 son lo único que separa a un usuario de escribir en el catálogo de otro distribuidor.
- **El scope se valida en el servidor, siempre.** SIGA se apoyaba en que el dropdown venía acotado;
  un cliente de API no tiene dropdown. Aplica al `DealerId` de entrada tanto en create como en
  update.
- **`Auditor` no escribe.** Es lectura por diseño en SIGA y así debe quedar.
- **Borrado lógico, no físico.** Los asesores están referenciados por `contrato.id_asesor`; un
  `DELETE` real rompería el histórico de contratos. El endpoint nunca debe borrar la fila.
- **Rate limiting:** `Restrictive` en las tres escrituras. La lectura conserva `Heavy`.
- Sin datos sensibles nuevos, sin cambios de IAM, sin secrets.

---

## 9. Consideraciones de infraestructura

- Sin servicios AWS nuevos y sin costo adicional.
- Se redespliegan dos contenedores ECS existentes: `Catalogs` y `ApiGateway`.
- **ApiGateway es obligatorio** en QA y PROD por el cambio de `krakend.json`.
- ⚠️ Al reconstruir la imagen para PROD, verificar
  `git diff --stat release origin/pre-qa -- Services/Catalogs/` y usar **etiqueta de ECR nueva** si
  difiere. Reusar etiqueta sobreescribe la imagen de QA en silencio.

---

## 10. Criterios de aceptación

- [ ] Omega crea, edita y desactiva asesores de su propio distribuidor por API.
- [ ] Un asesor creado por la API **sirve para dar de alta un contrato**; uno desactivado ya no.
- [ ] El `DELETE` **no borra la fila**: queda con `activo = false` y `updated_at` actualizado.
- [ ] Una segunda llamada al `DELETE` del mismo asesor devuelve 404, no 200.
- [ ] Un asesor desactivado se puede reactivar con el `PUT` (`Active = true`).
- [ ] El RFC duplicado dentro del mismo distribuidor se rechaza con 409; el mismo RFC en otro
      distribuidor se acepta.
- [ ] Guardar un asesor sin cambiarle el RFC **no** falla contra sí mismo.
- [ ] Un usuario recibe 403 al escribir sobre un distribuidor fuera de su scope, y `Auditor` recibe
      403 en las tres escrituras.
- [ ] La lectura (`GetAllAdvisors`, `GetAdvisorById`) sigue funcionando igual que antes.
- [ ] Las tres rutas responden a través de KrakenD en QA y en PROD.
- [ ] El `summary` del campo `Rfc` documenta el nombre por país.
- [ ] No hay cambios en base de datos.

---

## 11. Riesgos técnicos identificados

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|---|
| R-1 | Se implementa el CRUD sobre `bmw_asesor` en vez de `asesor`, y los asesores creados no sirven para dar de alta contratos | Baja | **Alto** | Está advertido en §3.4. El criterio de T-06 exige probar que el asesor creado pasa `ValidateAdvisorAsync` |
| R-2 | El `DELETE` se implementa como borrado físico y rompe el histórico de contratos que referencian al asesor | Baja | **Muy alto** | §3.6 y §8 lo dicen explícitamente; el criterio de T-08 exige verificar **en la base** que la fila sigue ahí |
| R-3 | La validación de RFC único no excluye el propio id al actualizar, y editar un asesor sin tocarle el RFC falla | **Alta** | Medio | Es el error clásico de esta validación. T-05 lo cubre con un criterio de aceptación propio |
| R-4 | El scope solo se valida en el `GET` y no en las escrituras, permitiendo crear asesores en distribuidores ajenos | Media | **Alto** | T-04 es una tarea dedicada a esto y T-10 lo prueba con un usuario real fuera de scope |
| R-5 | Se despliega `Catalogs` sin `ApiGateway` y las rutas nuevas dan 404 | Media | Medio | Escrito en T-09, T-12 y §9. Es un error conocido y recurrente del repositorio |
| R-6 | Se hereda la inconsistencia de roles de SIGA (Create GET permite un rol que el POST rechaza) | **Baja** | Bajo | Cerrado el 31-ago: la lista de roles está decidida y escrita en §12 punto 2, y T-02 la implementa tal cual |
| R-7 | La validación en QA se cae por el apagado automático de las 19:00 | Media | Bajo | Agendar las pruebas antes de esa hora; un 503 a esa hora es el apagado, no un bug |

---

## 12. Notas para el programador

1. **Este plan no tiene PRD.** Se generó por decisión explícita del responsable para desbloquear a
   Omega. La carpeta se llamó `crud-asesores-catalogos` sin folio `PJ####` a propósito, siguiendo el
   precedente de `Go Virtual/atenea-go-virtual` y del plan hermano `SIGA/payment-link-generico`.

2. **RESUELTO (31-ago) — *Administrador General Externo* SÍ puede crear asesores.** En SIGA hay una
   **inconsistencia**: el `Create` GET permite ese rol (`AsesoresController.cs:150`) pero el
   `Create` POST **no** (`línea 162`), así que hoy ese usuario abre el formulario y se come un 403
   al guardar. En `Edit` sí está permitido en ambos. El responsable decidió **permitirlo**, por
   coherencia con que ese rol ya puede editar asesores: si puede modificar uno existente, negarle
   crearlo no protege nada. La API **no hereda el bug**.

   Lista final de roles de `ICanManageAdvisors` (T-02) — los mismos de `ICanReadProductTypes`
   **menos `Auditor`**: `IsGeneralAdmin`, `IsExternalGeneralAdministrator`, `IsCountryManager`,
   `IsDistributorUser`, `IsDistributorWorkshopUser`, `IsSalesExecutive`, `IsCommercialManager`,
   `IsSalesman`.

3. **Los tres campos que SIGA dejó de capturar.** `numero_empleado`, `clabe` y `numero_tarjeta`
   existen en la tabla `asesor`, pero el bloque del formulario que los capturaba está dentro de un
   comentario Razor `@* *@` en `_EditMEX.cshtml` — está muerto. **Recomendación: no exponerlos en
   v1.** Reactivar por API una captura que negocio retiró de la pantalla es tomar una decisión de
   producto por la puerta de atrás. Si alguien los necesita, se agregan después sin romper nada.

4. **`tipo_persona` no va en el DTO.** Es `[NotMapped]` en el modelo: campo de formulario, no
   columna. Solo sirve para elegir el mensaje del identificador en Colombia.

5. **No refactorizar la lectura.** `AdvisorController` consulta la base directo desde el
   controlador. Es deuda, pero `rules/coding-guidelines.md` prohíbe refactorizar código existente
   sin petición explícita. La escritura sí va en `AdvisorService` porque es código nuevo (§3.3).

6. **Detalle cosmético de SIGA web, fuera de alcance de este plan:** la pantalla de editar asesor
   tiene el título *"Actualización de gerente comercial"*, copiado del catálogo de gerentes
   (`Edit.cshtml:4`). Si alguien toca esa vista, aprovechar para corregirlo.

7. **Relación con otras tareas.** Este plan es T-022 del tablero. Nace de la subtarea 4 de T-017,
   que se movió aquí al crecer de "falta el POST" a un CRUD completo. **T-017 no depende de este
   plan** para cerrarse: su parte de alta de datos y la consulta de asesores ya están resueltas. Lo
   que sí depende es que Alexis administre sus propios asesores.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Cimientos del servicio** | Carpetas `Services/` e `Interfaces/`, policy de escritura, `IAdvisorService` | T-01 a T-03 | 1 – 2 días | 242 |
| **Fase 1 — Validaciones compartidas** | Scope del distribuidor destino, RFC único por distribuidor | T-04 a T-05 | 1 – 2 días | 243 |
| **Fase 2 — Las tres operaciones** | Create, Update y Deactivate con sus DTOs | T-06 a T-08 | 2 – 3 días | 244 |
| **Fase 3 — Exposición y validación** | KrakenD, matriz de autorización, e2e con Omega, deploy QA + PROD | T-09 a T-12 | 2 – 3 días | 245 |
| **Total proyecto** | Todo es P1 | 12 tareas | ~6 – 10 días hábiles (≈ 1.5 – 2 semanas) | — |

> **Notas sobre la tabla:**
> - La Fase 0 parece desproporcionada para "crear dos carpetas y una policy", pero **no lo es**: es
>   donde se decide cómo `Catalogs` deja de ser un servicio de solo lectura. Esa decisión la van a
>   heredar todos los catálogos que necesiten escritura después de éste.
> - La Fase 1 va antes que las operaciones a propósito: las dos validaciones son compartidas por
>   create y update, y escribirlas después obligaría a retocar ambas.
> - Los rangos salen de la complejidad real de cada tarea. **No queda ninguna decisión abierta**: la
>   única que había (§12 punto 2) se cerró el 31-ago, así que el plan es ejecutable de punta a punta.
> - La columna **ID (BD)** la llena el flujo al registrar el plan; no editarla a mano.

> **Riesgo de deadline:** no hay fecha límite comprometida, porque no hay PRD que la fije. El
> disparador es Omega. Este plan **no bloquea a T-017**: Omega puede empezar a operar en QA con el
> asesor semilla que crean los scripts de alta, y este CRUD es lo que le permite después
> administrar los suyos sin pedirle nada a nadie. Si hubiera prisa, lo único recortable con sentido
> es la Fase 3 T-11 (el e2e con Omega), y aun así no conviene: es la única prueba que confirma que
> un asesor creado por API sirve de verdad para vender. Un segundo desarrollador aportaría poco:
> son 12 tareas secuenciales sobre los mismos tres archivos.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
