# Decisiones de negocio — BMW, paquete de cambios ago-2026

**Fecha:** 14-ago-2026 · **Origen:** sesión de definición con Carlos Castellanos (TI GarantiPlus)
sobre las dos solicitudes de BMW del 13-ago y los ajustes adicionales detectados.

---

## Solicitudes originales de BMW (13-ago)

1. Los contratos con producto **"Care Plus"** se deben facturar **al distribuidor**.
2. Crear una **sección dentro de la misma landing para el alta de usuarios de BMW**, visible sólo
   para personas en una **lista blanca**. Debe iniciar sesión y estar en la lista para ver el módulo.
   Similar a la creación de usuario que existe en SIGA: nombre, correo y rol, pero el listado de
   roles sólo será **"Usuario Distribuidor"**, y podrá seleccionar los distribuidores a los que el
   usuario tendrá acceso. Debe ser un **CRUD**, con **eliminación lógica** (se desactiva el usuario).

   > Textual del solicitante: *"Hay que blindar bien este módulo, porque el alta de usuario hoy está
   > controlada por gente de operaciones de Garantiplus y esto abre la puerta a que alguien del
   > cliente dé de alta los usuarios. De cierta forma está bien, porque sólo podrán dar de alta
   > usuarios con el rol distribuidor, sólo para distribuidores de BMW, y ellos mismos podrán
   > gestionar los usuarios de su gente. Se tiene pensado que, por ejemplo, alguien de RH de BMW
   > lleve esta gestión, ya que ellos saben quién está activo y quién no. Pero no significa que no
   > pueda haber un hueco de seguridad, así que hay que poner ojo a esto."*

---

## Respuestas a las preguntas abiertas (14-ago)

| # | Pregunta | Respuesta |
|---|---|---|
| 1 | Si el CFDI de Care Plus va al distribuidor, ¿quién paga y por qué vía? | El **cliente sigue pagando por pasarela** y la factura va al distribuidor. **Con un acote:** esto sólo aplica cuando el producto es **Care Plus** *y* la modalidad es **Contado**. En esa combinación se **ocultan** los campos de datos fiscales (código postal y régimen fiscal). Nombre y RFC se siguen pidiendo y guardando igual, pero los datos fiscales del comprobante son los del distribuidor |
| 2 | ¿Con qué uso de CFDI se factura al dealer? | Se deja **S01** por ahora. Negocio confirmará después si se queda o se cambia |
| 3 | ¿Los Care Plus ya vendidos se refacturan? | **No.** Se dejan como están |
| 4 | Los 48 distribuidores no tienen datos fiscales reales | **Se dejan con datos genéricos. No importa que el timbrado marque error** |
| 5 | Mecanismo de la lista blanca del módulo de usuarios | **Correos en `appsettings`** |
| 6 | ¿Contraseña en claro o link de activación? | **Contraseña en claro por correo**, como hace SIGA hoy |
| 7 | ¿Quién queda en la lista blanca? | De momento **sólo Carlos y Alexis**. Ya existe una lista blanca de otro tema en el `appsettings` de Contratos; se toman los mismos correos |
| 8 | ¿Se puede editar el correo de un usuario? | **Sí** |
| 9 | ¿Qué pasa con los 640 usuarios que ya existen? | **Aparecen en el listado** del módulo. Además, el módulo debe tener **filtros para buscar un usuario y saber quién está activo y quién no** |

---

## Ajustes adicionales solicitados (14-ago)

1. **Facturación a público en general** siempre que **no se manden los datos fiscales** (código postal
   y régimen fiscal), **excepto** cuando es Contado y se elige el producto Care Plus (caso del punto 1).
   - Si los datos **sí** se capturaron pero el **timbrado falló**, debe hacerse un **segundo intento**,
     ahora con los datos de público en general.
   - Ese reintento **debe hacerse desde el back**; el proyecto de facturación debe seguir funcionando
     igual.
   - Para esto conviene **agregar el try/catch que hace falta** para saber exactamente el error que
     devuelve el PAC.
2. Agregar la modalidad de pago **"Financiamiento externo"**, que funciona igual que "Financiamiento".
3. Agregar a la landing **paginación** y el **campo factura** en la vista de registros, similar a como
   lo hace la landing de Bridgestone.
4. *(Tema aparte, para el repo de SIGA)* En el **registro de averías** sólo se debe pedir **VIN y
   descripción**. Ya hay configuración en PaisesService que puede servir.
   → **Se acordó resolverlo al final y NO incluirlo en este PRD.**

---

## Decisiones de método (14-ago)

- La **prueba de `InformacionGlobal` se hace directo en producción**, sobre uno de los contratos de la
  cartera Allianz recientemente cargados, que fueron a público en general y no lograron timbrar por
  esa causa. El desarrollador ejecuta las consultas y lanza la llamada gRPC desde terminal.
  **Debe ser la primera actividad del proyecto.**
- El despliegue de `FacturacionGarantiplus` (y de todos los proyectos del repo de SIGA) se hace **a
  mano**, con `dotnet publish` y subida de DLLs. Lo realiza el desarrollador.
- El paquete se registra como **un solo PRD**. El módulo de usuarios se documenta aquí, dejando
  registrado el **solape con el PRD PJ2613** (Ejecutivo de Ventas crea asesores, PDV y usuarios),
  que cubre la misma capacidad en otra superficie.
- Alcance por **tres fases**: Fase 0 (prueba del PAC), Fase 1 (lo que no depende de nadie), Fase 2
  (facturación).
