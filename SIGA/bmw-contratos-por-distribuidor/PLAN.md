# Plan de Desarrollo — BMW: contratos por distribuidor (landing)

> Generado por Claude Code. **Sin PRD de origen**: el desarrollador autorizó generar el plan
> directamente desde el contexto de negocio. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | *(no existe — generado desde contexto directo, autorizado el 2026-08-25)* |
| Repositorio | `bmw_landing` (frontend) + `gp_3.0_siga_api` (backend, servicio `Contracts`) |
| Rama | `feature/bmw-contratos-por-distribuidor` |
| Tipo | Feature |
| Responsable | Juan Carlos Castellanos Solis |
| Folio PRD | `PJ5120` — ⚠️ **provisional, asignado por Claude a falta de folio real**. Verificado libre en `enginecx_prd` y en `pm_plan_desarrollo` al 2026-08-25. Sustituir por el folio oficial en cuanto exista (`plan-update --id <id> --folio <real>` y renombrar la carpeta). |
| Fecha de generación | 2026-08-25 |
| Estado | Borrador |
| ID plan (BD) | `57` (`pm_plan_desarrollo.id`) |
| Rama base | `develop` (verificada y actualizada: `5deb29f`) |
| Modelo | `claude-opus-5` — esfuerzo: alto |

---

## 1. Resumen técnico

BMW pide saber **cuántos contratos ha generado cada distribuidor**; hoy se entrega como reporte
manual. Se automatiza con una **sección nueva en la landing** que consulta ese conteo en vivo.

Dos componentes:

1. **Backend (`gp_3.0_siga_api`, servicio `Contracts`)** — endpoint nuevo que **agrega en SQL**:
   `GET /contracts/api/Bmw/v1/{projectId}/registrations/summary-by-distributor`.
   Devuelve una fila por distribuidor del proyecto con el total de contratos y sus desgloses.
2. **Frontend (`bmw_landing`)** — paso/sección nueva `report` (`/reporte` y `/embed/reporte`), con
   tabla ordenable, filtro por rango de fechas y grupo, totales y exportación a CSV.

**Por qué endpoint nuevo y no agregar en el navegador.** El listado actual
(`GET …/registrations`) sirve para lo suyo, pero no sirve como fuente del reporte:

| Motivo | Detalle |
|---|---|
| Agrupar por **id**, no por nombre | `registrations` expone `distributorName`, que es el **texto capturado** en `bmw_registro.nombre_distribuidor`. La regla de Engine es que la identidad del dealer va por `id_distribuidor`, nunca por nombre. Hoy coincide por casualidad (32 nombres ↔ 32 dealers, sin colisiones), pero el catálogo ya muestra el problema: existen los grupos `VECSA`, `SONI` y `Grupo Soni` como entradas distintas. |
| Dealers en **cero** | El reporte debe listar los 48 dealers del proyecto, no solo los 32 que tienen contratos. Un dealer con cero contratos es justo el dato que BMW quiere ver, y el front no puede inventarlo desde un listado de contratos. |
| Volumen | Agregar en el cliente obliga a bajar **todas** las filas (1,064 hoy y creciendo). El endpoint agregado devuelve ~48 filas constantes. |
| Reutiliza el scope existente | `GetAccessScopeAsync` ya resuelve qué dealers puede ver cada rol; se aplica igual al resumen sin escribir seguridad nueva. |

**Arquitectura aplicada:** Frontend + Backend separados (`rules/arquitectura.md` §2) — la que ya usa
el proyecto. No se crean servicios ni infraestructura nueva.

**Stack:** se respeta el existente (`rules/stack.md`): .NET Core 8 / C# en el backend, React 19 +
TypeScript + Vite + Tailwind 4 en la landing, PostgreSQL. Sin dependencias nuevas en ninguno de los
dos repos.

---

## 2. Prerequisitos

- [ ] Validar con negocio las **3 decisiones abiertas** de la §12 (Allianz, huérfanos, quién ve la sección)
- [ ] Folio `PJ####` asignado al proyecto (para registrar el plan en la BD de PM)
- [ ] Acceso a los dos repos confirmado (`bmw_landing`, `gp_3.0_siga_api`)
- [ ] `CLAUDE.md` presente en ambos repos — verificado, existe
- [ ] Rama `develop` de `bmw_landing` actualizada — verificado (`5deb29f`)
- [ ] Sin variables de entorno nuevas (ver §7)

---

## 3. Arquitectura del cambio

```
[Landing BMW /reporte]  --GET summary-by-distributor-->  [KrakenD ApiGateway]
   React 19 + Vite                                              |
   (S3 estatico)                                                v
                                                    [Contracts (ECS + Fargate)]
                                                      BmwController
                                                        -> GetAccessScopeAsync (scope por rol)
                                                        -> BmwRegistroSummaryService
                                                                |
                                                                v
                                                       [RDS PostgreSQL]
                                          distribuidor LEFT JOIN contrato/bmw_registro
                                          GROUP BY d.id_distribuidor
```

**Punto clave:** la agregación ocurre **en SQL**. El servicio nuevo NO reutiliza
`BmwRegistroQueryService.ListAsync`, que materializa todas las filas del proyecto en memoria para
que OData filtre encima. Reusarlo trasladaría ese costo al reporte sin ninguna ventaja.

---

## 4. Tareas de desarrollo

### Fase 0 — Contrato de API y consulta validada (P1)

- [ ] **T-01** — Definir el contrato de respuesta (API First, `coding-guidelines.md` §5)
  - Archivos a crear: `Services/Contracts/DTOs/Bmw/Responses/BmwDistributorSummaryResponse.cs`,
    `.../BmwDistributorSummaryItemResponse.cs`
  - Campos por fila: `distributorId`, `dealerCode` (`distribuidor.clave`), `distributorName`
    (`nombre_comercial` ?? `razon_social`), `groupId`, `groupName` (`grupo_distribuidor.razon_social`),
    `total`, `byStatus` (Registrado/Activo/Cancelado), `byModality` (Contado/Financiado/Enganche/
    Financiamiento externo), `paid`, `lastContractDate`
  - Envoltorio: `items[]` + `totals` (gran total y desgloses del conjunto ya filtrado por scope) +
    `unassigned` (registros sin dealer, ver T-04)
  - Criterio de completitud: DTOs compilando, una clase pública por archivo, XML docs en inglés

- [ ] **T-02** — Escribir y validar la consulta SQL de agregación contra la BD
  - `LEFT JOIN` **desde `distribuidor`** (para incluir dealers en cero) hacia `contrato` por
    `c.id_distribuidor` y `bmw_registro` por `r.id_contrato`, filtrando `r.id_proyecto = @project_id`
  - `GROUP BY d.id_distribuidor`; conteos con `FILTER (WHERE …)` por estatus y modalidad
  - Parámetros con `NpgsqlParameter` — nunca concatenación (`coding-guidelines.md` §11)
  - Criterio de completitud: la consulta corre y reproduce los números conocidos:
    **1,064 registros / 1,058 con contrato / 48 dealers / 32 con contratos / 6 sin dealer**

### Fase 1 — Backend: endpoint agregado (P1)

- [ ] **T-03** — Servicio de agregación
  - Archivos a crear: `Services/Contracts/Interfaces/IBmwRegistroSummaryService.cs`,
    `Services/Contracts/Services/Bmw/BmwRegistroSummaryService.cs`
  - Firma: `GetByDistributorAsync(int projectId, BmwDirectoryAccessScope scope, DateOnly? from, DateOnly? to, int? groupId, CancellationToken ct)`
  - Aplica el scope igual que `BmwRegistroQueryService`: `None` / `ByProjectIds` → sin recorte;
    `ByDistributorIds` → `d.id_distribuidor = ANY(@dist_ids)`; lista vacía → resultado vacío
  - Criterio de completitud: archivo bajo 200 líneas útiles; si se pasa, separar el SQL a un builder

- [ ] **T-04** — Fila de registros sin distribuidor
  - Los registros cuyo alta de contrato falló no tienen `c.id_distribuidor` (**6 hoy**) y quedarían
    fuera de todo `GROUP BY` por dealer, haciendo que la suma del reporte no cuadre con el listado
  - Se devuelven aparte en `unassigned`, nunca mezclados en una fila de dealer
  - **Solo visible para scope no acotado** (`None` / `ByProjectIds`): un dealer no debe ver huérfanos ajenos
  - Criterio de completitud: la suma de `items` más `unassigned` cuadra con el total del listado
    bajo el mismo filtro

- [ ] **T-05** — Endpoint en `BmwController`
  - Archivo a modificar: `Services/Contracts/Controllers/BmwController.cs`
  - `[HttpGet("v1/{projectId:int}/registrations/summary-by-distributor")]`
  - **Sin `[AutoODataFilter]`** — no es una colección OData; los filtros son parámetros explícitos
    (`from`, `to`, `groupId`). `[Authorize(Policy = Policies.ICanAccessBmw)]` más
    `[EnableRateLimiting(RateLimitPolicyNames.Standard)]`
  - Mismo patrón de scope que `GetRegistrations`: `Denied` → 403; `ByProjectIds` sin acceso → 403
  - `LogRequestAsync` / `LogResponseAsync` como el resto del controlador (GET → sobrecarga de 3 args)
  - XML docs completos con `<response code>` 200/400/401/403/500
  - Criterio de completitud: responde 200 con datos; un usuario dealer recibe solo sus dealers

- [ ] **T-06** — Registrar el endpoint en KrakenD
  - Archivo a modificar: `Services/ApiGateway/krakend.json`
  - **Sin esto el endpoint da 404 en QA y PROD**, aunque el servicio esté desplegado
  - Criterio de completitud: la ruta responde a través del gateway, no solo directo al servicio

- [ ] **T-07** — Inyección de dependencias y versión del servicio
  - Registrar `IBmwRegistroSummaryService` en el `Program.cs` del servicio `Contracts`
  - Subir la versión del servicio `Contracts` con la skill `actualizar-version-servicio-gp`
  - Criterio de completitud: el servicio arranca y resuelve la dependencia

### Fase 2 — Frontend: sección de reporte (P1)

- [ ] **T-08** — Tipos y servicio de red
  - Archivos a modificar: `src/types/bmwSiga.ts`, `src/services/sigaService.ts`
  - Tipos `BmwDistributorSummaryItem` y `BmwDistributorSummary`; método
    `bmwSigaApi.getDistributorSummary(projectId, { from, to, groupId }, token)` usando el helper
    `bmwV1Url` ya existente y lanzando `ContractAuthError` en 401/403 como el resto
  - Criterio de completitud: `pnpm lint` (typecheck) limpio

- [ ] **T-09** — Ruta y navegación
  - Archivos a modificar: `src/features/warranty-registration/navigation.ts`, `src/App.tsx`
  - Paso nuevo `report` ↔ `/reporte` y `/embed/reporte`, espejando lo hecho para `users`
  - Criterio de completitud: navegar a `/reporte` monta la vista y el botón Atrás vuelve bien

- [ ] **T-10** — Vista del reporte
  - Archivo a crear: `src/features/reports/DistributorReportView.tsx`
  - Tabla: Grupo | Clave | Distribuidor | Total | Registrados | Activos | Cancelados | Pagados | Último contrato
  - Orden por total descendente por defecto, encabezados ordenables; fila de totales
  - Estados de carga, error y vacío; badges de estatus reutilizando el tono de `CreatedContractsView`
  - Criterio de completitud: los 48 dealers aparecen, incluidos los de cero, y los números cuadran
    contra la consulta SQL de T-02

- [ ] **T-11** — Filtros
  - Rango de fechas (reutilizar `DateInput`) y selector de grupo alimentado por `directory/groups`,
    que ya existe
  - El filtro viaja al servidor como parámetro; no se filtra en el cliente
  - Criterio de completitud: cambiar el rango recalcula los totales contra el servidor

- [ ] **T-12** — Montaje en el portal y acceso desde la UI
  - Archivos a modificar: `src/features/warranty-registration/RegistrationPortal.tsx`,
    `src/features/warranty-registration/views/DocumentsView.tsx`
  - Botón "Contratos por distribuidor" junto a "Ver contratos registrados", con el mismo estilo
  - Visibilidad según la decisión D-3 de la §12
  - Criterio de completitud: el botón lleva a la sección y respeta la regla de visibilidad acordada

- [ ] **T-13** — Bump de versión de la landing
  - Archivos a modificar: `.env`, `.env.qa`, `.env.production` — `VITE_APP_VERSION` de `v1.0.19` a
    `v1.0.20`, los tres en sync (regla del `CLAUDE.md` del repo)
  - Criterio de completitud: la nueva versión se ve en `VersionInfo`

### Fase 3 — Exportación y refinamientos (P2)

- [ ] **T-14** — Exportar a CSV
  - Generación en el cliente a partir de los datos ya cargados (~48 filas); sin endpoint extra
  - Nombre del archivo con el rango consultado, para que el archivo se explique solo
  - Criterio de completitud: el CSV abre en Excel con acentos correctos (BOM UTF-8) y cuadra con la tabla

- [ ] **T-15** — Resumen visual
  - Tarjetas con gran total, dealers activos frente a dealers en cero, y top 5 por volumen
  - Criterio de completitud: los números coinciden con la fila de totales de la tabla

### Fase 4 — Validación y despliegue

- [ ] **T-16** — Pruebas de scope por rol
  - Verificar con un usuario **dealer** (ve solo lo suyo, sin `unassigned`), uno de proyecto y un
    admin general
  - Criterio de completitud: los tres casos dan el recorte esperado y ninguno filtra datos ajenos

- [ ] **T-17** — Despliegue a QA
  - Skill `deploy-qa-prod`: merge de la rama a `pre-qa` y PR `pre-qa` → `qa`, en **los dos repos**
  - Redeploy del `ApiGateway` (KrakenD) además del servicio `Contracts`
  - Criterio de completitud: el reporte funciona en QA end-to-end y BMW lo valida

- [ ] **T-18** — Despliegue a PROD
  - `release` desde `develop`, mergear solo esta rama, PR a `main` y a `develop`
  - Criterio de completitud: reporte operativo en producción y el reporte manual queda retirado

---

## 5. Cambios en base de datos

**Ninguno.** El reporte se construye leyendo tablas existentes (`distribuidor`,
`grupo_distribuidor`, `contrato`, `bmw_registro`, `poliza`). No hay migraciones, tablas ni columnas
nuevas, y por lo tanto tampoco `GRANT` que aplicar.

> Si el reporte se degrada con el crecimiento previsto (ver §11 R-05), la mitigación es un índice
> sobre `contrato(id_distribuidor)` — se evalúa con datos de producción, no de forma preventiva.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `contracts/api/Bmw/v1/{projectId}/registrations/summary-by-distributor` | Conteo de contratos agrupado por distribuidor, con desgloses por estatus y modalidad. Filtros opcionales `from`, `to`, `groupId`. Recortado por scope del usuario. | Nuevo |

Respuesta (forma abreviada):

```json
{
  "items": [
    {
      "distributorId": 512,
      "dealerCode": "00047",
      "distributorName": "Vecsa Puebla",
      "groupId": 12,
      "groupName": "VECSA",
      "total": 303,
      "byStatus": { "registrado": 296, "activo": 7, "cancelado": 0 },
      "byModality": { "contado": 300, "financiado": 3, "enganche": 0, "financiamientoExterno": 0 },
      "paid": 7,
      "lastContractDate": "2026-08-17"
    }
  ],
  "totals": { "total": 1058, "distributorsWithContracts": 32, "distributorsTotal": 48 },
  "unassigned": { "total": 6 }
}
```

---

## 7. Variables de entorno y configuración

**Ninguna nueva.** El front ya cuenta con `BASE_API_PATH` y `VITE_BMW_PROJECT_ID`, que es todo lo
que necesita la sección. `VITE_APP_VERSION` cambia de valor (T-13), no se agrega.

---

## 8. Consideraciones de seguridad

- **Autorización reutilizada, no reinventada:** el endpoint usa `GetAccessScopeAsync`, el mismo
  mecanismo del listado. Un usuario dealer solo puede ver sus propios dealers; `Denied` → 403.
- **El scope se aplica en SQL**, no filtrando después en memoria ni en el cliente: el recorte no
  puede saltarse manipulando la petición.
- **Datos agregados, sin PII:** el reporte devuelve conteos por dealer. No expone clientes, VIN,
  folios ni importes, así que amplía muy poco la superficie respecto al listado que ya existe.
- **Consultas parametrizadas** con `NpgsqlParameter` en el 100% de la consulta.
- **Sin secrets nuevos**; nada que agregar a Secrets Manager.
- **Rate limiting:** política `Standard`. No corresponde `OData` porque el endpoint no lo usa.

---

## 9. Consideraciones de infraestructura

Sin servicios AWS nuevos y sin costo incremental: se agrega un endpoint a un contenedor que ya corre
en ECS + Fargate y una vista a una SPA que ya vive en S3.

Dos redespliegues obligados: el servicio **`Contracts`** y el **`ApiGateway`** (por el cambio en
`krakend.json`). Omitir el segundo deja el endpoint en 404 aunque el primero esté sano.

---

## 10. Criterios de aceptación

- [ ] La landing muestra una sección con el conteo de contratos por distribuidor
- [ ] Aparecen **los 48 dealers** del proyecto, incluidos los que tienen cero contratos
- [ ] Los totales cuadran con el listado de contratos para el mismo filtro
- [ ] Los registros sin distribuidor se reportan aparte y no descuadran la suma
- [ ] Un usuario dealer ve únicamente sus propios distribuidores
- [ ] El rango de fechas recalcula contra el servidor
- [ ] El reporte se exporta a CSV con los mismos números que la tabla
- [ ] La agrupación es por `id_distribuidor`, verificable con dos dealers de nombre parecido
- [ ] `pnpm lint` limpio en la landing y el servicio `Contracts` compila
- [ ] Versión de la landing en `v1.0.20` en los tres `.env`
- [ ] BMW valida en QA que el reporte sustituye al manual

---

## 11. Riesgos técnicos identificados

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **R-01** — Los ~1,016 contratos comprados a **Allianz** están asignados a dealers e inflan el conteo. BMW podría leer como "vendido por el dealer" lo que fue una carga masiva | Alta | Alto | Decisión D-1 (§12) **antes** de codificar. La marca existe: el folio `GP-ALLIANZ-####` los identifica |
| **R-02** — Agrupar por nombre parece funcionar hoy (32 ↔ 32) y rompe mañana | Media | Alto | Agrupar por `id_distribuidor` desde el inicio (T-02). El catálogo ya trae `VECSA` / `SONI` / `Grupo Soni` duplicados |
| **R-03** — Olvidar `krakend.json` → 404 en QA/PROD con el servicio sano, y el diagnóstico se va al servicio equivocado | Media | Medio | T-06 explícita y redeploy del ApiGateway en T-17 y T-18 |
| **R-04** — `Contracts` compila `Ventas.Domain` por `ProjectReference` a `gp_4.0_siga`: un build puede romper por causas ajenas a esta feature | Media | Medio | Compilar en limpio antes de empezar, para separar lo preexistente de lo introducido |
| **R-05** — La agregación se degrada al crecer el volumen | Baja | Medio | ~48 filas de salida y agregación en SQL. Si aparece lentitud, índice en `contrato(id_distribuidor)` |
| **R-06** — Reusar `ListAsync` "por comodidad" y arrastrar la materialización completa en memoria | Media | Medio | El plan lo prohíbe explícitamente (§3); revisar en code review |
| **R-07** — Un dealer alcanza el reporte y ve volúmenes de la competencia | Baja | Alto | El scope ya lo impide en SQL; T-16 lo verifica con un usuario dealer real, no por inspección |

---

## 12. Notas para el programador

### Decisiones de negocio a cerrar antes de ejecutar

- **D-1 — ¿Los contratos Allianz cuentan?** Son ~1,016 de los 1,064 registros: dominan cualquier
  conteo. Tres salidas: incluirlos sin distinguir, excluirlos, o mostrarlos en columna aparte
  ("cargados" frente a "vendidos en landing"). **Recomendación: columna aparte** — es la que no
  pierde información y la que evita que BMW lea mal su propio reporte. Cambia T-01, T-02 y T-10.
- **D-2 — ¿Se muestran los registros huérfanos?** Son 6 altas cuyo contrato no se completó. El plan
  los devuelve en `unassigned` para que la suma cuadre. Confirmar que BMW quiere verlos.
- **D-3 — ¿Quién ve la sección?** El backend ya recorta por scope, así que un dealer solo vería lo
  suyo — útil para él, inofensivo para los demás. Alternativa: mostrarla solo a perfiles
  corporativos, como se hizo con "Administrar usuarios". **Recomendación: visible para todos**, dado
  que el recorte es de servidor y no de UI.

### Datos verificados durante la generación del plan

Consultados por MCP sobre la base local, restaurada de un respaldo de producción — los órdenes de
magnitud son representativos; las cifras exactas de PROD hay que releerlas ahí:

| Dato | Valor |
|---|---|
| Registros BMW (proyecto 206) | 1,064 |
| Con contrato ligado | 1,058 |
| Sin distribuidor (huérfanos) | 6 |
| Dealers en el proyecto | 48 |
| Dealers con al menos un contrato | 32 |
| Estatus | Registrado 1,038 · Activo 10 · Cancelado 10 |
| Modalidad | Contado 1,038 · Financiado 18 · Enganche 5 · Financiamiento externo 3 |
| Pagados | 11 |

Que **solo 11 de 1,064 estén pagados y 10 activos** hace que una columna "activos" por sí sola
parezca vacía. Por eso la tabla lleva el desglose completo por estatus y no un único conteo.

### Notas de ejecución

- La rama nace de `develop` (`git fetch -p` → `switch develop` → `pull` → `switch -c`), en los dos
  repos. Nunca desde `pre-qa` ni `qa`.
- Un commit por tarea; presentar el cambio para validación antes de commitear.
- La landing no tiene suite de pruebas: la verificación es `pnpm lint` (typecheck) más prueba manual.
- El texto de cara al usuario va en español; el código, en inglés.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Contrato de API y SQL validado (P1)** | DTOs de respuesta, consulta de agregación probada contra datos reales | T-01 a T-02 | 1 – 1.5 días | 198 |
| **Fase 1 — Backend: endpoint agregado (P1)** | Servicio de agregación con scope, fila de huérfanos, endpoint, KrakenD, DI y versión del servicio | T-03 a T-07 | 2 – 3 días | 199 |
| **Fase 2 — Frontend: sección de reporte (P1)** | Tipos y servicio, ruta, vista con tabla y totales, filtros, montaje, bump de versión | T-08 a T-13 | 3 – 4 días | 200 |
| **Fase 3 — Exportación y refinamientos (P2)** | CSV y tarjetas de resumen | T-14 a T-15 | 1 – 2 días | 201 |
| **Fase 4 — Validación y despliegue** | Pruebas de scope por rol, QA y PROD en dos repos | T-16 a T-18 | 1 – 2 días | 202 |
| **Total proyecto (P1+P2)** | | 18 tareas | ~8 – 12.5 días hábiles (≈ 2 – 2.5 semanas) | — |
| **Solo P1 (mínimo utilizable)** | Fase 0 + Fase 1 + Fase 2 | T-01 a T-13 | ~6 – 8.5 días hábiles (≈ 1.5 semanas) | — |

> **Notas sobre la tabla:**
> - P1 abarca aquí **tres** fases, no dos: sin la Fase 2 no hay sección en la landing y el entregable
>   que BMW pidió no existe. La Fase 3 (CSV, tarjetas) sí es prescindible en un primer corte.
> - Los rangos salen de la complejidad de cada tarea. La Fase 2 domina porque incluye vista, filtros,
>   navegación y montaje.
> - Las Fases 0 a 2 son de un solo desarrollador; backend y front se solapan poco porque el contrato
>   de API se fija en la Fase 0.

> **Riesgo de deadline:** el PRD no existe, así que **no hay fecha límite comprometida** contra la
> cual contrastar. Si BMW pone una: con un desarrollador, un reporte utilizable (P1) sale en
> ~1.5 semanas y el alcance completo en ~2.5. Sumar un segundo desarrollador comprime poco — quizá
> un 20 a 25% — porque la ruta crítica es secuencial: el contrato de API condiciona backend y front.
> Si hay que recortar, se recorta la Fase 3, nunca la 0.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`, y el `CLAUDE.md` de `bmw_landing`*
