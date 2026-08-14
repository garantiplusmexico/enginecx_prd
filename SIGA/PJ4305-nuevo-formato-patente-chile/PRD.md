# PRD - Nuevo formato de patente (placa) para Chile

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Nuevo formato de patente (placa) para Chile |
| **Área / empresa** | Garantiplus Chile |
| **Versión** | v0.1 |
| **Fecha** | 2026-08-13 |
| **Autores** | Alejandro Govea Hernández |
| **Revisión / liderazgo** | Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web o API |

## 1. Resumen ejecutivo

El módulo de **emisión** de SIGA (Chile) valida hoy el campo **patente** aceptando únicamente el formato histórico de 4 letras + 2 números (`LLLL-NN`). El Ministerio de Transportes de Chile introdujo un nuevo formato de matriculación de 5 letras + 1 número (`LLLLL-N`), cuya emisión de placas inicia a partir de **agosto de 2026**. Con la validación actual, un asesor no puede emitir un contrato para un vehículo con patente nueva, lo que bloquea la operación.

Este proyecto **actualiza la validación del campo patente en el módulo de emisión** para aceptar exactamente **dos** formatos —`LLLL-NN` y `LLLLL-N`— y **rechazar** cualquier otro. Es un cambio acotado, de alta urgencia por la entrada en vigor inminente del nuevo formato.

El MVP cubre exclusivamente la validación en **emisión** (frontend + backend), con entrada **normalizada** (mayúsculas, sin espacios, guion opcional). No se modifica el comportamiento de otros módulos en esta versión.

Resultado esperado: los vehículos con patente nueva pueden emitirse sin fricción, sin romper la emisión de patentes antiguas que siguen circulando.

**Captura de patente** → **normalización** → **validación (2 formatos válidos)** → **emisión permitida / error con formatos válidos**

## 2. Contexto y problema

- **Hoy:** en el módulo de emisión, el campo patente se valida contra un único patrón (`LLLL-NN`: 4 letras + 2 números). Cualquier valor fuera de ese patrón se rechaza.
- **Dolor:** el nuevo formato oficial `LLLLL-N` (5 letras + 1 número) no pasa la validación → no se pueden emitir contratos para vehículos matriculados con el esquema nuevo. Es un bloqueo operativo directo, no un tema estético.
- **Por qué ahora:** la matriculación con el nuevo formato entra en vigor a partir de **agosto de 2026** (ya vigente al momento de este PRD). Cada día sin el cambio implica emisiones bloqueadas para vehículos nuevos.
- **Distinción de dominio:** ambos formatos son **válidos y coexisten** — el nuevo no reemplaza al anterior; los vehículos antiguos conservan `LLLL-NN`. La regla debe aceptar los dos, no migrar de uno a otro.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Asesor / ejecutivo de emisión (Chile) | Captura la patente al emitir el contrato; es quien enfrenta hoy el bloqueo. |
| Operaciones Garantiplus Chile | Define reglas de negocio y confirma el formato de almacenamiento vigente. |
| Equipo de desarrollo (SIGA) | Implementa la validación en frontend y backend. |
| TI / Revisión técnica | Valida el diseño y la salida a producción. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Aceptar formato histórico | El campo patente acepta 4 letras + 2 números (`LLLL-NN`). |
| Aceptar formato nuevo | El campo patente acepta 5 letras + 1 número (`LLLLL-N`). |
| Rechazar cualquier otro | Todo valor que no corresponda exactamente a uno de los dos formatos se rechaza. |
| Normalización de entrada | Antes de validar, la entrada se convierte a mayúsculas, se eliminan espacios y el guion es opcional. |
| Mensaje de error guiado | Si la patente es inválida, se muestra un mensaje que indica los dos formatos válidos. |
| Validación en dos capas | La regla se aplica en el frontend (feedback inmediato) y en el backend/API (fuente de verdad). |

**Principio rector del MVP:** aceptar **exactamente** los dos formatos oficiales y nada más; la validación de frontend y backend debe ser **idéntica** para no dejar pasar datos inválidos por el servicio ni bloquear datos válidos en la UI. El MVP no reestructura el almacenamiento ni toca otros módulos.

## 6. Fuera de alcance

- **Otros módulos (búsqueda, averías, reportes, etc.):** el MVP solo toca emisión; extender la regla a otros puntos requiere un inventario aparte y se difiere hasta confirmar impacto.
- **Migración/normalización de patentes ya almacenadas:** no se reprocesan registros existentes; solo se valida la captura nueva.
- **Reglas de letras específicas del estándar chileno (exclusión de ciertas letras):** el MVP valida el patrón letras+números genérico; afinar qué letras son admisibles queda pendiente de confirmación (ver Preguntas abiertas).
- **Cambio del formato de almacenamiento:** no se modifica cómo se persiste la patente hasta confirmar el esquema vigente con operaciones.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Aceptar `LLLL-NN` | El sistema acepta patentes de 4 letras seguidas de 2 números. |
| RF-02 | Aceptar `LLLLL-N` | El sistema acepta patentes de 5 letras seguidas de 1 número. |
| RF-03 | Rechazar otros formatos | Cualquier valor que no cumpla exactamente RF-01 o RF-02 se rechaza. |
| RF-04 | Normalizar entrada | Antes de validar, convierte a mayúsculas, elimina espacios y trata el guion como opcional. |
| RF-05 | Mensaje de error guiado | Ante entrada inválida, muestra un mensaje indicando los dos formatos válidos. |
| RF-06 | Validación en frontend y backend | La misma regla se aplica en la UI de emisión y en el servicio/API. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Consistencia de reglas | La validación de frontend y backend produce el mismo resultado para cualquier entrada. |
| RNF-02 | Mantenibilidad | El patrón de validación se define de forma centralizada/parametrizable para facilitar futuros ajustes. |
| RNF-03 | Experiencia de usuario | El error se muestra de inmediato en la captura, sin requerir el envío del formulario para enterarse. |
| RNF-04 | Trazabilidad | Los rechazos de validación quedan registrados según el manejo de errores/logs actual del módulo. |
| RNF-05 | Alcance regional | El cambio aplica al contexto de Chile sin alterar la validación de patente de otros países. |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| Módulo de emisión (SIGA) | Lectura/escritura del campo patente durante la emisión del contrato. |
| API / backend de SIGA | Aplica la validación como fuente de verdad antes de persistir. |

**Datos mínimos:** campo **patente** (string) del contrato en emisión.

**Esquema de permisos:** sin cambios respecto al actual — quien hoy puede emitir contratos sigue capturando la patente; el cambio es únicamente la regla de validación del campo, no altera accesos ni roles.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Emisiones con formato nuevo | Nº de contratos emitidos con patente `LLLLL-N` tras el despliegue (antes: 0, imposibles). |
| Rechazos de patentes válidas | Debe tender a 0: ninguna patente de formato válido debe ser rechazada. |
| Bloqueos reportados por operación | Reducción/eliminación de tickets por "no puedo emitir, patente inválida". |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Divergencia frontend/backend | Si las reglas no quedan idénticas, la UI podría bloquear válidos o el backend aceptar inválidos. |
| Formato de almacenamiento no confirmado | Si el guardado real difiere de lo asumido, la normalización podría persistir en un formato inesperado. |
| Otros módulos siguen con la regla vieja | Búsqueda/averías/reportes podrían rechazar patentes nuevas, generando fricción no cubierta por el MVP. |
| Reglas de letras del estándar chileno | Si el estándar excluye ciertas letras y no se contempla, se podrían aceptar patentes técnicamente imposibles. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Coexistencia de formatos | `LLLL-NN` y `LLLLL-N` son ambos válidos; el nuevo no reemplaza al anterior. |
| Alcance limitado a emisión | Ningún otro módulo requiere el cambio en esta versión. |
| Almacenamiento alfanumérico sin guiones | Se asume que hoy se guarda sin guion (por confirmar con operaciones). |
| Patrón genérico letras+números | Se validan las cantidades de letras/números; no se filtran letras específicas en el MVP. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Almacenamiento | ¿En qué formato se persiste hoy la patente (alfanumérico sin guion vs. con guion)? Confirmar con operaciones. |
| Reglas de letras | ¿El estándar chileno excluye ciertas letras (p. ej. vocales o letras ambiguas)? ¿Debe validarse eso? |
| Alcance futuro | ¿Se extenderá la validación a búsqueda/averías/reportes en una fase posterior? |
| Texto del mensaje | Redacción final exacta del mensaje de error (a validar con UX/operación). |
| Fecha de salida | No hay fecha comprometida; se priorizará como "lo antes posible" y se programará en el Gantt. |
