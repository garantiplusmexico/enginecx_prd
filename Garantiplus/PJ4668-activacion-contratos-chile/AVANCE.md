# Registro de Avance — Activación de Contratos Chile (`contratos_chile`)

> Este documento lo actualiza Claude Code conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/activacion-contratos-chile-motor-v1` |
| Responsable actual | Aldo Álvarez |
| Folio PRD | **PJ4668** |
| ID plan (BD) | **34** (`pm_plan_desarrollo.id`) |
| Última actualización | 2026-08-04 |
| Estado general | 🟡 En progreso |

---

## Resumen de estado

**Fase 0 completa.** El repositorio local hereda el historial del repo original, tiene las cuatro ramas de Engine y la rama funcional, con el entorno verificado (Python 3.12.7, cuatro dependencias en sus versiones pinneadas). Se construyeron el cargador de configuración, los generadores de fixtures sintéticos y el logging con códigos de salida diferenciados. **35 tests pasando.**

**El trabajo corre en local por decisión operativa.** El repo `contratos_chile` aún no existe en la organización de Engine, así que no hay remoto al que pushear. El historial completo —incluido el del repo original— se publicará cuando se cree. Nada se pierde ni se rehace.

**Siguiente:** Fase 1 (T-05 a T-09), normalización e ingesta. No depende de credenciales.

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Andamiaje y contrato de datos** | 76 | T-01 a T-04 | 1 – 2 | 2026-08-04 | 2026-08-04 | 1 | 0 | ✅ Completada |
| **Fase 1 — Normalización e ingesta** | 77 | T-05 a T-09 | 4 – 6 | | | 0 | 6 | ⏳ Pendiente |
| **Fase 2 — Conciliación, clasificación y cruce con SIGA** | 78 | T-10 a T-13A | 5 – 6 | | | 0 | 6 | ⏳ Pendiente |
| **Fase 3 — Entregables y ejecución headless** | 79 | T-14 a T-17 | 4 – 6 | | | 0 | 6 | ⏳ Pendiente |
| **Fase 4 — Drive, datos reales y cierre** | 80 | T-18 a T-21 | 4 – 6 | | | 0 | 6 | ⏳ Pendiente |
| **Total proyecto (v1 completo)** | — | 22 tareas | ~18 – 26 | 2026-08-04 | | 1 | ~25 | 🟡 En progreso |
| **Guardarraíl — motor funcional en local** | — | T-01 a T-17 | ~14 – 20 | 2026-08-04 | | 1 | ~19 | 🟡 En progreso |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Heredar el repositorio en Engine y preparar el entorno | Claude Code | 2026-08-04 | Adaptada a local: sin remoto todavía. `.gitignore` heredado verificado sin cambios — ya cubría más de lo que pedía el plan |
| T-02 | Extender `fuentes.json` y construir su cargador | Claude Code | 2026-08-04 | 10 tests. El último carga el `fuentes.json` real del repo, no solo fixtures |
| T-03 | Fixtures sintéticos y arranque de pytest | Claude Code | 2026-08-04 | 13 tests. Cinco escenarios nombrados; los tests verifican que su aritmética es la que su nombre promete |
| T-04 | Logging estructurado y contrato de exit codes | Claude Code | 2026-08-04 | 12 tests. Redacción de datos personales como filtro ejecutable, no como regla de buena conducta |

---

## Tareas en progreso 🟡

*(ninguna — Fase 0 cerrada, Fase 1 sin arrancar)*

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-05 | Normalización de montos, folios, fechas e IDs | — |
| T-06 | Ingesta de los Excel de facturación | Validación contra archivo real requiere muestra de insumos |
| T-07 | Ingesta y parseo de XML (DTE SII) | Validación contra XML real requiere muestra de insumos |
| T-08 | Inventario de PDF | — |
| T-09 | `drive_io` con backend local | — |
| T-10 | Agrupación de contratos por folio | — |
| T-11 | Comparación de montos configurable | — |
| T-12 | Clasificación en los tres estados | — |
| T-13 | Invariante de conservación de filas y exclusiones | — |
| T-13A | Cruce contra el estado de activación en SIGA | **Credencial de solo lectura a Atenea Chile** |
| T-14 a T-17 | Entregables y ejecución headless | — |
| T-18, T-19 | Backend y publicación en Drive | **Credenciales de Google Drive** |
| T-20 | Corrida sobre datos reales y doble-cheque | **Muestra de insumos reales** |
| T-21 | README ejecutable por un tercero | — |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| — | Publicación del código | El repo `contratos_chile` no existe en la organización de Engine | TI / Aldo |
| T-13A | Cruce contra estado de activación | Falta credencial de solo lectura a Atenea Chile, acotada a `ventas` | TI |
| T-18, T-19 | Drive | Método de autenticación sin definir (cuenta de servicio vs. OAuth) | TI |
| T-20 | Datos reales | Falta muestra de insumos en `data/` | Andrés / Aldo |

Ninguno bloquea la Fase 1. El desarrollo puede continuar hasta T-13 sin resolver nada de lo anterior.

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Trabajar en local con las cuatro ramas creadas, sin remoto | El repo de Engine no existe todavía. Los pasos 1 y 2 del workflow exigen `pull`/`push` contra un remoto; se respeta el propósito de la regla (nunca escribir en la rama equivocada) sin poder cumplir su letra | El código nace en la rama correcta desde el commit uno. Al crear el repo se agrega el remoto y se pushea todo, historial heredado incluido |
| Conservar los pines heredados (`pandas` 2.2.2, `lxml` 5.2.2) en vez de los del plan | Cambiar versiones y escribir código nuevo en la misma tarea hace que un fallo sea ambiguo entre las dos causas | Ninguno: las cuatro dependencias instalan e importan bien bajo Python 3.12.7 |
| No modificar el `.gitignore` heredado | Ya cubría `data/`, `config/config.ini`, credenciales, `.venv/` y `.pytest_cache/` — más de lo que el plan proponía agregar | T-01 paso 3 se resolvió verificando, no editando |
| Escribir los fixtures XML en **ISO-8859-1 real** | El plan proponía declarar ISO-8859-1 y escribir UTF-8. Los DTE del SII son ISO-8859-1; la inconsistencia habría dejado sin ejercitar la codificación real | El parser de T-07 se prueba contra la codificación que recibirá en producción |
| Redacción de datos personales como **filtro del logger**, no como convención | El criterio decía "el logger no emite datos personales", pero eso nadie lo verifica: basta una fila de dataframe interpolada. Se procesan RUT de personas reales y los logs sobreviven a la corrida | Un error en cualquier módulo no puede filtrar un RUT o VIN. Folios, montos y estados pasan intactos |
| No redactar patentes | El formato chileno son seis alfanuméricos, demasiado cerca de identificadores legítimos; sobre-redactar se comería los datos operativos | Mantener patentes fuera de los mensajes de log queda como responsabilidad del punto de llamada, documentado en el módulo |
| Agregar `src/configuracion.py`, fuera de la estructura del PRD | Sin él cada módulo parsearía `fuentes.json` por su cuenta | Única adición a la estructura especificada, documentada en el plan §12 |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `requirements.txt` | Modificado | T-01 |
| `CLAUDE.md` | Modificado (fusión) | T-01 |
| `src/__init__.py`, `tests/__init__.py`, `tests/fixtures/__init__.py` | Creados | T-01 |
| `SESSION.md`, `PLAN.md` | Creados | T-01 |
| `config/fuentes.json` | Modificado | T-02 |
| `src/configuracion.py` | Creado | T-02 |
| `tests/test_configuracion.py` | Creado | T-02 |
| `tests/fixtures/generador.py` | Creado | T-03 |
| `tests/conftest.py` | Creado | T-03 |
| `tests/test_fixtures.py` | Creado | T-03 |
| `src/registro.py` | Creado | T-04 |
| `tests/test_registro.py` | Creado | T-04 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `dd6cc02` | `[activacion-contratos-chile] Preparar entorno de pruebas sobre estructura heredada` | 2026-08-04 |
| `f2c2bf4` | `[activacion-contratos-chile] Agregar carga y validacion de configuracion` | 2026-08-04 |
| `056df51` | `[activacion-contratos-chile] Agregar generadores de fixtures sinteticos` | 2026-08-04 |
| `6736685` | `[activacion-contratos-chile] Agregar logging y codigos de salida` | 2026-08-04 |

Los cuatro viven en la rama funcional local, sobre los dos commits heredados del repo original.

---

## Notas para quien retome el trabajo

**Por dónde continuar:** T-05, normalización de montos, folios, fechas e IDs. Es la tarea de mayor densidad de casos límite del proyecto y no depende de nada externo. El plan trae el test parametrizado completo.

**Contexto importante:**

- **El formato de moneda chileno es una trampa.** `$1.234.567` son 1.234.567 pesos: el punto separa miles, no decimales. Confundirlo es un error de factor 10⁶. El generador de fixtures ya usa el formato real.
- **El XML no contiene números de contrato.** Es el hecho estructural del que depende todo el diseño; hay un test que lo vigila (`test_invoice_detail_carries_no_contract_numbers`). Cualquier diseño que asuma lo contrario es inviable.
- **La regla ante la duda es no excluir.** Aplica al cruce de T-13A y en general: un caso indeterminado se marca y avanza, nunca se descarta en silencio.
- Los fixtures son 100% sintéticos y así deben permanecer. Ningún dato real entra al repositorio, ni siquiera como fixture.

**Decisiones pendientes que requieren input del equipo:**

- Qué valores de `ventas.estatus` cuentan como "activo" (se cierra en T-13A).
- Si los montos del Excel son netos o incluyen IVA (se cierra en T-20 con datos).
- Tolerancia de redondeo aceptable en la conciliación.
- Qué líneas excluir por no ser garantías, y cómo tratar las notas de crédito.

---

*Actualizado automáticamente por Claude Code — Engine CX*
