# Plan de Desarrollo — Módulo de Usuarios (filtrado por campo + rol en listado)

> Generado por Claude Code. Este documento es el punto de partida para la ejecución.
> El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | *(sin PRD — feature solicitada directamente por el responsable; folio asignado para registro y seguimiento)* |
| Repositorio | `gp_seguros` (backend) + `frontend-omega` (frontend) |
| Rama | `feature/ModuloUsuarios` (creada en ambos repos) |
| Rama base | `develop` |
| Tipo | Feature |
| Responsable | Alexis Salvador Herrera Garcia |
| Folio PRD | `PJ3074` |
| Fecha de generación | 2026-08-28 |
| Estado | Validado |
| ID plan (BD) | `65` |

---

## 1. Resumen técnico

El listado de usuarios de Omega (`Seguridad → Usuarios`) hoy sólo permite filtrar por la columna
**Usuario** y no muestra el rol de cada usuario. Este plan habilita **filtro por cada columna del
listado** y **agrega la columna Rol**.

La decisión técnica central es **aplanar el rol en el backend mediante una proyección a DTO**, en
lugar de resolverlo en el frontend:

- El rol vive en `AspNetUserRoles` → `AspNetRoles.Name`, es decir detrás de una **colección** de
  navegación (`aspnetusers.aspnetuserroles`). Filtrar eso por OData exigiría una cláusula
  `aspnetuserroles/any(r: r/aspnetroles/Name eq '...')`, que el constructor de filtros del frontend
  (`operacion-generica.construir_filtro`) **no sabe generar** — sólo traduce puntos a `/` para
  navegar relaciones escalares.
- `TablaOmega` pinta cada celda como `item[Header.value]`, es decir espera **una propiedad plana**.
- Ordenar y contar (`/cnt`) por rol requiere igualmente un campo escalar.

Proyectando `GET /Usuarios` a un DTO plano con `rol` como `string`, los tres problemas se resuelven
de un golpe y sin tocar el gateway ni el esquema de base de datos: el filtro, el `$orderby`, el
`$skip/$top` y el conteo siguen funcionando con el mismo mecanismo OData que ya usa el resto del
sistema.

**Componentes que se modifican**

| Componente | Cambio |
|---|---|
| `gp_seguros/Services/auth` | DTO nuevo de listado + proyección en `UsuariosController.Get` y `GetCount` |
| `frontend-omega` | Columna Rol y filtros por columna en `Usuarios.vue` |
| `gp_seguros/Services/apigateway/krakend.json` | **Sin cambios** (ver §6) |
| Base de datos | **Sin cambios** (ver §5) |

**Stack:** se respeta el existente — .NET 8 / C# / EF Core + Npgsql (DB-first) en backend;
Vue 2.6 + Vuetify 2.6 en frontend; PostgreSQL en RDS; despliegue ECS + Fargate (backend) y
S3 + CloudFront (frontend). No se introduce ninguna tecnología nueva.

---

## 2. Prerequisitos

- [x] Acceso a los repositorios `gp_seguros` y `frontend-omega` confirmado
- [x] Rama `feature/ModuloUsuarios` creada desde `develop` actualizado en ambos repos
- [x] `CLAUDE.md` presente en ambos repositorios
- [ ] Node 16.15.1 disponible para el frontend (`nvm use` — el build no funciona en Node moderno)
- [ ] Acceso de lectura a la BD de QA para validar la cardinalidad usuario↔rol (T-02)
- [ ] Usuario con rol `Administrador General` en QA para probar el listado
      (los endpoints `GET /Usuarios` y `GET /Roles` están restringidos a ese rol)
- [ ] Sin variables de entorno ni secrets nuevos (ver §7)

---

## 3. Arquitectura del cambio

Aplica la arquitectura **2 — Frontend + Backend separados** de `rules/arquitectura.md`, que es la
que ya rige entre `frontend-omega` y el microservicio `auth`. No se crea ningún servicio nuevo,
por lo que no hay decisión de arquitectura que revisar.

```
frontend-omega                        KrakenD                     Services/auth
Usuarios.vue                          (sin cambios)               UsuariosController
  │                                        │                            │
  │ GET v1/usuarios?filter=…&$top=…        │  GET /usuarios?…           │
  ├───────────────────────────────────────>├───────────────────────────>│
  │                                        │                            │  repo.All<aspnetusers>()
  │                                        │                            │    .Select(→ usuario_listadoDTO)
  │                                        │                            │  [EnableQuery] aplica
  │  [{id, userName, nombre, rol, … }]     │                            │    filter/orderby/skip/top
  │<───────────────────────────────────────┤<───────────────────────────┤
  │                                        │                            │
  │ GET v1/usuarios/cnt?filter=…           │                            │  misma proyección
  ├───────────────────────────────────────>├───────────────────────────>│  ODataQueryOptions<DTO>
  │<───────────────────────────────────────┤<───────────────────────────┤
```

**Punto clave:** la proyección se aplica **antes** de que `[EnableQuery]` procese la consulta, de
modo que EF Core traduce el filtro sobre `rol` a un subquery correlacionado en SQL. El filtrado y
la paginación siguen ocurriendo en la base de datos, no en memoria.

---

## 4. Tareas de desarrollo

### Fase 0 — Contrato de API y validación de supuestos

- [ ] **T-01** — Congelar el contrato del DTO de listado (API First)

  Definir y acordar los campos y sus nombres JSON antes de escribir implementación. Contrato
  propuesto (los nombres respetan el estilo local del repo, que espeja las columnas de PostgreSQL,
  tal como indica el `CLAUDE.md` de `gp_seguros`):

  | Propiedad C# | JSON | Tipo | Origen |
  |---|---|---|---|
  | `Id` | `id` | `string` | `aspnetusers.Id` |
  | `UserName` | `userName` | `string` | `aspnetusers.UserName` |
  | `nombre` | `nombre` | `string` | `aspnetusers.nombre` |
  | `id_rol` | `id_rol` | `string` | `aspnetuserroles.RoleId` |
  | `rol` | `rol` | `string` | `aspnetroles.Name` |
  | `LastAccessDate` | `lastAccessDate` | `DateTime?` | `aspnetusers.LastAccessDate` |
  | `LockoutEnd` | `lockoutEnd` | `DateTime?` | `aspnetusers.LockoutEnd` |
  | `bloqueado` | `bloqueado` | `bool` | `LockoutEnd != null` |
  | `activo` | `activo` | `bool` | `aspnetusers.activo == 1` |

  - Criterio de completitud: contrato revisado contra las columnas que hoy consume `Usuarios.vue`
    (`id`, `userName`, `nombre`, `lastAccessDate`, `lockoutEnd`) — **ninguna desaparece**, sólo se
    agregan `rol`, `id_rol`, `bloqueado` y `activo`.

- [ ] **T-02** — Verificar en BD que la relación usuario↔rol es realmente 1:1

  El plan asume 1:1 según lo indicado por el responsable, y el código lo asume de facto
  (`Usuario.vue:326` lee `aspnetuserroles[0].roleId`; `UsuariosController.UpdateById` borra todos
  los roles y agrega uno solo). Falta confirmarlo contra los datos reales.

  ```sql
  SELECT "UserId", count(*) AS roles
  FROM "AspNetUserRoles"
  GROUP BY "UserId"
  HAVING count(*) > 1;
  ```

  - Criterio de completitud: la consulta devuelve **0 filas** en QA y en producción. Si devuelve
    filas, se documenta la regla aplicada (mostrar el primer rol) y se escala al responsable antes
    de continuar — el DTO seguiría siendo válido, pero la UI ocultaría información.

### Fase 1 — Backend (`gp_seguros/Services/auth`)

- [ ] **T-03** — Crear el DTO de listado

  - Archivos a crear: `Services/auth/Models/DTO/usuario_listadoDTO.cs`
  - Una clase pública por archivo, nombre de archivo = nombre de clase, bajo `Models/DTO/` como el
    `usuarioDTO` existente.
  - Criterio de completitud: la clase compila y expone exactamente los campos de T-01.

- [ ] **T-04** — Proyectar `UsuariosController.Get()` al DTO

  - Archivos a modificar: `Services/auth/Controllers/UsuariosController.cs`
  - Cambiar la firma a `ActionResult<IQueryable<usuario_listadoDTO>>` y sustituir
    `repo.All<aspnetusers>()` por la proyección `.Select(x => new usuario_listadoDTO { … })`,
    resolviendo el rol con
    `x.aspnetuserroles.Select(r => r.aspnetroles.Name).FirstOrDefault()`.
  - Conservar `[Authorize(Roles = "Administrador General")]`, `[EnableQuery(MaxTop = 100, PageSize = 100)]`,
    el `ActivitySource`/`activity` de OpenTelemetry y el `Name = "GetUsers"`.
  - **No** materializar con `.ToList()` — debe devolverse el `IQueryable` para que OData filtre en BD.
  - Criterio de completitud: `GET /usuarios` devuelve el rol de cada usuario y
    `GET /usuarios?filter=Contains(tolower(rol),tolower('admin'))` filtra correctamente.

- [ ] **T-05** — Alinear `GetCount` a la misma proyección

  - Archivos a modificar: `Services/auth/Controllers/UsuariosController.cs`
  - Cambiar `ODataQueryOptions<aspnetusers>` por `ODataQueryOptions<usuario_listadoDTO>` y aplicar
    las opciones sobre la **misma** proyección que T-04.
  - Motivo: si el conteo sigue tipado contra `aspnetusers`, cualquier filtro sobre `rol`,
    `bloqueado` o `activo` devuelve **400** y la paginación del listado queda rota. Ambos endpoints
    deben ver el mismo modelo.
  - Criterio de completitud: `GET /usuarios/cnt?filter=…` devuelve el mismo número de registros que
    trae el listado con ese filtro, para cada campo filtrable.

- [ ] **T-06** — Compilar y probar el microservicio `auth`

  ```bash
  cd Services/auth && dotnet restore && dotnet build
  ```

  - Probar manualmente con un JWT de `Administrador General`: `filter` sobre cada campo,
    `$orderby=rol`, `$orderby=rol desc`, `$skip/$top`, y `/cnt` con y sin filtro.
  - Criterio de completitud: `dotnet build` sin errores y las 4 formas de consulta responden 200
    con datos correctos.

### Fase 2 — Frontend (`frontend-omega`)

- [ ] **T-07** — Cargar el catálogo de roles en el listado

  - Archivos a modificar: `src/views/seguridad/usuarios/Usuarios.vue`
  - Agregar un `mounted()` que consulte `v1/roles` con
    `operacion_generica.realizar_consulta('v1/roles')` y llene las opciones del filtro de la columna
    Rol. El `mounted()` del mixin `PlantillaListado` (que hace `limpia_filtros()`) sigue
    ejecutándose — Vue encadena los hooks del mixin y del componente, el mixin primero.
  - Declarar el arreglo de opciones **desde el inicio** en `data()` para que Vue 2 lo haga reactivo;
    llenarlo después con `.splice()`/asignación al arreglo ya declarado.
  - Criterio de completitud: al abrir el menú de filtro de Rol aparece el listado de roles
    existentes en un `v-select`.

- [ ] **T-08** — Agregar la columna Rol al listado

  - Archivos a modificar: `src/views/seguridad/usuarios/Usuarios.vue`
  - Nuevo header `{ text: 'Rol', value: 'rol', tipoDato: 'string', opciones: { datos: [...], texto: 'name', valor: 'name' } }`.
  - `TablaOmega` ya soporta filtro por `v-select` cuando el header trae `opciones` — no hay que
    tocar el componente.
  - Criterio de completitud: la columna Rol se muestra poblada para todos los usuarios y el filtro
    por select devuelve sólo los usuarios de ese rol.

- [ ] **T-09** — Habilitar filtro en Nombre y Último ingreso

  - Archivos a modificar: `src/views/seguridad/usuarios/Usuarios.vue`
  - Quitar `sinFiltro: true` de los headers `nombre` y `lastAccessDate`.
  - `lastAccessDate` ya declara `tipoDato: 'date'`, así que `TablaOmega` renderiza el `v-date-picker`
    de rango y `construir_URL` genera el `ge`/`le` con offset `-06:00`. No requiere código nuevo.
  - Criterio de completitud: el filtro de texto en Nombre y el filtro de rango de fechas en Último
    ingreso devuelven resultados correctos, verificados contra el `/cnt`.

- [ ] **T-10** — Convertir Bloqueado en filtro booleano

  - Archivos a modificar: `src/views/seguridad/usuarios/Usuarios.vue`
  - Cambiar el header a `value: 'bloqueado'`, `tipoDato: 'boolean'`, con
    `opciones: [{ text: 'Si', value: true }, { text: 'No', value: false }]` y
    `transformarValor` leyendo `item.bloqueado`.
  - Motivo: hoy la columna se calcula en el cliente desde `lockoutEnd`, que es un `DateTime?`;
    filtrar "bloqueado = No" sobre una fecha no es expresable con el constructor de filtros actual.
    Con el campo `bloqueado` del DTO se resuelve como `bloqueado eq true|false`, y `construir_URL`
    ya contempla explícitamente el caso `valor === false`.
  - Criterio de completitud: filtrar Bloqueado = Sí / No devuelve los conjuntos correctos y
    complementarios.

- [ ] **T-11** — *(Opcional)* Agregar la columna Activo con filtro booleano

  - Archivos a modificar: `src/views/seguridad/usuarios/Usuarios.vue`
  - Mismo patrón que T-10 sobre el campo `activo` del DTO.
  - Se marca opcional porque no fue pedida explícitamente; el dato ya viaja en el DTO, así que el
    costo es de minutos. Decisión del responsable al validar el plan.
  - Criterio de completitud: la columna se muestra y filtra, o la tarea se descarta formalmente.

- [ ] **T-12** — Lint del frontend

  ```bash
  nvm use && npm run lint
  ```

  - Criterio de completitud: `npm run lint` sin errores nuevos. (Este repo **no tiene suite de
    tests** — no existe Jest/Vitest/Cypress ni script `test`; la verificación es lint + prueba
    manual en `npm run serve`.)

### Fase 3 — Integración y pruebas

- [ ] **T-13** — Prueba de integración manual extremo a extremo contra QA

  Matriz mínima a cubrir en `npm run serve` apuntando a QA:

  | Escenario | Verificación |
  |---|---|
  | Filtro por cada columna, uno a uno | Resultados correctos y `/cnt` consistente con el listado |
  | Dos y tres filtros combinados | El backend recibe `filter=… and … and …` y responde coherente |
  | Filtro + cambio de página | El filtro **persiste** al paginar |
  | Filtro + `$orderby` por Rol | Orden correcto, ascendente y descendente |
  | Botón "limpiar todos los filtros" | Vuelve al listado completo |
  | Navegar a otra pantalla de listado y volver | Sin arrastre de filtros (estado global de `operacion-generica`) |
  | Usuario sin rol asignado (si existe) | La celda Rol queda vacía, sin romper la fila |
  | Clic en fila → edición | Sigue navegando con el `id` correcto y `Usuario.vue` carga el rol |

  - Criterio de completitud: los 8 escenarios pasan.

- [ ] **T-14** — Verificar que el gateway no requiere cambios

  - El endpoint `GET /api/v1/usuarios` de `krakend.json` ya declara
    `"input_query_strings": [ "*" ]`, por lo que propaga cualquier `filter`/`$orderby`/`$top` nuevo
    sin tocar el archivo. Igual para `/api/v1/usuarios/cnt`.
  - Criterio de completitud: confirmado por prueba real contra QA (no sólo por lectura del JSON).
    Si por cualquier motivo hubiera que editar `krakend.json`, validar el JSON después:
    ```bash
    node -e "JSON.parse(require('fs').readFileSync('Services/apigateway/krakend.json','utf8')); console.log('JSON VALIDO')"
    ```

- [ ] **T-15** — Commits en ambos repos y entrega

  - Formato de commit (`rules/version-control.md`):
    `[modulo-usuarios] Agregar columna de rol y filtros por campo en el listado de usuarios`
  - Push de `feature/ModuloUsuarios` en `gp_seguros` y `frontend-omega`.
  - **Los Pull Requests los crea el programador, no Claude.** Ruta:
    `feature/ModuloUsuarios → pre-qa` (merge local) → PR `pre-qa → qa`.
  - Criterio de completitud: ambas ramas pusheadas y el responsable notificado.

---

## 5. Cambios en base de datos

**Ninguno.** El rol ya existe en `AspNetUserRoles` / `AspNetRoles` y el plan sólo lo lee.

`gp_seguros` trabaja **DB-first sin migraciones** (no hay carpeta `Migrations` ni `dotnet ef` en el
flujo), por lo que evitar el cambio de esquema es también evitar un paso manual en tres ambientes.

> **Nota de desempeño (no bloqueante):** el filtro por `rol` genera un subquery correlacionado
> sobre `AspNetUserRoles`. Con el volumen actual de usuarios de Omega esto es irrelevante. Si en el
> futuro el listado se degrada, la mitigación es un índice sobre `"AspNetUserRoles"("UserId")` —
> medir antes de aplicar, no anticiparse.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `v1/usuarios` | Cambia el payload: de la entidad `aspnetusers` a `usuario_listadoDTO` plano con `rol`, `id_rol`, `bloqueado` y `activo` | **Modificado** |
| GET | `v1/usuarios/cnt` | Se retipa a `ODataQueryOptions<usuario_listadoDTO>` para aceptar los mismos filtros | **Modificado** |
| GET | `v1/roles` | Se consume desde el listado para poblar el filtro de Rol | Sin cambios |
| GET | `v1/usuarios/{id}` | **No se toca** — `Usuario.vue` depende de `aspnetuserroles[0].roleId` | Sin cambios |
| GET | `v1/usuarios/users_name` | **No se toca** — lo consumen Cotizaciones, Pólizas y Pólizas Externas | Sin cambios |

**Análisis de impacto del cambio de contrato de `GET v1/usuarios`:** se verificó por búsqueda en
todo `frontend-omega` que el **único** consumidor de la colección es
`src/views/seguridad/usuarios/Usuarios.vue`. El `continuarFetch` de esa vista despacha los datos a
`listUsuarios` (módulo `localizacion` del store), pero **ninguna vista lee `state.usuarios`** — es
código muerto del que no depende nadie. El cambio no rompe ninguna otra pantalla.

**Compatibilidad de campos:** el DTO conserva `id`, `userName`, `nombre`, `lastAccessDate` y
`lockoutEnd` con el mismo nombre JSON que hoy, de modo que aunque apareciera un consumidor no
detectado, seguiría funcionando salvo por los campos de navegación (`aspnetuserroles`,
`usuarios_empresa`, `usuarios_sucursal`, `usuarios_grupo`) que hoy **de todos modos no se
serializan** en el listado, porque `Get()` no hace `Include`.

---

## 7. Variables de entorno y configuración

**Ninguna.** No se agregan variables ni secrets en ningún ambiente.

> Recordatorio de `rules/infraestructura.md` y del `CLAUDE.md` del repo: los `appsettings.json` de
> `gp_seguros` traen credenciales reales comiteadas. Es deuda existente — **no propagarla**. Este
> plan no agrega configuración a esos archivos.

---

## 8. Consideraciones de seguridad

- **Autorización sin cambios.** `GET /Usuarios` y `GET /Usuarios/cnt` conservan
  `[Authorize(Roles = "Administrador General")]`. El listado no se abre a más roles.
- **Exposición de datos personales — validar al implementar.** La entidad `aspnetusers` marca
  `Email`, `PhoneNumber`, `PasswordHash`, `SecurityStamp`, `NormalizedEmail` y otros con
  `[JsonIgnore]`. El DTO nuevo **no debe** incluir ninguno de esos campos: al proyectar a una clase
  nueva se pierde la protección del `[JsonIgnore]` de la entidad, así que la omisión tiene que ser
  deliberada. El contrato de T-01 ya la respeta — verificarlo explícitamente en la revisión de T-03.
  (`UserName` sí se expone porque coincide con el correo y **ya se muestra hoy** en la columna
  Usuario; no hay cambio de exposición.)
- **Inyección OData.** El filtro lo arma `operacion-generica` interpolando el texto que teclea el
  usuario en la cláusula. El riesgo real es acotado — `[EnableQuery]` parsea y valida la expresión
  OData contra el modelo antes de traducirla a SQL parametrizado por EF Core, así que no hay
  inyección SQL. Un valor mal formado produce **400**, no un error de datos. Es el mismo mecanismo
  que ya usan todos los listados del sistema; no se introduce riesgo nuevo.
- **Rate limiting.** `GET /Usuarios` hoy no declara política. No se agrega ninguna en este plan
  para no cambiar el comportamiento de un endpoint en uso; queda anotado como deuda si el módulo
  crece.
- **Sin cambios en IAM ni en permisos de AWS.**

---

## 9. Consideraciones de infraestructura

Ninguna. No hay servicios AWS nuevos, ni cambios en ECS, RDS, S3, Cloudflare o Route 53, ni impacto
en costos.

El despliegue usa los pipelines existentes, que se disparan **por push, no manualmente**:

| Repo | Rama | Destino |
|---|---|---|
| `gp_seguros` | `qa` | Cluster ECS `qa-apiomega` (redespliegue del servicio `auth`) |
| `frontend-omega` | `qa` | S3 `frontend-omega-dev-gpagenteseguros` + CloudFront `E1ESKK072SD1VN` |

> **Coordinación de despliegue:** backend y frontend deben llegar a QA **juntos**. Si el frontend
> sube primero, la columna Rol aparece vacía y el filtro por rol devuelve 400. Si sube primero el
> backend, no pasa nada (el listado viejo sigue leyendo los campos que el DTO conserva). Por lo
> tanto: **mergear backend antes que frontend**, o ambos en la misma ventana.

---

## 10. Criterios de aceptación

- [ ] En `Seguridad → Usuarios` se muestra una columna **Rol** con el rol de cada usuario.
- [ ] Cada columna del listado (Usuario, Nombre, Rol, Último ingreso, Bloqueado) tiene su propio
      filtro funcional.
- [ ] Los filtros se pueden **combinar** entre sí y el resultado es la intersección.
- [ ] El contador de registros (`/cnt`) coincide con el listado bajo **cualquier** combinación de
      filtros.
- [ ] El filtro **persiste** al cambiar de página y al cambiar el número de registros por página.
- [ ] El listado se puede **ordenar** por Rol en ambos sentidos.
- [ ] El botón de limpiar filtros deja el listado completo.
- [ ] El filtrado, el ordenamiento y la paginación siguen ocurriendo **en la base de datos**
      (verificable porque `/cnt` responde el total filtrado, no el total de la tabla).
- [ ] El alta y la edición de usuarios (`Usuario.vue`) siguen funcionando sin cambios.
- [ ] Los listados de Cotizaciones, Pólizas y Pólizas Externas —que consumen
      `v1/usuarios/users_name`— siguen funcionando.
- [ ] `dotnet build` limpio en `Services/auth` y `npm run lint` limpio en `frontend-omega`.
- [ ] El listado no expone ningún campo sensible nuevo (§8).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Un usuario tiene más de un rol en BD y la UI muestra sólo uno, ocultando información | Media | Alto | **T-02 lo verifica antes de escribir código.** Si aparecen casos, se escala al responsable antes de continuar |
| `GetCount` queda tipado contra `aspnetusers` y los filtros nuevos devuelven 400, rompiendo la paginación | Media | Alto | T-05 es tarea propia y explícita; T-13 lo cubre con la verificación listado vs `/cnt` |
| EF Core no traduce el filtro sobre `rol` y cae en evaluación en memoria (trae toda la tabla) | Baja | Medio | T-06 valida contra QA; si ocurriera, EF Core 8 lanza excepción en lugar de degradarse en silencio |
| Frontend y backend se despliegan desfasados a QA | Media | Medio | §9 fija el orden: backend primero, o ambos en la misma ventana |
| El estado global de filtros de `operacion-generica` arrastra filtros de otra pantalla | Baja | Bajo | El mixin `PlantillaListado` ya llama `limpia_filtros()` en `mounted`; T-13 lo verifica explícitamente |
| El build del frontend falla por versión de Node | Media | Bajo | `nvm use` (Node 16.15.1 en `.nvmrc`); el build **requiere** argumento de entorno (`npm run build qa`) |
| Aparece un consumidor no detectado de `GET v1/usuarios` | Baja | Medio | Análisis de impacto ya hecho (§6) y el DTO conserva los nombres JSON de los campos actuales |

---

## 12. Notas para el programador

1. **Nombre de la rama.** `rules/version-control.md` pide kebab-case
   (`feature/modulo-usuarios`). La rama se creó como **`feature/ModuloUsuarios`** por indicación
   expresa del responsable. Queda anotado como desviación consciente de la convención, no como
   error a corregir a mitad del trabajo.

2. **Sin PRD, pero con folio.** El responsable decidió no generar PRD para esta feature. Se le
   asignó de todos modos el folio **`PJ3074`** para poder registrarlo y darle seguimiento:
   - Proyecto en `pm_projects`: `modulo-usuarios` — "Modificación listado de usuarios",
     unidad `GPLUS Seguros`.
   - Plan en `pm_plan_desarrollo`: id **65**, estatus `Aprobado`, 7 días.
   - Las 4 fases quedan en `pm_plan_fase` con estatus `Pendiente` (ids en la §13).
   - La carpeta del proyecto es `Gplus-Seguros/PJ3074-modulo-usuarios/`. **No existe `PRD.md`** —
     este `PLAN.md` es el único documento de origen del alcance.

3. **No refactorizar.** `UsuariosController.cs` (556 líneas) ya excede el límite de 200 líneas por
   archivo de las guidelines, y `Usuario.vue` tiene 583. Es deuda preexistente: **no se toca** en
   este plan, según `rules/coding-guidelines.md`. Igualmente el `continuarFetch` muerto de
   `Usuarios.vue` (despacha a un `state.usuarios` que nadie lee) se deja como está — borrarlo es
   correcto pero no forma parte del alcance pedido.

4. **Estilo de código.** El repo `gp_seguros` está en **español y snake_case** en modelos y DTOs
   porque los nombres espejan las columnas de PostgreSQL, en contra de la regla general de Engine
   de escribir todo en inglés. El `CLAUDE.md` del repo indica mantener el estilo local en
   modelos/DTOs nuevos que mapean tablas — por eso el DTO se llama `usuario_listadoDTO` y no
   `UserListItemDto`. Es intencional.

5. **Decisión pendiente de validar:** T-11 (columna Activo) está marcada como opcional. Confirmar
   si entra al alcance antes de arrancar la Fase 2.

6. **Alcance de "cualquier campo".** El plan cubre todos los campos **del listado**. Grupo, empresa
   y sucursal son relaciones **uno a muchos** (`usuario_grupo`, `usuario_empresa`,
   `usuario_sucursal`), no caben en una celda plana y filtrarlas exige `any()` en OData — que el
   constructor de filtros del frontend no genera. Si se necesitan, son un plan aparte con cambios
   en `operacion-generica`. Se deja fuera explícitamente.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Contrato de API y validación** | Contrato del DTO congelado; cardinalidad usuario↔rol verificada en BD | T-01 a T-02 | 0.5 – 1 día | 230 |
| **Fase 1 — Backend `auth`** | DTO de listado, proyección en `Get` y `GetCount`, build y pruebas OData | T-03 a T-06 | 1 – 2 días | 231 |
| **Fase 2 — Frontend `frontend-omega`** | Catálogo de roles, columna Rol, filtros por columna, Bloqueado booleano, lint | T-07 a T-12 | 1.5 – 2.5 días | 232 |
| **Fase 3 — Integración y entrega** | Matriz de pruebas E2E en QA, verificación del gateway, commits y push | T-13 a T-15 | 1 – 1.5 días | 233 |
| **Total proyecto** | | 15 tareas | **~4 – 7 días hábiles** (≈ 1 – 1.5 semanas) | — |
| **Núcleo mínimo entregable** | Fase 0 + Fase 1 + T-08 (columna Rol) | T-01 a T-08 | ~2 – 3.5 días hábiles | — |

> **Notas sobre la tabla:**
> - No hay prioridades P1/P2/P3 porque no hay PRD que las defina. En su lugar se marca el
>   **núcleo mínimo entregable**: el rol visible en el listado, que es la mitad de mayor valor de
>   lo pedido y la que arrastra todo el trabajo de backend. Los filtros por columna son incrementales
>   sobre esa base.
> - Los rangos salen de la complejidad real de cada tarea: la Fase 1 concentra el riesgo técnico
>   (proyección OData + retipado del conteo) y la Fase 2 es mecánica salvo T-07 y T-10.
> - La columna **ID (BD)** trae los ids de `pm_plan_fase`. El plan es `pm_plan_desarrollo.id = 65`
>   (folio `PJ3074`).
> - **Discrepancia de redondeo, intencional:** `pm_plan_desarrollo.dias = 7` (total superior de esta
>   tabla), pero las duraciones enteras por fase suman **8**. `workflows/db-sync.md` manda redondear
>   hacia arriba el límite superior de **cada** fase por separado (1 + 2 + 3 + 2), y cuatro redondeos
>   independientes exceden el total. El número de referencia del proyecto son los **7 días**.

> **Riesgo de deadline:** el PRD no existe, por lo tanto **no hay fecha límite comprometida** contra
> la cual contrastar. Con un solo desarrollador el alcance completo cabe holgadamente en una semana
> de trabajo. **No se recomienda sumar un segundo desarrollador**: el trabajo es secuencial por
> diseño —el frontend depende del contrato que produce el backend—, así que un recurso adicional
> generaría coordinación sin comprimir el calendario. Si apareciera una fecha límite dura por
> debajo de 3 días hábiles, el recorte correcto es entregar el núcleo mínimo (T-01 a T-08) y dejar
> los filtros de Nombre, Último ingreso y Bloqueado para una segunda entrega.

---

*Generado por Claude Code — Engine CX*
*Modelo: claude-opus-5 — esfuerzo: alto*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`, y los `CLAUDE.md` de `gp_seguros` y `frontend-omega`*
