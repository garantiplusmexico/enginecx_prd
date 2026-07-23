# PRD - Trazabilidad de usuario que crea contratos

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Trazabilidad de usuario que crea contratos |
| **Área / empresa** | Garantiplus (México, Colombia y Chile) |
| **Versión** | v0.1 |
| **Fecha** | 2026-07-23 |
| **Autores** | Operaciones / Colombia (solicitante); PM·AI |
| **Revisión / liderazgo** | Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web / API |

## 1. Resumen ejecutivo

SIGA gestiona la creación de garantías (contratos) en las operaciones de Garantiplus México, Colombia y Chile. Hoy, una vez creada una garantía, **no es visible quién la creó** en los reportes e informes que consume el negocio, lo que dificulta las auditorías y el control interno.

El dato del usuario creador **ya existe** en la base de datos (columna `registra_contrato` de la tabla `contrato`) e incluso `usuario_creador` ya se usa como criterio para **filtrar** reportes; lo que falta es **exponerlo** de forma consistente en las superficies de consulta.

El MVP consiste en **mostrar el usuario creador de cada garantía** (valor de `contrato.registra_contrato`, etiquetado como "Usuario creador") en los reportes de **Producción** y **Explotación**, en sus **exports a Excel** y en la **pantalla/detalle del contrato**, en los tres países. No se calcula ni captura ningún dato nuevo: solo se presenta uno ya almacenado.

El resultado esperado es **trazabilidad y auditabilidad** de la autoría de cada garantía, mejorando el control interno, **sin impacto en la captación** ni en los flujos de creación existentes.

**Crear garantía (SIGA)** → **`registra_contrato` almacenado** → **reportes/exports/detalle exponen "Usuario creador"** → **auditoría identifica al creador**

## 2. Contexto y problema

- **Hoy:** las garantías se crean en SIGA y el sistema guarda internamente al usuario creador (`contrato.registra_contrato`), pero ese dato **no se muestra** en los reportes de Producción y Explotación, ni en sus exports, ni en el detalle del contrato. `usuario_creador` solo se aprovecha para filtrar.
- **Dolor:** sin el creador visible, las **auditorías y el control interno** no pueden atribuir cada garantía a quien la registró; se depende de consultas manuales a BD.
- **Por qué ahora:** requerimiento de Operaciones/Colombia para reforzar auditoría y control interno. Importancia **media**, sin urgencia contractual conocida.
- **Concepto de dominio:** en este proyecto **"garantía" y "contrato" son sinónimos** (la garantía *es* el registro de contrato). El campo de referencia en Chile aparece como **"Usuario registra"**; en este PRD lo llamamos **"Usuario creador"**.

## 3. Objetivo del producto

Dar **trazabilidad del usuario creador de cada garantía** exponiendo el campo `contrato.registra_contrato` como columna/dato "Usuario creador" en los reportes de Producción y Explotación, sus exports a Excel y la pantalla de detalle del contrato, de forma consistente en México, Colombia y Chile, para habilitar auditoría y control interno sin alterar los procesos de creación.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Auditoría / Control interno | Consumidor principal: usa el dato para atribuir cada garantía a su creador. |
| Operaciones (MX/CO/CL) | Solicitante; consulta reportes con el creador visible. |
| Usuario creador (agente/operador) | Quien registra la garantía en SIGA; su identidad queda expuesta. |
| TI / Desarrollo | Extiende SPs/queries, reportes, exports y pantalla; revisión técnica (Alexis Herrera). |
| BI | Define línea base y metas de las métricas de éxito. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Columna "Usuario creador" en reporte Producción | Mostrar `contrato.registra_contrato` como nueva columna en el reporte de Producción. |
| Columna "Usuario creador" en reporte Explotación | Igual para el reporte de Explotación. |
| Columna en exports Excel | Incluir "Usuario creador" en las exportaciones a Excel de dichos reportes. |
| Dato en pantalla/detalle del contrato | Mostrar el usuario creador en la vista de detalle de la garantía. |
| Extensión de SPs/queries | Extender los SPs/queries que alimentan reportes/exports para exponer `registra_contrato` donde hoy falte. |
| Cobertura multi-país | Aplicar el cambio en las instancias de México, Colombia y Chile. |

**Principio rector del MVP:** solo se **expone** un dato ya existente (lectura/presentación); **no** se captura, calcula ni modifica información, y **no** se altera el flujo de creación de garantías.

## 6. Fuera de alcance

- **Backfill de históricos:** las garantías creadas sin el dato disponible saldrán vacías; recuperarlas requeriría fuente alterna y se difiere.
- **Captura o cambio del creador:** no se agrega edición ni corrección del usuario creador.
- **Nuevos reportes:** solo se extienden Producción y Explotación (y sus exports); no se crean reportes nuevos.
- **Resolución a nombre legible:** se muestra `registra_contrato` tal como se almacena; normalizar a nombre completo queda pendiente de validación (ver sección 14).
- **Unificación de naming entre países:** estandarizar "Usuario creador" vs "Usuario registra" (Chile) no es obligatorio en el MVP.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Mostrar creador en Producción | El reporte de Producción incluye la columna "Usuario creador" con el valor de `contrato.registra_contrato`. |
| RF-02 | Mostrar creador en Explotación | El reporte de Explotación incluye la columna "Usuario creador" con el mismo valor. |
| RF-03 | Creador en exports Excel | Los exports a Excel de ambos reportes incluyen la columna "Usuario creador". |
| RF-04 | Creador en detalle de contrato | La pantalla/detalle de la garantía muestra el usuario creador. |
| RF-05 | Extender SPs/queries | Se extienden los SPs/queries que alimentan reportes, exports y detalle para exponer `registra_contrato` donde falte. |
| RF-06 | Cobertura MX/CO/CL | Los cambios aplican en las instancias de México, Colombia y Chile. |
| RF-07 | Consistencia con filtro | El valor mostrado es consistente con el `usuario_creador` ya usado para filtrar reportes. |
| RF-08 | Manejo de dato ausente | Si una garantía no tiene `registra_contrato`, la columna/campo se muestra vacío sin generar error. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Trazabilidad / auditabilidad | El creador expuesto debe corresponder fielmente al registrado en BD, apto para auditoría. |
| RNF-02 | Permisos | El nuevo dato hereda el control de acceso actual de cada reporte/pantalla; no se expone a quien no tiene acceso hoy. |
| RNF-03 | Consistencia de datos | El valor proviene directo de `contrato.registra_contrato`, sin transformación que altere su significado. |
| RNF-04 | Rendimiento | La inclusión de la columna no debe degradar de forma perceptible los tiempos de los reportes/exports. |
| RNF-05 | Compatibilidad multi-país | Respetar las particularidades por país (p. ej. Chile ya expone "Usuario registra") sin romper reportes existentes. |
| RNF-06 | Mantenibilidad | Cambios mínimos y localizados en SPs/queries/reportes, sin duplicar lógica innecesaria. |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| BD SIGA — tabla `contrato` | Lectura del campo `registra_contrato` (usuario creador). |
| Reportes Producción y Explotación | Consumen SPs/queries que deben exponer el nuevo campo. |
| Motor de export a Excel | Incluir la nueva columna en la salida. |
| Pantalla/detalle de contrato (UI SIGA) | Mostrar el usuario creador. |

**Datos mínimos:** `contrato.registra_contrato` (usuario creador), identificador de la garantía/contrato, país/instancia. Referencia: en Chile ya existe la columna equivalente "Usuario registra".

**Esquema de permisos:** operación **de solo lectura**; no se escribe, crea ni modifica ningún dato. El acceso al nuevo campo queda **restringido al control de acceso ya vigente** de cada reporte/pantalla; no se abre ninguna superficie nueva de datos.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Cobertura de superficies | Reportes Producción/Explotación, exports y detalle muestran "Usuario creador" en los 3 países. |
| % de garantías nuevas con creador visible | Proporción de garantías creadas tras el cambio que muestran el dato correctamente. |
| Uso en auditoría | Reducción de consultas manuales a BD para identificar al creador (pendiente de línea base con BI/operación). |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Alcance real de SPs/queries incierto | El "donde falte `registra_contrato`" puede abarcar más objetos de los previstos, ampliando el esfuerzo. |
| Inconsistencia de naming entre países | Confusión si conviven "Usuario creador" (MX/CO) y "Usuario registra" (CL). |
| Históricos sin dato | Columnas vacías podrían malinterpretarse en auditoría. |
| `registra_contrato` no poblado en todos los flujos | Algunas garantías nuevas podrían no traer el dato si algún flujo de creación no lo registra. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| El campo existe y se puebla | `contrato.registra_contrato` se guarda en la creación actual de garantías. |
| Identidad unívoca | `registra_contrato` / `usuario_creador` identifica sin ambigüedad al usuario. |
| Control de acceso vigente | Los reportes/pantallas ya tienen permisos adecuados a heredar. |
| Sin backfill | No se requiere completar históricos como parte del MVP. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Inventario técnico | ¿Cuál es la lista exacta de reportes, SPs y queries a modificar por país? |
| Pantalla de detalle | ¿El detalle de contrato ya tiene un lugar para el dato o se agrega un elemento nuevo de UI? |
| Naming | ¿Se estandariza "Usuario creador" vs "Usuario registra" (Chile) o se respeta el de cada país? |
| Formato del dato | ¿`registra_contrato` guarda login, id o nombre? ¿Se requiere resolverlo a nombre legible? |
| Métricas | Línea base y metas de auditoría a definir con BI/operación. |
| Históricos | Presentación de garantías sin dato: ¿vacío, "N/D" u otro? |
