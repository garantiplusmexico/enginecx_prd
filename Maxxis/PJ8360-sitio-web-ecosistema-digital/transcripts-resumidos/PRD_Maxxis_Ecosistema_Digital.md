# Condensado — PRD_Maxxis_Ecosistema_Digital.md

> Documento base aportado por el desarrollador: PRD v0.1 (14 de julio de 2026) del proyecto
> "Sitio Web + Ecosistema Digital Maxxis México/LatAm". Sirvió como insumo de ingesta para
> el `PRD.md` de este proyecto.

## Decisiones
- Se construye un sitio web propio para Grupo Maxxis, exclusivo para México y América Latina.
- El sitio sirve a dos audiencias con niveles de acceso distintos: consumidor final (contenido público) y personal de distribuidores (portal restringido).
- El proyecto se planea en dos fases. Fase 1 (MVP de este PRD): sitio informativo, catálogo público, mapa de sucursales, portal de distribuidor con material descargable y formularios de contacto/cotización.
- Fase 2 (fuera del MVP): integración de CRM y plataforma de e-learning formal con seguimiento y evaluaciones.
- El portal de distribuidor NO es un LMS: solo repositorio de material organizado, sin seguimiento de progreso ni evaluaciones.
- El alta de distribuidores es manual/curada por Maxxis; no se automatiza en el MVP.
- Sin e-commerce: el sitio es informativo y dirige al distribuidor físico.
- Esquema de permisos: Go Virtual con permisos de edición y carga de contenido; Maxxis con acceso de solo lectura sobre el contenido publicado.
- Go Virtual ofrece mantenimiento mensual post-lanzamiento.

## Alcance / requerimientos
- RF-01 Sitio informativo público de marca/producto para consumidor final.
- RF-02 Catálogo público navegable de más de 400 artículos, visible a cualquier visitante.
- RF-03 Mapa interactivo de sucursales/distribuidores (México y LatAm) con dirección, coordenadas, horarios, contacto y redes por distribuidor y departamento.
- RF-04 Portal de acceso restringido para distribuidores, aislado del contenido público.
- RF-05 Alta de distribuidor manual/curada por Maxxis (mecanismo de validación pendiente).
- RF-06 Repositorio de material de capacitación (documentos, videos, guías) sin seguimiento ni evaluaciones.
- RF-07 Gestión de contenido: Go Virtual carga y actualiza el contenido que Maxxis provee.
- RF-08 Formularios de cotización y contacto con captura básica de lead (nombre, contacto, mensaje/producto de interés), sin CRM.
- RNF: disponibilidad 24/7 del sitio público; capacidad para alojar ~4TB de material existente; separación de acceso público/restringido; escalabilidad del catálogo (>400 artículos y crecimiento); privacidad de datos de distribuidor pendiente de definir.
- Datos mínimos: distribuidor (nombre y departamento), dirección/ubicación/coordenadas, horarios, teléfono y WhatsApp, redes sociales, correo(s) destino de leads, catálogo de +400 artículos.
- Eventos BI propuestos: `catalogo_articulo_visto`, `mapa_sucursal_consultada`, `distribuidor_material_descargado`, `distribuidor_acceso_otorgado`. Campos mínimos: fecha/hora, id de usuario o sesión, id de recurso, resultado.
- Métricas: cumplimiento de fecha de lanzamiento (binaria), tráfico al sitio (analítica web), leads generados. Líneas base y metas pendientes de validar.

## Actores
- Consumidor final: visita el sitio con fines informativos y de adquisición; usa el mapa para localizar sucursales.
- Distribuidor (personal): accede a la zona restringida para consultar material de producto y capacitación.
- Maxxis (Antonio / equipo de marketing): provee y actualiza el contenido; acceso de solo lectura sobre lo publicado. Antonio es Líder de Mercadotecnia México y LatAm, y lidera la decisión.
- Go Virtual (equipo de proyecto): carga y actualiza contenido, permisos de edición, mantenimiento mensual post-lanzamiento.
- Influyen en la decisión, además de Antonio: importadores y distribuidores.

## Riesgos / pendientes
- Deadline ajustado: el levantamiento formal inicia la misma semana del documento y el lanzamiento es el 30 de septiembre.
- Migración de ~4TB de material existente sin claridad sobre su organización/etiquetado → riesgo de retrabajo.
- Mecanismo de acceso del distribuidor sin definir → puede atrasar el portal restringido.
- Ausencia de CRM definido → gestión manual de leads, riesgo de pérdida de trazabilidad.
- Falta de experiencia previa en plataformas de e-learning (relevante para Fase 2) y disponibilidad no confirmada del material de e-learning.
- Falta de contenido gráfico personalizado: posible dependencia de contenido genérico o de sitios de referencia (Toyo Tires, Maxxis Europe).
- Tiempos administrativos previos (setup doc, propuesta, firma de contrato) consumen ventana de implementación.
- Supuestos: entrega oportuna del material (~4TB) y del setup doc; estabilidad de alcance (sin CRM ni cambios mayores); disponibilidad de contenido de ventas y gráfico.

## Preguntas abiertas heredadas
- Mecanismo definitivo de validación de acceso del distribuidor (propuesta: alta por nombre y correo contra el listado de personal activo del distribuidor).
- Principio rector del MVP: qué decisiones críticas NO debe tomar el sistema.
- Requerimientos de privacidad / normativa regional aplicable a datos de personal de distribuidores.
- Recorrido detallado de consumidor final y distribuidor (entrada, decisiones clave, excepciones de acceso) → el documento base no incluye la sección 7 de Flujos.
- Alcance detallado de los formularios de cotización y contacto (campos, destino del lead sin CRM, seguimiento manual).

## Fechas / hitos
- 14 de julio de 2026: fecha del documento base (v0.1).
- 30 de septiembre: fecha objetivo de salida en vivo del sitio (año no especificado en el documento).
