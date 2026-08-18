# Condensado — plan-tecnico-bmw-cambios-2026-08

> Documento técnico (el CÓMO). Se conserva como insumo; el PRD sólo toma de aquí lo que
> condiciona el QUÉ y el POR QUÉ.

## Decisiones
- El interruptor para facturar al distribuidor **ya existe** en SIGA: `producto_proyecto.facturar_a_nombre`, usado por 12 proyectos. Los 66 productos BMW están hoy en "Beneficiario".
- El código que facturaba al dealer en BMW **existió y se eliminó** el 7-ago-2026; es recuperable íntegro de un commit anterior.
- No hace falta modificar el armador del CFDI para cambiar el receptor: se lee todo de `fiscales_poliza`.
- El módulo de usuarios se construye en el microservicio de **Authentication** (es el único con hashing de contraseñas, envío de correo y acceso a datos ya cableados). Todo su backend es nuevo.
- La modalidad de pago es **texto libre** de punta a punta: no hay catálogo, ni enum, ni esquema que cambiar.
- La paginación se porta de la landing de Bridgestone, que ya la resolvió server-side; el pipeline necesario ya está activo en el microservicio.

## Alcance / requerimientos
- Cinco frentes en el PRD: Care Plus al distribuidor, público en general con reintento y error del PAC, módulo de usuarios, modalidad "Financiamiento externo", paginación y folio de factura.
- El folio de factura **ya se captura y se almacena**; sólo falta exponerlo en el listado.
- El módulo de usuarios escribe en cuatro tablas dentro de una única transacción y deja rastro de quién dio de alta a quién.
- Se documentan 14 candados de seguridad para el módulo, con su justificación.

## Actores
- Sin actores nuevos respecto al condensado de decisiones de negocio.

## Riesgos / pendientes
- **El error del PAC nunca cruza el gRPC**: el método de timbrado individual carece de try/catch y devuelve siempre una respuesta vacía, así que el consumidor **reporta éxito falso**. El error sólo queda en el log del contenedor.
- Un CFDI individual a público en general **exige el nodo `InformacionGlobal`**, que el generador de CFDI no construye; es la causa verificada del rechazo CFDI40130. Sin resolverlo, el fallback a público en general no timbra.
- La cadena original y el XML del CFDI se construyen **por separado y a mano**: cualquier cambio debe aplicarse en ambos o el sello deja de corresponder.
- Cada intento fallido de timbrado deja una factura huérfana en base de datos; un reintento automático las duplica.
- La modalidad nueva **falla en silencio** si se olvida un punto concreto del controlador: crea contratos sin timbrar y sin orden de pago, sin error visible.
- Desactivar un usuario no surte efecto si no se ajusta también la bandera de bloqueo: seguiría obteniendo sesión por la API.
- Con paginación server-side se pierden tres filtros actuales del listado, que hoy operan sobre valores derivados en el cliente.

## Fechas / hitos
- Estimación: 19.5 – 26 días laborales para el paquete completo, incluyendo la fase de prueba y el despliegue.
- La prueba de `InformacionGlobal` en producción es la actividad inicial y la de mayor varianza (1 – 2 días).
