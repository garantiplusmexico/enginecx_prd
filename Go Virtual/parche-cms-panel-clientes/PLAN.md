# Plan de Desarrollo — Parche CMS: Panel de Clientes (Go Virtual)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Go Virtual/parche-cms-panel-clientes/PRD.md` (v0.1) |
| Repositorio | `Sitios-Web-Go-Virtual/govirtual-api` |
| Rama base | `main` |
| Rama | `feature/parche-cms-panel-clientes-roles-y-ambito` |
| Tipo | Feature |
| Responsable | Javier Antonio Oropeza Camacho |
| Folio PRD | *(pendiente de asignar — ver §12)* |
| Fecha de generación | 2026-08-20 |
| Estado | Borrador |
| ID plan (BD) | *(lo escribe el flujo al registrar el plan)* |

> ⚠️ No existe rama `develop` en este repositorio (solo `main` y `stage`). El plan se generó desde `main`.
> Se recomienda crear `develop` antes de continuar con el flujo estándar de Engine.

---

## 1. Resumen técnico

Se interviene la API existente `govirtual-api` (NestJS 11 + MongoDB/Mongoose + Redis + BullMQ) para introducir multi-tenencia por ámbito y extender el modelo de contenido a tres niveles.

El trabajo se agrupa en cinco fases. La Fase 0 cierra riesgos de autorización que hoy son inocuos porque todas las cuentas son internas, pero que se vuelven explotables al abrir el panel a terceros. La Fase 1 construye la pieza central: un catálogo de permisos granular, un nivel de ámbito en el rol y una **capa de resolución de ámbito reutilizable** que las fases posteriores heredan sin trabajo adicional. Las fases 2 y 3 extienden y crean módulos de contenido sobre esa capa. La Fase 4 integra el acceso autenticado a Duda.

**Stack:** se mantiene NestJS + MongoDB. Por tratarse de una feature sobre un sistema en producción, aplica la regla de `rules/stack.md` de respetar el stack existente; los defaults de Engine (.NET Core 8, PostgreSQL) no se aplican aquí. Ver §12.

**Arquitectura:** no cambia. Se conserva el patrón de dos procesos (`AppModule` para la API, `WorkerModule` para los consumidores BullMQ) y la paridad Grid ↔ Brick. La capa de ámbito se implementa como módulo global inyectable, no como middleware, para que cada servicio decida dónde aplicar el filtro.

---

## 2. Prerequisitos

- [x] `CLAUDE.md` presente en el repositorio (generado durante este flujo)
- [ ] PRD validado por el responsable
- [ ] Folio `PJ####` asignado
- [ ] Acceso al repositorio `Sitios-Web-Go-Virtual/govirtual-api` confirmado
- [ ] Listado de formularios de Go Virtual recibido (bloquea T-26, no bloquea fases previas)
- [ ] Sesión de definición de lead driver y pop-ups agendada (bloquea T-27 y T-28)
- [ ] Credenciales de la Partner API de Duda con permisos de SSO disponibles (bloquea Fase 4)
- [ ] Ventana operativa acordada con Go Virtual para reconfigurar External Collections (bloquea T-24)

---

## 3. Arquitectura del cambio

La pieza nueva es un **módulo global de ámbito** que traduce la identidad del solicitante en un conjunto de identificadores consultables, y que los servicios aplican a sus filtros de Mongo.

```
Request → SessionGuard → PermissionsGuard → Controller → Service
                                                  ↓          ↓
                                            ScopeService → { level, dealerIds[], groupIds[], brandIds[] }
                                                             ↓
                                                    filtro Mongo + sufijo de cache key
```

Reglas de diseño:

- **El ámbito se deriva del token, nunca de parámetros de consulta.** Un `dealerId` que llegue por query string se ignora o se valida contra el ámbito, jamás lo amplía.
- **Fail-safe:** si `ScopeService` no resuelve ámbito para una cuenta de cliente, devuelve un filtro que no coincide con nada. La ausencia de ámbito nunca produce una consulta sin filtro.
- **La cache key incorpora el ámbito.** Sin esto, dos clientes distintos comparten entrada en Redis.
- **Resolución recursiva de grupos** vía `$graphLookup` sobre `groups.parentGroupId`, sin materializar rutas, para no migrar datos existentes.
- El modelo de tres niveles de contenido (marca / grupo / dealer) es **ortogonal** al ámbito del usuario: el ámbito dice qué puede tocar la cuenta; el nivel dice de quién es el elemento.

---

## 4. Tareas de desarrollo

### Fase 0 — Cierre de riesgos (P0)

- [ ] **T-01** — Corregir el virtual `group` de `UserSchema`
  - Archivos: `src/modules/users/schemas/user.schema.ts`
  - Criterio: el virtual resuelve por `groupId`; un usuario con grupo asignado lo devuelve poblado en `GET /users/:id`

- [ ] **T-02** — Invertir el default del `PermissionsGuard` a denegar
  - Archivos: `src/global/guards/permissions.guard.ts`, `src/global/decorators/permissions.decorator.ts`
  - Criterio: una ruta autenticada sin declaración de permisos responde 403; la exposición interna requiere un decorador explícito

- [ ] **T-03** — Inventariar y decorar las rutas que queden sin permiso tras T-02
  - Archivos: `src/modules/grid/sites/grid.sites.controller.ts`, `src/modules/grid/templates/grid.templates.controller.ts`, barrido del resto de `src/modules/**/*.controller.ts`
  - Criterio: tabla de rutas con su permiso asignado; ninguna ruta autenticada sin declaración; la API arranca y la suite pasa

- [ ] **T-04** — Bloquear escalada de privilegios en alta y edición de usuarios
  - Archivos: `src/modules/users/dto/create-user.dto.ts`, `src/modules/users/dto/update-user.dto.ts`, `src/modules/users/users.service.ts`
  - Criterio: no se puede asignar un rol de jerarquía superior a la del solicitante; `isStaff` no es modificable por `PATCH`; pruebas unitarias de los tres casos de rechazo

### Fase 1 — Roles y ámbito (P1)

- [ ] **T-05** — Rediseñar el catálogo de permisos
  - Archivos: `src/global/enums/permissions.enum.ts`
  - Criterio: catálogo granular por módulo conforme al Anexo A del PRD, con lectura y escritura separadas donde el anexo lo exige

- [ ] **T-06** — Semántica alternativa en el guard (`@RequireAnyPermission`)
  - Archivos: `src/global/decorators/permissions.decorator.ts`, `src/global/guards/permissions.guard.ts`
  - Criterio: un endpoint compartido es accesible por una cuenta de Go Virtual y por una de cliente sin necesidad de otorgar permisos de Go Virtual al cliente

- [ ] **T-07** — Re-decorar los controladores con el nuevo catálogo
  - Archivos: todos los `src/modules/**/*.controller.ts`
  - Criterio: la matriz del Anexo A queda implementada; prueba por módulo que verifica el permiso exigido

- [ ] **T-08** — Añadir `scopeLevel` al rol
  - Archivos: `src/modules/roles/schemas/role.schema.ts`, `src/modules/roles/dto/create-role.dto.ts`, `src/modules/roles/dto/update-role.dto.ts`, `src/modules/roles/roles.service.ts`
  - Criterio: `GET /roles` expone `scopeLevel` (`gv` | `group` | `dealer`); el front puede decidir qué referencia pedir en el alta

- [ ] **T-09** — Seed idempotente de roles
  - Archivos: `src/global/seeds/roles.seed.ts` (nuevo), registro del comando en `package.json`
  - Criterio: ejecutar el seed dos veces deja los mismos roles; crea Editor Dealer, Admin Dealer, Editor Grupo, Admin Grupo y los roles de Go Virtual con su jerarquía

- [ ] **T-10** — Emitir el ámbito completo en el token
  - Archivos: `src/modules/auth/auth.service.ts`, `src/global/types/iRequest.ts`, `src/global/utils/token.ts`
  - Criterio: el access token incluye `groupId` y `scopeLevel` además de `dealerId`; el refresh reconstruye el mismo payload

- [ ] **T-11** — Servicio de resolución de ámbito
  - Archivos: `src/global/scope/scope.service.ts`, `src/global/scope/scope.module.ts`, `src/global/scope/types/index.ts` (nuevos)
  - Criterio: dado un usuario devuelve `{ level, dealerIds[], groupIds[], brandIds[] }`; resuelve subgrupos con `$graphLookup`; una cuenta de cliente sin ámbito devuelve conjuntos vacíos; pruebas unitarias con jerarquía de tres niveles

- [ ] **T-12** — Aplicar el filtro de ámbito en los servicios compartidos
  - Archivos: `src/modules/dealers/dealers.service.ts`, `src/modules/groups/groups.service.ts`, `src/modules/audit-logs/audit-logs.service.ts`, y sus controladores
  - Criterio: los listados y el detalle por id quedan restringidos al ámbito; un id fuera de ámbito responde 404, no 403, para no filtrar existencia

- [ ] **T-13** — Segmentar las claves de caché por ámbito
  - Archivos: servicios con `CACHE_MANAGER` de los módulos alcanzados por T-12 y por la Fase 2
  - Criterio: dos cuentas de ámbito distinto no comparten entrada en Redis para la misma ruta y parámetros

- [ ] **T-14** — Validar ámbito único y coherencia rol↔ámbito
  - Archivos: `src/modules/users/dto/create-user.dto.ts`, `src/modules/users/dto/find-user.dto.ts`, `src/modules/users/users.service.ts`
  - Criterio: 400 si una cuenta no-staff llega sin ámbito o con ambos; 400 si el `scopeLevel` del rol no corresponde con la referencia enviada; `GET /users` acepta filtro por `groupId`

- [ ] **T-15** — Restringir alta de grupos y dealers a Go Virtual
  - Archivos: `src/modules/dealers/dealers.controller.ts`, `src/modules/groups/groups.controller.ts`
  - Criterio: una cuenta de cliente recibe 403 en `POST`, `PATCH` y `DELETE`; conserva el `GET` filtrado por su ámbito

- [ ] **T-16** — Incorporar el ámbito a la bitácora
  - Archivos: `src/modules/audit-logs/schemas/audit-log.schema.ts`, `src/modules/audit-logs/audit-logs.service.ts`, dto de consulta
  - Criterio: cada registro persiste el dealer o grupo del autor; un cliente consulta únicamente los movimientos de su ámbito

- [ ] **T-17** — Suite de pruebas de autorización negativa
  - Archivos: `test/authorization.e2e-spec.ts` (nuevo)
  - Criterio: matriz de casos cruzados (dealer A contra dealer B, grupo contra dealer ajeno, cliente contra módulos de Go Virtual) que falla si algún ámbito accede a información de otro

### Fase 2 — Banners y promociones en tres niveles (P2)

- [ ] **T-18** — Modelo de niveles y destinos en banners
  - Archivos: `src/modules/banners/schemas/banner.schema.ts`, dto de create/update/find, `src/modules/banners/banners.service.ts`
  - Criterio: cada banner declara nivel (`brand` | `group` | `dealer`), propietario, destinos y orden dentro de su nivel

- [ ] **T-19** — Modelo de niveles y destinos en promociones
  - Archivos: `src/modules/promotions/schemas/promotion.schema.ts`, dto de create/update/find, `src/modules/promotions/promotions.service.ts`
  - Criterio: paridad funcional con T-18

- [ ] **T-20** — Migración del contenido existente a nivel marca
  - Archivos: `src/global/migrations/banners-promotions-level.migration.ts` (nuevo)
  - Criterio: los banners y promociones actuales quedan como nivel marca, con orden asignado y sin interrupción del feed; la migración es idempotente y reversible

- [ ] **T-21** — Resolución de herencia y orden
  - Archivos: `src/modules/banners/banners.service.ts`, `src/modules/promotions/promotions.service.ts`, `src/global/scope/scope.service.ts`
  - Criterio: dado un dealer devuelve marca + grupo + propios en el orden marca → grupo → dealer; un dealer no puede ocultar, eliminar ni reordenar lo heredado; un grupo tampoco sobre lo de marca

- [ ] **T-22** — Endpoints de administración por nivel
  - Archivos: `src/modules/banners/banners.controller.ts`, `src/modules/promotions/promotions.controller.ts`
  - Criterio: el panel distingue elementos propios de heredados; Go Virtual administra los tres niveles; cada cliente solo el suyo

- [ ] **T-23** — Cambio de contrato del feed y espejo en Brick
  - Archivos: `src/modules/grid/banners/**`, `src/modules/grid/promotions/**`, `src/modules/brick/**` equivalentes, `src/modules/grid/types/index.ts`
  - Criterio: el feed resuelve por sitio o dealer combinando los tres niveles; la paridad Grid ↔ Brick se mantiene; el contrato anterior sigue respondiendo durante la transición

- [ ] **T-24** — Corte y reconfiguración de External Collections
  - Archivos: documento de corte en `enginecx_prd/Go Virtual/parche-cms-panel-clientes/`
  - Criterio: procedimiento por sitio validado en un sitio piloto antes del despliegue masivo; plan de reversa documentado

### Fase 3 — Módulos nuevos (P3)

- [ ] **T-25** — Módulo TYP
  - Archivos: `src/modules/thank-you-pages/**` (nuevo)
  - Criterio: CRUD con título, subtítulo, slug y hasta tres CTAs; nivel grupo y dealer con la herencia de la Fase 2

- [ ] **T-26** — Precarga de TYP por formulario
  - Archivos: `src/modules/thank-you-pages/thank-you-pages.seed.ts` (nuevo)
  - Criterio: las páginas de los formularios que provee Go Virtual quedan dadas de alta con información base y son modificables; la precarga es idempotente

- [ ] **T-27** — Módulo pop-ups
  - Archivos: `src/modules/popups/**` (nuevo)
  - Criterio: título, imagen mobile y desktop, enlace, vigencia opcional y página destino; soporta al menos diez por ámbito

- [ ] **T-28** — Módulo lead driver
  - Archivos: `src/modules/lead-drivers/**` (nuevo)
  - Criterio: imágenes mobile y desktop, selector de modalidad enlace o formulario con sus campos condicionales, y control de activo/inactivo

- [ ] **T-29** — Exposición de los tres módulos en Grid y Brick
  - Archivos: `src/modules/grid/**`, `src/modules/brick/**`, `src/modules/grid/types/index.ts`
  - Criterio: los sitios consumen TYP, pop-ups y lead driver resueltos por nivel; el lead driver activo aparece en la página de inventario; paridad mantenida

### Fase 4 — Acceso a Duda

- [ ] **T-30** — Spike de la Partner API de Duda para acceso autenticado
  - Archivos: nota técnica en la carpeta del PRD
  - Criterio: se confirma el mecanismo disponible, el modelo de licenciamiento por usuario y el impacto en costo; decisión documentada de continuar o replantear

- [ ] **T-31** — Implementación del acceso autenticado
  - Archivos: `src/modules/duda-access/**` (nuevo), `src/global/config/environments.config.ts`
  - Criterio: desde el panel, una cuenta de cliente llega a blog, landings y auditoría de SEO de su sitio sin volver a iniciar sesión

---

## 5. Cambios en base de datos

MongoDB. No hay migraciones de esquema en el sentido relacional; los cambios son de forma de documento más scripts de respaldo.

| Colección | Tipo de cambio | Descripción |
|---|---|---|
| `users` | Modificación | Corrección del virtual `group`; validación de ámbito único. Sin cambio de forma |
| `roles` | Modificación | Nuevo campo `scopeLevel`; alta de los cuatro roles de cliente vía seed |
| `banners` | Modificación | Nuevos campos de nivel, propietario, destinos y orden. Requiere migración de datos (T-20) |
| `promotions` | Modificación | Igual que `banners` |
| `audit_logs` | Modificación | Nuevos campos de ámbito. Los registros previos quedan sin ámbito y se excluyen de las consultas de cliente |
| `thank_you_pages` | Nueva | Módulo TYP |
| `popups` | Nueva | Módulo pop-ups |
| `lead_drivers` | Nueva | Módulo lead driver |
| Índices | Nuevos | `banners` y `promotions` por nivel y propietario; `audit_logs` por ámbito y fecha; `groups.parentGroupId` para el `$graphLookup` |

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `auth` | Payload del token con `groupId` y `scopeLevel` | Modificado |
| GET | `roles` | Expone `scopeLevel` | Modificado |
| POST / PATCH | `users` | Validación de ámbito y de jerarquía de rol | Modificado |
| GET | `users` | Nuevo filtro por `groupId` | Modificado |
| GET | `dealers`, `dealers/:id` | Filtrado por ámbito | Modificado |
| POST / PATCH / DELETE | `dealers` | Restringido a Go Virtual | Modificado |
| GET | `groups`, `groups/:id` | Filtrado por ámbito | Modificado |
| POST / PATCH / DELETE | `groups` | Restringido a Go Virtual | Modificado |
| GET | `audit-logs` | Filtrado por ámbito | Modificado |
| GET / POST / PATCH / DELETE | `banners`, `promotions` | Nivel, destinos y orden | Modificado |
| GET | `grid/banners/...`, `grid/promotions/...` | Resolución por sitio o dealer con los tres niveles | Modificado |
| GET | `brick/banners/...`, `brick/promotions/...` | Espejo de lo anterior | Modificado |
| GET / POST / PATCH / DELETE | `thank-you-pages` | Módulo TYP | Nuevo |
| GET / POST / PATCH / DELETE | `popups` | Módulo pop-ups | Nuevo |
| GET / POST / PATCH / DELETE | `lead-drivers` | Módulo lead driver | Nuevo |
| GET | `grid/thank-you-pages/...`, `grid/popups/...`, `grid/lead-drivers/...` | Feeds de los módulos nuevos, con espejo en Brick | Nuevo |
| POST | `duda-access/session` | Acceso autenticado a Duda | Nuevo |

Se mantiene el prefijo global `/api` y la convención de rutas entity-scoped documentada en `CLAUDE.md`.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `DUDA_SSO_*` | Credenciales del mecanismo de acceso autenticado de Duda. Nombre exacto pendiente del spike T-30 | Desarrollo / QA / Producción |

El resto de las fases no introduce variables nuevas. Los secretos existentes (`JWT_SECRET`, `PASSWORD_SALT`, credenciales de Duda y AWS) permanecen sin cambio y fuera del código.

---

## 8. Consideraciones de seguridad

- **Este plan es, en su mayor parte, trabajo de seguridad.** El criterio rector es que el ámbito se derive del token y nunca de la entrada del cliente.
- Fail-safe obligatorio: la ausencia de ámbito produce un filtro que no coincide con nada, jamás una consulta sin filtro.
- Un identificador fuera de ámbito responde 404 y no 403, para no revelar la existencia de recursos de otros clientes.
- Segmentación de caché por ámbito: una clave mal construida es una fuga de datos entre clientes que ninguna prueba de permisos detecta.
- El alta y la edición de usuarios no deben permitir elevar el propio nivel ni cambiar `isStaff`.
- Se mantiene la política de rate limiting existente; conviene endurecerla en autenticación antes de exponer el login a terceros.
- Sin cambios en IAM ni en permisos de AWS.

---

## 9. Consideraciones de infraestructura

No se requieren servicios AWS nuevos. El despliegue sigue el pipeline actual (`.github/workflows/aws-stage.yml` y `aws-production.yml`).

El punto de atención no es de infraestructura sino **operativo**: la reconfiguración de las External Collections de Duda (T-24) se ejecuta sitio por sitio y la realiza el equipo de Go Virtual. Con el volumen de sitios en producción, es el candidato más probable a marcar el ritmo de la Fase 2 y debe dimensionarse con Sharon Mendoza antes de iniciarla.

---

## 10. Criterios de aceptación

- [ ] Ninguna ruta autenticada queda accesible sin declaración explícita de permisos
- [ ] Una cuenta de dealer no obtiene información de otro dealer por ningún endpoint, ni en listado, ni por identificador, ni por caché
- [ ] Una cuenta de grupo ve sus dealers y los de sus subgrupos, y ninguno más
- [ ] Una cuenta de cliente sin ámbito resuelto no obtiene información
- [ ] Los roles Editor y Admin operan igual a nivel grupo y a nivel dealer, cambiando solo el conjunto de datos
- [ ] El alta de cuentas, grupos y dealers solo es posible desde Go Virtual
- [ ] Un dealer no puede ocultar, eliminar ni reordenar contenido de grupo o de marca; un grupo tampoco sobre el de marca
- [ ] El orden de despliegue respeta la prioridad marca → grupo → dealer
- [ ] Los sitios en producción siguen recibiendo su contenido durante y después del cambio de contrato del feed
- [ ] La paridad Grid ↔ Brick se mantiene en todo endpoint tocado o creado
- [ ] La suite de autorización negativa pasa y falla ante una regresión de ámbito

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Fuga entre clientes por cache key sin ámbito | Alta | Alto | T-13 explícita; revisión de las claves de todos los servicios tocados; caso de prueba dedicado en T-17 |
| Filtro de ámbito omitido en algún servicio | Alta | Alto | Capa reutilizable en lugar de filtros ad hoc; matriz de cobertura en T-17; inventario de rutas de T-03 como lista de control |
| Interrupción de sitios en producción al cambiar el contrato del feed | Media | Alto | T-23 conserva el contrato anterior durante la transición; T-24 valida en un sitio piloto antes del despliegue masivo |
| La reconfiguración de External Collections excede la ventana operativa | Media | Medio | Dimensionar con Go Virtual antes de iniciar la Fase 2; el contrato dual permite desacoplar el despliegue de código de la reconfiguración |
| Re-decorar 30 controladores introduce regresiones de acceso | Media | Medio | T-07 acompañada de prueba por módulo; ejecución después de T-02 para que cualquier omisión falle cerrada y no abierta |
| Definición insuficiente de lead driver y pop-ups | Media | Medio | Sesión pendiente como prerequisito de T-27 y T-28; la Fase 3 no bloquea a las anteriores |
| Duda no ofrece el mecanismo de acceso esperado o cobra por usuario | Media | Medio | T-30 es un spike previo con decisión documentada; la Fase 4 es independiente del resto |
| Ausencia de `develop` desalinea el flujo de ramas de Engine | Alta | Bajo | Crear `develop` antes de arrancar; hoy solo existen `main` y `stage` |
| El `$graphLookup` de grupos degrada con jerarquías profundas | Baja | Bajo | Índice sobre `parentGroupId`; cachear el resultado por usuario; si degrada, materializar la ruta |

---

## 12. Notas para el programador

**Desviación de stack, justificada.** `rules/stack.md` fija .NET Core 8 y PostgreSQL como defaults, pero la misma regla indica respetar el stack existente en features sobre proyectos en producción. Este plan se ejecuta en NestJS + MongoDB. No se propone refactor.

**Dos cambios respecto al documento que Go Virtual validó el 2026-08-19.** Ambos vienen del documento de respuestas del 2026-08-20 y conviene tenerlos presentes porque **simplifican** el alcance:

1. En la versión original, un dealer podía ocultar y reordenar el contenido OEM. Eso obligaba a una colección de sobreescrituras por dealer, porque un banner de marca lo comparten todas las agencias. La regla nueva lo prohíbe explícitamente: **esa complejidad desaparece** y el orden pasa a ser determinista por nivel.
2. El alta de dealers por parte del admin de grupo quedaba confirmada y ahora se revierte a exclusiva de Go Virtual. Eso elimina la necesidad de forzar el grupo desde el token al crear dealers y cierra la vía por la que un cliente podía ampliar su propio ámbito.

**Sobre "lead destinations" como referencia del módulo TYP.** No existe un módulo con ese nombre en la API. Sí existe el concepto: `DealerLeadDestinations` se construye en los servicios `*-info` de Grid y Brick a partir de `LeadConfig`, y hay una `DUDA_LEAD_DESTINATION_URL` en configuración. Antes de T-25 conviene confirmar con Sharon si se refiere a ese patrón de derivación automática por dealer o al catálogo precargado de `lead_integration_types`. La diferencia cambia el diseño de la precarga de T-26.

**El destino de asignación está sin cerrar.** Las reglas dicen que el nivel marca asigna a *sitios* y el nivel grupo asigna a *dealers*. Un grupo puede tener sitios de agencia y además un sitio de grupo, así que no son equivalentes. Es pregunta abierta del PRD y debe resolverse antes de T-18, no durante.

**Orden de ejecución dentro de la Fase 0.** T-02 antes que T-03: al invertir el default primero, cualquier ruta que se haya pasado por alto falla cerrada y aparece en pruebas, en lugar de quedar silenciosamente abierta.

**Ramas.** Esta rama cubre Fase 0 y Fase 1. Las fases 2, 3 y 4 deberían tomar su propia rama funcional desde `develop` una vez que exista, para no arrastrar una rama de larga vida.

**Folio.** Falta asignar el `PJ####` antes de registrar el plan en la base de datos.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Cierre de riesgos (P0)** | Virtual de grupo, denegación por defecto, inventario y decoración de rutas, bloqueo de escalada | T-01 a T-04 | 3 – 5 días | |
| **Fase 1 — Roles y ámbito (P1)** | Catálogo de permisos, `scopeLevel`, seed de roles, token con ámbito, `ScopeService`, filtrado y caché, validaciones de alta, bitácora con ámbito, suite de autorización | T-05 a T-17 | 20 – 28 días | |
| **Fase 2 — Banners y promociones (P2)** | Modelo de tres niveles, migración, herencia y orden, endpoints, cambio de contrato del feed, corte de External Collections | T-18 a T-24 | 10 – 15 días | |
| **Fase 3 — Módulos nuevos (P3)** | TYP con precarga, pop-ups, lead driver y sus feeds en Grid y Brick | T-25 a T-29 | 12 – 18 días | |
| **Fase 4 — Acceso a Duda** | Spike de la Partner API e implementación del acceso autenticado | T-30 a T-31 | 4 – 8 días | |
| **Total proyecto (P0+P1+P2+P3+F4)** | | 31 tareas | ~49 – 74 días hábiles (≈ 10 – 15 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-17 | ~23 – 33 días hábiles (≈ 5 – 7 semanas) | — |

> **Notas sobre la tabla:**
> - Los rangos salen de la complejidad de las tareas y asumen **un desarrollador de tiempo completo**.
> - La Fase 1 concentra alrededor del 45% del esfuerzo total y no produce cambios visibles en el panel. Conviene gestionar esa expectativa con Go Virtual desde el arranque.
> - La Fase 2 excluye el tiempo del equipo de Go Virtual para reconfigurar las External Collections (T-24), que corre en paralelo y no es esfuerzo de desarrollo.
> - Las fases 3 y 4 están estimadas sobre la definición disponible al 2026-08-20; la sesión pendiente de lead driver y pop-ups puede moverlas.

> **Riesgo de deadline:** el PRD no fija fecha límite, por lo que no hay contraste posible contra días hábiles disponibles. La recomendación es acordar una: con un solo desarrollador el alcance completo se ubica entre 10 y 15 semanas, y solo P1 entre 5 y 7. Si Go Virtual necesita el panel abierto a clientes antes de ese horizonte, la vía es comprometer P1 y diferir las fases 2 y 3, no comprimir la Fase 1 — es la que sostiene el aislamiento entre clientes. Un segundo desarrollador aportaría alrededor de un 30% de compresión sobre el total, no un 50%: las fases 0 y 1 son secuenciales por dependencia y se paralelizan mal, mientras que las fases 2, 3 y 4 sí admiten trabajo simultáneo.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
