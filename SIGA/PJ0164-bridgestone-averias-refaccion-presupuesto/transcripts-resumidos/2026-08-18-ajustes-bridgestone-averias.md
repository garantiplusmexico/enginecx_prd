# Condensado — 2026-08-18-ajustes-bridgestone-averias

## Decisiones
- PRD en versión reducida (ajuste menor a módulo existente): se omiten secciones 7 (Flujos) y 11 (Eventos BI).
- Los bloqueos aplican SOLO en la captura del distribuidor/taller: `_RefaccionesServiciosDealer.cshtml` y `_PresupuestoDealer.cshtml`.
- En Bridgestone se oculta por completo la mano de obra en esa pantalla: campo "Servicio", campo "M.O." y tabla "Servicios (Mano de obra)".
- "Llanta" (catálogo `refaccion`) e "I.V.A. cero" (catálogo `impuesto`) se determinan por **ID configurado**, no por nombre ni por porcentaje.
- Campos ocultos se persisten como vacío/cero: `no_parte` null/vacío y `mano_obra` = 0.00.
- El bloqueo se aplica en UI **y** se valida en servidor (`AddSpareDealer`, `AssignBudget`).
- La tabla "Servicios" se muestra (solo lectura) únicamente si la avería ya trae M.O. capturada.
- Encabezado: autor Javier Antonio Oropeza; revisión Aldo Álvarez (Director de TI).

## Alcance / requerimientos
- Bridgestone atiende únicamente llantas; el módulo de Averías debe reflejarlo cuando el proyecto seleccionado es Bridgestone.
- Sección "Refacciones y mano de obra": "Tipo" fijo en "Refacción" (solo lectura); "Refacción" fijo en "Llanta" (solo lectura); "Refacción" se habilita/llena a partir de "Tipo".
- Ocultar los campos "No. de parte" y "M.O.".
- Sección "Presupuesto": el selector de impuesto siempre en "I.V.A. cero", solo lectura.
- Ningún otro proyecto cambia de comportamiento.

## Actores
- Distribuidor / taller Bridgestone: captura refacciones y presupuesto de la avería.
- Administrador de averías Garantiplus: revisa y aprueba (su vista no cambia).
- TI Garantiplus México: implementa y parametriza los IDs.

## Riesgos / pendientes
- Falta confirmar el `id_refaccion` de "Llanta" y el `id_impuesto` de "I.V.A. cero" en el catálogo de México.
- Falta definir dónde se parametrizan esos IDs (constante en `PaisMX` vs. tabla de configuración).
- Averías Bridgestone previas con M.O. capturada: montos siguen sumando al presupuesto.

## Contexto técnico detectado en el repo
- Existe `PaisMX.BridgestoneProjectId = 173` y el precedente `ClaimBudgetRequirements` / `ViewBag.IsBmwUat` (config por proyecto) en `PaisesService/Classes/MX/PaisMX.cs`.
- El "selector de presupuesto" es el selector de impuesto `id_impuesto` (catálogo `impuesto`, filtrado por país).
