# Condensado — Análisis de la API de SIGA para automatizar averías (2026-08-26)

Documento de trabajo que recoge la verificación de la API de SIGA contra las necesidades del **Copiloto de Averías** (`Desarrollos_internos/PJ1544-copiloto-averias`, PRD v0.2). Es el insumo directo de este PRD.

## Decisiones
- **El PRD de la API se organiza por las mismas cinco etapas del PRD de averías**, porque las etapas *son* los bloqueos: cada una está definida por lo que la API no permite hacer todavía.
- **Nada se pide sin verificar.** Pedir una función que ya existe daña la credibilidad del documento completo. De ahí el script de verificación y la regla de interpretación de códigos.
- **Regla de interpretación de códigos de respuesta**, para no pedir de más: **404/405** = verificado que no existe, se puede pedir como función nueva; **403** = existe y está protegida, **nunca** pedirlo como nuevo, a lo sumo pedir acceso para el rol de servicio; **400/422** = existe y valida la entrada, solo documentar el contrato.
- **La etapa 1 no depende de ningún cambio en la API** y puede arrancar de inmediato. Eso es deliberado: el proyecto entrega valor antes de que el equipo de SIGA mueva una línea.
- **Entra el condicionado estructurado** (G19) marcado como de alto valor, no como bloqueo.
- **Entran los webhooks** (G05) como deseables, no bloqueantes.
- **Se piden los 34 huecos**, priorizados y con los bloqueantes marcados, porque no habrá una segunda entrega.

## Alcance / requerimientos
- **34 huecos en 6 grupos**, cada uno mapeado a la etapa que desbloquea: grupo 0 plataforma y transversal (10), grupo 1 lectura del expediente (10), grupo 2 escritura de improcedencia (5), grupo 3 deliberación del caso procedente (4), grupo 4 operación de alta carga (3), grupo 5 operación regional (2).
- **Nueve bloqueantes:** G04 idempotencia, G06 nomenclatura OData, G15 catálogo de motivos, G16 componente y refacciones, G21 resolver una avería, G23 atribución de la decisión, G26 presupuesto desglosado, G27 límites e importes del vehículo, G28 marcar aceptada, G33 APIs de Colombia y Chile.
- **El bloqueo nº 1 es G21**: no existe forma de cambiar el estatus de una avería. `ClaimResponse.statusId` es de respuesta y el único `status` escribible pertenece a `UpdateIssue`, que aplica a incidencias.
- **Plantilla obligatoria para especificar cada hueco:** paso del proceso que lo necesita · por qué es necesario · estado actual verificado · método y ruta · petición · respuesta 200 · errores · permisos · idempotencia · efectos colaterales · criterios de aceptación · consecuencia si no se atiende.
- **Restricciones que la forma de los endpoints debe respetar**, heredadas del PRD de averías: el endpoint de aceptación **debe exigir atribución del humano que aprobó**; el de resolución **debe aceptar la referencia al documento**, porque no puede haber rechazo sin resolución adjunta; y ningún error puede ser silencioso.

## Actores
- **Equipo de desarrollo de SIGA** (Alexis) — destinatario del PRD y único que puede exponer las capacidades faltantes.
- **Orquestador de n8n** — el consumidor principal de la API.
- **Agente de cobertura y agente de presupuesto** — consumidores de lectura; el segundo aparece en la etapa 3.
- **Identidad de servicio** — el sujeto que autentica. Hoy no existe: solo hay login de persona.

## Riesgos / pendientes
- **Doce pendientes de verificación en runtime (V1–V12)**, cada uno con consecuencia distinta según la respuesta. Los que pueden tumbar la etapa 1 si salen mal: **V2** (nomenclatura OData del filtro por folio), **V5** (filtro de contrato por VIN), **V9** (correspondencia entre el folio del correo y el `claimId`) y **V4** (completitud del texto del certificado).
- **V12 puede eliminar un hueco:** `IssueResponse` trae `vinOrPlate`, `odometer` **y** `claimId`. Si el puente incidencia → avería funciona, **G12 desaparece**.
- **Las cuentas de prueba disponibles no son de técnico.** Hay una de taller (`pruebastallergpmx@outlook.com`) y una de distribuidor (`martin.rivero@autocom.mx`). Ambas pueden sufrir filtrado por fila y devolver 403 en endpoints del área técnica. **V13:** pedir a TI una cuenta de técnico o coordinador para QA.
- **Tres pendientes que no resuelve el script** y hay que preguntar a personas: **V10** plan de las APIs de Colombia y Chile (a TI), **V11** si el folio del correo es el que ve el técnico en pantalla (a David Simancas), **V13** cómo se da de alta una identidad de servicio hoy (a TI).
- **Falta confirmar el destinatario y el patrocinador** de la entrega: si el interlocutor es Alexis y quién de EngineCX la respalda.
- **El entorno QA estuvo caído** el 2026-08-27: todo el host devolvía 503 con `server: awselb/2.0`, o sea el balanceador de AWS sin destinos sanos. La verificación quedó pendiente de que vuelva.

## Fechas / hitos
- 2026-08-24 — primera captura de los OpenAPI.
- 2026-08-26 — verificación a nivel de especificación; se confirman los 4 servicios y las ausencias por conteo de cadenas. Se escribe el script de verificación.
- 2026-08-27 — script v2.1 (arreglo del bundle de CA); entorno QA caído; verificación en runtime **pendiente**.
