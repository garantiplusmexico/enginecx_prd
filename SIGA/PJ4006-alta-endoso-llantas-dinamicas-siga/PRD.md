# PRD — Alta y endoso de llantas dinámicas en SIGA web (estilo Bridgestone)

| Campo | Detalle |
|---|---|
| Proyecto / Sistema | SIGA web — `GarantiplusWeb` (`gp_4.0_siga`); backend `VentasService` y microservicio `Endosos` |
| Tipo | Feature / Mejora |
| Área / empresa | GarantiPlus México, Colombia y Chile |
| Versión | v0.1 |
| Fecha | 2026-07-08 |
| Autores | Carlos Castellanos |
| Revisión / liderazgo | Aldo Álvarez (Director de TI) — por confirmar |

---

## 1. Resumen del cambio

En SIGA web (`GarantiplusWeb`), los contratos de llantas se capturan hoy con una estructura rígida: **una sola** marca/modelo/medida y exactamente **4 DOT** (un select de "Nº de llantas" de 1 a 4). Esto obliga a partir o rechazar contratos con más de 4 llantas y no refleja escenarios de flotilla o de varias medidas en un mismo contrato.

El cambio convierte la captura de llantas en una **lista dinámica al estilo del proyecto Bridgestone (BS)**: un botón "Agregar llanta" y filas con `Marca / Modelo / Medida / DOT / Cantidad` y borrar por fila. Cada fila es una llanta con su propio DOT, donde `Cantidad` indica cuántas llantas comparten ese DOT (relación 1 DOT : N llantas, igual que BS). El total de llantas del contrato se valida contra un tope configurable (20) vía `appsettings`.

El cambio aplica a **dos superficies**: la **creación** del contrato (donde el backend de `VentasService` ya soporta la lista dinámica) y el **endoso/modificación** (donde hay que rehacer la ruta gRPC y el microservicio `Endosos`, hoy cableados a 4 DOT). Resultado esperado: capturar y endosar N llantas (hasta 20) con marca/modelo/medida/DOT/cantidad por fila, sin el límite artificial de 4, reutilizando el almacenamiento jerárquico ya existente.

---

## 2. Contexto del cambio

**Cómo funciona hoy:**

- **Creación:** en `Areas/Contratos/Views/Contratos/Create.cshtml` (sección "Datos de la Garantía de Llanta") y el partial `Areas/Contratos/Views/Contratos/_DatosLlantas.cshtml` hay un select "Nº de llantas" de **1 a 4**, una marca/modelo/medida únicas y hasta 4 inputs DOT que se muestran/ocultan con `MostrarDots()`. El `ContratosController.Create/Edit` recibe `informacion_llantas` (un solo objeto) + `string[] dots` y llama la sobrecarga **legacy** de `VentasBusinessRules.CreateContract`.
- **Endoso:** el modal "Modificando Información de Llantas" (`Areas/Contratos/Views/Endosos/_TiresEndorsement.cshtml`) postea a `EndososController.EndosoLlantas`, que arma un `TiresEndorsementRequest` **gRPC** con campos fijos `DotLlanta1..4` / `IdDot1..4` y una sola marca/modelo/medida (`Protos/Endosos.proto:122-140`). El microservicio `Endosos` aplica endosos atómicos por campo (`EndosoLlantaMarca/Modelo/Medida`, `EndosoLlantaDotUno..Cuatro`).

**Qué ya está resuelto (no se rehace):**

- El **almacenamiento** ya es jerárquico y dinámico: `contrato → poliza → informacion_llantas (1:N) → dot_llanta (1:N)`. **No requiere cambio de esquema.** Entidades en `DataAccess/Models/informacion_llantas.cs` y `dot_llanta.cs` (espejo en `DataAccessColombia`).
- `VentasService` ya expone `CreateContract(..., IReadOnlyList<TireContractLine> tireContractLines, ...)` que crea **una fila `informacion_llantas` por línea** con sus DOTs (`VentasService/src/Ventas.Domain/Classes/VentasBusinessRules.cs:399-469`). La web aún llama la versión "de a 1".

**Necesidad que dispara el cambio:** alinear SIGA con el comportamiento ya usado por BS (contratos con múltiples llantas/medidas/flotilla), eliminando el tope de 4 y unificando la experiencia de captura.

**Referencia BS:** UI `bridgestone_landing/src/features/warranty-registration/sections/TiresSection.tsx` (React, filas dinámicas, 5 columnas, borrar si hay >1) con modelo `TireDetail { tireBrand, tireModel, tireSize, dot, tireCount }`; validación de tope en el backend `gp_3.0_siga_api` (`ContractTireLimitsOptions`, sección `ContractTireLimits`, `Min/MaxPerContract`).

---

## 3. Alcance del cambio

**Qué entra:**

| Elemento | Descripción |
|---|---|
| UI creación — lista dinámica | Reemplazar el select 1-4 + DOTs fijos por filas dinámicas "Agregar/Quitar llanta" con `Marca/Modelo/Medida/DOT/Cantidad`, calcando la UX de BS. Reutilizar el patrón de filas de Averías (`addSpare`/`deleteSpare`). |
| ViewModel creación como lista | Cambiar el `informacion_llantas` único de `ContratoViewModel` por una **lista** de líneas y hacer que `ContratosController.Create/Edit` invoque la sobrecarga `CreateContract(IReadOnlyList<TireContractLine>)` ya existente. |
| Validación de tope (creación) | Nuevo `Options` tipado (p. ej. `ContractTireLimits`) en `gp_4.0_siga` leído de `appsettings`, con `MaxPerContract = 20` (y `MinPerContract`). Validar que la **suma de cantidades** de todas las filas ≤ 20. Espejo de la lógica de BS en `gp_3.0_siga_api`. |
| Validación por fila | DOT obligatorio por fila, marca/modelo/medida requeridos, `Cantidad ≥ 1`. Backend obligatorio; front como aviso previo al envío. |
| Endoso — UI dinámica | Rehacer el modal "Modificando Información de Llantas" para editar N filas: agregar, quitar y editar `Marca/Modelo/Medida/DOT/Cantidad`. |
| Endoso — backend gRPC | Rehacer `Endosos.proto` (`TiresEndorsementRequest`) para soportar una **lista repetida** de líneas de llanta (cada una con sus DOTs) en vez de `DotLlanta1..4` fijos; y el microservicio `Endosos` para aplicar **add/update/delete** sobre la colección `informacion_llantas`/`dot_llanta`, manteniendo la auditoría de endoso (solicitante, motivo). |
| Multi-país | Aplicar a MEX, COL y CHL. Mantener el espejo `DataAccess` ↔ `DataAccessColombia` si se toca cualquier modelo/mapeo. |

**Qué NO entra:**

| Exclusión | Justificación |
|---|---|
| Cambios de esquema de BD para llantas | `informacion_llantas` + `dot_llanta` ya soportan N líneas y N DOTs; no se requiere migración. |
| Tabla `bs_llantas` / flyer Bridgestone | Es MX-only, SQL crudo del PDF de BS, ajeno al flujo de SIGA web. |
| Cálculo automático del "Número de llantas" | Por decisión, la Cantidad por fila se captura manualmente (no se autocalcula un total capturable). El total solo se usa para validar el tope y para el pricing. |
| Cambios en el pricing de llantas | `BuildAggregatedTiresInfoForPricing` ya agrega la lista; no se modifica la lógica de precios. |
| Rediseño visual general de la pantalla de contratos | Solo se toca el bloque de llantas. |

---

## 4. Requerimientos funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-01 | Lista dinámica en creación | En la creación de contrato de llantas, el usuario puede agregar y quitar filas de llanta; cada fila captura `Marca`, `Modelo`, `Medida`, `DOT` y `Cantidad`. Al menos 1 fila obligatoria. |
| RF-02 | Persistir N líneas | Al guardar, cada fila se persiste como un `informacion_llantas` propio (con `numero_llantas = Cantidad`) y su `DOT` como `dot_llanta`, vía la sobrecarga `CreateContract(IReadOnlyList<TireContractLine>)`. |
| RF-03 | Modelo por fila (1 DOT : N llantas) | Cada fila tiene un único DOT; `Cantidad` indica cuántas llantas comparten ese DOT (igual que BS). |
| RF-04 | Validación por fila | DOT obligatorio; `Marca`, `Modelo`, `Medida` requeridos; `Cantidad ≥ 1`. Mensajes de error al usuario en español. |
| RF-05 | Tope de llantas por contrato | La suma de las cantidades de todas las filas no puede exceder `ContractTireLimits.MaxPerContract` (= 20). Validación **obligatoria en backend** vía `appsettings`; la UI avisa/bloquea antes de enviar. |
| RF-06 | Endoso — cargar N filas | El modal de endoso carga **todas** las líneas de llanta existentes del contrato (no solo 4), con sus DOTs. Compatible con contratos previos. |
| RF-07 | Endoso — agregar/quitar/editar | En el endoso el usuario puede agregar nuevas llantas, eliminar existentes y editar `Marca/Modelo/Medida/DOT/Cantidad` de cada fila, respetando el tope de 20. |
| RF-08 | Endoso — auditoría | El endoso sigue exigiendo `Solicitante del Endoso` y `Motivo del Endoso`, y registra los cambios (add/update/delete) en el seguimiento de endosos. |
| RF-09 | Multi-país | El comportamiento es idéntico en MEX, COL y CHL. |

---

## 5. Requerimientos no funcionales *(solo los que aplican)*

| ID | Requerimiento | Descripción |
|---|---|---|
| RNF-01 | Configurable sin recompilar | El tope de llantas vive en `appsettings` (`ContractTireLimits`), ajustable por ambiente sin recompilar. |
| RNF-02 | Compatibilidad hacia atrás | Contratos y endosos existentes (creados con la estructura de hasta 4 DOT) deben cargarse y editarse sin error con la nueva UI/servicio. |
| RNF-03 | Consistencia de código | Seguir `CODING_GUIDELINES.md` de SIGA (Options sin hardcode, mensajes de usuario en español, logs técnicos en inglés, auditoría). Mantener espejo `DataAccess` ↔ `DataAccessColombia`. |
| RNF-04 | Integridad transaccional | El endoso con add/update/delete de varias filas debe aplicarse de forma consistente (todo o nada) para no dejar el contrato con llantas parciales. |

---

## 6. Componentes e integraciones afectadas

| Componente / Integración | Tipo de cambio | Descripción |
|---|---|---|
| `Areas/Contratos/Views/Contratos/Create.cshtml` | Modificación | Reemplazar select 1-4 + `MostrarDots()` por filas dinámicas de llanta. |
| `Areas/Contratos/Views/Contratos/_DatosLlantas.cshtml` | Modificación | Partial de captura de llantas (usado también en `EmisionEspecial.cshtml`): pasar a lista dinámica. |
| `Areas/Contratos/Models/ContratoViewModel.cs` | Modificación | Cambiar `informacion_llantas` único por lista de líneas de llanta. |
| `Areas/Contratos/Controllers/ContratosController.cs` (`Create`, `Edit`) | Modificación | Bindear la lista de filas e invocar `CreateContract(IReadOnlyList<TireContractLine>)`. |
| `VentasService` — `VentasBusinessRules` / `IVentasBusinessRules` | Solo lectura / reutilización | Ya expone la sobrecarga de lista; se consume tal cual. Añadir aquí (o en el controller) la validación de tope. |
| Nuevo `Options` `ContractTireLimits` + `appsettings*.json` (gp_4.0_siga) | Nuevo | `Min/MaxPerContract` (Max = 20), registrado en DI. Espejo del `ContractTireLimitsOptions` de `gp_3.0_siga_api`. |
| `Protos/Endosos.proto` (`TiresEndorsementRequest`) | Modificación | Sustituir `DotLlanta1..4`/`IdDot1..4` por una lista repetida de líneas (marca/modelo/medida/cantidad + repeated dots {id, dot}). |
| Microservicio `Endosos` (`EndososService`, `Vehiculo/EndosoLlanta*`) | Modificación | Aplicar add/update/delete sobre `informacion_llantas`/`dot_llanta`; generalizar los endosos atómicos hoy fijos a Dot1..4; conservar auditoría. |
| `Areas/Contratos/Views/Endosos/_TiresEndorsement.cshtml` + `Endorsements/_Tire.cshtml` + JS `updateTires()`/`editTires()` | Modificación | UI del endoso a filas dinámicas. |
| `Areas/Contratos/Controllers/EndososController.cs` (`LoadTiresView`, `EndosoLlantas`) | Modificación | Cargar N líneas y enviar la lista al gRPC. |
| Entidades EF `informacion_llantas` / `dot_llanta` (`DataAccess` y `DataAccessColombia`) | Solo lectura | Sin cambio de esquema; se reutilizan. |
| Patrón de filas dinámicas de Averías (`RefaccionesPermitidas/Create.cshtml`: `addSpare`/`deleteSpare`) | Solo lectura / reutilización | Referencia idiomática para el JS de agregar/quitar filas con binding `coleccion[KEY].prop` + `coleccion.Index`. |

---

## 7. Preguntas abiertas

| Tema | Pregunta abierta |
|---|---|
| Chile | No existe `DataAccessChile`; se asume que CHL corre sobre el contexto EF vía el switch de país base y que ya tiene las tablas `informacion_llantas`/`dot_llanta`. **Confirmar** que el ambiente de Chile tiene el esquema y que no requiere GRANT/seed adicional. |
| Valor del tope | Se fija `MaxPerContract = 20` (BS usa 100 hoy). Confirmar que 20 es el valor de negocio definitivo para SIGA y si difiere por país. |
| Formato de DOT | BS valida en front con regex `^[A-Za-z0-9 ]{4,15}$` y solo longitud en back. ¿SIGA debe aplicar el mismo regex o validación de DOT propia? |
| Endoso — pricing/póliza | Al agregar/quitar llantas en un endoso, ¿debe recalcularse precio/póliza o el endoso es solo de datos (marca/modelo/medida/DOT/cantidad) sin tocar el importe? |
| Producto que activa el bloque llantas | Confirmar que la visibilidad del bloque de llantas seguirá atada al tipo de producto llanta actual (sin cambios en esa condición). |
| Revisión técnica | Confirmar si la revisión recae en Aldo Álvarez (Director de TI). |

---

*Engine CX — Departamento de Desarrollo — v0.1*
