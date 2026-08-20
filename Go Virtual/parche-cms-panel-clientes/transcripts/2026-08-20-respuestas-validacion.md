# Validación y respuestas del equipo Go Virtual

| Campo | Detalle |
|---|---|
| Fecha | 2026-08-20 |
| Autor | Sharon Mendoza (Go Virtual), tras revisión con su equipo |
| Responde a | Documento de plan por fases enviado el 2026-08-19 |
| Fuente | `respuestas.docx` |

---
Tras revisar el documento con el equipo, te comparto nuestras conclusiones fase por fase y las respuestas a las preguntas que dejaste abiertas.

Fase 0 y Fase 1: sin cambios. Confirmamos el alcance y el orden tal como los planteaste.

————————————————————————

Fase 2 — Banners y promociones (con modificación)

Necesitaremos una lógica distinta a la que vimos ayer: dividir los módulos en tres niveles en lugar de dos. Esto, de paso, responde tu pregunta sobre si eran dos niveles o tres —son tres—:

• OEM marca — administrado únicamente por GV.
• OEM grupo — administrado por GV y el admin de un grupo de dealers.
• Dealer — administrado por GV y el admin de un dealer.

Reglas de herencia entre niveles:

• Dealer (el más bajo): no puede ocultar, eliminar ni reordenar los elementos heredados desde el grupo o la marca; solo puede asignar elementos a su agencia.
• Grupo: no puede ocultar, eliminar ni reordenar lo heredado desde marca, pero sí puede asignar elementos al conjunto de dealers de su grupo.
• Marca: asigna elementos a cualquier sitio que pertenezca a la marca.

El orden de aparición seguirá esta prioridad: marca → grupo → dealer.

————————————————————————

Fase 3 — Módulos nuevos (ampliamos el contexto)

Estos módulos estarían disponibles a nivel grupo y dealer, siguiendo la misma lógica de la Fase 2: el nivel grupo puede asignar elementos a todos los dealers de su grupo (para lo que es igual en todos los sitios pertenecientes a su grupo) y el nivel dealer queda para las especificidades de cada uno.

Módulo TYP (página de agradecimiento)
• Replicaremos la forma en que se construyó &quot;lead destinations&quot;, para tener siempre presentes las páginas de agradecimiento de los formularios existentes que provee GV. Por defecto quedarán dadas de alta con información base, modificable a demanda.
• Campos: título (obligatorio), subtítulo (obligatorio), slug (obligatorio) y apartado de CTAs (opcional, hasta 3 botones; cada botón con su texto y su link).

Módulo pop-up
• Campos: título (obligatorio), imagen mobile y desktop (obligatorio), link (obligatorio), vigencia (opcional) y página donde se mostrará (obligatorio).
• Debe permitir crear al menos 10 pop-ups.

Módulo lead driver
• Campos: imagen mobile y desktop (obligatorio) y un selector para determinar su funcionamiento (link o despliegue de formulario).
   – Funcionamiento por link: link del banner (obligatorio).
   – Funcionamiento por formulario: selector de tipo de formulario (obligatorio), título (obligatorio), subtítulo (opcional) y texto del CTA (opcional).
• Debe incluir un botón de activo/inactivo.
Al activarlo, se muestra en la página de inventario.

————————————————————————

Fase 4 — Acceso a Duda: sin cambios. Te adjunto la documentación de la API de Duda por si ayuda a dimensionar este acceso: https://developer.duda.co/docs/partner-api-introduction

————————————————————————

Cambio adicional en permisos de roles

El alta de grupos y dealers quedará únicamente bajo GV; el cliente no tendrá ese acceso. Es un ajuste respecto a lo que quedaba como confirmado en tu documento, así que lo señalamos de forma explícita.

————————————————————————

Respuestas a tus preguntas

Bloqueante — ¿Una cuenta puede coordinar más de un grupo o más de una agencia suelta?
No. En todo caso quedaría fuera del grupo, así que se maneja como un acceso independiente de nivel dealer (o de otro grupo, si aplicara). Una misma cuenta no coordina varios grupos ni varias agencias sueltas.

3. Orden de los banners, ¿por agencia o por sitio?
Se resuelve con los tres niveles: GV define el orden de los de marca, GV o el admin de grupo define el de nivel grupo, y el dealer solo manipula los suyos. Como referencia, normalmente una agencia tiene un sitio; un grupo puede tener múltiples sitios de agencias y/o un sitio de grupo, donde se centraliza la información de las agencias pertenecientes al mismo.

4. ¿El resto del grupo ve y edita los banners/promociones locales de una agencia?
No, son individuales de cada dealer. Aplica la misma lógica de niveles.

5. ¿La agencia nueva queda dentro del grupo del admin que la da de alta?
Sí. La diferencia es que esa alta ahora solo la realiza el equipo de GV; el cliente no tiene ese acceso.

6. Thank you pages: ¿de dónde sale la lista de formularios?
Te compartiré el listado de formularios existentes, ya que quedarán dados de alta por defecto (como se describe en el módulo TYP).

7. Lead driver y popups: ¿agendamos una sesión para verlos a detalle?
Sí, podemos agendarla para profundizar. Arriba va ya bastante detalle de ambos módulos como punto de partida.

8. ¿Qué perfil de GV da de alta las cuentas de acceso?
Correcto: un rol de administrador.

————————————————————————

Con esto, el alcance y el orden de las fases quedan validados de nuestro lado, salvo los ajustes anteriores.  