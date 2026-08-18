# Condensado — PRD_GAC.md

> Documento de **referencia técnica**, no de alcance. Es el PRD de otro proyecto de Go Virtual
> (GAC — Nuevo Sitio Dealers, v0.1 del 4 de agosto de 2026). El desarrollador lo aportó para
> fijar el stack tecnológico estándar del equipo, que se adoptó en los RNF e integraciones del
> PRD de Maxxis. Su alcance funcional NO aplica a Maxxis.

## Decisiones
- El stack estándar de Go Virtual para sitios web es **Next.js (App Router) con despliegue en Vercel**.
- Almacenamiento y procesamiento de archivos en **Amazon S3**.
- Analítica sobre **Google Analytics 4 + GTM**, con reportes en **Looker Studio**.
- Geolocalización y mapas con **Google Maps**.
- Los leads se entregan por **correo (texto o ADF/XML)** al destino configurado del cliente; las integraciones a CRM se manejan como caso aparte y, cuando existen, van por Seekop/Sale-U o mailhook→Make.
- El CMS de autogestión se maneja como **PRD independiente** (Strapi como herramienta candidata); mientras no existe, Go Virtual administra el contenido de forma centralizada.
- Los sitios se publican **solo en español MX**; multi-idioma queda fuera de alcance.
- Principio de arquitectura: plantilla única parametrizada, **cero información hardcodeada**; la variación por cliente es de datos y contenido, no de diseño.

## Alcance / requerimientos
*(Del proyecto GAC, no de Maxxis — se resume solo como contexto del estilo y nivel de detalle que Go Virtual maneja en sus PRDs.)*
- Rediseño de una plantilla replicable de micrositios de distribuidores, homologada con la marca y orientada a conversión.
- Parametrización por `dealer_id`; réplica estimada en ~6 h por distribuidor sobre 19 sitios objetivo.
- Componentes de conversión: inventario condicional, promociones de marca y locales, CTAs (agendar servicio, visitar agencia, cotizar, prueba de manejo, WhatsApp, llamar).
- Instrumentación de eventos bajo el estándar **ASC (Automotive Standards Council)** sobre GA4/GTM, atribuidos por `dealer_id`.
- SEO técnico, Core Web Vitals, responsive y aviso de privacidad como requerimientos no funcionales base.
- Regla de seguridad explícita: los secretos nunca se exponen con prefijo `NEXT_PUBLIC_`.

## Actores
- Go Virtual — Sitios Web: desarrolla, administra contenido central, ejecuta réplicas y deploys.
- Cliente/marca: define lineamientos de identidad, valida el diseño y provee contenido.
- Distribuidor/dealer: aporta dominio, inventario y correos destino; recibe sus leads.

## Riesgos / pendientes
- Riesgo recurrente en los proyectos de Go Virtual: **desalineación entre los términos comerciales** que se comunican al cliente (hosting, WordPress, GRID, CMS) **y la solución técnica real** (Next.js, Vercel, base de datos). Aplicable como advertencia al proyecto Maxxis.
- Dependencia de insumos del cliente (datos, correos destino, contenido) como causa principal de retrasos en la activación.
- Definiciones técnicas pendientes (blog, CMS) que generan reproceso si se difieren demasiado.

## Fechas / hitos
- 4 de agosto de 2026: fecha del documento de referencia.
- Sin hitos aplicables al proyecto Maxxis.
