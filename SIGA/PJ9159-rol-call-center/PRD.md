# PRD - Creación de nuevo Rol Call Center

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Creación de nuevo Rol Call Center |
| **Área / empresa** | Garantiplus México (aplica de forma transversal a las operaciones Garantiplus) |
| **Versión** | v0.1 |
| **Fecha** | 2026-08-12 |
| **Autores** | Alejandro Govea Hernández |
| **Revisión / liderazgo** | Alexis Salvador Herrera García (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web o API |

## 1. Resumen ejecutivo

El proyecto crea un **nuevo rol de solo consulta para el área de Call Center** dentro de SIGA, en el módulo de averías. Hoy los analistas de Call Center operan con un usuario de **rol "Técnico"**, que además de consultar les permite **ajustar/modificar averías** — una capacidad que excede su función y representa un riesgo operativo y de control de accesos.

El problema se agrava por la **alta rotación de personal** en Call Center y ha sido señalado por **Auditoría**: perfiles con más permisos de los necesarios, asignados a usuarios que entran y salen con frecuencia. Se busca aplicar el principio de mínimo privilegio.

El **MVP** consiste en crear un rol "Call Center" de **solo lectura** sobre averías (ver listado, detalle, documentos adjuntos e historial, con búsqueda/filtros), **sin** capacidad de crear, editar, cambiar estatus, aprobar, adjuntar, comentar ni exportar; y que el **Administrador General** reasigne manualmente a los usuarios de Call Center a este rol.

**Resultado esperado:** eliminar la posibilidad de que Call Center modifique averías, cerrar el hallazgo de auditoría y reducir el riesgo asociado a la rotación, sin perder su capacidad de consulta.

**Alta del rol** → **Asignación manual por Administrador General** → **Call Center consulta averías (solo lectura)** → **Acciones de escritura bloqueadas**

## 2. Contexto y problema

- **Hoy:** los analistas de Call Center acceden a SIGA con un usuario de **rol "Técnico"**. Ese rol les da visibilidad de las averías que consultan, pero **también les permite realizar ajustes** sobre ellas.
- **Dolor concreto:** el rol otorga permisos de escritura que no corresponden a la función de Call Center (consulta/atención), habilitando modificaciones indebidas sobre averías y debilitando el control de accesos.
- **Por qué ahora:** **alta rotación de personal** en el área (muchas altas/bajas de usuarios con un rol sobre-privilegiado) y una observación de **Auditoría** que exige alinear los accesos al mínimo necesario.
- **Distinción clave para dev:** "consultar una avería" (leer su información y documentos) es distinto de "operar una avería" (crear, editar, cambiar estatus, aprobar, adjuntar). El nuevo rol habilita lo primero y bloquea lo segundo.

## 3. Objetivo del producto

Crear en SIGA un **rol "Call Center" de solo consulta** sobre el módulo de averías, que permita a los analistas ver toda la información que hoy consultan **sin poder modificarla**, aplicando el principio de mínimo privilegio. El rol debe ser asignable manualmente por el Administrador General y mantener el mismo **alcance de visibilidad** (filtros por país/hub/distribuidor) que hoy tienen esos usuarios, retirando únicamente las capacidades de escritura.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Analista de Call Center | Usuario final del nuevo rol: consulta averías (listado, detalle, documentos, historial) sin modificarlas. |
| Administrador General | Asigna/reasigna manualmente el nuevo rol a los usuarios de Call Center (existentes y nuevos). |
| Auditoría | Origen del requerimiento; verifica que los accesos de Call Center queden acotados a consulta. |
| TI / Desarrollo (Engine) | Crea el rol en el catálogo de roles/permisos de SIGA y aplica los bloqueos de escritura. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Nuevo rol "Call Center" (solo consulta) | Alta de un rol en el catálogo de roles de SIGA, orientado a consulta del módulo de averías. |
| Consulta de averías (listado) | Visualiza el listado de averías con el **mismo alcance de visibilidad y filtros** vigentes hoy para esos usuarios. |
| Detalle de avería | Abre y visualiza el detalle completo de una avería. |
| Documentos adjuntos | Ve y **descarga** los documentos adjuntos de la avería. |
| Historial / bitácora | Consulta el historial/bitácora de cambios de la avería. |
| Búsqueda y filtros | Busca y filtra el listado de averías. |
| Asignación manual del rol | El Administrador General asigna/reasigna el rol a usuarios de Call Center (altas nuevas y usuarios existentes). |

**Matriz de permisos del rol Call Center:**

| Acción | ¿Permitida? |
| --- | --- |
| Ver listado / detalle de averías | ✅ Sí |
| Ver y descargar documentos adjuntos | ✅ Sí |
| Ver historial / bitácora | ✅ Sí |
| Buscar / filtrar | ✅ Sí |
| Exportar (Excel/PDF) | ❌ No |
| Crear avería | ❌ No |
| Editar / modificar avería | ❌ No |
| Cambiar estatus | ❌ No |
| Aprobar / rechazar | ❌ No |
| Adjuntar documentos | ❌ No |
| Comentar | ❌ No |

**Principio rector del MVP:** el rol es **estrictamente de solo lectura** sobre averías. Ninguna acción de escritura debe quedar accesible para este rol, ni siquiera de forma residual en la interfaz.

## 6. Fuera de alcance

- **Exportación de averías (Excel/PDF) para el rol Call Center:** se excluye por definición del alcance de consulta; podría revisarse en una fase futura si el negocio lo justifica.
- **Automatizar la reasignación masiva de usuarios:** la migración del rol Técnico al nuevo rol la hace manualmente el Administrador General; no se construye un proceso automático de migración.
- **Rediseñar o modificar el rol "Técnico" existente:** solo se crea el rol nuevo; el rol Técnico se mantiene para quienes sí lo requieren.
- **Nuevos permisos de consulta fuera del módulo de averías:** el rol se acota a averías; otros módulos quedan fuera hasta que se soliciten explícitamente.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Crear rol "Call Center" | Alta de un nuevo rol en el catálogo de roles/permisos de SIGA. |
| RF-02 | Ver listado de averías | El rol visualiza el listado con el mismo alcance de visibilidad y filtros vigentes. |
| RF-03 | Ver detalle de avería | El rol abre y visualiza el detalle de una avería. |
| RF-04 | Ver/descargar documentos adjuntos | El rol accede y descarga los documentos adjuntos de la avería. |
| RF-05 | Ver historial/bitácora | El rol consulta el historial de cambios de la avería. |
| RF-06 | Buscar/filtrar | El rol usa la búsqueda y los filtros del listado de averías. |
| RF-07 | Bloqueo de escritura | El rol NO puede crear, editar, cambiar estatus, aprobar/rechazar, adjuntar documentos ni comentar averías. |
| RF-08 | Sin exportación | El rol NO puede exportar averías (Excel/PDF). |
| RF-09 | Asignación manual | El Administrador General puede asignar/reasignar el rol a usuarios existentes y nuevos. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Seguridad de permisos (defensa en backend) | Los bloqueos de escritura y exportación deben aplicarse en el backend/API, no solo ocultando botones en la UI; el rol no debe poder ejecutar esas acciones por ninguna vía. |
| RNF-02 | Trazabilidad / auditoría | Debe poder identificarse qué usuarios tienen el rol y registrarse los cambios de asignación, para responder a Auditoría. |
| RNF-03 | Consistencia de visibilidad | El rol respeta el mismo alcance de datos (país/hub/distribuidor) que hoy aplica a esos usuarios; no amplía ni reduce lo que ya ven. |
| RNF-04 | Mantenibilidad | El rol vive como entrada del catálogo de roles de SIGA, reutilizable y mantenible como los demás roles. |
| RNF-05 | Experiencia de usuario | Los usuarios con el rol ven una interfaz de solo lectura coherente, sin controles de acción que generen errores o confusión. |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| SIGA — módulo de averías | Lectura de averías, detalle, documentos adjuntos e historial. |
| SIGA — gestión de usuarios/roles | Alta del nuevo rol y asignación de permisos; asignación manual de usuarios por el Administrador General. |

**Datos mínimos:** definición del rol (nombre, descripción, permisos asociados); asociación usuario–rol; y las entidades ya existentes de avería (encabezado, documentos adjuntos, historial/bitácora).

**Esquema de permisos:** el rol **lee** averías (listado, detalle, adjuntos, historial) dentro de su alcance de visibilidad actual; **no escribe** nada (crear/editar/estatus/aprobar/adjuntar/comentar) ni exporta. La asignación del rol a usuarios queda reservada al **Administrador General**.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Modificaciones de averías por Call Center | Objetivo: 0 modificaciones hechas por usuarios de Call Center tras la migración. |
| Cobertura de migración | % de usuarios de Call Center reasignados del rol Técnico al nuevo rol (meta: 100%). |
| Hallazgos de auditoría | Cierre del hallazgo de accesos de Call Center (validar criterio con Auditoría). |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Bloqueo solo en UI y no en API | Un usuario podría eludir el bloqueo y seguir modificando averías; no se cerraría el hallazgo de auditoría. |
| Migración incompleta por rotación | Usuarios de Call Center quedan con el rol Técnico y conservan permisos de escritura. |
| Herencia incorrecta del alcance de visibilidad | El rol podría ver de más o de menos respecto a lo que hoy consultan esos usuarios. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Catálogo de roles configurable | SIGA permite crear roles y definir sus permisos sobre el módulo de averías. |
| Nivel de visibilidad actual es correcto | Los filtros/alcance vigentes de esos usuarios son los que deben conservarse. |
| Asignación manual es suficiente | La reasignación por el Administrador General cubre la necesidad; no se requiere automatización. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Reutilización del rol | ¿El rol es exclusivo de Call Center o reutilizable para otras áreas de solo consulta? ¿Nombre definitivo del rol en SIGA? |
| Despliegue por operación | La unidad registrada es Garantiplus México, pero el insumo original mencionó Colombia. ¿En qué operación(es)/país(es) se despliega primero? |
| Alcance API | ¿El rol debe respetarse también en la API de SIGA, además de la web? |
| Reporte para auditoría | ¿Se requiere un reporte/listado de qué usuarios tienen el rol para entregar a Auditoría? |
| Nombres actuales | Nombre exacto del rol "Técnico" actual y del nuevo rol a crear. |
