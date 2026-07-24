# Plan de Desarrollo — Endpoint de consulta de cotizaciones con error

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Gplus-Seguros/omega-endpoint-cotizaciones-error/PRD.md` |
| Repositorio | `github.com/garantiplusmexico/gp_seguros` (Omega — backend) |
| Rama | `feature/omega-endpoint-cotizaciones-error` |
| Tipo | Feature (solo lectura, sobre proyecto existente) |
| Responsable | Alexis Salvador Herrera Garcia |
| Folio PRD | `56445` |
| Fecha de generación | 2026-07-24 |
| Estado | Borrador |
| ID plan (BD) | 33 |
| Modelo / esfuerzo | Opus 4.8 — esfuerzo alto |
| Rama base | `develop` |

---

## 1. Resumen técnico

Se agrega un **endpoint GET de solo lectura** al microservicio `cotizador_omega` que devuelve las **últimas 10 cotizaciones con error**, con el folio de cotización, la aseguradora y el mensaje de error.

- **Componente modificado:** `Services/cotizador/cotizador_omega` (Web API .NET 8 ya existente). No se crean servicios ni contenedores nuevos.
- **Origen de datos:** tabla `cotizacion_aseguradora`, columna `error_aseguradora`. Se filtra por registros con error no vacío, se ordena por recencia (`fecha_respuesta`) y se limita a 10.
- **Arquitectura:** se respeta la del proyecto (microservicios en ECS + patrón repositorio `IRepository`/`GPSegurosRepository` sobre PostgreSQL con EF Core + Npgsql + NodaTime). Sin cambios de infraestructura, BD ni NATS.
- **Stack:** .NET 8 / C# (el del proyecto). No se introduce ninguna dependencia nueva.

**Hallazgo clave que resuelve la pregunta abierta del PRD** (¿todas las cotizaciones con error o solo las excluidas de NATS?): todas las rutas que registran un error —timeout, error devuelto por la aseguradora y las **validaciones de excepción por aseguradora que excluyen del envío a NATS**— escriben en la **misma** columna `cotizacion_aseguradora.error_aseguradora` (a través de `AuxiliaresCotizadorHelper.GenerarCotizacionAseguradoraError`, incluidas las llamadas de `RegistrarErroresHomologacion...` y `ValidarConfiguracionPorAseguradora...` en `CotizacionesController` líneas ~3190 y ~3239). Por lo tanto, **una sola consulta sobre `cotizacion_aseguradora` con `error_aseguradora` no vacío cubre todos los tipos de error**, incluidas las excepciones por aseguradora. Se recomienda ese alcance (todas), pendiente de confirmación del negocio.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable.
- [ ] Acceso al repositorio `gp_seguros` confirmado.
- [ ] Repo hermano `LogsMonitorClient` presente en `C:/Proyectos/EngineCX/LogsMonitorClient` (dependencia obligatoria por ruta relativa de `cotizador_omega.csproj`; sin él no compila el servicio).
- [ ] `CLAUDE.md` presente en el repositorio. ✅ Confirmado.
- [ ] Cadena de conexión a una BD de cotizaciones con datos de prueba (idealmente algunas cotizaciones con error) para validar el endpoint en local.
- [ ] Definición confirmada de "error" (recomendación del plan: todas las `cotizacion_aseguradora` con `error_aseguradora`).

---

## 3. Arquitectura del cambio

Feature de solo lectura sobre un microservicio existente. No aplica microservicio nuevo (regla `arquitectura.md`: modificación → mantener donde ya vive). Flujo de datos:

```
Cliente (JWT) ──GET /cotizaciones/con-error──> CotizacionesController (cotizador_omega)
                                                      │
                                                      ▼
                                     IRepository.Filter<cotizacion_aseguradora>
                                     (error_aseguradora != null/"", include aseguradora,
                                      OrderByDescending fecha_respuesta, Take 10)
                                                      │
                                                      ▼
                                          PostgreSQL (tabla cotizacion_aseguradora)
                                                      │
                                                      ▼
                                     List<CotizacionErrorResponseDTO>
                                     { folio_cotizacion, aseguradora, error }
```

No hay escritura, ni publicación a NATS, ni llamadas a sistemas externos.

---

## 4. Tareas de desarrollo

### Fase 0 — Preparación y rama base

- [ ] **T-01** — Posicionarse en `develop` actualizado y crear la rama funcional.
  - Comandos: `git checkout develop && git pull origin develop && git checkout -b feature/omega-endpoint-cotizaciones-error`
  - Criterio de completitud: rama `feature/omega-endpoint-cotizaciones-error` creada desde `develop` al día y publicada en el remoto.

- [ ] **T-02** — Verificar que `cotizador_omega` compila en local (con el repo hermano `LogsMonitorClient` presente).
  - Archivos: `Services/cotizador/cotizador_omega/cotizador_omega.csproj`
  - Comandos: `cd Services/cotizador/cotizador_omega && dotnet restore && dotnet build`
  - Criterio de completitud: build exitoso antes de tocar código.

### Fase 1 — Endpoint de cotizaciones con error (P1 — guardarraíl del PRD)

- [ ] **T-03** — Crear el DTO de respuesta con los campos del PRD (RF-03).
  - Archivos a crear: `Services/cotizador/cotizador_omega/DTOs/Cotizaciones/Responses/CotizacionErrorResponseDTO.cs` (o, si se decide seguir la convención existente de DTOs del proyecto, junto a los demás DTOs de cotizaciones — ver §12).
  - Contenido: propiedades `folio_cotizacion` (int, = `id_cotizacion`), `aseguradora` (string, = `nombre_comercial`), `error` (string, = `error_aseguradora`). Opcional: `fecha_error` (DateTime) para dar contexto de recencia (fuera del mínimo del PRD; incluir solo si el responsable lo aprueba).
  - Criterio de completitud: clase compila; una propiedad por campo requerido.

- [ ] **T-04** — Implementar la consulta de las 10 cotizaciones con error más recientes.
  - Archivos a modificar: `Services/cotizador/cotizador_omega/Controllers/CotizacionesController.cs` (nuevo método de acción, siguiendo el patrón del controller que usa `repo.Filter<T>` directamente).
  - Lógica: `repo.Filter<cotizacion_aseguradora>(ca => ca.error_aseguradora != null && ca.error_aseguradora != "", new[]{ "aseguradora" }).OrderByDescending(ca => ca.fecha_respuesta).Take(10)` y proyección al DTO (`folio_cotizacion = id_cotizacion`, `aseguradora = aseguradora.nombre_comercial`, `error = error_aseguradora`).
  - Criterio de completitud (RF-01, RF-02, RF-04): devuelve como máximo 10 registros, ordenados de más reciente a más antiguo, cada uno con folio + aseguradora + error.

- [ ] **T-05** — Exponer el endpoint HTTP y aplicar autorización (RF-01, RNF-01, RNF-02).
  - Archivos a modificar: `Services/cotizador/cotizador_omega/Controllers/CotizacionesController.cs`.
  - Endpoint: `[HttpGet("con-error", Name = "GetCotizacionesConError")]`, método `GET`, `async Task<ActionResult<IEnumerable<CotizacionErrorResponseDTO>>>`. Solo lectura (no escribe nada).
  - Autorización: el controller ya tiene `[Authorize]` (JWT). Restringir por rol de monitoreo siguiendo el patrón existente del controller (p. ej. `[Authorize(Roles = "Administrador General,Auditor,Soporte")]`). **Roles exactos por confirmar** con el responsable (RNF-02 quedó como definición técnica pendiente en el PRD).
  - Criterio de completitud: `GET /cotizaciones/con-error` responde 200 con la lista; sin token responde 401; con rol no autorizado responde 403.

- [ ] **T-06** — Documentar el endpoint (XML docs) y tipos de respuesta.
  - Archivos a modificar: `Services/cotizador/cotizador_omega/Controllers/CotizacionesController.cs`.
  - Agregar `/// <summary>`, `/// <returns>`, `/// <response>` y `[ProducesResponseType]` para 200/401/403/500, conforme a `coding-guidelines.md §5`.
  - Criterio de completitud: el endpoint aparece documentado en Swagger con el esquema del DTO.

- [ ] **T-07** — Prueba manual del endpoint en local.
  - Levantar `cotizador_omega`, obtener JWT válido y llamar `GET /cotizaciones/con-error`.
  - Criterio de completitud: con cotizaciones con error en BD, la respuesta trae ≤10 registros ordenados por recencia con los 3 campos; sin errores en BD, devuelve lista vacía y 200.

### Fase 2 — Endurecimiento y validación (P2 — opcional según tiempo)

- [ ] **T-08** — Revisar índice/plan de consulta para el filtro por `error_aseguradora` + orden por `fecha_respuesta`.
  - Criterio de completitud: confirmar que la consulta sobre el volumen real es aceptable; dejar registrada la recomendación de índice si el `EXPLAIN` lo justifica (no crear índice salvo que el responsable lo apruebe — cambio en BD).

- [ ] **T-09** — Commit final y push de la rama funcional.
  - Comandos: `git add . && git commit -m "[omega-endpoint-cotizaciones-error] Agregar endpoint de consulta de cotizaciones con error" && git push origin feature/omega-endpoint-cotizaciones-error`
  - Criterio de completitud: rama publicada, lista para que el programador gestione el PR hacia `pre-qa`.

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `cotizacion_aseguradora` | Ninguno (solo lectura) | Se consulta la columna `error_aseguradora` existente. |
| `cotizacion_aseguradora` | Índice *(opcional, T-08)* | Solo si el `EXPLAIN` sobre el volumen real lo justifica; requiere aprobación del responsable. No se incluye en el alcance P1. |

Sin migraciones. La feature es RNF-01 (solo lectura).

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/cotizaciones/con-error` | Últimas 10 cotizaciones con error (folio, aseguradora, error), orden descendente por recencia. | Nuevo |

> Nota de convención: el `CotizacionesController` existente **no** versiona sus rutas (`/cotizaciones`, `/cotizaciones/cnt`, `/cotizaciones/{id}`). El plan sigue ese patrón por consistencia con el controller. `coding-guidelines.md §5` pide versionar (`v1/...`); se documenta la desviación en §12 para decisión del responsable.

---

## 7. Variables de entorno y configuración

Ninguna nueva. Se reutiliza `CONNECTION_STRING` y la configuración de autenticación JWT (`SIGNING_KEY`) ya presentes en `cotizador_omega`.

---

## 8. Consideraciones de seguridad

- **Autenticación:** JWT Bearer (política global `RequireAuthenticatedUser`). El controller ya exige `[Authorize]`.
- **Autorización:** restringir el endpoint a roles de monitoreo/soporte (por confirmar — RNF-02). No exponer el detalle de roles en la documentación pública del endpoint (`coding-guidelines.md §6`).
- **Datos sensibles:** el mensaje de error puede contener texto devuelto por la aseguradora. No se registran tokens ni datos personales sensibles en logs. Verificar que `error_aseguradora` no incluya datos sensibles antes de exponerlo ampliamente; si los incluyera, acotar el texto.
- **Inyección:** la consulta usa LINQ/EF Core parametrizado; sin concatenación de SQL.
- **Secrets:** ninguno nuevo; nada hardcodeado.

---

## 9. Consideraciones de infraestructura

Ninguna. No se crean servicios AWS, ni cambios en ECS/RDS/S3, ni en Cloudflare/Route 53. El endpoint se despliega con el ciclo normal de `cotizador_omega` (contenedor existente en ECS + Fargate).

---

## 10. Criterios de aceptación

- [ ] `GET /cotizaciones/con-error` devuelve como máximo 10 registros (RF-02).
- [ ] Cada registro incluye folio de cotización, aseguradora y error (RF-03).
- [ ] Los resultados están ordenados de la cotización con error más reciente a la más antigua (RF-04).
- [ ] El endpoint no escribe ni modifica datos (RNF-01).
- [ ] El acceso requiere autenticación JWT válida; sin token → 401; con rol no autorizado → 403 (RNF-02).
- [ ] Con BD sin cotizaciones con error, devuelve `200` con lista vacía.
- [ ] `cotizador_omega` compila y el endpoint aparece documentado en Swagger.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Repo hermano `LogsMonitorClient` ausente → no compila `cotizador_omega` | Media | Alto | Verificar presencia en T-02 antes de codificar. |
| Definición de "error" distinta a la asumida (solo excepciones de NATS vs. todas) | Media | Medio | El plan recomienda "todas"; confirmar con el responsable antes de cerrar T-04. La consulta se ajusta con un filtro adicional si se restringe. |
| Roles de autorización sin definir (RNF-02) | Media | Medio | Confirmar roles con el responsable en T-05; por defecto restringir a roles de monitoreo. |
| `fecha_respuesta` sin poblar en errores de excepción previos a NATS | Baja | Bajo | Usar orden secundario por `id_cotizacion_aseguradora` desc como desempate/fallback. |
| Volumen alto de `cotizacion_aseguradora` degrada la consulta | Baja | Bajo | `Take(10)` limita el resultado; evaluar índice en T-08 solo si el `EXPLAIN` lo justifica. |

---

## 12. Notas para el programador

1. **Convención de DTO (decisión requerida).** `coding-guidelines.md §1` pide nombres en inglés para código nuevo, pero los DTOs existentes de Omega usan snake_case en español (`cotizacion_completaDTO`). El plan propone `CotizacionErrorResponseDTO` con propiedades snake_case para no romper la consistencia del proyecto; confirmar si se prefiere inglés estricto.
2. **Versionado de ruta.** El controller existente no versiona; el plan sigue ese patrón. Si se quiere alinear con la guía (`v1/...`), decidir antes de T-05 (afecta a los consumidores).
3. **Roles de autorización (RNF-02).** Pendiente en el PRD. Definir la lista exacta de roles con acceso antes de T-05.
4. **Alcance de "error".** Se recomienda incluir todas las `cotizacion_aseguradora` con `error_aseguradora` (cubre las excepciones excluidas de NATS y los demás errores, ya que todas escriben en esa columna). Si el negocio quiere solo las excepciones por aseguradora, se requiere un discriminador adicional (hoy no existe un campo que distinga el tipo de error de forma persistida; habría que agregarlo — quedaría fuera del alcance actual).
5. **Campo `fecha_error`.** Fuera del mínimo del PRD (3 campos). Incluir solo si aporta valor y el responsable lo aprueba.
6. **No refactorizar** el resto del `CotizacionesController` ni el patrón de acceso a datos; solo agregar el método nuevo.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Preparación y rama base** | Rama funcional desde `develop`, build de `cotizador_omega` verificado | T-01 a T-02 | 0.5 día | 73 |
| **Fase 1 — Endpoint de cotizaciones con error (P1)** | DTO de respuesta, consulta top-10, endpoint HTTP + auth, XML docs, prueba manual | T-03 a T-07 | 1.5 – 2 días | 74 |
| **Fase 2 — Endurecimiento y validación (P2, opcional)** | Revisión de plan de consulta/índice, commit y push final | T-08 a T-09 | 0.5 – 1 día | 75 |
| **Total proyecto (P1+P2)** | | 9 tareas | ~2.5 – 3.5 días hábiles (≈ 0.5 – 0.75 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-07 | ~2 – 2.5 días hábiles (≈ 0.5 semanas) | — |

> **Notas sobre la tabla:**
> - Es una feature pequeña y de solo lectura; el peso está en la Fase 1.
> - La columna **ID (BD)** la llena el flujo al registrar el plan en la base de datos; no editarla a mano.

> **Riesgo de deadline:** el PRD (fecha 2026-07-22, v0.1) **no define una fecha límite explícita**. Con la estimación de ~2 – 3.5 días hábiles y un solo desarrollador, el riesgo de deadline es **bajo**; no se requiere un segundo recurso. Se recomienda confirmar con el responsable si existe una fecha objetivo; de haberla y ser holgada, el alcance completo (P1+P2) cabe sin comprimir.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
