# Notas: Omitir Datos Distribuidor Chile

## Problema
El formulario de registro de distribuidor incluye los campos Cuenta Bancaria y CLABE, los cuales no aplican en Chile (CLABE es identificador bancario exclusivo de Mexico).

## Mejora propuesta
Ocultar o eliminar los campos Cuenta Bancaria y CLABE del formulario de registro de distribuidor para Chile.

## Consideraciones para desarrollo
- Ocultar campos Cuenta Bancaria y CLABE en _EditCHL de distribuidores.
- CLABE es identificador exclusivo de Mexico.
- No eliminar columnas BD, solo ocultar en UI Chile.
- Validar Create y Edit de distribuidor CHL.

## Importancia e impacto de negocio
- Importancia: Baja
- Impacto: Experiencia de usuario | Administracion local
- Oculta campos CLABE/cuenta en Chile; mejora formulario sin impacto en fidelizacion o captacion.
