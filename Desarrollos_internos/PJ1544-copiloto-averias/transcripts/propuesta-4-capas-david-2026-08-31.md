# Propuesta de Proyecto — Automatización de Resoluciones de Averías (David Simancas, 2026-08-31)

> Texto extraído del .docx original, conservado junto a este archivo.

PROPUESTA DE PROYECTO
Automatización de Resoluciones de Averías
Asistente de Pre-Dictamen Técnico basado en datos históricos
Presenta
David Simancas Estrada — Controller / Analista Técnico Regional de Averías LATAM
Dirigido a
Héctor Izquierdo — Dirección General
Alcance
México, Colombia, Chile y Argentina
Fecha
31 de agosto de 2026
Estatus
Propuesta para aprobación
1. Resumen ejecutivo
Hoy la operación de averías está automatizada únicamente hasta la creación del siniestro. A partir de ese punto, cada caso requiere análisis técnico manual, sin importar si se trata de un rechazo evidente por cobertura o de un dictamen complejo de motor. Esto concentra el tiempo del equipo técnico en volumen repetitivo y limita nuestra capacidad de crecer sin crecer la nómina.
Se propone desarrollar un Asistente de Pre-Dictamen: un motor que analiza automáticamente cada avería contra el histórico regional, resuelve por reglas lo que es determinístico, y para todo lo demás entrega al técnico un caso pre-analizado con propuesta de resolución redactada. El técnico conserva íntegramente la facultad de decisión y firma.
Principio rector: el sistema no sustituye el criterio técnico, elimina el trabajo previo al criterio técnico.
2. Situación actual
La automatización termina en la creación de la avería; la resolución es 100% manual.
Se dedica el mismo esfuerzo analítico a un rechazo obvio por componente no cubierto que a un dictamen de motor de alto monto.
Los criterios de resolución dependen del gestor, lo que genera dispersión entre países y entre analistas.
Existe un volumen muy alto de data histórica infrautilizada: marca, modelo, año, kilometraje, componente, distribuidor, taller, región, resolución y monto.
La detección de desviaciones por distribuidor o taller ocurre de forma reactiva, generalmente al cierre mensual.
3. Objetivo
Reducir el tiempo de resolución por avería y homologar criterios técnicos en LATAM mediante un motor de pre-dictamen alimentado por el histórico de siniestros, manteniendo la decisión final bajo control humano y liberando capacidad del equipo técnico para los casos de alto valor.
Objetivos específicos
Resolver automáticamente los casos determinísticos (vigencia, kilometraje, componente fuera de cobertura).
Entregar propuesta de resolución redactada y sustentada en el histórico para los casos que requieren criterio.
Homologar el criterio técnico entre México, Colombia, Chile y Argentina.
Detectar desviaciones de comportamiento por taller y distribuidor de manera preventiva.
Construir trazabilidad completa: toda resolución queda documentada con su sustento.
4. Arquitectura del modelo — cuatro capas
El motor procesa cada avería en secuencia. Cada capa filtra casos y solo escala hacia la siguiente lo que no pudo resolver.
Capa 1 — Validación administrativa
Verificación determinística de las condiciones formales del contrato: vigencia del certificado, kilometraje contra el límite de cobertura, taller registrado y autorizado, situación de pagos. Son condiciones binarias que no admiten interpretación técnica. Resuelve sin intervención humana.
Capa 2 — Componente contra cobertura
Aplica a certificados nominados, donde la cobertura enumera componentes específicos. Si el componente reportado no aparece en el certificado, el rechazo es automático con fundamento citado. Esta capa es de implementación inmediata y bajo riesgo: hoy no existe y representa la primera ganancia visible del proyecto.
Capa 3 — Semáforo de confianza (coberturas amplias)
Para coberturas amplias, donde se cubre todo excepto desgaste, uso, duración y exclusiones específicas, el dictamen no puede automatizarse por completo porque distinguir desgaste de falla súbita exige criterio y evidencia física. Lo que sí se automatiza es la clasificación de riesgo y la preparación del caso.
El motor cruza dos ejes: confianza estadística (qué tan consistente ha sido el histórico para esa combinación exacta de marca, modelo, año, rango de kilometraje y componente) y exposición económica (monto en juego).
Semáforo
Criterio
Acción del sistema
Decisión
VERDE
≥90% de aprobación histórica, mínimo 30 casos comparables y monto bajo
Genera resolución completa
Automática
ÁMBAR
Confianza media o insuficientes casos comparables
Entrega caso pre-analizado con casos similares y propuesta
Técnico valida y firma
ROJO
Monto alto, componente sensible (motor, transmisión) o patrón anómalo
Escala con expediente completo y alertas
Revisión técnica y regional

Nota técnica: los umbrales de 90%, 30 casos y los cortes de monto son valores de arranque. Se calibran contra el histórico real durante el piloto y se ajustan por país y por cuenta.
Capa 4 — Excepciones
Todo caso de monto alto, siniestro con antecedentes, patrón atípico o sensibilidad comercial se excluye de cualquier automatización y se enruta a revisión humana, incluyendo escalamiento a la Dirección Regional cuando corresponda.
5. Detección de anomalías — control de red
Componente de alto valor que no depende de automatizar dictámenes, solo de comparar comportamientos, por lo que puede implementarse con la data actual sin dependencias adicionales.
El motor compara continuamente cada taller y cada distribuidor contra el promedio de sus pares por región, marca y tipo de componente. Cuando un actor se desvía significativamente del comportamiento esperado, se emite alerta.
Frecuencia atípica por componente: un taller que reporta el triple de transmisiones que sus pares.
Monto promedio desviado: costos por avería consistentemente por encima de la media regional.
Concentración temporal: picos de siniestros próximos al vencimiento de la cobertura.
Reincidencia por VIN: unidades con siniestros repetidos sobre el mismo sistema.
Valor directo: la desviación se detecta durante el mes y no en el cierre, lo que permite intervenir al distribuidor antes de que impacte la siniestralidad del periodo.
6. Alternativas de arranque evaluadas
Se evaluaron tres rutas de implementación. Se recomienda la Alternativa A como punto de partida, con incorporación progresiva de B y C.
Opción
Enfoque
Ventaja
Consideración
A ✓
Asistencia, no decisión
El sistema sugiere y redacta; la persona firma. Nula pérdida de autoridad técnica y máxima aceptación interna.
El ahorro de tiempo es alto pero no total; se conserva un paso humano por caso.
B
Arranque por cuenta
Iniciar con una sola cuenta (Mitsubishi o BMW) donde la data es más limpia y el resultado es demostrable antes de escalar.
Compatible con A: define el alcance del piloto más que el modelo.
C
Automatización por monto
Todo caso por debajo de un umbral se resuelve solo, sin importar marca. El costo de analizarlo supera el riesgo de error.
Requiere histórico calibrado; se recomienda activarla en fase 2, ya con el motor validado.

Recomendación: Alternativa A como modelo operativo, ejecutada bajo el alcance de la Alternativa B para el piloto, y habilitando la Alternativa C una vez calibrados los umbrales.
7. Caso de negocio
El sustento económico no está en reducir plantilla, sino en absorber mayor volumen sin incrementarla, manteniendo el control de calidad técnica.
Concepto
Actual
Proyectado
Impacto
Tiempo promedio de dictamen
[a definir]
≈5 min
Reducción estimada 80%
Averías atendidas por técnico / mes
[a definir]
[a calcular]
Mayor capacidad instalada
Casos resueltos sin intervención
0%
Por calibrar en piloto
Capas 1 y 2
Dispersión de criterio entre países
Alta
Homologada
Control regional
Detección de desviaciones
Al cierre mensual
Continua
Acción preventiva

Pendiente para cierre de cifras: volumen mensual real de averías por país y tiempo promedio actual de dictamen. Con esos dos datos las proyecciones dejan de ser estimadas y se vuelven cifras defendibles ante Dirección General.
Beneficios no financieros
Trazabilidad total: cada resolución queda documentada con su sustento histórico, lo que fortalece la posición ante auditorías y ante reclamaciones de distribuidores.
Homologación regional efectiva del criterio técnico, hoy dependiente del gestor.
Curva de aprendizaje más corta para nuevos gestores en la operación LATAM.
Reducción del tiempo de respuesta al cliente final y al distribuidor.
8. Ruta de implementación
Fase
Entregable
Contenido
Duración
Fase 1
Diagnóstico de data
Depuración, validación de integridad histórica y definición de variables del modelo
2 semanas
Fase 2
Motor de reglas
Capas 1 y 2 en operación: validación administrativa y componente contra cobertura
3 semanas
Fase 3
Semáforo y pre-dictamen
Capa 3 con calibración de umbrales sobre histórico real
3 semanas
Fase 4
Piloto en una cuenta
Operación en paralelo con medición de precisión contra dictamen humano
4 semanas
Fase 5
Despliegue regional
Escalamiento por país e integración del módulo de anomalías
Por definir

Primera versión funcional: 6 a 8 semanas. Piloto validado: 12 semanas desde el arranque.
9. Riesgos y mitigación
Riesgo
Nivel
Mitigación
Calidad e inconsistencia de la data histórica
Alto
Fase 1 dedicada exclusivamente a depuración; el modelo no avanza sin data validada.
Resolución automática incorrecta
Alto
Modelo de asistencia: la firma es humana. Automatización plena solo en capas determinísticas.
Resistencia del equipo técnico
Medio
El sistema no retira autoridad; se posiciona como herramienta de apoyo y se involucra al equipo en la calibración.
Sesgo del histórico (replicar errores pasados)
Medio
Auditoría de casos verdes durante el piloto y revisión periódica de umbrales.
Diferencias legales entre países
Medio
Parametrización por país; el marco legal local se configura como regla independiente.
10. Próximos pasos
#
Acción
1
Aprobación de Dirección General sobre el enfoque de asistencia (Alternativa A).
2
Definición de la cuenta piloto: Mitsubishi o BMW, según limpieza de data.
3
Entrega de volumen mensual y tiempo promedio de dictamen para cerrar el caso de negocio con cifras reales.
4
Asignación de recurso técnico para desarrollo e integración con el Portal de Averías.
5
Arranque de Fase 1 — diagnóstico de data.
Documento de uso interno — GarantiPlus México, S.A.P.I. de C.V. · Dirección Regional de Averías LATAM
