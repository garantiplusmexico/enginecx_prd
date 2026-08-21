# Condensado — Solicitud inicial: Análisis técnico GarantiMAX

## Decisiones
- Se crea un PRD de **análisis** (no de construcción): el entregable es documentación técnica.
- Alcance del PRD: **solo el análisis + la documentación**. La decisión refactor/rehacer y su
  plan de ejecución se tratarán en un PRD posterior.
- Identidad: `project_id` = `garantimax-analisis-tecnico`, `unidad` = EngineCX,
  `sistema` = GarantiMAX, `prd_dir` = `GarantiMAX/PJ3896-garantimax-analisis-tecnico`.
- Autoría: Javier Oropeza ejecuta; **Aldo Álvarez (Director de TI) aprueba** la decisión final.
- Análisis en **3 fases**: inventario y mapeo → análisis de calidad → escenarios y dictamen.
- Profundidad: **inventario completo** de tablas, RLS, RPCs y Edge Functions.
- Entregable: **Markdown versionado con diagramas mermaid**.
- Estimación de esfuerzo: **rangos gruesos** por escenario (no desglose por módulo).
- Fecha objetivo del entregable final: **04-09-2026** (2 semanas).

## Alcance / requerimientos
- Documentar tecnologías, estructura y lógica del sistema; evaluar buenas prácticas,
  arquitectura y patrones de diseño usados.
- Documentar qué se consume de SIGA y **auditar la API de SIGA** para ver si ya cubre esos
  datos o hay que construir endpoints.
- Documentar qué se guarda en Supabase y **dónde exactamente se usa realtime**.
- Capítulo dedicado: **Supabase vs. lo que habría que construir en .NET 8** — qué puede
  convivir y qué conviene.
- Comparar 3 escenarios de destino: (1) front React actual + back .NET 8 API,
  (2) todo .NET 8 + Razor, (3) híbrido .NET 8 con realtime (Supabase Realtime vs SignalR).
- Evaluar 3 opciones para la PWA: dejarla en el mismo proyecto, extraerla a proyecto/app
  separada, o app nativa/híbrida.
- Dimensiones de calidad obligatorias: seguridad (RLS, secretos, datos personales),
  rendimiento y escalabilidad, testing/CI-CD y proceso, observabilidad y operación.

## Actores
- Javier Oropeza — ejecuta el análisis y redacta la documentación.
- Aldo Álvarez — Director de TI, revisa y decide.
- Fabrizio Álvarez — Country Manager, dueño/usuario principal del sistema actual.
- Equipo de desarrollo .NET de Engine — consumidor del documento.

## Riesgos / pendientes
- Drivers del análisis: sistema construido **fuera del estándar corporativo** (.NET 8 + Razor)
  que TI debe absorber, y **riesgo/costo de Supabase + Vercel** como plataforma externa.
- Accesos confirmados: código del repo local, base Supabase (lectura), repo/doc de la API
  de SIGA. **NO** hay acceso a los paneles de costos de Vercel/Supabase → el capítulo de costo
  queda condicionado a conseguirlo.

## Fechas / hitos
- 21-08-2026: inicio del análisis (creación de este PRD).
- 04-09-2026: entrega de la documentación técnica final con dictamen.
