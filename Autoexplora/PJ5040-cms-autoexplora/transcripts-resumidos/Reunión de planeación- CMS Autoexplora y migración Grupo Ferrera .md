# Condensado — Reunión de planeación: CMS Autoexplora y migración Grupo Ferrera

> Nota de alcance: la reunión cubre DOS temas. Solo el **CMS de Autoexplora** alimenta este PRD.
> El tema "Grupo Ferrera / becarios de soporte / skill de descarga de contenido" es un asunto
> separado (proceso de migración de contenido de marcas) y se registra aquí solo como contexto.

## Decisiones
- Se construirá un **CMS/panel para que el cliente Autoexplora edite su propio contenido** sin pasar por el equipo interno.
- Se maneja **independiente del "panel de cliente" general** (infraestructura aislada, alcance más corto) para no incrementar el alcance ni depender del panel completo. Es un proyecto distinto al "CMS general" (segundo proyecto, más complejo, no comprometido hoy). Eventualmente podría migrarse el panel de Autoexplora al CMS completo — etapa posterior, no comprometida.
- Se generará este **PRD de alcance completo** para dar certeza al cliente de qué incluye.
- La forma de resolverlo (a mano vs. IA/skills, Strapi vs. Contentful vs. reutilizar API de Memo) **queda por definir en una sesión de exploración**; la IA/plugin de PRDs y skills es una **sugerencia**, no una imposición.
- Corresponde a la **Etapa 2** del desarrollo de Autoexplora.

## Alcance / requerimientos
- Contenido a gestionar por el cliente (foco principal):
  - **Banners** de secciones del sitio.
  - **Artículos / contenido de blog**.
  - **Textos estáticos** de secciones promocionales / institucionales.
  - Posible: **teléfonos/datos de agencias** — mencionado como posible "texto", pero **complica** y está por confirmar. Abby estima que principalmente serían banners + blog.
- Objetivo funcional: que el cliente **gestione hasta cierto punto su propio contenido** sin intervención del equipo.
- Persistencia: independientemente de Contentful/Strapi, **hay que almacenar la información** (AWS). Se mencionó base de estructura en **Mongo**.
- Opciones técnicas discutidas (NO decididas):
  - **Contentful** (free tier — content types gratis podrían alcanzar para blog + banners, sin costo).
  - **Strapi** (tiene MCP; podría agilizar desarrollo con Claude Code).
  - **Reutilizar la API de Memo**: colecciones dinámicas por cliente (como las colecciones de modelos) para blogs; banners quizá reutilizables. Valor limitado porque Autoexplora **no es multisitio** ni comparte oferta comercial.
  - Evaluar conectar Contentful directamente a AWS sin pasar por la base de datos.

## Actores
- **Abigail Estrada (Abby)** — solicitante; trabaja los PRDs con el plugin.
- **Alexis Herrera** — líder técnico / revisión técnica; coordina desarrolladores.
- **Sharon** — desarrolladora con experiencia en las implementaciones de la API de Memo; ayudará a determinar endpoints necesarios.
- **Erick** — desarrollador; preguntó por los repos de Memo.
- **Aldo Álvarez** — Director de TI (presente).
- **Juan** — comercial/dirección; hizo la promesa del CMS a Autoexplora.
- **Memo** — desarrollador anterior (ya no está); dejó handover parcial y repos (infra AWS, portal administrativo, API "LAPI"); disponible para dudas puntuales.
- **Directivos de Autoexplora** — cliente / usuarios finales del CMS.
- (Periféricos: Omar, Vic, Toni, Yari; equipo de soporte/becarios — ligados al tema Grupo Ferrera.)

## Riesgos / pendientes
- **Deadline agresivo:** compromiso de entregar la capacidad de editar contenido a **fin de mes (fin de julio 2026)**; factibilidad incierta, requiere sesión de exploración antes de comprometer. Fallback: **primera semana de agosto 2026**.
- **Ausencia de Memo** + documentación incompleta.
- **Bugs existentes en el panel**: cambios recientes de Memo rompieron algo; algunos registros no se guardan. Podría requerir reparación como parte del trabajo.
- **Ambigüedad de alcance**: qué exactamente puede editar el cliente (¿solo banners + blog? ¿textos? ¿teléfonos de agencias?).
- **Decisión técnica no tomada**: Strapi vs. Contentful vs. reutilizar API de Memo; riesgo de curva de aprendizaje.
- **Doble trabajo**: si se hace herramienta aislada ahora, habrá que rehacer/reconfigurar al conectar con el panel general después.
- **Accesos**: el avance del plugin de PRDs quedó local por falta de acceso al repositorio (Alexis dará acceso). El repositorio del sitio se compartirá en la fase de plan de desarrollo.
- **Sitio personalizado**: Autoexplora no sigue la plantilla de otros sitios (Grid, Brick); su contenido hoy está "directo a código" (hardcodeado).

## Fechas / hitos
- **2026-07-14** — reunión de planeación (hoy).
- **Fin de julio 2026** — compromiso de entrega de la capacidad de edición de contenido (mejor escenario).
- **Primera semana de agosto 2026** — fallback si la exploración indica que no es factible en julio.
- Sesión de exploración/profundización agendada para el día siguiente.

## Contexto separado (NO parte de este PRD) — Grupo Ferrera / becarios
- Migración de contenido de Grupo Ferrera: recopilar y cargar contenido para agilizar migración.
- Dos caminos: (A) equipo de soporte (becarios) carga el contenido manualmente; (B) automatizar con un skill de Google/descarga que lee el código, ve los taggeos, descarga contenido e imágenes, las sube a bucket S3 y genera archivo de URLs. Ya hay un motor de descarga base; falta automatizar la **carga** del contenido en el panel.
