# PRD - Dígitos RUT

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Dígitos RUT |
| **Área / empresa** | Garantiplus Chile |
| **Versión** | v0.1 |
| **Fecha** | 2026-07-23 |
| **Autores** | Alejandro Govea Hernández |
| **Revisión / liderazgo** | Alexis Salvador Herrera García (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web / API |

## 1. Resumen ejecutivo

**Dígitos RUT** es un ajuste de validación en **SIGA / GarantiplusWeb** para **Garantiplus Chile**, solicitado por **Operaciones Chile**. Hoy la emisión de contratos exige una **cantidad fija de caracteres** en los campos **RUT** (identificador fiscal del cliente/beneficiario y del dealer) y **HP** (caballos de fuerza del vehículo), rechazando valores que en realidad son válidos pero más cortos. Esto impide emitir contratos con datos correctos y frena ventas.

El problema nace de que las longitudes se configuran por país en la librería **PaisesService** (que consume GarantiplusWeb): para Chile el RUT está fijo en 12 caracteres (`rfc_min = rfc_max = 12`, mensaje "El RUT debe tener 12 caracteres"), y el campo HP tiene una restricción de longitud fija en otro punto del sistema.

El **MVP** flexibiliza esas longitudes **solo para Chile**: RUT pasa a aceptar **8 a 12 caracteres** y HP a aceptar **1 o más dígitos (incluido 0)**, con mensajes de error acordes y consistencia entre frontend y backend. **No** se implementa validación de dígito verificador ni se altera la configuración de otros países.

**Resultado esperado:** desbloquear la emisión de contratos hoy rechazados → mayor captación de clientela y fluidez en la operación diaria de Chile.

**Emitir contrato** → **captura RUT / HP** → **validación de longitud (flexible, por país)** → **contrato emitido**

## 2. Contexto y problema

- **Hoy:** al emitir un contrato en GarantiplusWeb (Chile), el frontend toma los rangos de validación desde **PaisesService**. El RUT está configurado con longitud fija de **12** (`beneficiario_rfc_min/max = 12` en `GetAdditionalContractBeneficiaryVehicleElements()`; `rfc_longitud_min/max = 12` en `GetAdditionalDealerElements()`). El campo **HP** tiene una restricción de longitud fija en un punto aún por ubicar (no está en PaisesService).
- **Dolor:** valores de RUT y HP **válidos pero más cortos** son rechazados, bloqueando la emisión de contratos con datos correctos.
- **Inconsistencia técnica conocida:** `ValidateRFC` en `PaisCL` nunca se implementó (lanza `NotImplementedException`); era para validar la *estructura* del identificador fiscal por país, pero quedó sin uso. Además, `IsEnabledFiscalIdValidation()` retorna `true` pero el backend no valida realmente — hay que asegurar que el backend no bloquee los valores que el frontend ya acepta.
- **Por qué ahora:** impacto **Alto** en captación de clientela y operación diaria; cada rechazo indebido es una venta frenada.

## 3. Objetivo del producto

Flexibilizar la validación de longitud de los campos **RUT** y **HP** en la emisión de contratos de **Garantiplus Chile**, para que se acepten todos los valores válidos (RUT de 8 a 12 caracteres; HP de 1 o más dígitos, incluido 0), manteniendo la configuración centralizada por país y sin afectar a otros países ni introducir validación estructural del identificador fiscal.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Operaciones Chile | Solicitante; opera la emisión de contratos y detecta los rechazos indebidos |
| Ejecutivos / dealers que emiten contratos en GarantiplusWeb (Chile) | Usuarios finales que capturan RUT y HP al emitir el contrato *(por confirmar)* |
| Equipo de Desarrollo / TI | Implementa el ajuste en PaisesService y backend; controla la configuración por país |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Flexibilizar longitud de RUT (Chile) | Ajustar en PaisesService los rangos del RUT para Chile: **min 8, max 12** caracteres (hoy fijo en 12), en los campos de beneficiario y dealer que hoy usan `rfc_min/max = 12` |
| Flexibilizar longitud de HP | Permitir **1 o más dígitos** en HP, admitiendo el valor **0**; eliminar la exigencia de longitud fija |
| Mensajes de error acordes | Actualizar los mensajes (hoy "El RUT debe tener 12 caracteres") para reflejar el nuevo rango permitido |
| Consistencia frontend ↔ backend | Asegurar que el backend acepte los mismos valores que el frontend valida por PaisesService (resolver que `IsEnabledFiscalIdValidation()=true` no bloquee valores válidos) |
| Cambio acotado a Chile | El ajuste aplica **solo** a la configuración de Chile; México y Colombia quedan intactos |

**Principio rector del MVP:** aceptar todo valor válido sin sobre-validar. El MVP **relaja longitudes**; **no** valida la estructura ni el dígito verificador del RUT.

## 6. Fuera de alcance

- **Implementar `ValidateRFC` / validación de dígito verificador del RUT (módulo 11, "K"):** se decidió mantener solo validación por longitud; la validación estructural queda fuera (se habilitaría si más adelante se requiere integridad del RUT).
- **Cambiar la configuración de otros países (México, Colombia):** el ajuste es exclusivo de Chile para no introducir regresiones.
- **Modificar el cálculo del precio de la garantía que usa HP:** solo se flexibiliza la *validación* de longitud del campo, no su uso en el pricing.
- **Rediseñar la pantalla de emisión de contrato:** solo se ajustan reglas de validación y mensajes.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | RUT con longitud flexible (Chile) | El sistema acepta RUT de **8 a 12 caracteres** en emisión de contrato para Chile, en los campos de beneficiario y dealer |
| RF-02 | HP con longitud flexible | El sistema acepta HP de **1 o más dígitos**, incluido el valor **0**, sin exigir longitud fija |
| RF-03 | Mensajes de error acordes | Los mensajes de validación reflejan el nuevo rango (no "El RUT debe tener 12 caracteres") |
| RF-04 | Consistencia front/back | El backend acepta los mismos valores que el frontend valida vía PaisesService; ningún valor válido en front es rechazado en back |
| RF-05 | Alcance por país | Los cambios aplican solo a Chile; la configuración de México y Colombia permanece sin cambios |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | No regresión multi-país | El cambio en Chile no altera el comportamiento de validación de México ni Colombia |
| RNF-02 | Mantenibilidad / config por país | Las longitudes siguen configurándose de forma centralizada por país en PaisesService |
| RNF-03 | Consistencia de datos | Reglas de validación equivalentes entre frontend y backend |
| RNF-04 | Claridad de mensajes | Mensajes de error localizados y coherentes con la regla vigente |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| PaisesService (librería) | Fuente de configuración por país de longitudes/mensajes de RUT (y campos afines); se ajustan los rangos de Chile |
| GarantiplusWeb (frontend) | Consume PaisesService; aplica los rangos en la pantalla de emisión de contrato |
| Backend SIGA (validación fiscal) | Aloja `IsEnabledFiscalIdValidation()` y `ValidateRFC`/`PaisCL`; debe quedar consistente con los rangos del front |

**Datos mínimos:** RUT (identificador fiscal de beneficiario y de dealer) y HP (caballos de fuerza, numérico) capturados en la emisión de contrato.

**Permisos:** cambio de configuración/validación gestionado por Desarrollo/TI; no expone nuevos permisos a usuarios finales.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Rechazos indebidos por RUT/HP | Reducción (idealmente a 0) de contratos rechazados por longitud de RUT o HP en Chile — *línea base por validar con Operaciones/BI* |
| Contratos emitidos (Chile) | Aumento de contratos emitidos que antes se bloqueaban — *por validar con BI* |
| Regresiones en otros países | 0 incidencias de validación reportadas en México/Colombia tras el cambio |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| El cambio no se acota bien a Chile | Regresión en la validación de RUT de México/Colombia |
| HP no está en PaisesService (ubicación de la validación desconocida) | Se ajusta el front pero HP sigue bloqueado en el punto no identificado |
| Backend inconsistente (`IsEnabledFiscalIdValidation()=true` sin validar) | El backend podría rechazar valores que el front ya acepta |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Config por país aislada | PaisesService permite ajustar min/max de Chile sin afectar otros países |
| El front respeta PaisesService | La validación del frontend efectivamente toma los rangos de PaisesService |
| Rango RUT 8–12 correcto | 8 (min) y 12 (max) caracteres cubren los RUT válidos de Chile |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| HP – ubicación | ¿Dónde se valida hoy la longitud de HP (no está en PaisesService)? ¿Existe un máximo deseado o solo mínimo 1? |
| RUT – conteo | La longitud 8–12, ¿cuenta puntos y guion (formato `12.345.678-9`) o solo dígitos? |
| Backend | ¿Qué debe hacer el backend con `IsEnabledFiscalIdValidation()=true` para Chile: desactivarlo o alinearlo a validación solo-longitud? |
| Alcance de campos | ¿Todos los campos que hoy usan `rfc_min/max = 12` (beneficiario y dealer) pasan a 8–12, o alguno queda distinto? |
