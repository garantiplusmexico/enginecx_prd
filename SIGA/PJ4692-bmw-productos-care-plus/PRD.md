# PRD — BMW: precios Jul 2026 + tercer producto "BMW Care Plus" + quitar filtro de marca

> Plantilla para features y bugfixes sobre proyectos existentes.

| Campo | Detalle |
|---|---|
| Proyecto / Sistema | Landing BMW (`bmw_landing`) + API de SIGA (Contracts) + DB portal BMW |
| Tipo | Feature (catálogo de productos) |
| Área / empresa | GarantiPlus México |
| Versión | v1.0 |
| Fecha | 2026-07-10 |
| Autores | Carlos Castellanos |
| Revisión / liderazgo | Aldo Álvarez (Dir. TI) · Mario Luna / Israel Escutia (negocio BMW) |

---

## 1. Resumen del cambio

Actualización del catálogo de productos de la landing BMW acordada en la junta de negocio:

1. **Precios nuevos** (Excel de Mario Luna "Pricing - Ajuste BMW Care", jul-2026): la columna *GarantiPlus* es el precio nuevo del producto existente; la columna *BMW Care Plus* introduce un **tercer producto**.
2. **Tercer producto "BMW Care Plus"**: por cada (marca, modelo) habrá ahora **2 productos** (líneas): *Excellence Mirror* (precios GarantiPlus) y *BMW Care Plus* (precios Care).
3. **Quitar el filtro** marca↔producto: hoy elegir "BMW/MINI Excellence Mirror" restringe las marcas seleccionables; se elimina para permitir selección libre. El campo "Producto" se conserva **para trazabilidad** de BMW.

Resultado esperado: la landing cotiza y crea contratos para 2 líneas de producto por modelo con los precios nuevos; marca/modelo se eligen libres; cada registro guarda con qué producto se vendió.

---

## 2. Contexto del cambio

**Hoy:**
- Existe **1 producto por (marca, modelo)** mapeado en `bmw_modelo_producto` (`UNIQUE(id_proyecto, marca, modelo)`); el seed vive en `bmw_landing/db_bmw/08_bmw_equivalencia_productos.sql` con precios de la hoja "BMW Financial Services".
- El dropdown "Producto" de la landing (`vehicleCatalog.ts` → `BMW_PRODUCT_FAMILIES`) tiene 2 familias ("BMW Excellence Mirror", "MINI Excellence Mirror") que **filtran** las marcas seleccionables.
- El backend resuelve el `id_producto` por `(marca, modelo)` (`BmwRegistrationService.ProductResolution.cs`), ignorando la modalidad; el precio se lee de `precio_producto` (12/24, mensual × meses).
- `bmw_registro` es la "fotografía" del formulario, pero **no** guarda con qué familia/línea se vendió.

**Qué dispara el cambio:** indicación de negocio (junta 2026-07-09): nuevos precios aprobados + creación del tercer producto Plus Care + simplificación de la captura (quitar filtro), conservando trazabilidad del producto para BMW.

**Decisiones cerradas con el responsable:**
- Precios y nombres **tal cual el Excel**; `i3 REX` **se elimina** (no está en la pricing nueva) → 33 modelos.
- **DB se restaura limpia** (local + QA) → seed de inserción limpia, sin lógica de UPDATE.
- Equivalencia gana columna `linea_producto` (`Excellence Mirror` | `Care Plus`); `UNIQUE(marca, modelo, linea_producto)` (sin `id_proyecto` en la constraint).
- Dropdown = **3 opciones** (BMW EM / MINI EM / Care Plus); **filtro quitado**; BMW EM y MINI EM mapean a la misma línea (Excellence Mirror), Care Plus a la suya.
- **Trazabilidad (Opción A):** se guarda la **selección exacta del dropdown** en una columna nueva de `bmw_registro` (`producto_bmw`). Motivo: BMW quiere trazabilidad de con qué producto se vendió cada garantía.

---

## 3. Alcance del cambio

**Qué entra:**

| Elemento | Descripción |
|---|---|
| Precios nuevos | Actualizar precios del producto existente (col GarantiPlus) — vía DB limpia. |
| Tercer producto Care Plus | 2 productos por (marca, modelo): Excellence Mirror y BMW Care Plus, cada uno con sus precios 12/24. |
| Dimensión `linea_producto` | Columna en `bmw_modelo_producto` + resolver por (marca, modelo, línea). |
| Quitar filtro marca↔producto | La landing deja de restringir marcas por familia; marca/modelo libres. |
| Dropdown "Producto" 3 opciones | BMW EM / MINI EM / Care Plus (trazabilidad); mapea a línea para resolver. |
| Trazabilidad en `bmw_registro` | Columna `producto_bmw` con la selección exacta. |
| Quitar `i3 REX` | Del catálogo (DB + `vehicleCatalog.ts`). |

**Qué NO entra:**

| Exclusión | Justificación |
|---|---|
| Guardar `bmw_registro.precio_producto` (precio cotizado) | Hueco de snapshot conocido; se atiende después (fuera de este alcance por decisión del responsable). |
| Guardar nombres texto `nombre_gerente/ejecutivo_fi/asesor` | Ídem; hoy solo se guardan los FK ids. |
| Cambios en el flujo de precio del backend | No requiere cambios: cada línea es un producto con sus filas `precio_producto`. |
| Migraciones/UPDATE de datos | La DB se restaura limpia. |

---

## 4. Requerimientos funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-01 | Dos líneas por modelo | Por (marca, modelo) existen 2 productos SIGA: `BMW - {marca} - {modelo}` (Excellence Mirror) y `BMW Care Plus - {marca} - {modelo}` (Care Plus). |
| RF-02 | Precios nuevos | Los precios provienen del Excel de Mario (GarantiPlus → Excellence Mirror; BMW Care Plus → Care Plus), 12 y 24 meses, guardados mensuales. |
| RF-03 | Sin `i3 REX` | El modelo `i3 REX` no existe en el catálogo nuevo (DB ni landing). |
| RF-04 | Resolución por línea | El backend resuelve el producto por (marca, modelo, `linea_producto`). |
| RF-05 | Dropdown 3 opciones | La landing muestra BMW EM / MINI EM / Care Plus. |
| RF-06 | Sin filtro de marca | Cualquier opción de "Producto" permite elegir cualquier marca/modelo. |
| RF-07 | Mapeo dropdown→línea | BMW EM y MINI EM → `Excellence Mirror`; Care Plus → `Care Plus`. |
| RF-08 | Trazabilidad | Al crear el contrato se guarda la selección exacta del dropdown en `bmw_registro.producto_bmw`. |
| RF-09 | Cotización correcta por línea | El precio mostrado corresponde al producto de la línea elegida (Care Plus ≠ Excellence Mirror). |

---

## 5. Requerimientos no funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RNF-01 | Sin regresión de precio | El flujo de precio del backend no cambia; sigue leyendo `precio_producto` por duración. |
| RNF-02 | Unicidad de equivalencia | `UNIQUE(marca, modelo, linea_producto)` evita ambigüedad al resolver (sin `LIMIT 1` arbitrario). |
| RNF-03 | Nombres canónicos | El seed usa los nombres de marca/modelo del catálogo del front (`vehicleCatalog.ts`). |
| RNF-04 | Idempotencia del seed | Se conserva el patrón find-or-create por `nombre_producto`. |

---

## 6. Componentes e integraciones afectadas

| Componente | Tipo | Descripción |
|---|---|---|
| `bmw_landing/db_bmw/08_bmw_equivalencia_productos.sql` | Modificación | Columna `linea_producto`, UNIQUE nueva, seed 66 filas (33×2), precios nuevos, sin i3 REX. |
| `bmw_landing/db_bmw/02_schema_bmw_portal.sql` | Modificación | Columna `producto_bmw` en `bmw_registro`. |
| `gp_3.0_siga_api` `BmwRegistrationService.ProductResolution.cs` | Modificación | Resolver por `linea_producto`. |
| `gp_3.0_siga_api` `BmwController.cs` (`ResolveProductByVehicle`) | Modificación | Param `linea`. |
| `gp_3.0_siga_api` `CreateBmwLandingContractForm.cs` + factory + `InsertRegistrationAsync` | Modificación | Campo/persistencia de `producto_bmw`. |
| `bmw_landing/src` (`vehicleCatalog.ts`, `ProductDetailSection`, `VehicleInfoSection`, `RegistrationPortal`, `sigaService`, `buildBmwContractFormData`, `types`, `validation`) | Modificación | 3 opciones, quitar filtro, mandar línea + familia. |
| Base de datos | Restauración limpia | Local + QA; sin migración. |

---

## 7. Decisiones cerradas (antes preguntas abiertas)

| Tema | Resolución |
|---|---|
| `i3 REX` | Se elimina (solo modelos del listado nuevo). |
| Precios que cambian | DB limpia → seed sin UPDATE. |
| Modelado 3er producto | Columna `linea_producto`; 2 productos/modelo; UNIQUE(marca, modelo, linea_producto). |
| Filtro de marca | Se quita; el campo Producto queda para trazabilidad. |
| Granularidad de trazabilidad | Opción A: se guarda la selección exacta (3 valores) en `producto_bmw`. |
| Nombres de modelo | Tal cual el Excel (normalizados al catálogo del front). |
| Alcance del snapshot | Solo producto/línea; precio cotizado y nombres de equipo quedan fuera. |

---

*Engine CX — Departamento de Desarrollo*
*Versión: v1.0*
