# Plan de Desarrollo — GAC Nuevo Sitio Dealers

| Campo | Detalle |
|---|---|
| PRD de origen | `GAC Dealers/PJ1854-gac-nuevo-sitio-dealers/PRD.md` (v0.1) |
| Folio PRD | PJ1854 |
| Área / empresa | Go Virtual |
| Responsable | Aldo Álvarez (a confirmar) |
| Fecha de generación | 2026-08-05 |
| Estado | Borrador |
| Alcance de este plan | Fase 1 (MVP) desglosada completa. Fase 2 (multi-tenant, Vercel) desglosada. Fase 3 (blog) solo referenciada. |

> Generado a partir del PRD y de las correcciones dadas en conversación. No se inspeccionó el repo real (`GAC-Next-Stack`) — es privado y este entorno no tiene `gh`/credenciales configuradas — así que las tareas sobre el UI kit y los endpoints se validan en la práctica al ejecutarlas.
>
> **Tiempos:** estimación preliminar en días hábiles, a nivel de tarea/desarrollador único. Son un punto de partida para que el equipo de desarrollo los valide y ajuste — no están comprometidos con el cliente todavía.

---

## 1. Resumen técnico

Se **rediseña una plantilla Next.js/Vercel ya existente**, no se construye desde cero. Ya existe un **UI kit** (`src/modules/ui-design`, dentro del mismo repo `GAC-Next-Stack` del sitio de marca) con tipografías, colores y componentes casi listos, pero con **props hardcodeadas** de un proyecto único — la Fase 1 los adapta para reutilización multi-dealer. La **estructura de páginas es fija e idéntica** entre marca y dealers (11 internas + 9 de modelo/MRP); lo único que cambia por dealer es el **contenido**, resuelto en runtime contra endpoints reales ya existentes. **No habrá módulo de inventario** en ningún sitio. Fase 2 construye un **sitio único multi-tenant** desplegado en **Vercel**, que resuelve el dealer por dominio y mantiene la configuración estructural en variables de entorno y el contenido variable en base de datos. El blog se mueve a una **Fase 3** aparte por su potencial de exceder el scope actual.

## 2. Prerequisitos

- [ ] Acceso al repo `GAC-Next-Stack` (incluye el UI kit en `src/modules/ui-design`).
- [ ] Acceso/credenciales a los endpoints de contenido (ver §4 Integraciones conocidas).
- [x] **Resuelto** — páginas: 11 internas + 9 de modelo (MRP), estructura fija e igual para marca y dealer; contenido por dealer desde BD.
- [x] **Resuelto** — no hay módulo de inventario; se retira de todo el alcance (Fase 1 y Fase 2).
- [x] **Resuelto** — infraestructura de Fase 2: **Vercel**.
- [ ] Lineamientos de identidad de marca (parcialmente cubiertos por el UI kit existente).
- [ ] Cuenta/proyecto GA4 + contenedor GTM bajo estándar ASC.

## 3. Arquitectura del cambio

```
UI kit existente (src/modules/ui-design, props hardcodeadas)
        │  adaptar
        ▼
UI kit parametrizado
        │
Endpoints de contenido (dealer-info · mrp-models · versions · promotions OEM)
        │  por Dealer ID / dominio
        ▼
Sitio (Fase 1: 1 plantilla · Fase 2: multi-tenant en Vercel)
        │
        ├─ Home (idéntico entre dealers, solo cambia data) + bloques de conversión
        ├─ 11 páginas internas (estructura fija, contenido por dealer vía dealer-info)
        ├─ 9 páginas de modelo/MRP (estructura fija, contenido vía mrp-models + versions)
        ├─ 1-2 páginas exclusivas de dealer (plantilla propia + dealer-info)
        └─ 4 formularios reutilizados del sitio de marca → conexión Make existente
```

## 4. Integraciones conocidas

| Recurso | Referencia |
|---|---|
| Repo (marca + UI kit, mismo repo) | `Sitios-Web-Go-Virtual/GAC-Next-Stack` |
| UI kit | `src/modules/ui-design` |
| Info de dealer | `GET /api/brick/group-info/dealers/{dealer-id}` |
| Contenido de modelos (MRP) | `GET /api/brick/mrp-models/brand/{id}` |
| Versiones (complemento de datos de modelo) | `GET /api/brick/versions/{id}` |
| Promociones | `GET /api/brick/promotions/{id}` — **solo OEM**, no existe desarrollo para promociones locales |

## 5. Fases y tareas

### Fase 1 — Rediseño de la plantilla (MVP)

**T-01 — Adaptar el UI kit existente (`src/modules/ui-design`) para reutilización multi-dealer** · **3 días**
Quitar el hardcode de props de los componentes ya construidos para que acepten datos dinámicos por marca/dealer, sin rehacer el diseño visual.
Cubre: RF-01, RNF-03. Criterio: cero props con valores fijos de un proyecto específico.

**T-02 — Diseño final de home + 11 páginas internas + 9 páginas de modelo (MRP)** · **5 días**
Estructura fija e igual para marca y dealer; el contenido por dealer se resuelve en runtime desde BD, no se duplica estructura. Home con bloques de conversión: plantilla idéntica para todos los dealers.
Cubre: RF-02, F2, F10/RF-11. Depende de: T-01.

**T-03 — Home reorientado a conversión** · **2 días**
Sobre UI kit adaptado. Cubre: RF-06, F6.

**T-04 — Componentes de conversión (CTAs)** · **3 días**
Agendar servicio, visitar agencia (mapa), cotizar, prueba de manejo, WhatsApp, llamar.
Cubre: RF-05, F5.

**T-05 — Bloque de promociones (solo OEM)** · **2 días**
Consumir `GET /brick/promotions/{id}`. No se construye gestión de promociones locales — no existe backend para ello.
Cubre: RF-04, F4 (acotado a OEM).

**T-06 — Formularios de lead reutilizados del sitio de marca** · **2 días**
Los 4 formularios (cotización, prueba de manejo, contacto, agendar servicio) ya existen en el sitio de marca. Se adaptan con estilos para preseleccionar/fijar el dealer correspondiente y reutilizan la conexión de envío de leads (Make) ya existente — sin integración nueva.
Cubre: RF-07, RF-08, F7, F8.

**T-07 — Instrumentación de eventos (estándar ASC)** · **2 días**
Eventos de conversión e interacción vía GTM/GA4, atribuidos por `dealer_id`.
Cubre: RF-12, RNF-07.

**T-08 — SEO técnico y geolocalización** · **1 día**
Metadatos, sitemap/robots por micrositio, datos estructurados de ubicación.
Cubre: RF-13, RNF-04.

**T-09 — Conectar las páginas de modelo (MRP) a la fuente de datos** · **3 días**
Consumir `mrp-models/brand/{id}` para el contenido base y `versions/{id}` como complemento por versión. Hoy el contenido está hardcodeado.
Depende de: T-02, acceso a los endpoints.

**T-10 — Mapear el contenido de las páginas internas contra `dealer-info`** · **2 días**
Determinar qué campos de las 11 páginas internas se resuelven con `GET /group-info/dealers/{dealer-id}` (dirección, contacto, horarios, etc.) y cuáles quedan fijos/estáticos compartidos por marca.

**T-11 — Páginas exclusivas de dealer** (ej. "Horarios y ubicaciones") · **2 días**
1-2 páginas con plantilla única, llenadas con `dealer-info` (dirección, horarios, geolocalización, contacto).

**T-12 — QA de homologación, responsive y no-regresión de parametrización** · **3 días**
Contra el UI kit adaptado y el set completo de páginas (11+9+1-2).
**Criterio de completitud del MVP:** diseño final aprobado; UI kit sin hardcode; CTAs y formularios funcionales sobre datos de prueba; páginas de modelo conectadas a `mrp-models`/`versions`; páginas internas mapeadas contra `dealer-info`; promociones OEM funcionando end-to-end; instrumentación ASC verificada. *(Sin inventario. Blog fuera de este criterio — Fase 3.)*

**Total Fase 1: 30 días hábiles**

### Fase 2 — Arquitectura multi-tenant en Vercel

Un solo sitio multi-tenant que resuelve el dealer por dominio, desplegado en **Vercel** (confirmado), permitiendo cambios masivos a componentes compartidos sin tocar sitio por sitio.

**T-13 — Resolución de tenant por dominio** · **3 días**
Middleware de Next.js que, a partir del `Host` de la petición, determina el `dealer_id` correspondiente y carga su configuración. Se apoya en el soporte de Vercel para múltiples dominios sobre un mismo proyecto.

**T-14 — Modelo de configuración por dealer (variables de entorno + BD)** · **4 días**
Variables de entorno de Vercel para lo estructural (credenciales, entorno, feature flags); toda la información variable por dealer (contenido, contacto, horarios) vive en base de datos, para que un cambio de dealer no implique tocar el front ni redeploy.

**T-15 — Activación de dominios y alta progresiva de dealers** · **5 días** (setup inicial; el alta de cada dealer adicional es incremental, no recurre el total)
Con el modelo multi-tenant operando, activar un dealer es dar de alta su dominio en Vercel + su registro en BD, no copiar código.

**Total Fase 2: 12 días hábiles**

### Fase 3 — Blog

**T-16 — Definición e implementación del blog** · **sin estimar** (depende de la decisión de negocio pendiente)
Movida aquí por su potencial de generar un desarrollo considerablemente mayor al scope actual. Depende de la decisión de negocio pendiente (PRD §14): integrar en fuente central, diferir a CMS, o hardcode temporal.

**Total Fase 3: pendiente de definición de alcance**

---

**Total estimado del plan (Fase 1 + Fase 2): 42 días hábiles** (~8.5 semanas-persona), sin contar Fase 3 (blog, sin alcance definido).

## 6. Riesgos

| Riesgo | Efecto |
|---|---|
| Acceso al repo/endpoints reales aún no verificado desde este entorno | Las tareas T-01, T-05, T-09, T-10 se validan en la práctica, no en este plan |
| Migración de contenido hardcodeado (UI kit, páginas de modelo) a BD | Puede tomar más tiempo si el esquema de BD no está definido a detalle |
| Blog en Fase 3 sin fecha | Puede generar expectativa de scope no comprometido si no se comunica bien al cliente |
| Escalar Fase 2 a 19+ dominios en un solo proyecto Vercel | Validar límites de dominios/planes de Vercel contra RNF-09 (escalabilidad) |
| Estimaciones de tiempo son preliminares | No están validadas por el equipo de desarrollo real; ajustar tras revisión |

## 7. Preguntas abiertas

- Blog: ¿integrar en fuente central, diferir a CMS, o hardcode temporal? → bloquea T-16 (Fase 3).
