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

Fase 0 en marcha. T-02, T-03, T-04 y T-05 completas y verificadas. `docker compose up` levanta base de datos, API y frontend, y el flujo funciona de punta a punta contra los tres contenedores reales: nginx sirve el build estático (sin artefactos del dev server), el bundle trae horneada la URL de la API, el fallback de SPA responde 200 en rutas profundas, `/health` confirma conexión real a la Postgres del contenedor `db`, y CORS funciona entre ambos contenedores. Queda solo T-06 para cerrar la Fase 0, bloqueada por la consola AWS sin definir.

**El repositorio no tiene remoto.** Se inicializó local por decisión del responsable para no detener el arranque; falta crearlo en GitHub y conectar `origin` para poder publicar las ramas. Hasta entonces, todo commit de código vive únicamente en la máquina del responsable.

**El .NET SDK 8 y PostgreSQL no estaban instalados en la máquina.** El responsable autorizó instalarlos durante la ejecución (ver Decisiones). Docker Desktop sigue sin resolverse, pendiente para T-05/T-06.

**Nota operativa:** la instalación de PostgreSQL por `winget` (en segundo plano) terminó correctamente pero el sistema no dejó registro de finalización — se verificó de forma independiente (servicio de Windows `postgresql-x64-17` en estado `Running`, puerto `5432` escuchando, `psql` conecta) antes de continuar. No se asumió que había terminado solo porque "ya debería haber terminado".

**Docker Desktop** se instaló con autorización del responsable. El primer intento falló porque requiere un diálogo de UAC interactivo que el responsable canceló por accidente; el segundo intento se completó. Docker Desktop en este equipo requería además **WSL2**, que no estaba instalado; con autorización del responsable se instaló (`wsl --install`, que a su vez necesitó una PowerShell elevada aparte porque el comando no dispara UAC por sí solo) y el responsable reinició la máquina.

**Incidente durante la verificación de T-05 (autocontenido, ya resuelto):** al diagnosticar por qué `curl` a `localhost:5173` devolvía el HTML del dev server de Vite en vez del build servido por el contenedor, se identificó mal al proceso dueño del puerto — se asumió por coincidencia de nombre (`node`) que era un servidor de desarrollo colgado de T-03, y se terminó. Eran en realidad procesos propios de Docker Desktop (`wslrelay.exe`, `com.docker.backend.exe`), y su terminación tumbó el motor completo (los tres contenedores murieron con código 255). Se relanzó Docker Desktop, se identificó correctamente al dueño real del puerto por nombre de proceso (no solo PID) antes de tocar nada, y se volvió a levantar el stack — sin pérdida de datos ni cambios de código de por medio.

**Repositorio publicado en GitHub (2026-08-19).** Mismo criterio que la cuenta AWS: no existe
namespace transversal de Engine en GitHub, solo el org `garantiplusmexico`. Con autorización del
responsable, el repo quedó publicado en dos lugares:

- **`origin`** → `https://github.com/garantiplusmexico/portal-ordenes-pago` (privado). Es el
  repositorio de trabajo real, con las reglas de rama de Engine. `main` tiene una regla de
  protección propia del org que exige un status check y una fuente específica (`release`) —
  coherente con `version-control.md`, así que **`main` no se pudo empujar directo y eso es
  correcto**, no un error a corregir. `develop`, `pre-qa`, `qa` y la rama funcional sí se
  publicaron sin problema.
- **`backup`** → `https://github.com/aldoalvarez-engine/Portal_pagos_finanzas` (del
  responsable, ya existía vacío). Recibe copia de las cinco ramas, `main` incluida, sin las
  reglas de protección del org.

A partir de ahora, cada vez que el responsable autorice un commit/push (por fase, según
`ejecutar-plan.md`), se publica en ambos remotos en el mismo paso.

**Decisión pendiente de infraestructura resuelta parcialmente — cuenta AWS destino (T-06).** No existe hoy una cuenta AWS "transversal" de Engine; `infraestructura.md` la marca como "por definir". Se investigó junto con el responsable cómo entra a la consola de AWS: no usa SSO/IAM Identity Center (se descartó tras revisar la URL real de inicio de sesión), sino un **usuario IAM clásico** en la cuenta con alias **`gplus`** (Gplus Seguros), una de las seis consolas por empresa. El responsable decidió **desplegar el MVP temporalmente en esa cuenta** (`gplus`) mientras se resuelve la cuenta transversal, aceptando que la facturación de un sistema que sirve a las 10 empresas del grupo quede mezclada con la de una sola mientras tanto. **Queda como pendiente de migración** cuando exista la cuenta transversal — no es una decisión técnica, es de Dirección/Finanzas y no debe re-litigarse por el equipo de desarrollo sin involucrarlos.

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
| T-04 | PostgreSQL local y capa de acceso a datos con migraciones | Claude Code | 2026-08-14 | PostgreSQL 17 instalado y corriendo como servicio; migración `InitialCreate` aplicada; `/health` extendido para reportar conectividad real a la base, verificado con prueba positiva y negativa |
| T-05 | Dockerfiles y composición local | Claude Code | 2026-08-14 | Docker Desktop + WSL2 instalados; `docker compose up` levanta db/api/frontend; flujo end-to-end verificado contra los contenedores reales (build estático, bundle horneado, SPA fallback, `/health` con BD real, CORS) |

---

## Tareas en progreso 🟡

*(ninguna — Fase 0 pausada en T-06, a la espera de la consola AWS)*

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
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
| `/health` reporta `databaseReachable` además de `status` | No estaba en el plan original, pero es la única forma honesta de verificar el criterio de completitud de T-04 ("la API conecta") sin escribir un endpoint desechable; además es exactamente lo que necesitará el health check del ALB en T-06 | Cambia el contrato del endpoint; se actualizó el tipo `HealthStatus` del frontend para reflejarlo |
| Instalar Docker Desktop + WSL2 durante la ejecución | No estaban presentes; Docker es obligatorio para todo despliegue nuevo de Engine (`stack.md`) | Autorizado explícitamente por el responsable en dos pasos (Docker, luego WSL2); requirió reinicio de la máquina, ejecutado por el responsable |
| `docker-compose.yml` construye imágenes de producción, no de desarrollo con hot-reload | El plan destina Docker a ECS + Fargate (T-06); usar las mismas imágenes en local que en producción reduce sorpresas al desplegar | El ciclo de edición-prueba en contenedor requiere reconstruir la imagen (`docker compose build`); el desarrollo del día a día sigue usando `dotnet run` / `npm run dev`, como en T-02/T-03/T-04 |
| `.dockerignore` en `src/Api/` y `frontend/` | Sin ellos, `COPY . .` arrastra `bin/`, `obj/` y `node_modules/` del host al contenedor y pisa lo que el propio contenedor restauró, causando errores de build no reproducibles fuera de esa máquina | Ambos builds fallaron una vez antes de agregarlos; quedan como parte permanente de la estructura del proyecto |

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
| `src/Api/Controllers/HealthController.cs` | Modificado (verifica conexión a BD) | T-04 |
| `src/Api/DTOs/Health/Responses/HealthResponse.cs` | Modificado (campo `DatabaseReachable`) | T-04 |
| `frontend/src/api/client.ts` | Modificado (`HealthStatus.databaseReachable`) | T-04 |
| `src/Api/Dockerfile` | Creado | T-05 |
| `src/Api/.dockerignore` | Creado | T-05 |
| `frontend/Dockerfile` | Creado | T-05 |
| `frontend/.dockerignore` | Creado | T-05 |
| `frontend/nginx.conf` | Creado (fallback de SPA) | T-05 |
| `docker-compose.yml` | Creado | T-05 |
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

- **Por dónde continuar:** T-06 (despliegue base en ECS + Fargate), bloqueada hasta que se defina la consola AWS de Engine transversal. Es la última tarea de la Fase 0. Nada de esto está commiteado todavía — el commit de Fase 0 se hace hasta que T-01 a T-06 estén completas, con autorización explícita del responsable (Paso 4.1 del workflow).
- **Contexto importante:** el repositorio de código vive en `Finanzas/Portal de ordenes de compra` en la máquina de Aldo Álvarez, todavía sin remoto. El PRD, el plan y este avance viven en `enginecx_prd/Desarrollos_internos/PJ4535-portal-de-ordenes-de-pago/`. Para desarrollo día a día: API en `http://localhost:5118` (`dotnet run` desde `src/Api`), frontend en `http://localhost:5173` (`npm run dev` desde `frontend`). Para probar el stack contenerizado: `docker compose up -d` desde la raíz del repo (mismos puertos); `docker compose down` para bajarlo.
- **Decisiones pendientes que requieren input:** organización y nombre del repositorio en GitHub; consola AWS destino; fuente pública de tipo de cambio para peso colombiano y peso chileno; cuentas nominales de Google Workspace para Ilse García y Brian.
- **Cuidado al identificar procesos por puerto en esta máquina:** durante T-05 se mató por error el propio motor de Docker Desktop (`wslrelay.exe`, `com.docker.backend.exe`) al confundirlo con un servidor de desarrollo colgado, solo por coincidencia de nombre de proceso (`node`). Se resolvió relanzando Docker Desktop, sin pérdida de datos. Antes de terminar un proceso por ocupar un puerto, identificarlo por nombre real (`Get-Process -Id <pid>`), no solo por PID.
- **Lo más delicado del proyecto** es la Fase 2: las fronteras de la matriz de autorización. Un error ahí aprueba gastos en el nivel equivocado sin que nadie lo note. T-20 exige casos de prueba en ambas fronteras de cada rango de las 10 empresas.

---

*Actualizado automáticamente por Claude Code — Engine CX*
