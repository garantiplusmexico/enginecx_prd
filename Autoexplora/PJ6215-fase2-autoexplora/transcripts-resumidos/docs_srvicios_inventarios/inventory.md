# Condensado — docs_srvicios_inventarios/inventory.md

## Decisiones
- La sincronización del feed de un concesionario usa un patrón transaccional de "Soft Delete / Upsert": primero inactiva (status='inactive') TODOS los registros existentes de ese `inventory_id`, luego reinserta/actualiza en lotes de 500 los vehículos del nuevo archivo como 'active' vía `ON CONFLICT (vin) DO UPDATE`. Si el proceso falla a mitad de camino, hace ROLLBACK automático — nunca deja el inventario en estado inconsistente.
- Este patrón elimina la necesidad de calcular manualmente qué se insertó/borró/actualizó en cada corrida del feed.
- Las URLs de fotos 360° (proveedor por defecto "spincar") se manejan en una tabla separada (`inventory_integrations_media`), también con UPSERT por combinación `[vin, provider]`; si llegan varias filas para el mismo VIN en un mismo envío, solo se conserva la última.
- Ambos procesos de carga masiva usan chunking de 500 registros para evitar errores de memoria (OOM) en la base de datos.

## Alcance / requerimientos
- `InventoryService.bulk_insert(data, inventory_id)`: sincroniza el feed completo de un dealer/inventario.
- `InventoryServiceIntegrationsMedia.bulk_update_360_urls(data, provider)`: actualiza URLs de fotos 360.
- Utilidades de S3: `upload_feed_to_bucket` (sube el archivo del feed) y `get_presigned_url` (URL prefirmada temporal para subida directa).

## Riesgos / pendientes
- El código está estrictamente amarrado a PostgreSQL (`sqlalchemy.dialects.postgresql.insert`); una futura migración de motor de base de datos requeriría reescribir toda la lógica de `ON CONFLICT DO UPDATE`.
- En feeds muy pesados (miles de vehículos), el UPDATE masivo de inactivación al inicio del proceso puede generar bloqueos de tabla prolongados si no hay índices adecuados en `inventory_id` y `vin` — riesgo de afectar lecturas simultáneas desde la API web durante la sincronización.

## Componentes técnicos involucrados
- `InventoryServiceIntegrationsMedia` (tabla `inventory_integrations_media`), `InventoryService` (tabla `inventory`), SQLAlchemy Core con dialecto PostgreSQL, Amazon S3 (carga de archivos de feed).
