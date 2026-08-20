# Resumen — Validación y respuestas de Go Virtual (2026-08-20)

| Campo | Detalle |
|---|---|
| Autor | Sharon Mendoza (Go Virtual), tras revisión con su equipo |
| Responde a | Documento de plan por fases enviado el 2026-08-19 |
| Documento íntegro | `transcripts/2026-08-20-respuestas-validacion.md` |

## Veredicto

El alcance y el orden de las fases quedan **validados**, con dos modificaciones y ocho respuestas.

## Modificaciones al alcance

### 1. Tres niveles de contenido, no dos *(Fase 2)*

Los módulos se dividen en tres niveles en lugar de dos. Esto responde de paso la pregunta sobre si eran dos o tres niveles.

| Nivel | Administra |
|---|---|
| OEM marca | Solo Go Virtual |
| OEM grupo | Go Virtual y el admin del grupo |
| Dealer | Go Virtual y el admin del dealer |

**Reglas de herencia:**

- **Dealer** (el más bajo): no puede ocultar, eliminar ni reordenar lo heredado de grupo o marca. Solo asigna elementos a su agencia.
- **Grupo**: no puede ocultar, eliminar ni reordenar lo heredado de marca. Sí asigna elementos al conjunto de dealers de su grupo.
- **Marca**: asigna elementos a cualquier sitio que pertenezca a la marca.

**Orden de aparición:** marca → grupo → dealer.

> **Impacto técnico:** esta regla **elimina** la necesidad de sobreescrituras por dealer. En la versión anterior el dealer podía ocultar y reordenar el contenido OEM, lo que obligaba a una colección aparte de overrides porque un banner de marca lo comparten todas las agencias de esa marca. Con la regla nueva el orden es determinista y esa complejidad desaparece del alcance.

### 2. Alta de grupos y dealers: solo Go Virtual *(cambio de permisos)*

Señalado de forma explícita como ajuste respecto a lo que quedaba confirmado en el documento anterior. El cliente **no** tendrá acceso al alta de grupos ni de dealers.

> **Impacto técnico:** elimina la necesidad de forzar el grupo desde el token al crear dealers, y cierra la vía por la que un admin de grupo podía ampliar su propio ámbito de datos creando agencias.

## Ampliación de la Fase 3

Los tres módulos operan a nivel grupo y dealer con la misma lógica de la Fase 2: el nivel grupo asigna lo que es igual para todos los sitios de su grupo; el nivel dealer cubre las particularidades de cada agencia.

**Módulo TYP (página de agradecimiento)**
- Se replica la forma en que se construyó *lead destinations*, para tener siempre presentes las páginas de los formularios existentes que provee Go Virtual. Quedan dadas de alta por defecto con información base, modificable a demanda.
- Campos: título (obligatorio), subtítulo (obligatorio), slug (obligatorio), CTAs (opcional, hasta 3 botones con texto y link cada uno).

**Módulo pop-up**
- Campos: título (obligatorio), imagen mobile y desktop (obligatorio), link (obligatorio), vigencia (opcional), página donde se mostrará (obligatorio).
- Debe permitir crear al menos 10 pop-ups.

**Módulo lead driver**
- Campos: imagen mobile y desktop (obligatorio) y un selector de funcionamiento (link o despliegue de formulario).
  - Por link: link del banner (obligatorio).
  - Por formulario: tipo de formulario (obligatorio), título (obligatorio), subtítulo (opcional), texto del CTA (opcional).
- Incluye botón de activo/inactivo. Al activarlo se muestra en la página de inventario.

## Respuestas a las preguntas abiertas

| # | Pregunta | Respuesta |
|---|---|---|
| 1 | ¿Una cuenta puede coordinar más de un grupo o más de una agencia suelta? | **No.** Un dealer fuera de grupo se maneja como acceso independiente de nivel dealer. Una misma cuenta no coordina varios grupos ni varias agencias sueltas |
| 2 | ¿Dos niveles o tres? | **Tres**, resuelto vía la reestructura de la Fase 2 |
| 3 | Orden de banners, ¿por agencia o por sitio? | Se resuelve con los tres niveles. Como referencia: normalmente una agencia tiene un sitio; un grupo puede tener múltiples sitios de agencias y/o un sitio de grupo donde se centraliza la información de las agencias del mismo |
| 4 | ¿El resto del grupo ve y edita el contenido local de una agencia? | **No.** Son individuales de cada dealer |
| 5 | ¿La agencia nueva queda en el grupo del admin que la da de alta? | Sí, pero esa alta ahora solo la realiza Go Virtual |
| 6 | Thank you pages: ¿de dónde sale la lista de formularios? | Sharon compartirá el listado de formularios existentes; quedarán dados de alta por defecto |
| 7 | Lead driver y pop-ups: ¿sesión a detalle? | Sí, se puede agendar. El detalle de arriba es el punto de partida |
| 8 | ¿Qué perfil de Go Virtual da de alta las cuentas? | Un rol de **administrador** |

## Fases sin cambios

- **Fase 0 y Fase 1** — alcance y orden confirmados tal como se plantearon.
- **Fase 4** — sin cambios. Se adjunta la documentación de la API de Duda para dimensionar el acceso: https://developer.duda.co/docs/partner-api-introduction

## Pendientes que genera este documento

1. Listado de formularios de Go Virtual (bloquea la precarga de TYP).
2. Sesión de definición de lead driver y pop-ups.
3. Aclarar el destino de asignación: el nivel marca asigna a **sitios** y el nivel grupo asigna a **dealers**. No son equivalentes cuando un grupo tiene sitio propio además de los de sus agencias.
4. Confirmar a qué se refiere *lead destinations* como patrón de referencia del módulo TYP.
