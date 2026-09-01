# Condensado — Propuesta de Automatización de Resoluciones de Averías LATAM (David Simancas, 2026-08-31)

**Documento:** *Asistente de Pre-Dictamen Técnico basado en datos históricos.* Presenta David Simancas Estrada (Controller / Analista Técnico Regional de Averías LATAM). Dirigido a Héctor Izquierdo (Dirección General). Estatus: propuesta para aprobación. Alcance declarado: **México, Colombia, Chile y Argentina**.

> Original en `.docx` conservado en `transcripts/`; el texto íntegro extraído está en `transcripts/propuesta-4-capas-david-2026-08-31.md`.

## Decisiones

- **Principio rector:** *"el sistema no sustituye el criterio técnico, elimina el trabajo previo al criterio técnico"*. El técnico conserva íntegramente la facultad de decisión y firma.
- **Alternativa de arranque recomendada: A — asistencia, no decisión.** El sistema sugiere y redacta; la persona firma. Ejecutada bajo el alcance de la **Alternativa B** (piloto en una sola cuenta: Mitsubishi o BMW, según limpieza de data). La **Alternativa C** —automatización por monto bajo umbral— se habilita en fase 2, ya con el motor validado.
- **Los umbrales del semáforo (90%, 30 casos, cortes de monto) son valores de arranque**, a calibrar contra el histórico real durante el piloto y a ajustar por país y por cuenta.

## Alcance / requerimientos — la arquitectura en cuatro capas

El motor procesa cada avería en secuencia; cada capa filtra y solo escala lo que no pudo resolver.

| Capa | Qué hace | Resolución |
| --- | --- | --- |
| **1 — Validación administrativa** | Verificación determinística de condiciones formales: vigencia del certificado, kilometraje contra el límite, taller registrado y autorizado, situación de pagos. Condiciones binarias sin interpretación técnica. | Sin intervención humana |
| **2 — Componente contra cobertura** | Solo certificados nominados: si el componente reportado no aparece enumerado en el certificado, rechazo automático con fundamento citado. *"De implementación inmediata y bajo riesgo: hoy no existe y representa la primera ganancia visible del proyecto."* | Automática |
| **3 — Semáforo de confianza** | Para coberturas amplias (cubre todo salvo desgaste, uso, duración y exclusiones). Distinguir desgaste de falla súbita exige criterio y evidencia física, así que **no se automatiza el dictamen**: se automatiza la clasificación de riesgo y la preparación del caso. Cruza dos ejes: **confianza estadística** (consistencia del histórico para la combinación exacta marca/modelo/año/rango de km/componente) y **exposición económica**. | Ver desglose |
| **4 — Excepciones** | Monto alto, siniestro con antecedentes, patrón atípico o sensibilidad comercial: excluido de toda automatización, enrutado a revisión humana con escalamiento a Dirección Regional. | Humana |

**Semáforo de la capa 3:**

| Color | Criterio | Acción del sistema | Decisión |
| --- | --- | --- | --- |
| **Verde** | ≥90% de aprobación histórica, mínimo 30 casos comparables y monto bajo | Genera resolución completa | *Automática (según el documento)* |
| **Ámbar** | Confianza media o casos comparables insuficientes | Entrega caso pre-analizado con casos similares y propuesta | Técnico valida y firma |
| **Rojo** | Monto alto, componente sensible (motor, transmisión) o patrón anómalo | Escala con expediente completo y alertas | Revisión técnica y regional |

## Alcance / requerimientos — detección de anomalías (control de red)

Componente separado, que **no depende de automatizar dictámenes**: solo compara comportamientos, por lo que puede implementarse con la data actual. Compara cada taller y distribuidor contra el promedio de sus pares por región, marca y tipo de componente, y alerta ante:

- **Frecuencia atípica por componente** (un taller que reporta el triple de transmisiones que sus pares).
- **Monto promedio desviado** respecto de la media regional.
- **Concentración temporal**: picos de siniestros próximos al vencimiento de la cobertura.
- **Reincidencia por VIN**: unidades con siniestros repetidos sobre el mismo sistema.

Valor declarado: la desviación se detecta **durante el mes** y no en el cierre, lo que permite intervenir al distribuidor antes de que impacte la siniestralidad del periodo.

## Actores

- **David Simancas Estrada** — autor de la propuesta, Controller / Analista Técnico Regional de Averías LATAM.
- **Héctor Izquierdo** — Dirección General; destinatario y aprobador del enfoque.
- **Dirección Regional de Averías** — destino del escalamiento de la capa 4.
- **Equipo técnico** — conserva decisión y firma; se le involucra en la calibración de umbrales como mitigación de resistencia.

## Riesgos / pendientes

| Riesgo | Nivel | Mitigación declarada |
| --- | --- | --- |
| Calidad e inconsistencia de la data histórica | Alto | Fase 1 dedicada exclusivamente a depuración; el modelo no avanza sin data validada |
| Resolución automática incorrecta | Alto | Modelo de asistencia: la firma es humana; automatización plena solo en capas determinísticas |
| Resistencia del equipo técnico | Medio | El sistema no retira autoridad; se involucra al equipo en la calibración |
| **Sesgo del histórico (replicar errores pasados)** | Medio | Auditoría de casos verdes durante el piloto y revisión periódica de umbrales |
| Diferencias legales entre países | Medio | Parametrización por país; el marco legal local como regla independiente |

**Pendientes explícitos del documento:**

- Cifras del caso de negocio sin cerrar: **tiempo promedio actual de dictamen** y **volumen mensual real de averías por país** están marcados como *"a definir"*. Sin ellos las proyecciones (≈5 min por dictamen, −80% de tiempo) son estimadas.
- Definición de la cuenta piloto: Mitsubishi o BMW.
- Asignación de recurso técnico para desarrollo e integración con el Portal de Averías.
- Aprobación de Dirección General sobre el enfoque de asistencia.

## Fechas / hitos — ruta de implementación propuesta

| Fase | Entregable | Duración |
| --- | --- | --- |
| 1 | Diagnóstico de data: depuración, integridad histórica, definición de variables | 2 semanas |
| 2 | Motor de reglas: capas 1 y 2 en operación | 3 semanas |
| 3 | Semáforo y pre-dictamen: capa 3 con calibración de umbrales sobre histórico real | 3 semanas |
| 4 | Piloto en una cuenta, en paralelo, midiendo precisión contra dictamen humano | 4 semanas |
| 5 | Despliegue regional por país + módulo de anomalías | Por definir |

**Primera versión funcional: 6 a 8 semanas. Piloto validado: 12 semanas desde el arranque.**

## Contradicción a resolver con el PRD del Copiloto

El documento otorga a **VERDE una resolución automática**, mientras que el PRD del Copiloto sostiene como principio duro y permanente que **ninguna autorización existe sin confirmación humana** (RNF-04), por la asimetría entre un rechazo —que se reclama y se corrige— y una autorización —que se paga. El propio documento recomienda la Alternativa A (*"asistencia, no decisión"*) y lista el sesgo del histórico como riesgo, de modo que la contradicción es interna a la propuesta. **Resuelto en el PRD v0.3 a favor del PRD:** se adopta el semáforo como clasificador de riesgo y priorizador, y VERDE significa expediente pre-armado con revisión mínima, no autorización sin persona.
