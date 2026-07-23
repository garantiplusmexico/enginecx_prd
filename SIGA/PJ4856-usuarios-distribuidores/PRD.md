# PRD - Usuarios relacionados por distribuidor (SIGA)

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Usuarios relacionados por distribuidor |
| **Área / empresa** | Garantiplus México |
| **Versión** | v0.1 |
| **Fecha** | 2026-07-23 |
| **Autores** | Operaciones (solicitante) |
| **Revisión / liderazgo** | Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web o API |

## 1. Resumen ejecutivo

Este proyecto agrega, dentro de SIGA, la capacidad de **ver los usuarios relacionados a un distribuidor** al consultar su detalle. Está dirigido al área de **Operaciones** y a los perfiles internos con acceso administrativo (Admin, Gestor, Auditor).

Hoy, desde el panel del distribuidor no es posible visualizar todos los usuarios distribuidores asociados a ese distribuidor, lo que genera una brecha de visibilidad para la gestión comercial interna.

El MVP consiste en **mostrar, en el detalle del distribuidor, la lista de usuarios relacionados** (columnas UserName y name), en modo **solo consulta**, restringido a los roles Admin/Gestor/Auditor. No se contempla asociar, desasociar ni editar usuarios en esta versión.

El resultado esperado es mejorar la administración comercial interna dando visibilidad de qué usuarios pertenecen a cada distribuidor, sin impacto directo en la captación de clientes finales.

**Consultar distribuidor** → **Cargar usuarios relacionados (join usuario_distribuidor)** → **Mostrar lista (UserName, name)** → **Solo lectura, según rol**

## 2. Contexto y problema

- **Hoy:** al consultar el detalle de un distribuidor en SIGA, el panel no muestra los usuarios distribuidores asociados a ese distribuidor.
- **Dolor:** falta de visibilidad de la relación usuario–distribuidor, lo que dificulta la gestión comercial interna y obliga a consultas manuales o cruces externos.
- **Por qué ahora:** mejora de administración comercial de importancia media solicitada por Operaciones.
- **Concepto de dominio:** *usuario distribuidor* = usuario asociado a un distribuidor mediante la relación `usuario_distribuidor`; un distribuidor puede tener varios usuarios relacionados.

## 3. Objetivo del producto

Permitir que, al consultar el detalle de un distribuidor en SIGA, los perfiles autorizados (Admin/Gestor/Auditor) puedan **ver la lista de usuarios relacionados a ese distribuidor** de forma directa y en modo solo lectura, mejorando la visibilidad para la gestión comercial interna. Alcance único (sin fases).

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Admin | Consulta el detalle del distribuidor y sus usuarios relacionados. |
| Gestor | Consulta el detalle del distribuidor y sus usuarios relacionados. |
| Auditor | Consulta (solo lectura) el detalle del distribuidor y sus usuarios relacionados. |
| Operaciones | Área solicitante; beneficiaria de la visibilidad para gestión comercial interna. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Consulta de usuarios por distribuidor | Al abrir el detalle de un distribuidor, se listan los usuarios relacionados a ese distribuidor. |
| Columnas de la lista | Cada usuario se muestra con **UserName** y **name**. |
| Extensión de `GetAllUsers` | Se extiende el servicio `GetAllUsers` con un join a `usuario_distribuidor` para obtener los usuarios asociados a un distribuidor. |
| Control de acceso por rol | La información solo es visible para Admin, Gestor y Auditor. |

**Principio rector:** el MVP es **solo visualización**; no toma ninguna acción sobre la relación usuario–distribuidor (no crea, edita ni elimina asociaciones).

## 6. Fuera de alcance

- **Asociar / desasociar usuarios a un distribuidor:** el MVP es solo lectura; la gestión de la relación se evaluaría en una fase posterior.
- **Editar datos del usuario desde esta vista:** se excluye para mantener el alcance de solo consulta.
- **Filtros y búsqueda avanzada sobre la lista:** no definidos para esta versión (ver §14); podrían habilitarse después.
- **Exponer esta información a roles distintos de Admin/Gestor/Auditor:** excluido por seguridad hasta que se defina explícitamente.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Obtener usuarios por distribuidor | Extender `GetAllUsers` con un join a `usuario_distribuidor` para devolver los usuarios relacionados a un distribuidor dado. |
| RF-02 | Mostrar usuarios en el detalle del distribuidor | En el panel/detalle del distribuidor, listar los usuarios relacionados con las columnas UserName y name. |
| RF-03 | Restringir acceso por rol | La vista y el dato solo están disponibles para Admin, Gestor y Auditor. |
| RF-04 | Solo consulta | La vista no permite crear, editar, asociar ni desasociar usuarios. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Seguridad / permisos | El acceso al dato se valida por rol (Admin/Gestor/Auditor); cualquier otro rol no debe poder consultarlo, incluso vía API. |
| RNF-02 | Rendimiento | El join a `usuario_distribuidor` no debe degradar de forma perceptible el tiempo de respuesta del listado/detalle existente. |
| RNF-03 | Consistencia de datos | La lista refleja la relación vigente en SIGA al momento de la consulta (tiempo real). |
| RNF-04 | Experiencia de usuario | La lista se integra en el panel de distribuidor ya existente, sin romper su navegación actual. |
| RNF-05 | Trazabilidad | La consulta respeta el esquema de auditoría/logs existente de SIGA (sin requerir nueva bitácora específica). |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| SIGA (API / servicio `GetAllUsers`) | Lectura: obtener usuarios y su relación con el distribuidor. |
| Tabla `usuario_distribuidor` | Lectura: join para resolver la relación usuario ↔ distribuidor. |
| Panel/detalle de distribuidor (SIGA UI) | Presentación de la lista de usuarios relacionados. |

**Datos mínimos:** identificador de distribuidor; por usuario relacionado: `UserName`, `name`; identificador de la relación en `usuario_distribuidor`; rol del usuario que consulta (para control de acceso).

**Esquema de permisos:** lectura de usuarios relacionados permitida solo a Admin/Gestor/Auditor. No hay operaciones de escritura/creación en este MVP. Cualquier acceso fuera de esos roles queda bloqueado.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Adopción de la vista | Nº de consultas al detalle de distribuidor que despliegan usuarios relacionados (pendiente de línea base con BI/operación). |
| Reducción de consultas manuales | Disminución de solicitudes internas para conocer los usuarios de un distribuidor (pendiente de validar con Operaciones). |
| Cobertura de datos | % de distribuidores cuyos usuarios relacionados se muestran correctamente vs. la relación real en `usuario_distribuidor`. |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Distribuidores con muchos usuarios | Sin paginación, la lista podría afectar rendimiento o legibilidad (ver §14). |
| Datos de relación incompletos/inconsistentes en `usuario_distribuidor` | La vista mostraría relaciones erróneas o incompletas. |
| Fuga de información por rol mal aplicado | Exposición de usuarios a roles no autorizados si el control no se aplica también en la API. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Existe la relación en datos | La tabla `usuario_distribuidor` contiene la relación usuario ↔ distribuidor requerida. |
| `GetAllUsers` es extensible | El servicio actual puede extenderse con el join sin rediseñarlo por completo. |
| Panel de distribuidor existente | Ya existe un detalle/panel de distribuidor donde insertar la lista. |
| Roles ya definidos en SIGA | Admin/Gestor/Auditor ya existen y son gestionables en SIGA. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Filtros / búsqueda | ¿La vista requiere filtros (por rol, estatus) o búsqueda por UserName/name? No definidos en esta versión. |
| Paginación / orden | Si un distribuidor tiene muchos usuarios, ¿se pagina? ¿Cuál es el orden por defecto de la lista? |
| Columnas adicionales | ¿Bastan UserName y name, o a futuro se requerirán rol, estatus o fecha de alta? |
| Área / empresa | El revisor usa dominio `@gplusseguros.mx`; confirmar si la unidad de negocio es Garantiplus México o Gplus Seguros. |
