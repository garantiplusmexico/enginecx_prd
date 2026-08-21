# Plan de Desarrollo — Cierre de huecos del servicio de Issues (API SIGA)

> Generado por Claude Code a partir del PRD `PJ3173-issues-lectura-evidencia`.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ3173-issues-lectura-evidencia/PRD.md` |
| Repositorio | `gp_3.0_siga_api` (microservicio **Claims**) + repo hermano `gp_4.0_siga` (`DataAccess`, `DataAccessColombia`) |
| Rama base | `develop` (verificada y actualizada el 21-ago-2026) |
| Rama funcional | `feature/PJ3173-issues-lectura-evidencia` |
| Tipo | Feature sobre proyecto existente |
| Responsable | Javier Antonio Oropeza Camacho |
| Folio PRD | PJ3173 |
| Fecha de generación | 2026-08-21 |
| Estado | Borrador |
| ID plan (BD) | 54 |
| Modelo | `claude-opus-5` — esfuerzo: alto |

---

## 1. Resumen técnico

Se completan las cinco peticiones del PRD **dentro del microservicio `Services/Claims`** de la API de SIGA. No
se crean servicios nuevos, no se cambia la arquitectura y no se toca infraestructura: todo es superficie de
lectura y validación sobre estructuras que ya existen.

**Qué se crea**
- 4 endpoints nuevos en `IssuesController`: listado OData de documentos, listado por incidencia, descarga de
  binario y catálogo de estatus.
- 1 endpoint nuevo en `ClaimsController`: seguimiento (observaciones) de una avería.
- 2 tablas nuevas: `estatus_incidencia` (catálogo) y `seguimiento_incidencia` (anotaciones), espejo de
  `estatus_averia` y `seguimiento_averia`.
- 3 particiones nuevas de `IssuesService` (`.Documents.cs`, `.Notes.cs`, `.Status.cs`) — la clase ya es
  `partial` y las guidelines piden dividir por encima de ~200 líneas.
- La carpeta `Services/Claims/doc/` — **hoy no existe** en este microservicio, y este proyecto genera
  exactamente el tipo de conocimiento que `CLAUDE.md` obliga a documentar (reglas de permisos descubiertas
  probando, alternativas obvias descartadas, comportamiento del gateway).

**Qué se modifica**
- `UpdateIssue`: validación de estatus contra catálogo + escritura de anotación estructurada + anotación
  automática de transición.
- `GetIssueById`: devuelve la colección de anotaciones filtrada por visibilidad.
- DTOs de Issues: fechas con zona horaria, misma forma en POST y GET.

**Stack** (sin cambios, se respeta el proyecto existente): .NET 8 / C#, EF Core + Npgsql sobre PostgreSQL
(RDS), S3 vía `IStorage`, JWT Bearer, OData, Serilog + `LogsMonitorClient`, despliegue ECS + Fargate.

### 1.1 Hallazgos del análisis de código que cambian el plan respecto al PRD

Tres cosas se verificaron contra el código antes de estimar. Las dos primeras **cierran preguntas abiertas
del PRD §14**; la tercera abarata una fase.

**a) La pregunta bloqueante de permisos ya está respondida en el código — y la respuesta es la contraria a
la que temía el PRD.** En `Services/Claims/Program.cs:235-236`:

```csharp
options.AddPolicy(Policies.ICanManageIssues, policy =>
    policy.RequireRole(Policies.IsGeneralAdmin));
```

`ICanManageIssues` exige **únicamente el rol "Administrador General"**. Consecuencias:

1. El riesgo del PRD ("el técnico recibiría 403 por la regla espejo del upload") **no existe tal como se
   planteó**: nadie que no sea Administrador General llega siquiera al cuerpo del método, porque el gate del
   controlador se aplica antes. Si el panel opera hoy sobre Issues, lo hace con una cuenta Administrador
   General — y esa cuenta pasa la regla interna del upload sin problema.
2. La regla interna de `UploadIssueDocument` (admin general / admin externo / gerente de país / taller /
   `registrada_por`) es hoy, en la práctica, **inalcanzable más allá de su primera condición**. No es un bug:
   es defensa en profundidad para cuando la policy se amplíe.
3. Por eso la lectura de evidencia se implementa con **exactamente la misma forma** (policy
   `ICanManageIssues` + regla interna idéntica a la del upload). Así se cumple RNF-01 ("el criterio de
   lectura no puede ser más laxo que el de escritura") por construcción, y el día que se amplíe la policy
   ambas superficies se mueven juntas.

Queda una verificación real, no de código (T-02): confirmar con qué rol llama el panel de Ana. Si el panel
usa una cuenta que **no** es Administrador General, el problema no es la lectura de evidencia — es que hoy
no puede llamar a ningún endpoint de Issues, y eso se arregla ampliando la policy, no el endpoint nuevo.

**b) El catálogo de estatus se materializa como tabla, pero SIN llave foránea desde `incidencia`.** El PRD
deja la decisión abierta. Se recomienda tabla + validación en la API porque:
- La tabla es necesaria de todos modos: `seguimiento_incidencia` es espejo de `seguimiento_averia`, que
  guarda `id_estatus_anterior` / `id_estatus` como enteros. Sin catálogo materializado, esos campos no
  tienen a qué apuntar y la anotación de transición pierde sentido.
- La FK sobre `incidencia.estatus` obligaría a cambiar la columna de `VARCHAR(80)` a entero, migrar las
  filas existentes (incluida la de QA que dice `"En revisiónnnnn"`) y romper el contrato `status` por
  nombre — que el PRD §6 declara **explícitamente fuera de alcance** ("se mantiene el envío por nombre para
  no romper a los dos consumidores en vivo").
- Validar por nombre normalizado y persistir la forma canónica del catálogo entrega RF-06, RF-07 y RF-08 sin
  tocar el esquema de `incidencia` ni el contrato.

**c) La mitad de la Fase 1 ya está construida.** `documento_incidencia` existe como entidad y mapeo en
`DataAccess/IncidenciasExtensions/garantiplus_dbContext.cs`, `UploadIssueDocument` ya escribe metadatos y
sube el binario a S3 bajo `documentos/incidencias/{id}/`, y `DownloadClaimDocument` ya resuelve el patrón
completo de descarga (permisos → `_s3Storage.DownloadFileAsync(uri.TrimStart('/'))` → `Content-Type`). La
Fase 1 es espejar, no inventar. El bucket es el mismo (`bucket_api_siga` / `qa-gpmx-siga-files`), así que
**no se requiere ningún permiso IAM nuevo**.

---

## 2. Prerequisitos

- [x] PRD validado y presente en `enginecx_prd/SIGA/PJ3173-issues-lectura-evidencia/PRD.md`
- [x] `CLAUDE.md` presente en el repositorio
- [x] Acceso a `gp_3.0_siga_api` y al repo hermano `gp_4.0_siga` (`DataAccess`, `DataAccessColombia`)
- [x] Rama `develop` existe y está actualizada
- [ ] **Respuesta a T-02**: rol real con que el panel de Ana llama a los endpoints de Issues (bloquea el
      cierre de la Fase 1, no su implementación)
- [ ] **Confirmación de JC a las 3 decisiones de diseño** de §1.1(b), §12.1 y §12.2 (catálogo sin FK, casing
      declarado no normalizado, fechas por mapeo no por migración de columna)
- [ ] Acceso de escritura DDL a la BD de QA (MEX) para aplicar los scripts de las Fases 1 y 2
- [ ] Batería de sondas de solo lectura del equipo del agente (Pedro) disponible para verificar cada fase
- [ ] Para la Fase 4: URL del gateway de producción y cuenta de servicio del agente (dependencia de TI)

**No se requiere**: recursos AWS nuevos, secrets nuevos, permisos IAM nuevos, ni proyecto de tests (el repo
no tiene ninguno — ver RNF-15 y §11).

---

## 3. Arquitectura del cambio

Arquitectura aplicada: **microservicios en contenedores** — la que ya usa la API de SIGA
(`rules/arquitectura.md` §1). No hay decisión nueva que justificar: el cambio vive completo dentro del
contenedor `Claims` que ya está en ECS + Fargate.

```
Agente WhatsApp (Engine CX) ─┐
                             ├─→ API Gateway ─→ ECS/Fargate: Claims ─┬─→ RDS PostgreSQL
Panel web de incidencias  ───┘      (ALB)         IssuesController   │    incidencia
                                                  ClaimsController   │    documento_incidencia
                                                  IssuesService      │    estatus_incidencia      (nueva)
                                                  ClaimsService      │    seguimiento_incidencia  (nueva)
                                                                     │    seguimiento_averia
                                                                     │    tipo_documento
                                                                     └─→ S3 (solo lectura)
                                                                          documentos/incidencias/{id}/
```

**Aislamiento de espacios de ids (RF-03), a nivel de arquitectura.** Las dos superficies de documentos
nunca se cruzan porque leen tablas distintas y viven en controladores distintos:

| Superficie | Tabla | Prefijo S3 | Controlador |
|---|---|---|---|
| Documentos de avería | `documento_averia` | `documentos/averias/{claimId}/` | `ClaimsController` |
| Documentos de incidencia | `documento_incidencia` | `documentos/incidencias/{issueId}/` | `IssuesController` |

Ninguna consulta nueva hace `join` entre `documento_averia` e `incidencia`, ni al revés. `incidencia.id_averia`
se usa solo como enlace de trazabilidad de salida (para que el consumidor pueda llamar al claim aparte),
nunca como criterio para resolver documentos.

---

## 4. Tareas de desarrollo

### Fase 0 — Rama base y cierre de supuestos (prerequisito de P1)

- [ ] **T-01** — Crear la rama funcional desde `develop`
  - Comandos: `git checkout develop && git pull origin develop && git checkout -b feature/PJ3173-issues-lectura-evidencia && git push origin feature/PJ3173-issues-lectura-evidencia`
  - Criterio de completitud: la rama existe en `origin` y `git status` está limpio

- [ ] **T-02** — Verificar contra QA con qué rol llaman el panel y el agente a los endpoints de Issues
  - Archivos: ninguno (verificación empírica); el hallazgo se escribe en `Services/Claims/doc/`
  - Procedimiento: con el token del panel, llamar `GET claims/api/Issues/v1/GetIssues`. Un 403 significa que
    la cuenta no es Administrador General y el problema **precede** a este proyecto
  - Criterio de completitud: queda registrado el rol de la cuenta del panel y el de la cuenta del agente, y
    si alguno no es Administrador General, queda escrita la recomendación de ampliar `ICanManageIssues`
    (cambio de una línea en `Program.cs`, fuera del alcance de esta fase salvo que JC lo autorice)

- [ ] **T-03** — Confirmar con Juan Carlos las tres decisiones de diseño del plan
  - Decisiones: (1) catálogo `estatus_incidencia` como tabla sin FK desde `incidencia` — §1.1(b);
    (2) casing del gateway **declarado**, no normalizado — §12.1; (3) fechas resueltas fijando el `Kind` en
    el mapeo, sin migrar `fecha_registro` a `timestamptz` — §12.2
  - Criterio de completitud: las tres decisiones están confirmadas o corregidas por escrito. Si (1) cambia a
    "FK con migración de valores", la Fase 1 sube ~2 días y hay que agregar una tarea de migración de datos

### Fase 1 — Lectura de evidencia y estatus confiable (P1 · MVP · peticiones 1 y 3)

Sin dependencia de otros repositorios: se puede desplegar sola y desbloquea la pestaña de Evidencia.

- [ ] **T-04** — Script SQL del catálogo de estatus de incidencia
  - Archivos a crear: `gp_4.0_siga/GarantiplusWeb/BD/2026-08-XX_estatus_incidencia/estatus_incidencia.sql`
  - Contenido: `CREATE TABLE estatus_incidencia (id_estatus_incidencia INT4 PK, nombre_estatus VARCHAR(80)
    NOT NULL UNIQUE, cierra_incidencia BOOL NOT NULL DEFAULT false)`, seed de los 5 valores
    (`1 Registrada`, `2 En revisión`, `3 Información solicitada`, `4 Convertida a avería`, `5 Cerrada`, con
    `cierra_incidencia = true` en los dos últimos), `GRANT` a `acceso_garantiplus`. Encabezado con la misma
    forma del script existente `2026-07-17_incidencias/incidencias.sql`, incluida la nota de que aplica a las
    tres bases (MEX, COL, CHL) y que **en este proyecto solo se ejecuta en MEX**
  - Criterio de completitud: el script corre limpio en la BD local y en QA (MEX); `SELECT` devuelve las 5 filas

- [ ] **T-05** — Entidad y mapeo de `estatus_incidencia` en los dos contextos espejo
  - Archivos a crear: `gp_4.0_siga/DataAccess/Models/estatus_incidencia.cs` y su copia idéntica en
    `gp_4.0_siga/DataAccessColombia/Models/estatus_incidencia.cs`
  - Archivos a modificar: `gp_4.0_siga/DataAccess/IncidenciasExtensions/garantiplus_dbContext.cs` y su espejo
    en `DataAccessColombia/IncidenciasExtensions/` — agregar `DbSet` y configuración en
    `OnModelCreatingIncidencias`
  - Criterio de completitud: ambos contextos compilan y exponen `DbSet<estatus_incidencia>` con el mismo
    mapeo. **Regla de `CLAUDE.md`: todo modelo/`DbSet`/mapeo nuevo se replica igual en los dos contextos**,
    aunque la migración solo se aplique a México

- [ ] **T-06** — DTOs de lectura de documentos de incidencia
  - Archivos a crear: `Services/Claims/DTOs/Issues/Responses/IssueDocumentQueryResponse.cs`,
    `Services/Claims/DTOs/Issues/Responses/IssueStatusResponse.cs`
  - Campos de `IssueDocumentQueryResponse` (RF-01): `DocumentId`, `IssueId`, `DocumentType` (nombre resuelto
    desde `tipo_documento`), `OriginalFileName`, `Uri`, `MimeType`, `CreationDate`
  - `CreationDate` se declara **`DateTimeOffset`** desde el día uno: es un campo nuevo, cuesta cero hacerlo
    bien, y evita entregar en la Fase 1 un campo que la Fase 3 tendría que corregir (ver §12.2)
  - Criterio de completitud: los DTOs compilan, llevan XML docs con `<example>` y **no** exponen ningún campo
    de avería. `StatusId` de `ClaimDocumentQueryResponse` **no se replica**: `documento_incidencia` no tiene
    estatus de documento (supuesto explícito del PRD §13)

- [ ] **T-07** — Contrato de servicio: métodos de lectura en `IIssuesService`
  - Archivos a modificar: `Services/Claims/Interfaces/IIssuesService.cs`
  - Métodos: `IQueryable<IssueDocumentQueryResponse> GetIssueDocuments()`,
    `Task<IssueDocumentListResult> GetIssueDocumentsByIssueId(long issueId)`,
    `Task<(Stream? stream, string? fileName, string? contentType)?> DownloadIssueDocument(long documentId)`,
    `Task<IEnumerable<IssueStatusResponse>> GetIssueStatuses()`
  - Criterio de completitud: la interfaz compila con XML docs completos (API First: el contrato antes de la
    implementación)

- [ ] **T-08** — Implementación de la lectura de documentos
  - Archivos a crear: `Services/Claims/Services/IssuesService.Documents.cs` (partial nuevo; la clase ya es
    `partial` y `IssuesService.cs` está en 256 líneas)
  - Contenido:
    - Scoping por rol espejo de `GetIssues()`: admin ve todo; admin externo / gerente de país ven las
      incidencias de sus distribuidores vía `contrato → distribuidor → proyecto_usuario`; taller ve las que
      registró (`registrada_por == userEmail`)
    - Regla interna **idéntica** a la de `UploadIssueDocument` para el acceso a una incidencia concreta
      (RF-04, RNF-01)
    - Excluye siempre `incidencia.eliminada == true` (RF-05)
    - Resuelve el nombre del tipo con `join` a `tipo_documento` (solo lectura)
    - Descarga: `_s3Storage.DownloadFileAsync(document.uri.TrimStart('/'))`, espejo de
      `DownloadClaimDocument`, con `Content-Type` desde `documento_incidencia.mime_type` (registrado; no
      re-derivado de la extensión)
  - Criterio de completitud: las tres consultas leen **exclusivamente** `documento_incidencia`; ninguna
    referencia a `documento_averia` ni a `averia` en el archivo (verificable con `grep`)

- [ ] **T-09** — Resultados tipados y mapeo de errores de lectura
  - Archivos a modificar: `Services/Claims/Models/Issues/IssueResult.cs`,
    `Services/Claims/Services/IssueResultMapper.cs`
  - Contenido: enum `IssueDocumentReadStatus` (`Ok`, `Unauthorized`, `Forbidden`, `IssueNotFound`,
    `DocumentNotFound`), `IssueDocumentListResult`, y `MapDocumentRead(...)` con mensajes en español
    (RNF-05). Nota de seguridad: el mensaje de `DocumentNotFound` es genérico y **no** revela si el id
    existe en otro espacio de ids (RNF-01)
  - Criterio de completitud: cada caso del enum mapea a su código HTTP y su mensaje, sin `default` silencioso

- [ ] **T-10** — Endpoints de lectura de evidencia en `IssuesController`
  - Archivos a modificar: `Services/Claims/Controllers/IssuesController.cs`
  - Endpoints:
    - `GET v1/GetIssueDocuments` — `[AutoODataFilter]`, `[Authorize(Policy = Policies.ICanManageIssues)]`,
      `[EnableRateLimiting(RateLimitPolicyNames.OData)]` (RNF-10), espejo exacto de `GetClaimDocuments`
    - `GET v1/GetIssueDocumentsByIssueId/{issueId:long}` — devuelve **404** para incidencia inexistente o
      eliminada. Existe porque RF-05 pide 404 y una colección OData filtrada no puede devolver 404: para un
      `issueId` inexistente devolvería `[]`. El panel llama a esta; el agente y las listas usan la OData
    - `GET v1/DownloadIssueDocument/{documentId:long}` — `FileStreamResult` con el `Content-Type` real
  - Auditoría: `LogRequestAsync` de **3 argumentos** en los tres (son GET, sin body) — regla de `CLAUDE.md`
  - Criterio de completitud: los tres responden 200/403/404 según corresponde y aparecen en Swagger con sus
    `ProducesResponseType` completos y ejemplos OData con `&amp;` escapado

- [ ] **T-11** — Catálogo de estatus consultable
  - Archivos a modificar: `Services/Claims/Controllers/IssuesController.cs`,
    y crear `Services/Claims/Services/IssuesService.Status.cs`
  - Endpoint: `GET v1/GetIssueStatuses` → `[{ statusId, statusName, closesIssue }]` (RF-06), leído de la
    tabla, no de una constante en código
  - Criterio de completitud: devuelve las 5 filas del catálogo ordenadas por id

- [ ] **T-12** — Validación y normalización de estatus en `UpdateIssue`
  - Archivos a modificar: `Services/Claims/Services/IssuesService.cs` (método `UpdateIssue`),
    `Services/Claims/Services/IssuesService.Status.cs`, `Services/Claims/Services/IssueResultMapper.cs`,
    `Services/Claims/Controllers/IssuesController.cs`
  - Comportamiento:
    - Normaliza el `status` recibido sin distinguir mayúsculas ni acentos (`string.Normalize(NormalizationForm.FormD)`
      + descarte de marcas diacríticas) y lo resuelve contra el catálogo (RF-08)
    - Si no resuelve: **400** `{ errorCode = "INVALID_STATUS", message = "El estatus '<valor>' no es válido.
      Valores permitidos: …" }` y **no persiste nada del request** — la validación ocurre antes de aplicar
      `Description` y `Odometer` y antes de cualquier `SaveChangesAsync` (RF-07, es el punto fácil de romper)
    - Si resuelve: persiste la **forma canónica** del catálogo, no la cadena recibida
    - Registra el rechazo con el valor recibido y el usuario/cliente que lo envió, en nivel `Warning`
      (RNF-12), sin datos personales
  - Criterio de completitud: `PUT` con `"en revision"` persiste `"En revisión"` y devuelve 200; `PUT` con
    `"En revisiónnnnn"` devuelve 400 y una lectura posterior confirma que **ni la descripción ni el odómetro
    cambiaron**

- [ ] **T-13** — Carpeta `doc/` del microservicio Claims (no existe hoy) + entradas de la Fase 1
  - Archivos a crear: `Services/Claims/doc/README.md` (índice con el formato de
    `Services/Authentication/doc/README.md`), más:
    - `incidencias-quien-puede-leer-la-evidencia.md` — la regla, el hallazgo de que `ICanManageIssues` hoy es
      solo Administrador General, y por qué la lectura no puede ser más laxa que la escritura
    - `incidencias-ids-no-se-cruzan-con-averias.md` — por qué está prohibido filtrar `documento_averia` por
      `issueId`, con el caso real de los PDFs de taller de un claim de 2020
    - `incidencias-estatus-validado-por-nombre.md` — por qué catálogo sin FK y por qué se descartó `statusId`
  - Criterio de completitud: el `README.md` indexa las tres entradas y cada una tiene regla en una frase,
    tabla de ejemplos que pasan y que no pasan, el escenario que evita, y dónde vive en el código

- [ ] **T-14** — Verificación empírica de la Fase 1 contra QA
  - Archivos: ninguno (se anexa la evidencia al `AVANCE.md`)
  - Procedimiento: subir una foto conocida a un issue de QA, listarla por `issueId`, descargarla y comparar
    bytes con el original (RF-19). Probar un `documentId` que exista también en `documento_averia` y
    confirmar que devuelve el de incidencia o 404, nunca el de avería (RF-03). Correr la batería de sondas
    de Pedro
  - Criterio de completitud: paridad de bytes confirmada, aislamiento de ids confirmado, sondas en verde, y
    Ana confirma que la pestaña de Evidencia del panel ya muestra contenido

### Fase 2 — Anotaciones de incidencia (P2 · petición 2)

**Requiere despliegue coordinado** con el panel (Ana) y el agente (Pedro). El riesgo aquí no es técnico: es
que durante la ventana de migración el cliente se quede sin narración en WhatsApp.

- [ ] **T-15** — Script SQL de `seguimiento_incidencia`
  - Archivos a crear: `gp_4.0_siga/GarantiplusWeb/BD/2026-08-XX_seguimiento_incidencia/seguimiento_incidencia.sql`
  - Contenido: `id_seguimiento_incidencia BIGSERIAL PK`, `id_incidencia INT8 NOT NULL FK → incidencia`,
    `fecha TIMESTAMP NOT NULL DEFAULT now()`, `usuario VARCHAR(200) NOT NULL`, `observaciones VARCHAR(2000)`,
    `id_estatus_anterior INT4 NULL FK → estatus_incidencia`, `id_estatus INT4 NULL FK → estatus_incidencia`,
    `tipo VARCHAR(40) NOT NULL`, `publico BOOL NOT NULL DEFAULT false`, índice por `id_incidencia`, `GRANT`s
  - `id_estatus_anterior` es **nullable** a propósito: las filas históricas cuyo estatus está fuera de
    catálogo (`"En revisiónnnnn"`) no tienen id al que apuntar; en ese caso el valor crudo se preserva en
    `observaciones`
  - Migración **aditiva**: crea una tabla nueva, no altera `incidencia` (RNF-08)
  - Criterio de completitud: corre limpio en local y QA (MEX)

- [ ] **T-16** — Entidad y mapeo de `seguimiento_incidencia` en los dos contextos espejo
  - Archivos a crear: `gp_4.0_siga/DataAccess/Models/seguimiento_incidencia.cs` + copia idéntica en
    `DataAccessColombia/Models/`
  - Archivos a modificar: `IncidenciasExtensions/garantiplus_dbContext.cs` en ambos contextos (`DbSet` +
    configuración + navegación `incidencia.seguimiento_incidencia`)
  - Criterio de completitud: ambos contextos compilan con el mismo mapeo

- [ ] **T-17** — DTOs de anotaciones
  - Archivos a crear: `Services/Claims/DTOs/Issues/Responses/IssueNoteResponse.cs`
    (`NoteId`, `Text`, `Author`, `Date` como `DateTimeOffset`, `NoteType`, `IsPublic`,
    `PreviousStatus`, `NewStatus`)
  - Archivos a modificar: `Services/Claims/DTOs/Issues/UpdateIssueRequest.cs` — agregar `NoteText`
    (`MaxLength(2000)`), `NoteType`, `IsPublic` (bool?, **default `false` si no viene**: una nota no se
    vuelve narrable al cliente por omisión)
  - Los campos nuevos son **aditivos**: un `PUT` con el body de hoy sigue funcionando igual (RNF-06)
  - Criterio de completitud: los DTOs compilan con XML docs y ejemplos

- [ ] **T-18** — Implementación de anotaciones
  - Archivos a crear: `Services/Claims/Services/IssuesService.Notes.cs`
  - Contenido:
    - Escribir anotación estructurada desde `UpdateIssue` (texto + tipo + visibilidad), **sin tocar
      `descripcion`** (RF-10, RF-14)
    - Anotación automática en todo cambio de estatus, con estatus anterior, nuevo, usuario del token y fecha
      del servidor, incluso cuando el request no traiga comentario (RF-11, RNF-04). Tipo
      `Cambio de estatus`, `publico = false` por defecto — la bitácora técnica no se le narra al cliente
    - Lectura de anotaciones de un issue, ordenables por fecha y **filtradas por visibilidad** según el rol
      del solicitante (RF-13)
  - La escritura de la anotación y la actualización del issue van en **una sola** `SaveChangesAsync` para que
    no exista un estado con estatus cambiado y sin bitácora
  - Criterio de completitud: un `PUT` que cambia estatus genera exactamente una anotación de transición; un
    `PUT` con `noteText` genera además la nota del técnico; `descripcion` queda intacta en los dos casos

- [ ] **T-19** — `GetIssueById` devuelve las anotaciones
  - Archivos a modificar: `Services/Claims/DTOs/Issues/IssueResponse.cs` (agregar
    `IEnumerable<IssueNoteResponse>? Notes`), `Services/Claims/Services/IssuesService.cs`
  - **`GetIssues` (OData) NO devuelve anotaciones** — decisión de rendimiento: es la consulta que alimenta la
    lista del panel y una colección anidada por fila la degrada (RNF-09, cierra una pregunta abierta del PRD
    §14). `MapToResponse` (proyección de colección) queda sin `Notes`; solo el camino de get-by-id las carga
  - Criterio de completitud: `GetIssueById` trae las anotaciones visibles ordenadas por fecha descendente;
    `GetIssues` responde en tiempos equivalentes a los de hoy

- [ ] **T-20** — Convivencia de formatos durante la ventana de migración (RF-15, RNF-07)
  - Archivos a crear: `Services/Claims/Options/IssueLegacyNotesOptions.cs`
  - Archivos a modificar: `Services/Claims/appsettings.json` (+ `appsettings.{env}.json`),
    `Services/Claims/Program.cs` (binding `IOptions<T>`), `Services/Claims/Services/IssuesService.Notes.cs`
  - Comportamiento: con `Issues:LegacyClosureLine:Enabled = true`, al crear una anotación pública de cierre o
    de información solicitada la API **también** anexa la línea entre corchetes a `descripcion` usando el
    formato configurado. Así el agente sin migrar sigue narrando y el orden de despliegue deja de importar.
    Con el flag en `false` (después de que Ana y Pedro migren), `descripcion` queda limpia
  - **Nada hardcodeado**: el formato de la línea vive en `appsettings`, no en el código (regla de `CLAUDE.md`)
  - Criterio de completitud: con el flag encendido, un cierre produce anotación **y** línea entre corchetes;
    apagado, solo anotación. Cambiar el flag no requiere recompilar

- [ ] **T-21** — Entradas de `doc/` de la Fase 2
  - Archivos a crear: `Services/Claims/doc/incidencias-visibilidad-de-anotaciones.md`,
    `Services/Claims/doc/incidencias-ventana-de-convivencia-del-motivo-de-cierre.md`
  - La segunda debe explicar el flag, por qué existe, y **cuándo apagarlo** — es deuda deliberada con fecha
    de caducidad; si no queda escrito, se queda encendido para siempre
  - La primera documenta por qué **no** se replicó `solo_agencia` de `seguimiento_averia`: esa bandera
    modela el reparto agencia/taller de las averías, que las incidencias no tienen; una segunda dimensión de
    visibilidad sin caso de uso multiplica la matriz de filtrado y el riesgo de filtrar una nota interna
    (cierra una pregunta abierta del PRD §14)
  - Criterio de completitud: ambas indexadas en el `README.md` de `doc/`

- [ ] **T-22** — Ventana de despliegue coordinado
  - Archivos: ninguno (coordinación)
  - Procedimiento: validar en QA con Pedro → avisar a Ana con fecha y hora de corte → desplegar API con el
    flag **encendido** → Ana migra el panel a escribir anotaciones → Pedro migra el agente a leerlas →
    confirmar que ambos migraron → apagar el flag
  - Criterio de completitud: cero incidentes de narración rota durante la ventana; el flag queda apagado y
    `descripcion` de las incidencias nuevas no contiene líneas administrativas

### Fase 3 — Observaciones de avería y normalización del gateway (P3 · peticiones 4 y 5)

Prioridad baja: nada bloquea, pero saca de circulación el folclore oral.

- [ ] **T-23** — Observaciones de la avería con fecha, hora y autor
  - Archivos a crear: `Services/Claims/DTOs/Claims/Responses/ClaimObservationResponse.cs`
    (`ObservationId`, `ClaimId`, `Date` como `DateTimeOffset`, `Author`, `Observations`, `PreviousStatus`,
    `NewStatus`)
  - Archivos a modificar: `Services/Claims/Interfaces/IClaimsService.cs`,
    `Services/Claims/Services/ClaimsService.cs`, `Services/Claims/Controllers/ClaimsController.cs`
  - Endpoint: `GET claims/api/Claims/v1/GetClaimTracking/{claimId:long}`, leyendo `seguimiento_averia` y
    respetando `publico` y `solo_agencia` **ya existentes** (RF-16)
  - **Decisión (a confirmar con JC)**: endpoint dedicado en lugar de anidar la colección en `ClaimResponse`.
    El GET de claims es `GetClaims`, una proyección OData sobre `IQueryable`; anidarle una colección degrada
    la lista del panel para todos los consumidores y obliga a `$expand`, que no está configurado. El agente
    ya encadena una segunda consulta al claim, así que llamar a un endpoint dedicado no le agrega un viaje
  - Criterio de completitud: devuelve las observaciones ordenadas por fecha con autor y hora con zona; una
    observación con `publico = false` no aparece para un consumidor sin derecho a verla

- [ ] **T-24** — Fechas con zona en todo el servicio de Issues (RF-17)
  - Archivos a modificar: `Services/Claims/DTOs/Issues/IssueResponse.cs`,
    `Services/Claims/DTOs/Issues/CreateIssueResponse.cs`, `Services/Claims/Services/IssuesService.cs`,
    `Services/Claims/Services/IssuesService.Register.cs`
  - Solución: `DateTimeOffset` en los DTOs y `DateTime.SpecifyKind(valor, DateTimeKind.Utc)` al mapear desde
    la columna `TIMESTAMP` sin zona, de modo que el `201` de `CreateIssue` y el `GET` de `GetIssueById`
    devuelvan **la misma forma**. Ver §12.2 para por qué no se migra la columna aquí
  - Criterio de completitud: `POST CreateIssue` y `GET GetIssueById` devuelven `creationDate` con la misma
    forma y con zona; el agente puede retirar su segundo parser de fecha

- [ ] **T-25** — Casing de rutas y el 301 que descarta el `Authorization` (RF-18)
  - Archivos a crear: `Services/Claims/doc/gateway-casing-de-rutas-y-el-301.md`
  - Archivos a modificar: descripción del controlador en `Services/Claims/Controllers/IssuesController.cs`
    y el bloque de descripción de Swagger en `Program.cs`
  - Contenido: rutas de *claims* en minúsculas y de *Issues* Capitalizadas; la variante equivocada devuelve
    **301**, no 404; `HttpClient` de .NET **descarta el header `Authorization` al seguir un redirect**, por
    lo que el síntoma es un `401` inexplicable en una ruta que existe; los clientes deben correr con
    `AllowAutoRedirect = false`. Handoff a Pedro para `api-contract.md` (RNF-13)
  - **Decisión: se declara, no se normaliza.** Ver §12.1
  - Criterio de completitud: el documento existe, está indexado, y la advertencia del 301 aparece en Swagger

### Fase 4 — Habilitación a producción

No es código: es habilitación y validación. Depende de TI.

- [ ] **T-26** — Solicitar la URL del gateway de producción y la cuenta de servicio del agente
  - Archivos: ninguno
  - La cuenta de servicio necesita el rol que exige `ICanManageIssues` (hoy **Administrador General** — ver
    §1.1(a) y el hallazgo de T-02). Si esa amplitud de permisos no es aceptable para una cuenta de agente, la
    conversación correcta es acotar la policy, no ampliar la cuenta; queda como decisión de TI/JC
  - Criterio de completitud: URL y credenciales entregadas, con los permisos exactos documentados

- [ ] **T-27** — Aplicar los scripts de BD en producción (MEX)
  - Archivos: los de T-04 y T-15
  - Ambos son aditivos (crean tablas nuevas, no bloquean `incidencia`) — RNF-08
  - Criterio de completitud: las dos tablas existen en producción con sus `GRANT`s y el seed del catálogo

- [ ] **T-28** — Re-verificar en producción con la batería de sondas de solo lectura
  - Archivos: ninguno (resultados al `AVANCE.md`)
  - Verificar: casing de rutas, comportamiento del 301, forma de las fechas, paridad de bytes de la evidencia
  - Criterio de completitud: 100% de las sondas ejecutadas con éxito antes de declarar el corte (RF-20 y la
    métrica de cobertura del PRD §12)

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `estatus_incidencia` | **Nueva** (Fase 1) | Catálogo de los 5 estatus. `id_estatus_incidencia`, `nombre_estatus` (único), `cierra_incidencia`. Sin FK desde `incidencia` — ver §1.1(b) |
| `seguimiento_incidencia` | **Nueva** (Fase 2) | Anotaciones, espejo de `seguimiento_averia`. `id_seguimiento_incidencia`, `id_incidencia` (FK), `fecha`, `usuario`, `observaciones`, `id_estatus_anterior` (FK, nullable), `id_estatus` (FK, nullable), `tipo`, `publico` |
| `seguimiento_incidencia` | Índice | `idx_seguimiento_incidencia_incidencia` sobre `id_incidencia` — se consulta siempre por issue |
| `incidencia` | **Sin cambios** | No se altera la columna `estatus`, no se agrega FK, no se migra `fecha_registro`. Compatibilidad retroactiva (RNF-06) y migración no bloqueante (RNF-08) |
| `documento_incidencia` | **Sin cambios** | Ya existe y ya se llena. Este proyecto solo la lee |

**Réplica multi-país.** Los scripts contemplan las tres bases (MEX, COL, CHL) igual que el script original de
incidencias, pero **solo se ejecutan en MEX** en este proyecto (PRD §6). Las entidades y mapeos, en cambio,
**sí** se replican en `DataAccess` y `DataAccessColombia` desde el día uno, porque es regla del repositorio y
porque no hacerlo deja los contextos divergentes sin ganar nada. Chile no tiene contexto EF espejo en el repo
hermano: cuando el agente opere allá habrá que crearlo.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `claims/api/Issues/v1/GetIssueDocuments` | Listado OData de documentos de incidencia (RF-01) | **Nuevo** (F1) |
| GET | `claims/api/Issues/v1/GetIssueDocumentsByIssueId/{issueId}` | Documentos de una incidencia; 404 si no existe o está eliminada (RF-05) | **Nuevo** (F1) |
| GET | `claims/api/Issues/v1/DownloadIssueDocument/{documentId}` | Binario desde S3 con su `Content-Type` real (RF-02) | **Nuevo** (F1) |
| GET | `claims/api/Issues/v1/GetIssueStatuses` | Catálogo de los 5 estatus (RF-06) | **Nuevo** (F1) |
| PUT | `claims/api/Issues/v1/UpdateIssue/{id}` | Valida estatus contra catálogo (400 sin persistir) y acepta anotación estructurada | **Modificado** (F1 + F2) |
| GET | `claims/api/Issues/v1/GetIssueById/{id}` | Agrega la colección `notes` filtrada por visibilidad (RF-12/13) | **Modificado** (F2) |
| GET | `claims/api/Claims/v1/GetClaimTracking/{claimId}` | Observaciones de la avería con fecha, hora y autor (RF-16) | **Nuevo** (F3) |
| POST | `claims/api/Issues/v1/CreateIssue` | Solo cambia la forma de `creationDate` (con zona) — RF-17 | **Modificado** (F3) |

Todos con `[Authorize(Policy = Policies.ICanManageIssues)]`; los de colección con
`[EnableRateLimiting(RateLimitPolicyNames.OData)]` (RNF-10). Los GET registran auditoría con la sobrecarga de
**3 argumentos** de `LogRequestAsync`; el `PUT` con la de **4** (incluye `JsonSerializer.Serialize(request)`).

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `Issues:LegacyClosureLine:Enabled` | Enciende la convivencia de formatos de la Fase 2 (RF-15). `true` durante la ventana, `false` al cerrarla | Local / QA / Producción |
| `Issues:LegacyClosureLine:Format` | Plantilla de la línea entre corchetes (`[Cerrada por {user} el {date}: {reason}]`). Configurable, nunca hardcodeada | Local / QA / Producción |
| `FileStorage:Documentos_Incidencias` | Prefijo S3 `documentos/incidencias/` — **ya existe**, solo se lee | Todos |
| `FileStorage:BucketName` | Bucket `qa-gpmx-siga-files` (QA) — **ya existe**, mismo bucket que averías | Todos |

**Secrets nuevos: ninguno.** No se agregan credenciales ni claves. Nota aparte del alcance de este plan: el
`appsettings.json` versionado del servicio contiene la contraseña de BD, la `SecretKey` del JWT y el
`ClientSecret` de M365 en claro. Eso contradice `rules/infraestructura.md` §5 y las guidelines §11, pero es
código existente y **no se refactoriza sin petición explícita**; queda señalado para que alguien decida.

---

## 8. Consideraciones de seguridad

- **Datos personales del cliente final.** La evidencia son fotos y notas de voz de un cliente identificable
  (RNF-01). Tres defensas: la policy del controlador, la regla interna idéntica a la de escritura, y el
  aislamiento estricto de tablas.
- **El atajo prohibido.** Resolver documentos de incidencia filtrando `documento_averia` por `issueId`
  devuelve archivos de otro cliente — ya pasó en pruebas, con PDFs de taller de un claim de 2020. Es fuga de
  datos personales entre clientes, no un bug de listado. Se documenta en `doc/` y se verifica con un id
  presente en ambas secuencias (T-14).
- **No confirmar existencia por el código de error.** Un `documentId` que existe en el espacio de averías
  pero no en el de incidencias devuelve el mismo 404 genérico que un id inexistente.
- **Visibilidad de anotaciones.** `publico = false` por omisión. Una nota interna del técnico no puede llegar
  a WhatsApp por olvidar un campo; hay que pedirlo explícitamente.
- **Permisos IAM: sin cambios.** Mismo bucket que averías, cuyo `GetObject` ya funciona.
- **Autorización nunca por omisión** (RNF-02): todo endpoint nuevo lleva `[Authorize(Policy = …)]` explícito.
- **Auditoría** (RNF-03/04): `LoggingService` en cada llamada, y `seguimiento_incidencia` permite
  reconstruir la historia de una incidencia sin leer logs de aplicación.
- **Observabilidad de rechazos** (RNF-12): cada 400 por estatus inválido registra el valor recibido y quién
  lo envió, para identificar al consumidor que escribe mal — sin volcar datos personales.

---

## 9. Consideraciones de infraestructura

**Sin cambios de infraestructura.** No hay servicios AWS nuevos, ni cambios en ECS, RDS, S3, Cloudflare o
Route 53, ni costo incremental más allá del tráfico de descarga de la evidencia (imágenes de ~1-3 MB
consultadas por un técnico antes de decidir: irrelevante frente al tráfico actual del servicio).

- **Despliegue**: reconstrucción del contenedor de `Claims` y actualización del servicio ECS/Fargate, igual
  que cualquier release. Sin interrupción perceptible (RNF-08).
- **Orden en cada fase**: primero el script SQL (aditivo), después el contenedor. Como las tablas son nuevas
  y el código las lee pero no las requiere para los flujos existentes, el orden inverso tampoco rompe nada.
- **Rollback**: volver a la imagen anterior. Las tablas nuevas quedan huérfanas sin efecto sobre lo existente.
- **Gateway**: sin cambios de configuración, precisamente porque el casing se declara en lugar de
  normalizarse (§12.1).

---

## 10. Criterios de aceptación

**Fase 1 (P1 — guardarraíl del PRD)**
- [ ] Una foto subida a un issue de QA se lista por `issueId` y se descarga con los **mismos bytes** que el
      original (RF-19)
- [ ] `DownloadIssueDocument` devuelve el `Content-Type` registrado en `mime_type` (RF-02)
- [ ] Un `documentId`/`issueId` que existe también en el espacio de averías nunca devuelve datos de avería
      (RF-03), verificado con un id real presente en ambas secuencias
- [ ] Una incidencia con `eliminada = true` no expone sus documentos y devuelve 404 (RF-05)
- [ ] Un usuario sin los atributos de la regla espejo recibe 403, no una lista vacía (RF-04)
- [ ] `GET GetIssueStatuses` devuelve los 5 valores del catálogo (RF-06)
- [ ] `PUT UpdateIssue` con estatus fuera de catálogo devuelve 400 y **ni el estatus ni la descripción ni el
      odómetro del mismo request quedan persistidos** (RF-07)
- [ ] `PUT UpdateIssue` con `"en revision"` (sin acento ni mayúscula) persiste `"En revisión"` (RF-08)
- [ ] Ana confirma que la pestaña de Evidencia del panel muestra contenido (métrica del PRD §12)

**Fase 2 (P2)**
- [ ] `seguimiento_incidencia` existe con la forma espejo de `seguimiento_averia` (RF-09)
- [ ] `UpdateIssue` persiste el motivo como anotación estructurada **sin tocar `descripcion`** (RF-10, RF-14)
- [ ] Todo cambio de estatus deja su anotación con estatus anterior, nuevo, usuario y fecha, incluso sin
      comentario en el request (RF-11)
- [ ] `GetIssueById` devuelve las anotaciones con texto, autor, fecha con zona, tipo y visibilidad, ordenables
      (RF-12)
- [ ] Una anotación no pública no se devuelve a quien no tiene derecho a verla (RF-13)
- [ ] Con el flag de convivencia encendido, un cierre produce anotación **y** línea entre corchetes; apagado,
      solo anotación (RF-15)
- [ ] La ventana de corte se cierra con **cero** incidentes de narración rota (métrica del PRD §12)

**Fase 3 (P3)**
- [ ] El seguimiento de la avería devuelve fecha, hora con zona y autor, ordenable, respetando `publico` y
      `solo_agencia` (RF-16)
- [ ] `creationDate` tiene la misma forma y lleva zona en el `201` del POST y en el GET (RF-17)
- [ ] El casing y el 301 que descarta el `Authorization` están declarados en `doc/` y en Swagger (RF-18)

**Fase 4**
- [ ] URL del gateway de producción y cuenta de servicio entregadas, con permisos documentados (RF-20)
- [ ] Las dos tablas existen en producción con `GRANT`s y seed
- [ ] 100% de la batería de sondas ejecutada con éxito contra producción antes de declarar el corte

**Transversales**
- [ ] Los 4 parches del lado del consumidor quedan retirables: 2 parsers de línea entre corchetes, el doble
      parser de fecha y la contaminación de `descripcion` (métrica "Parsers eliminados: 4 de 4")
- [ ] Todo endpoint nuevo documentado en Swagger/Scalar con sus códigos de respuesta (RNF-13)
- [ ] Entidades y mapeos nuevos replicados en `DataAccess` **y** `DataAccessColombia`
- [ ] `Services/Claims/doc/` existe, con su `README.md` indexando las 6 entradas
- [ ] Ningún archivo nuevo supera ~200 líneas; los servicios se dividieron en `partial`

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| El panel llama a Issues con una cuenta que no es Administrador General | Media | Alto | T-02 lo verifica **antes** de implementar. Si ocurre, el arreglo es ampliar `ICanManageIssues` (una línea), no rediseñar los endpoints. El PRD lo planteó como riesgo de la regla interna; el código muestra que el gate real está antes |
| La ventana de la Fase 2 deja al cliente sin narración | Media | Alto | El flag de convivencia (T-20) elimina la dependencia del orden de despliegue. Sin él, este riesgo es el más caro del proyecto |
| El flag de convivencia se queda encendido para siempre | **Alta** | Medio | Es deuda con fecha de caducidad. T-21 documenta cuándo apagarlo y T-22 lo incluye como paso explícito de la ventana. Si no queda escrito, en seis meses nadie recuerda por qué la descripción sigue contaminada |
| Colisión de espacios de ids en una implementación descuidada | Baja | **Muy alto** (fuga de datos entre clientes) | Tablas separadas por diseño (§3), `grep` sin referencias cruzadas como criterio de T-08, prueba con un id presente en ambas secuencias (T-14), y entrada dedicada en `doc/` |
| Un `SaveChangesAsync` temprano hace que un 400 por estatus inválido persista la descripción | Media | Medio | Criterio explícito de T-12: validar antes de aplicar cualquier campo. Es el error natural al insertar la validación en un método que ya asigna y guarda |
| Estatus cambiado sin su anotación de bitácora | Media | Medio | Una sola `SaveChangesAsync` para el issue y su anotación (T-18) |
| `GetIssues` se degrada al agregar anotaciones | Media | Medio | Decisión de T-19: las anotaciones solo viajan en `GetIssueById`. Cierra la pregunta abierta del PRD §14 |
| Ruido de anotaciones automáticas en incidencias muy trabajadas | Media | Bajo | `tipo` + `publico = false` en las de transición: el agente narra solo lo público, el panel ve la bitácora completa |
| `fecha_registro` sigue siendo `TIMESTAMP` sin zona en la base | **Alta** (por diseño) | Bajo | Se resuelve en el mapeo, no en el esquema (§12.2). La ambigüedad queda en la base y documentada; migrar a `timestamptz` es un proyecto aparte que toca a todos los consumidores de la columna |
| **No hay proyectos de test en el repositorio** | Certeza | Medio | Toda la verificación es empírica contra QA con la batería de sondas de Pedro (RNF-15). Un cambio en la validación de estatus o en los permisos de lectura puede regresar sin que nada lo detecte. Si se quieren pruebas automatizadas, es trabajo adicional a estimar — no está en estos rangos |
| Producción no se comporta como QA | Media | Alto | Fase 4 completa es precisamente esa mitigación |
| Divergencia con Colombia y Chile | Alta | Medio | Entidades y mapeos se replican desde el día uno; solo el script queda sin aplicar. Chile además no tiene contexto EF espejo todavía |
| Un merge desde `qa`/`main` resucita copias viejas de los servicios de landing y rompe el build | Media | Bajo | El target `GuardStrayLandingServices` de `Contracts.csproj` falla temprano con mensaje accionable (gotcha de `CLAUDE.md`) |

---

## 12. Notas para el programador

### 12.1 Casing del gateway: se declara, no se normaliza

El PRD deja la decisión abierta. La recomendación es **declararlo** porque normalizarlo requiere inventariar
los consumidores actuales del gateway, y ese inventario **no existe** (riesgo y pregunta abierta del propio
PRD). Cambiar el casing sin inventario rompe silenciosamente a cualquier cliente no inventariado, y el
síntoma que verá será un `401` inexplicable — el peor error posible de diagnosticar. Declararlo cuesta un
documento y entrega el mismo valor operativo: el conocimiento deja de ser oral. Si JC quiere normalizarlo, el
prerequisito es el inventario, y eso es un proyecto aparte.

### 12.2 Fechas: se fija el `Kind` en el mapeo, no se migra la columna

`incidencia.fecha_registro` es `TIMESTAMP` sin zona. Migrarla a `timestamptz` es lo correcto en abstracto,
pero: (a) toca a todo consumidor que hoy lee la columna, dentro y fuera de este repo; (b) aplicada solo en
MEX agrava la divergencia de esquemas con COL y CHL, que ya es un riesgo del PRD; (c) RF-17 pide que **las
fechas que devuelve el servicio de Issues** tengan zona y la misma forma — un requisito de superficie de API,
que el mapeo satisface por completo. La ambigüedad queda en la base y **documentada**, no resuelta. Es deuda
consciente, no un descuido; si se decide migrar, es su propio proyecto con su propia ventana.

### 12.3 Estructura de carpetas de los DTOs nuevos

Las guidelines piden `DTOs/{Feature}/{Requests,Responses}/`. Los DTOs de Issues y Claims existentes están
planos en `DTOs/Issues/` y `DTOs/Claims/`; `DTOs/Workshops/` sí usa las subcarpetas. Los archivos **nuevos**
van en `Responses/` (guideline para código nuevo) y los existentes **no se mueven** (no se refactoriza sin
petición). Eso deja `DTOs/Issues/` mixto durante un tiempo. Si prefieres consistencia dentro de la carpeta
por encima de la guideline, dilo antes de T-06 y los pongo planos: es una decisión de dos minutos ahora y una
molestia de media hora después.

### 12.4 Lo que este plan NO hace

Fuera de alcance por decisión del PRD, no por olvido: migrar la evidencia a la avería en `ConvertToClaim`;
backfill de los motivos históricos que hoy viven entre corchetes en `descripcion`; una `v2` de `UpdateIssue`
que reciba `statusId`; aplicar la migración en Colombia y Chile; eventos para BI; pruebas automatizadas;
retirar la tolerancia del agente ante estatus desconocidos (se queda como red de seguridad por decisión del
equipo del agente); y la pantalla de evidencia dentro de `GarantiplusWeb` (la interfaz es del panel de Ana).

### 12.5 Preguntas abiertas del PRD que este plan cierra

| Pregunta del PRD §14 | Respuesta del plan |
|---|---|
| ¿Qué rol tiene el técnico que revisa? (bloqueante) | El gate real es `ICanManageIssues` = solo Administrador General. El riesgo planteado no aplica tal cual; T-02 lo confirma empíricamente — §1.1(a) |
| ¿Catálogo como tabla con FK o validación en la API? | Tabla **sin** FK desde `incidencia`, validación y normalización en la API — §1.1(b) |
| ¿Qué se hace con las filas de QA fuera de catálogo? | Se dejan como están (datos de prueba). Sin FK no bloquean nada; queda documentado |
| ¿Anotaciones también en el listado OData `GetIssues`? | No — solo en `GetIssueById`, por rendimiento de la lista del panel (T-19) |
| ¿Se replica `solo_agencia` además de `publico`? | No. Una sola dimensión de visibilidad; el por qué se documenta en `doc/` (T-21) |
| ¿Se migra `fecha_registro` a `timestamptz`? | No en este proyecto: se fija el `Kind` en el mapeo — §12.2 |
| ¿El casing se normaliza o se declara? | Se declara — §12.1 |
| ¿Backfill de los motivos históricos? | No (fuera de alcance del PRD). Requeriría parsear en producción justo el formato que se quiere retirar |

Siguen abiertas y **son de JC / TI, no de desarrollo**: si `ConvertToClaim` debe migrar la evidencia; cuándo
y quién dispara la réplica a Colombia y Chile; si se agregan pruebas automatizadas; quién actualiza
`api-contract.md`; y los permisos exactos de la cuenta de servicio del agente en producción.

---

## 13. Relación de tareas y tiempos

Estimación en **días hábiles** para **un** desarrollador, incluyendo la verificación empírica contra QA de
cada fase (que en este proyecto no es opcional: es el único mecanismo de prueba que hay).

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama base y cierre de supuestos** | Rama funcional, verificación del rol real del panel y del agente en QA, confirmación de las 3 decisiones de diseño con JC | T-01 a T-03 | 0.5 – 1 día | 181 |
| **Fase 1 — Lectura de evidencia y estatus confiable (P1)** | Tabla `estatus_incidencia` + entidades espejo, 4 endpoints nuevos, validación y normalización de estatus en `UpdateIssue`, carpeta `doc/` con 3 entradas, verificación de paridad de bytes y de aislamiento de ids | T-04 a T-14 | 4 – 6 días | 182 |
| **Fase 2 — Anotaciones de incidencia (P2)** | Tabla `seguimiento_incidencia` + entidades espejo, anotación estructurada y automática de transición, `notes` en `GetIssueById`, flag de convivencia de formatos, 2 entradas de `doc/`, ventana de despliegue coordinado con Ana y Pedro | T-15 a T-22 | 4 – 6 días | 183 |
| **Fase 3 — Observaciones de avería y gateway (P3)** | Endpoint de seguimiento de la avería, fechas con zona en todo el servicio de Issues, declaración del casing y del 301 | T-23 a T-25 | 2 – 3 días | 184 |
| **Fase 4 — Habilitación a producción** | URL del gateway y cuenta de servicio, scripts en producción, batería de sondas contra producción | T-26 a T-28 | 1 – 2 días de trabajo propio | 185 |
| **Total proyecto (P1+P2+P3+F4)** | | **28 tareas** | **~12 – 18 días hábiles** (≈ 2.5 – 3.5 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-14 | **~4.5 – 7 días hábiles** (≈ 1 – 1.5 semanas) | — |

**Notas sobre los rangos**
- El extremo bajo asume que T-02 confirma que el panel ya usa Administrador General y que JC ratifica las
  tres decisiones sin cambios. El extremo alto asume una ronda de ajustes en cada fase tras la verificación
  de Pedro.
- **La Fase 2 tiene un tramo que no depende de ti.** Sus 4–6 días son de desarrollo; la ventana de corte
  (T-22) depende de que Ana migre el panel y Pedro el agente. En calendario puede estirarse bastante más
  que en esfuerzo. Trátalos como cifras distintas.
- **Si JC pide FK sobre `incidencia.estatus`** en lugar de validación en la API, la Fase 1 sube ~2 días y hay
  que agregar la migración de los valores existentes, incluida la fila `"En revisiónnnnn"`.
- **Pruebas automatizadas no están incluidas.** El repositorio no tiene proyectos de test (RNF-15). Montar la
  infraestructura de pruebas y cubrir estos endpoints es trabajo adicional a estimar aparte.

**Riesgo de deadline.** El PRD **no declara fecha límite**: la restricción es cualitativa —"arreglar el
contrato **antes del corte a producción** evita migrar los parches también"— y es una restricción real, no
una preferencia: cada semana que el sistema siga sin salir a producción con los parches puestos aumenta la
probabilidad de que los parches se muden con él.

Con un desarrollador, el alcance completo cabe en **2.5 a 3.5 semanas** de trabajo efectivo, más el tiempo de
calendario de la ventana coordinada de la Fase 2 y la dependencia de TI para la Fase 4. Si el corte a
producción quedara a menos de dos semanas, la recomendación es entregar **Fase 0 + Fase 1** (P1), que es el
guardarraíl del propio PRD: desbloquea la pestaña de Evidencia —el hueco que hoy tiene costo operativo real,
porque el técnico decide a ciegas— y no requiere coordinar con ningún otro repositorio.

Un segundo desarrollador comprimiría el total en torno a **30–35%**, no a la mitad: las Fases 1 y 2 comparten
las mismas entidades, los mismos archivos `partial` de `IssuesService` y los mismos mapeos en los dos
contextos EF, así que trabajarlas en paralelo genera conflictos. El corte que sí paraleliza limpio es
**Fase 3 en paralelo con Fase 1**: la Fase 3 toca `ClaimsService`/`ClaimsController` y los DTOs de fechas,
que no se cruzan con la superficie de documentos.

---

*Generado por Claude Code — Engine CX*
*Modelo: `claude-opus-5` — esfuerzo: alto*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`, y `CLAUDE.md` de `gp_3.0_siga_api`*
