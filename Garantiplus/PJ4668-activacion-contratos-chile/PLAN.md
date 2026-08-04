# Plan de Desarrollo — Motor de Activación de Contratos Chile (`contratos_chile` v1)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

> **Para ejecución asistida:** usar `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar tarea por tarea. Los pasos usan sintaxis de checkbox (`- [ ]`) para seguimiento. Cada tarea sigue TDD: test que falla → implementación mínima → test que pasa → commit.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Garantiplus/PJ4668-activacion-contratos-chile/PRD.md` (v1.1) |
| Repositorio | `contratos_chile` — **repo nuevo en la organización de Engine**, heredando el contenido del repo privado de Iván Carreto |
| Rama | `feature/activacion-contratos-chile-motor-v1` |
| Tipo | **Proyecto nuevo en Engine**, con trabajo previo heredado (ver §2.1) |
| Responsable | Aldo Álvarez |
| Folio PRD | **PJ4668** |
| Fecha de generación | 2026-08-04 |
| Estado | Borrador |
| ID plan (BD) | *(lo escribe el flujo al registrar el plan)* |

---

## 1. Resumen técnico

Se construye desde cero un **motor de datos headless en Python** que consolida los insumos del despacho contable chileno y produce tres entregables que alimentan al RPA de órdenes de pago (Omar) y a la inyección de facturas de TI.

**Componentes que se crean** (todos nuevos — no hay código existente):

| Módulo | Responsabilidad |
|---|---|
| `configuracion.py` | Carga y valida `fuentes.json` + `config.ini` |
| `normalizacion.py` | Montos, folios, fechas, IDs — sin dependencias de otros módulos |
| `ingesta_excel.py` | Lee los Excel de facturación, mapeo por nombre de columna |
| `ingesta_xml.py` | Parsea DTE SII (TipoDTE 33/34/61) con `lxml` |
| `ingesta_pdf.py` | Inventario de PDF disponibles como evidencia |
| `drive_io.py` | I/O con dos backends tras una interfaz: `local` y `drive` |
| `validacion.py` | Conciliación Excel↔XML por folio → 3 estados |
| `entregables.py` | Genera `feed_rpa.csv`, `lista_ti.csv`, `reporte_validacion.xlsx` |
| `main.py` | Punto de entrada headless, orquestación, exit codes |

**Arquitectura:** flujo automatizado sin UI (ver §3). **Stack:** Python 3.11+, `pandas`, `openpyxl`, `lxml`. Sin backend HTTP, sin base de datos, sin frontend. Despliegue en v3 vía n8n.

**Desviación de `rules/stack.md`:** el default obligatorio de Engine para backend nuevo es .NET Core 8. Este proyecto usa Python. Justificación en §12.

---

## 2. Prerequisitos

- [x] PRD validado y publicado en `enginecx_prd` como **PJ4668** (v1.1, normalizado a las 14 secciones de Engine)
- [x] Folio del PRD asignado para registro en base de datos
- [ ] **Repo `contratos_chile` creado en la organización de Engine**, heredando el contenido del repo privado de Iván (ver §2.1), con las cuatro ramas obligatorias `main` / `develop` / `pre-qa` / `qa` — **bloqueante: sin esto no se puede crear la rama funcional**
- [ ] Python 3.11+ instalado en la máquina de desarrollo
- [ ] **Muestra de insumos reales** copiada a `data/` local: al menos un `FACTURACION AÑO 2025.xlsx`, un `FACTURACION 2026.xlsx`, y ~20 pares XML/PDF. Necesaria desde la Fase 1 para validar el mapeo de columnas real.
- [ ] Credenciales de Google Drive — **solo bloquean la Fase 4**, no las anteriores (por eso `drive_io.py` se construye con backend local primero)

### 2.1 Trabajo previo heredado

Existe un repositorio privado del desarrollador (`ivancarreto-BI/contratos_chile`) con dos commits que ya resuelven parte de la Fase 0. **No es un repo de la organización de Engine** — de ahí que el proyecto sea nuevo en términos de Engine aunque exista trabajo previo. Lo que se hereda:

| Artefacto | Estado | Efecto en el plan |
|---|---|---|
| Estructura completa de carpetas (PRD §11) | Completa | T-01 se reduce a verificar y crear ramas |
| `.gitignore` | Completo — excluye `data/` y `config/config.ini` | T-01 paso 2 resuelto |
| `requirements.txt` | Pinneado: `pandas==2.2.2`, `openpyxl==3.1.5`, `lxml==5.2.2` | T-01 paso 3 resuelto. **Se adoptan estos pines**, no los del plan original |
| `config/fuentes.json` | Completo, **con los cuatro IDs reales de carpeta de Drive** | T-02 se reduce a extenderlo |
| `config/config.example.ini` | Completo | T-02 paso 2 resuelto |
| `CLAUDE.md` | 61 líneas | Se fusiona con el ampliado (decisiones, stack, protocolo de sesiones) |
| `README.md` | Presente, pendiente de completar en T-21 | — |
| `docs/transcript_..._2026_06_23.md` | 540 líneas | Ya incorporado al PRD y a `enginecx_prd` |
| `src/` | **Vacío** (solo `.gitkeep`) | **Todo el código sigue pendiente: T-05 a T-21 sin cambios** |
| Ramas | Solo `main`, 2 commits | Faltan `develop`, `pre-qa`, `qa` |

El `fuentes.json` heredado aporta además tres cosas que el plan original no contemplaba: `rut_emisor_esperado` (`77320456-K`) como control de validación, los patrones concretos de exclusión (`REPARACION MOTOR`, `COTIZACION`, `CAMBIO BOBINA`) y el criterio documentado de "tiene factura emitida". **Lo que le falta es la palanca `base_comparacion` neto/total** — el riesgo del IVA sigue abierto y se resuelve en T-02 y T-20.

---

## 3. Arquitectura del cambio

El árbol de decisión de `rules/arquitectura.md` enruta este proyecto de forma inequívoca:

```
¿Tiene múltiples dominios de negocio independientes?  → No
¿Necesita base de datos?                              → No
¿Es un flujo automatizado sin UI?                     → Sí → N8N
```

En **v1 el motor corre como script local**; la orquestación n8n llega en v3. El diseño headless (sin sesión interactiva, exit code ≠ 0 ante fallo, log estructurado) es precisamente lo que hace que v3 sea un cambio de invocación y no un rediseño.

### Flujo de datos

```
Google Drive (insumos)
   │  Cruce Facturas/Contratos → FACTURACION AÑO 2025.xlsx, FACTURACION 2026.xlsx
   │  Facturas XML             → F{folio}T33.xml
   │  Facturas PDF             → F{folio}T33.pdf
   ↓
[drive_io: descarga] → data/insumos/
   ↓
[ingesta_excel] ──┐
[ingesta_xml]   ──┼→ [normalizacion] → [validacion: conciliación POR FOLIO]
[ingesta_pdf]   ──┘                          ↓
                              CUADRA / NO_CUADRA / NO_VERIFICABLE
                                             ↓
                                      [entregables]
                        ┌────────────────────┼────────────────────┐
                   feed_rpa.csv        lista_ti.csv     reporte_validacion.xlsx
                    (1 fila =           (1 fila =            (5 hojas)
                     1 contrato)         1 factura)
                                             ↓
                        [drive_io: publicación] → Drive/Resultados_Motor/
```

### La restricción que gobierna el diseño

El `Detalle` del XML **no contiene números de contrato** (PRD §4.2): una línea consolidada dice `QtyItem = 8 UNID` sin desglosar. Por eso:

- El Excel es **fuente de verdad única** del mapeo contrato↔factura.
- La conciliación es **agregada por folio**, nunca por contrato.
- `validacion.py` compara `∑(montos de contratos del Excel para el folio X)` contra el monto del XML de ese folio.

### Dirección de dependencias

```
main.py
  ├→ configuracion.py
  ├→ drive_io.py ──→ configuracion
  ├→ ingesta_{excel,xml,pdf}.py ──→ normalizacion
  ├→ validacion.py ──→ normalizacion
  └→ entregables.py
```

`normalizacion.py` no importa nada del proyecto. `validacion.py` no hace I/O. Ambos son puramente funcionales y testeables sin fixtures de archivo — es lo que permite que el 80% de los tests corran en milisegundos.

---

## 4. Tareas de desarrollo

**Convención TDD para todas las tareas:** escribir el test que falla → correrlo y ver que falla → implementación mínima → correrlo y ver que pasa → commit. Los comandos de test asumen `pytest` desde la raíz del repo.

**Regla transversal de datos sensibles:** ningún test usa datos reales. Todos los fixtures son **sintéticos** y viven en `tests/fixtures/`. Los insumos reales viven en `data/`, fuera de git.

---

### Fase 0 — Andamiaje y contrato de datos

#### T-01 — Heredar el repositorio en Engine y preparar el entorno

**Naturaleza de la tarea:** no se construye desde cero. La estructura, el `.gitignore`, el `requirements.txt` y los archivos de configuración **ya existen** en el repo privado de Iván (§2.1). Esta tarea los traslada a la organización de Engine, los verifica y completa lo que falta.

**Archivos:**
- Heredar: todo el contenido de `ivancarreto-BI/contratos_chile`
- Crear: `src/__init__.py`, `tests/__init__.py`, `tests/fixtures/`
- Modificar: `requirements.txt` (agregar `pytest`)

**Pasos:**

- [ ] **1.** Crear el repositorio `contratos_chile` en la organización de Engine e importar el contenido del repo de Iván, preservando su historial.
- [ ] **2.** Crear las cuatro ramas obligatorias de `rules/version-control.md`: `main`, `develop`, `pre-qa`, `qa`. Configurar `develop` como rama base de las funcionales.
- [ ] **3.** Verificar el `.gitignore` heredado: confirmar que excluye `data/` (salvo `.gitkeep`) y `config/config.ini`. Agregar `.pytest_cache/` y `.venv/` si no están.
- [ ] **4.** Agregar `pytest` al `requirements.txt` heredado, **conservando los pines existentes** (`pandas==2.2.2`, `openpyxl==3.1.5`, `lxml==5.2.2`). No actualizar versiones en esta tarea: cambiar pines y escribir código nuevo a la vez hace que un fallo sea ambiguo entre las dos causas.

```
pytest==8.3.4
```

- [ ] **5.** Crear `src/__init__.py`, `tests/__init__.py` y `tests/fixtures/` (la estructura de carpetas ya existe; faltan los paquetes de Python).
- [ ] **6.** Verificar que el entorno instala limpio: `python -m venv .venv && .venv/Scripts/pip install -r requirements.txt`
- [ ] **7.** Crear la rama funcional desde `develop` actualizado:

```bash
git checkout develop && git pull origin develop
git checkout -b feature/activacion-contratos-chile-motor-v1
git push origin feature/activacion-contratos-chile-motor-v1
```

- [ ] **8.** Commit: `[activacion-contratos-chile] Preparar entorno de pruebas sobre estructura heredada`

**Criterio de completitud:** el repo vive en la organización de Engine con las cuatro ramas; `pip install -r requirements.txt` termina sin error; `git status` no muestra nada bajo `data/`; la rama funcional existe en el remoto.

---

#### T-02 — Extender `fuentes.json` y construir su cargador

**Naturaleza de la tarea:** `config/fuentes.json` y `config/config.example.ini` **ya existen** y están bien construidos (§2.1). Esta tarea les agrega lo que falta y construye el cargador tipado que el resto del motor consume.

**Archivos:**
- Modificar: `config/fuentes.json` (agregar `base_comparacion` y `backend`)
- Crear: `src/configuracion.py`
- Test: `tests/test_configuracion.py`

**Interfaces producidas:**
- `cargar_configuracion(ruta: Path) -> Configuracion` — objeto con acceso tipado a todos los parámetros.
- `Configuracion.base_comparacion: str` (`"neto"` | `"total"`), `.tolerancia_pesos: int`, `.anios: list[int]`, `.tipos_dte_validos: list[int]`, `.rut_emisor_esperado: str`, `.patrones_exclusion: list[str]`, `.backend: str` (`"local"` | `"drive"`), `.ids_drive: dict[str, str]`.

**Lo que se agrega al `fuentes.json` heredado**, dentro de `reglas_validacion` y en la raíz:

```json
"reglas_validacion": {
  "base_comparacion": "neto",
  "_nota_base": "neto | total. El MntTotal del DTE incluye IVA; los montos del Excel parecen ser netos. Comparar contra la base equivocada marca ~100% de facturas como NO_CUADRA por el 19%. Se confirma con datos reales en T-20.",
  "tolerancia_monto_pesos": 1,
  "estados": ["CUADRA", "NO_CUADRA", "NO_VERIFICABLE"]
},
"backend": "local",
"_nota_backend": "local (desarrollo y pruebas) | drive (produccion). Ver drive_io.py."
```

El cargador debe leer el **esquema real del archivo heredado** —`drive.subcarpetas.*_id`, `procesamiento.anios_a_procesar`, `procesamiento.rut_emisor_esperado`, `procesamiento.tipos_dte_validos`, `reglas_validacion.tolerancia_monto_pesos`, `exclusiones.patrones_descripcion_excluir`, `salida.*`— y **ignorar las llaves que empiezan con `_`**, que son notas de documentación embebidas y no configuración.

> **Nota de desviación del PRD §11:** se añade `src/configuracion.py`, que no está en la estructura del PRD. Sin él, cada módulo tendría que parsear `fuentes.json` por su cuenta o `main.py` tendría que inyectar parámetros sueltos por todas partes. Es un módulo de 40 líneas que evita duplicación; se documenta aquí para que quede registrado como decisión, no como omisión.

**Pasos:**

- [ ] **1.** Editar el `config/fuentes.json` heredado agregando las dos llaves que le faltan (bloque de arriba): `reglas_validacion.base_comparacion` con default `"neto"` y su nota, y `backend` en la raíz con default `"local"`. **No reescribir el archivo**: conservar los IDs de Drive, el `rut_emisor_esperado`, los patrones de exclusión y las notas `_` que ya trae.
- [ ] **2.** Agregar a `config/config.example.ini` la llave `data_dir` si no está, y verificar que el resto de las llaves heredadas siguen documentadas con valor vacío. No se toca nada más: el archivo ya está bien construido.

  Sobre las exclusiones: el archivo heredado ya trae `patrones_descripcion_excluir` con tres patrones concretos (`REPARACION MOTOR`, `COTIZACION`, `CAMBIO BOBINA`) y `excluir_lineas_con_orden_de_compra: false`. Se conservan tal cual. La decisión de negocio sigue abierta (PRD §14) y se cierra con datos en T-20; hasta entonces el comportamiento conservador es **reportar los excluidos en su hoja, no descartarlos en silencio**.

- [ ] **3.** Escribir el test que falla. **Los fixtures deben usar el esquema real del archivo heredado**, no un esquema inventado, o el cargador pasará los tests y fallará contra el archivo de producción:

```python
# tests/test_configuracion.py
from pathlib import Path
import json
import pytest
from src.configuracion import cargar_configuracion

# Esquema real del fuentes.json heredado, recortado a lo que el cargador consume.
BASE = {
    "_comentario": "las llaves que empiezan con _ son notas y deben ignorarse",
    "drive": {
        "carpeta_raiz_id": "1DyUt...",
        "subcarpetas": {
            "cruce_facturas_contratos_id": "1NfAC...",
            "facturas_xml_id": "1SqC2...",
            "facturas_pdf_id": "19WwS...",
            "fechas_de_pago_id": "1sSs3...",
        },
        "carpeta_resultados_nombre": "Resultados_Motor",
    },
    "procesamiento": {
        "anios_a_procesar": [2025, 2026],
        "_nota_anios": "nota que debe ignorarse",
        "rut_emisor_esperado": "77320456-K",
        "tipos_dte_validos": [33, 34],
    },
    "reglas_validacion": {
        "base_comparacion": "neto",
        "tolerancia_monto_pesos": 1,
        "estados": ["CUADRA", "NO_CUADRA", "NO_VERIFICABLE"],
    },
    "exclusiones": {
        "patrones_descripcion_excluir": ["REPARACION MOTOR", "COTIZACION"],
        "excluir_lineas_con_orden_de_compra": False,
    },
    "salida": {"sufijo_fecha_en_nombre": True, "copia_local_en_data": True},
    "backend": "local",
}


def _escribir(tmp_path: Path, **cambios) -> Path:
    datos = json.loads(json.dumps(BASE))  # copia profunda
    for ruta_llave, valor in cambios.items():
        seccion, llave = ruta_llave.split(".")
        datos[seccion][llave] = valor
    destino = tmp_path / "fuentes.json"
    destino.write_text(json.dumps(datos), encoding="utf-8")
    return destino


def test_carga_el_esquema_real(tmp_path: Path):
    config = cargar_configuracion(_escribir(tmp_path))

    assert config.anios == [2025, 2026]
    assert config.base_comparacion == "neto"
    assert config.tolerancia_pesos == 1
    assert config.rut_emisor_esperado == "77320456-K"
    assert config.tipos_dte_validos == [33, 34]
    assert config.ids_drive["facturas_xml_id"] == "1SqC2..."


def test_ignora_las_llaves_de_nota(tmp_path: Path):
    """Las llaves con prefijo _ son documentacion embebida, no configuracion."""
    config = cargar_configuracion(_escribir(tmp_path))

    assert not any(nombre.startswith("_") for nombre in vars(config))


def test_rechaza_base_comparacion_invalida(tmp_path: Path):
    ruta = _escribir(tmp_path, **{"reglas_validacion.base_comparacion": "bruto"})

    with pytest.raises(ValueError, match="base_comparacion"):
        cargar_configuracion(ruta)


def test_rechaza_backend_invalido(tmp_path: Path):
    ruta = _escribir(tmp_path, **{"salida.x": None})  # placeholder, se sobreescribe abajo
    datos = json.loads(ruta.read_text(encoding="utf-8"))
    datos["backend"] = "dropbox"
    ruta.write_text(json.dumps(datos), encoding="utf-8")

    with pytest.raises(ValueError, match="backend"):
        cargar_configuracion(ruta)
```

- [ ] **4.** Correr: `pytest tests/test_configuracion.py -v` → **FAIL** (`ModuleNotFoundError: src.configuracion`).
- [ ] **5.** Implementar `src/configuracion.py` con un `@dataclass(frozen=True)` que aplane el esquema anidado a atributos planos, ignore las llaves con prefijo `_`, y valide explícitamente `base_comparacion` ∈ `{neto, total}` y `backend` ∈ `{local, drive}`. Fallar ruidoso: `ValueError` con mensaje que nombre la llave inválida y el valor recibido.
- [ ] **6.** Correr: `pytest tests/test_configuracion.py -v` → **PASS**.
- [ ] **7.** **Verificar contra el archivo real:** `cargar_configuracion(Path("config/fuentes.json"))` debe funcionar sobre el archivo heredado sin error.
- [ ] **8.** Commit: `[activacion-contratos-chile] Agregar carga y validacion de configuracion`

**Criterio de completitud:** los cuatro tests pasan; el cargador lee el `fuentes.json` real del repo sin error; una `base_comparacion` o un `backend` inválidos abortan con mensaje claro.

---

#### T-03 — Fixtures sintéticos y arranque de pytest

**Archivos:**
- Crear: `tests/conftest.py`, `tests/fixtures/generador.py`
- Test: los propios fixtures se auto-verifican en `tests/test_fixtures.py`

**Interfaces producidas:**
- `crear_excel_facturacion(ruta: Path, filas: list[dict], anio: int) -> Path`
- `crear_xml_dte(ruta: Path, folio: int, neto: int, iva: int, total: int, rut_receptor: str = "76111222-3", tipo_dte: int = 33) -> Path`
- Fixtures pytest: `excel_2025`, `excel_2026`, `xml_cuadra`, `xml_no_cuadra`, `dir_insumos`

**Por qué esta tarea existe:** los insumos reales contienen RUT, beneficiarios, VIN y montos — no pueden entrar a git (PRD §13). Sin generadores sintéticos, la suite de tests no es reproducible por un tercero, y el criterio "un tercero puede ejecutarlo siguiendo solo el README" (PRD §9) no se cumple.

**Pasos:**

- [ ] **1.** Escribir `tests/fixtures/generador.py`. `crear_xml_dte` debe emitir la estructura real del DTE SII **con su namespace**, porque es lo que `ingesta_xml` tendrá que parsear:

```python
# tests/fixtures/generador.py
from pathlib import Path
from openpyxl import Workbook

NS_SII = "http://www.sii.cl/SiiDte"

PLANTILLA_DTE = """<?xml version="1.0" encoding="ISO-8859-1"?>
<DTE xmlns="{ns}" version="1.0">
  <Documento ID="F{folio}T{tipo}">
    <Encabezado>
      <IdDoc><TipoDTE>{tipo}</TipoDTE><Folio>{folio}</Folio><FchEmis>{fecha}</FchEmis></IdDoc>
      <Emisor><RUTEmisor>77320456-K</RUTEmisor></Emisor>
      <Receptor><RUTRecep>{rut_receptor}</RUTRecep><RznSocRecep>DISTRIBUIDOR DEMO SPA</RznSocRecep></Receptor>
      <Totales><MntNeto>{neto}</MntNeto><IVA>{iva}</IVA><MntTotal>{total}</MntTotal></Totales>
    </Encabezado>
    <Detalle>
      <NroLinDet>1</NroLinDet><NmbItem>GARANTIA EXTENDIDA</NmbItem>
      <QtyItem>{cantidad}</QtyItem><UnmdItem>UNID</UnmdItem><MontoItem>{neto}</MontoItem>
    </Detalle>
  </Documento>
</DTE>
"""


def crear_xml_dte(ruta: Path, folio: int, neto: int, iva: int, total: int,
                  rut_receptor: str = "76111222-3", tipo_dte: int = 33,
                  fecha: str = "2026-01-06", cantidad: int = 1) -> Path:
    """Genera un DTE SII sintetico con el namespace real, para pruebas."""
    destino = ruta / f"F{folio}T{tipo_dte}.xml"
    destino.write_text(
        PLANTILLA_DTE.format(ns=NS_SII, folio=folio, tipo=tipo_dte, fecha=fecha,
                             rut_receptor=rut_receptor, neto=neto, iva=iva,
                             total=total, cantidad=cantidad),
        encoding="utf-8",
    )
    return destino


COLUMNAS_2025 = ["FACTURA N°", "ID", "Producto", "Importe", "Monto a Facturar",
                 "F. Alta", "F. Pago", "Beneficiario", "R.U.T.", "VIN",
                 "Patente", "Id Distr.", "Distribuidor", "Estatus"]

# El archivo 2026 trae columnas extra — el motor debe tolerarlo (PRD §4.1).
COLUMNAS_2026 = COLUMNAS_2025 + ["Impuestos", "Total", "Garant. Fabrica"]


def crear_excel_facturacion(ruta: Path, filas: list[dict], anio: int) -> Path:
    """Genera un Excel de facturacion sintetico con el esquema del anio dado."""
    columnas = COLUMNAS_2025 if anio == 2025 else COLUMNAS_2026
    libro = Workbook()
    hoja = libro.active
    hoja.append(columnas)
    for fila in filas:
        hoja.append([fila.get(col, "") for col in columnas])
    destino = ruta / f"FACTURACION {anio}.xlsx"
    libro.save(destino)
    return destino
```

- [ ] **2.** Escribir `tests/conftest.py` con fixtures que compongan escenarios nombrados. Mínimo: un folio que **cuadra** (2 contratos de $100.000 neto cada uno vs `MntNeto` = 200.000), uno que **no cuadra** (delta de $50.000), un contrato **sin factura** (`FACTURA N°` = `"NO FACTURADO"`), un folio del Excel **sin XML**, y un XML **sin correspondencia** en el Excel.
- [ ] **3.** Escribir `tests/test_fixtures.py` que verifique que los generadores producen archivos legibles: el XML parsea con `lxml` y el Excel abre con `openpyxl`.
- [ ] **4.** Correr: `pytest tests/test_fixtures.py -v` → **FAIL**.
- [ ] **5.** Ajustar los generadores hasta que pase.
- [ ] **6.** Correr: `pytest tests/ -v` → **PASS**.
- [ ] **7.** Commit: `[activacion-contratos-chile] Agregar generadores de fixtures sinteticos`

**Criterio de completitud:** los cinco escenarios nombrados están disponibles como fixtures; ningún archivo de test contiene datos reales.

---

#### T-04 — Logging estructurado y contrato de exit codes

**Archivos:**
- Crear: `src/registro.py`
- Test: `tests/test_registro.py`

**Interfaces producidas:**
- `configurar_logging(nivel: str) -> None`
- `obtener_logger(nombre: str) -> logging.Logger`
- Constantes: `EXIT_OK = 0`, `EXIT_ERROR_CONFIG = 2`, `EXIT_ERROR_INSUMOS = 3`, `EXIT_ERROR_PROCESO = 4`

**Por qué existe:** el PRD §9 exige "falla ruidoso (exit ≠ 0 + log claro)" porque n8n detecta el fallo por exit code. Un exit code genérico `1` no permite a n8n distinguir "falta configuración" de "falta un insumo" — y esa distinción cambia la acción del operador.

**Pasos:**

- [ ] **1.** Escribir el test que falla:

```python
# tests/test_registro.py
import logging
from src.registro import configurar_logging, obtener_logger, EXIT_OK, EXIT_ERROR_INSUMOS


def test_codigos_de_salida_son_distintos_y_no_cero_en_error():
    assert EXIT_OK == 0
    assert EXIT_ERROR_INSUMOS != 0


def test_logger_emite_al_nivel_configurado(caplog):
    configurar_logging("INFO")
    logger = obtener_logger("prueba")
    with caplog.at_level(logging.INFO):
        logger.info("mensaje de prueba")
    assert "mensaje de prueba" in caplog.text
```

- [ ] **2.** Correr: `pytest tests/test_registro.py -v` → **FAIL**.
- [ ] **3.** Implementar `src/registro.py`. Formato de log con timestamp, nivel, módulo y mensaje. Nunca registrar RUT, beneficiarios ni VIN (`rules/coding-guidelines.md` §9) — los logs referencian folios y conteos, no identidades.
- [ ] **4.** Correr: `pytest tests/test_registro.py -v` → **PASS**.
- [ ] **5.** Commit: `[activacion-contratos-chile] Agregar logging y codigos de salida`

**Criterio de completitud:** los cuatro exit codes están definidos y son distintos; el logger no emite datos personales.

---

### Fase 1 — Normalización e ingesta

#### T-05 — Normalización de montos, folios, fechas e IDs

**Archivos:**
- Crear: `src/normalizacion.py`
- Test: `tests/test_normalizacion.py`

**Interfaces producidas:**
- `normalizar_monto(valor) -> int | None` — `"$1.234.567"` → `1234567`
- `normalizar_folio(valor) -> int | None` — devuelve `None` para vacío y `"NO FACTURADO"`
- `es_sin_factura(valor) -> bool`
- `normalizar_fecha(valor) -> date | None`
- `normalizar_id_contrato(valor) -> str | None`
- `folio_desde_nombre_archivo(nombre: str) -> tuple[int, int] | None` — `"F19499T33.xml"` → `(19499, 33)`

**Esta es la tarea de mayor densidad de casos límite del proyecto.** El formato chileno usa punto como separador de miles y el peso no tiene decimales de uso corriente, así que `"$1.234.567"` son 1.234.567 pesos, no 1,234567. Confundirlo produce montos con error de 10⁶.

**Pasos:**

- [ ] **1.** Escribir el test que falla, cubriendo el rango real de basura que trae un Excel del despacho:

```python
# tests/test_normalizacion.py
from datetime import date
import pytest
from src.normalizacion import (
    normalizar_monto, normalizar_folio, es_sin_factura,
    normalizar_fecha, folio_desde_nombre_archivo,
)


@pytest.mark.parametrize("entrada,esperado", [
    ("$1.234.567", 1_234_567),   # formato chileno: punto = miles
    ("1.234.567", 1_234_567),
    ("$ 250.000", 250_000),
    (250000, 250_000),           # ya viene numerico desde openpyxl
    (250000.0, 250_000),
    ("", None),
    (None, None),
    ("   ", None),
])
def test_normalizar_monto(entrada, esperado):
    assert normalizar_monto(entrada) == esperado


def test_normalizar_monto_rechaza_texto_no_numerico():
    with pytest.raises(ValueError):
        normalizar_monto("SIN MONTO")


@pytest.mark.parametrize("entrada,esperado", [
    ("19499", 19499),
    (19499, 19499),
    ("F19499", 19499),
    ("NO FACTURADO", None),
    ("no facturado", None),
    ("", None),
    (None, None),
])
def test_normalizar_folio(entrada, esperado):
    assert normalizar_folio(entrada) == esperado


@pytest.mark.parametrize("entrada", ["NO FACTURADO", "no facturado", "", None, "  "])
def test_es_sin_factura(entrada):
    assert es_sin_factura(entrada) is True


def test_es_sin_factura_falso_para_folio_real():
    assert es_sin_factura("19499") is False


def test_normalizar_fecha_acepta_formatos_del_despacho():
    assert normalizar_fecha("06/01/2026") == date(2026, 1, 6)   # dd/mm/aaaa
    assert normalizar_fecha("2026-01-06") == date(2026, 1, 6)
    assert normalizar_fecha("") is None


@pytest.mark.parametrize("nombre,esperado", [
    ("F19499T33.xml", (19499, 33)),
    ("F19499T33.pdf", (19499, 33)),
    ("F2001T61.xml", (2001, 61)),
    ("cualquier_cosa.xml", None),
])
def test_folio_desde_nombre_archivo(nombre, esperado):
    assert folio_desde_nombre_archivo(nombre) == esperado
```

- [ ] **2.** Correr: `pytest tests/test_normalizacion.py -v` → **FAIL**.
- [ ] **3.** Implementar `src/normalizacion.py`. Puntos de cuidado: `normalizar_monto` elimina `$`, espacios y puntos de miles antes de convertir; un texto no numérico que no sea vacío levanta `ValueError` en vez de devolver `None` en silencio (marcado, no borrado — un monto ilegible es un problema que debe reportarse, no un cero). `folio_desde_nombre_archivo` usa `re.fullmatch(r"F(\d+)T(\d+)\.(xml|pdf)", nombre, re.IGNORECASE)`.
- [ ] **4.** Correr: `pytest tests/test_normalizacion.py -v` → **PASS** (todos los parámetros).
- [ ] **5.** Commit: `[activacion-contratos-chile] Agregar normalizacion de montos folios y fechas`

**Criterio de completitud:** los 20+ casos parametrizados pasan; `"$1.234.567"` produce exactamente `1234567`.

---

#### T-06 — Ingesta de los Excel de facturación

**Archivos:**
- Crear: `src/ingesta_excel.py`
- Test: `tests/test_ingesta_excel.py`

**Interfaces producidas:**
- `leer_excel_facturacion(ruta: Path, anio: int) -> pd.DataFrame` — devuelve columnas canónicas normalizadas
- `MAPA_COLUMNAS: dict[str, list[str]]` — nombre canónico → alias aceptados
- Columnas canónicas de salida: `folio`, `id_contrato`, `producto`, `importe`, `monto_a_facturar`, `f_alta`, `f_pago`, `beneficiario`, `rut`, `vin`, `patente`, `id_distr`, `distribuidor`, `estatus`, `anio_origen`, `fila_origen`

**Pasos:**

- [ ] **1.** Escribir el test que falla. Los tres comportamientos críticos: mapeo por **nombre** (no posición), tolerancia a columnas ausentes, y **conservación total de filas**:

```python
# tests/test_ingesta_excel.py
from src.ingesta_excel import leer_excel_facturacion
from tests.fixtures.generador import crear_excel_facturacion


def test_mapea_columnas_por_nombre_no_por_posicion(tmp_path):
    ruta = crear_excel_facturacion(tmp_path, [
        {"FACTURA N°": "19499", "ID": "C-001", "Monto a Facturar": "$100.000",
         "Beneficiario": "JUAN PEREZ", "Producto": "Excellence Light"},
    ], anio=2025)

    df = leer_excel_facturacion(ruta, anio=2025)

    assert df.loc[0, "folio"] == 19499
    assert df.loc[0, "id_contrato"] == "C-001"
    assert df.loc[0, "monto_a_facturar"] == 100_000


def test_tolera_esquema_2026_con_columnas_extra(tmp_path):
    ruta = crear_excel_facturacion(tmp_path, [
        {"FACTURA N°": "20001", "ID": "C-050", "Monto a Facturar": "$50.000",
         "Impuestos": "$9.500", "Total": "$59.500"},
    ], anio=2026)

    df = leer_excel_facturacion(ruta, anio=2026)

    assert len(df) == 1
    assert df.loc[0, "folio"] == 20001


def test_no_pierde_ninguna_fila(tmp_path):
    filas = [{"FACTURA N°": "19499", "ID": f"C-{i:03d}", "Monto a Facturar": "$10.000"}
             for i in range(50)]
    filas.append({"FACTURA N°": "NO FACTURADO", "ID": "C-999",
                  "Monto a Facturar": "$10.000"})
    ruta = crear_excel_facturacion(tmp_path, filas, anio=2025)

    df = leer_excel_facturacion(ruta, anio=2025)

    assert len(df) == 51  # las 50 facturadas + la sin factura


def test_marca_sin_factura_con_folio_nulo(tmp_path):
    ruta = crear_excel_facturacion(tmp_path, [
        {"FACTURA N°": "NO FACTURADO", "ID": "C-999", "Monto a Facturar": "$10.000"},
    ], anio=2025)

    df = leer_excel_facturacion(ruta, anio=2025)

    assert df.loc[0, "folio"] is None or df.loc[0, "folio"] != df.loc[0, "folio"]
```

- [ ] **2.** Correr: `pytest tests/test_ingesta_excel.py -v` → **FAIL**.
- [ ] **3.** Implementar `src/ingesta_excel.py`. El mapa de alias tolera variaciones de acento y espaciado:

```python
MAPA_COLUMNAS = {
    "folio": ["FACTURA N°", "FACTURA N", "FACTURA No", "FACTURA"],
    "id_contrato": ["ID"],
    "producto": ["Producto"],
    "importe": ["Importe"],
    "monto_a_facturar": ["Monto a Facturar", "Monto a facturar"],
    "f_alta": ["F. Alta"],
    "f_pago": ["F. Pago"],
    "beneficiario": ["Beneficiario"],
    "rut": ["R.U.T.", "RUT"],
    "vin": ["VIN"],
    "patente": ["Patente"],
    "id_distr": ["Id Distr.", "Id Distr"],
    "distribuidor": ["Distribuidor"],
    "estatus": ["Estatus"],
}
```

  Una columna canónica ausente se rellena con `None`, no se omite — así el DataFrame tiene siempre la misma forma sin importar el año. `fila_origen` guarda el número de fila del Excel para trazabilidad en el reporte. Si **ninguna** columna candidata para `folio`, `id_contrato` o `monto_a_facturar` está presente, abortar con `ValueError` nombrando la columna faltante: sin esas tres el archivo no es procesable y seguir produciría un reporte silenciosamente vacío.

- [ ] **4.** Correr: `pytest tests/test_ingesta_excel.py -v` → **PASS**.
- [ ] **5.** **Validar contra un archivo real.** Correr un script ad-hoc que abra `FACTURACION AÑO 2025.xlsx` real y liste las columnas encontradas vs. las esperadas. Ajustar `MAPA_COLUMNAS` con lo que aparezca. *Este paso no puede omitirse: el mapa de alias está construido desde el PRD, no desde los archivos.*
- [ ] **6.** Commit: `[activacion-contratos-chile] Agregar ingesta de Excel de facturacion`

**Criterio de completitud:** los cuatro tests pasan; el archivo real de 2025 y el de 2026 se leen sin error y el conteo de filas del DataFrame coincide con el del Excel abierto a mano.

---

#### T-07 — Ingesta y parseo de XML (DTE SII)

**Archivos:**
- Crear: `src/ingesta_xml.py`
- Test: `tests/test_ingesta_xml.py`

**Interfaces producidas:**
- `parsear_dte(ruta: Path) -> Dte` — dataclass con `folio: int`, `tipo_dte: int`, `fecha_emision: date`, `rut_emisor: str`, `rut_receptor: str`, `razon_social_receptor: str`, `monto_neto: int`, `iva: int`, `monto_total: int`, `ruta_archivo: str`
- `leer_directorio_xml(directorio: Path) -> dict[int, Dte]` — indexado por folio

**El detalle que rompe implementaciones ingenuas:** el DTE del SII usa el namespace `http://www.sii.cl/SiiDte`. Un `root.find("Documento/Encabezado")` sin namespace devuelve `None` en silencio y produce un motor que reporta *todo* como `NO_VERIFICABLE` sin ningún error visible.

**Pasos:**

- [ ] **1.** Escribir el test que falla:

```python
# tests/test_ingesta_xml.py
from datetime import date
import pytest
from src.ingesta_xml import parsear_dte, leer_directorio_xml
from tests.fixtures.generador import crear_xml_dte


def test_parsea_campos_del_encabezado(tmp_path):
    ruta = crear_xml_dte(tmp_path, folio=19499, neto=200_000, iva=38_000,
                         total=238_000, fecha="2026-01-06")

    dte = parsear_dte(ruta)

    assert dte.folio == 19499
    assert dte.tipo_dte == 33
    assert dte.fecha_emision == date(2026, 1, 6)
    assert dte.rut_receptor == "76111222-3"
    assert dte.monto_neto == 200_000
    assert dte.iva == 38_000
    assert dte.monto_total == 238_000


def test_reconoce_nota_de_credito_tipo_61(tmp_path):
    ruta = crear_xml_dte(tmp_path, folio=2001, neto=50_000, iva=9_500,
                         total=59_500, tipo_dte=61)

    dte = parsear_dte(ruta)

    assert dte.tipo_dte == 61


def test_indexa_directorio_por_folio(tmp_path):
    crear_xml_dte(tmp_path, folio=100, neto=1000, iva=190, total=1190)
    crear_xml_dte(tmp_path, folio=200, neto=2000, iva=380, total=2380)

    indice = leer_directorio_xml(tmp_path)

    assert set(indice.keys()) == {100, 200}
    assert indice[200].monto_neto == 2000


def test_xml_malformado_falla_ruidoso(tmp_path):
    ruta = tmp_path / "F999T33.xml"
    ruta.write_text("<DTE>sin cerrar", encoding="utf-8")

    with pytest.raises(ValueError, match="F999T33"):
        parsear_dte(ruta)
```

- [ ] **2.** Correr: `pytest tests/test_ingesta_xml.py -v` → **FAIL**.
- [ ] **3.** Implementar `src/ingesta_xml.py` con `lxml.etree`, declarando el namespace explícitamente:

```python
from lxml import etree

NS = {"sii": "http://www.sii.cl/SiiDte"}


def _texto(nodo, xpath: str) -> str | None:
    encontrado = nodo.find(xpath, namespaces=NS)
    return encontrado.text.strip() if encontrado is not None and encontrado.text else None
```

  El `MntNeto` puede venir ausente en un DTE exento (tipo 34): en ese caso `monto_neto` queda en `0` y `monto_total` es la cifra válida. Un XML ilegible levanta `ValueError` nombrando el archivo — nunca se salta en silencio, porque un XML que no parsea es un folio que aparecería como `NO_VERIFICABLE` sin explicación.

- [ ] **4.** Correr: `pytest tests/test_ingesta_xml.py -v` → **PASS**.
- [ ] **5.** **Validar contra un XML real** (`F19499T33.xml`). Confirmar que el namespace y las rutas coinciden con el archivo del PRD §4.2.
- [ ] **6.** Commit: `[activacion-contratos-chile] Agregar parseo de DTE SII`

**Criterio de completitud:** los cuatro tests pasan y un XML real de producción parsea con los mismos valores que se leen abriéndolo a mano.

---

#### T-08 — Inventario de PDF

**Archivos:**
- Crear: `src/ingesta_pdf.py`
- Test: `tests/test_ingesta_pdf.py`

**Interfaces producidas:**
- `inventariar_pdf(directorio: Path) -> dict[int, str]` — folio → ruta del PDF

**Alcance deliberadamente mínimo:** el PDF es evidencia, no fuente de datos (PRD §4). El motor solo necesita saber **si existe** el PDF de un folio, para poblar `ruta_pdf` en `lista_ti.csv` y para la doble confirmación de "tiene factura emitida" (PRD §7.2). No se extrae texto — hacerlo agregaría una dependencia (`pypdf`) y una superficie de fallo para un dato que ya está en el XML.

**Pasos:**

- [ ] **1.** Escribir el test que falla: un directorio con `F100T33.pdf`, `F200T33.pdf` y `notas.txt` produce `{100: ..., 200: ...}` e ignora el `.txt`.
- [ ] **2.** Correr: `pytest tests/test_ingesta_pdf.py -v` → **FAIL**.
- [ ] **3.** Implementar reutilizando `folio_desde_nombre_archivo` de `normalizacion`.
- [ ] **4.** Correr: `pytest tests/test_ingesta_pdf.py -v` → **PASS**.
- [ ] **5.** Commit: `[activacion-contratos-chile] Agregar inventario de PDF`

**Criterio de completitud:** archivos que no siguen la convención `F{folio}T{tipo}.pdf` se ignoran sin error.

---

#### T-09 — `drive_io` con backend local

**Archivos:**
- Crear: `src/drive_io.py`
- Test: `tests/test_drive_io.py`

**Interfaces producidas:**
- `class RepositorioInsumos(Protocol)` con `listar_excel() -> list[Path]`, `listar_xml() -> list[Path]`, `listar_pdf() -> list[Path]`, `publicar(archivos: list[Path], subcarpeta: str) -> None`
- `RepositorioLocal(rutas: RutasLocal)` — implementación de la interfaz
- `crear_repositorio(config: Configuracion) -> RepositorioInsumos` — fábrica que elige backend

**Por qué la interfaz existe antes que el backend de Drive:** el acceso a Drive es la decisión pendiente §10.8 del PRD y la única que puede bloquear el arranque. Definir el contrato ahora y construir el backend local permite que las Fases 1–3 terminen sin credenciales; la Fase 4 solo agrega una implementación de la misma interfaz.

**Pasos:**

- [ ] **1.** Escribir el test que falla: `RepositorioLocal` sobre un `tmp_path` con la estructura de subcarpetas devuelve los archivos correctos; `publicar` crea la subcarpeta con timestamp y copia los archivos.
- [ ] **2.** Correr: `pytest tests/test_drive_io.py -v` → **FAIL**.
- [ ] **3.** Implementar `RepositorioLocal` y la fábrica. `crear_repositorio` levanta `NotImplementedError` con mensaje explícito si `backend == "drive"` — se completa en T-18.
- [ ] **4.** Correr: `pytest tests/test_drive_io.py -v` → **PASS**.
- [ ] **5.** Commit: `[activacion-contratos-chile] Agregar abstraccion de IO con backend local`

**Criterio de completitud:** ningún módulo fuera de `drive_io.py` toca el sistema de archivos directamente.

---

### Fase 2 — Conciliación y clasificación

#### T-10 — Agrupación de contratos por folio

**Archivos:**
- Crear: `src/validacion.py`
- Test: `tests/test_validacion.py`

**Interfaces producidas:**
- `agrupar_por_folio(df_contratos: pd.DataFrame) -> dict[int, GrupoFolio]`
- `@dataclass GrupoFolio`: `folio: int`, `ids_contratos: list[str]`, `n_contratos: int`, `suma_montos: int`, `filas: pd.DataFrame`

**Pasos:**

- [ ] **1.** Escribir el test que falla:

```python
import pandas as pd
from src.validacion import agrupar_por_folio


def test_agrupa_contratos_del_mismo_folio_y_suma_montos():
    df = pd.DataFrame([
        {"folio": 19499, "id_contrato": "C-001", "monto_a_facturar": 100_000},
        {"folio": 19499, "id_contrato": "C-002", "monto_a_facturar": 150_000},
        {"folio": 19500, "id_contrato": "C-003", "monto_a_facturar": 80_000},
    ])

    grupos = agrupar_por_folio(df)

    assert grupos[19499].n_contratos == 2
    assert grupos[19499].suma_montos == 250_000
    assert set(grupos[19499].ids_contratos) == {"C-001", "C-002"}
    assert grupos[19500].n_contratos == 1


def test_excluye_filas_sin_folio_del_agrupamiento():
    df = pd.DataFrame([
        {"folio": 19499, "id_contrato": "C-001", "monto_a_facturar": 100_000},
        {"folio": None, "id_contrato": "C-999", "monto_a_facturar": 50_000},
    ])

    grupos = agrupar_por_folio(df)

    assert list(grupos.keys()) == [19499]
```

- [ ] **2.** Correr: `pytest tests/test_validacion.py -v` → **FAIL**.
- [ ] **3.** Implementar. Las filas sin folio no se pierden — se agrupan aparte y alimentan la hoja "Sin factura" (T-13).
- [ ] **4.** Correr → **PASS**.
- [ ] **5.** Commit: `[activacion-contratos-chile] Agregar agrupacion de contratos por folio`

---

#### T-11 — Comparación de montos configurable

**Archivos:**
- Modificar: `src/validacion.py`
- Test: `tests/test_validacion.py`

**Interfaces producidas:**
- `comparar_montos(grupo: GrupoFolio, dte: Dte, base: str, tolerancia: int) -> ResultadoMonto`
- `@dataclass ResultadoMonto`: `cuadra: bool`, `monto_referencia: int`, `delta_neto: int`, `delta_total: int`

**Esta es la tarea donde vive el riesgo de negocio más alto del proyecto.** Comparar la suma del Excel contra `MntTotal` cuando los montos del Excel son netos marca ~100% de las facturas como `NO_CUADRA` por la diferencia del IVA (19%). Por eso el resultado expone **ambos deltas** siempre: si el delta contra neto es ~0 y el delta contra total es ~19%, el operador ve de inmediato cuál es la base correcta.

**Pasos:**

- [ ] **1.** Escribir el test que falla:

```python
from src.validacion import comparar_montos, GrupoFolio
from src.ingesta_xml import Dte


def _dte(neto=200_000, iva=38_000, total=238_000):
    return Dte(folio=19499, tipo_dte=33, fecha_emision=None, rut_emisor="77320456-K",
               rut_receptor="76111222-3", razon_social_receptor="DEMO",
               monto_neto=neto, iva=iva, monto_total=total, ruta_archivo="F19499T33.xml")


def _grupo(suma):
    return GrupoFolio(folio=19499, ids_contratos=["C-001"], n_contratos=1,
                      suma_montos=suma, filas=None)


def test_cuadra_contra_neto_cuando_el_excel_trae_netos():
    resultado = comparar_montos(_grupo(200_000), _dte(), base="neto", tolerancia=1)

    assert resultado.cuadra is True
    assert resultado.delta_neto == 0
    assert resultado.delta_total == -38_000  # evidencia de que la base correcta es neto


def test_no_cuadra_contra_total_con_los_mismos_datos():
    resultado = comparar_montos(_grupo(200_000), _dte(), base="total", tolerancia=1)

    assert resultado.cuadra is False


def test_tolerancia_absorbe_redondeo():
    resultado = comparar_montos(_grupo(199_999), _dte(), base="neto", tolerancia=1)

    assert resultado.cuadra is True


def test_tolerancia_no_absorbe_diferencia_real():
    resultado = comparar_montos(_grupo(199_990), _dte(), base="neto", tolerancia=1)

    assert resultado.cuadra is False
    assert resultado.delta_neto == -10
```

- [ ] **2.** Correr → **FAIL**.
- [ ] **3.** Implementar. `delta_neto = suma_montos - dte.monto_neto`, `delta_total = suma_montos - dte.monto_total`; `cuadra` evalúa `abs(delta_de_la_base_elegida) <= tolerancia`. Ambos deltas se calculan siempre, sin importar la base.
- [ ] **4.** Correr → **PASS**.
- [ ] **5.** Commit: `[activacion-contratos-chile] Agregar comparacion de montos configurable neto o total`

**Criterio de completitud:** los cuatro tests pasan; el resultado expone los dos deltas independientemente de la base configurada.

---

#### T-12 — Clasificación en los tres estados

**Archivos:**
- Modificar: `src/validacion.py`
- Test: `tests/test_validacion.py`

**Interfaces producidas:**
- `clasificar_facturas(grupos, indice_xml, indice_pdf, config) -> list[FacturaValidada]`
- `@dataclass FacturaValidada`: `folio`, `estado`, `motivo`, `grupo`, `dte`, `resultado_monto`, `ruta_xml`, `ruta_pdf`
- `ESTADOS = ("CUADRA", "NO_CUADRA", "NO_VERIFICABLE")`

**Pasos:**

- [ ] **1.** Escribir el test que falla, cubriendo los cinco escenarios del PRD §8:

```python
def test_cuadra_cuando_existe_xml_y_montos_coinciden(): ...
def test_no_cuadra_cuando_existe_xml_y_montos_diferen(): ...
def test_no_verificable_cuando_folio_del_excel_no_tiene_xml(): ...
def test_xml_sin_correspondencia_en_excel_se_reporta_como_huerfano(): ...
def test_todas_las_facturas_reciben_exactamente_un_estado(): ...
```

  El último es el criterio de aceptación del PRD §9 hecho test: *"el reporte clasifica el 100% de las facturas en uno de los 3 estados"*.

- [ ] **2.** Correr → **FAIL**.
- [ ] **3.** Implementar. Reglas (PRD §7.2): un folio es `NO_VERIFICABLE` si no existe su XML **o** no existe su PDF (doble confirmación). El campo `motivo` guarda texto legible (`"sin XML"`, `"sin PDF"`, `"delta neto de $-38.000"`) porque el reporte lo consume directamente y un operador necesita saber *por qué*, no solo *qué*.
- [ ] **4.** Correr → **PASS**.
- [ ] **5.** Commit: `[activacion-contratos-chile] Agregar clasificacion en tres estados de validacion`

**Criterio de completitud:** ninguna factura queda sin estado; los XML huérfanos (sin correspondencia en el Excel) se reportan en vez de descartarse.

---

#### T-13 — Invariante de conservación de filas y exclusiones

**Archivos:**
- Modificar: `src/validacion.py`
- Test: `tests/test_conservacion.py`

**Interfaces producidas:**
- `aplicar_exclusiones(df, config) -> tuple[pd.DataFrame, pd.DataFrame]` — (conservadas, excluidas)
- `verificar_conservacion(total_original: int, con_factura: int, sin_factura: int, excluidas: int) -> None` — levanta `AssertionError` si no cuadra

**Este es el criterio de aceptación más importante del PRD** (§9): *"Ninguna fila se pierde: contratos con factura + sin factura + excluidos = total de filas del Excel"*. Se implementa como invariante ejecutable, no como revisión manual.

**Pasos:**

- [ ] **1.** Escribir el test que falla:

```python
import pytest
from src.validacion import verificar_conservacion


def test_conservacion_se_cumple_cuando_las_partes_suman_el_total():
    verificar_conservacion(total_original=100, con_factura=80, sin_factura=15, excluidas=5)


def test_conservacion_falla_ruidoso_si_falta_una_fila():
    with pytest.raises(AssertionError, match="conservacion"):
        verificar_conservacion(total_original=100, con_factura=80, sin_factura=15, excluidas=4)
```

- [ ] **2.** Correr → **FAIL**.
- [ ] **3.** Implementar ambas funciones. `aplicar_exclusiones` respeta `config.exclusiones.activa`: cuando es `false` (el default), devuelve todo en "conservadas" y un DataFrame vacío en "excluidas". El mensaje de la aserción debe nombrar el total esperado, el obtenido y la diferencia.
- [ ] **4.** Correr → **PASS**.
- [ ] **5.** Agregar la llamada a `verificar_conservacion` en el punto de salida de `validacion.py`, de modo que sea imposible producir entregables sin haberla verificado.
- [ ] **6.** Correr la suite completa: `pytest tests/ -v` → **PASS**.
- [ ] **7.** Commit: `[activacion-contratos-chile] Agregar invariante de conservacion de filas y exclusiones`

**Criterio de completitud:** el motor aborta si pierde una sola fila; con exclusiones desactivadas, el conteo de excluidas es 0.

---

### Fase 3 — Entregables y ejecución headless

#### T-14 — `feed_rpa.csv`

**Archivos:**
- Crear: `src/entregables.py`
- Test: `tests/test_entregables.py`

**Interfaces producidas:**
- `generar_feed_rpa(facturas: list[FacturaValidada], destino: Path) -> Path`

**Columnas exactas (PRD §6.1):** `id_contrato`, `factura_n`, `monto`, `beneficiario`, `rut`, `vin`, `patente`, `distribuidor`, `f_alta`, `estado_validacion`.

**Pasos:**

- [ ] **1.** Escribir el test que falla: verifica el encabezado exacto y su orden, que hay **una fila por contrato** (no por factura), que `estado_validacion` viene poblado, y que los contratos sin factura **no** aparecen.
- [ ] **2.** Correr → **FAIL**.
- [ ] **3.** Implementar. Encoding `utf-8-sig` y separador `;` — el RPA y los operadores abren estos CSV en Excel en configuración regional chilena, donde la coma es separador decimal. Un CSV con coma se abre como una sola columna.
- [ ] **4.** Correr → **PASS**.
- [ ] **5.** Commit: `[activacion-contratos-chile] Agregar generacion de feed para el RPA`

**Criterio de completitud:** el CSV se abre correctamente en Excel en español-Chile; el conteo de filas iguala el de contratos con folio.

---

#### T-15 — `lista_ti.csv`

**Archivos:**
- Modificar: `src/entregables.py`
- Test: `tests/test_entregables.py`

**Interfaces producidas:**
- `generar_lista_ti(facturas: list[FacturaValidada], destino: Path) -> Path`

**Columnas exactas (PRD §6.2):** `factura_n`, `tipo_dte`, `fecha_emision`, `rut_receptor`, `monto_total_xml`, `monto_total_excel`, `n_contratos`, `ids_contratos`, `ruta_xml`, `ruta_pdf`, `estado_validacion`.

**Pasos:**

- [ ] **1.** Escribir el test que falla: **una fila por factura** (no por contrato), `ids_contratos` como lista separada por `|` (no por `;`, que es el separador de campo, ni por `,` que confunde a Excel), y las facturas `NO_VERIFICABLE` presentes con campos del XML vacíos.
- [ ] **2.** Correr → **FAIL**.
- [ ] **3.** Implementar con el mismo encoding y separador que T-14.
- [ ] **4.** Correr → **PASS**.
- [ ] **5.** Commit: `[activacion-contratos-chile] Agregar generacion de lista para inyeccion de TI`

**Criterio de completitud:** el número de filas iguala el de folios distintos; una factura consolidada de 8 contratos aparece una sola vez con `n_contratos = 8`.

---

#### T-16 — `reporte_validacion.xlsx` (5 hojas)

**Archivos:**
- Modificar: `src/entregables.py`
- Test: `tests/test_reporte.py`

**Interfaces producidas:**
- `generar_reporte_validacion(facturas, sin_factura_df, excluidas_df, huerfanos, destino: Path) -> Path`

**Hojas exactas (PRD §6.3):**

| Hoja | Contenido |
|---|---|
| `Resumen` | Conteos por estado, montos totales, cobertura por año/mes |
| `No cuadra` | Facturas con diferencia Excel↔XML, **con ambos deltas** (neto y total) |
| `No verificable` | Folios del Excel sin XML/PDF, y XML/PDF sin correspondencia en el Excel |
| `Sin factura` | Contratos con `FACTURA N°` vacío o `NO FACTURADO` |
| `Excluidos` | Líneas descartadas por reglas (vacío mientras `exclusiones.activa` sea `false`) |

**Pasos:**

- [ ] **1.** Escribir el test que falla: el libro tiene exactamente esas 5 hojas con esos nombres; `Resumen` contiene el total de filas del Excel y la suma de los tres estados; la hoja `No cuadra` incluye columnas `delta_neto` y `delta_total`.
- [ ] **2.** Correr → **FAIL**.
- [ ] **3.** Implementar con `pandas.ExcelWriter(engine="openpyxl")`. Las hojas se crean **siempre**, aunque estén vacías — una hoja ausente es indistinguible de una hoja que el motor olvidó generar.
- [ ] **4.** Correr → **PASS**.
- [ ] **5.** Commit: `[activacion-contratos-chile] Agregar reporte de validacion en Excel`

**Criterio de completitud:** el libro abre en Excel sin advertencias; `Resumen` cuadra contra los conteos que devuelve `validacion`.

---

#### T-17 — `main.py` headless

**Archivos:**
- Crear: `src/main.py`
- Test: `tests/test_main.py`

**Interfaces producidas:**
- `main(argv: list[str] | None = None) -> int` — devuelve el exit code
- CLI: `python -m src.main --config config/fuentes.json [--anio 2025] [--solo-validar]`

**Pasos:**

- [ ] **1.** Escribir el test de integración de punta a punta que falla: sobre el directorio de fixtures sintéticos, `main()` devuelve `EXIT_OK` y deja los tres archivos en el destino. Y los tests de fallo: config inexistente → `EXIT_ERROR_CONFIG`; directorio de insumos vacío → `EXIT_ERROR_INSUMOS`.

```python
def test_ejecucion_completa_produce_los_tres_entregables(dir_insumos, tmp_path):
    codigo = main(["--config", str(config_de_prueba), "--destino", str(tmp_path)])

    assert codigo == EXIT_OK
    assert (tmp_path / "feed_rpa.csv").exists()
    assert (tmp_path / "lista_ti.csv").exists()
    assert (tmp_path / "reporte_validacion.xlsx").exists()


def test_config_inexistente_devuelve_exit_error_config(tmp_path):
    assert main(["--config", str(tmp_path / "no_existe.json")]) == EXIT_ERROR_CONFIG
```

- [ ] **2.** Correr → **FAIL**.
- [ ] **3.** Implementar la orquestación: cargar config → construir repositorio → ingestar → normalizar → validar → verificar conservación → generar entregables. Cada etapa registra un `INFO` con conteos. Ninguna excepción escapa sin traducirse a exit code; el log de error incluye el traceback pero nunca datos personales. Los nombres de salida llevan fecha (`feed_rpa_2026-08-04.csv`) por la idempotencia versionada del PRD §7.6.
- [ ] **4.** Correr → **PASS**.
- [ ] **5.** Correr la suite completa: `pytest tests/ -v` → **PASS**.
- [ ] **6.** Commit: `[activacion-contratos-chile] Agregar punto de entrada headless`

**Criterio de completitud:** `python -m src.main --config config/fuentes.json` corre de principio a fin sobre fixtures y devuelve 0; cada modo de fallo devuelve su código distintivo.

---

### Fase 4 — Google Drive, datos reales y cierre

#### T-18 — Backend de Google Drive

**Archivos:**
- Modificar: `src/drive_io.py`, `requirements.txt`
- Test: `tests/test_drive_io.py`

**Bloqueada por:** decisión §10.8 del PRD (cuenta de servicio vs. credencial OAuth de n8n) y entrega de credenciales.

**Pasos:**

- [ ] **1.** Confirmar con TI el mecanismo de acceso y obtener el JSON de la cuenta de servicio. Registrar la decisión en `SESSION.md`.
- [ ] **2.** Agregar `google-api-python-client` y `google-auth` pinneados a `requirements.txt`.
- [ ] **3.** Escribir el test que falla con el cliente de Drive **mockeado** — no se hacen llamadas de red en la suite de tests.
- [ ] **4.** Correr → **FAIL**.
- [ ] **5.** Implementar `RepositorioDrive` cumpliendo la misma interfaz `RepositorioInsumos` de T-09. Descarga a `data/insumos/`; nunca escribe en las carpetas de insumos de Drive (PRD §7.7).
- [ ] **6.** Correr → **PASS**.
- [ ] **7.** Prueba manual contra la carpeta real de Drive: listar y descargar. Verificar que los insumos quedan intactos.
- [ ] **8.** Commit: `[activacion-contratos-chile] Agregar backend de Google Drive`

**Criterio de completitud:** cambiar `"backend": "drive"` en `fuentes.json` hace que el motor lea de Drive sin ninguna otra modificación.

---

#### T-19 — Publicación en `Resultados_Motor/`

**Archivos:**
- Modificar: `src/drive_io.py`, `src/main.py`
- Test: `tests/test_drive_io.py`

**Pasos:**

- [ ] **1.** Escribir el test que falla (con Drive mockeado): `publicar()` crea la subcarpeta `Resultados_Motor/` si no existe y sube los tres archivos con fecha en el nombre.
- [ ] **2.** Correr → **FAIL**.
- [ ] **3.** Implementar. Una corrida nueva **no sobrescribe** la anterior: los nombres llevan fecha y, si colisionan en el mismo día, se agrega hora.
- [ ] **4.** Correr → **PASS**.
- [ ] **5.** Prueba manual: publicar y confirmar en Drive que los insumos originales no cambiaron.
- [ ] **6.** Commit: `[activacion-contratos-chile] Agregar publicacion de resultados en Drive`

---

#### T-20 — Corrida sobre datos reales y doble-cheque

**Archivos:**
- Crear: `docs/validacion-datos-reales.md`
- Modificar: `config/fuentes.json` (ajustes que salgan de los hallazgos)

**Esta es la tarea que cierra las decisiones abiertas del PRD §10 con evidencia en vez de con suposiciones.**

**Pasos:**

- [ ] **1.** Correr el motor completo sobre los insumos reales de 2025 y 2026.
- [ ] **2.** **Resolver la base de comparación con datos.** Revisar la hoja `No cuadra`: si `delta_neto ≈ 0` y `delta_total ≈ 19%` de forma sistemática, la base correcta es `neto` (el default). Si es al revés, cambiar `base_comparacion` a `"total"` en `fuentes.json`. Registrar la evidencia.
- [ ] **3.** **Validar el supuesto folio ↔ `FACTURA N°`** (PRD §10.2): contar cuántos folios del Excel tienen XML correspondiente. Una tasa alta confirma el mapeo 1:1; una tasa baja indica que la convención de nombres no coincide y hay que revisarla antes de operar.
- [ ] **4.** **Doble-cheque manual de muestra** (PRD §9): tomar 10 facturas al azar, sumar sus contratos a mano en el Excel y contrastar contra `lista_ti.csv`. Documentar el resultado.
- [ ] **5.** **Inventariar las líneas que no son garantías** (PRD §10.3): listar los valores distintos de `Producto` que contengan `REPARACI`, `COTIZACI` u `ORDEN DE COMPRA` y llevarlos a Andrés/Omar para decidir la regla de exclusión.
- [ ] **6.** **Inventariar notas de crédito** (PRD §10.4): contar los XML con `TipoDTE = 61` y proponer tratamiento.
- [ ] **7.** Escribir `docs/validacion-datos-reales.md` con los hallazgos — **sin cifras reales ni datos personales**, solo conteos, porcentajes y conclusiones (PRD §13).
- [ ] **8.** Aplicar en `fuentes.json` los ajustes confirmados.
- [ ] **9.** **Cerrar la pregunta de contratos ya activos** (PRD §14, primera fila) con Omar y TI: ¿existe un export o una vista de SIGA con el estado de activación que el motor pueda consumir, o el RPA valida antes de generar cada orden? Documentar la respuesta. Si la validación queda del lado del motor, es una tarea nueva de Fase 2 con su propio insumo — **no se agrega al alcance de v1 sin volver a estimar**.
- [ ] **10.** Correr de nuevo y verificar que el 100% de las facturas queda clasificado y que la conservación de filas se cumple.
- [ ] **11.** Commit: `[activacion-contratos-chile] Ajustar configuracion con hallazgos de datos reales`

**Criterio de completitud:** los tres entregables se generan sin error sobre los insumos reales de 2025 y 2026; el doble-cheque manual de 10 facturas coincide; los §10.1–§10.5 quedan cerrados o con recomendación documentada.

---

#### T-21 — README ejecutable por un tercero

**Archivos:**
- Modificar: `README.md`, `SESSION.md`

**Criterio del PRD §9:** *"Un tercero puede ejecutarlo siguiendo solo el `README.md`"*.

**Pasos:**

- [ ] **1.** Escribir el `README.md`: qué es el motor, qué produce, qué **no** hace, instalación, configuración de `fuentes.json` parámetro por parámetro, comando de ejecución, interpretación de los tres estados, y significado de cada exit code.
- [ ] **2.** **Prueba de terceros:** pedirle a alguien que no participó en el desarrollo que instale y corra el motor siguiendo solo el README, sobre los fixtures sintéticos. Anotar cada punto donde se atore.
- [ ] **3.** Corregir el README con lo que salga de la prueba.
- [ ] **4.** Actualizar `SESSION.md` con el cierre de v1 y los pendientes que pasan a v2.
- [ ] **5.** Correr la suite completa una última vez: `pytest tests/ -v` → **PASS**.
- [ ] **6.** Commit: `[activacion-contratos-chile] Agregar README ejecutable y cerrar v1`

**Criterio de completitud:** un tercero corre el motor sin ayuda del autor.

---

## 5. Cambios en base de datos

**No aplica.** El motor no persiste estado. Los resultados son archivos versionados por fecha; los insumos son de solo lectura. `sql/` queda reservado para cruces con vistas `vw_` de Athena si se necesitan en v2/v3 (PRD §11).

---

## 6. Endpoints nuevos o modificados

**No aplica.** El motor no expone API. Es un proceso batch invocado por línea de comandos (v1) o por n8n (v3).

---

## 7. Variables de entorno y configuración

| Variable / llave | Descripción | Ambiente |
|---|---|---|
| `config/fuentes.json` → `backend` | `local` (desarrollo) \| `drive` (producción) | Desarrollo / Producción |
| `config/fuentes.json` → `validacion.base_comparacion` | `neto` \| `total`. Default `neto`, se confirma en T-20 | Todos |
| `config/fuentes.json` → `validacion.tolerancia_pesos` | Margen de redondeo. Default `1` | Todos |
| `config/fuentes.json` → `drive.carpeta_*` | IDs de carpetas de Drive | Producción |
| `config/config.ini` → `[drive] service_account_json` | Ruta al JSON de la cuenta de servicio. **Fuera de git** | Producción |
| `config/config.ini` → `[ejecucion] log_level` | `DEBUG` \| `INFO` \| `WARNING` \| `ERROR` | Todos |

`config/config.example.ini` sí va a git, con las llaves documentadas y los valores vacíos.

---

## 8. Consideraciones de seguridad

**Datos personales.** Los insumos contienen RUT, nombres de beneficiarios, VIN y patentes de personas reales chilenas. Reglas ejecutables, no aspiracionales:

- `data/` está en `.gitignore` desde T-01, antes de que exista cualquier insumo.
- **Todos los tests usan fixtures sintéticos** (T-03). Ningún dato real entra al repositorio, ni siquiera como fixture.
- El logging referencia folios y conteos, nunca identidades (T-04, alineado con `rules/coding-guidelines.md` §9).
- `docs/validacion-datos-reales.md` (T-20) registra conteos y porcentajes, nunca cifras ni identidades.

**Credenciales.** El JSON de la cuenta de servicio de Drive vive fuera de git (`.gitignore` explícito en T-01) y su ruta se configura en `config.ini`. Nunca en el código fuente (`rules/infraestructura.md` §5).

**Permisos de Drive.** La cuenta de servicio necesita **lectura** sobre las carpetas de insumos y **escritura solo** sobre `Resultados_Motor/`. Solicitarla con ese alcance, no con acceso total a la carpeta raíz — principio de mínimo privilegio.

**Integridad de los insumos.** El motor nunca escribe en las carpetas de insumos (PRD §7.7). Se verifica manualmente en T-18 y T-19.

---

## 9. Consideraciones de infraestructura

**v1 no requiere infraestructura AWS.** El motor corre local. No hay costo incremental.

Para cuando llegue v3 (fuera de este plan), dejar constancia: la consola AWS de **Garanti Chile** es `sa-east-1` (São Paulo) según `rules/infraestructura.md` §1, y N8N corre hoy en VPS de Hostinger cuya **licencia vence en oct/nov del año en curso** — conviene contemplarlo antes de comprometer la orquestación a esa plataforma.

---

## 10. Criterios de aceptación

Tomados literalmente del PRD §9, cada uno con su verificación:

- [ ] Los tres entregables se generan sin error a partir de los insumos reales de 2025 y 2026 → **T-20 paso 1**
- [ ] El reporte de validación clasifica el **100%** de las facturas en uno de los 3 estados → **test `test_todas_las_facturas_reciben_exactamente_un_estado` (T-12)**
- [ ] Ninguna fila se pierde: `con factura + sin factura + excluidos = total de filas del Excel` → **invariante `verificar_conservacion` (T-13)**, ejecutada en cada corrida
- [ ] La suma de montos por año cuadra contra un doble-cheque manual de muestra → **T-20 paso 4**
- [ ] El motor corre headless y falla ruidoso (exit ≠ 0 + log claro) → **tests de exit code (T-17)**
- [ ] Un tercero puede ejecutarlo siguiendo solo el `README.md` → **T-21 paso 2**

Adicionales de este plan:

- [ ] La suite completa pasa: `pytest tests/ -v`
- [ ] Cambiar `base_comparacion` en `fuentes.json` altera la validación sin tocar código
- [ ] Cambiar `backend` a `drive` funciona sin ninguna otra modificación

---

## 11. Riesgos técnicos identificados

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **Parte del histórico ya está activo** — hubo una activación masiva hasta ~mediados de 2023 y posiblemente algunos contratos de 2024. Si el feed incluye contratos ya activos, el RPA genera **órdenes de pago duplicadas** sobre ~60 mil contratos | Alta | **Muy alto** | El motor **no puede detectarlo**: el estado de activación vive en SIGA, que no es insumo del MVP. Registrado como primera pregunta abierta del PRD §14. **Debe resolverse antes de correr el RPA sobre el histórico**, no antes de terminar el motor — no bloquea el desarrollo, sí bloquea la operación. Ver T-20 paso 11. |
| **Los montos del Excel son netos y se comparan contra `MntTotal`** → ~100% de facturas marcadas `NO_CUADRA` por el IVA (19%) | Alta | Alto | `base_comparacion` configurable con default `neto`; el reporte expone **ambos deltas** siempre, lo que hace el diagnóstico inmediato (T-11). Se cierra con datos en T-20. |
| **Namespace del DTE SII** ignorado al parsear → todo sale `NO_VERIFICABLE` sin error visible | Media | Alto | Namespace declarado explícitamente y test con XML que lo incluye (T-07); validación contra XML real en T-07 paso 5. |
| **El mapa de columnas del Excel no coincide con los archivos reales** — se construyó desde el PRD, no desde los archivos | Media | Alto | T-06 paso 5 obliga a validar contra archivo real antes de cerrar la tarea; mapeo por nombre con alias múltiples y aborto ruidoso si faltan las tres columnas esenciales. |
| **Credenciales de Drive no llegan a tiempo** (§10.8 abierta) | Media | Medio | `drive_io` abstraído desde T-09: Fases 0–3 completas sin credenciales. Solo se retrasa la Fase 4. |
| **El supuesto folio ↔ `FACTURA N°` no se cumple.** El transcript aporta evidencia en contra: en Colombia el número de factura coincide en dígitos con el folio de SIGA pero no en las letras, y **en Chile no existe consecutivo de SIGA** | Media | Alto | El motor lo mide en T-20 paso 3 y lo reporta como tasa de correspondencia, en vez de asumirlo. Si falla, se detecta antes de operar. |
| **Notas de crédito (DTE 61) alteran los montos** y no están contempladas en la conciliación | Media | Medio | `tipos_dte_validos` es configurable; T-20 paso 6 inventaría cuántas hay antes de decidir. Mientras tanto se reportan, no se descartan. |
| **CSV abierto en Excel chileno con separador equivocado** → una sola columna, inservible para el operador | Media | Bajo | Separador `;` y encoding `utf-8-sig` desde T-14; verificación manual de apertura. |
| **Faltan los Excel de 2024 y 2022–2023** (§10.7) | Alta | Bajo | El motor procesa lo que exista; `anios` es configurable. No bloquea v1. |

---

## 12. Notas para el programador

**Sobre la premisa corregida de este plan.** La primera versión asumía un repositorio vacío con solo el PRD. Era falso: existe un repo privado del desarrollador con la estructura, la configuración y el transcript ya construidos (§2.1). El plan se corrigió — T-01 y T-02 pasaron de "crear desde cero" a "heredar, verificar y extender", y la Fase 0 bajó de 2–3 a 1–2 días. **Lo que no cambió es el grueso del trabajo:** `src/` está vacío, así que T-05 a T-21 siguen íntegras. La lección operativa es verificar el estado real del repositorio antes de estimar, no inferirlo del PRD.

**Sobre la desviación de stack.** `rules/stack.md` fija .NET Core 8 como default obligatorio para todo backend nuevo, y este proyecto es Python. La justificación: el árbol de decisión de `rules/arquitectura.md` enruta *"flujo automatizado sin UI"* → **N8N**, que es exactamente este caso; el default de .NET aplica a backends con API REST y persistencia, y aquí no hay endpoints, ni base de datos, ni frontend. El trabajo es parseo de Excel y XML con `pandas`/`openpyxl`/`lxml`. **Esto está documentado, no escondido** — si el Gerente de TI prefiere que se escale antes de ejecutar, es una conversación de cinco minutos que conviene tener ahora y no en la Fase 3.

**Sobre `src/configuracion.py`.** No está en la estructura del PRD §11. Se agrega deliberadamente (T-02) porque sin él cada módulo parsearía `fuentes.json` por su cuenta. Es la única adición a la estructura especificada.

**Sobre el orden de las fases.** La Fase 4 (Drive) va al final a propósito, no por ser menos importante. El acceso a Drive es la decisión §10.8 abierta y la única que puede bloquear; poniendo el I/O tras una interfaz desde T-09, las Fases 0–3 producen un motor funcional y probado sin esperar credenciales.

**Sobre T-20.** No es una tarea de "pruebas finales". Es donde las decisiones abiertas del PRD §10 se cierran **con evidencia**: la base de comparación, el supuesto del folio, las exclusiones y las notas de crédito. Si se salta o se hace superficialmente, el motor entra a producción con supuestos sin verificar. Es la tarea de mayor valor por hora del plan.

**Lo que este plan no incluye y no debe agregarse sobre la marcha:** conciliación de pagos y set de activación (v2), orquestación n8n y tableros (v3), y cualquier ejecución del RPA o inyección en base de datos (los operan Omar y TI). El PRD es explícito en §3.2.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Andamiaje y contrato de datos** | Heredar el repo en Engine + ramas, extender `fuentes.json`, fixtures sintéticos, logging y exit codes | T-01 a T-04 | 1 – 2 días | |
| **Fase 1 — Normalización e ingesta** | `normalizacion`, `ingesta_excel`, `ingesta_xml`, `ingesta_pdf`, `drive_io` local | T-05 a T-09 | 4 – 6 días | |
| **Fase 2 — Conciliación y clasificación** | Agrupación por folio, comparación de montos, 3 estados, invariante de conservación | T-10 a T-13 | 3 – 4 días | |
| **Fase 3 — Entregables y ejecución headless** | `feed_rpa.csv`, `lista_ti.csv`, `reporte_validacion.xlsx`, `main.py` | T-14 a T-17 | 4 – 6 días | |
| **Fase 4 — Drive, datos reales y cierre** | Backend Drive, publicación, corrida real + doble-cheque, README | T-18 a T-21 | 4 – 6 días | |
| **Total proyecto (v1 completo)** | | **21 tareas** | **~16 – 24 días hábiles (≈ 3 – 5 semanas)** | — |
| **Guardarraíl — motor funcional en local** | Fase 0 + Fase 1 + Fase 2 + Fase 3 | T-01 a T-17 | **~12 – 18 días hábiles (≈ 2.5 – 3.5 semanas)** | — |

> **Notas sobre la tabla:**
> - El PRD **no define prioridades P1/P2/P3**; define versiones (v1/v2/v3). Todo este plan es **v1**. El guardarraíl equivalente es el motor funcional corriendo en local (Fases 0–3): produce los tres entregables y es verificable de punta a punta sin credenciales de Drive. La Fase 4 es lo que lo lleva a operación real.
> - Los rangos salen de la complejidad estimada por tarea. Las Fases 1 y 3 son las más anchas: la 1 porque el mapeo real de columnas del Excel es incógnita hasta abrir los archivos, la 3 porque el reporte de 5 hojas concentra trabajo de detalle.
> - La Fase 4 incluye tiempo de iteración: T-20 casi con certeza produce hallazgos que exigen volver a ajustar configuración y re-correr.
> - La columna **ID (BD)** la llena el flujo al registrar el plan; no editarla a mano.

> **Riesgo de deadline:** **el PRD no establece fecha límite.** Sin ella no es posible contrastar días disponibles contra el rango estimado, así que este plan no puede declarar riesgo de deadline en un sentido u otro. Dos cosas sí se pueden afirmar:
>
> 1. **Si aparece una fecha comprometida**, el recorte natural es entregar el guardarraíl (Fases 0–3, ~13–19 días) y diferir la Fase 4 — el motor queda funcional y auditable en local, operable manualmente descargando los insumos de Drive a mano, mientras se resuelven las credenciales.
> 2. **Un segundo desarrollador aporta poco al inicio y mucho al final.** Las Fases 0–2 son una cadena de dependencias estrecha (normalización → ingesta → validación) donde paralelizar genera más coordinación que ahorro. La Fase 3 sí paraleliza bien: los tres entregables son independientes entre sí (T-14, T-15, T-16 pueden ir en simultáneo). Estimación de compresión con un recurso adicional: **~15–20% del total**, concentrado en la Fase 3.

---

*Generado por Claude Code — Engine CX*
*Modelo: claude-opus-5 — esfuerzo: alto*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
