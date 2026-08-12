# PRD - Opción de menú "Contratos" para Coordinadores Técnicos

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Habilitar el listado de Contratos en el menú lateral para el rol Coordinador Técnico |
| **Área / empresa** | EngineCX (alcance transversal: Garantiplus Colombia, México y Chile) |
| **Versión** | v0.1 |
| **Fecha** | 2026-08-12 |
| **Autores** | Alejandro Govea Hernández |
| **Revisión / liderazgo** | Alexis Salvador Herrera García (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web/API |

## 1. Resumen ejecutivo

El proyecto habilita la opción de menú **"Contratos"** (listado de contratos) en el menú lateral izquierdo de SIGA para el rol **Coordinador Técnico**. Hoy este rol necesita consultar el listado de contratos como parte de su operación, pero la opción no aparece en su menú.

El acceso a la vista **ya está autorizado** para el rol: si el Coordinador Técnico escribe la URL directamente, entra sin problema. El único faltante es de **navegación/UI**: exponer el ítem en el menú para que no dependa de conocer la URL.

El MVP se limita a **mostrar la opción de menú** que lleva a la vista de Contratos ya existente, con el **mismo listado** que ven los demás roles con acceso (sin filtros adicionales por rol). El despliegue cubre los **tres hubs**: Colombia, México y Chile. No hay fases posteriores previstas.

Resultado esperado: el Coordinador Técnico llega al listado de Contratos desde el menú sin depender de la URL, eliminando fricción operativa y tickets de soporte por "no aparece la opción".

**Coordinador Técnico inicia sesión** → **menú lateral muestra "Contratos"** → **clic en la opción** → **listado de Contratos**

## 2. Contexto y problema

- **Hoy:** El Coordinador Técnico no ve la opción "Contratos" en el menú lateral izquierdo de SIGA. Puede acceder a la vista únicamente escribiendo la URL directa, lo que confirma que el permiso de acceso a la vista ya está concedido al rol.
- **Dolor:** Fricción operativa y dependencia de conocer/copiar la URL; genera consultas a soporte y percepción de que el rol "no tiene acceso" cuando en realidad solo falta la entrada de menú.
- **Por qué ahora:** Es un ajuste de bajo esfuerzo que desbloquea la operación cotidiana del Coordinador Técnico.
- **Distinción clave:** El requerimiento es de **visibilidad de menú**, no de **autorización/permisos**: el acceso ya existe; solo falta exponerlo en la navegación.

## 3. Objetivo del producto

Habilitar, para el rol Coordinador Técnico, la opción de menú "Contratos" en el menú lateral izquierdo de SIGA, de modo que pueda navegar al listado de contratos existente sin usar la URL directa. El cambio debe aplicar de forma consistente en los tres hubs (Colombia, México, Chile) y no alterar la visibilidad ni los permisos de ningún otro rol.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Coordinador Técnico | Usuario final beneficiario: verá y usará la nueva opción de menú para acceder al listado de Contratos. |
| Operación / Coordinación Técnica | Solicitante del requerimiento (área usuaria que reporta la necesidad). |
| Desarrollo / TI | Implementa la asociación rol → opción de menú y valida en los tres hubs. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Mostrar opción "Contratos" en el menú | El menú lateral izquierdo muestra el ítem "Contratos" (listado de contratos) cuando el usuario tiene el rol Coordinador Técnico. |
| Navegación a la vista existente | Al seleccionar la opción, el sistema navega a la vista de listado de Contratos que hoy ya es accesible por URL. |
| Alcance de datos sin cambios | El listado mostrado es el mismo que ven los demás roles con acceso, sin filtros adicionales por rol. |
| Aplicación en los tres hubs | La opción se habilita de forma consistente en Colombia, México y Chile. |

**Principio rector del MVP:** el cambio es exclusivamente de **navegación/visibilidad**. No modifica permisos de acceso, ni el contenido/comportamiento de la vista de Contratos, ni la visibilidad de menú de ningún otro rol.

## 6. Fuera de alcance

- **Modificar permisos o autorización de la vista de Contratos:** el permiso ya está concedido; agregarlo/cambiarlo queda fuera.
- **Filtros o acotamiento de datos por rol:** el listado se muestra igual que a otros roles; cualquier filtrado específico para el Coordinador Técnico sería otro requerimiento.
- **Cambios a la vista de Contratos (columnas, acciones, diseño):** solo se habilita el acceso desde el menú.
- **Habilitar la opción para otros roles:** el alcance es únicamente el rol Coordinador Técnico.
- **Rediseño o reordenamiento del menú lateral:** solo se agrega el ítem faltante para este rol.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Mostrar opción de menú por rol | Cuando el usuario autenticado tiene el rol Coordinador Técnico, el menú lateral izquierdo muestra la opción "Contratos". |
| RF-02 | Navegación a la vista existente | Al hacer clic en "Contratos", el sistema abre la vista de listado de contratos ya existente (la misma accesible hoy por URL). |
| RF-03 | Alcance de datos sin cambios | El listado desplegado al Coordinador Técnico es el mismo que ven los demás roles con acceso, sin filtros por rol. |
| RF-04 | Consistencia multi-hub | La opción se muestra de igual forma para el rol en los tres hubs (Colombia, México, Chile). |
| RF-05 | No afectar otros roles | La visibilidad de la opción para roles distintos al Coordinador Técnico permanece sin cambios. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Permisos intactos | El cambio solo afecta la visibilidad del ítem de menú; no otorga ni modifica permisos de acceso a datos o vistas. |
| RNF-02 | Consistencia por región | Comportamiento idéntico en los tres hubs; si la configuración de menú es independiente por hub, debe replicarse en cada uno. |
| RNF-03 | No regresión | No debe alterar la visibilidad de otras opciones del menú ni de otros roles. |
| RNF-04 | UX consistente | La opción se ubica y estiliza en el menú lateral igual que para los roles que ya la ven. |
| RNF-05 | Trazabilidad | El cambio queda registrado en control de versiones; no requiere auditoría en runtime. |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| SIGA — configuración de menú por rol | Lectura/ajuste de la asociación rol → opción de menú para incluir "Contratos" en el rol Coordinador Técnico. |
| SIGA — vista de listado de Contratos | Destino de navegación; se reutiliza sin cambios. |

**Datos mínimos:** rol del usuario (Coordinador Técnico), definición del ítem de menú "Contratos" (etiqueta + ruta), y la asociación rol ↔ opción de menú.

**Esquema de permisos:** el rol **ya tiene** permiso de acceso a la vista de Contratos; el cambio solo agrega la **asociación rol → ítem de menú**. No se conceden permisos nuevos de datos ni se toca la autorización de otros roles.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Acceso desde el menú | El Coordinador Técnico llega al listado de Contratos desde el menú lateral, sin usar la URL directa (verificación funcional). |
| Cobertura multi-hub | La opción es visible para el rol en los tres hubs (Colombia, México, Chile). |
| Reducción de fricción/tickets | Disminución o eliminación de reportes de soporte por "no aparece Contratos en el menú" (pendiente de línea base con operación/soporte). |
| Sin regresiones | Ningún otro rol ve cambios en su menú tras el despliegue. |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Configuración de menú independiente por hub | Si cada hub tiene su propia configuración, el cambio podría aplicarse en unos y no en otros (cobertura parcial). |
| Regresión de visibilidad | Una mala asociación podría mostrar la opción a roles que no deben verla, o afectar otros ítems del menú. |
| Supuesto de permiso incorrecto | Si el acceso por URL no correspondiera a un permiso correctamente concedido, aparecería un tema de seguridad fuera de este alcance. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Permiso ya concedido | El rol Coordinador Técnico ya tiene autorizado el acceso a la vista de Contratos (confirmado: entra por URL). |
| Listado sin filtros por rol | El Coordinador Técnico verá el mismo listado que otros roles con acceso. |
| Vista existente estable | La vista de Contratos funciona correctamente y no requiere cambios. |
| Menú controlado por configuración rol→opción | El menú lateral se gobierna por una asociación rol → opciones en SIGA. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Configuración multi-hub | ¿La configuración de menú por rol es compartida por los tres hubs o hay que replicar el cambio en cada uno (Colombia, México, Chile)? |
| Identificadores técnicos | ¿Cuál es el identificador exacto del ítem de menú y la ruta/permiso de la vista de Contratos que debe asociarse al rol? |
| Origen del requerimiento | ¿Existe un ticket de soporte asociado a PV-01 que convenga referenciar? |
