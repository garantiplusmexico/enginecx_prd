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

**Fases 0 y 1 completas — 9 de 22 tareas, 172 tests pasando.** El motor ya sabe leer los tres tipos de insumo: los Excel de facturación con mapeo por nombre de columna, los DTE del SII con su namespace y sus dos formas de declarar el monto, y el inventario de PDF. La normalización cubre el formato de moneda chileno, las fechas día-primero y las coerciones de tipo que introduce pandas.

**El I/O quedó tras una interfaz con backend local**, que es lo que permite que las Fases 2 y 3 se construyan y verifiquen enteras sin credenciales de Drive.

**El trabajo corre en local por decisión operativa.** El repo `contratos_chile` aún no existe en la organización de Engine. El historial completo —incluido el heredado— se publicará cuando se cree.

**Siguiente:** Fase 2 (T-10 a T-13A), conciliación y clasificación. Solo T-13A está bloqueada, por la credencial de Atenea Chile.

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Andamiaje y contrato de datos** | 76 | T-01 a T-04 | 1 – 2 | 2026-08-04 | 2026-08-04 | 1 | 0 | ✅ Completada |
| **Fase 1 — Normalización e ingesta** | 77 | T-05 a T-09 | 4 – 6 | 2026-08-04 | 2026-08-04 | 1 | 0 | ✅ Completada |
| **Fase 2 — Conciliación, clasificación y cruce con SIGA** | 78 | T-10 a T-13A | 5 – 6 | | | 0 | 6 | ⏳ Pendiente |
| **Fase 3 — Entregables y ejecución headless** | 79 | T-14 a T-17 | 4 – 6 | | | 0 | 6 | ⏳ Pendiente |
| **Fase 4 — Drive, datos reales y cierre** | 80 | T-18 a T-21 | 4 – 6 | | | 0 | 6 | ⏳ Pendiente |
| **Total proyecto (v1 completo)** | — | 22 tareas | ~18 – 26 | 2026-08-04 | | 2 | ~18 | 🟡 En progreso |
| **Guardarraíl — motor funcional en local** | — | T-01 a T-17 | ~14 – 20 | 2026-08-04 | | 2 | ~12 | 🟡 En progreso |

---

## 🔎 Hallazgos que requieren tu confirmación

Ninguno bloquea el desarrollo; todos tienen un comportamiento por defecto elegido conservadoramente y son parámetros o reglas que se ajustan sin reescribir código. Se listan por impacto.

| # | Hallazgo | Qué se hizo por defecto | Qué necesito |
|---|---|---|---|
| 1 | **Las facturas exentas (DTE 34) declaran el monto en `MntExe`, no en `MntNeto`.** No estaba en el PRD ni en el plan. Leer solo `MntNeto` puntuaría toda factura exenta como cero y la marcaría como que no cuadra | El parser expone ambos montos y una propiedad `base_neta` que los suma — la única cifra que significa lo mismo en los dos tipos de documento | ¿Hay facturas exentas en el histórico chileno, y en qué proporción? Si son muchas, conviene verificarlo con datos reales antes de la Fase 2 |
| 2 | **Folios duplicados entre documentos.** Dos archivos pueden reclamar el mismo folio (p. ej. `F100T33.xml` y `F100T34.xml`) | Se conserva el primero en orden alfabético y se registra el choque con `WARNING` | ¿Es la regla correcta? Alternativas razonables: preferir el tipo 33 sobre el 34, o el más reciente por fecha de emisión |
| 3 | **Varios Excel para el mismo año.** Si la carpeta tiene dos archivos que coinciden con el patrón del año | Se usa el primero alfabéticamente y se avisa | ¿Puede pasar en la práctica? Si sí, ¿cuál gana? |
| 4 | **Estructura de carpetas local asumida:** `data/insumos/{cruce,xml,pdf}` | Elegida por brevedad | ¿Prefieres que espejen los nombres de Drive (`Cruce Facturas/Contratos`, `Facturas XML`, `Facturas PDF`)? Es un cambio de una línea en `fuentes.json` |
| 5 | **Patrón de nombre de los Excel:** `*{año}*.xlsx` | Coincide con `FACTURACION AÑO 2025.xlsx` y `FACTURACION 2026.xlsx`, los dos nombres que menciona el PRD | Confirmar contra los archivos reales que no haya otras variantes |
| 6 | **El mapa de columnas del Excel está construido desde el PRD, no desde los archivos.** Es el riesgo con más probabilidad de morder en la Fase 2 | Mapeo tolerante: normaliza mayúsculas y espacios, acepta varios alias por columna, y aborta nombrando cuál falta si no encuentra folio, ID o monto | **Una muestra de insumos reales** en `data/insumos/`: un Excel de 2025, uno de 2026 y ~20 pares XML/PDF. Es el paso 5 de T-06 y T-07, que quedó sin hacer |

**Lo más valioso que puedes darme ahora es el punto 6.** Con la muestra real puedo cerrar los pasos de validación pendientes de T-06 y T-07 antes de construir la conciliación encima.

---

## Tareas completadas ✅

| ID | Tarea | Fecha | Tests | Notas |
|---|---|---|---|---|
| T-01 | Heredar el repositorio y preparar el entorno | 2026-08-04 | — | Adaptada a local. `.gitignore` heredado verificado sin cambios |
| T-02 | Extender `fuentes.json` y construir su cargador | 2026-08-04 | 10 | El último test carga el `fuentes.json` real, no solo fixtures |
| T-03 | Fixtures sintéticos y arranque de pytest | 2026-08-04 | 13 | Cinco escenarios nombrados, con su aritmética verificada |
| T-04 | Logging estructurado y contrato de exit codes | 2026-08-04 | 12 | Redacción de datos personales como filtro ejecutable |
| T-05 | Normalización de montos, folios, fechas e IDs | 2026-08-04 | 80 | Descubrimiento de la coerción `float64` de pandas |
| T-06 | Ingesta de los Excel de facturación | 2026-08-04 | 15 | openpyxl en vez de pandas, para no reintroducir la coerción |
| T-07 | Ingesta y parseo de XML (DTE SII) | 2026-08-04 | 19 | Namespace del SII; hallazgo de `MntExe` en facturas exentas |
| T-08 | Inventario de PDF | 2026-08-04 | 11 | Alcance mínimo deliberado: solo existencia |
| T-09 | `drive_io` con backend local | 2026-08-04 | 12 | Interfaz ajustada respecto del plan |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por |
|---|---|---|
| T-10 | Agrupación de contratos por folio | — |
| T-11 | Comparación de montos configurable | — |
| T-12 | Clasificación en los tres estados | — |
| T-13 | Invariante de conservación de filas y exclusiones | — |
| T-13A | Cruce contra el estado de activación en SIGA | **Credencial de Atenea Chile** |
| T-14 a T-17 | Entregables y ejecución headless | — |
| T-18, T-19 | Backend y publicación en Drive | **Credenciales de Drive** |
| T-20 | Corrida sobre datos reales y doble-cheque | **Muestra de insumos reales** |
| T-21 | README ejecutable por un tercero | — |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo | Quién resuelve |
|---|---|---|---|
| — | Publicación del código | El repo no existe en la organización de Engine | TI / Aldo |
| T-13A | Cruce con SIGA | Falta credencial de solo lectura a Atenea Chile, acotada a `ventas` | TI |
| T-18, T-19 | Drive | Método de autenticación sin definir | TI |
| T-20 | Datos reales | Falta muestra de insumos en `data/` | Andrés / Aldo |
| T-06, T-07 | Pasos de validación contra archivos reales | Misma muestra | Andrés / Aldo |

**Ninguno bloquea la Fase 2** salvo T-13A, que es su última tarea.

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Trabajar en local con las cuatro ramas, sin remoto | El repo de Engine no existe. Se respeta el propósito de la regla (nunca escribir en la rama equivocada) sin poder cumplir su letra | El código nace en la rama correcta desde el commit uno |
| Conservar los pines heredados (`pandas` 2.2.2, `lxml` 5.2.2) | Cambiar versiones y escribir código nuevo a la vez hace ambiguo cualquier fallo | Ninguno |
| No modificar el `.gitignore` heredado | Ya cubría más de lo que el plan proponía agregar | T-01 paso 3 se resolvió verificando |
| Fixtures XML en ISO-8859-1 real | Los DTE del SII usan esa codificación; el plan proponía declararla y escribir UTF-8 | El parser se prueba contra la codificación real |
| Redacción de datos personales como filtro del logger | "El logger no emite datos personales" es una regla que nadie verifica | RUT y VIN no pueden llegar al log ni por error |
| No redactar patentes | Seis alfanuméricos están demasiado cerca de identificadores legítimos | Queda como responsabilidad del punto de llamada, documentado |
| **openpyxl en vez de `pandas.read_excel`** | pandas coerce a `float64` toda columna numérica con celdas vacías — la coerción que `normalizacion.py` existe para deshacer | El contrato `1001` no se vuelve `"1001.0"`, que no coincidiría con ningún `id_contrato` en el cruce de T-13A |
| **`base_neta` = `MntNeto` + `MntExe`** | Un DTE 34 no trae `MntNeto`; su monto está en `MntExe` | La base "neto" funciona igual para facturas afectas y exentas |
| **Celda ilegible no aborta; falta de columna esencial sí** | Una celda mala no puede tumbar una corrida sobre 60 mil contratos, pero sin folio/ID/monto el archivo no es procesable y seguir daría un reporte vacío en silencio | El motor degrada con gracia y falla ruidoso solo donde importa |
| **Documento corrupto se omite; folio duplicado conserva el primero** | Consistente con lo anterior: un archivo malo no detiene el histórico, pero el choque se reporta en vez de resolverse en silencio | Ambos casos quedan visibles en el log |
| **Interfaz de `drive_io` ajustada respecto del plan** | El plan definía `listar_xml() -> list[Path]`, pero `leer_directorio_xml()` recibe un directorio | `preparar_insumos() -> RutasInsumos` es lo que los módulos realmente consumen |
| **Publicar nunca sobreescribe** | Idempotencia significa que correr dos veces da la misma respuesta, no que la segunda destruya la evidencia de la primera | Un nombre repetido recibe sufijo de hora |
| Agregar `src/configuracion.py`, fuera de la estructura del PRD | Sin él cada módulo parsearía `fuentes.json` por su cuenta | Única adición a la estructura, documentada en el plan §12 |

---

## Archivos creados o modificados

| Archivo | Tarea |
|---|---|
| `requirements.txt`, `CLAUDE.md`, `SESSION.md`, `PLAN.md`, `src/__init__.py`, `tests/__init__.py`, `tests/fixtures/__init__.py` | T-01 |
| `config/fuentes.json`, `src/configuracion.py`, `tests/test_configuracion.py` | T-02 |
| `tests/fixtures/generador.py`, `tests/conftest.py`, `tests/test_fixtures.py` | T-03 |
| `src/registro.py`, `tests/test_registro.py` | T-04 |
| `src/normalizacion.py`, `tests/test_normalizacion.py` | T-05 |
| `src/ingesta_excel.py`, `tests/test_ingesta_excel.py` | T-06 |
| `src/ingesta_xml.py`, `tests/test_ingesta_xml.py` | T-07 |
| `src/ingesta_pdf.py`, `tests/test_ingesta_pdf.py` | T-08 |
| `src/drive_io.py`, `tests/test_drive_io.py` | T-09 |

---

## Commits realizados

| Hash | Tarea | Mensaje |
|---|---|---|
| `dd6cc02` | T-01 | Preparar entorno de pruebas sobre estructura heredada |
| `f2c2bf4` | T-02 | Agregar carga y validacion de configuracion |
| `056df51` | T-03 | Agregar generadores de fixtures sinteticos |
| `6736685` | T-04 | Agregar logging y codigos de salida |
| `27a81bd` | — | Registrar avance de la Fase 0 en SESSION.md |
| `ab38473` | T-05 | Agregar normalizacion de montos folios y fechas |
| `07c7a6d` | T-06 | Agregar ingesta de Excel de facturacion |
| `c5a757b` | T-07 | Agregar parseo de DTE SII |
| `ba03881` | T-08 | Agregar inventario de PDF |
| *(pendiente)* | T-09 | Agregar abstraccion de IO con backend local |

Todos en la rama funcional local, sobre los dos commits heredados.

---

## Notas para quien retome el trabajo

**Por dónde continuar:** T-10, agrupación de contratos por folio. Es la entrada de la Fase 2 y no depende de nada externo.

**Contexto que ahorra tiempo:**

- **El formato de moneda chileno es una trampa.** `$1.234.567` son 1.234.567 pesos: el punto separa miles. Error de factor 10⁶ si se lee al revés. Ya resuelto en `normalizacion.py`, pero conviene saberlo al leer código.
- **El XML no contiene números de contrato.** Hecho estructural del que depende todo el diseño; hay un test que lo vigila.
- **El monto imponible vive en un elemento distinto según el tipo de DTE.** Usar `dte.base_neta`, nunca `dte.monto_neto` directamente, para comparar.
- **La regla ante la duda es no excluir.** Un caso indeterminado se marca y avanza; nunca se descarta en silencio.
- Los fixtures son 100% sintéticos y así deben permanecer.
- Solo `drive_io.py` toca el sistema de archivos. Si otro módulo necesita leer o escribir, va por la interfaz.

**Decisiones de negocio pendientes:** ver la sección de hallazgos arriba, más las que ya venían del PRD §14 (base de comparación neto/total, tolerancia de redondeo, exclusiones, notas de crédito, valores de `ventas.estatus`).

---

*Actualizado automáticamente por Claude Code — Engine CX*
