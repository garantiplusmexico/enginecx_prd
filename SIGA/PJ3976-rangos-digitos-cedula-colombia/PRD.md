# PRD - Rangos de dígitos de cédula (Colombia)

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Rangos de dígitos de cédula de identidad (Colombia) |
| **Área / empresa** | Garantiplus Colombia |
| **Versión** | v0.1 |
| **Fecha** | 2026-08-13 |
| **Autores** | Alejandro Govea Hernández |
| **Revisión / liderazgo** | Alexis Salvador Herrera García (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web / API |

## 1. Resumen ejecutivo

**Rangos de dígitos de cédula (Colombia)** es un ajuste de validación en **SIGA / GarantiplusWeb** para **Garantiplus Colombia**. Hoy el sistema exige un **mínimo de 10 dígitos** en el documento de identidad; los documentos válidos más cortos (p. ej. cédulas antiguas de 7 dígitos) se **rellenan artificialmente con ceros a la izquierda** para poder capturarlos, lo que ensucia el dato y no refleja el documento real.

En Colombia conviven cédulas **nuevas de 10 dígitos** con cédulas **antiguas de 7 dígitos** (ambas válidas). La restricción de mínimo fijo obliga a distorsionar el número real.

El **MVP** flexibiliza la longitud del documento de identidad **solo para Colombia**: la **cédula de ciudadanía** pasa a aceptar **7 a 10 dígitos** (eliminando el relleno con ceros), mientras el **NIT** se mantiene en **10 dígitos**. La regla de longitud queda **configurable por país** en `PaisesService`, con consistencia entre frontend y backend. **No** se normalizan los datos históricos ya rellenados con ceros.

**Resultado esperado:** capturar el número de documento real (sin ceros artificiales), desbloquear la captura de cédulas de 7 dígitos y mantener el dato limpio para operación y reportes.

**Capturar documento** → **selección tipo (cédula / NIT)** → **validación de longitud (flexible, por país)** → **registro con el número real**

## 2. Contexto y problema

- **Hoy:** al capturar el documento de identidad en GarantiplusWeb (Colombia), la validación exige **mínimo 10 dígitos**. Las cédulas antiguas de 7 dígitos, que son válidas, se **completan con ceros a la izquierda** para pasar la validación.
- **Dolor:** el número almacenado **no corresponde al documento real** (lleva ceros de relleno); además, cualquier documento válido más corto queda forzado a un formato incorrecto.
- **Distinción de dominio:** en Colombia conviven la **cédula de ciudadanía** (puede ser de 7 dígitos —antiguas— hasta 10 —nuevas—) y el **NIT** (identificación tributaria, 10 dígitos). La regla de longitud **no es la misma** para ambos.
- **Por qué ahora:** el relleno con ceros degrada la calidad del dato de identidad y puede frenar/ensuciar la captura de clientes con cédula corta.

## 3. Objetivo del producto

Flexibilizar la validación de longitud del documento de identidad en **Garantiplus Colombia**, de modo que la **cédula de ciudadanía** se acepte con **7 a 10 dígitos** (sin relleno de ceros) y el **NIT** se mantenga en **10 dígitos**, con la regla **configurable por país** en `PaisesService` y consistente entre frontend y backend, sin afectar a otros países.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Operaciones / Ejecutivos Colombia | Capturan el documento de identidad al registrar cliente/contrato; detectan el problema del relleno con ceros *(por confirmar rol exacto)* |
| Equipo de Desarrollo / TI | Ajusta los rangos por país en `PaisesService` y la validación backend; controla la configuración |
| BI / Operación | Consumen el dato de identidad; se benefician de tener el número real sin ceros artificiales |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Rango flexible de cédula (Colombia) | La cédula de ciudadanía acepta de **7 a 10 dígitos**; se elimina la exigencia de mínimo 10 y el relleno con ceros a la izquierda |
| NIT en 10 dígitos | El NIT se mantiene con longitud de **10 dígitos** |
| Regla configurable por país | Las longitudes min/max por tipo de documento se configuran de forma centralizada por país en `PaisesService` (mismo patrón que Dígitos RUT) |
| Consistencia frontend ↔ backend | El backend acepta los mismos valores que valida el frontend; ningún documento válido en front se rechaza en back |
| Mensajes de error acordes | Los mensajes reflejan el nuevo rango permitido por tipo de documento (no "mínimo 10 dígitos") |
| Cambio acotado a Colombia | El ajuste aplica **solo** a Colombia; México y Chile quedan intactos |

**Principio rector del MVP:** capturar el documento real sin distorsionarlo. El MVP **relaja/ajusta longitudes por tipo de documento y país**; **no** normaliza datos históricos ni valida la estructura/dígito de verificación del documento.

## 6. Fuera de alcance

- **Normalizar/migrar los documentos históricos rellenados con ceros:** el MVP solo cambia la validación en captura nueva; limpiar datos existentes queda fuera (se habilitaría con un esfuerzo de migración/BI aparte).
- **Validación estructural o de dígito de verificación (cédula/NIT):** solo se ajusta la longitud; no se valida la integridad del número.
- **Cambiar la configuración de otros países (México, Chile):** el ajuste es exclusivo de Colombia para evitar regresiones.
- **Rediseñar la pantalla de captura:** solo se ajustan reglas de validación y mensajes.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Cédula con longitud flexible (Colombia) | El sistema acepta cédula de ciudadanía de **7 a 10 dígitos** en la captura del documento para Colombia |
| RF-02 | Sin relleno con ceros | El sistema deja de rellenar con ceros a la izquierda los documentos con menos de 10 dígitos; se guarda el número tal cual |
| RF-03 | NIT en 10 dígitos | El sistema mantiene el NIT con longitud de **10 dígitos** |
| RF-04 | Regla configurable por país | Los rangos min/max por tipo de documento se definen por país en `PaisesService` |
| RF-05 | Consistencia front/back | El backend acepta los mismos valores que el frontend valida; ningún valor válido en front es rechazado en back |
| RF-06 | Mensajes de error acordes | Los mensajes de validación reflejan el rango vigente por tipo de documento |
| RF-07 | Alcance por país | Los cambios aplican solo a Colombia; México y Chile permanecen sin cambios |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | No regresión multi-país | El cambio en Colombia no altera la validación de México ni Chile |
| RNF-02 | Mantenibilidad / config por país | Las longitudes siguen configurándose de forma centralizada por país en `PaisesService` |
| RNF-03 | Consistencia de datos | Reglas de validación equivalentes entre frontend y backend |
| RNF-04 | Claridad de mensajes | Mensajes de error coherentes con la regla vigente por tipo de documento |
| RNF-05 | Integridad del dato de identidad | El número capturado corresponde al documento real (sin ceros artificiales) |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| `PaisesService` (librería) | Fuente de configuración por país de longitudes/mensajes del documento de identidad; se ajustan los rangos de Colombia (cédula 7–10, NIT 10) |
| GarantiplusWeb (frontend) | Consume `PaisesService`; aplica los rangos en la pantalla de captura |
| Backend SIGA (validación de identidad) | Debe quedar consistente con los rangos del front (aceptar cédula 7–10, NIT 10) |

**Datos mínimos:** tipo de documento (cédula de ciudadanía / NIT) y número de documento capturados en el registro de cliente/contrato para Colombia.

**Permisos:** cambio de configuración/validación gestionado por Desarrollo/TI; no expone nuevos permisos a usuarios finales.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Documentos capturados sin relleno de ceros | Cédulas de 7–9 dígitos capturadas con su número real (antes imposibles sin ceros) — *línea base por validar con Operación/BI* |
| Rechazos indebidos por longitud | Reducción (idealmente a 0) de rechazos de cédulas válidas más cortas — *por validar con Operación* |
| Regresiones en otros países | 0 incidencias de validación reportadas en México/Chile tras el cambio |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| El cambio no se acota bien a Colombia | Regresión en la validación de documentos de México/Chile |
| Backend inconsistente con el front | El backend podría rechazar cédulas de 7–9 dígitos que el front ya acepta |
| Datos históricos con ceros conviven con nuevos sin ceros | Inconsistencia en reportes/búsquedas mientras no se normalice el histórico (fuera de alcance) |
| Ubicación de la validación de longitud en Colombia | Si la longitud del documento no vive en `PaisesService`, el ajuste podría requerir tocar otro punto |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Config por país aislada | `PaisesService` permite ajustar min/max de Colombia sin afectar otros países |
| El front respeta `PaisesService` | La validación del frontend efectivamente toma los rangos de `PaisesService` |
| Rango cédula 7–10 correcto | 7 (min) y 10 (max) dígitos cubren las cédulas de ciudadanía válidas de Colombia |
| NIT = 10 | El NIT colombiano se captura con 10 dígitos |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Otros tipos de documento | ¿Hay que contemplar cédula de extranjería, pasaporte u otros? ¿Con qué rangos? |
| NIT – dígito de verificación | Los 10 dígitos del NIT, ¿incluyen el dígito de verificación o solo el número base? |
| Conteo de dígitos | El rango 7–10, ¿cuenta solo dígitos numéricos (sin separadores/guiones)? |
| Ubicación de la validación | ¿La longitud del documento de Colombia vive hoy en `PaisesService` (como el RUT de Chile) o en otro punto del backend? |
| Datos históricos | ¿Se hará después una normalización de los documentos ya rellenados con ceros? ¿Quién la prioriza (BI/operación)? |
