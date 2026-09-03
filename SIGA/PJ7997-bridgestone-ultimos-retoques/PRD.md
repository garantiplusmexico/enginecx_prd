# PRD - Bridgestone: últimos retoques al registro de avería/ajuste (SIGA)

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Bridgestone – Últimos retoques módulo de averías/ajustes (SIGA) |
| **Área / empresa** | Garantiplus México |
| **Versión** | v0.1 |
| **Fecha** | 2026-09-03 |
| **Autores** | Daniela Carbajal (PM) |
| **Revisión / liderazgo** | David Simancas (solicitante/patrocinador, cliente Bridgestone) |
| **Tipo de proyecto** | Feature web/API (ajuste menor a módulo existente) |

## 1. Resumen ejecutivo

Este proyecto cubre tres ajustes finales solicitados por el cliente Bridgestone sobre el módulo de averías de SIGA, dentro del ambiente/tenant específico de Bridgestone. El módulo ya venía siendo personalizado para este cliente (existen proyectos previos sobre el mismo flujo de averías/refacción/presupuesto); esta solicitud son los "últimos retoques" antes de cerrar esa personalización.

Los ajustes son: (1) dejar de exigir el campo "kilometraje" como obligatorio al registrar una avería; (2) permitir omitir la carga de documentos en la opción "varios"; (3) reemplazar en toda la interfaz visible del ambiente Bridgestone la palabra "avería" por "ajuste" (menús, títulos, labels, encabezados de tabla), por preferencia de naming del cliente, sin implicar un cambio funcional de fondo.

El MVP cubre exactamente estos tres ajustes sobre el ambiente Bridgestone; no hay fases posteriores planeadas por ahora. El resultado esperado es reducir la fricción operativa de quienes registran averías/ajustes (menos bloqueos por datos no siempre disponibles al momento del registro) y cerrar formalmente la solicitud de personalización visual del cliente.

**Registro de avería/ajuste** → **Kilometraje y documentos "varios" ya no bloquean el envío** → **Validación/aprobación** → **Pantallas del ambiente Bridgestone muestran "ajuste" en vez de "avería"**

## 2. Contexto y problema

- Hoy, en el ambiente Bridgestone de SIGA, al registrar una avería el campo "kilometraje" es obligatorio y la opción "varios" de carga de documentos también lo es; si el usuario no cuenta con ese dato o documento al momento del registro, no puede completar el registro.
- Además, toda la interfaz de este módulo usa el término "avería" (menú "Averías", pantalla "Registro de avería", listado "Averias" con sus columnas), término que el cliente Bridgestone no quiere ver — su preferencia es "ajuste".
- El dolor concreto es doble: fricción operativa para quien registra (bloqueo por datos no siempre disponibles) e inconsistencia de marca/naming frente a lo que el cliente espera ver en pantalla.
- Se resuelve ahora porque el cliente lo indicó explícitamente como los "últimos retoques" antes de dar por cerrada la personalización de este ambiente.
- No hay distinción funcional de dominio entre "avería" y "ajuste": es puramente una preferencia de naming del cliente, sin implicar un proceso de negocio distinto.

## 3. Objetivo del producto

Reducir la fricción operativa en el registro de averías/ajustes para el ambiente Bridgestone, eliminando validaciones obligatorias que hoy bloquean el registro (kilometraje, documentos en "varios"), y alinear la terminología visible en pantalla al naming solicitado por el cliente ("ajuste" en vez de "avería"), sin alterar el modelo de datos ni la lógica de negocio subyacente.

Es un alcance único, sin fases posteriores planeadas.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Distribuidores / talleres | Registran la avería/ajuste: capturan contrato, VIN, kilometraje, descripción de la falla y documentos. |
| Coordinador técnico / validador | Revisa y aprueba el registro de avería/ajuste (presupuesto, taller). |
| Cliente Bridgestone (vía David Simancas) | Dueño del negocio; solicita y valida los ajustes de validación y de naming. |
| TI / equipo de desarrollo | Implementa los cambios de validación y de terminología en el ambiente Bridgestone. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Kilometraje opcional | El campo "kilometraje" del formulario de registro de avería/ajuste (ambiente Bridgestone) permanece visible, pero deja de ser obligatorio: el registro se completa aunque el campo quede vacío. |
| Documentos "varios" opcionales | La opción "varios" de carga de documentos dentro del flujo de registro deja de ser obligatoria: el usuario puede omitirla y completar el registro sin cargar documentos ahí. Las demás categorías de documentos del flujo no cambian. |
| Renombrado "avería" → "ajuste" | Todo texto visible en la interfaz del ambiente Bridgestone (nombres de menú, títulos de pantalla, labels de formulario, encabezados de tabla) que hoy dice "avería"/"Averias" se muestra como "ajuste"/"Ajustes". Aplica únicamente al tenant/ambiente Bridgestone; otros clientes de SIGA no se ven afectados. |

Principio rector del MVP: los cambios son de validación de formulario y de texto de interfaz únicamente — no se modifica el modelo de datos, la lógica de negocio, ni el esquema de permisos del módulo de averías.

## 6. Fuera de alcance

- Renombrar tablas, campos de base de datos, rutas o código interno del backend: se excluye porque el cambio solicitado es de naming visible al usuario, no de arquitectura; solo cambia el texto que se muestra en pantalla.
- Aplicar el naming "ajuste" a otros tenants/clientes de SIGA: se excluye porque es una personalización específica del cliente Bridgestone, no un cambio de producto general.
- Cambiar textos en documentos exportables, PDFs, reportes o plantillas de correo que mencionen "avería": se excluye de este alcance; queda como posible solicitud futura si el cliente lo pide explícitamente.
- Modificar otras validaciones obligatorias del formulario de registro distintas a kilometraje y documentos "varios": se excluye porque el cliente no las mencionó; cualquier otro campo obligatorio se mantiene como está hoy.

## 7. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Kilometraje no obligatorio | El sistema no debe exigir el campo "kilometraje" como obligatorio al registrar una avería/ajuste en el ambiente Bridgestone; el registro debe completarse exitosamente aunque el campo quede vacío. |
| RF-02 | Documentos "varios" no obligatorios | El sistema no debe exigir la carga de documentos en la opción "varios" como obligatoria al registrar una avería/ajuste en el ambiente Bridgestone; el registro debe completarse exitosamente sin documentos cargados en esa opción. |
| RF-03 | Renombrado de terminología en UI | Todo texto visible en la interfaz del ambiente Bridgestone (menús, títulos de pantalla, labels de formularios, encabezados de tabla) que actualmente diga "avería"/"Averias" debe mostrarse como "ajuste"/"Ajustes", sin afectar otros ambientes/tenants de SIGA. |

## 8. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Consistencia de terminología | El naming "ajuste" debe aplicarse de forma uniforme en TODAS las pantallas del ambiente Bridgestone, sin dejar mezcla de "avería"/"ajuste" en ninguna vista. |
| RNF-02 | Aislamiento multi-tenant | El cambio de validaciones (kilometraje, documentos "varios") y de naming debe quedar acotado al tenant/ambiente Bridgestone, sin afectar el comportamiento ni la terminología de otros clientes de SIGA. |

## 9. Integraciones y datos

Este cambio es interno al módulo de averías/ajustes de SIGA (backend y base de datos propios del sistema); no involucra integraciones externas nuevas (no hay APIs externas, S3 u otros servicios adicionales) ni cambios al esquema de permisos existente.

Datos mínimos ya existentes que se ven afectados por la validación: contrato, VIN, kilometraje, descripción de la falla, documentos adjuntos (incluyendo la categoría "varios"). No se agregan ni eliminan campos del modelo de datos; solo cambia la obligatoriedad de kilometraje y de la carga de documentos en "varios", y el texto mostrado para "avería"/"ajuste".

Esquema de permisos: sin cambios respecto al esquema actual del módulo de averías; no se requiere validación humana o de TI adicional para este alcance.

## 10. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Registros bloqueados por kilometraje/documentos | 0 registros de avería/ajuste bloqueados por falta de kilometraje o de documentos en "varios" después del despliegue. |
| Cobertura del renombrado | 100% de las pantallas del ambiente Bridgestone sin menciones a "avería", validado mediante checklist/QA sobre las pantallas del módulo. |
| Cierre de la solicitud | Cierre formal de la solicitud del cliente (David Simancas / Bridgestone) sin retrabajo adicional tras el despliegue. |

## 11. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Renombrado incompleto | Queda mezcla de "avería"/"ajuste" en pantallas o componentes no detectados, afectando la percepción de calidad ante el cliente. |
| Menos datos disponibles al validar | Al volverse opcionales, kilometraje y documentos "varios" pueden no estar presentes al momento de validar o presupuestar la avería/ajuste, reduciendo la información disponible para esa decisión. |
| Naming hardcodeado en múltiples componentes | El texto "avería" puede estar repetido en varios componentes del frontend, lo que eleva el esfuerzo real de implementación frente a lo que parece un cambio simple de tres puntos. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Término único de reemplazo | "Ajuste" es el único término de reemplazo confirmado por el cliente; no hay otras palabras adicionales a cambiar en esta solicitud. |
| Modelo de datos sin cambios | El campo kilometraje y la opción "varios" de documentos siguen existiendo en el modelo de datos; solo cambia su obligatoriedad, no su existencia. |
| Sin restricción legal/contractual | No existe un requerimiento legal o contractual que obligue a mantener kilometraje o documentos como obligatorios para el proceso de garantía. |

## 12. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Cobertura del renombrado | ¿Cuál es el listado exhaustivo de todas las pantallas/componentes del ambiente Bridgestone que mencionan "avería", para no dejar textos sin actualizar? |
| Validación backend | ¿La obligatoriedad de kilometraje y de documentos "varios" está validada también en backend/API (no solo en frontend), y debe desactivarse ahí también? |
| Fecha límite | ¿Cuál es la fecha límite deseada por el cliente para este ajuste final? No se mencionó en la solicitud original. |
