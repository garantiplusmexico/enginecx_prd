# Plan de Desarrollo — Nuevo rol Usuario Distribuidor-Taller

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.


| Campo               | Detalle                                                       |
| ------------------- | ------------------------------------------------------------- |
| PRD de origen       | `enginecx_prd/SIGA/PJ4981-usuario-distribuidor-taller/PRD.md` |
| Repositorio         | `gp_4.0_siga` (SIGA Web — GarantiplusWeb)                     |
| Rama                | `feature/PJ4981-usuario-distribuidor-taller`                  |
| Tipo                | Feature sobre proyecto existente                              |
| Responsable         | Alejandro Govea Hernández                                     |
| Fecha de generación | 2026-07-15                                                    |
| Rama base           | `develop` (actualizada con `git pull`)                        |
| Estado              | Borrador                                                      |


---



## 1. Resumen técnico

Se agrega un nuevo rol **"Usuario Distribuidor-Taller"** al catálogo de usuarios de SIGA (GarantiplusWeb, ASP.NET Core 8 MVC + Razor, EF Core sobre PostgreSQL). El rol debe operar con la **unión** de las opciones/permisos de los roles existentes **"Usuario Distribuidor"** y **"Taller"**, ligado a **N distribuidores** y **1 taller**.

**Hallazgo determinante (del análisis del código):** SIGA **no tiene un modelo de permisos data-driven**. La autorización y la visibilidad de opciones están **hardcodeadas por nombre/GUID de rol** en tres capas dispersas:

1. Menús laterales (`profiles="..."` en `_LeftMenuBar_{MEX,CHL,COL}.cshtml`) y navegación legacy (`User.IsInRole(...)`).
2. Autorización de acciones (`[Authorize(Roles="...")]` en cada controller).
3. Filtrado de aislamiento de datos, que hoy usa bloques **mutuamente excluyentes** `if (Usuario Distribuidor) … else if (Taller) …`.

Por tanto, el rol combinado **no hereda permisos automáticamente**: el trabajo consiste en (a) crear el rol, (b) habilitarlo en el alta/edición ligando ambos tipos de entidad a la vez, (c) añadir el nombre del rol a cada punto de permiso donde hoy aparecen "Usuario Distribuidor" o "Taller", y (d) convertir los bloques de filtrado excluyentes en **aditivos** para que el usuario combinado vea los datos de sus distribuidores **y** de su taller sin fuga de datos.

- **Arquitectura:** se mantiene la del proyecto existente (SIGA Web monolítico en EC2). No se crean servicios ni infraestructura nueva. No aplica el default de microservicios porque es una feature sobre un sistema existente (ver `rules/arquitectura.md` §3 y §5).
- **Stack:** el ya existente del proyecto (C#/.NET 8, Razor + jQuery, PostgreSQL). No se introduce stack nuevo.
- **BD:** se agrega un registro de rol (no hay migraciones EF en el repo; los roles se siembran por script SQL — ver §5).

> ⚠️ **Nota de alcance / regla anti-refactor:** este plan modifica bloques `if/else` existentes de filtrado. No es refactor cosmético — es un cambio **funcional obligatorio** sin el cual el rol combinado no puede aislar datos correctamente. Se acota al mínimo necesario y se aísla en un helper nuevo (T-11) para no reescribir la lógica existente. El programador debe validar este punto (ver §12).

---



## 2. Prerequisitos

- [x] PRD validado por el responsable.
- [x] Acceso de escritura al repo `gp_4.0_siga` confirmado.
- [x] **Definir la nomenclatura técnica exacta del rol** (pregunta abierta del PRD §14) — ver T-01.
- [x] Acceso a las BD de los ambientes (dev/QA) para aplicar el seed del rol (MX y, si aplica, CO/CL).
- [x] Confirmar en qué países se libera (MX obligatorio; CO/CL usan `DataAccessColombia` y menús `_COL`/`_CHL` — ver §12).
- [x] `CLAUDE.md` presente en el repositorio. ✅ (generado en esta sesión).

---



## 3. Arquitectura del cambio

No hay cambio arquitectónico. Todo ocurre dentro de GarantiplusWeb y su capa de datos.

```
[Admin SIGA] → UsuariosController (Create/Edit)
                    │
                    ├── AspNetUserRoles         (rol = "Usuario Distribuidor-Taller")
                    ├── usuario_distribuidor     (N filas: userid × id_distribuidor)
                    └── usuario_taller           (1 fila: userid × id_taller)

[Usuario final] → Login → IsInRole("Usuario Distribuidor-Taller")
                    │
                    ├── Menú/Autorización: unión de opciones Distribuidor ∪ Taller
                    └── Filtrado de datos: por SUS distribuidores  ∪  por SU taller
```

**Modelo de datos existente que se reutiliza (sin cambios de esquema):**

- `aspnetusers` ↔ `usuario_distribuidor` (N:M, PK `{id_distribuidor, userid}`).
- `aspnetusers` ↔ `usuario_taller` (1:1 lógico, PK `{userid, id_taller}`).
- `aspnetroles` / `aspnetuserroles` (ASP.NET Identity).

---



## 4. Tareas de desarrollo



### Fase 0 — Alta del rol en BD

- [x] **T-01 — Definir nomenclatura técnica y GUID fijo del rol**
  - Decisión requerida: `Name = "Usuario Distribuidor-Taller"`, `NormalizedName = "USUARIO DISTRIBUIDOR-TALLER"`, `Id` = **GUID fijo** (generado una sola vez) para poder referenciarlo de forma estable en las vistas (los `is-visible` de `_Edit.cshtml` referencian roles por GUID).  
  - Decisión (acordado el 2026-07-15):  - "Id" = 'ead42fa6-dd6b-421b-8732-a3558691b234' - "Name" = 'Usuario Distribuidor-Taller' - "NormalizedName" = 'USUARIO DISTRIBUIDOR-TALLER'
  - Archivos: solo decisión documentada (se consume en T-02 y T-04).
  - Criterio de completitud: nombre y GUID acordados con el responsable y anotados en este plan.

- [x] **T-02 — Script SQL de alta del rol**
  - Crear `GarantiplusWeb/BD/2026-07-15_rol_usuario_distribuidor_taller/rol_usuario_distribuidor_taller.sql` siguiendo el patrón existente (`GarantiplusWeb/BD/2024-01-24_rol_gestor_de_paises/rol_gestor_de_paises.sql` y `hub_Panama.sql:42`, que usan `Id` fijo).
  - `INSERT INTO "AspNetRoles" (Id, Name, NormalizedName, ConcurrencyStamp)` con el GUID fijo de T-01, idempotente (`ON CONFLICT DO NOTHING` o guard `WHERE NOT EXISTS`).
  - Criterio de completitud: script ejecuta sin error en una BD limpia y en una con el rol ya presente; el rol aparece en `AspNetRoles`.



### Fase 1 — Catálogo de usuarios: alta/edición del rol combinado

- [x] **T-03 — Exponer el rol en el selector y poblar talleres**
  - `UsuariosController.cs` → `SetupViewBags` (139-175): incluir el nuevo rol en `ViewBag.Roles` (hoy la rama general excluye solo `"Taller"` en la línea ~169; verificar que el rol combinado sí aparezca tanto para "Administrador General" como para "Gestor de Países").
  - Resolver la carga de `ViewBag.Talleres`: hoy **nunca** se llena en `SetupViewBags` (el combo de taller depende del AJAX de la acción `Talleres` 184-201). Decidir y dejar consistente: o poblar `ViewBag.Talleres` en `SetupViewBags`, o garantizar que el JS del `_Edit` invoque `Talleres` cuando el rol seleccionado sea el combinado.
  - Archivos: `GarantiplusWeb/Areas/Catalogos/Controllers/UsuariosController.cs`.
  - Criterio de completitud: al abrir Crear/Editar usuario, "Usuario Distribuidor-Taller" aparece en el dropdown de rol y el combo de taller se puebla.

- [x] **T-04 — Visibilidad de campos en el formulario**
  - `GarantiplusWeb/Areas/Catalogos/Views/Usuarios/_Edit.cshtml`: añadir el **GUID del nuevo rol** (T-01) a los `is-visible` de:
    - Distribuidores (multi-select, líneas ~61-70) → debe mostrarse.
    - Taller (single, líneas ~53-60, hoy `is-visible="id_rol,Taller"`) → añadir el GUID/valor del rol combinado para que también aparezca.
  - Confirmar que la lógica client-side (`is-visible` → `tw-hidden`) soporta que **ambos** campos se muestren a la vez para el mismo rol (hoy ningún rol muestra los dos).
  - Archivos: `_Edit.cshtml` (y revisar `Create.cshtml`/`Edit.cshtml` que lo renderizan).
  - Criterio de completitud: seleccionando el rol combinado en el formulario, se muestran simultáneamente el multi-select de distribuidores y el select de taller.

- [x] **T-05 — Validación obligatoria (RF-07)**
  - Cliente: en `Create.cshtml` (17-20) la validación exige `distribuidores[]`; agregar regla condicional para que, cuando el rol = combinado, exija **≥1 distribuidor y exactamente 1 taller**.
  - Servidor: en `Create` POST y `Edit` POST de `UsuariosController.cs`, validar lo mismo antes de persistir y devolver error claro (RNF-03) si falta alguno.
  - Criterio de completitud: no se puede guardar un usuario combinado sin al menos un distribuidor y un taller; el mensaje de validación es explícito.



### Fase 2 — Persistencia de las ligas

- [x] **T-06 — Create POST: ligar distribuidores + taller a la vez**
  - `UsuariosController.cs` `Create` POST (204-388): hoy la inserción de `usuario_distribuidor` vive en una rama `else if` excluyente respecto a `proyectos` (296 vs 326), y el taller se inserta aparte (341-349). Ajustar el flujo para que, con el rol combinado, se inserten **tanto** los N `usuario_distribuidor` **como** la fila `usuario_taller` en la misma alta.
  - Criterio de completitud: crear un usuario combinado deja N filas en `usuario_distribuidor` y 1 en `usuario_taller` para ese `userid`.

- [x] **T-07 — Edit POST: actualizar ambas ligas**
  - `UsuariosController.cs` `Edit` POST (438-558): replicar el borrado+reinserción para distribuidores (474/492-504) y taller (526-539) de forma que el rol combinado mantenga ambas relaciones al editar.
  - Criterio de completitud: editar los distribuidores y/o el taller de un usuario combinado persiste correctamente sin dejar filas huérfanas.

- [x] **T-08 — Reflejar ambas ligas en lectura**
  - `Details` (86-120) y `Listado` (33-78): asegurar que las navegaciones `distribuidores` y `taller` se incluyan/muestren para el rol combinado (el `Include`/`Filter` ya trae `distribuidores`; verificar que también traiga `taller`).
  - Criterio de completitud: la ficha y el listado del usuario combinado muestran sus distribuidores y su taller.



### Fase 3 — Unión de permisos (opciones/menú y autorización)

- [x] **T-09 — Menús: añadir el rol donde aparece Distribuidor o Taller**
  - En `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_MEX.cshtml` (y `_CHL`, `_COL` si se liberan esos países): agregar `"Usuario Distribuidor-Taller"` a cada `profiles="..."` que hoy incluya `"Usuario Distribuidor"` **o** `"Taller"` (unión). Ej.: Contratos (106-109), Averías (157-166), Catálogos/Distribuidores (44-55).
  - Revisar navegación legacy si sigue activa (`Views/Shared/_Navigation*.cshtml` con `@if(User.IsInRole(...))`).
  - Criterio de completitud: el usuario combinado ve en el menú la unión exacta de las opciones de Distribuidor y Taller — ni más ni menos.

- [x] **T-10 — Autorización de acciones**
  - Añadir `"Usuario Distribuidor-Taller"` a los `[Authorize(Roles="...")]` de las acciones donde hoy figura `"Usuario Distribuidor"` o `"Taller"` (p. ej. `ContratosController.cs`, `CotizadorController.cs`, `AsesoresController.cs`, `Areas/Averias/Controllers/AveriasController.cs`, `DistribuidoresController.cs`).
  - Enfoque recomendado: hacer un barrido (grep) de `Usuario Distribuidor` y de `"Taller"` en atributos `[Authorize]` y añadir el rol combinado en cada coincidencia pertinente.
  - Criterio de completitud: el usuario combinado accede a toda acción a la que accede Distribuidor o Taller, y a ninguna fuera de esa unión (RNF-01).



### Fase 4 — Aislamiento de datos (filtrado combinado)

- [x] **T-11 — Helper de grupos de rol (código nuevo)**
  - Crear un helper/extension (p. ej. `Helpers/RoleGroupExtensions.cs`) con métodos como `ActsAsDistribuidor(ClaimsPrincipal)` → true para `"Usuario Distribuidor"` **y** el combinado, y `ActsAsTaller(ClaimsPrincipal)` → true para `"Taller"` **y** el combinado. Código nuevo en inglés (`coding-guidelines.md`).
  - Objetivo: centralizar la semántica del rol combinado y mitigar la desincronización futura (RNF-04, riesgo "divergencia de permisos").
  - Criterio de completitud: helper con pruebas mínimas; disponible para T-12/T-13/T-14.

- [x] **T-12 — Resolución de proyectos combinada**
  - `GarantiplusWeb/Controllers/GeneralController.cs` (95/102 y 155/162): hoy `if (Usuario Distribuidor) {proyectos vía usuario_distribuidor} else if (Taller) {proyectos vía usuario_taller.proyecto_taller}`. Convertir a **aditivo** para el combinado: unir los proyectos derivados de sus distribuidores **y** de su taller.
  - Criterio de completitud: el usuario combinado resuelve el conjunto unión de proyectos de sus distribuidores y su taller.

- [x] **T-13 — Filtrado en Averías e i18n**
  - `Areas/Averias/Controllers/AveriasController.cs` (bloques 99/103, 156/160, 214/218, 296/300, 435/461, 609/626, etc.) y `JsonStringLocalizer.cs` (123/130): que el usuario combinado sea filtrado por sus `id_distribuidor` **y** por su `id_taller` (unión), no por una sola rama.
  - Usar el helper de T-11 y pasar correctamente los flags `bool` que las business rules esperan (p. ej. `GetAllAverias(..., idTaller, esTaller, ...)`).
  - Criterio de completitud: el usuario combinado ve las averías de sus distribuidores y de su taller; **no** ve las de distribuidores/talleres no ligados (RF-06).

- [x] **T-14 — Flags a business rules y otros consumidores**
  - Revisar llamadas que pasan `User.IsInRole("Usuario Distribuidor")` / `User.IsInRole("Taller")` como `bool` a capas de negocio (`ContratosController.cs:245`, `OrdenesPagoController.cs`, `ArmadorasBusinessRules`, `PaisesService/Classes/Pais*.cs`) y asegurar que el rol combinado active la rama correcta (idealmente vía helper T-11).
  - Criterio de completitud: los reportes y listados con filtro por distribuidor/taller respetan la unión para el rol combinado.



### Fase 5 — Pruebas y aceptación

- [x] **T-15 — Matriz de pruebas manual del rol combinado**
  - Alta con 1 distribuidor + 1 taller; alta con varios distribuidores + 1 taller; intento de guardar sin taller / sin distribuidor (debe bloquear).
  - Login del usuario combinado: menú = unión; acceso a acciones = unión; datos visibles = solo sus distribuidores y su taller.
  - Criterio de completitud: todos los casos pasan; sin fuga de datos entre entidades no ligadas.

- [x] **T-16 — Regresión de roles base**
  - Verificar que "Usuario Distribuidor" y "Taller" (y los demás) siguen operando idénticos (fuera de alcance modificarlos — PRD §6).
  - Criterio de completitud: sin cambios de comportamiento en los roles existentes.

---



## 5. Cambios en base de datos

No hay migraciones EF en el repo; los roles se siembran por **script SQL** (patrón `GarantiplusWeb/BD/`**).


| Tabla                  | Tipo de cambio        | Descripción                                                                                                 |
| ---------------------- | --------------------- | ----------------------------------------------------------------------------------------------------------- |
| `AspNetRoles`          | Nueva fila (seed)     | Rol `Usuario Distribuidor-Taller` con GUID fijo. Aplicar en BD de cada país liberado (MX; CO/CL si aplica). |
| `usuario_distribuidor` | Sin cambio de esquema | Se reutiliza para las N ligas del usuario combinado.                                                        |
| `usuario_taller`       | Sin cambio de esquema | Se reutiliza para la liga 1:1 del usuario combinado.                                                        |


> El seed debe ejecutarse manualmente en cada ambiente/BD (no hay pipeline de migraciones). Registrar la ejecución en dev, QA y producción.

---



## 6. Endpoints nuevos o modificados

No se crean endpoints REST nuevos. Se modifican acciones MVC existentes del catálogo de usuarios:


| Método | Ruta                                 | Descripción                                                | Estado             |
| ------ | ------------------------------------ | ---------------------------------------------------------- | ------------------ |
| POST   | `Catalogos/Usuarios/Create`          | Alta ligando distribuidores + taller para el rol combinado | Modificado         |
| POST   | `Catalogos/Usuarios/Edit`            | Edición de distribuidores + taller del rol combinado       | Modificado         |
| GET    | `Catalogos/Usuarios/Create` · `Edit` | Selector de rol + visibilidad de campos                    | Modificado         |
| POST   | `Catalogos/Usuarios/Talleres`        | Poblado del combo de taller (AJAX)                         | Revisar/Modificado |


---



## 7. Variables de entorno y configuración

No se requieren variables de entorno ni secrets nuevos. La selección de país sigue el mecanismo existente (`<CountryBase>` en `.csproj` + `Hub:HubBaseCountryCode`); ver skill `siga-cambio-pais-base`.

---



## 8. Consideraciones de seguridad

- **Aislamiento de datos (crítico):** el mayor riesgo es una fuga por filtrado incompleto. La Fase 4 es el punto sensible — cualquier bloque `if/else` de filtrado no cubierto haría que el usuario combinado vea de más o de menos. Verificación explícita en T-13/T-15.
- **Principio de mínimo privilegio (RNF-01):** el rol nunca debe exceder la unión Distribuidor ∪ Taller. La Fase 3 solo **agrega** el nombre del rol a listas existentes; no se crean permisos nuevos (PRD §6).
- **Sin secrets en código** (regla vigente); no aplica material sensible nuevo.
- No hay cambios de IAM/AWS.

---



## 9. Consideraciones de infraestructura

Ninguna. SIGA Web sigue en EC2 (Ubuntu + .NET 8 + Nginx). No hay nuevos servicios AWS, ECS, RDS ni S3, ni cambios de DNS/Cloudflare/Route 53.

---



## 10. Criterios de aceptación

- [x] El rol "Usuario Distribuidor-Taller" existe en `AspNetRoles` y es seleccionable al crear/editar usuarios (RF-01).
- [x] Al crear/editar, se pueden ligar uno o varios distribuidores (RF-02) y exactamente un taller (RF-03), con persistencia correcta en `usuario_distribuidor` y `usuario_taller`.
- [x] No se puede guardar sin ≥1 distribuidor y exactamente 1 taller (RF-07), con mensaje claro (RNF-03).
- [x] El usuario combinado ve en menú/acciones la **unión exacta** de opciones de Distribuidor y Taller, sin permisos extra (RF-04, RNF-01).
- [x] El usuario combinado solo accede a datos de sus distribuidores y su taller ligados; ninguna otra entidad (RF-06).
- [x] Los roles "Usuario Distribuidor" y "Taller" mantienen su comportamiento intacto (PRD §6).

---



## 11. Riesgos técnicos identificados


| Riesgo                                                                       | Probabilidad | Impacto  | Mitigación                                                                                              |
| ---------------------------------------------------------------------------- | ------------ | -------- | ------------------------------------------------------------------------------------------------------- |
| Puntos de permiso hardcodeados omitidos (menú/`[Authorize]`)                 | Alta         | Medio    | Barrido sistemático (grep) de `Usuario Distribuidor` y `Taller`; matriz de pruebas T-15.                |
| Fuga de datos por bloque de filtrado `if/else` no convertido a aditivo       | Media        | **Alto** | Centralizar en helper T-11; revisar todas las ocurrencias del reporte; prueba explícita de aislamiento. |
| Ramas excluyentes proyectos/distribuidores en Create/Edit                    | Media        | Medio    | T-06/T-07 ajustan el flujo; probar alta con distribuidores + taller a la vez.                           |
| GUID de rol distinto entre BD (MX/CO/CL) rompe los `is-visible` por GUID     | Media        | Medio    | Seed con **GUID fijo** idéntico en todas las BD (T-01/T-02).                                            |
| `ViewBag.Talleres` no poblado en `SetupViewBags`                             | Media        | Bajo     | Resolver en T-03 (poblar en servidor o vía AJAX del `_Edit`).                                           |
| Desincronización futura si cambian permisos de los roles base                | Media        | Medio    | Helper T-11 + nota de mantenibilidad (RNF-04); documentar los puntos de tacto.                          |
| Divergencia de modelos MX vs Colombia (`DataAccess` vs `DataAccessColombia`) | Baja         | Medio    | Aplicar cambios de datos en ambos si se libera CO/CL.                                                   |


---



## 12. Notas para el programador

- **Nombre real del rol taller = "Taller"** (no "Usuario Distribuidor**-Taller**" ni "Usuario Taller"). El rol de distribuidor sí es "Usuario Distribuidor". Tenlo presente en cada barrido.
- **Pregunta abierta del PRD §14 (nomenclatura):** confirma con el responsable el `Name`/`NormalizedName`/GUID definitivos antes de T-02 y T-04.
- **Regla anti-refactor:** las modificaciones a los bloques `if/else` de filtrado (Fase 4) son cambios **funcionales necesarios**, no refactor cosmético. Están acotados y encapsulados en el helper T-11. Aun así, valídalo: si prefieres no tocar esos bloques, el rol combinado **no** podrá aislar los datos de su taller (romper la unión).
- **Países:** confirma si la feature se libera solo en México o también Colombia/Chile. Si incluye CO/CL, hay que replicar el seed en esas BD y editar `_LeftMenuBar_COL.cshtml` / `_CHL.cshtml`, además de considerar `DataAccessColombia`.
- **No hay migraciones EF:** el alta del rol es un script SQL manual por ambiente. Coordina su ejecución en dev/QA/prod.
- **Fuera de alcance (PRD §6):** no modificar los roles base, no crear permisos nuevos, no migrar/fusionar usuarios existentes, no multi-taller.
- **Ticket:** ajusta el prefijo de la rama si el ID de ticket real difiere de `PJ4981` (la convención Engine usa `feature/ECX-XXX-...`).

---

*Generado por Claude Code — Engine CX*
*Basado en:* `rules/infraestructura.md`*,* `rules/coding-guidelines.md`*,* `rules/stack.md`*,* `rules/arquitectura.md`*,* `rules/version-control.md`