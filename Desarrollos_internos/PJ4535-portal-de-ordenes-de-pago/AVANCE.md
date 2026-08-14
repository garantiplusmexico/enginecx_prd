# Registro de Avance — Portal de Órdenes de Pago

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/portal-de-ordenes-de-pago-mvp` |
| Responsable actual | Aldo Álvarez |
| Folio PRD | `PJ4535` |
| ID plan (BD) | `35` |
| Última actualización | 2026-08-13 |
| Estado general | 🟡 En progreso |
| Modelo de ejecución | `claude-sonnet-5` — esfuerzo: alto |

---

## Resumen de estado

Ejecución recién iniciada. El repositorio quedó inicializado localmente con las cuatro ramas obligatorias (`main`, `develop`, `pre-qa`, `qa`) y la rama funcional `feature/portal-de-ordenes-de-pago-mvp`, con `CLAUDE.md` y `.gitignore` versionados. Ninguna tarea del plan se ha ejecutado todavía.

**El repositorio no tiene remoto.** Se inicializó local por decisión del responsable para no detener el arranque; falta crearlo en GitHub y conectar `origin` para poder publicar las ramas. Hasta entonces, todo commit de código vive únicamente en la máquina del responsable.

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

*(ninguna todavía)*

---

## Tareas en progreso 🟡

*(ninguna todavía — la ejecución arranca en T-01)*

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-01 | Crear el repositorio y las cuatro ramas obligatorias | Parcialmente hecho en local; el remoto depende de crear el repo en GitHub |
| T-02 | Solución .NET Core 8 con la estructura de carpetas de Engine | |
| T-03 | Proyecto React con layout, ruteo y cliente HTTP | |
| T-04 | PostgreSQL local y capa de acceso a datos con migraciones | |
| T-05 | Dockerfiles y composición local | |
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

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `CLAUDE.md` | Creado | Prerequisito del plan |
| `.gitignore` | Creado | T-01 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `e95ebf1` | `[portal-de-ordenes-de-pago] Inicializar repositorio con CLAUDE.md y .gitignore` | 2026-08-13 |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** T-02, la solución .NET Core 8. T-01 quedó completa salvo la publicación de las ramas en el remoto.
- **Contexto importante:** el repositorio de código vive en `Finanzas/Portal de ordenes de compra` en la máquina de Aldo Álvarez, todavía sin remoto. El PRD, el plan y este avance viven en `enginecx_prd/Desarrollos_internos/PJ4535-portal-de-ordenes-de-pago/`.
- **Decisiones pendientes que requieren input:** organización y nombre del repositorio en GitHub; consola AWS destino; fuente pública de tipo de cambio para peso colombiano y peso chileno; cuentas nominales de Google Workspace para Ilse García y Brian.
- **Lo más delicado del proyecto** es la Fase 2: las fronteras de la matriz de autorización. Un error ahí aprueba gastos en el nivel equivocado sin que nadie lo note. T-20 exige casos de prueba en ambas fronteras de cada rango de las 10 empresas.

---

*Actualizado automáticamente por Claude Code — Engine CX*
