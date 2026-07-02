# Documentación del Servicio: Inventory & Media Integrations

## Descripción General
Este módulo proporciona los servicios de base de datos para la gestión del inventario centralizado y sus medios enriquecidos. Utiliza **SQLAlchemy Core** (con la extensión de dialecto de PostgreSQL) para ejecutar operaciones masivas de inserción y actualización (UPSERTs) de manera altamente eficiente, garantizando la integridad de los datos transaccionales. Además, provee utilidades para la carga de archivos hacia Amazon S3.

El módulo está compuesto por dos clases principales:
1.  **`InventoryServiceIntegrationsMedia`**: Maneja la inserción de URLs externas de multimedia (ej. SpinCar 360).
2.  **`InventoryService`**: Maneja el ciclo de vida del inventario en la base de datos central, controlando la activación/inactivación de vehículos por feed.

---

## Componente 1: `InventoryServiceIntegrationsMedia`

Servicio dedicado exclusivamente a interactuar con la tabla `inventory_integrations_media`. Implementa un patrón *Singleton* interno (`_table`) para evitar reflejar (autoload) la estructura de la tabla en cada instanciación.

### Método: `bulk_update_360_urls`

Actualiza o inserta de forma masiva los registros de URLs de fotografías en 360 grados.

#### Parámetros
*   `data` (List[dict]): Lista de diccionarios que contiene la información multimedia extraída.
*   `provider` (str, opcional): El proveedor de las imágenes. Por defecto es `"spincar"`.

#### Flujo de Ejecución (Workflow)
1.  **Deduplicación:** Recorre la lista entrante y utiliza un diccionario temporal (`clean_dict`) usando el `vin` como llave. Si existen múltiples filas para el mismo VIN en el payload, **solo conserva la última**, evitando errores de conflicto en la BD.
2.  **Segmentación (Chunking):** Divide la data limpia en bloques de **500 registros** usando la función de utilidad `chunker`. Esto previene el sobrepaso de los límites de memoria de la base de datos (Out Of Memory) en envíos masivos.
3.  **UPSERT vía PostgreSQL (`pg_insert`):** Utiliza una cláusula nativa de Postgres `ON CONFLICT DO UPDATE`. 
    *   Si la combinación `['vin', 'provider']` no existe, hace un `INSERT`.
    *   Si ya existe, actualiza únicamente los campos `photo_360_url_list` y `updated_at`.
4.  **Respuesta:** Devuelve un diccionario indicando el estatus (`success` / `error`) y el número total de filas afectadas.

---

## Componente 2: `InventoryService`

Servicio principal para el manejo del inventario físico. Interactúa con la tabla `inventory`.

### Método: `bulk_insert`

Sincroniza el feed de un concesionario utilizando un patrón de **Soft Delete / Upsert**. 

#### Parámetros
*   `data` (List[dict]): Lista de diccionarios validados con la información de los vehículos.
*   `inventory_id` (str): Identificador único del feed que se está procesando.

#### Flujo de Ejecución (Workflow)
1.  **Deduplicación:** Elimina los vehículos repetidos dentro del mismo bloque de datos utilizando la función auxiliar interna `remove_duplicates` (evaluando por la clave primaria natural `vin`).
2.  **Inicio de Transacción (`engine.begin()`):** Todo el proceso ocurre en un bloque transaccional. Si el script falla a mitad de camino, se realiza un `ROLLBACK` automático.
3.  **Inactivación Previa:** Ejecuta un `UPDATE` masivo que cambia la columna `status` a `'inactive'` para todos los registros existentes en la tabla que coincidan con este `inventory_id`. *Esto limpia el inventario de vehículos que ya no vienen en el nuevo archivo.*
4.  **Preparación del Lote:** En bloques de **500**, fuerza que los registros entrantes tengan `status = 'active'` y el `inventory_id` correspondiente.
5.  **UPSERT Dinámico:** 
    *   Utiliza `pg_insert(self.table)`.
    *   Genera un diccionario (`update_dict`) iterando dinámicamente sobre todas las columnas de la tabla (excepto Primary Keys) para saber cuáles actualizar.
    *   Configura el `ON CONFLICT (vin) DO UPDATE SET ...` para aplicar los cambios si el VIN ya existe, o insertarlos si es nuevo.
6.  **Commit:** Confirma la transacción y devuelve el resultado.

### Métodos Auxiliares para S3
Esta clase también actúa como un adaptador (Wrapper) hacia las utilidades de almacenamiento.
*   **`upload_feed_to_bucket(file_obj, object_key)`**: Envía un flujo de bytes a un bucket S3.
*   **`get_presigned_url(object_key)`**: Genera y retorna un string con una URL prefirmada temporal para subir objetos a S3 directamente.

---

## Notas para Desarrolladores y Arquitectura

1.  **Dialecto Específico de BD:**
    *   El uso de `from sqlalchemy.dialects.postgresql import insert as pg_insert` amarra este código estrictamente a **PostgreSQL**. Si en el futuro se migra a MySQL o SQL Server, la lógica del `on_conflict_do_update` deberá reescribirse para ese motor.
2.  **Lógica de Inactivación (Bulk Sync):**
    *   El método de establecer el inventario previo a "inactivo" y reinsertar/actualizar como "activo", es una solución excelente y performante para los sincronizadores nocturnos de feeds. Elimina la necesidad de calcular manualmente "Qué se insertó / Qué se borró / Qué se actualizó".
3.  **Bloqueos de Base de Datos (Table Locks):**
    *   En el método `bulk_insert`, el `update` masivo inicial inactiva todas las filas con un `inventory_id`. Durante feeds muy pesados (miles de vehículos), asegúrate de tener índices en las columnas `inventory_id` y `vin` para evitar bloqueos secuenciales prolongados que puedan afectar consultas de lectura simultáneas en la API web.