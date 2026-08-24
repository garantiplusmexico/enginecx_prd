# 19 · Dictamen y recomendación

| Campo | Detalle |
|---|---|
| Capítulo | C18 |
| Requerimiento(s) | RF-21 |
| Etapa | A (preliminar) — T-26 · B (definitivo) — T-38 |
| Versión | 1.0 — **PRELIMINAR** |
| Fecha | 2026-08-24 |
| Estado | 🟡 Preliminar — el dictamen definitivo (T-38) puede diferir de este si Etapa B revela algo material |

> ## ⚠️ Este dictamen es preliminar
> Se emite sobre evidencia de código y migraciones (Etapa A), **sin verificación contra la base real ni cifras de costo** (Etapa B, bloqueada por A1/A2/A3). Tres cosas concretas podrían cambiar esta recomendación cuando lleguen:
> 1. **Si T-32 encuentra más tablas con políticas tan abiertas como `mora_corte`**, el peso del Fork 1 (¿el riesgo de la plataforma justifica moverla?) se inclina más hacia migrar por seguridad, no solo por gobierno.
> 2. **Si T-35 muestra que el costo/consumo se concentra en el dominio de operación de garantías** (no en el comercial), E4 pierde su principal atractivo — hoy la hipótesis es que el dominio comercial (sin equivalente en SIGA) es el que más justifica quedarse en Supabase.
> 3. **Si T-36 confirma que la API de SIGA no cubre los 40 campos que hoy entran por Excel** (C6/T-13), cualquier escenario de migración —cualquiera de los cinco— hereda la dependencia manual; esto no cambia la elección de escenario, pero sí el riesgo aceptado de todos por igual.

---

## 1. Recorrido del árbol de decisión (PRD §7.3, con la rama de E4)

**Fork 1 — ¿El riesgo/costo de la plataforma externa justifica mover algo?**

La evidencia de Fase 2 es más matizada de lo que el problema original del PRD sugiere. La mayoría de los hallazgos (`hallazgos.md`) — cero tests de UI, TypeScript sin `strict`, CORS inconsistente, sin observabilidad de backend, 7 módulos sin documentar — **son deuda técnica y de proceso, no defectos inherentes de Supabase**. Existirían igual en un backend .NET mal disciplinado. El único hallazgo verdaderamente ligado a la plataforma es `mora_corte` (#1), y es un error de configuración de una política, no una limitación del modelo RLS (que en las otras 135 tablas está bien aplicado).

**Sin embargo**, hay una razón real para mover algo que no es de calidad de código sino de **gobierno de acceso**: TI no controla las llaves, el billing ni la cuenta donde vive el código (`fabriziolag/garantiplus-dashboard`, cuenta personal, pregunta abierta del PRD). Esa dependencia no se resuelve documentando ni refactorizando — solo se resuelve moviendo el control, no necesariamente todo el sistema.

**Lectura preliminar: Sí, hay razón para mover algo — pero es una razón de gobierno de plataforma, no de calidad de código.** Esto ya descarta, preliminarmente, que la motivación correcta sea "hay que rehacerlo porque está mal hecho" (sesgo que el PRD pide evitar explícitamente, RNF-10).

**Fork 2 — ¿La calidad interna permite construir sobre lo existente?**

Evidencia mayoritariamente a favor: `postventa/dominio` es una capa de lógica pura, testeada, aislada de React y de Supabase (C10) — exactamente lo que facilita construir encima o migrar por partes. El patrón *staging → aplicar* se repite con criterio entre módulos (C10 §5). El equipo se autocorrige (commits de revisión, migración de contención de duplicados que funciona, C13). Los problemas reales (componentes de hasta 3525 líneas, cero tests de UI, tipado no estricto) son refactorizables — no son un indicio de que el sistema esté mal concebido, son indicio de que le faltó tiempo/disciplina en superficies concretas.

**Lectura preliminar: Sí, la calidad interna permite construir sobre lo existente.** Esto descarta preliminarmente la re-escritura total (rama D del árbol) — no hay evidencia que la justifique.

**Fork 3 — ¿Supabase es sustituible a costo razonable? (Sí / No / En parte)**

Esta es la pregunta que Etapa A **no puede responder con números** (T-35 pendiente), pero sí puede acotar con estructura:

- El servicio más caro y riesgoso de sustituir, con diferencia, es **Realtime** (C15 §1.5) — no por su tecnología sino porque `postgres_changes` no tiene equivalente gratuito del otro lado: alguien tiene que construir y operar la emisión de eventos que hoy Postgres hace sola.
- Los 11 canales de Realtime están concentrados en el dominio comercial y de atención (8 de 11 en `warroom`/`callcenter`, C8) — es decir, **en el dominio que E4 propone dejar en Supabase**.
- La segmentación de C2/C3 encontró costuras reales pero acotadas (`callcenter` vía `av_casos`, catálogos transversales) — no una maraña que haga inviable un corte de dominio.

**Lectura preliminar: "En parte."** La estructura favorece a E4 más que a un "sí" (E1/E2) o un "no" (E3) categórico — precisamente porque la pieza más cara de sustituir (Realtime) coincide con el dominio que E4 propone conservar. **Esto es la hipótesis a confirmar en T-37, no una conclusión.**

---

## 2. Recomendación preliminar

**Camino recomendado, en orden de confianza:**

1. **E4 (retención parcial por dominio) es el candidato preliminar más prometedor** — no porque ya esté probado, sino porque es el único de los cuatro escenarios de migración cuya lógica coincide con dos hechos duros ya confirmados: el dominio comercial no tiene equivalente en SIGA (no hay nada que "consolidar"), y el Realtime —la pieza más cara de mover— vive mayoritariamente ahí. **Su aprobación final depende enteramente de T-35 (peso real) y T-37 (costuras resueltas).**
2. **E0 permanece como línea base seria, no como trámite** — si T-35 muestra que el costo de Supabase es bajo y manejable, y si se resuelve el gobierno de acceso (llaves, cuenta de GitHub) sin mover código, E0 + el trabajo ya identificado en Fase 2 (tests de UI, `strict`, observabilidad) puede ser suficiente.
3. **E3 es el respaldo si E4 se descarta en T-37** — conserva el Realtime en convivencia (evitando el ítem más caro) sin comprometerse a un corte de dominio que resultó no ser viable.
4. **E1 se recomienda solo si T-35 muestra que el costo de Supabase es alto de forma pareja en ambos dominios** (sin concentración que favorezca E4) y el gobierno de acceso exige salir de Supabase por completo.
5. **E2 no tiene evidencia que lo justifique hoy.** La calidad interna (Fork 2) no lo exige, y el costo de rehacer 113 587 líneas de UI —incluida una PWA con offline funcional (C9)— es el más alto de los cinco sin un beneficio claro que los otros cuatro no den también.

## 3. Qué debe decidirse antes de arrancar cualquier escenario que no sea E0

- **Regularizar la propiedad del código** (`fabriziolag/garantiplus-dashboard`) — es un requisito de gobierno independiente del escenario técnico elegido.
- **Confirmar la latencia real que exige War Room y call center** (A6) — decide si el Realtime se puede sustituir por polling en algunas partes, cambiando el cálculo de esfuerzo de E1/E2/E3.
- **Obtener el costo real de Supabase/Vercel** (A2) — sin esto, "costo de plataforma" en la comparación de escenarios sigue siendo hipótesis, no evidencia.
- **Verificar RLS real** (T-32) — si aparecen más hallazgos como `mora_corte`, cambia el peso del Fork 1.

## 4. Riesgos que se aceptan con esta recomendación preliminar

| Riesgo aceptado | Por qué se acepta de todas formas |
|---|---|
| E4 podría no ser viable tras T-37 | Es exactamente lo que Etapa B existe para resolver; recomendarlo como "candidato preliminar" en vez de "decisión" es la forma correcta de aceptarlo |
| La dependencia manual de SIGA por Excel persiste en cualquier escenario si T-36 no confirma cobertura de API | Está fuera del control de esta decisión — es un riesgo transversal a los cinco escenarios, no un motivo para preferir uno sobre otro |
| El hallazgo Crítico (`mora_corte`) no está remediado a la fecha de este documento | Está escalado y con recomendación concreta desde el 24-08-2026; no depende de la elección de escenario para resolverse — debe corregirse ya, en el stack actual |

---

## Cobertura declarada (RNF-11)

Recomendación derivada explícitamente del árbol de decisión del PRD, con la evidencia que resuelve cada bifurcación citada. **Marcada preliminar en su título y en cada sección relevante** (RNF-06, trazabilidad de decisiones). El dictamen definitivo (T-38) reemplazará este documento dejando constancia de qué cambió y por qué, según exige `PLAN.md` §1.4.
