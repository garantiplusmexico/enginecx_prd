# Condensado — Omar André _ Gustavo Ivan - 2026_07_06 16_02 CST - Transcript

## Decisiones
- Se construirá un flujo de N8N que lea el correo `minutas@galanic.mx` (buzón de Google Workspace) vía trigger de "correo entrante" (no polling).
- Cada minuta recibida se tipificará: quién la mandó, hacia quién, participantes, asuntos y acuerdos, más un resumen generado por el bot.
- El resultado se centralizará en un Google Sheets, con un resumen sencillo por minuta.
- Gustavo ya tiene usuario/contraseña del correo de minutas y se los compartió a Omar por WhatsApp.

## Alcance / requerimientos
- Fuerza de ventas de Alfa: cada gerente KS (y similares) debe enviar una minuta por cada visita a un punto de venta, con copia a `minutas@galanic.mx`.
- Métrica 1 (cobertura): medir, por gerente, cuántas visitas a puntos de venta tuvieron minuta enviada vs. cuántas no (ej. "Iván visitó 10 puntos de venta y mandó 9 minutas").
- Métrica 2 (desfase de tiempo): la minuta debería enviarse el mismo día de la visita; se busca medir el desfase entre fecha/hora de la visita y fecha/hora de envío de la minuta.
- Corte de reporte: quincenal o semanal, aún sin definir.
- Visibilidad del Google Sheets: Israel y sus gerentes (para dar seguimiento a quién no manda minutas), posiblemente también finanzas.
- Prioridad: se busca tener el flujo funcionando antes de la próxima quincena, para cuando pidan el reporte de dirección.

## Actores
- Gustavo Ivan Carreto Abascal — impulsa el requerimiento, contacto para credenciales del correo de minutas, reporta a dirección.
- Omar André Lara Saldaña — desarrollador del flujo N8N.
- Israel — líder de la fuerza de ventas de Alfa; consumidor principal del reporte/Sheets.
- Gerentes KS y equipo de fuerza de ventas — generan las minutas que se procesan.
- Finanzas (posible) — visibilidad adicional del Sheets.
- Aldo — pendiente de plática para definir cómo medir el desfase de tiempo visita↔minuta.

## Riesgos / pendientes
- No está definido cómo "machar" (cruzar) la fecha/hora de la visita contra la fecha/hora de envío de la minuta cuando hay desfase de horas o incluso días — pendiente de plática con Aldo.
- No está definida la periodicidad exacta del reporte (semanal vs. quincenal).
- Mencionan la posibilidad de conectar vía MCP para crear una API (Gustavo vio APIs ya creadas que podrían reutilizarse) — sin decidir aún si aplica a este flujo.
- Tema aparte (fuera de este PRD): validación de facturas/actualización de contratos de póliza, mencionado de pasada por Gustavo con Shirley/Dani — no forma parte del alcance de minutas.

## Fechas / hitos
- Transcript de la reunión: 2026-07-06.
- Meta informal: tener el flujo con datos antes de la próxima quincena, para el reporte de dirección.
