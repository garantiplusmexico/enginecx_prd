# Plan de Desarrollo — Fecha de colocación retroactiva en el landing de Bridgestone (SIGA)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ0221-bs-fecha-colocacion/PRD.md` |
| Repositorio | **2 repos:** `gp_3.0_siga_api` (backend, servicio `Contracts`) y `bridgestone_landing` (frontend) |
| Rama | `feature/PJ0221-bs-fecha-colocacion` (misma en ambos repos) |
| Tipo | Feature |
| Responsable | Javier Antonio Oropeza Camacho |
| Folio PRD | `PJ0221` |
| Fecha de generación | 2026-08-20 |
| Estado | Borrador |
| ID plan (BD) | `51` (pm_plan_desarrollo.id) |
| Rama base | `develop` (existe en ambos repos; ya sincronizada con `origin/develop`) |
| Modelo / esfuerzo | `claude-opus-5` — esfuerzo alto |

---

## 1. Resumen técnico

Se expone la **fecha de colocación** del contrato en el landing de Bridgestone y se habilita
retroactividad de hasta 3 días naturales **sin salir del mes en curso**, con habilitación
**por proyecto/canal** en el servicio compartido de creación de contratos.

**Hoy la fecha no existe como dato de entrada.** Se fija en el backend en un solo lugar:

- `Services/Contracts/Services/Bs/BridgestoneLandingContractRequestFactory.cs:193` →
  `BuildProduct(...)` asigna `StartDate = DateTime.UtcNow.Date`.
- Ese `Product.StartDate` termina en `contrato.fecha_inicio` y `poliza.fecha_inicio`
  (`ContractCreationService.cs:258` y `:272`) — **es la fecha que factura**.
- La puerta dura está en `Services/Contracts/Services/ContractCreationService.cs:429`:
  `if (request.Product.StartDate.Date < DateTime.Today) → "Contract start date cannot be in the past"`.
  Vive en `ValidateBusinessRules`, dentro del servicio **compartido** con BMW, financieras y WhatsApp.

**Componentes que se crean:**

| Componente | Repo | Rol |
|---|---|---|
| `IBusinessClock` / `BusinessClock` | API · `Services/Contracts` | Único "hoy" del proyecto, resuelto en la zona horaria del país (configurable). Cierra RNF-08. |
| `ContractBackdatingOptions` | API · `Options/` | Días máximos y permiso de cruce de mes **por proyecto** (`IOptions<T>`, RF-11 / RNF-04). |
| `IPlacementDateWindowService` / `PlacementDateWindowService` | API · `Services/` | Calcula y valida la ventana. Única fuente de verdad consumida por landing, reanudación, endpoint de ventana y servicio compartido. |
| `GET v1/placement-window/{projectId}` | API · `BridgestoneController` | El front lee la ventana **del backend**, no del reloj del navegador. |
| `lib/placementWindow.ts` | Landing | Parseo/formateo `yyyy-MM-dd` y cálculo de respaldo, con pruebas Vitest. |

**Componentes que se modifican:** `CreateBridgestoneLandingContractForm`,
`BridgestoneLandingContractRequestFactory` (ambos `partial`), `BridgestoneRegistrationPayload`,
`BridgestoneRegistrationService` (INSERT), `BridgestoneRegistroSnapshot`,
`BridgestoneBsRegistroQueryService` (SELECT de reanudación), `BridgestoneController`,
`ContractCreationService` + `IContractCreationService`, `BmwController` (solo la llamada),
`appsettings.json` y task definitions de QA/prod. En el landing: `types.ts`, `initialFormData.ts`,
`InvoicePurchaseSection.tsx`, `DateInput.tsx`, `validation.ts`, `sigaService.ts`,
`RegistrationPortal.tsx`, `PendingContractsView.tsx`.

**Stack (se respeta el existente, `rules/stack.md`):** backend .NET 8 / C# con EF Core + Npgsql;
frontend React 19 + Vite 6 + TypeScript; BD PostgreSQL (RDS); despliegue ECS + Fargate (API) y
S3 + CloudFront (landing). **No se introduce tecnología nueva ni se refactoriza código existente.**

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable
- [ ] Acceso a `gp_3.0_siga_api` y `bridgestone_landing` confirmado (ambos ya clonados y en `develop`)
- [ ] **Decisión sobre la dependencia de zona horaria** (ver §12, punto 1) — es lo único que puede
      invalidar la regla completa. El plan trae una mitigación acotada (T-01), no el bugfix general.
- [ ] Confirmar el valor de configuración por ambiente: `MaxBackdatingDays = 3`,
      `AllowMonthCrossing = false`, `ProjectId` de Bridgestone (`141` en el `.env` del landing;
      **confirmar el de QA y prod**)
- [ ] Acceso a la BD de cada ambiente para aplicar el `ALTER TABLE` de `bs_registro` (T-08)
- [ ] `CLAUDE.md` presente en ambos repos — ✅ ya existía en `gp_3.0_siga_api`; **creado en este flujo**
      para `bridgestone_landing`
- [ ] Nota operativa del repo de API: **no se ejecutan `dotnet build` / `dotnet run` / `docker-compose`
      automáticamente** (regla de su `CLAUDE.md`); los compila y reinicia el desarrollador

---

## 3. Arquitectura del cambio

Arquitectura existente: **microservicios en contenedores** (`rules/arquitectura.md` §1) para la API y
**frontend estático separado** (§2) para el landing. El cambio no altera la arquitectura: agrega un
servicio de dominio dentro del microservicio `Contracts` y un campo en el SPA.

```
[Landing BS — React/S3]
   │  1. GET  /contracts/api/Bridgestone/v1/placement-window/{projectId}   ← ventana calculada por el backend
   │  2. POST /contracts/api/Bridgestone/v1/contracts/{projectId}          ← multipart + PlacementDate (yyyy-MM-dd)
   ▼
[Contracts — ECS/Fargate]
   ├── BridgestoneController ──── LogRequestAsync (auditoría: incluye PlacementDate)
   ├── BridgestoneLandingContractRequestFactory
   │      ├── PlacementDateWindowService.Validate(projectId, date)  → errores de negocio acumulados
   │      └── BuildProduct(StartDate = fecha validada)
   ├── BridgestoneRegistrationService → INSERT bs_registro (fecha_colocacion)
   └── ContractCreationService  ← SERVICIO COMPARTIDO (BMW · financieras · WhatsApp)
          └── ValidateBusinessRules(projectId, …)
                 └── ¿projectId en ContractBackdating:Projects?
                        Sí → permite pasado dentro del límite configurado del proyecto
                        No → rechaza el pasado EXACTAMENTE como hoy   ← default seguro
   ▼
[PostgreSQL RDS] contrato.fecha_inicio · poliza.fecha_inicio · bs_registro.fecha_colocacion
```

**Tres decisiones de arquitectura que sostienen el diseño:**

1. **Un solo "hoy".** `IBusinessClock` es la única fuente de la fecha del día para todo lo que toca
   este proyecto (cálculo de ventana, validación del landing, validación del servicio compartido,
   endpoint de ventana). Dos referencias distintas producen rechazos inexplicables en los bordes
   (RNF-08, riesgo #4 del PRD).
2. **El front no calcula la ventana; la pide.** El selector se acota con los límites que devuelve el
   backend. Si el endpoint falla, se cae al cálculo local (`lib/placementWindow.ts`) — degradación,
   no fuente de verdad. El backend revalida siempre (RNF-01).
3. **La habilitación se resuelve por configuración del `projectId` de la ruta**, nunca por un dato del
   request (RNF-02). El default de un proyecto no listado es el comportamiento actual (RF-10, RNF-03).

---

## 4. Tareas de desarrollo

### Fase 0 — Referencia de "hoy" y configuración de la ventana *(habilitadores, repo API)*

- [ ] **T-01** — Crear `IBusinessClock` / `BusinessClock`: `TodayInBusinessTimeZone` resuelto con
      `TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, tz)` a partir de `BusinessTime:TimeZoneId`
      (default `America/Mexico_City`). Registrar en DI.
  - Archivos a crear/modificar: `Services/Contracts/Interfaces/IBusinessClock.cs`,
    `Services/Contracts/Services/BusinessClock.cs`,
    `Services/Contracts/Options/BusinessTimeOptions.cs`, `Services/Contracts/Program.cs`,
    `Services/Contracts/appsettings.json`
  - Criterio de completitud: a las 19:00 h de México, `TodayInBusinessTimeZone` devuelve **el día en
    curso local**, no el siguiente (contraste directo con `DateTime.UtcNow.Date`, que ya rueda a las
    18:00 h). Ningún consumidor nuevo usa `DateTime.Today` ni `DateTime.UtcNow` para "hoy".

- [ ] **T-02** — `ContractBackdatingOptions` con sección `ContractBackdating`: lista de proyectos
      habilitados, cada uno con `ProjectId`, `MaxBackdatingDays`, `AllowMonthCrossing`. Validator
      (`IValidateOptions<T>`, mismo patrón que `ContractTireLimitsOptionsValidator`) que rechaza
      `MaxBackdatingDays < 0` y `ProjectId < 1`. Registrar en `Program.cs`.
  - Archivos a crear/modificar: `Services/Contracts/Options/ContractBackdatingOptions.cs`,
    `Services/Contracts/Program.cs`, `Services/Contracts/appsettings.json`
  - Criterio de completitud: arrancar sin la sección deja **cero** proyectos retroactivos
    (comportamiento actual); ningún valor de la regla queda hardcodeado (RF-11 / RNF-04).

- [ ] **T-03** — `IPlacementDateWindowService` / `PlacementDateWindowService`:
      `GetWindow(projectId)` → `(MinDate, MaxDate, MaxBackdatingDays, AllowMonthCrossing, Today)` con
      `MinDate = max(hoy − N días, día 1 del mes)` cuando el cruce de mes está prohibido, y
      `Validate(projectId, date)` → `null` o mensaje **en español que nombra el rango válido**
      (RNF-06). Proyecto no habilitado ⇒ ventana `[hoy, hoy]`.
  - Archivos a crear/modificar: `Services/Contracts/Interfaces/IPlacementDateWindowService.cs`,
    `Services/Contracts/Services/PlacementDateWindowService.cs`,
    `Services/Contracts/Models/Contracts/PlacementDateWindow.cs`, `Services/Contracts/Program.cs`
  - Criterio de completitud: con `N=3` y `AllowMonthCrossing=false`, el día 1 la ventana es
    `[día 1, día 1]`; el día 2, `[día 1, día 2]`; el día 10, `[día 7, día 10]`. Fecha futura ⇒
    siempre inválida.

- [ ] **T-04** — Documentar la configuración y sembrarla por ambiente: sección nueva en
      `Services/Contracts/docs/CONFIGURATION.md` + variables en las task definitions de QA y prod
      (formato ECS con doble guion bajo e índice de arreglo:
      `ContractBackdating__Projects__0__ProjectId`, `…__MaxBackdatingDays`, `…__AllowMonthCrossing`,
      `BusinessTime__TimeZoneId`).
  - Archivos a crear/modificar: `Services/Contracts/docs/CONFIGURATION.md`,
    `Infrastructure/qa/Contracts-task-definition.json`,
    `Infrastructure/prod/Contracts-task-definition.json`
  - Criterio de completitud: la doc dice quién cambia los días, dónde y qué efecto contable tiene.
    Queda escrito que cambiar los días **no** requiere desplegar código, pero **sí** publicar una
    revisión nueva de la task definition.

### Fase 1 — Backend: captura, validación y persistencia

- [ ] **T-05** — Agregar `PlacementDate` (string, `[Required]`) a la forma multipart del landing, con
      XML doc que fija el formato **`yyyy-MM-dd`**.
  - Archivos a crear/modificar:
    `Services/Contracts/DTOs/Bridgestone/Requests/CreateBridgestoneLandingContractForm.cs`
  - Criterio de completitud: Swagger/Scalar muestran el campo y su formato; un POST sin él responde
    400 por `ModelState` (RF-08).

- [ ] **T-06** — En `BuildAsync`: parsear `PlacementDate` **estrictamente** con
      `DateTime.TryParseExact(raw, "yyyy-MM-dd", InvariantCulture, DateTimeStyles.None, out …)`
      — deliberadamente **no** se reutiliza `ParseLandingInvoiceDate`, que prueba varias culturas y
      puede invertir día y mes. Validar con `PlacementDateWindowService` y **acumular en `errors`**
      (nunca excepción). Pasar la fecha validada a `BuildProduct` como `StartDate`, eliminando
      `DateTime.UtcNow.Date`.
  - Archivos a crear/modificar:
    `Services/Contracts/Services/Bs/BridgestoneLandingContractRequestFactory.cs`
  - Criterio de completitud: fecha fuera de ventana ⇒ 400 con el mensaje de rango **junto con** los
    demás errores del registro, en una sola respuesta (RF-06, RF-07). Fecha válida ⇒
    `Product.StartDate` es exactamente la recibida (RF-05).

- [ ] **T-07** — Persistir la fecha solicitada: `PlacementDate` en `BridgestoneRegistrationPayload`
      y columna `fecha_colocacion` en el INSERT de `bs_registro` (parámetro `NpgsqlDbType.Date`,
      mismo patrón que `fecha_factura`).
  - Archivos a crear/modificar: `Services/Contracts/Services/Bs/BridgestoneRegistrationPayload.cs`,
    `Services/Contracts/Services/Bs/BridgestoneRegistrationService.cs`
  - Criterio de completitud: un alta nueva deja `fecha_colocacion` poblada y **distinta** de
    `fecha_creacion` cuando se retrodata (RF-12). `fecha_creacion` no se toca.

- [ ] **T-08** — Script DDL de la columna y aplicación por ambiente:
      `ALTER TABLE bs_registro ADD COLUMN IF NOT EXISTS fecha_colocacion date NULL;`
      Se entrega como script versionado en el PRD (no hay carpeta de migraciones en el repo de API;
      `bs_registro` se accede por SQL crudo con Npgsql y **no tiene entidad EF**, así que no hay que
      replicar nada en `DataAccess` / `DataAccessColombia`).
  - Archivos a crear/modificar:
    `enginecx_prd/SIGA/PJ0221-bs-fecha-colocacion/sql/001_bs_registro_fecha_colocacion.sql`
  - Criterio de completitud: columna **nullable sin default** — los registros previos quedan en `NULL`
    y se interpretan como "sin fecha solicitada" (RF-15, RNF-10). Aplicado en local, QA y prod, en ese
    orden.

- [ ] **T-09** — Incluir `form.PlacementDate` en el objeto `requestData` que se serializa a
      `LogRequestAsync` en `CreateBridgestoneContract` (junto a `form.InvoiceDate`).
  - Archivos a crear/modificar: `Services/Contracts/Controllers/BridgestoneController.cs`
  - Criterio de completitud: el log de auditoría del registro permite reconstruir qué fecha se
    solicitó y cuándo se envió (RF-16, RNF-05). No se registran archivos ni datos sensibles nuevos.

- [ ] **T-10** — **Habilitación por proyecto en el servicio compartido.** Agregar `int projectId` a
      `ValidateContractRequestAsync` (interfaz + implementación) y a `ValidateBusinessRules`.
      Reemplazar la puerta dura de `ContractCreationService.cs:429` por:
      *si `StartDate` es pasada, permitirla solo si el proyecto está configurado como retroactivo y la
      fecha cae dentro de su ventana; en cualquier otro caso, el mismo rechazo de hoy.*
      Actualizar el único llamador externo (`BmwController.cs:1717`) para que pase su `projectId`.
  - Archivos a crear/modificar: `Services/Contracts/Services/ContractCreationService.cs`,
    `Services/Contracts/Interfaces/IContractCreationService.cs`,
    `Services/Contracts/Controllers/BmwController.cs`
  - Criterio de completitud: con la sección `ContractBackdating` vacía, **todos** los canales se
    comportan igual que antes (RF-10, RNF-03). Ningún campo del request puede habilitar retroactividad
    (RNF-02). La fecha futura sigue permitida/rechazada exactamente como hoy — este cambio no la toca.

### Fase 2 — Backend: reanudación de registros pendientes

- [ ] **T-11** — `PlacementDate` (`DateTime?`) en `BridgestoneRegistroSnapshot` y en el SELECT de
      `GetRegistroForResumeAsync` (`fecha_colocacion`, leído como nullable).
  - Archivos a crear/modificar: `Services/Contracts/Models/Bridgestone/BridgestoneRegistroSnapshot.cs`,
    `Services/Contracts/Services/Bs/BridgestoneBsRegistroQueryService.cs`
  - Criterio de completitud: registros previos al cambio devuelven `null` sin error de lectura.

- [ ] **T-12** — En `BuildFromRegistroAsync`: si hay fecha solicitada y **sigue** dentro de la ventana
      calculada al momento de reanudar, usarla (RF-13); si salió de la ventana o es `null`, usar hoy y
      devolver un aviso explícito para el usuario (RF-14, RF-15). **No** se reescribe la columna
      (RNF-09).
  - Archivos a crear/modificar:
    `Services/Contracts/Services/Bs/BridgestoneLandingContractRequestFactory.FromRegistro.cs`
  - Criterio de completitud: registro pendiente del día 31 reanudado el día 2 ⇒ contrato con fecha de
    hoy **y** aviso; `bs_registro.fecha_colocacion` sigue mostrando la fecha original.

- [ ] **T-13** — Propagar el aviso hasta la respuesta del endpoint de regeneración (campo `Message` de
      `CreateContractResponse`, que ya viaja al front en el 201).
  - Archivos a crear/modificar: `Services/Contracts/Services/Bs/BridgestoneContractResumeService.cs`,
    `Services/Contracts/Controllers/BridgestoneController.cs`
  - Criterio de completitud: el 201 de una reanudación con fecha ajustada trae en `message` la fecha
    original, la usada y el motivo — en español.

### Fase 3 — Endpoint de la ventana *(cierra RNF-08)*

- [ ] **T-14** — `GET v1/placement-window/{projectId}` en `BridgestoneController`:
      `[Authorize(Policy = Policies.ICanAccessBridgestone)]`,
      `[EnableRateLimiting(RateLimitPolicyNames.Light)]`, respuesta
      `{ today, minDate, maxDate, maxBackdatingDays, allowMonthCrossing }` en `yyyy-MM-dd`, con XML doc
      completo y `LogRequestAsync` de 3 argumentos (es GET).
  - Archivos a crear/modificar: `Services/Contracts/Controllers/BridgestoneController.cs`,
    `Services/Contracts/DTOs/Bridgestone/Responses/BridgestonePlacementWindowResponse.cs`
  - Criterio de completitud: el endpoint respeta el `accessScope` como los demás del controlador y
    devuelve exactamente los límites que aplicará la validación del POST.

### Fase 4 — Frontend: captura y validación en el landing

- [ ] **T-15** — `placementDate: string` (formato interno `yyyy-MM-dd`) en `WarrantyRegistration`,
      inicializado en hoy.
  - Archivos a crear/modificar: `src/types.ts`,
    `src/features/warranty-registration/initialFormData.ts`
  - Criterio de completitud: el estado nunca guarda la fecha de colocación en `dd/MM/yyyy` — ese
    formato es solo de presentación. (`invoiceDate` se deja como está: fuera de alcance del PRD.)

- [ ] **T-16** — Exponer `minDate` / `maxDate` en `DateInput` (react-datepicker ya los soporta; hoy no
      se pasan).
  - Archivos a crear/modificar: `src/components/ui/DateInput.tsx`
  - Criterio de completitud: "Fecha Factura" no cambia de comportamiento; el campo nuevo sí queda
    acotado y las fechas fuera de rango **no son seleccionables** (RF-02).

- [ ] **T-17** — `lib/placementWindow.ts`: `parseIsoDate`, `formatIsoDate`, `computeLocalWindow`
      (respaldo) y `validatePlacementDate` con mensaje en español que nombra el rango. Pruebas Vitest
      + `fast-check` para los bordes de mes (ambas dependencias ya están en el repo).
  - Archivos a crear/modificar: `src/lib/placementWindow.ts`, `src/lib/placementWindow.test.ts`
  - Criterio de completitud: `pnpm test` pasa; los casos día 1 / día 2 / día 3 y fin de mes están
    cubiertos.

- [ ] **T-18** — Consumir el endpoint de ventana desde `sigaService` y guardar la ventana en el estado
      del portal (se pide al entrar al formulario, con el token ya disponible). Si falla, usar
      `computeLocalWindow` y registrar el aviso.
  - Archivos a crear/modificar: `src/services/sigaService.ts`, `src/types.ts`,
    `src/features/warranty-registration/RegistrationPortal.tsx`
  - Criterio de completitud: el selector y la validación del front usan **la ventana del backend**
    siempre que esté disponible.

- [ ] **T-19** — Campo "Fecha de colocación" en la sección Datos de Compra, **junto a "Fecha
      Factura"**, acotado por la ventana, con texto de ayuda que explique por qué el rango se encoge a
      principio de mes (riesgo #7 del PRD).
  - Archivos a crear/modificar:
    `src/features/warranty-registration/sections/InvoicePurchaseSection.tsx`,
    `src/features/warranty-registration/views/FormView.tsx`
  - Criterio de completitud: el campo aparece inicializado en hoy y editable dentro de la ventana
    (RF-01).

- [ ] **T-20** — Validar la ventana en `validateRegistrationForm` antes de enviar, con `placementDate`
      en `RegistrationFormErrors`.
  - Archivos a crear/modificar: `src/features/warranty-registration/validation.ts`
  - Criterio de completitud: fecha fuera de ventana ⇒ no se envía el POST y se muestra el rango válido
    (RF-03).

- [ ] **T-21** — Enviar `PlacementDate` en `buildBridgestoneContractFormData` (como `yyyy-MM-dd`) y
      agregar `PlacementDate: 'Fecha de colocación'` a `SIGA_VALIDATION_FIELD_LABEL_ES`.
  - Archivos a crear/modificar: `src/services/sigaService.ts`
  - Criterio de completitud: la fecha viaja idéntica en **todos** los lotes cuando el pedido se trocea
    por tope de llantas (RF-04, RF-18).

- [ ] **T-22** — Mostrar el aviso de fecha ajustada al reanudar un registro pendiente (toast con el
      `message` del 201).
  - Archivos a crear/modificar: `src/features/warranty-registration/views/PendingContractsView.tsx`
  - Criterio de completitud: el usuario ve el cambio de fecha; no queda solo en el log (RF-14).

### Fase 5 — Pruebas, no-regresión y despliegue

- [ ] **T-23** — Ejecutar la matriz de casos borde del PRD (§14, QA): días 1, 2 y 3 del mes; último día
      del mes a las 17:59 y a las 18:01 hora local; fecha futura; fecha no parseable; fecha ausente;
      reanudación con cruce de mes; registro previo sin fecha; traslape por VIN al retroceder la fecha.
  - Archivos a crear/modificar: `enginecx_prd/SIGA/PJ0221-bs-fecha-colocacion/QA-casos-borde.md`
  - Criterio de completitud: cada caso con resultado esperado y observado. El caso 18:01 es el que
    demuestra si la dependencia de zona horaria quedó realmente contenida por T-01.

- [ ] **T-24** — **No-regresión de los otros canales** (RNF-03): crear contrato por BMW, por
      financieras y por el flujo de WhatsApp con fecha de inicio pasada y confirmar que **se rechaza**
      igual que antes; y con fecha de hoy, que se crea igual que antes.
  - Archivos a crear/modificar: sección de resultados en `QA-casos-borde.md`
  - Criterio de completitud: cero contratos de BMW/financieras/WhatsApp con `fecha_inicio` en el
    pasado. Es el riesgo más caro del proyecto; sin esta evidencia el plan no se cierra.

- [ ] **T-25** — Configurar QA (task definition + `ALTER TABLE`), validar el flujo end-to-end desde el
      landing de QA y dejar escrito el procedimiento de despliegue a producción.
  - Archivos a crear/modificar: `Infrastructure/qa/Contracts-task-definition.json`, notas de
    despliegue en el PRD
  - Criterio de completitud: un contrato de BS creado en QA con fecha de 2 días atrás tiene
    `contrato.fecha_inicio` = `poliza.fecha_inicio` = la fecha solicitada (RF-17), y su
    `bs_registro.fecha_colocacion` coincide.

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `bs_registro` | Modificación | `ADD COLUMN fecha_colocacion date NULL` — fecha de colocación **solicitada** por el usuario. Nullable sin default: `NULL` = registro previo al cambio o sin fecha solicitada. No sustituye a `fecha_creacion` (auditoría, default de BD) ni a `fecha_factura`. |
| `contrato` | Sin cambio de esquema | `fecha_inicio` empieza a recibir fechas pasadas para el proyecto de BS. Cambia el **dato**, no la estructura. |
| `poliza` | Sin cambio de esquema | Igual que `contrato.fecha_inicio`. |

`bs_registro` se accede por SQL crudo con Npgsql y **no tiene entidad EF**, así que el cambio no se
replica en `DataAccess` (MEX) ni `DataAccessColombia` (COL). No se requiere índice nuevo: en este
alcance no se filtra ni se ordena por la columna.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `contracts/api/Bridgestone/v1/placement-window/{projectId}` | Ventana de colocación vigente (`today`, `minDate`, `maxDate`, `maxBackdatingDays`, `allowMonthCrossing`). Autoridad única del "hoy" para el front. | Nuevo |
| POST | `contracts/api/Bridgestone/v1/contracts/{projectId}` | Acepta el campo multipart `PlacementDate` (`yyyy-MM-dd`), obligatorio, validado contra la ventana. | Modificado |
| POST | `contracts/api/Bridgestone/v1/registrations/{idBsRegistro}/contract` | Usa la fecha solicitada si sigue vigente; si no, hoy, y lo informa en `message`. | Modificado |

Sin cambios de contrato en los endpoints de BMW: solo cambia la firma **interna** de
`ValidateContractRequestAsync` (T-10).

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `BusinessTime__TimeZoneId` | Zona horaria de negocio para resolver "hoy" (`America/Mexico_City`). | Desarrollo / QA / Producción |
| `ContractBackdating__Projects__0__ProjectId` | Id del proyecto de Bridgestone habilitado para retroactividad (confirmar por ambiente; el landing usa `141`). | Desarrollo / QA / Producción |
| `ContractBackdating__Projects__0__MaxBackdatingDays` | Días naturales de retroactividad permitidos (`3`). | Desarrollo / QA / Producción |
| `ContractBackdating__Projects__0__AllowMonthCrossing` | Permiso de cruce de mes (`false`). | Desarrollo / QA / Producción |

En el landing **no se agrega ninguna variable**: la ventana llega del backend y el `projectId` ya
existe (`VITE_BRIDGESTONE_PROJECT_ID`).

> Sobre RNF-04: cambiar los días no requiere desplegar código, pero en ECS los valores viven en la
> task definition, así que sí requiere publicar una revisión nueva y reiniciar el servicio. Si el
> negocio necesita cambiarlo sin intervención de despliegue, habría que moverlo a una tabla de
> parámetros — **fuera del alcance de este PRD**, se deja anotado.

---

## 8. Consideraciones de seguridad

- **Sin permisos nuevos.** El endpoint de ventana reutiliza `Policies.ICanAccessBridgestone` y el
  `accessScope` por proyecto que ya aplica el controlador. El PRD descarta explícitamente crear un
  rol para retrodatar.
- **La habilitación no es manipulable desde el request** (RNF-02): se resuelve por el `projectId` de
  la ruta contra configuración del servidor. No se agrega ningún campo que el cliente pueda enviar
  para auto-habilitarse, y el `projectId` ya se valida contra el `accessScope` del usuario y contra
  la pertenencia del distribuidor al proyecto (`ContractCreationService`, paso 2.1).
- **Rate limiting:** el POST conserva `Restrictive`; el GET de ventana usa `Light`.
- **Sin secretos nuevos.** Los valores de la ventana son parámetros de negocio, no credenciales; van
  en `appsettings` / task definition, nunca en código (`rules/coding-guidelines.md` §11).
- **Auditoría:** solo se agrega una fecha al request serializado. No hay datos personales nuevos.
- **Riesgo de seguridad real del cambio:** que la relajación se filtre a otro canal. Se contiene con
  el default seguro de T-10 y se **verifica** en T-24.

---

## 9. Consideraciones de infraestructura

- **Sin servicios AWS nuevos, sin costo incremental.** Se reutilizan el contenedor `Contracts` en
  ECS + Fargate, RDS PostgreSQL y el hosting S3 + CloudFront del landing.
- **API:** nueva revisión de task definition de `Contracts` en QA y prod (variables de §7) y nueva
  imagen ECR con el código.
- **Landing:** el despliegue es automático por push a `qa` y a `main`
  (`.github/workflows/qa-deploy.yml` / `prod-deploy.yml`) con build pnpm + S3 + invalidación de
  CloudFront. No requiere cambios de pipeline.
- **Orden de despliegue obligatorio:** `ALTER TABLE` → API → landing. El landing envía un campo que
  la API tiene que saber recibir, y `PlacementDate` es obligatorio (RF-08), así que el intervalo
  entre los dos últimos pasos debe ser mínimo y coordinado: mientras la API nueva esté arriba y el
  landing viejo siga en caché de CloudFront, los POST del landing viejo fallarán por `ModelState`.
  Invalidar CloudFront inmediatamente después del despliegue del landing.
- **Cloudflare / Route 53:** sin cambios.

---

## 10. Criterios de aceptación

- [ ] El formulario del landing de BS muestra "Fecha de colocación" junto a "Fecha Factura",
      inicializada en hoy, y el selector no permite elegir fuera de `[max(hoy−3, día 1) … hoy]`
- [ ] Un contrato de BS colocado con 2 días de retroactividad queda con
      `contrato.fecha_inicio` = `poliza.fecha_inicio` = la fecha elegida
- [ ] El día 1 del mes la ventana es solo el día 1, y el mensaje de error lo explica en español
      nombrando el rango
- [ ] Una fecha fuera de ventana enviada por un cliente que no aplicó la regla (p. ej. `curl`) se
      rechaza en el backend con 400 y **junto** con los demás errores del registro
- [ ] `bs_registro.fecha_colocacion` guarda la fecha solicitada; `fecha_creacion` no cambia de
      semántica
- [ ] Reanudar un pendiente cuya fecha sigue vigente usa **esa** fecha; si ya salió de la ventana usa
      hoy, avisa al usuario y **no** reescribe la columna
- [ ] Un registro creado antes del cambio (columna en `NULL`) se reanuda sin error, con fecha de hoy
- [ ] La fecha solicitada aparece en el request serializado del log de auditoría
- [ ] **BMW, financieras y WhatsApp siguen rechazando fechas de inicio pasadas** — verificado con
      evidencia en T-24
- [ ] Con la sección `ContractBackdating` vacía, el sistema completo se comporta como antes del cambio
- [ ] Ningún valor de la regla (3 días, cruce de mes, proyecto habilitado) está hardcodeado
- [ ] `pnpm lint` y `pnpm test` pasan en el landing; el build del servicio `Contracts` compila sin
      advertencias nuevas

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **Dependencia de zona horaria** (`DateTime.UtcNow.Date` vs `DateTime.Today`): de las 18:00 h en adelante el "hoy" en UTC ya es el día siguiente | Alta | Alto | T-01 introduce `IBusinessClock` y **todo** el código nuevo lo usa, así que la ventana de este proyecto se calcula contra un "hoy" local confiable. **No es el bugfix general**: los demás usos de `UtcNow`/`Today` en el servicio compartido siguen como están y son proyecto aparte. Se valida con el caso 18:01 de T-23. |
| Que la retroactividad se filtre a BMW, financieras o WhatsApp | Media | **Muy alto** (facturación de terceros) | Default seguro: proyecto no listado ⇒ rechazo idéntico al actual. Verificación explícita y con evidencia en T-24. Es el criterio que puede detener la liberación. |
| Desajuste de formato de fecha entre front y backend (el formulario ya envía `InvoiceDate` en `dd/MM/yyyy`) | Media | Alto (día y mes invertidos, sin error visible) | Formato único `yyyy-MM-dd` para el campo nuevo, `TryParseExact` en backend (no la ruta multi-cultura de `ParseLandingInvoiceDate`) y el estado del front guarda ISO, no el formato de presentación. |
| "Hoy" divergente entre navegador y servidor | Media | Medio | El front **pide** la ventana al backend (T-14 / T-18); el cálculo local es solo respaldo y el backend revalida siempre. |
| Cambio de firma de `ValidateContractRequestAsync` (interfaz pública del servicio) | Alta | Medio | Un solo llamador externo (`BmwController.cs:1717`); el compilador detecta cualquier otro. Se actualiza en la misma tarea (T-10). |
| Despliegue desincronizado API ↔ landing (`PlacementDate` obligatorio) | Media | Alto (altas rotas) | Orden fijo BD → API → landing, ventana mínima entre los dos últimos e invalidación inmediata de CloudFront (§9). |
| Traslape por VIN al retroceder la fecha | Baja | Medio | Caso explícito en T-23; el VIN se genera por timestamp, así que el traslape real es improbable, pero se prueba. |
| Vigencia acortada al retrodatar (la póliza termina antes) | Media | Bajo/Medio (expectativa del cliente) | Comportamiento conservado a propósito por el PRD. Se documenta; no se cambia el cálculo. |
| Ventana encogida los días 1-2 leída como falla del sistema | Alta | Bajo | Mensaje que nombra el rango (RNF-06) + texto de ayuda en el campo (T-19). |
| Uso de la retroactividad como práctica corriente | Media | Bajo en el MVP | Sin motivo obligatorio ni reporte, por decisión del PRD. Queda medible comparando `fecha_colocacion` con `fecha_creacion`. |

---

## 12. Notas para el programador

1. **La pregunta que hay que responder antes de ejecutar:** ¿se libera este desarrollo antes, después
   o en paralelo al bugfix de zona horaria? El plan lo resuelve **para la ventana** con T-01, pero la
   validación del servicio compartido (`DateTime.Today`, hora local del servidor) y el cálculo actual
   (`DateTime.UtcNow.Date`) conviven hoy con dos referencias distintas. Si se decide unificarlas por
   completo, eso es el bugfix y crece el alcance. **Recomendación:** ejecutar como está —
   `IBusinessClock` deja el terreno listo para que el bugfix lo adopte después.

2. **Por qué la validación no reutiliza `ParseLandingInvoiceDate`.** Ese parser prueba
   `InvariantCulture` y luego `es-MX` / `es-EC` / `es-CL` / `es-ES`; con `03/04/2026` puede resolver
   3 de abril o 4 de marzo según la cultura que gane. Para un dato que factura eso es inaceptable, así
   que el campo nuevo usa `TryParseExact("yyyy-MM-dd")`. `InvoiceDate` se deja intacto: unificar
   formatos es una pregunta abierta del PRD (§14), no una tarea de este plan.

3. **Decisión de diseño que agrega alcance respecto a la lectura literal del PRD:** el endpoint
   `placement-window` (T-14) no está pedido como tal, pero RNF-08 exige la **misma** referencia de
   "hoy" en el selector, la validación del front y la del backend. Sin el endpoint eso no es
   verificable: el navegador del usuario puede estar en otra zona horaria. Es ~1 día de trabajo y
   elimina un riesgo del propio PRD. Si se decide recortarlo, T-17 (`computeLocalWindow`) queda como
   único cálculo del front y se acepta el riesgo de divergencia.

4. **`ContractCreationService.cs` ya pasa de 200 líneas** (767). `rules/coding-guidelines.md` §3 pide
   partir en `partial` al superarlas, y el `CLAUDE.md` del repo lo confirma. **No se refactoriza en
   este plan** (la regla es no tocar código existente sin petición explícita); si se quiere, es una
   tarea aparte. Lo mismo aplica a `BridgestoneController.cs` (773 líneas).

5. **No hay proyectos de test en el repo de API.** Las pruebas del backend son manuales y quedan
   documentadas en `QA-casos-borde.md` (T-23 / T-24). En el landing sí hay Vitest + `fast-check`: la
   lógica de ventana se prueba ahí (T-17), y por eso vale la pena que esa lógica viva en un módulo
   puro y no dentro del componente.

6. **Regla operativa del repo de API:** no ejecutar `dotnet build` / `dotnet run` / `docker-compose`
   automáticamente; los corre el desarrollador. El plan asume eso en cada fase.

7. **Cuidado con el troceo de llantas del landing:** `registerWarranty` puede partir un pedido en
   varios POST. La fecha de colocación debe ser la misma en todos los lotes (hoy el spread
   `{...data, tires}` ya lo garantiza, pero conviene verificarlo en T-21 porque un desfase generaría
   contratos hermanos con fechas distintas).

8. **`fecha_creacion` de `bs_registro` no se toca.** Es auditoría con default de BD. La métrica
   "contratos colocados retroactivamente" del PRD se calcula comparándola contra `fecha_colocacion`.

---

## 13. Relación de tareas y tiempos

Estimación en **días hábiles** para **un (1) desarrollador**, con el repo ya conocido y la BD
accesible.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Reloj de negocio y configuración de la ventana** | `IBusinessClock`, `ContractBackdatingOptions`, `PlacementDateWindowService`, documentación y task definitions | T-01 a T-04 | 2 – 3 días | 166 |
| **Fase 1 — Backend: captura, validación y persistencia** | Campo `PlacementDate`, parseo estricto, validación de ventana, `StartDate` real, columna `fecha_colocacion`, auditoría y habilitación por proyecto en el servicio compartido | T-05 a T-10 | 4 – 6 días | 167 |
| **Fase 2 — Backend: reanudación** | Snapshot con fecha, respeto/recálculo de la fecha original y aviso al usuario | T-11 a T-13 | 2 – 3 días | 168 |
| **Fase 3 — Endpoint de la ventana** | `GET v1/placement-window/{projectId}` (autoridad única del "hoy") | T-14 | 1 – 2 días | 169 |
| **Fase 4 — Frontend: captura y validación** | Campo nuevo acotado, helper de ventana con pruebas, consumo del endpoint, validación y envío `yyyy-MM-dd`, aviso de reanudación | T-15 a T-22 | 3 – 5 días | 170 |
| **Fase 5 — Pruebas, no-regresión y despliegue** | Matriz de casos borde, no-regresión de BMW/financieras/WhatsApp, configuración y validación en QA | T-23 a T-25 | 2 – 3 días | 171 |
| **Total proyecto** | | **25 tareas** | **~14 – 22 días hábiles (≈ 3 – 4.5 semanas)** | — |
| **Mínimo comprometido (guardarraíl)** | Fases 0 + 1 + 3 + 4 + 5 (todo menos reanudación) | T-01 a T-10, T-14 a T-25 | **~12 – 19 días hábiles (≈ 2.5 – 4 semanas)** | — |

> **Notas sobre la tabla:**
> - El PRD define **alcance MVP único, sin fases ni prioridades P1/P2/P3**, así que no hay un
>   guardarraíl reducido preexistente: el total *es* el compromiso. La fila "mínimo comprometido"
>   es la única compresión defensible que identifiqué, no una prioridad del PRD.
> - Si hay que recortar, el único candidato es la **Fase 2 (reanudación)**: diferirla deja los
>   registros pendientes colocando con la fecha del día, que es **exactamente el comportamiento
>   actual** — se pierde la mejora, no se rompe nada. Cualquier otro recorte deja el proyecto sin
>   cumplir su objetivo o sin la verificación de no-regresión, que no es negociable.
> - La Fase 5 no se comprime: sin la evidencia de T-24 no hay forma de afirmar que BMW, financieras
>   y WhatsApp quedaron intactos, y ese es el riesgo más caro del proyecto.
> - Las Fases 1 y 4 pueden solaparse parcialmente con dos desarrolladores (uno en backend, otro en el
>   landing), siempre que el contrato del campo (`PlacementDate`, `yyyy-MM-dd`) se acuerde al terminar
>   T-05. Un segundo recurso comprimiría el calendario aproximadamente **25-30 %**
>   (a ~10-16 días hábiles), no 50 %: las Fases 0, 2 y 5 son secuenciales por dependencia.
> - La columna **ID (BD)** la llena el flujo al registrar el plan en la base de datos
>   (`pm_plan_fase.id`); no editarla a mano.

> **Riesgo de deadline:** **el PRD no fija fecha límite** (no tiene sección de calendario ni fecha
> objetivo), así que no hay días hábiles disponibles contra los cuales contrastar el rango. El riesgo
> de calendario real de este proyecto **no es el esfuerzo, es la dependencia**: la decisión sobre el
> bugfix de zona horaria (§12, punto 1). Mientras no se responda, cualquier fecha de liberación que
> se comprometa lleva un supuesto abierto. **Recomendación:** fijar la fecha objetivo junto con esa
> decisión, y no antes.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`, `CLAUDE.md` de `gp_3.0_siga_api` y `CLAUDE.md` de `bridgestone_landing`*
