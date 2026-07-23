# PRD - Ocultar Código Postal (CP) en Chile

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Ocultar Código Postal (CP) en Chile |
| **Área / empresa** | Garantiplus Chile |
| **Versión** | v0.1 |
| **Fecha** | 2026-07-23 |
| **Autores** | Operaciones Chile (solicitante) |
| **Revisión / liderazgo** | Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web/API |

## 1. Resumen ejecutivo

El formulario de emisión de contratos de SIGA solicita el campo **Código Postal (CP)**, un dato **irrelevante para la operación de Garantiplus Chile**. Esto agrega fricción innecesaria al capturista sin aportar valor al proceso local.

El proyecto elimina esa fricción: en el flujo de emisión de **Chile** el campo CP deja de mostrarse y deja de capturarse/persistirse, sin afectar en absoluto los formularios de **México** y **Colombia**, donde el campo se conserva tal como está.

Es un cambio menor, de **impacto en experiencia de usuario y administración local**, sin efecto sobre fidelización ni captación. El MVP (y alcance único de este PRD) es ocultar el campo en los partials de emisión CHL y ajustar las reglas de país necesarias para que la emisión sea exitosa sin ese dato.

**Formulario emisión CHL con CP** → **retirar campo CP** → **emisión sin CP** → **MX/CO sin cambios**

## 2. Contexto y problema

- **Hoy:** el formulario de emisión de contratos de SIGA incluye el campo Código Postal para todas las operaciones, incluida Chile. El capturista de Chile debe verlo (y potencialmente llenarlo) aunque el dato no se usa en la operación local.
- **Dolor:** campo irrelevante que ensucia el formulario, resta usabilidad y puede inducir capturas basura o dudas al operador.
- **Por qué ahora:** mejora de usabilidad solicitada por Operaciones Chile; cambio de bajo esfuerzo y bajo riesgo.
- **Distinción de dominio:** el cambio es **regionalizado** — aplica solo a la base/país **Chile (CHL)**; México y Colombia no se tocan.

## 3. Objetivo del producto

Retirar el campo Código Postal del flujo de emisión de contratos de Garantiplus **Chile** —tanto de la interfaz como de la captura/persistencia— para simplificar el formulario y eliminar un dato sin uso local, garantizando que la emisión siga siendo exitosa sin ese campo y que México y Colombia permanezcan sin cambios.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Capturista / operador de emisión (Chile) | Usa el formulario de emisión; se beneficia de un formulario más limpio |
| Operaciones Chile | Solicitante; define que el CP no aplica a la operación local |
| Desarrollo / TI | Implementa el ocultamiento y ajuste de reglas por país |
| Revisión técnica (Alexis Salvador Herrera Garcia) | Valida el cambio técnico |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Ocultar CP en partials de emisión CHL | Retirar el campo Código Postal de los partials de emisión de Chile (`_BeneficiarioCHL`, `Create`) para que no se muestre al operador |
| No capturar/persistir CP en Chile | El flujo de emisión de Chile deja de enviar/guardar el CP; queda nulo por diseño |
| Ajuste de reglas por país (`PaisCL`) | Retirar/ajustar cualquier validación de CP para Chile de modo que la emisión sea exitosa sin el dato |
| Aislar México/Colombia | Garantizar que los formularios y reglas de MX/CO no se ven afectados |

**Principio rector del MVP:** el cambio es estrictamente **regionalizado a Chile**; bajo ninguna circunstancia debe alterar el comportamiento de emisión de México o Colombia.

## 6. Fuera de alcance

- **Migración/limpieza de datos históricos de CP en Chile:** el cambio aplica solo a emisiones nuevas; los contratos ya emitidos no se tocan (habilitable después si Operaciones lo pide).
- **Eliminar el campo CP del modelo/base de datos:** no se borra la columna ni la estructura; solo se deja de capturar para Chile (evita riesgo sobre MX/CO y sobre históricos).
- **Cambios en México y Colombia:** el CP se conserva íntegro allí.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Ocultar CP en `_BeneficiarioCHL` | El partial de beneficiario de Chile no debe renderizar el campo Código Postal |
| RF-02 | Ocultar CP en vista `Create` de emisión CHL | La vista de creación/emisión de Chile no debe mostrar el campo Código Postal |
| RF-03 | No capturar/persistir CP en Chile | El flujo de emisión de Chile no debe enviar ni guardar el CP; queda nulo por diseño |
| RF-04 | Ajustar validaciones en `PaisCL` | Retirar/ajustar cualquier regla que exija CP en Chile, de modo que la emisión concluya sin ese dato |
| RF-05 | No afectar MX/CO | Los formularios y reglas de emisión de México y Colombia deben permanecer sin cambios |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Regionalización | El cambio aplica exclusivamente a la base/país Chile; sin efectos colaterales en MX/CO |
| RNF-02 | Consistencia de datos | Contratos de Chile emitidos sin CP no deben romper reportes, impresión de contrato ni consumidores aguas abajo |
| RNF-03 | Mantenibilidad | Seguir el patrón de regionalización por país ya existente en SIGA (partials/reglas separadas por país) |
| RNF-04 | Experiencia de usuario | El formulario debe quedar visualmente coherente tras retirar el campo (sin labels ni espacios huérfanos) |
| RNF-05 | Trazabilidad | El cambio queda versionado en el repositorio y registrado en el control de cambios |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| SIGA — partials/vistas de emisión CHL | Modificación de UI y lógica de formulario (ocultar campo, no capturar) |
| Reglas por país (`PaisCL`) | Ajuste de validaciones para no exigir CP en Chile |
| Base de datos de contratos | El CP queda nulo / no capturado para emisiones de Chile |

**Datos mínimos:** campo Código Postal (CP) del beneficiario/contrato en el flujo de emisión CHL.

**Permisos:** cambio de código estándar; no introduce nuevos accesos ni permisos. El despliegue lo realiza TI conforme al proceso habitual.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Campo ausente en emisión CHL | El CP ya no aparece en el formulario de emisión de Chile (verificación funcional/QA) |
| Emisiones sin bloqueo | 0 emisiones de Chile bloqueadas por falta de CP tras el cambio |
| Sin regresión MX/CO | Emisiones de México y Colombia siguen mostrando/capturando CP como antes |
| Usabilidad percibida | Percepción de formulario más simple por Operaciones Chile (pendiente de validar con Operaciones) |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Validación de CP oculta en `PaisCL` u otra capa | La emisión de Chile podría bloquearse si algún componente sigue exigiendo el dato |
| Consumidores aguas abajo del CP en Chile | Reportes, impresión de contrato o integraciones que esperen CP podrían fallar o mostrar vacío |
| Campo compartido con MX/CO | Regresión accidental en México/Colombia si el partial/regla es común |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| CP no obligatorio en Chile | Según nota del documento, el campo no es obligatorio para la emisión en Chile |
| Manejo regionalizado por país | El CP se maneja con partials/reglas separables por país (Chile aislable de MX/CO) |
| Sin requisito legal/fiscal | No existe obligación legal o fiscal de capturar CP en Chile |
| Solo emisiones nuevas | El cambio aplica a emisiones nuevas; no requiere tocar históricos |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Validaciones | ¿Existen reglas de validación de CP en `PaisCL` u otra capa que deban ajustarse? (la nota decía "si aplica") |
| Aguas abajo | ¿Algún reporte, impresión de contrato o integración de Chile consume el CP y se vería afectado si queda nulo? |
| Alcance de código | ¿Los partials/reglas de CP son exclusivos de Chile o compartidos con MX/CO (riesgo de regresión)? |
| Datos históricos | ¿Se requiere limpieza de CP histórico en Chile, o basta con aplicarlo a emisiones nuevas? |
