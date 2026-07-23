# Condensado — Notas: Omitir Datos Distribuidor Chile

## Decisiones
- Ocultar (NO eliminar) los campos **Cuenta Bancaria** y **CLABE** en el formulario de registro de distribuidor para **Chile**.
- No eliminar columnas de base de datos; el cambio es solo de UI para Chile.

## Alcance / requerimientos
- Ocultar los campos Cuenta Bancaria y CLABE en la vista `_EditCHL` de distribuidores.
- Validar tanto el flujo **Create** como **Edit** de distribuidor CHL.
- Alcance limitado a Chile; México/Colombia no cambian (CLABE es exclusiva de México).

## Actores
- Administración local (usuarios que registran/editan distribuidores en Chile).

## Riesgos / pendientes
- Verificar que ocultar los campos no rompa validaciones server-side que los exijan como obligatorios.
- Confirmar que las columnas queden nulas/vacías en BD sin efectos colaterales.

## Fechas / hitos
- (No especificadas)

## Importancia / impacto
- Importancia: Baja. Impacto: Experiencia de usuario / Administración local. Sin impacto en fidelización o captación.
