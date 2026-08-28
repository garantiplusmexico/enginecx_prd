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
| Estado general | 🟡 En progreso — 14 de 15 tareas completadas; T-13 bloqueada por despliegue a QA |

---

## Resumen de estado

**Todo el código está escrito, compilado, linteado y subido.** Backend y frontend quedaron en
`feature/ModuloUsuarios` en sus respectivos repos.

**Versionado completo (ver la sección "Versionado"):** frontend `1.1.29 → 1.1.30`; servicio `auth`
`serviceVersion 1.1 → 1.2` **y** imagen de despliegue `v2.2 → v2.3` en QA y prod. El gateway no se
versiona porque no se le agregó ningún endpoint.

**Lo único pendiente es T-13**, la matriz de pruebas manuales extremo a extremo contra QA. No es
ejecutable desde aquí: requiere que el código esté desplegado en QA (lo que ocurre al hacer push a
la rama `qa`, vía el flujo de PRs que es responsabilidad del programador) y validación manual en
navegador. La Fase 3 queda `Bloqueada` por esa dependencia externa, y el plan sigue `En curso`
hasta que se valide.

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
| Frontend | Versión de producto que se muestra en la UI | `.env.local`, `.env.qa`, `.env.production` (`VUE_APP_VERSION`) | `1.1.29 → 1.1.30` |
| `auth` — telemetría | `serviceVersion` que reporta OpenTelemetry | `Services/auth/Program.cs` | `1.1 → 1.2` |
| `auth` — despliegue QA | Tag de la imagen de ECR con la que arranca el contenedor | `Infrastructure/qa/Authentication-task-definition.json` | `v2.2 → v2.3` |
| `auth` — despliegue QA | `ImageVersion` que el script usa al desplegar | `Infrastructure/qa/deploy-services-v2.ps1` | `v2.2 → v2.3` |
| `auth` — despliegue prod | Tag de la imagen de ECR | `Infrastructure/prod/Authentication-task-definition.json` | `v2.2 → v2.3` |
| `auth` — despliegue prod | `ImageVersion` del script | `Infrastructure/prod/deploy-services-v2.ps1` | `v2.2 → v2.3` |
| API Gateway | Tag de la imagen `gp_seguros_api_gateway` | `Infrastructure/{qa,prod}/ApiGateway-task-definition.json` y sus scripts | **Sin cambio** — ver abajo |

**Por qué el tag y el `ImageVersion` se cambian juntos:** la función `Update-ImageVersion` de
`deploy-services-v2.ps1` reescribe el tag de la task definition en tiempo de despliegue con el valor
de `ImageVersion`. Cambiar sólo el JSON no sirve — el script lo sobreescribiría con el valor viejo.

**Por qué el gateway no sube de versión:** este trabajo **no agrega ningún endpoint**.
`GET /api/v1/usuarios`, `/usuarios/cnt` y `/roles` ya estaban ruteados, y `krakend.json` no se
modificó. La imagen `gp_seguros_api_gateway` tendría contenido idéntico, así que subirle el tag
desplegaría lo mismo con otro número. Si más adelante se agrega un endpoint, sí hay que tocar
`krakend.json` y subir su versión en los cuatro lugares equivalentes.

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
| **Total proyecto** | — | 15 tareas | ~4 – 7 | 2026-08-28 | | <1 | 1 | 🟡 En progreso |
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
| T-15 | Commits en ambos repos y entrega | Claude Code | 2026-08-28 | 5 commits, ambas ramas publicadas |

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
| `Infrastructure/qa/Authentication-task-definition.json` | Modificado (imagen `v2.2 → v2.3`) | Versionado |
| `Infrastructure/qa/deploy-services-v2.ps1` | Modificado (`ImageVersion v2.2 → v2.3`) | Versionado |
| `Infrastructure/prod/Authentication-task-definition.json` | Modificado (imagen `v2.2 → v2.3`) | Versionado |
| `Infrastructure/prod/deploy-services-v2.ps1` | Modificado (`ImageVersion v2.2 → v2.3`) | Versionado |
| `CLAUDE.md` | Restaurado desde la rama hermana | Prerequisito del flujo |

### `frontend-omega` (rama `feature/ModuloUsuarios`)

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `src/views/seguridad/usuarios/Usuarios.vue` | Modificado | T-07 a T-11 |
| `.env.local`, `.env.qa`, `.env.production` | Modificados (`VUE_APP_VERSION` 1.1.29 → 1.1.30) | Versionado |
| `CLAUDE.md` | Agregado al repo | Prerequisito del flujo |

### Sin cambios (confirmado)

- `Services/apigateway/krakend.json` — `input_query_strings: ["*"]` ya propaga los filtros nuevos.
  Al no agregarse endpoints, tampoco sube de versión la imagen del gateway.
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
