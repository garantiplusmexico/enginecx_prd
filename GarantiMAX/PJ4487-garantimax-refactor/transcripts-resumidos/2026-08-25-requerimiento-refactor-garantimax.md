# Condensado — 2026-08-25-requerimiento-refactor-garantimax

## Decisiones

- Se **reconstruye GarantiMAX desde cero**. El objetivo explícito **NO es replicar la arquitectura actual**: el sistema existente se usa como *fuente de descubrimiento* (qué hace el producto, qué reglas existen, qué datos usa), no como plantilla.
- Distinción obligatoria en todo el documento: **requisito funcional existente** (se conserva) vs. **decisión técnica de la implementación actual** (se reconsidera). No se conserva nada solo porque ya existe.
- **La arquitectura nueva no debe depender de Supabase.** Se abstrae por contratos: `Repository` (datos), `RealtimeProvider`, `StorageProvider`, `AuthProvider`. La lógica de negocio no conoce `supabase.from(...)`.
- **Realtime ≠ Database.** Se tratan como capacidades independientes; si mañana cambia la base, Realtime debe poder implementarse con WebSockets/SSE/SignalR/Socket.IO/backend propio/Event Bus.
- **Ninguna vista o componente consulta la base de datos.** Las capas: Presentación → Aplicación / Casos de Uso → Dominio → Infraestructura (referencia conceptual, sin dogmatismo de Clean Architecture).
- **Anti-sobreingeniería explícita.** Cada abstracción debe justificarse por: evitar dependencia de proveedor, reemplazo tecnológico probable, testabilidad, separar negocio, encapsular infraestructura, compartir comportamiento o proteger el dominio. Sin razón clara → no se agrega.
- "Considerar no significa implementar": los módulos futuros se consideran arquitectónicamente, pero **no se construyen hoy** tablas, servicios, interfaces ni capas anticipadas.
- La decisión **Web vs. PWA** debe cerrarse con una **recomendación explícita** (no un listado de pros/contras) y documentarse como ADR.
- La PRD será la **fuente de verdad** para planificar e implementar, "posiblemente mediante desarrolladores y agentes de IA".

## Alcance / requerimientos

**Fase 1 = todo lo relacionado con el vendedor.** Se deben analizar los 24 módulos actuales, pero clasificarlos como mínimo en: **Fase 1** (primera salida, vendedor) · **Fase 2** (siguiente prioridad) · **Futuro** · **Legacy / candidato a eliminación** · **Requiere análisis adicional**. Deben quedar explícitas las **dependencias** entre lo del vendedor y los módulos fuera de alcance.

**Análisis obligatorio previo** del sistema actual: módulos, funcionalidades, tipos de usuario, roles y permisos, flujos, reglas de negocio, entidades, relaciones, estados y transiciones, integraciones externas, base de datos, uso de Supabase, Realtime, Auth, Storage, APIs, servicios externos, PWA, diferencias web vs. app instalada, dependencias entre módulos, código compartido, problemas arquitectónicos, duplicación, acoplamientos, deuda técnica y riesgos de seguridad.

**Arquitectura por features/dominios** (`customers`, `sales`, `contracts`, `documents`, `notifications`, `users`…), no por páginas, layouts ni tipos de usuario. Los roles determinan *qué puede hacer* un usuario, no la forma del dominio. Se debe clasificar cada funcionalidad como core/shared, específica del vendedor, compartible a futuro, infraestructura común o UI por rol.

**Web/PWA — tres alternativas a evaluar y recomendar una:**
- **A** — `WebLayout` + `AppLayout` separados, ambos consumiendo los mismos features/use cases/domain/repositories.
- **B** — experiencia app-like única, esté instalada como PWA o no.
- **C** — layout adaptativo por tamaño de pantalla, contexto, capacidades del dispositivo e instalación PWA, sin dos aplicaciones conceptualmente distintas.

Si se conservan dos layouts, son **solo presentación** (navegación, header, sidebar, bottom nav, app shell, responsive): nada de reglas de negocio, queries, Supabase, repositories ni integraciones. La detección de modo PWA debe estar **centralizada** — prohibido el `if (isPWA)` repartido por la app.

**Secciones obligatorias de la PRD (≈40):** resumen ejecutivo, contexto del sistema actual, objetivos, alcance, fuera de alcance, usuarios y actores, inventario de módulos, clasificación por fases, alcance del vendedor, funcionalidades, flujos, reglas de negocio, entidades, requisitos funcionales y no funcionales, problemas de la arquitectura actual, arquitectura propuesta + diagrama, organización por features, estructura de directorios, estrategia frontend, application layer/use cases, domain layer, repository strategy, infrastructure layer, realtime strategy, integraciones externas, estrategia Web/PWA, seguridad, manejo de errores, logging y observabilidad, testing, **matriz de vendor lock-in**, **ADRs**, estrategia de migración, riesgos técnicos, criterios de aceptación, decisiones pendientes y recomendaciones para fases posteriores. Diagramas **Mermaid** cuando aporten.

**Matriz de lock-in** con columnas: Capacidad · Proveedor actual · Abstracción propuesta · Riesgo de lock-in · Impacto de reemplazo (mínimo Database, Realtime, Storage, Auth).

**ADRs** (decisión · problema · alternativas · motivo · consecuencias · costo de cambio futuro) al menos para: arquitectura general, Supabase, repositories, realtime, Web/PWA, state management, auth, storage y backend.

**Seguridad:** autenticación, autorización, roles, permisos, validación de inputs, secrets, variables de entorno, APIs, RLS, XSS, CSRF, SQL injection, rate limiting, uploads, storage, logging seguro, sesiones, tokens, manejo de errores y exposición accidental. Regla dura: **nunca confiar solo en el frontend**. Si se mantiene acceso directo frontend→Supabase, hay que determinar **qué operaciones pueden ir así y cuáles deben pasar obligatoriamente por backend/server functions**.

**Requisitos no funcionales medibles** — se prohíbe explícitamente "el sistema debe ser rápido".

**Migración:** qué se conserva, reimplementa, rediseña o elimina; qué datos migran; qué integraciones se mantienen; qué se simplifica; **qué deuda técnica NO debe trasladarse**; y riesgos.

## Actores

- El documento solo nombra explícitamente al **vendedor** como foco de la Fase 1 (sin definir si es el asesor de terreno de GarantiPLUS o el vendedor de la sala/concesionario). Los demás actores salen del análisis del sistema actual.
- Autor del análisis y la PRD: rol de **Software Architect / Tech Lead / Product Engineer senior**.
- Consumidores de la PRD: desarrolladores humanos y **agentes de IA** que implementarán el sistema.

## Riesgos / pendientes

- **Ambigüedad crítica no resuelta en el documento:** qué significa "el vendedor". En el sistema actual conviven el **Asesor Farmer (AF)** —usuario del sistema que visita salas— y la entidad **`Vendedor`** —persona del concesionario que vende la garantía y que hoy *no* tiene login. Definir esto cambia por completo el alcance de la Fase 1.
- El documento no fija fechas, presupuesto, tamaño de equipo ni si la reconstrucción conserva el stack (React/TS) o migra al estándar corporativo Engine (.NET 8 + Razor).
- No define qué pasa con la base de datos existente (128 tablas, 364 migraciones) ni si se migran datos, se conserva el esquema o se rediseña.
- Riesgo de que la PRD se convierta en documentación del sistema actual en vez de especificación del nuevo (el documento lo señala explícitamente como resultado NO deseado).

## Fechas / hitos

- Sin fechas en el documento. (Recibido el 25-08-2026.)
