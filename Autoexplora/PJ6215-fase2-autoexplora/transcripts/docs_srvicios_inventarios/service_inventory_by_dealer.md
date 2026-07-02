# Documentación del Servicio: Inventory by Dealer

## Descripción General
El módulo `inventory_by_dealer` conforma la capa de acceso a datos y lógica de negocio para la consulta de inventarios. Se encarga de recuperar los vehículos asociados a determinados concesionarios, calcular métricas en tiempo real (como vistas en los últimos 30 días y días en stock), determinar si un vehículo es "popular" basándose en tendencias relativas, y formatear el resultado final.

El módulo implementa un patrón estructurado dividiendo la responsabilidad en tres partes principales:
1.  **`InventoryRepository`**: Capa de acceso a datos (Queries a Base de Datos).
2.  **`InventoryService`**: Capa de lógica de negocio (Cálculos y Transformaciones).
3.  **`get_inventory_by_dealer`**: Función orquestadora principal.

---

## Componentes Principales

### 1. Función Orquestadora: `get_inventory_by_dealer`
Es el punto de entrada que interactúa directamente con el controlador.

*   **Parámetros:**
    *   `dealeron_ids` (list): Lista de IDs numéricos/strings del sistema.
    *   `dealer_codes` (list): Lista de códigos de los concesionarios (ej. "MIA").
*   **Retorno:** Un diccionario con el total de vehículos y la lista procesada.
*   **Flujo:** Valida la entrada $\rightarrow$ Solicita datos crudos al Repositorio $\rightarrow$ Manda a procesar los datos al Servicio $\rightarrow$ Retorna el payload final.

### 2. Capa de Acceso a Datos: `InventoryRepository`
Clase estática encargada de interactuar con **SQLAlchemy** para armar y ejecutar la consulta a la base de datos.

#### Método: `fetch_raw_inventory`
Realiza un `select` complejo utilizando `outerjoin` para consolidar información de diferentes tablas.

*   **Subqueries y Cálculos SQL:**
    *   **Vistas (Views):** Genera una subconsulta (`stats_sub`) filtrando la tabla `VehicleViews` para contar las vistas de los últimos **30 días** agrupadas por `vin`. Usa `coalesce` para asignar `0` si no hay vistas.
    *   **Días en Stock (Days in Stock):** Calcula la diferencia entre la fecha actual (`func.current_date()`) y la fecha de activación (`Inventory.last_activated_at`).
*   **Relaciones (Joins):**
    *   Cruza el inventario con `InventoryIntegrationMedia` para obtener las URLs de las fotos 360º.
    *   Cruza el inventario con `Dealer` para obtener el nombre del concesionario y la ubicación (`location` tipo JSON).
*   **Filtrado:** Aplica condiciones `OR` dinámicas dependiendo de si se proporcionaron `dealeron_ids` o `dealer_codes`.

### 3. Capa de Negocio: `InventoryService`
Clase estática encargada de aplicar reglas de negocio y mutar los objetos de base de datos a diccionarios.

#### Método: `calculate_popularity_threshold(results)`
Calcula un umbral dinámico para definir qué vehículos son populares dentro de este conjunto de resultados específicos.
*   **Lógica:** Ordena todas las vistas de mayor a menor y extrae el valor que se encuentra en el **Top 20%** de la lista. (Ej: Si hay 100 vehículos, el umbral será la cantidad de vistas del vehículo en la posición 20).

#### Método: `_format_vehicle_data(row, threshold)`
Transforma el registro crudo (`Row` de SQLAlchemy) en el diccionario final (JSON).
*   **Generación de VDP URL (Slug):** Crea dinámicamente un slug amigable para SEO en minúsculas con el formato: `{year}-{make}-{model}-{trim}-{city}-{vehicle_id}`.
*   **Regla de Popularidad:** Un vehículo se marca como `isPopular: True` si sus vistas superan el umbral del Top 20% **Y** tiene al menos 10 vistas en total.
*   **Transformación JSON:** Llama a `inv.toJson()` y enriquece el payload con:
    *   `locationCode` (Código postal de la ubicación del dealer).
    *   `locationName` (Nombre del dealer).
    *   `totalViews`, `daysInStock`, `photo360UrlList` y `vdpUrl`.

---

## Estructura de Datos de Salida (Output)

La función principal retorna un diccionario con la siguiente estructura:

```json
{
  "totalVehicles": 1,
  "vehicles":[
    {
      "...": "Campos heredados de inv.toJson()",
      "locationCode": "33101",
      "locationName": "Ejemplo Motors Miami",
      "isPopular": true,
      "totalViews": 145,
      "daysInStock": 12,
      "photo360UrlList": ["https://img.url/1", "https://img.url/2"],
      "vdpUrl": "2024-toyota-camry-se-miami-123456"
    }
  ]
}
```