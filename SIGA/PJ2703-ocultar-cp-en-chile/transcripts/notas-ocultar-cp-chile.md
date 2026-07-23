# Notas — Ocultar CP en Chile

**Solicita:** Operaciones Chile
**Revisión técnica:** Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx)
**Área / empresa:** Garantiplus Chile — Sistema: SIGA
**Tipo:** Feature web/API

## Problema
El campo Código Postal es solicitado en el formulario de emisión, dato irrelevante para la operación en Chile.

## Mejora propuesta
No solicitar el campo Código Postal del formulario de emisión de contratos para Chile.

## Consideraciones para desarrollo
- Ocultar campo Código Postal en partials de emisión CHL (`_BeneficiarioCHL`, `Create`).
- Ajustar reglas en `PaisCL` si aplica.
- El campo no es obligatorio según nota del documento.
- No afectar formularios de México/Colombia.

## Importancia e impacto de negocio
- **Importancia:** Baja
- **Impacto:** Experiencia de usuario | Administración local
- Elimina campo irrelevante en Chile; mejora usabilidad del formulario sin impacto en fidelización o captación.
