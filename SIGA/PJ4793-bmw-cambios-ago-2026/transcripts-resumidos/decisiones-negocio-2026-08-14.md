# Condensado — decisiones-negocio-2026-08-14

## Decisiones
- Care Plus factura al **distribuidor sólo cuando la modalidad es Contado**. En esa combinación se ocultan CP fiscal y régimen fiscal; nombre y RFC se siguen capturando y guardando en el contrato.
- El cliente **sigue pagando por pasarela** aunque el receptor del CFDI sea el distribuidor.
- Uso de CFDI al dealer: **S01** por ahora, sujeto a confirmación posterior de negocio.
- Los contratos Care Plus **ya vendidos no se refacturan**.
- Los 48 distribuidores **se quedan con datos fiscales genéricos**; se acepta que el timbrado marque error.
- Lista blanca del módulo de usuarios: **correos en `appsettings`**, reutilizando los de la lista ya existente en el `appsettings` de Contratos (Carlos y Alexis).
- Credencial del alta: **contraseña en claro por correo**, igual que SIGA hoy.
- **Sí** se permite editar el correo de un usuario.
- Los 640 usuarios existentes **aparecen en el listado**; el módulo lleva filtros de búsqueda y de estado activo/inactivo.
- El rol que se puede dar de alta es **únicamente "Usuario Distribuidor"**; el alcance del administrador son los **48 distribuidores** BMW; la eliminación es **lógica**.
- El paquete se registra como **un solo PRD**, con nota de solape con **PJ2613**. Alcance en **tres fases**.
- El registro de averías simplificado (sólo VIN y descripción) **queda fuera de este PRD**: se resuelve al final.

## Alcance / requerimientos
- Facturación a **público en general** cuando no se capturen CP fiscal ni régimen fiscal, con la excepción de Contado + Care Plus.
- **Segundo intento de timbrado** con datos de público en general cuando el primero falla habiendo datos fiscales. El reintento vive **en el back**; el proyecto de facturación sigue funcionando igual.
- **Try/catch** que permita conocer el error exacto que devuelve el PAC.
- Nueva modalidad de pago **"Financiamiento externo"**, con el mismo comportamiento que "Financiamiento".
- **Paginación** y **campo factura** en la vista de registros de la landing, al estilo de la landing de Bridgestone.
- Módulo **CRUD de usuarios** dentro de la landing, con lista blanca, rol fijo, selección de distribuidores, baja lógica y filtros.

## Actores
- **BMW (RH)**: administrará las altas y bajas de usuarios de sus distribuidores; conoce quién está activo.
- **Operaciones GarantiPlus**: hoy es la única que puede dar de alta usuarios; cede parte de esa función.
- **Carlos Castellanos y Alexis Herrera**: únicos en la lista blanca inicial.
- **Usuario Distribuidor**: usuario final creado por el módulo; opera la landing de registro de garantías.
- **Distribuidores BMW (48)**: receptores del CFDI en los contratos Care Plus de Contado.

## Riesgos / pendientes
- Facturar al dealer con RFC genérico produce un CFDI **no deducible** para el distribuidor; si el objetivo era que dedujera, la decisión de datos genéricos no lo logra.
- Con contraseña en claro por correo **y** correo editable, cambiar el correo de un usuario y pedir restablecimiento es una vía de toma de cuenta; exige auditoría del cambio.
- El módulo abre a un tercero una función hoy exclusiva de Operaciones GarantiPlus.
- Solape funcional con **PJ2613**: la misma capacidad (crear Usuario Distribuidor acotado a dealers) se construiría dos veces si no se coordina.

## Fechas / hitos
- 13-ago-2026: BMW plantea las dos solicitudes originales.
- 14-ago-2026: se cierran las nueve decisiones y se suman los cuatro ajustes adicionales.
- **Primera actividad del proyecto**: prueba de `InformacionGlobal` directa en producción sobre un contrato de la cartera Allianz.
