# PRD - Valores de moneda sin separadores de miles en Averías

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Valores de moneda sin separadores de miles en Averías |
| **Área / empresa** | Garantiplus México (equipo solicitante). Alcance de aplicación: multi-país SIGA (México, Colombia, Chile) |
| **Versión** | v0.1 |
| **Fecha** | 2026-07-22 |
| **Autores** | Operaciones-Averías (solicitante) · PM·AI / Equipo de Desarrollo |
| **Revisión / liderazgo** | Alexis Salvador Herrera García (revisión técnica) |
| **Tipo de proyecto** | Feature web / ajuste acotado |

## 1. Resumen ejecutivo

En el módulo de **Averías** de SIGA, los **talleres** capturan los valores monetarios (mano de obra, piezas e impuestos asociados) de forma inconsistente: algunos incluyen el **IVA** dentro del monto y otros usan **separadores de miles** (puntos o comas). Esto provoca **errores de cálculo** aguas abajo y **reprocesos** con los talleres para corregir los montos.

Este proyecto es un **ajuste acotado** sobre el formulario de captura de averías. El MVP consiste en: (1) mostrar una **instrucción visible** de que los valores se capturan **sin IVA y sin separadores de miles**, (2) **normalizar automáticamente** el valor al capturar, eliminando el separador de miles según el país y **preservando el decimal**, y (3) **validar** los campos de impuestos (`impuestos_mano_obra`, `impuestos_piezas`).

El cambio aplica a las tres instancias SIGA (**México, Colombia y Chile**), respetando el *locale* de cada país. No se corrigen datos históricos ni se modifica la lógica de pagos.

Resultado esperado: montos capturados de forma consistente, **menos errores de cálculo por IVA/separadores** y **menos reprocesos** con talleres.

**Taller captura monto** → **normalización por locale (quita separador de miles, conserva decimal)** → **validación de campos de impuestos** → **valor consistente almacenado**

## 2. Contexto y problema

- **Hoy:** los talleres registran los costos de la avería directamente en el formulario de SIGA. No hay una instrucción clara ni normalización, por lo que cada taller captura a su criterio: unos incluyen IVA en el monto, otros usan separadores de miles (`1.234,50` / `1,234.50` / `1234.50`).
- **Dolor concreto:** los valores heterogéneos generan **errores de cálculo** (montos inflados por IVA o mal interpretados por separadores) y obligan a **reprocesar** con el taller.
- **Por qué ahora:** es un problema recurrente de **administración operativa** con impacto en la **precisión de los pagos**; importancia media, impacto en reducción de errores.
- **Distinción de dominio clave:** el **separador de miles** no es universal — en **México** el separador de miles es `,` y el decimal `.`; en **Colombia/Chile** suele ser al revés (miles `.`, decimal `,`). Cualquier normalización debe respetar el *locale* del país para no corromper los decimales.

## 3. Objetivo del producto

Lograr que los valores monetarios de las averías se capturen de forma **consistente y sin ambigüedad** (sin IVA y sin separadores de miles) en las tres instancias SIGA, mediante una instrucción visible, normalización automática por país y validación de los campos de impuestos, reduciendo los errores de cálculo y los reprocesos con talleres.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Talleres | Capturan los valores monetarios de la avería (mano de obra, piezas, impuestos) en el formulario de SIGA |
| Operaciones-Averías | Solicitante del cambio; opera y supervisa el módulo de averías |
| TI / Desarrollo | Implementa el mensaje, la normalización por locale y la validación |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Mensaje/instrucción visible | Mostrar en el formulario de captura de avería (taller) una instrucción clara: capturar los valores **sin IVA** y **sin separadores de miles** |
| Normalización automática por país | Al capturar/guardar, eliminar el **separador de miles** según el *locale* del país (México: `,`; Colombia/Chile: `.`) y **preservar el separador decimal** |
| Validación de campos de impuestos | Validar formato/valor de `impuestos_mano_obra` e `impuestos_piezas` (numérico, ya normalizado) antes de guardar |
| Cobertura multi-país | Aplicar el comportamiento en las instancias SIGA de México, Colombia y Chile respetando el *locale* de cada una |

**Principio rector del MVP:** garantizar que **el valor almacenado siempre quede normalizado y sin ambigüedad**; ante un valor que no pueda interpretarse con certeza, el sistema **no debe guardar silenciosamente** un dato corrupto. El MVP **no** intenta detectar ni descontar el IVA automáticamente (eso queda a cargo de la instrucción al taller).

## 6. Fuera de alcance

- **Cálculo o desglose automático del IVA:** el sistema no detecta ni resta el IVA; solo se instruye capturar sin IVA. Se habilitaría después si se define una regla fiscal por país.
- **Corrección de valores históricos:** solo aplica a capturas nuevas; no se limpian datos ya registrados. Requeriría un proceso de migración/limpieza aparte.
- **Rediseño del formulario de averías:** solo se agrega el mensaje, la normalización y la validación; sin cambios de layout mayores.
- **Cambios en la lógica de pagos/cálculo aguas abajo:** el proyecto solo asegura el dato de entrada; no toca los procesos que lo consumen.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Mensaje visible en captura | El formulario de avería/taller debe mostrar una instrucción visible indicando capturar los valores sin IVA y sin separadores de miles |
| RF-02 | Normalización por locale | Al capturar/guardar, el sistema debe eliminar el separador de miles correspondiente al país de la instancia y conservar el separador decimal |
| RF-03 | Validación de impuestos | El sistema debe validar `impuestos_mano_obra` e `impuestos_piezas` (numéricos, sin separadores de miles, valor válido) antes de persistir |
| RF-04 | Cobertura multi-país | El comportamiento (RF-01 a RF-03) debe operar en SIGA México, Colombia y Chile según el *locale* de cada país |
| RF-05 | No persistir valores ambiguos | Si tras la normalización el valor no puede interpretarse como monto válido, el sistema debe avisar y no guardar el dato |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Compatibilidad multi-país | La normalización debe respetar el *locale* (separador de miles/decimal) de México, Colombia y Chile |
| RNF-02 | Consistencia de datos | El valor almacenado siempre queda normalizado; sin ambigüedad entre miles y decimales |
| RNF-03 | Experiencia de usuario | La instrucción debe ser clara y visible en el punto de captura, sin entorpecer el flujo del taller |
| RNF-04 | Mantenibilidad | La configuración de *locale* por país debe estar centralizada/parametrizada, no duplicada por pantalla |
| RNF-05 | Manejo de errores | Ante un valor no interpretable, avisar al usuario y evitar guardar datos corruptos silenciosamente |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| SIGA — módulo/formulario de Averías | Lectura y escritura de los campos de montos capturados por el taller |
| Base de datos (PostgreSQL/RDS) | Persistencia de los campos normalizados (`impuestos_mano_obra`, `impuestos_piezas`, montos de la avería) |

**Datos mínimos:** montos de la avería (mano de obra, piezas), `impuestos_mano_obra`, `impuestos_piezas`, y el país/*locale* de la instancia.

**Esquema de permisos:** los **talleres** capturan y editan los montos de su avería; la normalización y validación se aplican en captura/guardado (front y/o back, por definir); **no** se modifica la lógica de pagos ni se otorgan permisos nuevos.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Reprocesos con talleres | Reducción de correcciones/reprocesos por valores mal capturados (pendiente de línea base) |
| Averías con corrección manual | % de averías cuyos montos requieren corrección manual tras captura (pendiente de línea base) |
| Errores de cálculo por IVA/separadores | Reducción de incidencias de cálculo atribuidas a IVA o separadores (pendiente de línea base) |

*No se cuenta con línea base; las metas numéricas quedan pendientes de validar con operación.*

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Normalización mal aplicada al decimal | Corromper montos (confundir miles con decimales) si el *locale* del país no se aplica correctamente |
| Persistencia del error de IVA | Como el sistema no detecta el IVA, si el taller lo sigue incluyendo el error de cálculo persiste pese al fix de separadores |
| Diferencias entre instancias | Que los campos o el formulario no sean idénticos en México/Colombia/Chile y el cambio no aplique de forma uniforme |
| Datos históricos sin corregir | Los registros previos mal capturados siguen generando ruido en reportes/pagos |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Locale por instancia conocido | Cada instancia SIGA tiene un país/*locale* determinado y disponible en tiempo de captura |
| Existencia de campos | Los campos `impuestos_mano_obra` e `impuestos_piezas` existen en el modelo de averías de las instancias en alcance |
| Formulario reutilizado | El formulario de captura de averías es el mismo componente por país, parametrizable por *locale* |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Ubicación exacta | ¿En qué pantalla/componente de SIGA vive el formulario y los campos a intervenir? |
| Alcance de campos por país | La nota original mencionó `impuestos_*` para **Colombia**: ¿existen y aplican igual en México y Chile, o hay diferencias por país? |
| Capa de validación | ¿La normalización/validación se implementa en front, back o ambos? |
| Mensaje | ¿La instrucción es única o depende del idioma/país de la instancia? |
| Rango de validación | ¿Se define un rango o regla válida para `impuestos_mano_obra`/`impuestos_piezas`? ¿cuál? |
| Manejo del IVA | ¿Solo instrucción, o se agrega alguna validación/alerta cuando el monto parezca incluir IVA? |
