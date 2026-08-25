# Requerimiento — Refactor / reconstrucción de GarantiMAX

> Origen: `garantimax-refactor.docx` (Escritorio del desarrollador, 25-08-2026).
> El plugin no versiona `.docx`; este `.md` es la transcripción fiel del texto del documento.

---


Rol
Actúa como Software Architect, Tech Lead y Product Engineer senior.
Tu tarea es analizar un proyecto existente y generar una PRD (Product Requirements Document) técnica y funcional para reconstruirlo desde cero.
La PRD será utilizada posteriormente como fuente de verdad para planificar e implementar el nuevo sistema, posiblemente mediante desarrolladores y agentes de IA.
El objetivo NO es replicar la arquitectura actual.
Debes:
- Entender qué hace actualmente el sistema.
- Identificar sus funcionalidades y reglas de negocio.
- Detectar problemas, deuda técnica y acoplamientos.
- Determinar qué debe conservarse funcionalmente.
- Proponer una nueva arquitectura limpia.
- Definir claramente qué pertenece a la primera fase.
- Considerar el crecimiento futuro sin implementar prematuramente funcionalidades o abstracciones innecesarias.

1. Análisis obligatorio del proyecto existente
Antes de generar la PRD, analiza el proyecto actual.
Identifica:
- Módulos existentes.
- Funcionalidades.
- Tipos de usuario.
- Roles y permisos.
- Flujos principales.
- Reglas de negocio.
- Entidades.
- Relaciones.
- Estados y transiciones.
- Integraciones externas.
- Base de datos.
- Uso de Supabase.
- Uso de Realtime.
- Autenticación.
- Storage.
- APIs.
- Servicios externos.
- PWA.
- Diferencias entre experiencia web y aplicación instalada.
- Dependencias entre módulos.
- Código compartido.
- Problemas arquitectónicos.
- Código duplicado.
- Acoplamientos.
- Deuda técnica.
- Problemas potenciales de seguridad.
No asumas que una decisión actual debe conservarse simplemente porque ya existe.
Distingue siempre entre:
requisito funcional existente
y
decisión técnica de la implementación actual.
Los requisitos funcionales importantes deben conservarse.
Las decisiones técnicas pueden y deben reconsiderarse.

2. Alcance de la primera versión
El sistema actual contiene múltiples módulos.
La primera salida de la nueva versión estará enfocada principalmente en todas las funcionalidades relacionadas con el vendedor.
Analiza todos los módulos existentes, pero clasifícalos como mínimo en:
- Fase 1 — necesarios para la primera salida enfocada al vendedor.
- Fase 2 — siguiente prioridad.
- Futuro.
- Legacy / candidato a eliminación.
- Requiere análisis adicional.
Identifica también dependencias entre funcionalidades del vendedor y módulos que inicialmente quedarán fuera del alcance.
La PRD debe definir claramente:
- Qué entra en Fase 1.
- Qué no entra.
- Qué dependencias existen.
- Qué funcionalidades actuales necesita realmente el vendedor.
- Qué funcionalidades podrían simplificarse.
- Qué módulos futuros deben ser considerados arquitectónicamente.
Principio fundamental
Los módulos futuros deben considerarse arquitectónicamente, pero NO deben implementarse prematuramente.
La arquitectura debe permitir incorporarlos posteriormente sin reconstruir nuevamente el sistema, pero evita crear interfaces, servicios, capas o abstracciones que actualmente no aporten valor.
Diseña para evolucionar, no para intentar predecir todo el futuro.

3. Principios arquitectónicos
La nueva arquitectura debe priorizar:
- Separation of Concerns.
- Single Responsibility Principle.
- Dependency Inversion.
- Bajo acoplamiento.
- Alta cohesión.
- Modularidad.
- Testabilidad.
- Escalabilidad.
- Mantenibilidad.
- Seguridad.
- Legibilidad.
- Facilidad de evolución.
- Facilidad para reemplazar infraestructura.
- Facilidad para reemplazar proveedores externos.
Como referencia conceptual, separar:
Presentación → Aplicación / Casos de Uso → Dominio / Negocio → Infraestructura
No es obligatorio aplicar Clean Architecture de forma dogmática.
Utiliza únicamente las capas, patrones y abstracciones que tengan una justificación real.
Evita sobreingeniería.
Cada abstracción propuesta debe resolver un problema concreto de desacoplamiento, testabilidad, seguridad, reutilización o posibilidad real de cambio.

4. Arquitectura orientada a módulos/features
Evalúa si conviene utilizar una arquitectura:
- Por features.
- Por capas.
- O híbrida: features + separación interna por responsabilidades.
Prioriza una estructura que permita que el sistema crezca progresivamente.
Evita organizar todo alrededor de páginas, layouts o tipos de usuario.
Cuando sea apropiado, utiliza dominios/capacidades como:
customers
sales
contracts
documents
notifications
users
etc.
Los roles deben determinar principalmente qué puede hacer un usuario, pero no necesariamente definir toda la arquitectura del dominio.
Identifica qué funcionalidades son:
- Core/shared.
- Específicas del vendedor.
- Compartibles con futuras áreas.
- Infraestructura común.
- UI específica por rol.

5. Frontend
El frontend debe estar organizado mediante componentes reutilizables y responsabilidades claras.
Ninguna vista, página o componente visual debe:
- Consultar directamente la base de datos.
- Contener queries.
- Conocer detalles de Supabase.
- Acceder directamente a repositorios cuando exista una capa de aplicación que deba coordinar la operación.
- Implementar reglas importantes del negocio.
- Consumir directamente SDKs externos cuando esto genere acoplamiento.
- Mezclar infraestructura con presentación.
Los componentes deben concentrarse principalmente en:
- Renderizado.
- Interacción.
- Estado estrictamente relacionado con UI.
- Composición de componentes.
Define claramente la responsabilidad de:
- Pages / Views.
- Components.
- Composables / Hooks.
- Stores / State.
- Application Services.
- Use Cases.
- Domain.
- Repositories.
- Infrastructure.
- Providers.
- External Services.

6. Separación de lógica de negocio
Las reglas del negocio deben estar centralizadas.
Evita duplicarlas entre:
- Componentes.
- Views.
- Stores.
- Queries.
- Event handlers.
- Repositories.
- Integraciones externas.
Identifica:
- Entidades.
- Casos de uso.
- Validaciones.
- Estados.
- Transiciones.
- Permisos.
- Invariantes.
- Procesos críticos.
Una regla importante del negocio debe tener una única fuente de verdad.

7. Acceso a datos y Repository Pattern
Actualmente se utiliza Supabase.
Sin embargo, la arquitectura nueva NO debe depender directamente de Supabase.
Define contratos/interfaces de repositorios cuando exista una razón real para abstraer la persistencia.
Ejemplo conceptual:
UserRepository
Implementación:
SupabaseUserRepository
De esta forma, en el futuro podría existir:
PostgresUserRepository
ApiUserRepository
FirebaseUserRepository
u otra implementación.
La lógica de negocio no debe conocer:
supabase.from(...)
ni detalles específicos del proveedor.
Las consultas, filtros, persistencia y operaciones relacionadas con almacenamiento deben permanecer encapsuladas.
Cambiar de proveedor de datos debe tener un impacto controlado y localizado.

8. Realtime como capacidad independiente
Actualmente Supabase se utiliza también por sus capacidades de Realtime.
No asumir que:
Database = Realtime
Arquitectónicamente deben considerarse capacidades independientes.
Define una abstracción conceptual como:
RealtimeProvider
con una implementación actual:
SupabaseRealtimeProvider
Si en el futuro la base de datos cambia y el nuevo proveedor no incluye Realtime, debe ser posible implementar alternativas como:
- WebSockets.
- Server-Sent Events.
- SignalR.
- Socket.IO.
- Backend propio.
- Servicios administrados.
- Event Bus.
- Otro proveedor.
Identifica exactamente:
- Qué funcionalidades utilizan Realtime.
- Por qué lo necesitan.
- Qué eventos escuchan.
- Qué información actualizan.
- Qué módulos dependen de esos eventos.
- Cuáles realmente necesitan Realtime.
- Cuáles podrían utilizar consultas tradicionales.
La UI no debe conocer directamente los detalles de Supabase Realtime.

9. Servicios externos
Todos los servicios de terceros deben permanecer correctamente encapsulados.
Analiza servicios relacionados con:
- Supabase.
- Autenticación.
- Storage.
- Email.
- Notificaciones.
- Analytics.
- APIs externas.
- Pagos.
- IA.
- Webhooks.
- Realtime.
- Cualquier SDK externo.
Cuando exista posibilidad razonable de reemplazo, utiliza contratos, adapters, gateways o providers.
Ejemplo:
StorageProvider
Implementación:
SupabaseStorageProvider
Futuro:
S3StorageProvider
Cambiar un proveedor no debería obligar a modificar múltiples módulos del sistema.

10. PWA y experiencia Web/App
Actualmente el sistema detecta cuando la web se encuentra instalada como PWA/app.
Cuando detecta este contexto, carga un layout diferente con una experiencia más cercana a una aplicación móvil y determinadas acciones específicas.
Esta decisión NO debe conservarse automáticamente.
Analiza las siguientes alternativas.
Alternativa A — WebLayout + AppLayout
Mantener dos experiencias de presentación diferentes.
Conceptualmente:
WebLayout
AppLayout
Ambos deben consumir los mismos:
- Features.
- Use Cases.
- Domain.
- Repositories.
- Services.
La diferencia debe limitarse principalmente a presentación y navegación.

Alternativa B — experiencia App-like única
Evaluar convertir toda la aplicación en una experiencia consistente tipo aplicación independientemente de si está instalada como PWA.
Analizar especialmente:
- Desktop.
- Mobile.
- Responsive design.
- Navegación.
- Productividad del vendedor.
- Mantenimiento.
- Complejidad.
- Código duplicado.

Alternativa C — Layout adaptativo
Evaluar una arquitectura común que adapte su presentación según:
- Tamaño de pantalla.
- Contexto.
- Capacidades del dispositivo.
- Instalación PWA.
- Tipo de usuario cuando sea necesario.
Sin convertir Web y PWA en dos aplicaciones conceptualmente distintas.

11. Decisión arquitectónica Web/PWA
La PRD debe analizar las alternativas anteriores y realizar una recomendación explícita.
No te limites a enumerar ventajas y desventajas.
Recomienda una solución.
Considera:
- UX.
- Desktop.
- Mobile.
- PWA.
- Mantenibilidad.
- Complejidad.
- Reutilización.
- Duplicación.
- Necesidades del vendedor.
- Futuras áreas administrativas.
- Evolución del producto.
Documenta esta decisión como ADR.

12. Separación obligatoria de layouts
Si se decide mantener WebLayout y AppLayout, deben permanecer claramente separados.
Los layouts pueden encargarse de:
- Navegación.
- Header.
- Sidebar.
- Bottom navigation.
- App shell.
- Distribución visual.
- Responsive behavior.
- Acciones globales relacionadas con navegación.
NO deben contener:
- Reglas de negocio.
- Queries.
- Acceso a Supabase.
- Acceso directo a base de datos.
- Repositories.
- Integraciones externas.
- Lógica específica del dominio.
La detección del modo PWA tampoco debe encontrarse distribuida por toda la aplicación.
Evitar:
if (isPWA) ...
repetido en múltiples componentes.
La detección del contexto debe estar centralizada.

13. Seguridad
Incluye una sección específica de seguridad.
Analiza como mínimo:
- Autenticación.
- Autorización.
- Roles.
- Permisos.
- Validación de inputs.
- Información sensible.
- Secrets.
- Variables de entorno.
- APIs.
- Base de datos.
- Row Level Security cuando aplique.
- XSS.
- CSRF cuando aplique.
- SQL Injection.
- Rate limiting.
- Uploads.
- Storage.
- Logging seguro.
- Sesiones.
- Tokens.
- Manejo de errores.
- Exposición accidental de información.
Nunca confiar exclusivamente en el frontend para proteger operaciones sensibles.
Si la arquitectura propuesta utiliza acceso directo desde frontend hacia Supabase, analiza específicamente sus implicaciones de seguridad y determina qué operaciones pueden realizarse de esta manera y cuáles deberían pasar obligatoriamente por backend/server functions.

14. Manejo de errores
Define una estrategia consistente para:
- Domain errors.
- Application errors.
- Infrastructure errors.
- Network errors.
- External provider errors.
- Validation errors.
- Authentication errors.
- Authorization errors.
La UI debe recibir errores comprensibles sin conocer detalles internos de infraestructura.
No exponer información sensible al usuario.

15. Logging y observabilidad
Define una estrategia para:
- Logging.
- Auditoría.
- Métricas.
- Monitoring.
- Tracking de errores.
- Operaciones críticas.
- Integraciones externas.
- Fallos de Realtime.
Determina qué operaciones necesitan trazabilidad.

16. Testing
Define una estrategia de testing para:
- Unit tests.
- Domain tests.
- Use Case tests.
- Repository tests.
- Integration tests.
- Component tests.
- End-to-End tests.
Identifica especialmente los flujos críticos del vendedor que deberían tener pruebas E2E.
El desacoplamiento debe facilitar utilizar:
- Mocks.
- Fakes.
- Test implementations.
Sin depender necesariamente de Supabase real durante pruebas unitarias.

17. Estructura del proyecto
Propón una estructura de directorios concreta.
Explica la responsabilidad de cada carpeta.
Debe quedar claro dónde viven:
- Features.
- Pages.
- Components.
- Layouts.
- Domain.
- Application.
- Use Cases.
- Repositories.
- Infrastructure.
- Providers.
- External integrations.
- Shared code.
- Configuration.
- Types.
- Tests.
Evita carpetas genéricas que terminen convirtiéndose en depósitos de código sin responsabilidad clara.

18. Matriz de dependencias y Vendor Lock-in
Genera una matriz similar a:
Capacidad
Proveedor actual
Abstracción propuesta
Riesgo de lock-in
Impacto de reemplazo
Database
Supabase
Repository
...
...
Realtime
Supabase Realtime
RealtimeProvider
...
...
Storage
...
StorageProvider
...
...
Auth
...
AuthProvider
...
...
Completa la tabla utilizando lo encontrado realmente durante el análisis.
Identifica explícitamente cualquier dependencia crítica de un proveedor.

19. ADR — Architecture Decision Records
Para decisiones arquitectónicas importantes genera ADRs simplificados.
Cada ADR debe contener:
Decisión
Qué se propone.
Problema
Qué problema resuelve.
Alternativas consideradas
Qué otras opciones existen.
Motivo
Por qué se recomienda esta alternativa.
Consecuencias
Qué implica adoptar esta decisión.
Costo de cambio futuro
Qué tan complicado sería reemplazarla.
Genera ADRs especialmente para decisiones como:
- Arquitectura general.
- Supabase.
- Repositories.
- Realtime.
- Web/PWA.
- State management.
- Auth.
- Storage.
- Backend cuando corresponda.

20. Requisitos no funcionales
Documenta:
- Performance.
- Seguridad.
- Escalabilidad.
- Mantenibilidad.
- Accesibilidad.
- Responsive design.
- Compatibilidad.
- Observabilidad.
- Disponibilidad.
- Recuperación ante errores.
- Experiencia móvil.
- Experiencia desktop.
- PWA.
Cuando sea posible define criterios verificables.
Evita requisitos vagos como:
"El sistema debe ser rápido."
Preferir criterios medibles cuando exista información suficiente para establecerlos.

21. Migración desde el sistema actual
Identifica:
- Qué debe conservarse.
- Qué debe reimplementarse.
- Qué debe rediseñarse.
- Qué debe eliminarse.
- Qué datos deben migrarse.
- Qué integraciones deben mantenerse.
- Qué funcionalidades pueden simplificarse.
- Qué deuda técnica NO debe trasladarse.
- Riesgos de migración.
No copies deuda técnica simplemente para mantener compatibilidad con la implementación anterior.

22. Preparación para crecimiento futuro
Aunque inicialmente se implemente solamente el alcance relacionado con vendedores, analiza cómo los futuros módulos podrían integrarse.
Identifica:
- Capacidades compartidas.
- Entidades compartidas.
- Servicios compartidos.
- Dependencias potenciales.
- Límites entre dominios.
Pero aplica estrictamente:
Considerar no significa implementar.
No crear infraestructura, tablas, servicios, módulos, abstracciones o interfaces únicamente porque hipotéticamente podrían necesitarse algún día.
Implementa abstracciones anticipadas solamente cuando exista evidencia suficiente de que representan un punto real de variación o integración futura.

23. Formato final obligatorio de la PRD
Genera la PRD utilizando como mínimo:
- Resumen ejecutivo.
- Contexto del sistema actual.
- Objetivos.
- Alcance.
- Fuera de alcance.
- Usuarios y actores.
- Inventario de módulos actuales.
- Clasificación Fase 1 / Fase 2 / Futuro / Legacy.
- Alcance específico del vendedor.
- Funcionalidades.
- Flujos principales.
- Reglas de negocio.
- Entidades principales.
- Requisitos funcionales.
- Requisitos no funcionales.
- Problemas detectados en la arquitectura actual.
- Arquitectura propuesta.
- Diagrama conceptual de arquitectura.
- Organización por módulos/features.
- Estructura de directorios propuesta.
- Estrategia frontend y componentes.
- Application Layer / Use Cases.
- Domain Layer.
- Repository Strategy.
- Infrastructure Layer.
- Realtime Strategy.
- Integraciones externas.
- Estrategia Web/PWA.
- Seguridad.
- Manejo de errores.
- Logging y observabilidad.
- Testing.
- Matriz de proveedores y Vendor Lock-in.
- ADRs.
- Estrategia de migración.
- Riesgos técnicos.
- Criterios de aceptación.
- Decisiones pendientes.
- Recomendaciones para fases posteriores.

24. Diagramas
Cuando ayude a comprender la solución, incluye diagramas Mermaid.
Como mínimo considera:
Arquitectura general
UI
↓
Application / Use Cases
↓
Domain
↓
Repository Interfaces / Provider Interfaces
↓
Infrastructure
↓
Supabase / APIs / External Services
Genera también diagramas para flujos importantes cuando aporten valor.

25. Reglas fundamentales
Durante todo el análisis aplica estas reglas:
Regla 1
La UI puede cambiar sin afectar el dominio.
Regla 2
La base de datos puede cambiar sin reescribir la lógica del negocio.
Regla 3
Supabase puede ser reemplazado.
Regla 4
El mecanismo Realtime puede cambiar independientemente de la base de datos.
Regla 5
Los servicios externos deben estar encapsulados.
Regla 6
Ninguna vista o componente debe realizar consultas directamente a base de datos.
Regla 7
La lógica de negocio debe estar separada de UI, persistencia e infraestructura.
Regla 8
WebLayout y AppLayout, si ambos existen, son capas de presentación y no arquitecturas diferentes.
Regla 9
El sistema debe poder crecer hacia nuevos módulos sin reconstruir su base.
Regla 10
No implementar prematuramente módulos futuros.
Regla 11
No crear abstracciones únicamente por seguir un patrón.
Regla 12
Priorizar código simple, explícito, mantenible y fácil de entender.

26. Criterio para proponer abstracciones
Antes de recomendar una interfaz, provider, adapter, repository o capa adicional, evalúa:
¿Qué problema concreto resuelve esta abstracción?
Debe existir al menos una razón válida:
- Evitar dependencia directa de un proveedor.
- Permitir reemplazo tecnológico razonablemente probable.
- Facilitar testing.
- Separar lógica de negocio.
- Encapsular infraestructura.
- Compartir comportamiento.
- Proteger el dominio de detalles externos.
Si no existe una razón clara, evita agregar la abstracción.

Resultado esperado
La PRD no debe ser simplemente una documentación del sistema actual.
Debe representar la especificación del nuevo sistema que queremos construir.
Utiliza el proyecto existente como fuente para descubrir:
- Qué hace el producto.
- Qué necesitan los usuarios.
- Qué reglas existen.
- Qué datos utiliza.
- Qué integraciones necesita.
Pero cuestiona la forma en que actualmente está implementado.
Cuando encuentres una decisión que pueda generar:
- Acoplamiento fuerte.
- Vendor lock-in.
- Problemas de seguridad.
- Código duplicado.
- Dificultad de testing.
- Problemas de mantenimiento.
- Dificultad para incorporar módulos futuros.
Señálala explícitamente y propón una alternativa.
Finalmente, prioriza siempre:
simplicidad + separación de responsabilidades + mantenibilidad + seguridad + capacidad de evolución.
La nueva arquitectura debe estar preparada para cambiar, pero no debe intentar construir hoy todo lo que posiblemente necesitaremos mañana.

