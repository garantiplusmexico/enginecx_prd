# Plan de Desarrollo — Ecosistema Digital Maxxis México y LatAm

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Maxxis/PJ8360-sitio-web-ecosistema-digital/PRD.md` (v0.3) |
| Repositorio | `aldoalvarez-engine/maxxis-ecosistema-digital` (privado) |
| Rama | `feature/sitio-web-ecosistema-digital-h1-sitio-portal` (H1) · `feature/sitio-web-ecosistema-digital-h2-elearning` (H2) |
| Rama base | `develop` |
| Tipo | Proyecto nuevo |
| Responsable | Aldo Álvarez |
| Folio PRD | PJ8360 |
| Fecha de generación | 14 de agosto de 2026 |
| Estado | Borrador |
| ID plan (BD) | 40 |

---

## 1. Resumen técnico

Desarrollo desde cero de un ecosistema digital compuesto por tres bloques funcionales sobre una
sola aplicación **Next.js (App Router)** desplegada en **Vercel**:

1. **Sitio público** — contenido de marca, catálogo de más de 400 artículos con ficha técnica y
   filtros, mapa interactivo de sucursales de la región, y formularios de contacto/cotización con
   ruteo de leads por correo.
2. **Portal de distribuidor** — zona autenticada con roles, alta manual de usuarios y repositorio
   de material descargable respaldado en S3.
3. **Plataforma de e-learning** — módulo a medida con cursos, lecciones en video, evaluaciones
   calificadas automáticamente, seguimiento de progreso, certificados con folio, rutas de
   aprendizaje por rol y tablero de reportes.

**Arquitectura aplicada:** frontend + backend integrados en un solo proyecto Next.js (route
handlers como capa de API) contra **PostgreSQL**, con **S3 + CDN** para archivos pesados. Según
`rules/arquitectura.md` corresponde al patrón *Frontend + Backend separados (componentes)*: hay
base de datos y lógica de negocio, pero no hay múltiples dominios independientes que justifiquen
microservicios. El e-learning es el dominio más complejo y se aísla como módulo con su propio
esquema de datos, de modo que pueda extraerse a un servicio propio si el volumen lo exigiera.

> **Excepción documentada a `rules/stack.md`.** Las reglas de Engine fijan .NET Core 8 + React
> sobre ECS+Fargate para proyectos nuevos. Este proyecto usa **Next.js sobre Vercel** por decisión
> explícita del Director de TI, siguiendo el precedente de *GAC — Nuevo Sitio Dealers* (PJ1854),
> que es el stack estándar de Go Virtual para sitios web. El resto de las reglas de Engine
> (seguridad, secrets, PostgreSQL, control de versiones, guías de código) aplica sin cambios.

---

## 2. Prerequisitos

- [x] PRD validado por el responsable (v0.3, 14 de agosto de 2026)
- [x] Repositorio creado con estructura de ramas `main` / `develop` / `pre-qa` / `qa`
- [x] `CLAUDE.md` presente en el repositorio
- [ ] Cuenta y proyecto de Vercel asignados al cliente
- [ ] Instancia PostgreSQL aprovisionada (desarrollo y producción)
- [ ] Bucket S3 y distribución CDN creados, con monitoreo de facturación configurado
- [ ] API key del proveedor de mapas, restringida por dominio
- [ ] Cuenta de correo transaccional con dominio verificado (SPF/DKIM)
- [ ] Propiedad de Google Analytics 4 y contenedor GTM
- [ ] Dominio definido y administrado en Cloudflare
- [ ] **Contenido de Maxxis**: fichas técnicas de los 400+ artículos en formato estructurado, datos de sucursales de la región, material de ~4TB organizado, y aviso de privacidad validado por legal
- [ ] **Contenido de cursos** para H2: videos, guiones y reactivos de evaluación

> Los dos últimos prerequisitos **no son desarrollo** y son la dependencia crítica del proyecto.
> Ver §11 y §13.

---

## 3. Arquitectura del cambio

```
                       ┌──────────────────────────────┐
   Consumidor final ──▶│  Sitio público (Next.js SSG/ │
                       │  ISR) — catálogo, mapa,      │
                       │  formularios                 │
                       └───────────┬──────────────────┘
                                   │
   Personal de       ┌─────────────▼──────────────────┐      ┌──────────────┐
   distribuidor ────▶│  Zona autenticada (middleware  │─────▶│ PostgreSQL   │
                     │  de sesión + control de roles) │      │ usuarios,    │
                     │  ├─ Repositorio de material    │      │ catálogo,    │
                     │  └─ E-learning (cursos,        │      │ cursos,      │
                     │     evaluaciones, certificados)│      │ avance,      │
                     └─────────────┬──────────────────┘      │ leads        │
                                   │                         └──────────────┘
                     ┌─────────────▼──────────────────┐
                     │  Route handlers (API v1)       │
                     └──┬──────────┬──────────┬───────┘
                        │          │          │
                  ┌─────▼───┐ ┌────▼─────┐ ┌──▼──────────┐
                  │ S3+CDN  │ │ Correo   │ │ Mapas / GA4 │
                  │ material│ │ transac. │ │             │
                  │ y video │ │ leads    │ │             │
                  └─────────┘ └──────────┘ └─────────────┘
```

**Decisiones de arquitectura:**

- El **catálogo público** se renderiza de forma estática con revalidación incremental: son 400+
  fichas que cambian poco y deben ser indexables (RNF-09) y rápidas (RNF-10).
- La **zona autenticada** se protege en middleware, nunca solo en el cliente, para cumplir RNF-04
  (el contenido restringido no debe ser accesible ni indexable sin sesión).
- Los **archivos pesados nunca pasan por la aplicación**: el material y el video se sirven desde
  S3/CDN mediante URLs firmadas de vigencia corta, lo que preserva el control de acceso sin
  saturar el servidor ni exponer los objetos públicamente.
- El **e-learning usa su propio esquema** dentro de la misma base. Los resultados de evaluación y
  los certificados se escriben solo desde el servidor (RNF-16): ningún rol puede alterarlos desde
  el front.

---

## 4. Tareas de desarrollo

### Fase 0 — Fundación e infraestructura

- [ ] **T-01** — Inicializar el proyecto Next.js (App Router) con TypeScript, linter y formateo
  - Archivos: `package.json`, `tsconfig.json`, `next.config.ts`, `app/layout.tsx`, `eslint.config.mjs`
  - Criterio: `npm run build` y `npm run lint` pasan en limpio

- [ ] **T-02** — Configurar despliegue en Vercel con ambientes de preview y producción
  - Criterio: un push a `develop` genera preview desplegable; variables de entorno cargadas por ambiente

- [ ] **T-03** — Aprovisionar PostgreSQL y configurar el ORM con migraciones versionadas
  - Archivos: `prisma/schema.prisma` (o equivalente), `lib/db.ts`
  - Criterio: migración inicial aplicada y conexión verificada desde la app

- [ ] **T-04** — Configurar acceso a S3 y generación de URLs firmadas
  - Archivos: `lib/storage/s3.ts`
  - Criterio: subida y descarga de un archivo de prueba mediante URL firmada con expiración

- [ ] **T-05** — Definir el sistema de diseño base y el layout responsive
  - Archivos: `app/globals.css`, `components/ui/*`, `components/layout/*`
  - Criterio: header, footer y grid responsive funcionando en móvil, tableta y escritorio (RNF-11)

- [ ] **T-06** — Configurar manejo de errores, logging estructurado y monitoreo
  - Archivos: `app/error.tsx`, `app/not-found.tsx`, `lib/logger.ts`
  - Criterio: los errores de aplicación e integración se registran sin exponer datos personales (RNF-12, RNF-13)

### Fase 1 — Sitio público (H1)

- [ ] **T-07** — Modelar el esquema de catálogo (artículo, familia, medidas, aplicación, imágenes)
  - Criterio: migración aplicada; el modelo soporta más de 400 artículos y su crecimiento (RNF-08)

- [ ] **T-08** — Construir el importador de catálogo desde el archivo estructurado de Maxxis
  - Archivos: `scripts/import-catalog.ts`
  - Criterio: carga idempotente y validada; los registros inválidos se reportan sin abortar el proceso

- [ ] **T-09** — Desarrollar el listado de catálogo con filtros por medida y tipo de vehículo (RF-02, RF-03)
  - Criterio: filtrado y búsqueda funcionando sobre el volumen completo sin degradar la navegación

- [ ] **T-10** — Desarrollar la ficha técnica de artículo con generación estática y revalidación (RF-02)
  - Criterio: cada artículo tiene URL semántica propia, metadatos e imágenes optimizadas

- [ ] **T-11** — Modelar sucursales/distribuidores con soporte multi-país (RNF-14)
  - Criterio: el modelo admite país, coordenadas, horarios, teléfono, WhatsApp, redes y correos de lead

- [ ] **T-12** — Integrar el proveedor de mapas y construir el localizador interactivo (RF-04)
  - Archivos: `components/map/*`, `lib/maps/*`
  - Criterio: búsqueda por ubicación y selección de sucursal; la API key nunca se expone del lado cliente sin restricción de dominio

- [ ] **T-13** — Implementar el listado alterno de sucursales como degradación del mapa (RNF-12)
  - Criterio: si el servicio de mapas no responde, el usuario sigue pudiendo localizar sucursales

- [ ] **T-14** — Construir formularios de contacto y cotización con validación y consentimiento (RF-05, RF-07)
  - Criterio: validación en servidor, protección anti-spam y registro de la aceptación del aviso de privacidad

- [ ] **T-15** — Implementar el ruteo de leads por correo al distribuidor con copia a Maxxis (RF-06)
  - Archivos: `app/api/v1/leads/route.ts`, `lib/mail/*`
  - Criterio: el lead llega al destino correcto según sucursal; ante fallo de envío el lead se persiste y se avisa al usuario (RNF-12)

- [ ] **T-16** — Desarrollar páginas informativas de marca, aviso de privacidad y SEO técnico (RF-01, RNF-09)
  - Criterio: sitemap, robots, metadatos por página y datos estructurados de producto

### Fase 2 — Portal de distribuidor (H1)

- [ ] **T-17** — Modelar usuarios, distribuidores y roles (RF-12)
  - Criterio: un usuario pertenece a un distribuidor y tiene rol de consulta, participante, responsable o administrador

- [ ] **T-18** — Implementar autenticación con sesión, expiración por inactividad y cierre de sesión (RF-11, RNF-05)
  - Archivos: `lib/auth/*`, `middleware.ts`
  - Criterio: sin autoregistro; contraseñas con hash; la sesión expira por inactividad

- [ ] **T-19** — Proteger la zona restringida en middleware y excluirla de indexación (RF-10, RNF-04)
  - Criterio: ninguna ruta ni archivo del portal es accesible sin sesión válida

- [ ] **T-20** — Construir el back office de alta y baja de usuarios con carga del listado de personal (RF-13)
  - Criterio: Go Virtual da de alta cuentas individuales asignando rol por puesto; la baja revoca el acceso de inmediato

- [ ] **T-21** — Implementar recuperación de contraseña por correo registrado (RF-14)
  - Criterio: token de un solo uso con expiración; no revela si el correo existe

- [ ] **T-22** — Modelar y construir el repositorio de material navegable por categoría (RF-15)
  - Criterio: navegación por categoría y descarga mediante URL firmada, solo con sesión válida

- [ ] **T-23** — Construir la herramienta de carga masiva de material a S3 con metadatos
  - Archivos: `scripts/import-media.ts`
  - Criterio: carga reanudable de volúmenes grandes, con registro de lo cargado y lo fallido

- [ ] **T-24** — Registrar la trazabilidad de accesos y descargas (RNF-06)
  - Criterio: cada acceso y descarga queda registrado con usuario, recurso y fecha/hora, consultable por Maxxis

### Fase 3 — Analítica y salida a producción (H1)

- [ ] **T-25** — Instrumentar GA4/GTM con los eventos públicos y de portal (RF-09)
  - Criterio: se emiten `catalogo_articulo_visto`, `mapa_sucursal_consultada`, `lead_capturado`, `distribuidor_acceso_otorgado`, `distribuidor_acceso_denegado` y `distribuidor_material_descargado` con sus campos mínimos

- [ ] **T-26** — Configurar dominio, certificados, CDN y cabeceras de seguridad
  - Criterio: dominio productivo activo en Cloudflare, HTTPS y CORS restrictivo

- [ ] **T-27** — Ejecutar pruebas de desempeño, accesibilidad y responsive (RNF-10, RNF-11)
  - Criterio: tiempos de carga aceptables en móvil en catálogo y ficha; navegación correcta en los tres tamaños

- [ ] **T-28** — Pruebas de aceptación de H1 y salida a producción
  - Criterio: criterios de aceptación de §10 verificados con Maxxis; sitio en vivo

### Fase 4 — E-learning: núcleo de cursos (H2)

- [ ] **T-29** — Modelar cursos, módulos y lecciones (RF-16)
  - Criterio: el modelo soporta orden, tipos de contenido y estado de publicación

- [ ] **T-30** — Construir el back office de autoría de cursos y módulos (RF-25)
  - Criterio: Go Virtual crea, edita, ordena y publica cursos sin tocar código

- [ ] **T-31** — Implementar la carga de lecciones y sus recursos a S3 desde el back office (RF-25)
  - Criterio: video y documentos asociados a la lección, servidos por URL firmada

- [ ] **T-32** — Desarrollar el reproductor de lecciones con registro de avance (RF-17)
  - Criterio: reproducción progresiva sin descarga previa del archivo completo (RNF-15); la lección se marca como completada

- [ ] **T-33** — Construir la vista de curso y navegación entre módulos y lecciones (RF-16)
  - Criterio: el usuario ve su posición dentro del curso y puede retomar donde se quedó

- [ ] **T-34** — Modelar e implementar el seguimiento de progreso por usuario y curso (RF-21)
  - Criterio: lecciones completadas, porcentaje de avance y estado del curso, visibles para el usuario

- [ ] **T-35** — Desarrollar el catálogo de cursos del usuario con sus pendientes (RF-21)
  - Criterio: el usuario ve sus cursos asignados, en progreso y aprobados

- [ ] **T-36** — Instrumentar los eventos de capacitación `curso_iniciado` y `leccion_completada` (RF-26)
  - Criterio: eventos emitidos con distribuidor, país y rol del usuario

### Fase 5 — E-learning: evaluación y acreditación (H2)

- [ ] **T-37** — Modelar el banco de preguntas y las evaluaciones (RF-18)
  - Criterio: soporta varios tipos de reactivo y asociación a curso o módulo

- [ ] **T-38** — Construir el editor de evaluaciones en el back office (RF-18, RF-25)
  - Criterio: Go Virtual arma evaluaciones, define puntaje mínimo e intentos permitidos

- [ ] **T-39** — Desarrollar la presentación de evaluación con calificación automática en servidor (RF-19)
  - Criterio: las respuestas correctas nunca viajan al cliente antes de calificar; el resultado se registra por intento

- [ ] **T-40** — Implementar la política de reintentos y el bloqueo al agotarlos (RF-20)
  - Criterio: se respeta el número de intentos configurado y el comportamiento definido al agotarse

- [ ] **T-41** — Implementar la emisión de certificados con folio verificable (RF-22, RNF-16)
  - Criterio: constancia descargable a nombre de la persona, con folio consultable; inalterable desde el front

- [ ] **T-42** — Instrumentar `evaluacion_presentada`, `curso_completado` y `certificado_emitido` (RF-26)
  - Criterio: eventos emitidos con calificación, número de intento y resultado

### Fase 6 — E-learning: rutas por rol, reportes y cierre (H2)

- [ ] **T-43** — Modelar e implementar rutas de aprendizaje por rol (RF-23)
  - Criterio: al asignar el rol de un usuario se le asignan automáticamente sus cursos obligatorios y opcionales

- [ ] **T-44** — Construir la administración de rutas y su asignación en el back office (RF-23, RF-25)
  - Criterio: se define qué cursos corresponden a cada puesto sin intervención de desarrollo

- [ ] **T-45** — Desarrollar el tablero de reportes de capacitación para Maxxis (RF-24)
  - Criterio: avance por distribuidor, curso y persona, con exportación (RNF-18)

- [ ] **T-46** — Implementar la vista de avance del equipo para el responsable de distribuidor (RF-12)
  - Criterio: el responsable ve solo a su propio distribuidor, nunca a otros

- [ ] **T-47** — Implementar la retención del historial de capacitación de usuarios dados de baja (RNF-17)
  - Criterio: avance, calificaciones y certificados se conservan tras la baja del usuario

- [ ] **T-48** — Pruebas de aceptación de H2 y liberación
  - Criterio: criterios de aceptación de §10 verificados con Maxxis; e-learning en vivo

---

## 5. Cambios en base de datos

Esquema nuevo completo. Entidades principales:

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `countries` | Nueva | Países de la región atendidos |
| `distributors` | Nueva | Distribuidores y sus datos comerciales |
| `branches` | Nueva | Sucursales: dirección, coordenadas, horarios, contacto, correos de lead |
| `products` | Nueva | Catálogo: identificador, familia, medidas, aplicación, especificaciones |
| `product_images` | Nueva | Imágenes por artículo |
| `leads` | Nueva | Leads capturados, destino, país y constancia de consentimiento |
| `users` | Nueva | Personal de distribuidor: correo, distribuidor, puesto, estado |
| `roles` / `user_roles` | Nueva | Roles: consulta, participante, responsable, administrador |
| `sessions` | Nueva | Sesiones activas y expiración |
| `password_resets` | Nueva | Tokens de recuperación de un solo uso |
| `media_assets` | Nueva | Material del repositorio: título, tipo, categoría, referencia en S3 |
| `access_logs` | Nueva | Trazabilidad de accesos y descargas |
| `courses` | Nueva | Cursos: nombre, tema, estado de publicación |
| `course_modules` | Nueva | Módulos dentro del curso, con orden |
| `lessons` | Nueva | Lecciones: tipo de contenido, recurso en S3, orden |
| `questions` / `question_options` | Nueva | Banco de preguntas y opciones de respuesta |
| `assessments` | Nueva | Evaluaciones: curso/módulo, puntaje mínimo, intentos permitidos |
| `assessment_attempts` | Nueva | Intentos por usuario, con calificación y fecha |
| `enrollments` | Nueva | Inscripción de usuario a curso y su estado |
| `lesson_progress` | Nueva | Avance por lección y usuario |
| `certificates` | Nueva | Folio, usuario, curso, fecha de emisión y vigencia |
| `learning_paths` / `path_courses` | Nueva | Rutas de aprendizaje por rol y sus cursos |

Índices requeridos: búsqueda de catálogo por medida y aplicación; sucursales por país y
coordenadas; avance por usuario y curso; certificados por folio.

---

## 6. Endpoints nuevos

Route handlers de Next.js bajo `app/api/v1/`, versionados y con sustantivos en plural conforme a
`coding-guidelines.md` §5.

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `v1/products` | Listado y filtrado de catálogo | Nuevo |
| GET | `v1/products/{id}` | Ficha técnica de artículo | Nuevo |
| GET | `v1/branches` | Sucursales por país o proximidad | Nuevo |
| POST | `v1/leads` | Captura y ruteo de lead | Nuevo |
| POST | `v1/auth/sessions` | Inicio de sesión | Nuevo |
| DELETE | `v1/auth/sessions` | Cierre de sesión | Nuevo |
| POST | `v1/auth/password-resets` | Solicitud de recuperación | Nuevo |
| PUT | `v1/auth/password-resets/{token}` | Restablecimiento de contraseña | Nuevo |
| GET | `v1/media-assets` | Material del repositorio por categoría | Nuevo |
| GET | `v1/media-assets/{id}/download-url` | URL firmada de descarga | Nuevo |
| GET | `v1/courses` | Cursos asignados al usuario | Nuevo |
| GET | `v1/courses/{id}` | Detalle del curso con módulos y lecciones | Nuevo |
| POST | `v1/lessons/{id}/progress` | Registro de lección completada | Nuevo |
| POST | `v1/assessments/{id}/attempts` | Presentación y calificación de evaluación | Nuevo |
| GET | `v1/certificates` | Certificados del usuario | Nuevo |
| GET | `v1/certificates/{folio}` | Verificación pública de certificado por folio | Nuevo |
| GET | `v1/reports/training` | Tablero de avance de capacitación | Nuevo |
| POST | `v1/admin/users` | Alta de usuario de distribuidor | Nuevo |
| DELETE | `v1/admin/users/{id}` | Baja de usuario | Nuevo |

Códigos de estado conforme a `coding-guidelines.md` §5: 200/201/204 en éxito, 400 validación,
401 sin sesión, 403 sin permiso, 404 no encontrado, 409 conflicto, 429 rate limit, 500 error interno.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `DATABASE_URL` | Cadena de conexión a PostgreSQL | Desarrollo / QA / Producción |
| `AUTH_SECRET` | Secreto de firma de sesión | Desarrollo / QA / Producción |
| `AWS_REGION`, `AWS_S3_BUCKET` | Bucket de material y video | Desarrollo / QA / Producción |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | Credenciales IAM de mínimo privilegio sobre el bucket | Desarrollo / QA / Producción |
| `CDN_BASE_URL` | Dominio de distribución CDN | QA / Producción |
| `MAPS_API_KEY` | Proveedor de mapas, restringida por dominio | Desarrollo / QA / Producción |
| `MAIL_API_KEY`, `MAIL_FROM_ADDRESS` | Servicio de correo transaccional | Desarrollo / QA / Producción |
| `MAIL_MARKETING_BCC` | Copia de leads al equipo de Maxxis | Producción |
| `NEXT_PUBLIC_GA4_ID`, `NEXT_PUBLIC_GTM_ID` | Analítica — públicos por diseño | Desarrollo / QA / Producción |
| `NEXT_PUBLIC_SITE_URL` | URL canónica para SEO y sitemap | Desarrollo / QA / Producción |

> **Ningún secreto lleva prefijo `NEXT_PUBLIC_`.** Solo los identificadores de analítica y la URL
> del sitio son públicos por diseño. Las credenciales viven en variables de entorno de Vercel o en
> AWS Secrets Manager, nunca en el repositorio (`rules/infraestructura.md` §5).

---

## 8. Consideraciones de seguridad

- **IAM de mínimo privilegio:** la credencial de la aplicación solo puede leer y escribir en el
  prefijo correspondiente del bucket, nunca administrar la cuenta.
- **Objetos privados en S3:** el material y el video nunca son públicos. Todo acceso ocurre por URL
  firmada de vigencia corta, generada en servidor tras validar la sesión y el rol.
- **API key de mapas restringida por dominio.** Sin restricción, una key expuesta puede generar
  facturación masiva sin tope (`rules/infraestructura.md` §5).
- **Datos personales:** el portal maneja nombre y correo de personal de distribuidores, y los
  formularios capturan datos de consumidores. Aplica la LFPDPPP (México): aviso de privacidad,
  consentimiento explícito y atención de derechos ARCO. La normativa del resto de la región sigue
  sin definir (PRD §14) y debe resolverse antes de publicar el sitio en esos países.
- **Logging sin datos sensibles:** nunca se registran contraseñas, tokens ni datos personales
  (`coding-guidelines.md` §9).
- **Calificación solo en servidor:** las respuestas correctas de una evaluación nunca se envían al
  cliente antes de calificar. Resultados y certificados son inescribibles desde el front (RNF-16).
- **Rate limiting** en autenticación, recuperación de contraseña y envío de formularios, para
  contener abuso y spam.
- **Consultas parametrizadas** y validación de toda entrada de usuario en servidor.
- **CORS restrictivo** en producción.

---

## 9. Consideraciones de infraestructura

- **Vercel:** proyecto con ambientes de preview y producción. El costo escala con tráfico y
  funciones; conviene revisar el plan antes de la salida.
- **S3 + CDN:** ~4TB iniciales más el video de cursos. El costo de almacenamiento es predecible,
  pero **la transferencia de salida no lo es**: el video del e-learning es el componente de costo
  variable más relevante del proyecto. Configurar monitoreo de facturación desde el día uno — AWS
  no corta servicios al alcanzar un límite, solo notifica si está configurado.
- **PostgreSQL:** instancia gestionada con respaldos automáticos. El volumen esperado es moderado;
  la tabla de mayor crecimiento será `lesson_progress`.
- **Proveedor de mapas:** costo por volumen de consultas. Definir cuota y alerta.
- **Cloudflare:** administración del dominio, conforme al estándar de Engine.

---

## 10. Criterios de aceptación

**H1 — Sitio y portal**

- [ ] El catálogo muestra los más de 400 artículos con ficha técnica completa, filtrables por medida y tipo de vehículo
- [ ] Las fichas de producto son indexables, tienen URL semántica y metadatos propios
- [ ] El mapa localiza sucursales de la región y degrada a listado si el servicio falla
- [ ] Un lead enviado llega al correo del distribuidor destino con copia a Maxxis, y no se pierde si el envío falla
- [ ] Ningún contenido del portal es accesible ni indexable sin sesión válida
- [ ] Un usuario dado de alta puede entrar, recuperar su contraseña y descargar material; uno dado de baja no
- [ ] Cada acceso y descarga queda registrado con usuario, recurso y fecha/hora
- [ ] Los seis eventos de H1 se emiten con sus campos mínimos
- [ ] El sitio funciona correctamente en móvil, tableta y escritorio
- [ ] El aviso de privacidad está publicado y todo formulario captura consentimiento explícito

**H2 — E-learning**

- [ ] Go Virtual puede crear, editar y publicar un curso completo con lecciones y evaluación sin tocar código
- [ ] El usuario ve solo los cursos que corresponden a su rol, y puede retomar donde se quedó
- [ ] El video reproduce de forma progresiva, sin requerir descarga previa del archivo completo
- [ ] La evaluación califica en servidor contra el puntaje mínimo y respeta los intentos configurados
- [ ] Las respuestas correctas no son obtenibles desde el cliente antes de calificar
- [ ] Al aprobar se emite un certificado con folio verificable, no alterable desde el front
- [ ] El tablero muestra el avance por distribuidor, curso y persona, y permite exportarlo
- [ ] El responsable de un distribuidor ve solo a su equipo
- [ ] El historial de capacitación se conserva tras la baja del usuario
- [ ] Los cinco eventos de capacitación se emiten correctamente

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| El alcance de H1 no cabe en los 32 días hábiles disponibles con un solo desarrollador | Alta | Alto | Sumar un segundo desarrollador en paralelo desde la Fase 1, o recortar alcance de H1. Ver §13 |
| Maxxis no entrega las fichas técnicas estructuradas a tiempo o llegan incompletas | Alta | Alto | Definir el formato de intercambio en la primera semana y construir el importador (T-08) contra ese formato. Sin dato estructurado, la captura es manual y no es trabajo de desarrollo |
| La migración de ~4TB tarda más de lo previsto o el material llega desorganizado | Alta | Alto | Construir la carga reanudable y con reporte (T-23) antes de recibir el volumen completo; acordar la taxonomía de categorías antes de mover archivos |
| No existe contenido de cursos al liberar H2 | Alta | Alto | Confirmar con Maxxis la disponibilidad de video, guiones y reactivos antes de arrancar la Fase 4. La plataforma sin cursos no entrega valor |
| Subestimación del e-learning por falta de experiencia previa en LMS | Alta | Alto | El rango de H2 en §13 es amplio a propósito. Cerrar antes las decisiones de política de reintentos y vigencia de certificados (PRD §14), que cambian el modelo de datos |
| Costo variable no acotado de video y mapas | Media | Alto | Monitoreo de facturación y cuotas desde T-02/T-04; evaluar servicio especializado de video si el egreso de CDN se dispara |
| La vigencia de certificados se define después de construir el módulo | Media | Alto | Resolverlo antes de T-41. Manejar caducidad y recertificación agrega complejidad que no se absorbe bien a posteriori |
| Datos de sucursales de LatAm incompletos al momento de publicar el mapa | Media | Medio | El modelo admite publicación parcial por país (T-11); se publica lo validado y se agrega el resto sin cambios de código |
| Desempeño del catálogo con 400+ fichas e imágenes pesadas | Media | Medio | Generación estática con revalidación (T-10) y optimización de imágenes; validar en T-27 |
| Normativa de privacidad no resuelta fuera de México | Media | Medio | Escalar a legal antes de publicar el sitio en países distintos a México |

---

## 12. Notas para el programador

1. **La estimación de §13 es de desarrollo, no de contenido.** La captura de 400+ fichas técnicas y
   la organización de los ~4TB de material son trabajo del cliente y del equipo de contenido, y
   ocurren en paralelo. Si esas tareas recaen sobre el desarrollador, los rangos dejan de aplicar.

2. **Antes de arrancar la Fase 4, cerrar dos decisiones del PRD §14:** política de reintentos y
   vigencia de los certificados. Ambas afectan el modelo de datos del e-learning y son caras de
   introducir después.

3. **`coding-guidelines.md` está redactado para .NET.** En este proyecto aplican sus principios
   transversales: código y comentarios en inglés, un artefacto público por archivo, archivos
   acotados, API versionada `v1/` con sustantivos en plural y kebab-case, códigos de estado
   estándar, `async/await` en toda operación de I/O, secrets fuera del código, consultas
   parametrizadas y validación de entrada. Las convenciones específicas de C# (PascalCase en
   métodos, prefijo `I` en interfaces, llaves estilo Allman) se sustituyen por las idiomáticas de
   TypeScript/React.

4. **El orden de las fases no es negociable en su dependencia:** la Fase 2 (autenticación y roles)
   es prerequisito de todo el e-learning, porque las rutas de aprendizaje se asignan por rol.

5. **Las tareas de contenido tienen lead time propio.** T-08 y T-23 dependen de entregas del
   cliente; conviene arrancarlas apenas llegue el primer lote en lugar de esperar el total.

---

## 13. Relación de tareas y tiempos

Estimación en **días hábiles** para **un (1) desarrollador**.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Fundación e infraestructura** | Proyecto Next.js, Vercel, PostgreSQL, S3, sistema de diseño, manejo de errores | T-01 a T-06 | 4 – 6 días | 108 |
| **Fase 1 — Sitio público (H1)** | Catálogo con ficha técnica y filtros, importador, mapa regional, formularios, ruteo de leads, SEO | T-07 a T-16 | 12 – 16 días | 109 |
| **Fase 2 — Portal de distribuidor (H1)** | Usuarios y roles, autenticación, alta/baja, repositorio de material, carga masiva, trazabilidad | T-17 a T-24 | 10 – 14 días | 110 |
| **Fase 3 — Analítica y salida a producción (H1)** | Instrumentación GA4/GTM, dominio y seguridad, pruebas de desempeño, aceptación y salida | T-25 a T-28 | 3 – 5 días | 111 |
| **Fase 4 — E-learning: núcleo de cursos (H2)** | Modelo de cursos, back office de autoría, carga de lecciones, reproductor, progreso | T-29 a T-36 | 15 – 20 días | 112 |
| **Fase 5 — E-learning: evaluación y acreditación (H2)** | Banco de preguntas, editor de evaluaciones, calificación, reintentos, certificados | T-37 a T-42 | 10 – 14 días | 113 |
| **Fase 6 — E-learning: rutas, reportes y cierre (H2)** | Rutas por rol, administración de rutas, tablero de reportes, retención, aceptación | T-43 a T-48 | 8 – 11 días | 114 |
| **Total proyecto (H1 + H2)** | | 48 tareas | **~62 – 86 días hábiles (≈ 12.5 – 17 semanas)** | — |
| **Solo H1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 + Fase 3 | T-01 a T-28 | **~29 – 41 días hábiles (≈ 6 – 8 semanas)** | — |
| **Solo H2 (e-learning)** | Fase 4 + Fase 5 + Fase 6 | T-29 a T-48 | **~33 – 45 días hábiles (≈ 7 – 9 semanas)** | — |

> **Riesgo de deadline.** Del lunes 17 de agosto al miércoles 30 de septiembre de 2026 hay
> **32 días hábiles** (descontando el 16 de septiembre). H1 requiere **29 a 41 días hábiles con un
> solo desarrollador**: solo cabe en el escenario más optimista, y sin margen para imprevistos,
> retrabajo ni retrasos en la entrega de contenido por parte del cliente. Considerando que el
> proyecto aún requiere firma de contrato y levantamiento formal, **la fecha del 30 de septiembre
> no es alcanzable de forma realista con un recurso.**
>
> Recomendaciones, en orden de preferencia:
>
> 1. **Sumar un segundo desarrollador desde la Fase 1.** Las Fases 1 y 2 son paralelizables casi por
>    completo (sitio público y portal comparten poca superficie: solo el sistema de diseño y el
>    esquema base). Dos recursos comprimirían H1 a aproximadamente **18 – 25 días hábiles**, lo que
>    sí cabe en la ventana con margen razonable.
> 2. **Recortar alcance de H1.** El candidato natural es la ficha técnica completa de los 400+
>    artículos: salir con ficha básica y completar el detalle después reduce la Fase 1 en unos
>    3 – 5 días y elimina la dependencia más pesada de contenido del cliente.
> 3. **Renegociar la fecha.** Si ni el recurso adicional ni el recorte son viables, el 30 de
>    septiembre debe replantearse con Maxxis antes de firmar, no después.
>
> **H2 no tiene fecha comprometida** y se calendariza a partir de la liberación de H1. Con un
> desarrollador, el e-learning terminaría aproximadamente **7 a 9 semanas después** de la salida de
> H1; con dos recursos, alrededor de **4 a 6 semanas**. La paralelización de H2 rinde menos que la
> de H1 porque las Fases 5 y 6 dependen fuertemente del modelo construido en la Fase 4.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
