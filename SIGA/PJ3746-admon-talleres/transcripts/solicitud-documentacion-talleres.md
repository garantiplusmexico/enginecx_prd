# Contexto inicial — admon-talleres (documentación obligatoria de talleres)

**Fuente:** aportado por el solicitante en el chat de /pm-prd (2026-07-21).

## Problema
Los talleres se pueden registrar con información mínima, sin documentación de soporte suficiente.

## Notas / dependencias
OK, SOLAMENTE HAY TEMA DE ANÁLISIS DE LA CUENTA BANCARIA PARA SU ACTUALIZACIÓN.

## Mejora propuesta
Solicitar documentos obligatorios al registrar un taller: RUT, Cámara de Comercio, brochure, descuentos pactados y cuenta bancaria.

## Consideraciones para el desarrollo
Análisis pendiente de cuenta bancaria para actualización (nota del documento); definir documentos obligatorios: RUT, Cámara de Comercio, brochure, descuentos, cuenta bancaria; crear modelo/tabla de documentos de taller y almacenamiento S3; integrar validaciones en flujo de registro y aprobación de taller.

## Motivo de la estimación
Hoy no existe carga de documentos en el registro público ni en la solicitud de taller. Requiere modelo de datos, endpoints upload, UI con validaciones y flujo de aprobación.

## Importancia e impacto de negocio
Importancia: Alta | Impacto: Reducción de riesgo | Administración operativa | Exige documentación al registrar talleres; reduce riesgo de proveedores no confiables y mejora calidad de la red de servicio.

## Pitch ejecutivo (gerencia/inversionistas)
Exige documentación al registrar talleres; reduce riesgo de proveedores no confiables en la red.
