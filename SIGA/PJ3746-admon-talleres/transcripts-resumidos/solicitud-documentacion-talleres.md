# Condensado — solicitud-documentacion-talleres

## Decisiones
- Exigir documentos obligatorios al registrar un taller: RUT, Cámara de Comercio, brochure, descuentos pactados y cuenta bancaria.

## Alcance / requerimientos
- Definir el conjunto de documentos obligatorios del taller.
- Crear modelo/tabla de documentos de taller.
- Almacenamiento de archivos en S3.
- Endpoints de upload de documentos.
- UI con validaciones (no permitir registro/aprobación sin documentación completa).
- Integrar validaciones en el flujo de registro y aprobación del taller.
- Hoy NO existe carga de documentos ni en el registro público ni en la solicitud de taller (se construye desde cero).

## Actores
- Solicitante del PRD (gerencia/administración operativa de la red de talleres).
- Talleres (proveedores que se registran).
- Área que aprueba talleres (flujo de aprobación).

## Riesgos / pendientes
- Análisis PENDIENTE de la cuenta bancaria para su actualización (única dependencia abierta señalada).
- Riesgo de proveedores no confiables si no se exige documentación (motiva el proyecto).
- Posible inconsistencia de región: RUT + Cámara de Comercio son conceptos de Colombia; la unidad configurada es Garantiplus México (a confirmar).

## Fechas / hitos
- (No especificadas.)

## Importancia / impacto
- Importancia: Alta. Impacto: reducción de riesgo y mejora de calidad de la red de servicio.
