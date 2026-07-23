# PRD - Versión del Vehículo en Reporte de Contratos

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Versión del Vehículo en Reporte de Contratos (SIGA) |
| **Área / empresa** | EngineCX |
| **Solicitante** | Operaciones / Chile |
| **Versión** | v0.2 |
| **Fecha** | 2026-07-23 |
| **Autores** | Alejandro Govea (alejandro.govea@garantiplus.mx) |
| **Revisión / liderazgo** | Alexis Salvador Herrera Garcia — Revisor Técnico (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web o API |

## 1. Resumen ejecutivo

El reporte de contratos emitidos de SIGA se exporta a Excel para uso de las áreas de
Administración y Reportes, que lo utilizan para análisis interno del parque de contratos. Hoy
ese export **no incluye el campo Versión del vehículo**, un atributo que identifica la variante
específica del modelo (motor/acabado/edición) y que aporta granularidad al análisis.

El problema es una carencia de dato en el entregable: quien analiza los contratos no puede
segmentar ni cruzar por versión del vehículo directamente desde el Excel, y debe recurrir a
consultas manuales adicionales o prescindir de ese nivel de detalle.

El MVP consiste en **agregar la columna «Versión del vehículo» al export Excel de contratos
emitidos**, disponible en todos los países en los que opera el reporte. No se contempla ninguna
fase posterior: es un cambio acotado y autocontenido.

El resultado esperado es un reporte más completo que enriquece el análisis interno de
Administración/Reportes, sin impacto en captación ni fidelización y sin cambios en la
experiencia del usuario final del sistema.

**Generar reporte de contratos** → **incluir dato Versión del vehículo** → **exportar Excel con la columna** → **entregar a Administración/Reportes**

## 2. Contexto y problema

- **Cómo funciona hoy:** SIGA genera el reporte de contratos emitidos (alimentado por el SP
  `sp_reporte_contratos` y/o el modelo `contrato`) y lo exporta a Excel. El export incluye los
  datos del contrato y del vehículo, pero **omite la Versión del vehículo**.
- **Dolor concreto:** las áreas de Administración y Reportes no pueden analizar ni segmentar los
  contratos por versión del vehículo desde el Excel; pierden granularidad para análisis interno
  y dependen de trabajo manual adicional para obtener ese dato.
- **Por qué ahora:** es una mejora de bajo esfuerzo que enriquece los reportes existentes; se
  aprovecha para dejar el export completo y evitar la fricción recurrente en el análisis.
- **Distinción de dominio:** «Versión del vehículo» se refiere a la variante específica del
  modelo (no confundir con marca ni modelo, que ya podrían estar presentes en el reporte).

## 3. Objetivo del producto

Incorporar el campo **Versión del vehículo** al reporte Excel de contratos emitidos de SIGA,
para todas las plazas donde se genera el reporte, de modo que las áreas de Administración y
Reportes cuenten con ese atributo directamente en el entregable y puedan realizar análisis
interno con mayor granularidad. La mejora medible es la disponibilidad del dato en el 100 % de
los renglones del export donde el contrato tenga versión registrada.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Operaciones / Chile | Solicitante del cambio; consume el reporte Excel para su operación y análisis interno. |
| Administración | Consume el reporte Excel para control y análisis interno del parque de contratos. |
| Reportes / BI interno | Usa el export para segmentar y cruzar información; requiere la versión del vehículo como dimensión. |
| Equipo de desarrollo SIGA | Implementa el cambio en el export y, si aplica, en la query/SP fuente. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Columna «Versión del vehículo» en el export Excel | Agregar una nueva columna al reporte Excel de contratos emitidos que muestre la versión del vehículo asociada a cada contrato. |
| Cobertura multi-país | El campo se incluye en el export de todos los países donde se genera el reporte, contemplando el ajuste específico del export de PaisCL. |
| Fuente del dato | Tomar la versión del vehículo desde el SP `sp_reporte_contratos` o el modelo `contrato`; si el dato no está expuesto, ajustar la query SQL para incluirlo. |

Principio rector del MVP: es un cambio aditivo y de bajo riesgo — se agrega un dato ya existente
en el dominio al entregable, sin alterar la lógica del reporte, el resto de columnas ni la
experiencia del usuario.

## 6. Fuera de alcance

- **Nuevos filtros o segmentaciones por versión dentro de SIGA:** el MVP solo agrega la columna
  al export; cualquier filtrado se hace en Excel. Se incluiría después si Reportes lo solicita.
- **Rediseño o reordenamiento del reporte:** no se modifica el layout existente más allá de
  sumar la columna nueva.
- **Otros reportes o exports distintos al de contratos emitidos:** el cambio se limita a este
  reporte.
- **Carga o captura del dato Versión:** se asume que la versión ya existe en el dominio; poblar
  o corregir el dato origen queda fuera.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Incluir columna Versión del vehículo | El export Excel de contratos emitidos debe incluir una columna con la versión del vehículo de cada contrato. |
| RF-02 | Cobertura en todos los países | La columna debe aparecer en el export de todos los países donde se genera el reporte, incluyendo el export de PaisCL. |
| RF-03 | Origen del dato | El valor debe provenir de `sp_reporte_contratos` o del modelo `contrato`; si no está disponible, se ajusta la query SQL para exponerlo. |
| RF-04 | Manejo de contratos sin versión | Si un contrato no tiene versión registrada, la celda debe quedar vacía (o con un valor neutro acordado), sin romper la generación del reporte. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Consistencia de datos | La versión mostrada debe corresponder al vehículo del contrato en la misma fuente que el resto de los datos del reporte. |
| RNF-02 | No regresión | Agregar la columna no debe alterar las columnas existentes, el orden de los datos ni el tiempo de generación del reporte de forma perceptible. |
| RNF-03 | Mantenibilidad multi-país | El cambio debe seguir el patrón de export ya usado por cada país (evitando divergencias innecesarias entre plazas). |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| SP `sp_reporte_contratos` | Fuente principal del reporte; lectura del dato Versión del vehículo (ajustar si no lo expone). |
| Modelo `contrato` (SIGA) | Fuente alternativa/complementaria del dato de versión. |
| Módulo de export Excel (por país, incl. PaisCL) | Consumidor que renderiza la nueva columna en el archivo generado. |

Datos mínimos requeridos: identificador del contrato, datos del vehículo ya presentes (marca,
modelo) y el **campo Versión del vehículo**. El feature es de solo lectura sobre las fuentes:
no escribe ni modifica datos, únicamente los expone en el export.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Presencia del dato | % de renglones del export con Versión del vehículo poblada respecto a los contratos que tienen versión registrada (meta: 100 %). |
| Cobertura por país | Nº de países cuyo export ya incluye la columna / total de países que generan el reporte (meta: todos). |
| Adopción | Uso del reporte enriquecido por Administración/Reportes (confirmación cualitativa con el área). |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| El dato Versión no está expuesto por `sp_reporte_contratos` ni el modelo | Requiere ajuste de query/SP, ampliando el esfuerzo más allá del export. |
| Divergencia entre exports por país | El ajuste puede requerir tocar código distinto por plaza (p. ej. PaisCL), con riesgo de inconsistencia. |
| Calidad del dato origen | Contratos sin versión registrada mostrarían celdas vacías; percepción de reporte incompleto. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| El dato Versión existe en el dominio | La versión del vehículo ya se captura/almacena y solo falta exponerla en el export. |
| El reporte es el mismo entre países | El reporte de contratos emitidos comparte estructura base entre plazas, con el export de PaisCL como variante conocida. |
| Sin impacto en usuario final | El cambio es interno para Administración/Reportes; no afecta captación ni fidelización. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Disponibilidad del dato | ¿El SP `sp_reporte_contratos` o el modelo `contrato` ya exponen la versión del vehículo, o hay que ajustar la query SQL? |
| Definición del campo | ¿«Versión» corresponde a un campo único del catálogo de vehículos, o se compone de varios atributos (motor, acabado, año)? |
| Ubicación en el Excel | ¿En qué posición debe ir la columna y con qué encabezado exacto? |
| Alcance por país | ¿Cuáles países específicos generan este reporte y cuáles comparten el mismo código de export además de PaisCL? |
| Contratos sin versión | ¿Cómo representar la ausencia de versión: celda vacía, «N/A» u otro valor acordado? |
