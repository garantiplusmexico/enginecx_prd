# PRD - Gerentes Comerciales — Consulta de Averías

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Gerentes Comerciales — Consulta de Averías |
| **Área / empresa** | Garantiplus México |
| **Versión** | v0.1 |
| **Fecha** | 2026-07-23 |
| **Autores** | Alejandro Govea (alejandro.govea@garantiplus.mx) |
| **Revisión / liderazgo** | Alexis Salvador Herrera García (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web/API |

## 1. Resumen ejecutivo

Este proyecto habilita la **consulta de averías** para el rol **Gerente Comercial** dentro de SIGA (Garantiplus México). Hoy los gerentes comerciales no tienen acceso al módulo de averías, por lo que carecen de visibilidad sobre la experiencia postventa de sus clientes y no pueden actuar de forma proactiva ante problemas.

La mejora es acotada: el módulo de averías (`AveriasController`) **ya existe** y el rol ya está autorizado en ~85% de sus acciones; además, el **filtro por `usuario_distribuidor`** —que acota las averías a los clientes de cada gerente— ya está implementado. El trabajo consiste en completar la autorización del rol para la **consulta**, exponer el acceso en el **menú de navegación** y **restringir explícitamente** las acciones de escritura.

El **MVP** entrega consulta en **modo lectura**: el Gerente Comercial ve el listado de averías de sus clientes y puede abrir el detalle (estatus, historial y documentos adjuntos) sin modificar nada. Quedan **fuera de alcance** aprobación, carga de documentos y export.

El **impacto de negocio es alto**: fortalece la fidelización de clientes y la visibilidad comercial, permitiendo al gerente detectar y atender proactivamente problemas de sus clientes.

**Gerente Comercial inicia sesión** → **abre Averías desde el menú** → **ve el listado de sus clientes (filtrado por `usuario_distribuidor`)** → **consulta el detalle en modo lectura**

## 2. Contexto y problema

- **Hoy:** el módulo de averías vive en SIGA (`AveriasController`) y lo operan otros roles (postventa/operación). El rol **Gerente Comercial** no tiene acceso a la consulta de averías.
- **Dolor:** el gerente comercial no tiene visibilidad sobre las averías de sus clientes; depende de solicitar la información a otras áreas, con fricción y retraso, y pierde capacidad de reacción proactiva.
- **Por qué ahora:** es una mejora de bajo costo con alto impacto comercial — la mayor parte de la infraestructura de permisos y el filtrado por distribuidor ya existen; falta habilitar el rol y cerrar el acceso.
- **Distinción de dominio:** "consulta" en este PRD = **acceso de solo lectura** (ver listado y detalle). No incluye ninguna acción de escritura (aprobar, cargar documentos, exportar).

## 3. Objetivo del producto

Habilitar al rol **Gerente Comercial** la **consulta en modo lectura** de las averías correspondientes a **sus propios clientes** (acotadas por `usuario_distribuidor`) dentro de SIGA, reutilizando el módulo existente, de forma que gane visibilidad sobre la experiencia postventa y pueda actuar proactivamente, sin habilitar ninguna capacidad de modificación de datos.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Gerente Comercial | Rol destino: consulta (lectura) las averías de sus clientes para dar seguimiento comercial. |
| Cliente / Distribuidor | Sujeto de la avería; sus averías son visibles al gerente que lo atiende (vía `usuario_distribuidor`). |
| Postventa / Operación de averías | Rol que gestiona las averías (aprobación, carga de documentos, etc.); no cambia con este desarrollo. |
| TI / Desarrollo | Implementa el ajuste de permisos, navegación y restricciones. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Autorización del rol para consulta | Completar la autorización del rol Gerente Comercial en `AveriasController` para las acciones de consulta (listado y detalle). Parte de la base ~85% ya autorizada. |
| Acceso en menú de navegación | Mostrar la entrada al módulo de Averías en el menú para el rol Gerente Comercial. |
| Listado filtrado por cliente | Listar únicamente las averías de los clientes del gerente, aplicando el filtro por `usuario_distribuidor` ya implementado. |
| Detalle en modo lectura | Permitir abrir el detalle de una avería (estatus, historial y documentos adjuntos) en solo lectura. |
| Bloqueo de acciones de escritura | Impedir, para este rol, aprobación, carga de documentos y export. |

**Principio rector del MVP:** acceso **estrictamente de solo lectura y acotado al distribuidor** del gerente. Ninguna acción del rol debe modificar datos ni exponer averías de clientes ajenos.

## 6. Fuera de alcance

- **Aprobación de averías:** se excluye por ser una acción de gestión que corresponde a postventa/operación; se habilitaría si el negocio decide dar al gerente capacidad de decisión.
- **Carga de documentos:** se excluye por ser escritura sobre el expediente; requeriría reglas de negocio y auditoría propias.
- **Export del listado/detalle:** fuera del MVP; **queda planeado como fase posterior**.
- **Averías de clientes ajenos al gerente:** excluidas por diseño; el filtrado por `usuario_distribuidor` es un límite duro, no configurable por el rol.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Autorizar rol para consulta | El sistema debe permitir al rol Gerente Comercial acceder a las acciones de consulta (listado y detalle) del módulo de averías. |
| RF-02 | Entrada en navegación | El menú de navegación debe mostrar el acceso a Averías cuando el usuario tiene rol Gerente Comercial. |
| RF-03 | Listado acotado por distribuidor | El listado de averías debe mostrar únicamente las averías cuyos clientes correspondan al `usuario_distribuidor` del gerente. |
| RF-04 | Detalle en modo lectura | El sistema debe permitir abrir el detalle de una avería (estatus, historial, documentos adjuntos) sin opciones de edición para este rol. |
| RF-05 | Bloqueo de escritura | El sistema debe impedir, para el rol Gerente Comercial, las acciones de aprobación, carga de documentos y export (no visibles/no ejecutables). |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Control de permisos por rol | El acceso debe regirse por el esquema de roles de SIGA; el rol solo obtiene permisos de lectura sobre averías. |
| RNF-02 | Aislamiento de datos por distribuidor | El filtro por `usuario_distribuidor` debe aplicarse en listado y detalle, evitando cualquier fuga de averías de otros distribuidores. |
| RNF-03 | Trazabilidad | Los accesos del rol quedan cubiertos por la traza existente en SIGA; no requiere auditoría adicional. |
| RNF-04 | Reutilización / mantenibilidad | Reutilizar la UI y la lógica existentes del módulo de averías; el cambio debe ser mínimo e incremental. |
| RNF-05 | Disponibilidad | Misma disponibilidad y tiempos de respuesta que el módulo de averías de SIGA (horario operativo). |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| SIGA — `AveriasController` | Lectura: listado y detalle de averías; reutilización de los endpoints de consulta existentes. |
| Base de datos SIGA (PostgreSQL/RDS) | Lectura de averías, estatus, historial y relación cliente↔`usuario_distribuidor`. |
| Almacenamiento de documentos (S3 u origen actual de adjuntos) | Lectura de documentos adjuntos de la avería para visualización en el detalle. |

**Datos mínimos:** identificador de avería, estatus, cliente/distribuidor asociado (`usuario_distribuidor`), fechas, historial de estatus y documentos adjuntos (solo lectura).

**Esquema de permisos:** el rol Gerente Comercial **puede leer** listado y detalle de averías de sus clientes; **no puede** crear/editar (aprobación, carga de documentos) ni exportar; el filtrado por distribuidor es obligatorio y no puede ser evadido por el rol.

## 12. Métricas de éxito

No se definen métricas de éxito para este MVP: es una habilitación de permisos de consulta de bajo alcance. El criterio de éxito es funcional — el Gerente Comercial puede consultar, en modo lectura, las averías de sus clientes.

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Filtro por distribuidor no cubre todos los endpoints de consulta/detalle | Fuga de averías de clientes ajenos al gerente (incidente de datos). |
| Autorización mal acotada deja accesibles acciones de escritura | El rol podría aprobar/cargar/exportar sin estar autorizado. |
| Documentos adjuntos con permisos de acceso propios (S3) | El detalle podría no mostrar (o mostrar de más) adjuntos si los permisos no se alinean. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Base ~85% autorizada | El rol ya tiene autorizada la mayoría de las acciones de consulta en `AveriasController`. |
| Filtro `usuario_distribuidor` funcional | El filtrado por distribuidor está implementado y es correcto para acotar a los clientes del gerente. |
| Rol existente | El rol "Gerente Comercial" existe en el esquema de roles de SIGA y es asignable. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Autorización restante | ¿Qué acciones exactas componen el ~15% no autorizado y cuáles son consulta vs. escritura? |
| Detalle y adjuntos | ¿El detalle expone documentos desde S3 con permisos propios? ¿Requiere ajuste para lectura del rol? |
