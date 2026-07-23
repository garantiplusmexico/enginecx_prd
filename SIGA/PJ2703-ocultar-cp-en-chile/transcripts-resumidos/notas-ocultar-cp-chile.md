# Condensado — notas-ocultar-cp-chile

## Decisiones
- No solicitar el campo Código Postal (CP) en el formulario de emisión de contratos para Chile (ocultarlo).
- No afectar los formularios de México ni Colombia.

## Alcance / requerimientos
- Ocultar el campo CP en los partials de emisión CHL (`_BeneficiarioCHL`, `Create`).
- Ajustar reglas en `PaisCL` si aplica.
- El campo CP no es obligatorio (según nota del documento).

## Actores
- Solicita: Operaciones Chile.
- Revisión técnica: Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx).

## Riesgos / pendientes
- Confirmar si hay reglas de validación de CP en `PaisCL` que deban ajustarse.
- Definir si el campo solo se oculta en UI o también deja de capturarse/persistirse para Chile.

## Fechas / hitos
- (sin fechas comprometidas)

## Importancia / impacto
- Importancia: Baja. Impacto: Experiencia de usuario / administración local. Sin impacto en fidelización o captación.
