# Notas — Dígitos RUT (Operaciones Chile)

**Solicita:** Operaciones Chile
**Tipo:** Feature web / API
**Sistema:** SIGA · **Unidad:** Garantiplus Chile

## Problema
El sistema exige cantidad fija de dígitos en los campos RUT y HP, rechazando valores válidos con menor cantidad de caracteres.

## Mejora propuesta
Flexibilizar la validación de RUT y HP (permitir 2 o más dígitos).

## Consideraciones para desarrollo
- Implementar `ValidateRFC` en `PaisCL` (actualmente lanza `NotImplementedException`); para RUT chileno en backend y frontend.
- Flexibilizar HP a 2 o más dígitos.
- `IsEnabledFiscalIdValidation()` retorna `true` pero el backend no valida.

## Importancia e impacto de negocio
- **Importancia:** Alta
- **Impacto:** Captación de clientela · Operación diaria
- Validación de RUT y HP flexible; permite emitir contratos con datos válidos que hoy son rechazados, desbloqueando ventas.
