# Registro de Avance — Portal de Órdenes de Pago

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/portal-de-ordenes-de-pago-mvp` |
| Responsable actual | Aldo Álvarez |
| Folio PRD | `PJ4535` |
| ID plan (BD) | `35` |
| Última actualización | 2026-08-14 |
| Estado general | 🟡 En progreso |
| Modelo de ejecución | `claude-sonnet-5` — esfuerzo: alto |

---

## Resumen de estado

Fase 0 en marcha. T-02 (API .NET Core 8) y T-03 (frontend React) están completas y verificadas con servidores reales corriendo, compilando y comunicándose entre sí por CORS. T-04 (PostgreSQL) está a medio camino: el SDK de .NET, EF Core, el `DbContext` y la migración inicial ya existen y compilan; falta un PostgreSQL vivo para correr `dotnet ef database update` — su instalación está en curso.

**El repositorio no tiene remoto.** Se inicializó local por decisión del responsable para no detener el arranque; falta crearlo en GitHub y conectar `origin` para poder publicar las ramas. Hasta entonces, todo commit de código vive únicamente en la máquina del responsable.

**El .NET SDK 8 y PostgreSQL no estaban instalados en la máquina.** El responsable autorizó instalarlos durante la ejecución (ver Decisiones). Docker Desktop sigue sin resolverse, pendiente para T-05/T-06.

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Andamiaje e infraestructura** | `84` | T-01 a T-06 | 6 – 9 | | | 0 | 9 | ⏳ Pendiente |
| **Fase 1 — Identidad, catálogos y modelo (P1)** | `85` | T-07 a T-13 | 8 – 11 | | | 0 | 11 | ⏳ Pendiente |
| **Fase 2 — Motor de reglas y moneda (P1)** | `86` | T-14 a T-20 | 9 – 12 | | | 0 | 12 | ⏳ Pendiente |
| **Fase 3 — Ciclo de la solicitud (P1)** | `87` | T-21 a T-28 | 12 – 16 | | | 0 | 16 | ⏳ Pendiente |
| **Fase 4 — Notificaciones, histórico y consulta (P1)** | `88` | T-29 a T-34 | 9 – 12 | | | 0 | 12 | ⏳ Pendiente |
| **Fase 5 — Administración, calidad y producción** | `89` | T-35 a T-40 | 7 – 10 | | | 0 | 10 | ⏳ Pendiente |
| **Total proyecto (MVP completo)** | — | 40 tareas | ~51 – 70 | 2026-08-13 | | 0 | 70 | 🟡 En progreso |
| **Solo P1 (guardarraíl del PRD)** | — | T-01 a T-13 | ~14 – 20 | | | 0 | 20 | ⏳ Pendiente |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-02 | Solución .NET Core 8 con la estructura de carpetas de Engine | Claude Code | 2026-08-14 | API real levantada en local; `/health` responde 200 `{"status":"ok"}` |
| T-03 | Proyecto React con layout, ruteo y cliente HTTP | Claude Code | 2026-08-14 | Vite real levantado en local; verificadas las 5 rutas y CORS end-to-end contra la API real |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| T-04 | PostgreSQL local y capa de acceso a datos con migraciones | Claude Code | 2026-08-14 | Paquetes, `AppDbContext` y migración `InitialCreate` listos y compilando. Falta un PostgreSQL vivo para `database update` — instalación en curso |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-05 | Dockerfiles y composición local | Docker Desktop no está instalado; decisión pendiente del responsable |
| T-06 | Despliegue base en ECS + Fargate para desarrollo | Consola AWS de Engine transversal sin definir |
| T-07 a T-13 | Fase 1 — Identidad, catálogos y modelo de datos | |
| T-14 a T-20 | Fase 2 — Motor de reglas y conversión de moneda | Fuente de tipo de cambio para COP y CLP sin definir (afecta solo a T-18) |
| T-21 a T-28 | Fase 3 — Ciclo de vida de la solicitud | |
| T-29 a T-34 | Fase 4 — Notificaciones, histórico y consulta | |
| T-35 a T-40 | Fase 5 — Administración, calidad y producción | T-40 requiere cuentas nominales de Ilse García y Brian |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| T-01 *(parcial)* | Publicar las ramas en el remoto | El repositorio no existe en GitHub; falta definir organización y nombre | Aldo Álvarez |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Inicializar el repositorio en local sin remoto | El repositorio en GitHub no existía y el responsable pidió arrancar de inmediato; detenerse habría bloqueado toda la ejecución | Los commits de código no son visibles para el equipo hasta que se cree el remoto y se publiquen las ramas |
| Excluir del control de versiones los insumos del PRD (`Pagos.csv`, `Aprobadores.csv`, la política y el `.xlsx`) | Su fuente de verdad es `enginecx_prd`; además `Aprobadores.csv` contiene correos de personas identificables | En T-11 los datos de seed se incorporan en su propia ruta bajo `src/Api/Data/Seed/`, no desde la raíz del repo |
| Instalar el SDK de .NET 8 durante la ejecución (winget) | No estaba presente en la máquina y es obligatorio para todo backend nuevo de Engine | Autorizado explícitamente por el responsable antes de instalar |
| `/health` sin `[Authorize]` y sin versionar (`v1/...`) | Es un endpoint de infraestructura consumido por el ALB y por el frontend antes de que exista sesión; exigir versión y auth ahí no aporta y rompe el patrón de probes | Ninguno de los demás endpoints del portal sigue esta excepción — todos los de negocio sí llevan `v1/` y `[Authorize]` |
| CORS restringido por configuración (`Cors:AllowedOrigins`), no `AllowAny` | `coding-guidelines.md` exige CORS restrictivo; el origen de desarrollo (`localhost:5173`) vive en `appsettings.Development.json`, no hardcodeado en código | QA y producción deberán definir su propio origen permitido antes de desplegar |
| Instalar PostgreSQL nativo en vez de esperar a Docker (T-05) | El responsable eligió resolver T-04 sin depender de la decisión de Docker, que sigue abierta | Desacopla T-04 de T-05/T-06; cuando se instale Docker, T-05 apuntará el `docker-compose` a un Postgres en contenedor, independiente de este local |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `CLAUDE.md` | Creado | Prerequisito del plan |
| `.gitignore` | Creado | T-01 |
| `PortalOrdenesPago.sln` | Creado | T-02 |
| `src/Api/Api.csproj` | Creado | T-02 |
| `src/Api/Program.cs` | Creado | T-02, T-04 |
| `src/Api/Controllers/HealthController.cs` | Creado | T-02 |
| `src/Api/DTOs/Health/Responses/HealthResponse.cs` | Creado | T-02 |
| `src/Api/Options/CorsOptions.cs` | Creado | T-02 |
| `src/Api/appsettings.json` | Creado (scaffold) | T-02 |
| `src/Api/appsettings.Development.json` | Modificado | T-02, T-04 |
| `src/Api/Data/AppDbContext.cs` | Creado | T-04 |
| `src/Api/Migrations/20260814151728_InitialCreate.cs` | Creado | T-04 |
| `frontend/` (Vite + React + TypeScript, scaffold completo) | Creado | T-03 |
| `frontend/src/api/client.ts` | Creado | T-03 |
| `frontend/src/layout/AppLayout.tsx` | Creado | T-03 |
| `frontend/src/routes/` (Login, Inbox, Search, RequestDetail, NotFound) | Creado | T-03 |
| `frontend/src/index.css` | Modificado (limpiado el estilo de marketing del scaffold) | T-03 |
| `frontend/.env.example` | Creado | T-03 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `e95ebf1` | `[portal-de-ordenes-de-pago] Inicializar repositorio con CLAUDE.md y .gitignore` | 2026-08-13 |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** cerrar T-04 en cuanto PostgreSQL termine de instalarse (`dotnet ef database update` desde `src/Api`), luego decidir Docker para T-05/T-06. Nada de esto está commiteado todavía — el commit de Fase 0 se hace hasta que T-01 a T-06 estén completas, con autorización explícita del responsable (Paso 4.1 del workflow).
- **Contexto importante:** el repositorio de código vive en `Finanzas/Portal de ordenes de compra` en la máquina de Aldo Álvarez, todavía sin remoto. El PRD, el plan y este avance viven en `enginecx_prd/Desarrollos_internos/PJ4535-portal-de-ordenes-de-pago/`. La API corre en `http://localhost:5118` (perfil `http`), el frontend en `http://localhost:5173`.
- **Decisiones pendientes que requieren input:** organización y nombre del repositorio en GitHub; Docker Desktop sí/no para T-05/T-06; consola AWS destino; fuente pública de tipo de cambio para peso colombiano y peso chileno; cuentas nominales de Google Workspace para Ilse García y Brian.
- **Lo más delicado del proyecto** es la Fase 2: las fronteras de la matriz de autorización. Un error ahí aprueba gastos en el nivel equivocado sin que nadie lo note. T-20 exige casos de prueba en ambas fronteras de cada rango de las 10 empresas.

---

*Actualizado automáticamente por Claude Code — Engine CX*
