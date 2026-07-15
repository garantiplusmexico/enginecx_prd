# Condensado — feature-nuevo-rol-distribuidor-taller

## Decisiones
- Crear un nuevo rol de usuario llamado **Usuario Distribuidor-Taller** en SIGA.
- El rol combina las capacidades/permisos de los roles existentes **Usuario Distribuidor** y **Usuario Taller**.

## Alcance / requerimientos
- En el **catálogo de usuarios**, al crear un usuario de este tipo se debe permitir seleccionar:
  - **uno o varios distribuidores** relacionados al usuario.
  - **el taller** al que estará relacionado el usuario.
- Las **opciones/permisos** de este usuario deben corresponder a la unión de las permitidas a Usuario Distribuidor y Usuario Taller.

## Actores
- Usuario Distribuidor-Taller (nuevo rol).
- Administrador del catálogo de usuarios (quien crea/edita el usuario).

## Riesgos / pendientes
- ¿Relación con distribuidores es 1:N (varios) y con taller 1:1 (uno)? Confirmar cardinalidad exacta.
- ¿Cómo se resuelve la unión de permisos cuando ambos roles difieren en una misma opción?
- ¿Aplica a edición además de creación de usuarios?

## Fechas / hitos
- (No especificadas en el transcript.)
