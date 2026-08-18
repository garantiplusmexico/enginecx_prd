# Plan de Desarrollo — Portal de Órdenes de Pago

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Desarrollos_internos/PJ4535-portal-de-ordenes-de-pago/PRD.md` (v0.5) |
| Repositorio | *Por crear* — `portal-ordenes-de-pago` en la organización de GitHub de Engine |
| Rama | `feature/portal-de-ordenes-de-pago-mvp` |
| Tipo | Proyecto nuevo |
| Responsable | Aldo Álvarez |
| Folio PRD | `PJ4535` |
| Fecha de generación | 2026-08-13 |
| Estado | Borrador |
| ID plan (BD) | `35` |

---

## 1. Resumen técnico

Se construye desde cero una aplicación web interna que centraliza la autorización de gastos del Grupo Engine CX. Son dos componentes nuevos: una **API REST en .NET Core 8 con C#** y un **frontend en React**, comunicados por HTTP y desplegados como contenedores independientes en **ECS + Fargate**. La persistencia va en **PostgreSQL** (RDS en producción) y los documentos —cotizaciones y facturas— en **S3**.

La identidad se resuelve con **SSO de Google Workspace**: el backend valida el token de Google y emite su propio JWT con los roles del portal. No se administran contraseñas.

El corazón técnico del sistema es el **motor de reglas de autorización**: a partir de la empresa que absorbe el gasto y del monto total con impuestos —convertido previamente a la moneda de esa empresa— determina qué nivel jerárquico está facultado para autorizar. Ese motor concentra la mayor densidad de reglas del proyecto y por eso se aísla como servicio propio, con pruebas unitarias exhaustivas de las fronteras de cada rango. Todo lo demás del sistema es, en comparación, CRUD con estados.

Alcance de este plan: **la Fase 1 (MVP) del PRD**. El registro del pago ejecutado, los tableros de cierre financiero y las integraciones con contabilidad y proveedores quedan fuera, conforme a las Fases 2 y 3 del PRD.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable — **cumplido**: PRD v0.5 aprobado y publicado
- [ ] Repositorio creado en GitHub con las cuatro ramas obligatorias (`main`, `develop`, `pre-qa`, `qa`)
- [ ] `CLAUDE.md` presente en el repositorio — **cumplido**
- [ ] Consola AWS destino definida (Engine transversal) y permisos IAM para crear ECS, RDS y S3
- [ ] Proyecto en Google Cloud Console con credenciales OAuth 2.0 y dominios del grupo autorizados
- [ ] Cuenta o alias de Google Workspace desde la cual el portal enviará las notificaciones
- [ ] Token de la API de Banxico (gratuito, requiere registro) para el tipo de cambio del peso mexicano
- [ ] Cuentas personales de Google Workspace de Ilse García y Brian — hoy figuran como buzones compartidos y sin ellas no pueden autorizar
- [ ] Fuente de tipo de cambio definida para peso colombiano y peso chileno (pregunta abierta del PRD)

---

## 3. Arquitectura del cambio

**Arquitectura aplicada: frontend + backend separados (componentes).**

Siguiendo el árbol de decisión de `rules/arquitectura.md`: el proyecto **no** tiene múltiples dominios de negocio independientes —es un único dominio, la autorización de gastos— pero **sí** necesita base de datos y lógica de negocio en el servidor. Eso descarta tanto los microservicios (complejidad injustificada para un dominio único) como el frontend estático en S3 sin backend. La arquitectura monolítica queda descartada por la propia regla de Engine para proyectos nuevos.

```
[React SPA]  →  [API .NET Core 8]  →  [PostgreSQL / RDS]
     ↓                  ↓
[Google SSO]      [S3: cotizaciones y facturas]
                        ↓
        [Google Workspace: correo]  [Banxico / BCE: tipo de cambio]
```

Dentro del backend, el motor de reglas se aísla en su propia capa de servicios sin dependencias de infraestructura, de modo que sea probable unitariamente sin base de datos ni HTTP. Es la decisión de diseño más importante del plan: si el motor de reglas queda acoplado al acceso a datos, verificar las fronteras de la matriz —donde vive el riesgo real del sistema— se vuelve caro y se deja de hacer.

---

## 4. Tareas de desarrollo

### Fase 0 — Andamiaje e infraestructura base

- [ ] **T-01** — Crear el repositorio y las cuatro ramas obligatorias
  - Archivos a crear/modificar: `.gitignore`, `README.md`
  - Criterio de completitud: existen `main`, `develop`, `pre-qa` y `qa` en el remoto, y `CLAUDE.md` está versionado

- [ ] **T-02** — Solución .NET Core 8 con la estructura de carpetas de Engine
  - Archivos a crear/modificar: `PortalOrdenesPago.sln`, `src/Api/Program.cs`, `src/Api/Controllers/`, `src/Api/Services/`, `src/Api/Interfaces/`, `src/Api/DTOs/`, `src/Api/Models/`, `src/Api/Options/`
  - Criterio de completitud: la API arranca en local y responde el endpoint de health check

- [ ] **T-03** — Proyecto React con layout, ruteo y cliente HTTP
  - Archivos a crear/modificar: `frontend/src/App.tsx`, `frontend/src/routes/`, `frontend/src/api/client.ts`
  - Criterio de completitud: la SPA compila, navega entre rutas vacías y consume el health check de la API

- [ ] **T-04** — PostgreSQL local y capa de acceso a datos con migraciones
  - Archivos a crear/modificar: `src/Api/Data/AppDbContext.cs`, `src/Api/Migrations/`
  - Criterio de completitud: `dotnet ef database update` crea la base vacía y la API conecta

- [ ] **T-05** — Dockerfiles y composición local
  - Archivos a crear/modificar: `src/Api/Dockerfile`, `frontend/Dockerfile`, `docker-compose.yml`
  - Criterio de completitud: `docker compose up` levanta API, frontend y base de datos y el flujo local funciona end-to-end

- [ ] **T-06** — Despliegue base en ECS + Fargate para el ambiente de desarrollo
  - Archivos a crear/modificar: `infra/task-definition.json`, `infra/README.md`
  - Criterio de completitud: ambos contenedores corren en ECS detrás del ALB y responden por una URL de Route 53

### Fase 1 — Identidad, catálogos y modelo de datos

- [ ] **T-07** — Autenticación con Google Workspace y emisión de JWT propio
  - Archivos a crear/modificar: `src/Api/Services/GoogleAuthService.cs`, `src/Api/Services/TokenService.cs`, `src/Api/Controllers/AuthController.cs`, `src/Api/Options/GoogleAuthOptions.cs`
  - Criterio de completitud: un usuario del dominio del grupo inicia sesión y recibe un JWT con su identidad; una cuenta ajena al dominio es rechazada

- [ ] **T-08** — Inicio de sesión y manejo de sesión en el frontend
  - Archivos a crear/modificar: `frontend/src/auth/`, `frontend/src/routes/Login.tsx`
  - Criterio de completitud: el usuario entra con su cuenta de Google, la sesión persiste al recargar y el cierre de sesión invalida el token local

- [ ] **T-09** — Alta automática del solicitante en el primer ingreso (RF-29)
  - Archivos a crear/modificar: `src/Api/Services/UserProvisioningService.cs`
  - Criterio de completitud: una cuenta válida del grupo que nunca ha entrado queda registrada como solicitante sin intervención de un administrador, y no obtiene ningún rol adicional

- [ ] **T-10** — Esquema de catálogos: empresas, usuarios, roles, analistas y matriz versionada
  - Archivos a crear/modificar: `src/Api/Models/Catalog/`, `src/Api/Migrations/`
  - Criterio de completitud: las migraciones crean las tablas de la §5 y las restricciones de integridad se cumplen

- [ ] **T-11** — Carga inicial de catálogos desde los CSV del PRD
  - Archivos a crear/modificar: `src/Api/Data/Seed/`, `src/Api/Data/Seed/companies.csv`, `src/Api/Data/Seed/authorizers.csv`
  - Criterio de completitud: quedan cargadas las 10 empresas con su moneda, la matriz completa como versión 01 y los autorizadores y analistas de `Aprobadores.csv` y `Pagos.csv`. ISAMAD **no** se carga

- [ ] **T-12** — Autorización por rol y empresa con políticas
  - Archivos a crear/modificar: `src/Api/Authorization/Policies.cs`, `src/Api/Authorization/CompanyScopeHandler.cs`
  - Criterio de completitud: un usuario no puede leer ni operar solicitudes de una empresa que no le corresponde, verificado con prueba automatizada

- [ ] **T-13** — Endpoints de consulta de catálogos
  - Archivos a crear/modificar: `src/Api/Controllers/CompaniesController.cs`, `src/Api/Controllers/UsersController.cs`
  - Criterio de completitud: el frontend puede poblar los selectores de empresa y área

### Fase 2 — Motor de reglas y conversión de moneda

- [ ] **T-14** — Servicio de matriz vigente con versionado (RF-23, RF-24)
  - Archivos a crear/modificar: `src/Api/Services/AuthorizationMatrixService.cs`, `src/Api/Models/Authorization/`
  - Criterio de completitud: el servicio devuelve la versión de la matriz vigente a una fecha dada; una versión nueva no altera la lectura de fechas anteriores

- [ ] **T-15** — Resolución del nivel facultado por empresa y monto (RF-05)
  - Archivos a crear/modificar: `src/Api/Services/AuthorizationLevelResolver.cs`, `src/Api/Interfaces/IAuthorizationLevelResolver.cs`
  - Criterio de completitud: para cualquier combinación de empresa y monto devuelve exactamente un nivel, sin huecos ni ambigüedad en las fronteras

- [ ] **T-16** — Reglas de jerarquía, tope por nivel, auto-autorización y nivel sin titular (RF-09, RF-10, RF-26, RF-28)
  - Archivos a crear/modificar: `src/Api/Services/AuthorizationPolicyService.cs`
  - Criterio de completitud: un nivel superior puede resolver montos inferiores; uno inferior no puede exceder su tramo; nadie autoriza lo que él mismo originó; si el nivel facultado no tiene titular activo la solicitud escala y queda registrado el motivo

- [ ] **T-17** — Doble investidura CEO / Consejo (RF-25)
  - Archivos a crear/modificar: `src/Api/Services/AuthorizationPolicyService.cs`, `src/Api/DTOs/Authorization/Requests/`
  - Criterio de completitud: la misma cuenta puede resolver como CEO o como Consejo; para montos de nivel Consejo el sistema exige confirmación explícita de la investidura y la persiste

- [ ] **T-18** — Integración con fuentes públicas de tipo de cambio (RF-03, RF-04)
  - Archivos a crear/modificar: `src/Api/Services/ExchangeRateService.cs`, `src/Api/Options/ExchangeRateOptions.cs`
  - Criterio de completitud: convierte a la moneda de la empresa usando el tipo de cambio de la fecha de envío y persiste valor, fuente y fecha junto a la solicitud

- [ ] **T-19** — Respaldo manual ante indisponibilidad de la fuente (RNF-08)
  - Archivos a crear/modificar: `src/Api/Services/ExchangeRateService.cs`, `frontend/src/routes/RequestForm.tsx`
  - Criterio de completitud: si la fuente no responde, el portal informa la situación y permite capturar el tipo de cambio, registrando quién lo hizo

- [ ] **T-20** — Pruebas unitarias del motor de reglas
  - Archivos a crear/modificar: `tests/Api.Tests/AuthorizationLevelResolverTests.cs`, `tests/Api.Tests/AuthorizationPolicyServiceTests.cs`
  - Criterio de completitud: hay casos para **las dos fronteras de cada rango de las 10 empresas** —el techo de un nivel y el piso del siguiente— más los casos de Engine CX y Celta Soluciones sin Country Manager, jerarquía, auto-autorización y nivel vacío

### Fase 3 — Ciclo de vida de la solicitud

- [ ] **T-21** — Esquema de solicitudes, versiones, documentos, autorizaciones, facturas y bitácora
  - Archivos a crear/modificar: `src/Api/Models/Requests/`, `src/Api/Migrations/`
  - Criterio de completitud: las migraciones crean las tablas de la §5 y la bitácora no admite `UPDATE` ni `DELETE` desde la aplicación

- [ ] **T-22** — Captura de solicitud con adjunto de cotización en S3 (RF-01, RF-02)
  - Archivos a crear/modificar: `src/Api/Controllers/ExpenseRequestsController.cs`, `src/Api/Services/DocumentStorageService.cs`, `frontend/src/routes/RequestForm.tsx`
  - Criterio de completitud: se guarda un borrador con todos sus datos y la cotización queda en un bucket privado, accesible solo por URL firmada

- [ ] **T-23** — Envío de la solicitud: conversión, cálculo de nivel y cambio de estado (RF-06)
  - Archivos a crear/modificar: `src/Api/Services/ExpenseRequestService.cs`
  - Criterio de completitud: al enviarse quedan fijos el monto convertido, el tipo de cambio y el nivel facultado, y la solicitud aparece en la bandeja del autorizador correcto

- [ ] **T-24** — Bandeja de pendientes del autorizador
  - Archivos a crear/modificar: `frontend/src/routes/Inbox.tsx`, `src/Api/Controllers/ExpenseRequestsController.cs`
  - Criterio de completitud: cada autorizador ve exactamente las solicitudes que le corresponden por nivel y empresa, y ninguna otra

- [ ] **T-25** — Autorizar y rechazar con motivo obligatorio (RF-07, RF-08)
  - Archivos a crear/modificar: `src/Api/Controllers/AuthorizationsController.cs`, `frontend/src/routes/RequestDetail.tsx`
  - Criterio de completitud: la resolución registra usuario, nivel con el que resolvió, resultado, motivo y fecha; el rechazo sin motivo es rechazado con 400

- [ ] **T-26** — Corrección y reenvío como versión nueva (RF-17)
  - Archivos a crear/modificar: `src/Api/Services/ExpenseRequestService.cs`
  - Criterio de completitud: la versión rechazada permanece consultable con su motivo y la nueva versión vuelve a pasar por el motor de reglas desde cero

- [ ] **T-27** — Cancelación de solicitud con motivo (RF-27)
  - Archivos a crear/modificar: `src/Api/Services/ExpenseRequestService.cs`, `frontend/src/routes/RequestDetail.tsx`
  - Criterio de completitud: solicitante y autorizador pueden cancelar mientras el pago no se haya solicitado; después de ese punto la operación se rechaza

- [ ] **T-28** — Carga de factura y validación con tolerancia de ±2% (RF-13, RF-14, RF-15)
  - Archivos a crear/modificar: `src/Api/Services/InvoiceValidationService.cs`, `frontend/src/routes/InvoiceUpload.tsx`
  - Criterio de completitud: dentro del margen la solicitud avanza a *pago solicitado*; fuera del margen se rechaza la autorización, se notifica al solicitante y se indica la diferencia detectada

### Fase 4 — Notificaciones, histórico y consulta

- [ ] **T-29** — Servicio de correo sobre Google Workspace con plantillas
  - Archivos a crear/modificar: `src/Api/Services/EmailService.cs`, `src/Api/Templates/`
  - Criterio de completitud: envía correo con plantilla y registra el resultado de cada envío

- [ ] **T-30** — Disparo de las notificaciones del ciclo y manejo de fallas (RF-11, RF-12, RF-16, RNF-11)
  - Archivos a crear/modificar: `src/Api/Services/NotificationDispatcher.cs`
  - Criterio de completitud: se envían los correos de resolución, de solicitud de factura y de pago autorizado —éste último al solicitante, al analista de la empresa y a Tesorería—; un fallo de envío queda registrado y no deja la solicitud en estado intermedio

- [ ] **T-31** — Bitácora de auditoría inmutable (RF-18, RNF-03, RNF-04)
  - Archivos a crear/modificar: `src/Api/Services/AuditLogService.cs`
  - Criterio de completitud: toda acción relevante deja registro con usuario, fecha y valores; no existe camino en la aplicación para modificar o borrar un registro

- [ ] **T-32** — Emisión de los eventos para BI
  - Archivos a crear/modificar: `src/Api/Services/BiEventService.cs`
  - Criterio de completitud: se emiten los eventos de la sección 11 del PRD con los campos mínimos ahí definidos

- [ ] **T-33** — Consulta con filtros y búsqueda (RF-19)
  - Archivos a crear/modificar: `src/Api/Controllers/ExpenseRequestsController.cs`, `frontend/src/routes/Search.tsx`
  - Criterio de completitud: filtra por empresa, área, solicitante, estatus, rango de fechas y rango de montos, con paginación

- [ ] **T-34** — Detalle de la solicitud con línea de tiempo del histórico
  - Archivos a crear/modificar: `frontend/src/routes/RequestDetail.tsx`
  - Criterio de completitud: la pantalla muestra todas las versiones, autorizaciones, rechazos con motivo, documentos y el tipo de cambio aplicado

### Fase 5 — Administración, calidad y salida a producción

- [ ] **T-35** — Administración de usuarios, niveles y analistas (RF-22)
  - Archivos a crear/modificar: `frontend/src/routes/admin/Users.tsx`, `src/Api/Controllers/AdminController.cs`
  - Criterio de completitud: un administrador asigna empresa, nivel y rol de analista; el cambio queda en bitácora

- [ ] **T-36** — Edición de la matriz con versionado y bitácora (RF-23)
  - Archivos a crear/modificar: `frontend/src/routes/admin/Matrix.tsx`, `src/Api/Controllers/AdminController.cs`
  - Criterio de completitud: guardar cambios crea una versión nueva conservando la anterior con su autor y fecha; las solicitudes ya enviadas siguen resolviéndose con la versión que les tocó

- [ ] **T-37** — Usabilidad en teléfono para bandeja y autorización (RNF-06)
  - Archivos a crear/modificar: `frontend/src/routes/Inbox.tsx`, `frontend/src/routes/RequestDetail.tsx`, estilos
  - Criterio de completitud: un autorizador puede revisar, abrir la cotización y resolver desde un teléfono sin zoom horizontal

- [ ] **T-38** — Pruebas de integración del ciclo completo
  - Archivos a crear/modificar: `tests/Api.IntegrationTests/`
  - Criterio de completitud: hay una prueba que recorre captura → conversión → autorización → factura → notificación, y otra del camino de rechazo y reenvío

- [ ] **T-39** — Revisión de seguridad previa a producción
  - Archivos a crear/modificar: `infra/`, `src/Api/Program.cs`
  - Criterio de completitud: bucket S3 privado con acceso solo por URL firmada, CORS restringido, IAM de mínimo privilegio, secrets fuera del código y verificación de que ningún usuario alcanza datos de otra empresa

- [ ] **T-40** — Despliegue a producción y carga de catálogos reales
  - Archivos a crear/modificar: `infra/task-definition.json`
  - Criterio de completitud: el portal opera en producción con las 10 empresas, la matriz versión 01 y los autorizadores reales dados de alta

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `companies` | Nueva | Las 10 empresas con su moneda base y estatus |
| `authorization_matrix_versions` | Nueva | Versiones de la matriz: etiqueta, vigencia, autor y fecha |
| `authorization_levels` | Nueva | Rango por empresa y nivel dentro de una versión de la matriz: monto mínimo y máximo |
| `users` | Nueva | Identidad de Google, correo, nombre, empresa, estatus |
| `user_roles` | Nueva | Roles e investiduras del usuario: solicitante, funcional, country manager, CFO, CEO, consejo, analista, administrador |
| `company_payment_analysts` | Nueva | Analista de pagos asignado a cada empresa |
| `expense_requests` | Nueva | Solicitud con empresa, área, concepto, proveedor, monto y moneda originales, monto convertido, tipo de cambio con fuente y fecha, nivel facultado, estatus, versión y referencia a la versión anterior |
| `authorizations` | Nueva | Resolución: usuario, nivel con el que resolvió, resultado, motivo, fecha |
| `invoices` | Nueva | Factura: monto, moneda, diferencia contra lo autorizado, resultado de validación |
| `documents` | Nueva | Cotizaciones y facturas: tipo, llave de S3, quién cargó, fecha |
| `audit_log` | Nueva | Bitácora de solo inserción sobre todas las entidades |
| `bi_events` | Nueva | Eventos de la sección 11 del PRD con sus campos mínimos |
| `expense_requests` | Índice | Por empresa, estatus y fecha de envío, para la bandeja y la consulta filtrada |

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `v1/auth/google` | Intercambia el token de Google por el JWT del portal | Nuevo |
| GET | `v1/companies` | Catálogo de empresas con su moneda | Nuevo |
| POST | `v1/expense-requests` | Crea la solicitud en borrador | Nuevo |
| PUT | `v1/expense-requests/{id}` | Actualiza un borrador | Nuevo |
| POST | `v1/expense-requests/{id}/documents` | Adjunta cotización o factura | Nuevo |
| POST | `v1/expense-requests/{id}/submit` | Envía a autorización: convierte moneda y calcula el nivel | Nuevo |
| POST | `v1/expense-requests/{id}/resubmit` | Corrige y reenvía como versión nueva | Nuevo |
| POST | `v1/expense-requests/{id}/cancel` | Cancela con motivo | Nuevo |
| POST | `v1/expense-requests/{id}/invoice` | Carga la factura y dispara la validación de ±2% | Nuevo |
| GET | `v1/expense-requests` | Consulta con filtros y paginación | Nuevo |
| GET | `v1/expense-requests/{id}` | Detalle con histórico completo | Nuevo |
| GET | `v1/authorizations/inbox` | Bandeja de pendientes del autorizador | Nuevo |
| POST | `v1/authorizations/{requestId}/approve` | Autoriza, con investidura cuando aplica | Nuevo |
| POST | `v1/authorizations/{requestId}/reject` | Rechaza con motivo | Nuevo |
| GET | `v1/admin/users` · POST · PATCH | Administración de usuarios y roles | Nuevo |
| GET | `v1/admin/matrix` · POST | Consulta y publicación de versiones de la matriz | Nuevo |

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `ConnectionStrings__Default` | Cadena de conexión a PostgreSQL | Todos |
| `GoogleAuth__ClientId` | Cliente OAuth 2.0 de Google Workspace | Todos |
| `GoogleAuth__ClientSecret` | Secreto OAuth — en AWS Secrets Manager | Todos |
| `GoogleAuth__AllowedDomains` | Dominios del grupo autorizados para entrar | Todos |
| `Jwt__SigningKey` | Llave de firma del JWT del portal — en Secrets Manager | Todos |
| `Storage__BucketName` | Bucket S3 de cotizaciones y facturas | Todos |
| `ExchangeRate__BanxicoToken` | Token de la API de Banxico | Todos |
| `ExchangeRate__EcbEndpoint` | Endpoint del Banco Central Europeo para el euro | Todos |
| `Email__SenderAddress` | Cuenta desde la que se envían las notificaciones | Todos |
| `Email__Credentials` | Credenciales de envío — en Secrets Manager | Todos |
| `Notifications__TreasuryAddress` | Buzón de Tesorería que recibe el aviso de pago autorizado | Todos |
| `Invoice__TolerancePercent` | Tolerancia de validación de factura. Valor inicial: `2` | Todos |

---

## 8. Consideraciones de seguridad

- **Permisos IAM**: el rol de la tarea de ECS necesita acceso de lectura y escritura únicamente al bucket del portal, y lectura de los secretos del proyecto. Nada más — principio de mínimo privilegio de `rules/infraestructura.md`.
- **Documentos**: el bucket es privado sin excepción. Las cotizaciones y facturas se sirven por URL firmada de vigencia corta, nunca por URL pública.
- **Segmentación por empresa**: es el control de acceso más delicado del portal. Un usuario no debe alcanzar montos, proveedores ni facturas de una empresa que no le corresponde. Se implementa como política transversal (T-12) y se verifica con prueba automatizada, no por revisión manual endpoint por endpoint.
- **El permiso más sensible es editar la matriz**: quien la modifica cambia quién autoriza qué. Queda restringido al rol administrador y toda modificación deja versión anterior, autor y fecha en bitácora.
- **Datos sensibles**: el portal concentra información financiera de todo el grupo con acceso desde internet. Nunca registrar en logs montos ligados a personas identificables, tokens ni credenciales.
- **Secrets**: ninguno en el código. Variables de entorno en local, AWS Secrets Manager en QA y producción.

---

## 9. Consideraciones de infraestructura

- **Servicios nuevos**: dos servicios de ECS + Fargate (API y frontend), una instancia RDS PostgreSQL, un bucket S3, un ALB y un registro en Route 53. Todo en la consola AWS de Engine transversal, por tratarse de un sistema que sirve a las 10 empresas del grupo.
- **Dimensionamiento**: el volumen esperado es de ~100 solicitudes al mes. Es un sistema de bajísimo tráfico, así que corresponde arrancar con la configuración más pequeña de Fargate y la instancia RDS más chica disponible. Sobredimensionar aquí es gasto puro.
- **Costos**: AWS no corta servicios al alcanzar un límite. Configurar alarma de facturación para este proyecto desde el primer despliegue, antes de que existan datos reales.
- **Ciclo de vida en S3**: definirlo alineado a la política de retención una vez que Finanzas confirme el plazo de conservación de facturas (pregunta abierta del PRD).

---

## 10. Criterios de aceptación

- [ ] Un colaborador del grupo entra al portal con su cuenta de Google sin que nadie lo dé de alta
- [ ] Una solicitud en moneda distinta a la de la empresa se convierte al tipo de cambio de la fecha de envío, y ese tipo de cambio queda visible en el detalle
- [ ] Para las 10 empresas, el nivel facultado calculado coincide con la matriz en ambas fronteras de cada rango
- [ ] Un usuario no puede autorizar su propia solicitud ni un monto por encima de su nivel
- [ ] Si el nivel facultado no tiene titular activo, la solicitud escala al siguiente nivel y queda registrado el motivo
- [ ] Héctor Izquierdo puede resolver como CEO y como Consejo desde la misma cuenta, y el histórico distingue con cuál autorizó
- [ ] Una factura con diferencia mayor al 2% respecto de lo autorizado es rechazada y el solicitante recibe el aviso con la diferencia
- [ ] Al validarse la factura, llega correo al solicitante, al analista de la empresa y a Tesorería
- [ ] Una solicitud rechazada puede corregirse y reenviarse, y la versión rechazada sigue consultable con su motivo
- [ ] Ninguna autorización, rechazo o documento puede editarse ni borrarse desde la aplicación
- [ ] Un usuario de una empresa no alcanza datos de otra empresa, verificado con prueba automatizada
- [ ] Un autorizador puede resolver desde su teléfono

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Fronteras de la matriz mal implementadas | Media | **Alto** | Es el defecto más caro posible: aprobaría gastos en el nivel equivocado sin que nadie lo note. T-20 exige casos de prueba en ambas fronteras de cada rango de las 10 empresas |
| Fuente de tipo de cambio gratuita, sin SLA | Alta | Medio | T-19 implementa captura manual con registro; el sistema nunca queda bloqueado por una API caída |
| Fuente indefinida para peso colombiano y chileno | Alta | Medio | Pregunta abierta del PRD. Resolver antes de la Fase 2; si no hay fuente oficial gratuita, esas conversiones arrancan con captura manual |
| Cuota de envío de Google Workspace | Baja | Medio | ~500 correos al mes está muy por debajo del límite, pero conviene medirlo desde el inicio para no descubrirlo en producción |
| Autorizadores con buzón compartido | Media | **Alto** | Ilse García y Brian figuran con `administracion@` y `contabilidad@`. Sin cuenta nominal, su autorización no es atribuible a una persona y se rompe el propósito del histórico. Bloqueante para producción, no para desarrollo |
| Consola AWS destino sin definir | Media | Medio | La consola de Engine transversal aparece como "por definir" en `rules/infraestructura.md`. Confirmarlo antes de T-06 |
| Cambio de la política de autorización a media construcción | Baja | Alto | El versionado de la matriz (T-14, T-36) absorbe el cambio sin tocar código ni alterar autorizaciones ya emitidas |

---

## 12. Notas para el programador

**Decisiones técnicas tomadas al generar este plan**, todas revisables:

1. **El motor de reglas se aísla sin dependencias de infraestructura.** Es lo que permite probar exhaustivamente las fronteras de la matriz sin base de datos. Si se acopla al acceso a datos, esas pruebas se vuelven caras y en la práctica se dejan de escribir — y ahí es exactamente donde vive el riesgo del sistema.

2. **La matriz vive en base de datos, versionada, no en código.** El PRD lo exige (RF-23) y además evita un despliegue cada vez que Finanzas ajuste un rango.

3. **El frontend se despliega como contenedor en ECS, no como estático en S3.** Es discutible: siendo una SPA compilada, S3 + CloudFront sería más barato y sencillo. Lo dejé en ECS para mantener un solo mecanismo de despliegue para ambos componentes. **Si prefieres S3, cámbialo** — no afecta ninguna otra decisión del plan.

4. **La tolerancia del ±2% es configurable** (`Invoice__TolerancePercent`), no una constante. El PRD la fija en 2%, pero es el tipo de número que cambia sin que cambie el sistema.

**Puntos a validar antes de ejecutar:**

- El nombre del repositorio y la organización de GitHub donde vivirá.
- La consola AWS destino y quién crea los recursos iniciales.
- Si Finanzas puede entregar las cuentas nominales de Ilse García y Brian antes de la Fase 5, o si el arranque en producción se hace con un subconjunto de empresas.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Andamiaje e infraestructura** | Repositorio y ramas, solución .NET, SPA React, PostgreSQL, Docker, despliegue base en ECS | T-01 a T-06 | 6 – 9 días | `84` |
| **Fase 1 — Identidad, catálogos y modelo (P1)** | SSO con Google, alta automática, esquema de catálogos, carga inicial, autorización por rol y empresa | T-07 a T-13 | 8 – 11 días | `85` |
| **Fase 2 — Motor de reglas y moneda (P1)** | Matriz versionada, resolución de nivel, jerarquía y excepciones, doble investidura, tipo de cambio con respaldo manual, pruebas del motor | T-14 a T-20 | 9 – 12 días | `86` |
| **Fase 3 — Ciclo de la solicitud (P1)** | Esquema de solicitudes, captura con documentos en S3, envío, bandeja, autorización y rechazo, reenvío, cancelación, factura con ±2% | T-21 a T-28 | 12 – 16 días | `87` |
| **Fase 4 — Notificaciones, histórico y consulta (P1)** | Correo, disparo de notificaciones, bitácora inmutable, eventos BI, consulta con filtros, detalle con línea de tiempo | T-29 a T-34 | 9 – 12 días | `88` |
| **Fase 5 — Administración, calidad y producción** | Pantallas de administración, edición de la matriz, usabilidad móvil, pruebas de integración, revisión de seguridad, despliegue | T-35 a T-40 | 7 – 10 días | `89` |
| **Total proyecto (MVP completo)** | | 40 tareas | **~51 – 70 días hábiles** (≈ 10 a 14 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-13 | ~14 – 20 días hábiles (≈ 3 a 4 semanas) | — |

> **Notas sobre la tabla:**
> - El PRD no define prioridades P1/P2/P3 internas: **todo este plan es la Fase 1 (MVP) del PRD**, y las Fases 2 y 3 del PRD quedan fuera de este alcance. Las marcas (P1) señalan las fases sin las cuales el portal no cumple su propósito; la Fase 0 es habilitadora y la Fase 5 es de cierre.
> - La fila "Solo P1" refleja el andamiaje más la identidad y los catálogos: el mínimo que produce algo desplegado y verificable, útil como primer punto de revisión con el patrocinador. No es un producto entregable por sí solo.
> - El rango 51–70 sale de la suma de las fases, no de un número global. La Fase 3 es la más ancha porque concentra la mayor cantidad de estados y pantallas.

> **Riesgo de deadline:** el PRD **no tiene fecha objetivo comprometida**, así que no hay riesgo de incumplimiento contractual. El riesgo real es de recurso: el responsable propuesto tiene el plan **PJ4668 en curso** (30 días hábiles desde el 4 de agosto, con cierre estimado el 14 de septiembre). Arrancar de inmediato significa trabajar los dos proyectos en paralelo, y entonces ninguna de las dos fechas se sostiene. Recomendación: **arrancar la Fase 0 de inmediato** —es andamiaje, tolera bien la fragmentación y no requiere concentración continua— y programar la Fase 2 en adelante después del 15 de septiembre, cuando PJ4668 libere. Un segundo desarrollador en las Fases 3 y 4 comprimiría el calendario aproximadamente un 30%, dado que ambas admiten trabajo paralelo entre backend y frontend.

---

*Generado por Claude Code — Engine CX*
*Modelo: claude-opus-5 — esfuerzo: alto*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
