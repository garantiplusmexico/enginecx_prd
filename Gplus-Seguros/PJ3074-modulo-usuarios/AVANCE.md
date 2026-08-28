# Registro de Avance — Módulo de Usuarios (filtrado por campo + rol en listado)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan.
> Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/ModuloUsuarios` (en `gp_seguros` y en `frontend-omega`, ambas publicadas) |
| Responsable actual | Alexis Salvador Herrera Garcia |
| Folio PRD | `PJ3074` |
| ID plan (BD) | `65` |
| Modelo / esfuerzo | claude-opus-5 — esfuerzo: alto |
| Fecha de inicio | 2026-08-28 |
| Última actualización | 2026-08-28 |
| Estado general | 🟡 En progreso — 22 de 24 tareas completadas; T-13 y T-24 bloqueadas por despliegue a QA |

---

## Resumen de estado

**Todo el código está escrito, compilado, linteado y subido.** Backend y frontend quedaron en
`feature/ModuloUsuarios` en sus respectivos repos.

El plan cubre **dos módulos**: el listado de usuarios (fases 0 a 3) y el listado de empresas
(fases 4 y 5, agregadas el 2026-08-28 a petición del responsable sobre la misma rama).

**Versionado completo (ver la sección "Versionado"):** frontend `1.1.29 → 1.1.30`; `auth`
`v2.2 → v2.3`; `clientes` `v2.1 → v2.2`; y **el gateway** `v2.1 → v2.2`, éste último sí, porque la
Fase 4 agregó dos endpoints y con ello cambió `krakend.json`.

**Pendientes: T-13 y T-24**, ambas de validación manual contra QA. No son ejecutables desde aquí:
requieren el código desplegado (lo que ocurre al hacer push a la rama `qa`, vía el flujo de PRs que
es responsabilidad del programador) y validación en navegador. Las fases 3 y 5 quedan `Bloqueadas`
por esa dependencia externa, y el plan sigue `En curso` hasta que se validen.

**Lo que sí se verificó, y cómo:**

| Verificación | Método | Resultado |
|---|---|---|
| El backend compila | `dotnet build` en `Services/auth` | 0 errores, 27 advertencias (todas preexistentes) |
| EF traduce el filtro por rol a SQL y no lo evalúa en memoria | `IQueryable.ToQueryString()` en un proyecto desechable, sin conexión a BD | Confirmado — ver "Decisiones" |
| El frontend pasa lint | `npx eslint Usuarios.vue` | Limpio |
| El gateway no requiere cambios | Lectura y parseo de `krakend.json` | `input_query_strings: ["*"]` en ambos endpoints; JSON válido (402 endpoints) |
| Cardinalidad usuario↔rol | Auditoría del modelo EF y de todas las rutas de escritura de roles | Es invariante de aplicación, **no** del esquema — ver "Decisiones" |
| Que el cambio de contrato no rompa a ningún consumidor | Búsqueda de código en toda la organización de GitHub + auditoría del gateway | Un único consumidor, y es la vista que se actualizó — ver "Análisis de impacto" |

---

## Versionado

| Componente | Qué es | Dónde vive | Cambio |
|---|---|---|---|
| Frontend | Versión de producto que se muestra en la UI | `.env.local`, `.env.qa`, `.env.production` (`VUE_APP_VERSION`) | `1.1.29 → 1.1.30` (una sola vez para toda la entrega) |
| `auth` — **build** | **Construye la imagen Docker y la sube a ECR con ese tag** | `Services/auth/build.ps1` (`$version_nueva`, `$version_anterior`) | `v2.2 → v2.3` |
| `auth` — telemetría | `serviceVersion` que reporta OpenTelemetry | `Services/auth/Program.cs` | `1.1 → 1.2` |
| `auth` — despliegue QA | Tag de la imagen de ECR con la que arranca el contenedor | `Infrastructure/qa/Authentication-task-definition.json` | `v2.2 → v2.3` |
| `auth` — despliegue QA | `ImageVersion` que el script usa al desplegar | `Infrastructure/qa/deploy-services-v2.ps1` | `v2.2 → v2.3` |
| `auth` — despliegue prod | Tag de la imagen de ECR | `Infrastructure/prod/Authentication-task-definition.json` | `v2.2 → v2.3` |
| `auth` — despliegue prod | `ImageVersion` del script | `Infrastructure/prod/deploy-services-v2.ps1` | `v2.2 → v2.3` |
| `clientes` — build | Construye la imagen y la sube a ECR | `Services/clientes/build.ps1` | `v2.1 → v2.2` |
| `clientes` — telemetría | `serviceVersion` de OpenTelemetry | `Services/clientes/Program.cs` | `1.0 → 1.1` |
| `clientes` — despliegue | Tag e `ImageVersion` en QA y prod | `Infrastructure/{qa,prod}/Clients-task-definition.json` y `deploy-services-v2.ps1` | `→ v2.2` |
| API Gateway — build | Construye la imagen y la sube a ECR | `Services/apigateway/build.ps1` | `v2.1 → v2.2` |
| API Gateway — despliegue | Tag e `ImageVersion` en QA y prod | `Infrastructure/{qa,prod}/ApiGateway-task-definition.json` y `deploy-services-v2.ps1` | `→ v2.2` |

> **El gateway sí subió de versión en la Fase 4**, a diferencia de las fases 1 a 3. La razón es la
> regla, no la excepción: en las fases 1–3 no se agregó ningún endpoint y `krakend.json` no cambió,
> así que la imagen habría sido idéntica. En la Fase 4 sí se agregaron dos rutas nuevas, el archivo
> cambió y por lo tanto la imagen cambia de contenido y debe reconstruirse y redesplegarse.
>
> Se aprovechó para alinear los tags obsoletos de las task definitions, que traían `v1.0` (clients)
> y `v0.97` (gateway) mientras los scripts de despliegue ya usaban `v2.1`. Como `Update-ImageVersion`
> reescribe el JSON al desplegar, esos valores estaban muertos y sólo confundían a quien leyera el
> archivo.

**La cadena tiene cinco eslabones y todos deben coincidir.** `build.ps1` es el que compila, arma la
imagen y la sube a ECR con el tag de `$version_nueva`: si se omite, las task definitions apuntan a
un tag que **nunca se construyó** y el despliegue falla al no encontrar la imagen. Y el tag de la
task definition va siempre en pareja con el `ImageVersion` del script, porque `Update-ImageVersion`
reescribe el JSON en tiempo de despliegue — cambiar sólo el JSON no sirve, el script lo pisa con el
valor viejo.

Estado final de la cadena de `gp_seguros_auth`, verificado:

```
Services/auth/build.ps1                                   v2.3   (construye y sube a ECR)
Infrastructure/qa/Authentication-task-definition.json     v2.3
Infrastructure/qa/deploy-services-v2.ps1                  v2.3
Infrastructure/prod/Authentication-task-definition.json   v2.3
Infrastructure/prod/deploy-services-v2.ps1                v2.3
Services/auth/Program.cs   serviceVersion                 1.2    (telemetría, línea aparte)
```

**Cuándo sube el gateway y cuándo no.** Sube si y sólo si `krakend.json` cambia, porque es lo que
cambia el contenido de su imagen. En las fases 1 a 3 (listado de usuarios) no se agregó ningún
endpoint —`/usuarios`, `/usuarios/cnt` y `/roles` ya estaban ruteados— así que no subió. En la
Fase 4 se agregaron dos rutas para el listado de empresas, y por eso sí subió a `v2.2`.

**Cuántas veces sube cada componente.** Una sola vez por entrega, no una por fase. El frontend
subió a `1.1.30` en la Fase 2 y ese número cubre también la Fase 5; un segundo bump a `1.1.31` se
introdujo por error y se revirtió en el commit `f7ad67a`. `clientes` y el gateway sí subieron en la
Fase 4 porque era su primer bump de la entrega, y además es obligatorio: desplegar contenido nuevo
bajo un tag que ya existe en ECR dejaría corriendo la imagen vieja.

> `Services/auth/publish/` está en `.gitignore`. La imagen la construye y la sube el programador;
> el repo sólo declara con qué tag se desplegará.

---

## Análisis de impacto — quién consume el endpoint modificado

`GET v1/usuarios` cambió de contrato (de la entidad `aspnetusers` a `usuario_listadoDTO`) y
`GET v1/usuarios/cnt` cambió el tipo de sus `ODataQueryOptions`. Verificación de que no rompe a nadie:

| Verificación | Alcance | Resultado |
|---|---|---|
| Búsqueda de código en la organización de GitHub (`gh search code`) | Los ~60 repos de `garantiplusmexico` | El **único** consumidor de la colección es `frontend-omega/src/views/seguridad/usuarios/Usuarios.vue`, que es justamente la vista actualizada |
| Endpoints del gateway que agreguen `/usuarios` junto a otros backends | `krakend.json` completo (402 endpoints) | Ninguno. Los 8 endpoints `/usuarios*` tienen **un solo backend** cada uno; no hay agregación que mezcle este payload con otro |
| Acoplamiento a campos en el gateway (`allow`, `deny`, `mapping`, `group`, `target`) | Los 8 endpoints `/usuarios*` | Ninguno. Todos son `encoding: no-op` / `output_encoding: no-op` — passthrough puro de bytes; el gateway ni siquiera parsea el JSON |
| Llamadas internas entre microservicios | Todo `Services/**/*.cs` de `gp_seguros` | Ninguna. Ningún servicio llama a `/usuarios` por HTTP |
| Quién apunta al host interno `gp_omega_authentication` | Organización completa | Sólo `krakend.json` y el `docker-compose.yml` de desarrollo local |
| Construcción dinámica de la URL (concatenación en vez de literal) | `frontend-omega/src` | Las 4 concatenaciones existentes apuntan a `users_name` o `reset-password`, no a la colección |

**Endpoints vecinos que deliberadamente no se tocaron:** `v1/usuarios/{id}` (lo consume
`Usuario.vue`, que depende de `aspnetuserroles[0].roleId`), `v1/usuarios/users_name` (lo consumen
Cotizaciones, Pólizas y Pólizas Externas), `reset-password` y `reset-password-request`.

### Diferencia campo por campo, y quién usaba cada uno

Buscar por URL no basta: al pasar de la entidad al DTO hay propiedades que la respuesta anterior sí
traía y la nueva ya no. Éstas son, con la verificación de uso en todo `frontend-omega`:

| Campo | Antes | Ahora | ¿Quién lo usaba? |
|---|---|---|---|
| `id`, `userName`, `nombre`, `lastAccessDate`, `lockoutEnd` | ✅ | ✅ | Se conservan con el mismo nombre JSON |
| `lockoutEnabled` (bool) | ✅ | ❌ **eliminado** | **Nadie.** Cero coincidencias en todo `src/` |
| `aspnetuserroles` | `[]` (vacío) | ❌ eliminado | Sólo `Usuario.vue:326`, y lee del endpoint **de detalle** `v1/usuarios/{id}`, que no se tocó |
| `usuarios_grupo` | `[]` (vacío) | ❌ eliminado | Sólo `Usuario.vue:327`, mismo endpoint de detalle |
| `usuarios_empresa` | `[]` (vacío) | ❌ eliminado | Sólo `Usuario.vue:331`, mismo endpoint de detalle |
| `usuarios_sucursal` | `[]` (vacío) | ❌ eliminado | Sólo `Usuario.vue:346`, mismo endpoint de detalle |
| `id_rol`, `rol`, `bloqueado`, `activo` | ❌ | ✅ **nuevos** | Aditivos; no rompen nada |

**Por qué las cuatro colecciones son seguras:** las cuatro lecturas viven en
`Usuario.vue → prepara_modificacion()`, que construye su URL como
`'v1/usuarios/' + this.$route.params.id` — es el endpoint de **detalle**, no la colección. Ese
endpoint sigue devolviendo la entidad `aspnetusers` y sigue haciendo `Include` de esas cuatro
navegaciones. Importa porque el código hace `.length` y `[0]` sin guarda: si esos datos hubieran
venido de la colección, ahora reventaría con *cannot read properties of undefined*.

**Consumidores de los items del listado, uno por uno:**

| Consumidor | Qué lee | Estado |
|---|---|---|
| `TablaOmega` — celdas | `item[Header.value]` para cada header | Los 5 headers (`userName`, `nombre`, `rol`, `lastAccessDate`, `bloqueado`) existen en el DTO |
| `TablaOmega` — clic en fila | `e[permissions.editar.id]`, con `id: 'id'` | El DTO expone `Id` → serializa como `id` |
| `Usuarios.vue` — `continuarFetch` | Despacha `datos` a `listUsuarios` → `state.usuarios` | Escritura a estado muerto: la única coincidencia de `state.usuarios` en todo `src/` es la mutación que lo escribe. Nadie lo lee |

**Conclusión: ningún consumidor del frontend se rompe.** El único campo que desapareció de verdad
—`lockoutEnabled`— no se usa en ninguna parte, y las cuatro colecciones que desaparecieron sólo se
leen desde el endpoint de detalle, que quedó intacto.

**Límites de esta verificación — lo que no cubre:**

- `gh search code` indexa **sólo la rama por defecto** de cada repo. Un consumidor que viva en una
  rama sin mergear no aparecería.
- No cubre consumidores **fuera de GitHub**: flujos de N8N (VPS de Hostinger), colecciones de
  Postman, integraciones de terceros o cualquier cliente que pegue directo contra la API.

Si existiera un consumidor así, el impacto sería acotado: el DTO **conserva con el mismo nombre
JSON** todos los campos que el listado ya exponía (`id`, `userName`, `nombre`, `lastAccessDate`,
`lockoutEnd`). Lo único que desaparece son las colecciones de navegación (`aspnetuserroles`,
`usuarios_empresa`, `usuarios_sucursal`, `usuarios_grupo`), que **ya venían vacías** porque el
`Get()` original nunca hacía `Include`.

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Contrato de API y validación** | 230 | T-01 a T-02 | 0.5 – 1 | 2026-08-28 | 2026-08-28 | <1 | 0 | ✅ Completada |
| **Fase 1 — Backend `auth`** | 231 | T-03 a T-06 | 1 – 2 | 2026-08-28 | 2026-08-28 | <1 | 0 | ✅ Completada |
| **Fase 2 — Frontend `frontend-omega`** | 232 | T-07 a T-12 | 1.5 – 2.5 | 2026-08-28 | 2026-08-28 | <1 | 0 | ✅ Completada |
| **Fase 3 — Integración y entrega** | 233 | T-13 a T-15 | 1 – 1.5 | 2026-08-28 | | <1 | 1 | 🔴 Bloqueada (T-13) |
| **Fase 4 — Backend: listado de empresas** | 234 | T-16 a T-20 | 1.5 – 2 | 2026-08-28 | 2026-08-28 | <1 | 0 | ✅ Completada |
| **Fase 5 — Frontend: columna de aseguradoras** | 235 | T-21 a T-24 | 1 – 2 | 2026-08-28 | | <1 | 1 | 🔴 Bloqueada (T-24) |
| **Total proyecto** | — | 24 tareas | ~6.5 – 11 | 2026-08-28 | | <1 | 2 | 🟡 En progreso |
| **Núcleo mínimo entregable** | — | T-01 a T-08 | ~2 – 3.5 | 2026-08-28 | 2026-08-28 | <1 | 0 | ✅ Completada |

> **Nota sobre los días ejecutados:** la ejecución fue asistida por IA y tomó bastante menos de un
> día hábil. Los rangos estimados del plan corresponden a esfuerzo humano y se conservan sin
> alterar, como referencia de la complejidad real del cambio.

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Congelar el contrato del DTO de listado | Claude Code | 2026-08-28 | Contrato de la §4 del plan, sin cambios |
| T-02 | Verificar la cardinalidad usuario↔rol | Claude Code | 2026-08-28 | Resuelta contra el modelo del backend, no contra datos. Ver "Decisiones" |
| T-03 | Crear el DTO de listado | Claude Code | 2026-08-28 | `usuario_listadoDTO.cs` |
| T-04 | Proyectar `UsuariosController.Get()` al DTO | Claude Code | 2026-08-28 | Proyección extraída a `ConsultaListadoUsuarios()` |
| T-05 | Alinear `GetCount` a la misma proyección | Claude Code | 2026-08-28 | Comparte literalmente el mismo método que T-04 |
| T-06 | Compilar y probar el microservicio `auth` | Claude Code | 2026-08-28 | Build limpio + verificación de SQL generado |
| T-07 | Cargar el catálogo de roles en el listado | Claude Code | 2026-08-28 | `mounted()` propio; encadena con el del mixin |
| T-08 | Agregar la columna Rol al listado | Claude Code | 2026-08-28 | Filtro por `v-select` |
| T-09 | Habilitar filtro en Nombre y Último ingreso | Claude Code | 2026-08-28 | Retirado `sinFiltro` de ambos headers |
| T-10 | Convertir Bloqueado en filtro booleano | Claude Code | 2026-08-28 | Pasa de `lockoutEnd` (fecha) a `bloqueado` (bool) |
| T-11 | *(Opcional)* Columna Activo | Claude Code | 2026-08-28 | **Implementada y luego retirada.** Ver "Decisiones" |
| T-12 | Lint del frontend | Claude Code | 2026-08-28 | `Usuarios.vue` limpio |
| T-14 | Verificar que el gateway no requiere cambios | Claude Code | 2026-08-28 | Verificado estáticamente; falta la prueba real contra QA |
| T-15 | Commits en ambos repos y entrega | Claude Code | 2026-08-28 | Ambas ramas publicadas |
| T-16 | Crear el DTO de listado de empresas | Claude Code | 2026-08-28 | `empresa_listadoDTO.cs`, con `aseguradoras` como `List<int>` |
| T-17 | Endpoint de listado y su conteo | Claude Code | 2026-08-28 | `GET /empresas/listado` y `/listado/cnt`; conserva la autorización por rol |
| T-18 | Registrar las rutas en el gateway | Claude Code | 2026-08-28 | +2 endpoints en `krakend.json` (402 → 404), JSON válido |
| T-19 | Versionado de `clientes` y del gateway | Claude Code | 2026-08-28 | Ambos a `v2.2` en sus 5 lugares |
| T-20 | Compilar y verificar la traducción a SQL | Claude Code | 2026-08-28 | Build limpio; `LIMIT` antes del join y filtro como subconsulta correlacionada |
| T-21 | Apuntar el listado al endpoint nuevo | Claude Code | 2026-08-28 | `v1/empresas/listado` |
| T-22 | Cargar el catálogo de aseguradoras | Claude Code | 2026-08-28 | `mounted()` contra `v1/aseguradoras` |
| T-23 | Agregar la columna Aseguradoras | Claude Code | 2026-08-28 | Ids resueltos a `nombre_comercial`; degrada a `#id` |

---

## Tareas en progreso 🟡

*(ninguna)*

---

## Tareas pendientes ⏳

*(ninguna fuera de la bloqueada)*

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| T-13 | Prueba de integración manual E2E contra QA (8 escenarios) | Requiere el código desplegado en QA y validación manual en navegador. El despliegue se dispara al hacer push a la rama `qa`, y los PRs son responsabilidad del programador, no de Claude | Alexis Salvador Herrera Garcia |
| T-24 | Validar en QA el filtro por aseguradora del listado de empresas | Mismo bloqueo que T-13. El código está completo y linteado, pero el `any()` de OData sobre la colección de ids sólo se puede confirmar contra el servicio corriendo | Alexis Salvador Herrera Garcia |

**Matriz que falta ejecutar (§4, T-13 del plan):**

| Escenario | Verificación |
|---|---|
| Filtro por cada columna, uno a uno | Resultados correctos y `/cnt` consistente con el listado |
| Dos y tres filtros combinados | El backend recibe `filter=… and … and …` y responde coherente |
| Filtro + cambio de página | El filtro persiste al paginar |
| Filtro + `$orderby` por Rol | Orden correcto, ascendente y descendente |
| Botón "limpiar todos los filtros" | Vuelve al listado completo |
| Navegar a otra pantalla de listado y volver | Sin arrastre de filtros |
| Usuario sin rol asignado (si existe) | La celda Rol queda vacía, sin romper la fila |
| Clic en fila → edición | Sigue navegando con el `id` correcto y `Usuario.vue` carga el rol |

**Además, correr en QA el SQL que quedó pendiente de T-02:**

```sql
SELECT "UserId", count(*) AS roles
FROM "AspNetUserRoles"
GROUP BY "UserId"
HAVING count(*) > 1;
```

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| **T-02 se resolvió contra el modelo del backend, no contra los datos** | La BD de pruebas (`192.168.1.65`, `gp_seguros_test`) no es alcanzable desde la máquina del desarrollador y no hay cliente de PostgreSQL instalado. Indicación explícita del responsable | **El hallazgo cambia el supuesto del plan:** el esquema **no** impone 1:1 — `AspNetUserRoles` tiene PK compuesta `(UserId, RoleId)` y relación `HasOne(aspnetusers).WithMany(...)`, sin constraint único sobre `UserId`. Quien sí impone el 1:1 es la aplicación: sólo existen dos rutas de escritura de roles en todo el repo (`UsuariosController.cs:201` y `:444`), ambas escriben un rol y `UpdateById` borra todos los previos antes de insertar. El login sí toleraría multi-rol (`GetRolesAsync` devuelve lista y sólo exige intersección no vacía). Conclusión: `FirstOrDefault()` es coherente con el resto del sistema; el riesgo residual son filas heredadas, y eso sólo lo despeja el SQL en QA |
| **La proyección se extrajo al método privado `ConsultaListadoUsuarios()`** | El criterio de T-05 exige que listado y conteo vean el mismo modelo. Duplicar la proyección lo dejaba dependiendo de la disciplina de quien edite después | El invariante queda garantizado estructuralmente: si alguien cambia un campo, cambia en ambos endpoints |
| **Verificación de traducción a SQL sin conexión a BD** | El riesgo técnico #3 del plan era que EF cayera en evaluación en cliente y trajera la tabla completa. `ToQueryString()` genera el SQL sin abrir conexión | Confirmado que todo baja a SQL: el filtro por rol a `WHERE lower((subconsulta correlacionada)) LIKE '%…%'`, `bloqueado` a `LockoutEnd IS NOT NULL`, el orden a `ORDER BY (subconsulta)` y la paginación a `LIMIT/OFFSET`. El riesgo #3 queda cerrado |
| **T-11 (columna Activo) se implementó y después se retiró** | Al verificar la Fase 3 se encontró que `aspnetusers.activo` se escribe en un único punto del servicio (`UsuariosController.cs:230`, al crear el usuario, siempre `1`) y ninguna ruta lo modifica — `UpdateById` no lo toca | La columna habría mostrado "Si" para todos y su filtro no discriminaría nada. Se retiró del frontend con un comentario que explica por qué. El campo `activo` **se conserva en el DTO**: no cuesta nada y deja la columna a un header de distancia si el backend implementa baja de usuarios |
| **`CLAUDE.md` se comiteó en ambos repos** | Es prerequisito del flujo de Engine. En `gp_seguros` existía sólo en la rama hermana `feature/productos-adicionales-garantia-siga` (aún sin mergear) y en `frontend-omega` estaba sin trackear | Contenido idéntico al de la rama hermana, por lo que no genera conflicto al integrar. Commits separados para no mezclarlo con la feature |
| **El listado de empresas se resolvió con un endpoint nuevo, no modificando el existente** | `GET /empresas` tiene **13 consumidores** en `frontend-omega` (cotizaciones, pólizas, órdenes de pago, sucursales, usuarios, login…), varios de los cuales sí dependen del grafo completo | Se creó `GET /empresas/listado`. Es el caso opuesto al del listado de usuarios, donde el único consumidor era la propia vista y sí se pudo cambiar el contrato en sitio |
| **Causa raíz de la lentitud del listado de empresas** | Diagnóstico sobre `EmpresasController.Get()` | Carga **nueve `Include`, siete de ellos de colecciones**, sin `QuerySplitting`. EF Core lo resuelve como un único `JOIN` que multiplica filas —explosión cartesiana— y después serializa el grafo completo por empresa, para pintar 8 columnas escalares. El endpoint nuevo baja a **dos `LEFT JOIN`** con el `LIMIT` aplicado en una subconsulta **antes** del join, de modo que la paginación cuenta empresas y no filas explotadas |
| **Las aseguradoras viajan como ids, no como nombres** | Decisión del responsable. `aseguradora_empresa` sólo tiene `id_empresa`, `id_aseguradora` y `activa`, y **no** tiene navegación a `aseguradora` | Evita agregar una propiedad de navegación al modelo EF. El frontend resuelve el `nombre_comercial` contra el catálogo `v1/aseguradoras`. El filtro se expresa como `aseguradoras/any(a: a eq {id})`, que EF traduce a `WHERE {id} IN (SELECT …)` correlacionado |
| **`activa` de `aseguradora_empresa` no se filtra — pendiente de confirmar** | La pregunta quedó sin respuesta explícita; se tomó la lectura literal de "configuradas" = filas de la tabla de relación | La columna muestra **todas** las aseguradoras relacionadas, activas o no. Si se quieren sólo las activas, es agregar `.Where(a => a.activa == 1)` en la proyección: una línea |
| **La columna Grupo dejó de usar `transformarGrupo`** | El endpoint viejo devolvía `grupo` como objeto y la función leía `item.grupo.nombre`; el DTO nuevo lo entrega aplanado como string | De haberla dejado conectada, la columna Grupo habría mostrado `-` en **todas** las filas, porque `"texto".nombre` es `undefined`. Es el tipo de rotura silenciosa que no da error |
| **Ejecución en `claude-opus-5` en lugar de familia Sonnet** | El workflow pide Sonnet, pero la sesión corre en Opus 5 y el cambio de modelo no es posible desde dentro. El responsable autorizó continuar | Sólo afecta la trazabilidad registrada en los commits |
| **Versionado: frontend patch, backend menor** | La convención real del frontend en sus últimos 8 releases es patch sobre `VUE_APP_VERSION`. El backend usa `serviceVersion` de dos partes (`1.0`, `1.1`, `2.2`) y esto es una feature | Frontend `1.1.29 → 1.1.30` en los tres `.env`; `auth` `1.1 → 1.2` |

---

## Archivos creados o modificados

### `gp_seguros` (rama `feature/ModuloUsuarios`)

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `Services/auth/Models/DTO/usuario_listadoDTO.cs` | Creado | T-03 |
| `Services/auth/Controllers/UsuariosController.cs` | Modificado | T-04, T-05 |
| `Services/auth/Program.cs` | Modificado (`serviceVersion` 1.1 → 1.2) | Versionado |
| `Services/auth/build.ps1` | Modificado (`$version_nueva v2.2 → v2.3`) | Versionado |
| `Services/clientes/Models/DTO/empresa_listadoDTO.cs` | Creado | T-16 |
| `Services/clientes/Controllers/EmpresasController.cs` | Modificado | T-17 |
| `Services/apigateway/krakend.json` | Modificado (+2 endpoints) | T-18 |
| `Services/clientes/build.ps1`, `Services/clientes/Program.cs` | Modificados (versionado `clientes`) | T-19 |
| `Services/apigateway/build.ps1` | Modificado (versionado gateway) | T-19 |
| `Infrastructure/{qa,prod}/Clients-task-definition.json` | Modificados (`→ v2.2`) | T-19 |
| `Infrastructure/{qa,prod}/ApiGateway-task-definition.json` | Modificados (`→ v2.2`) | T-19 |
| `Infrastructure/qa/Authentication-task-definition.json` | Modificado (imagen `v2.2 → v2.3`) | Versionado |
| `Infrastructure/qa/deploy-services-v2.ps1` | Modificado (`ImageVersion v2.2 → v2.3`) | Versionado |
| `Infrastructure/prod/Authentication-task-definition.json` | Modificado (imagen `v2.2 → v2.3`) | Versionado |
| `Infrastructure/prod/deploy-services-v2.ps1` | Modificado (`ImageVersion v2.2 → v2.3`) | Versionado |
| `CLAUDE.md` | Restaurado desde la rama hermana | Prerequisito del flujo |

### `frontend-omega` (rama `feature/ModuloUsuarios`)

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `src/views/seguridad/usuarios/Usuarios.vue` | Modificado | T-07 a T-11 |
| `src/views/configuracion/empresas/Empresas.vue` | Modificado | T-21 a T-24 |
| `.env.local`, `.env.qa`, `.env.production` | Modificados (`VUE_APP_VERSION` 1.1.29 → 1.1.30) | Versionado |
| `CLAUDE.md` | Agregado al repo | Prerequisito del flujo |

### Sin cambios (confirmado)

- `Services/apigateway/krakend.json` — para el listado de usuarios no requirió cambios. **Sí se modificó
  en la Fase 4** para rutear los dos endpoints nuevos de empresas, y por eso el gateway sí subió de
  versión en esa fase.
- Base de datos — no hay migración ni cambio de esquema.
- `Services/auth/Controllers/AuthenticationController.cs`, `RolesController.cs` — intactos.
- `v1/usuarios/{id}` y `v1/usuarios/users_name` — intactos, según el análisis de impacto de la §6.

---

## Commits realizados

| Repo | Hash | Mensaje | Fecha |
|---|---|---|---|
| enginecx_prd | `b4775dd` | `[modulo-usuarios] Plan de desarrollo generado` | 2026-08-28 |
| enginecx_prd | `4659cab` | `[modulo-usuarios] AVANCE.md inicial - arranque de ejecucion` | 2026-08-28 |
| gp_seguros | `5f4ee303` | `[modulo-usuarios] Restaurar CLAUDE.md en la rama de trabajo` | 2026-08-28 |
| gp_seguros | `2cbde63d` | `[modulo-usuarios] Fase 1 - Proyeccion plana del listado de usuarios con rol` | 2026-08-28 |
| gp_seguros | `299ac36f` | `[modulo-usuarios] Subir version de despliegue del servicio auth a v2.3` | 2026-08-28 |
| gp_seguros | `526a55af` | `[modulo-usuarios] Subir version en el build del servicio auth (v2.2 -> v2.3)` | 2026-08-28 |
| gp_seguros | `9365385d` | `[modulo-usuarios] Fase 4 - Endpoint plano para el listado de empresas` | 2026-08-28 |
| frontend-omega | `1743518` | `[modulo-usuarios] Fase 5 - Columna de aseguradoras filtrable en el listado de empresas` | 2026-08-28 |
| frontend-omega | `c522ce8` | `[modulo-usuarios] Agregar CLAUDE.md al repositorio` | 2026-08-28 |
| frontend-omega | `fd4d815` | `[modulo-usuarios] Fase 2 - Columna de rol y filtros por columna en el listado` | 2026-08-28 |
| frontend-omega | `247bf2f` | `[modulo-usuarios] Fase 3 - Retirar la columna Activo del listado (T-11)` | 2026-08-28 |

---

## Notas para quien retome el trabajo

**Por dónde continuar:** desplegar a QA y ejecutar la matriz de T-13 (arriba, en "Tareas
bloqueadas"). Ese es el único trabajo restante.

**Orden de despliegue — importante.** Backend y frontend deben llegar a QA juntos, o el backend
primero. Si el frontend sube solo, la columna Rol aparece vacía y el filtro por rol devuelve 400,
porque el DTO todavía no existe del otro lado.

**Ruta de integración** (manual, del programador — Claude no crea PRs):

```
feature/ModuloUsuarios → pre-qa (merge local, en ambos repos)
pre-qa → qa (PR; la CI rechaza cualquier PR a qa que no venga de pre-qa)
```

**Contexto clave:** el corazón del cambio es `ConsultaListadoUsuarios()` en
`UsuariosController.cs`. Aplana el rol para que el filtro, el orden y el conteo puedan operar sobre
un campo escalar. Si alguien agrega un campo al listado, hay que agregarlo ahí y en
`usuario_listadoDTO` — el conteo lo hereda solo.

**Trampa conocida:** el estado de filtros de `operacion-generica` es un singleton global compartido
entre vistas. El mixin `PlantillaListado` lo limpia en `mounted`, pero es la causa clásica de
"filtros que se arrastran de otra pantalla" si alguien agrega una vista sin el mixin.

**Deuda detectada, fuera de alcance, no tocada:**

- `format_fecha` en `Usuarios.vue` devuelve `"Fecha no válida"` cuando `lastAccessDate` es nulo, es
  decir para todo usuario que nunca ha entrado. Es preexistente y ahora es más visible porque la
  columna se volvió filtrable. Un `if (!value) return '—'` lo arregla.
- `continuarFetch` en `Usuarios.vue` despacha a `listUsuarios` → `state.usuarios`, que **ninguna
  vista lee**. Es código muerto.
- `GET /Usuarios` no declara política de rate limiting.
- `UsuariosController.cs` (581 líneas) y `Usuario.vue` (583) exceden el límite de 200 líneas de las
  guidelines. Deuda preexistente; el plan prohíbe refactorizar sin petición explícita.

---

*Actualizado automáticamente por Claude Code — Engine CX*
