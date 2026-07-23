# Notas — Trazabilidad Usuario Crea Contratos

**Solicita:** Operaciones / Colombia
**Revisión técnica:** Alexis Salvador Herrera Garcia — alexis.herrera@gplusseguros.mx

## Problema
No hay trazabilidad del usuario que creó una garantía, dificultando auditorías.

## Mejora propuesta
Registrar el usuario creador en reportes e informes.

## Consideraciones para desarrollo
- `usuario_creador` ya se usa para filtrar reportes.
- Agregar columna 'Usuario creador' en reportes Producción y Explotación.
- Extender SPs/queries donde falte `registra_contrato`.
- Export Excel Chile ya incluye 'Usuario registra' como referencia.

## Importancia e impacto de negocio
- Importancia: Media
- Impacto: Trazabilidad | Auditoría
- Registra quién creó cada garantía; mejora control interno y auditorías, sin impacto directo en captación.
