# Condensado — digitos-rut

## Decisiones
- Tipo de proyecto: **B. Feature web / API** (validación en backend y frontend de SIGA).
- Solicita: **Operaciones Chile**. Unidad: Garantiplus Chile. Sistema: SIGA.

## Alcance / requerimientos
- Flexibilizar la validación de los campos **RUT** y **HP**: permitir **2 o más dígitos** (hoy exige cantidad fija y rechaza valores válidos más cortos).
- Implementar `ValidateRFC` en `PaisCL` (hoy lanza `NotImplementedException`) para el **RUT chileno**, en **backend y frontend**.
- Corregir inconsistencia: `IsEnabledFiscalIdValidation()` retorna `true` pero el backend **no valida** realmente.

## Actores
- Operaciones Chile (solicitante / usuario del proceso de emisión de contratos).

## Riesgos / pendientes
- Definir qué es el campo **HP** y su formato.
- Definir la regla exacta de validación del RUT chileno (dígito verificador).

## Fechas / hitos
- (pendiente)

## Impacto de negocio
- Importancia **Alta**. Desbloquea emisión de contratos con datos válidos hoy rechazados → captación de clientela / ventas.
