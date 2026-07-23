# Plan de Desarrollo — Endpoint de consulta de cotizaciones con error (Omega)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Gplus-Seguros/omega-endpoint-cotizaciones-error/PRD.md` |
| Repositorio | `gp_seguros` (backend Omega) — `C:\Proyectos\Seguros\gp_seguros` |
| Rama | `feature/omega-endpoint-cotizaciones-error` |
| Tipo | Feature (solo lectura) |
| Responsable | Alexis Salvador Herrera Garcia |
| Folio PRD | `PRueba1` |
| Fecha de generación | 2026-07-23 |
| Estado | Borrador |
| ID plan (BD) | 13 |

---

## 1. Resumen técnico

Se agrega un **endpoint GET de solo lectura** al microservicio `cotizador_omega` (Web API .NET 8) que devuelve las **últimas 10 cotizaciones registradas con error**, exponiendo por cada una: **folio de cotización** (`id_cotizacion`), **aseguradora** (nombre comercial) y **error** (`error_aseguradora`).

- **Componente que se modifica:** `Services/cotizador/cotizador_omega` (se crea un controller nuevo y un DTO de respuesta). No se toca ningún otro servicio ni el flujo de cotización.
- **Arquitectura:** microservicio existente en ECS + Fargate. No cambia. Se respeta la arquitectura y stack actuales (ver `rules/arquitectura.md`, `rules/stack.md`).
- **Stack:** .NET Core 8 / C#, EF Core + Npgsql sobre PostgreSQL (RDS Aurora), patrón repositorio (`GPSegurosRepository`). Sin frontend en este alcance.
- **Fuente de datos:** la vista de solo lectura **`vr_cotizaciones_aseguradora`** (`Models/Reportes/vr_cotizaciones_aseguradora.cs`), que ya expone en una sola entidad `id_cotizacion`, `aseguradora` (nombre resuelto), `error_aseguradora` y `fecha_registro`. Es el camino de menor riesgo (solo lectura, sin joins nuevos, sin cambios de esquema).
- **Determinación del "error":** una cotización quedó con error cuando `error_aseguradora` **no** es null ni vacío. Es el criterio que ya usa todo el código (`CotizacionesController` líneas 298 y 798).

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable.
- [ ] Acceso al repositorio `gp_seguros` confirmado (rama `develop` actualizada). ✔ verificado al generar el plan.
- [ ] **Repo hermano `LogsMonitorClient` presente** en `C:/Proyectos/EngineCX/LogsMonitorClient` — `cotizador_omega.csproj` lo referencia por ruta relativa; sin él el build falla. ✔ presente en el árbol de proyectos.
- [ ] Variables de entorno de desarrollo disponibles para levantar `cotizador_omega` en local: `CONNECTION_STRING` (`GPSeguros_Connection`), `SIGNING_KEY` y config `Authentication:Issuer/Audience/SigningKey` para emitir/validar el JWT de prueba.
- [ ] `CLAUDE.md` presente en el repositorio. ✔ existe.
- [x] **Alcance de "error" confirmado:** se incluyen **todas** las cotizaciones con `error_aseguradora` seteado (todos los tipos), no solo las excluidas de NATS por excepción de aseguradora.
- [x] **Permisos confirmados:** el endpoint es **libre** (sin restricción por rol); se mantiene únicamente la autenticación estándar de Omega (`[Authorize]` / JWT). No se añaden roles.

---

## 3. Arquitectura del cambio

Flujo de datos del nuevo endpoint (todo dentro del contenedor `cotizador_omega`):

```
Cliente (JWT) ──GET──> API Gateway (KrakenD)
                            │
                            ▼
              cotizador_omega  (ECS + Fargate)
                 CotizacionesErrorController  [Authorize]
                            │
                            ▼
              GPSegurosRepository (envuelve cotizaciones_dbContext)
                            │
                            ▼
         PostgreSQL — vista vr_cotizaciones_aseguradora (solo lectura)
         WHERE error_aseguradora != null/''  ORDER BY fecha_registro DESC  LIMIT 10
```

**Justificación (`rules/arquitectura.md`):** es una feature de solo lectura sobre un microservicio existente. No se crea servicio nuevo, no se justifica microservicio adicional ni cambio de arquitectura. El cambio vive donde ya vive el dominio de cotización (regla: modificación → se mantiene donde ya vive).

**Decisiones de diseño ancladas al código real:**
- Se imita el patrón de `Controllers/ReporteController.cs` (controller de consulta más simple): `[ApiController]`, `[Route("...")]`, `[Authorize]`, hereda `DecoratorControllerBase`, inyecta `cotizaciones_dbContext` y construye `repo = new GPSegurosRepository(dbContext)`.
- **No se registra `IRepository` en DI** ni se modifica `Program.cs`: el repo se instancia en el controller, como en todos los controllers existentes. El `cotizaciones_dbContext` ya está registrado (`Program.cs` líneas 77-79).

---

## 4. Tareas de desarrollo

### Fase 0 — Preparación (P1)

- [ ] **T-01** — Crear la rama funcional desde `develop` actualizado.
  - Comandos: `git checkout develop && git pull origin develop && git checkout -b feature/omega-endpoint-cotizaciones-error`
  - Criterio de completitud: rama `feature/omega-endpoint-cotizaciones-error` creada y publicada (`git push origin ...`).

- [ ] **T-02** — Verificar build baseline del servicio antes de tocar código.
  - Archivos: —
  - Comandos: `cd Services/cotizador/cotizador_omega && dotnet restore && dotnet build`
  - Criterio de completitud: `dotnet build` compila sin errores (con `LogsMonitorClient` presente). Se establece la línea base.

### Fase 1 — Implementación del endpoint (P1 — guardarraíl del PRD)

- [ ] **T-03** — Crear el DTO de respuesta del endpoint.
  - Archivos a crear: `Services/cotizador/cotizador_omega/Models/DTO/CotizacionErrorDTO.cs`
  - Contenido: clase plana con `int Folio` (= `id_cotizacion`), `string Aseguradora` (nombre comercial) y `string Error` (= `error_aseguradora`). Namespace acorde a la carpeta (`mx.gpseguros.services.cotizaciones.models`), estilo Allman, 4 espacios (`rules/coding-guidelines.md`).
  - Criterio de completitud: el DTO compila y expone exactamente los 3 campos del RF-03.

- [ ] **T-04** — Crear el controller de consulta con el endpoint GET.
  - Archivos a crear: `Services/cotizador/cotizador_omega/Controllers/CotizacionesErrorController.cs`
  - Detalle: `[ApiController]`, `[Route("cotizaciones-error")]` (kebab-case, siguiendo el patrón `reporte-cotizaciones`), `[Authorize]`, `[Produces("application/json")]`; hereda `DecoratorControllerBase`; constructor con la misma inyección que `ReporteController` (`ActivitySource`, `cotizaciones_dbContext`, `ILogger<T>`, `LinkGenerator`, `IConfiguration`, `IHttpClientFactory`, `IS3Access`, `ILoggingService`) y `repo = new GPSegurosRepository(dbContext)`.
  - Método: `[HttpGet(Name = "GetCotizacionesConError")]` que retorna `ActionResult<IEnumerable<CotizacionErrorDTO>>`. Documentación XML completa (summary, response 200/401/500) según `rules/coding-guidelines.md §5`.
  - Criterio de completitud: el endpoint aparece en Swagger, responde 401 sin token y 200 con token válido.

- [ ] **T-05** — Implementar la consulta de datos (última milla del RF-01/02/03/04).
  - Archivos a modificar: `CotizacionesErrorController.cs` (cuerpo del método GET).
  - Detalle: `repo.All<vr_cotizaciones_aseguradora>()` → filtrar `!string.IsNullOrWhiteSpace(x.error_aseguradora)` → `OrderByDescending(x => x.fecha_registro)` (RF-04, recencia) → `Take(10)` (RF-02) → proyectar a `CotizacionErrorDTO { Folio = id_cotizacion, Aseguradora = aseguradora, Error = error_aseguradora }` (RF-03) → `Ok(lista)`. Consulta `async` con `ToListAsync()`; sin `.Result`/`.Wait()` (`rules/coding-guidelines.md §10`).
  - Criterio de completitud: con datos de prueba con error, el endpoint devuelve como máximo 10 registros, ordenados de más reciente a más antiguo, con folio + aseguradora + error correctos.

### Fase 2 — Verificación y cierre (P2)

- [ ] **T-06** — Pruebas manuales y validación funcional.
  - Detalle: levantar el servicio en local (`dotnet run` o `docker compose up` en `Infrastructure/local`), obtener un JWT válido y verificar: (a) 401 sin token; (b) 200 con token; (c) que solo aparezcan cotizaciones con error; (d) orden por recencia; (e) límite de 10.
  - Criterio de completitud: los 5 criterios de aceptación de §10 se cumplen manualmente y se deja evidencia (capturas / respuestas de ejemplo).

- [ ] **T-07** — Commit final y push de la rama funcional.
  - Comandos: `git add . && git commit -m "[omega-endpoint-cotizaciones-error] Agregar endpoint de consulta de cotizaciones con error" && git push origin feature/omega-endpoint-cotizaciones-error`
  - Criterio de completitud: rama publicada con el cambio; el PR hacia `pre-qa` queda a cargo del programador (Claude Code no crea PRs, `rules/version-control.md §5`).

---

## 5. Cambios en base de datos

**No aplica.** La feature es de solo lectura sobre datos ya existentes. Se consume la vista `vr_cotizaciones_aseguradora` (ya creada) y/o las tablas `cotizacion` y `cotizacion_aseguradora`. Sin migraciones, sin nuevas tablas, sin índices nuevos.

> Nota: si en QA la consulta resulta lenta por volumen, evaluar (fuera de este alcance) un índice sobre `cotizacion_aseguradora(error_aseguradora)` / `cotizacion(fecha_registro)`. No se incluye en el plan por ser prematuro.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `cotizaciones-error` | Devuelve las últimas 10 cotizaciones con error (folio, aseguradora, error), ordenadas por recencia | Nuevo |

Respuesta 200 (ejemplo):
```json
[
  { "folio": 10234, "aseguradora": "Qualitas", "error": "Timeout al consultar el servicio de la aseguradora" },
  { "folio": 10231, "aseguradora": "HDI", "error": "Paquete no disponible para el tipo de uso" }
]
```

---

## 7. Variables de entorno y configuración

**No se agregan variables nuevas.** El endpoint reutiliza la configuración existente del servicio:

| Variable | Descripción | Ambiente |
|---|---|---|
| `CONNECTION_STRING` (`GPSeguros_Connection`) | Cadena de conexión a PostgreSQL (ya existente) | Desarrollo / QA / Producción |
| `Authentication:Issuer` / `Audience` / `SigningKey` | Validación del JWT (ya existente) | Desarrollo / QA / Producción |

---

## 8. Consideraciones de seguridad

- **Autenticación:** cubierta por la política global `RequireAuthenticatedUser` + JWT Bearer (`Program.cs` líneas 31-36 y 86-99). El controller lleva `[Authorize]` explícito por claridad. Sin token → 401.
- **Autorización por rol:** **confirmado que el endpoint es libre** — no se restringe por rol. Se mantiene solo la autenticación estándar (`[Authorize]` + JWT global). No se añade `[Authorize(Roles = ...)]`.
- **Datos sensibles:** el endpoint expone folio, nombre de aseguradora y mensaje de error. No expone datos personales del cliente ni credenciales. El mensaje de error proviene de `NormalizarErrorAseguradora` (ya truncado/normalizado); no incluye stack traces.
- **Consultas parametrizadas:** se usa LINQ sobre EF Core (parametrizado por diseño). Sin concatenación de SQL.
- **Secrets:** ninguno nuevo; todo por variables de entorno / configuración existente.

---

## 9. Consideraciones de infraestructura

**No aplica cambio de infraestructura.** El endpoint se despliega con el mismo contenedor `cotizador_omega` existente en ECS + Fargate (`us-east-1`), vía el flujo de despliegue automático ya configurado (GitHub Actions: push a `qa` → `qa-apiomega`; push a `main` → producción). No hay nuevos servicios AWS, ni cambios en RDS/S3/Route 53/Cloudflare. Costo incremental: nulo.

---

## 10. Criterios de aceptación

- [ ] Existe un endpoint `GET cotizaciones-error` en `cotizador_omega` (RF-01).
- [ ] Devuelve como máximo **10** registros (RF-02).
- [ ] Cada registro incluye **folio de cotización, aseguradora y error** (RF-03).
- [ ] Los resultados están ordenados de la cotización con error **más reciente a la más antigua** (RF-04).
- [ ] Solo aparecen cotizaciones cuyo `error_aseguradora` no es null/vacío (definición de "error").
- [ ] El endpoint responde **401** sin JWT válido y **200** con JWT válido (RNF-02).
- [ ] El endpoint **no escribe ni modifica** datos (RNF-01) — es solo lectura.
- [ ] El servicio compila y arranca sin regresiones (`dotnet build` OK).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| El repo hermano `LogsMonitorClient` no está presente y el build de `cotizador_omega` falla | Media | Alto | Verificar su presencia en `C:/Proyectos/EngineCX/LogsMonitorClient` antes de compilar (T-02, prerequisito). |
| La vista `vr_cotizaciones_aseguradora` no contenga los campos/filas esperadas en QA/prod (definiciones distintas por ambiente) | Baja | Medio | Confirmar la definición de la vista en el ambiente objetivo; si no aplica, usar la alternativa desde tablas (`cotizacion_aseguradora` + include `cotizacion`/`aseguradora`). |
| ~~Ambigüedad en la definición de "error"~~ | — | — | **Resuelto:** todas las cotizaciones con `error_aseguradora` no vacío (todos los tipos). Confirmado por el solicitante. |
| ~~Alcance de permisos no definido (RNF-02)~~ | — | — | **Resuelto:** endpoint libre, sin rol; solo `[Authorize]` estándar. Confirmado por el solicitante. |
| Volumen de datos degrade la consulta sin índice | Baja | Bajo | `Take(10)` acota el resultado; evaluar índice solo si QA lo evidencia (§5). |

---

## 12. Notas para el programador

Decisiones tomadas durante la generación del plan (a validar antes de ejecutar):

1. **Fuente de datos = vista `vr_cotizaciones_aseguradora`** en lugar de armar el join manualmente. Es de solo lectura, ya resuelve el nombre de la aseguradora y trae `fecha_registro` y `error_aseguradora`. Alternativa lista si la vista no sirve en algún ambiente: `repo.All<cotizacion_aseguradora>(new[]{"cotizacion","aseguradora"})` filtrando `error_aseguradora`, ordenando por `cotizacion.fecha_registro` y proyectando `nombre_comercial`.
2. **Folio = `id_cotizacion`.** El modelo `cotizacion` no tiene un campo "folio" propio; el folio de negocio de la cotización es su `id_cotizacion`. (El campo `folio` string vive en `cotizacion_aseguradora` y es el folio que devuelve la aseguradora — distinto; no es el solicitado por el PRD.)
3. **Definición de "error" = `error_aseguradora` no vacío**, tal como lo usa el código productivo. **Confirmado por el solicitante:** incluye **todos** los tipos de error (Timeout, Homologación, Paquete no disponible, etc.), no solo las exclusiones de NATS por excepción de aseguradora.
   - **Permisos (confirmado):** el endpoint es **libre** — sin restricción por rol; solo autenticación estándar (`[Authorize]` + JWT global).
4. **Ruta `cotizaciones-error`** siguiendo el patrón kebab-case del repo (`reporte-cotizaciones`). Los controllers de Omega no versionan la URI con `v1/` (convención propia del proyecto); se respeta esa convención existente en lugar de introducir versionado nuevo. Si el equipo prefiere versionar, ajustar a `v1/cotizaciones-error`.
5. **Sin cambios en `Program.cs`.** El `cotizaciones_dbContext` ya está registrado y el repositorio se instancia en el controller, como el resto del servicio. No hay rate limiting configurado en Omega, así que no se añade (se respeta el proyecto).

---

## 13. Relación de tareas y tiempos

Estimación en **días hábiles** por fase. Feature pequeña, de solo lectura, sobre un servicio existente y con patrón de controller ya presente en el repo.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Preparación (P1)** | Rama funcional + build baseline | T-01 a T-02 | 0.5 día | 3 |
| **Fase 1 — Implementación del endpoint (P1)** | DTO, controller y consulta (RF-01 a RF-04) | T-03 a T-05 | 1 – 2 días | 4 |
| **Fase 2 — Verificación y cierre (P2)** | Pruebas manuales + commit/push | T-06 a T-07 | 0.5 – 1 día | 5 |
| **Total proyecto (P1+P2)** | | 7 tareas | ~2 – 3.5 días hábiles (≈ 0.5 semana) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-05 | ~1.5 – 2.5 días hábiles | — |

> **Notas sobre la tabla:**
> - Los rangos salen de la complejidad real: el patrón de controller y la vista ya existen, por lo que la implementación (Fase 1) es el grueso del esfuerzo.
> - La columna **ID (BD)** la llena el flujo al registrar el plan en la base de datos (`pm_plan_fase.id`); no editar a mano.

> **Riesgo de deadline:** el PRD (v0.1, fecha 2026-07-22) **no fija una fecha límite explícita**. Con un solo desarrollador el alcance completo (P1+P2) cabe holgadamente en ~1 semana laboral. No se identifica riesgo de deadline ni necesidad de un segundo recurso. Si surgiera una fecha límite ajustada, el guardarraíl P1 (endpoint funcional, T-01 a T-05) entrega el valor central del PRD en ~1.5–2.5 días.

---

*Generado por Claude Code — Engine CX*
*Modelo: claude-opus-4-8 — esfuerzo: alto*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
