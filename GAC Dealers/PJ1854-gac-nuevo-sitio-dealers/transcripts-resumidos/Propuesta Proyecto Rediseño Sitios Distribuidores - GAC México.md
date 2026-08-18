# Condensado — Propuesta Proyecto Rediseño Sitios Distribuidores - GAC México

> Documento comercial (acuerdo de trabajo GAC México ↔ Go Virtual, apoderado Juan Berner).
> Es la base de alcance del proyecto. Nota: usa lenguaje comercial (menciona plataforma
> "GRID", WordPress, hosting propio); la decisión técnica real acordada con el equipo es
> **construir sobre el mismo stack del sitio de marca (Next.js) y deployar en Vercel**,
> parametrizado por base de datos. Reconciliar términos comerciales vs. técnicos (ver PRD §14).

## Decisiones
- Solución integral de sitios web **responsivos, estandarizados y enfocados a conversión/leads** para la red de distribuidores GAC México.
- **Diseño semi-personalizado**: identidad visual adaptada por dealer según sus lineamientos.
- **Hosting**: lo gestiona Go Virtual; **el dominio lo proporciona el cliente (dealer)**.
- Incluye **CMS** para que el distribuidor actualice su información (contenido de marca/OEM + contenido local).
- Métricas: **Google Analytics 4**, reportes en **Looker Studio** (personalizables por dealer), estándares del **Automotive Standards Council**.

## Alcance / requerimientos
- **Rediseño (plantilla):** Diseño home, prototipo home, **prototipo de 5 páginas internas**, desarrollo con animaciones/transiciones. (93 h.)
- **Implementación por dealer (réplica):** personalización de datos (horarios, dirección, teléfono, etc.) + revisión de calidad. **6 h por distribuidor.**
- Funcionalidades técnicas: responsivo, geolocalización, **SEO**, **blog** (la propuesta menciona WordPress; conciliar con el enfoque de contenido en BD), seguridad/privacidad de datos.
- **Integraciones con terceros:** **DMS** (gestión de inventario) y **CRM** (leads).
- Contenido: **de marca (OEM)** centralizado + **local** por dealer (promos y eventos locales).

## Actores
- **GAC México** (cliente / marca), **Go Virtual** (proveedor: diseño, desarrollo, hosting, réplica), **distribuidores** (proveen dominio, gestionan su contenido local vía CMS).

## Riesgos / pendientes
- **CMS**: comprometido comercialmente en la propuesta, pero el equipo lo definió **fuera de alcance de este PRD** (irá en PRD propio). Reconciliar.
- Reconciliar **términos comerciales** (GRID, WordPress, hosting) con la **arquitectura técnica real** (Next.js sobre el stack de marca + Vercel + BD).
- Alcance de páginas: la propuesta habla de **5 páginas internas**; falta confirmar con la marca cuáles y cómo se relacionan con las páginas "básicas" (modelos, promociones, contacto, ubicación, cotización, prueba de manejo).

## Fechas / hitos
- **Onboarding en 6 etapas:** 1) Iniciación y preparación interna, 2) Gobernanza del proyecto, 3) Validación de información y estrategia, 4) Configuración del sitio web, 5) Pruebas y control de calidad, 6) Entrega y lanzamiento (incluye garantía, estabilización y capacitación de mantenimiento).

## Inversión (referencia, no es parte funcional del PRD)
- Rediseño/plantilla: **93 h / $46,500 MXN**. Implementación por dealer: **6 h / $3,000 MXN** (por cada distribuidor). Costo/hora: $500 MXN.
