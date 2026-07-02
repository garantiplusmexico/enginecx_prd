# Condensado — docs_srvicios_inventarios/service_inventory_by_dealer.md

## Decisiones
- La consulta de inventario por dealer (`get_inventory_by_dealer`) separa responsabilidades en 3 capas: `InventoryRepository` (acceso a datos/queries), `InventoryService` (lógica de negocio/cálculos) y la función orquestadora.
- Un vehículo se marca como `isPopular: true` solo si sus vistas de los últimos 30 días superan el umbral del Top 20% del conjunto de resultados **Y** tiene al menos 10 vistas totales (doble condición, no solo relativa).
- La URL de la ficha de vehículo (VDP) se genera dinámicamente como slug SEO: `{year}-{make}-{model}-{trim}-{city}-{vehicle_id}`, en minúsculas — esto es la base técnica real de las URLs con tokens dinámicos descritas en el contexto técnico de SEO.
- "Días en stock" se calcula en la misma query como diferencia entre la fecha actual y `last_activated_at` (no es un campo estático, se computa en tiempo real).

## Alcance / requerimientos
- Parámetros de entrada: `dealeron_ids` y/o `dealer_codes` (filtrado OR dinámico).
- El resultado enriquece cada vehículo con: `locationCode`, `locationName` (del dealer, vía join), `totalViews`, `daysInStock`, `photo360UrlList` (join con `InventoryIntegrationMedia`) y `vdpUrl`.
- Salida: `{ totalVehicles, vehicles: [...] }`.

## Riesgos / pendientes
- El umbral de "popularidad" es relativo al conjunto de resultados consultado (Top 20% de ESE query), no un valor absoluto global — dos consultas con distinto universo de vehículos pueden marcar como "popular" cosas distintas; relevante si se usa este flag para features de cara al usuario (ej. tags de inventario).

## Componentes técnicos involucrados
- `InventoryRepository.fetch_raw_inventory` (SQLAlchemy, outerjoin, subquery de vistas 30 días vía tabla `VehicleViews`), `InventoryService.calculate_popularity_threshold`, `InventoryService._format_vehicle_data`, tabla `Dealer` (nombre/ubicación), tabla `InventoryIntegrationMedia` (fotos 360).
