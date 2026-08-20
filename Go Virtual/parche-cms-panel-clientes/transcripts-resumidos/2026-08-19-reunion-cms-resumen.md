# Resumen — Reunión PRD CMS (2026-08-19)

| Campo | Detalle |
|---|---|
| Participantes | Sharon Mendoza (Go Virtual) · Javier Antonio Oropeza Camacho (Desarrollo) |
| Duración | 00:28:56 |
| Transcripción íntegra | `transcripts/2026-08-19-reunion-cms-transcripcion.md` |

## Objeto de la reunión

Sharon presenta lo que falta desarrollar en el panel CMS para que el "parche" que necesita Aldo Álvarez funcione: abrir el panel a los clientes (dealers y grupos) con contenido local propio, y corregir el esquema de accesos actual.

## Puntos tratados

**Banners y promociones OEM + locales** *(00:00:00, 00:25:33)* — Hoy el panel solo maneja contenido global de marca. Se necesita que convivan con contenido local y que un administrador local pueda ver ambos. Referencia de mercado: DealerOn los maneja en apartados separados; aquí se plantea resolverlo con tabs para distinguir global de local. Go Virtual debe conservar acceso al contenido local porque su equipo de soluciones hace los cambios de oferta comercial mes a mes.

**Módulo de thank you pages** *(00:03:31)* — No existe en el panel. Son las páginas que se muestran al enviar un formulario. Los mensajes son **uno por formulario**: un sitio con cinco formularios tiene cinco páginas. Campos básicos: título, subtítulo y botones de acción.

**Qué ve el cliente** *(00:06:51)* — Grupos, información de cada dealer, banners y promociones locales, bitácora de cambios, thank you pages, lead driver y pop-ups. Nada más. Go Virtual retiene la administración general.

**Acceso a Duda** *(00:08:35)* — El cliente seguirá editando blog, landings y auditoría de SEO en Duda. Se busca que llegue desde el panel ya autenticado, sin volver a iniciar sesión.

**Jerarquía organizacional** *(00:10:14, 00:18:52)* — Ejemplo Autofin: un grupo con ~54 dealers. Existen tres situaciones: administrador del grupo completo, administrador de un subgrupo (los cinco Volkswagen que pertenecen a la misma persona) y administrador de una agencia individual. El modelo debe soportar grupos multimarca y multiubicación, marcas con varios dealers, y clientes sin grupo.

**Roles** *(00:14:07)* — Dos niveles (dealer y grupo) y dos roles internos: editor con enfoque de marketing (promociones, campañas), y administrador que además edita información operativa (horarios, dirección, ficha de Google My Business).

**Estado actual de los accesos** *(00:15:49)* — Señalado como urgente: prácticamente todas las cuentas operan como super admin, incluido el equipo de soluciones, que debería ser editor. Los administradores están sobrelimitados y el rol de editor "no sirve para nada". El riesgo concreto que preocupa es el mapeo de leads: un cambio ahí rompe la captura de formularios y hoy cualquier super admin puede tocarlo.

**Creación de usuarios** *(00:22:12)* — Debe quedar controlada por Go Virtual por el costo de licencias por login. Se distingue de dar de alta dealers, que es otra cosa. La tarea de alta de cuentas debería recaer en un rol de administrador, dejando super admin prácticamente para desarrollo.

## Acuerdos

1. **Orden de trabajo** *(00:17:25)*, propuesto por Javier y aceptado: primero roles, luego validar el filtrado de banners y promociones por grupo o dealer, y al final construir los tres módulos nuevos.
2. **Creación de usuarios exclusiva de Go Virtual**, por control de costos de licenciamiento.
3. **Convivencia global/local**: Go Virtual mantiene la gestión del contenido de marca; se amplía el módulo para que el cliente gestione el suyo.

## Siguientes pasos acordados

- Sharon: compartir el documento de requerimientos mostrado en pantalla.
- Javier: elaborar el plan de implementación con la estrategia de roles, banners y convivencia de contenidos, y regresarlo para validación.

## Puntos que quedaron sin definir en la reunión

Sharon indica explícitamente *(00:05:31)* que el reparto de "qué le toca a cada quien" no estaba cerrado, sino el inventario de lo que falta construir. Los pendientes se enviaron como preguntas y se resolvieron en el documento del 2026-08-20 (`transcripts-resumidos/2026-08-20-respuestas-resumen.md`).
