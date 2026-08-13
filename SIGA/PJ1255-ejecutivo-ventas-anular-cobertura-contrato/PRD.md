# PRD - Ejecutivo de Ventas: dejar contrato sin cobertura (SIGA)

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Habilitar al Ejecutivo de Ventas la acción "dejar sin cobertura" un contrato |
| **Área / empresa** | Garantiplus Chile |
| **Versión** | v0.1 |
| **Fecha** | 2026-08-13 |
| **Autores** | Alejandro Govea Hernández (desarrollo) · Solicita: Operaciones Chile |
| **Revisión / liderazgo** | Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web/API (SIGA) — cambio de permisos sobre función existente |

## 1. Resumen ejecutivo

En SIGA ya existe la acción **"dejar sin cobertura"** de un contrato: al consultar un contrato, ciertos roles ven un botón que, con un **motivo** obligatorio, **suspende la cobertura** del contrato. Hoy el **Ejecutivo de Ventas no tiene ese botón**, por lo que debe solicitar la suspensión a **Operaciones**, generando dependencia entre áreas y demoras.

Este proyecto **habilita esa misma acción al rol Ejecutivo de Ventas**, sin crear lógica nueva: reutiliza el botón, el motivo obligatorio y la trazabilidad ya existentes. El Ejecutivo podrá dejar sin cobertura **cualquier contrato que su rol ya pueda consultar**.

El **MVP** se limita a **suspender** cobertura (acción existente). **Reactivar/reanudar** la cobertura queda **fuera de alcance** y sigue en el área/rol actual.

Resultado esperado: **eliminar la dependencia** de Operaciones/otras áreas para esta tarea y **agilizar** la gestión.

**Consultar contrato** → **clic "Dejar sin cobertura"** → **capturar motivo** → **confirmar** → **cobertura suspendida (registrada)**

## 2. Contexto y problema

- **Hoy:** la función existe y opera para algunos roles (botón en la consulta del contrato → pide motivo → suspende cobertura). El Ejecutivo de Ventas **no** la tiene y **depende de Operaciones** (vía solicitud) para ejecutarla.
- **Dolor:** dependencia entre áreas, demoras y carga operativa trasladada a Operaciones por una acción que técnicamente ya está resuelta.
- **Por qué ahora:** reducir la dependencia entre áreas y darle autonomía al Ejecutivo de Ventas.
- **Concepto de dominio:** *dejar sin cobertura* = **suspender** la cobertura del contrato (el contrato sigue existiendo; es reversible por el proceso actual). No es anulación ni baja definitiva.

## 3. Objetivo del producto

Permitir que el **Ejecutivo de Ventas** ejecute por sí mismo la acción existente **"dejar sin cobertura"** en SIGA, con motivo obligatorio y trazabilidad, para eliminar la dependencia de otras áreas y agilizar la gestión — sin modificar el comportamiento de la función ni los permisos de los demás roles.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Ejecutivo de Ventas | Nuevo rol habilitado para ejecutar "dejar sin cobertura" (suspender) sobre contratos que puede consultar. |
| Operaciones (Chile) | Hoy ejecuta la acción a solicitud; tras el cambio deja de ser intermediario obligatorio y conserva la reactivación. |
| TI | Configura el permiso del rol y da soporte. |
| Cliente (indirecto) | Beneficiario de una gestión más ágil. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Habilitar botón "dejar sin cobertura" al rol Ejecutivo de Ventas | Mostrar y permitir la acción existente en la pantalla de consulta del contrato para este rol. |
| Motivo obligatorio | Reutiliza el campo/catálogo de motivo ya existente; la suspensión no se confirma sin motivo. |
| Ámbito de contratos | Aplica a cualquier contrato que el rol tenga permitido consultar (mismo criterio que los roles ya habilitados). |
| Trazabilidad de la acción | Registra usuario ejecutor, contrato, motivo y fecha/hora (comportamiento existente). |

**Principio rector:** no se crea lógica nueva ni se cambian los efectos de la suspensión — solo se **otorga el permiso** de la función existente a un rol adicional.

## 6. Fuera de alcance

- **Reactivar/reanudar la cobertura por el Ejecutivo de Ventas:** se mantiene en el área/rol actual; habilitarlo requeriría definir sus propias reglas.
- **Cambiar el comportamiento o los efectos de "dejar sin cobertura":** el MVP reutiliza la función tal cual; cualquier ajuste es otro alcance.
- **Modificar permisos de otros roles:** solo se agrega el rol Ejecutivo de Ventas.
- **Restricciones adicionales de ámbito (por sucursal/propios):** no se agregan; se usa el mismo criterio de consulta del rol.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Mostrar acción al rol | El botón "dejar sin cobertura" es visible y utilizable por el rol Ejecutivo de Ventas en la consulta de contrato. |
| RF-02 | Motivo obligatorio | Al ejecutar, el sistema exige un motivo (campo/catálogo existente) antes de confirmar la suspensión. |
| RF-03 | Ámbito de aplicación | La acción aplica a cualquier contrato que el rol pueda consultar, sin restricción adicional. |
| RF-04 | Trazabilidad | Cada ejecución registra usuario, contrato, motivo y fecha/hora (log existente de la función). |
| RF-05 | Sin reactivación | El rol no puede reactivar/reanudar cobertura; esa acción no se habilita para este rol. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Seguridad/permisos | El permiso se otorga exclusivamente al rol Ejecutivo de Ventas; no altera permisos de otros roles. |
| RNF-02 | Auditabilidad | Reutiliza la trazabilidad existente (usuario, contrato, motivo, timestamp). |
| RNF-03 | Consistencia | Los efectos de suspender cobertura son idénticos a los de los roles ya habilitados; sin lógica nueva. |
| RNF-04 | Experiencia de usuario | Misma ubicación y flujo del botón (consulta → botón → motivo → confirmar); sin curva de aprendizaje. |
| RNF-05 | Regional | Aplica a la operación de Chile según el alcance del rol. |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| SIGA — módulo de contratos | Escritura del estado de cobertura (suspensión) mediante la acción existente. |
| SIGA — gestión de roles/permisos | Alta del permiso de la acción para el rol Ejecutivo de Ventas. |

**Datos mínimos:** identificador de contrato, estado de cobertura, motivo, usuario ejecutor, fecha/hora.

**Permisos:** el rol ya **lee** el contrato; se le habilita **escribir** el cambio de estado a cobertura suspendida vía la acción existente; queda **bloqueada** la reactivación de cobertura.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Tiempo de ejecución | Tiempo entre necesidad y suspensión efectiva (de solicitud a Operaciones → acción directa). Línea base pendiente con Operaciones. |
| Descarga de Operaciones | Reducción de solicitudes de "dejar sin cobertura" recibidas por Operaciones. Línea base pendiente. |
| Autonomía del rol | % de acciones ejecutadas directamente por Ejecutivos de Ventas vs. otras áreas. |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Suspensiones indebidas al ampliar el permiso a más usuarios | Contratos suspendidos sin justificación; se mitiga con motivo obligatorio y trazabilidad. |
| Desconocimiento de efectos de suspender cobertura (facturación/comisiones/siniestros) | Errores operativos; requiere comunicación/capacitación al rol. |
| Ámbito "cualquier contrato que pueda consultar" más amplio de lo deseado | El rol podría actuar sobre contratos no esperados; validar el scope de consulta del rol. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| La función existe y opera correctamente para otros roles | Solo se agrega el rol, sin tocar la lógica. |
| Motivo y trazabilidad ya implementados | El campo de motivo y el registro de auditoría son los existentes. |
| Suspensión reversible por el proceso actual | Reactivar cobertura sigue en el área/rol actual. |
| Sin cambios en efectos de negocio | Los efectos de la suspensión no cambian con este proyecto. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Rol | Nombre/identificador técnico exacto del rol "Ejecutivo de Ventas" en SIGA. |
| Ámbito | ¿El scope de "contratos que puede consultar" es el correcto para esta acción o debe acotarse (sucursal/país/propios)? |
| Reglas de negocio | ¿Hay contratos que no deban poder suspenderse (estado, siniestro abierto, etc.)? |
| Confirmación | ¿Se requiere doble confirmación o alguna validación extra para este rol? |
| Notificación | ¿Debe avisarse a alguna área cuando un ejecutivo deja un contrato sin cobertura? |
| Métricas | Línea base y metas numéricas de las métricas (validar con Operaciones/BI). |
