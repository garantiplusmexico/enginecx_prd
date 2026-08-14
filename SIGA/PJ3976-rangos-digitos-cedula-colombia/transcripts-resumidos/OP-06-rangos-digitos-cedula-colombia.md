# Condensado — OP-06 Rangos de dígitos de cédula de identidad (Colombia)

## Decisiones
- Cambiar la validación de longitud del documento de identidad para Colombia: de "mínimo 10 dígitos fijo" a un rango permitido.
- Regla de validación de longitud **configurable por país** (no hardcodeada).

## Alcance / requerimientos
- Cédula de ciudadanía (Colombia): permitir de **7 a 10 dígitos** (hoy exige mínimo 10 y rellena con ceros a la izquierda los más cortos).
- NIT (Colombia): mantener/exigir **10 dígitos**.
- Eliminar el relleno artificial con ceros para documentos válidos con menos de 10 dígitos.

## Actores
- Usuarios que capturan documentos de identidad en SIGA para Colombia (por confirmar rol exacto: ejecutivo de ventas / PDV).

## Riesgos / pendientes
- Definir si la regla distingue por **tipo de documento** (cédula vs NIT vs otros) además de por país.
- Impacto en datos ya capturados con ceros de relleno (¿migración/normalización?).
- Efecto en integraciones/reportes que asumen longitud fija de 10.
- Confirmar longitudes exactas por tipo de documento (rangos min/max) y país base.

## Fechas / hitos
- No especificadas en el insumo.
