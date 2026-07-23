# PRD - Estado Colonia Chile

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Estado Colonia Chile |
| **Área / empresa** | Garantiplus Chile |
| **Versión** | v0.1 |
| **Fecha** | 2026-07-23 |
| **Autores** | Operaciones / Chile (solicitante) |
| **Revisión / liderazgo** | Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web/API |

## 1. Resumen ejecutivo

Estado Colonia Chile es un ajuste de **localización de nomenclatura** para los reportes de contratos de **Garantiplus Chile**. Hoy el reporte descargable (Excel/CSV) y algunas vistas de la aplicación muestran etiquetas con nomenclatura mexicana —"Estado Beneficiario", "Colonia" y "RFC"— que no corresponden a la terminología administrativa chilena.

El MVP consiste en **renombrar esas etiquetas únicamente para Chile (PaisCL)**: `Estado Beneficiario → Región Beneficiario`, `Colonia → Comuna` y `RFC → RUT`, tanto en el export de contratos como en las vistas en pantalla donde aparezcan. Los reportes y vistas de México y Colombia **no se modifican**.

Es un cambio de **capa de presentación** (solo etiquetas/encabezados), sin alterar datos, modelo ni lógica de negocio. Su importancia es baja y su impacto es de **Administración / Reportes**: mejora la claridad de los reportes internos en Chile, sin impacto para clientes finales.

**Reporte de contratos Chile** → **detección de etiquetas MX** → **renombrado condicionado a PaisCL** → **export/vista con nomenclatura local**

## 2. Contexto y problema

- **Hoy:** el reporte de contratos se genera de forma compartida entre países; para Chile hereda encabezados en nomenclatura mexicana ("Estado Beneficiario", "Colonia", "RFC"), presentes principalmente en los archivos de descarga/exportación (Excel/CSV) y en algunas vistas.
- **Dolor:** la terminología no corresponde a la administración chilena, lo que resta claridad a los reportes internos del equipo de Operaciones/Administración de Chile.
- **Por qué ahora:** es una mejora de bajo esfuerzo que alinea los reportes con la nomenclatura local; no hay dependencia crítica pero mejora la operación diaria.
- **Distinción de dominio (MX → CL):** `Estado Beneficiario → Región Beneficiario`; `Colonia → Comuna`; `RFC → RUT`. El cambio es de etiqueta de presentación, no de significado del dato subyacente.

## 3. Objetivo del producto

Alinear la nomenclatura de los reportes y vistas de contratos de **Garantiplus Chile** con la terminología administrativa local, renombrando los encabezados/etiquetas afectados **solo para el país Chile (PaisCL)**, sin afectar a México ni Colombia y sin modificar los datos ni la lógica de generación del reporte.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Operaciones / Administración (Chile) | Solicitante y consumidor de los reportes; valida que la nomenclatura sea correcta |
| Equipo de Reportes / BI (Chile) | Usa los exports de contratos para análisis interno |
| Desarrollo (TI Engine) | Implementa el renombrado condicionado por país |
| Alexis Salvador Herrera Garcia | Revisión técnica del cambio |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Renombrado en export (Excel/CSV) | En el reporte de contratos de Chile (PaisCL), los encabezados cambian: "Estado Beneficiario"→"Región Beneficiario", "Colonia"→"Comuna", "RFC"→"RUT" |
| Renombrado en vistas en pantalla | En las vistas/pantallas de la app para Chile donde aparezcan, "Estado Beneficiario"→"Región Beneficiario" y "Colonia"→"Comuna" |
| Aislamiento por país | El cambio se aplica condicionado a Chile (PaisCL); los exports y vistas de México y Colombia permanecen sin cambios |

**Principio rector del MVP:** es un cambio de **presentación** localizado por país. No debe alterar los datos, el modelo, la lógica del reporte ni la nomenclatura de otros países.

## 6. Fuera de alcance

- **Modificar exports/vistas de México y Colombia:** el cambio es exclusivo de Chile; tocar otros países rompería su nomenclatura vigente.
- **Cambios en el modelo de datos o en los nombres de columnas de base de datos:** solo se ajustan etiquetas de presentación, no la estructura de datos.
- **Rediseño del reporte de contratos o nuevos campos:** fuera de esta versión; solo se renombran las tres etiquetas indicadas.
- **Traducción/localización integral de la app para Chile:** este PRD cubre únicamente las tres etiquetas señaladas, no una localización completa.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Encabezado "Región Beneficiario" en export CL | El export Excel/CSV de contratos de Chile muestra "Región Beneficiario" donde antes decía "Estado Beneficiario" |
| RF-02 | Encabezado "Comuna" en export CL | El export Excel/CSV de contratos de Chile muestra "Comuna" donde antes decía "Colonia" |
| RF-03 | Encabezado "RUT" en export CL | El export Excel/CSV de contratos de Chile muestra "RUT" donde antes decía "RFC" |
| RF-04 | Etiquetas en vistas CL | Las vistas en pantalla de Chile muestran "Región Beneficiario" y "Comuna" en lugar de "Estado Beneficiario" y "Colonia" |
| RF-05 | Aislamiento por país | Los exports y vistas de México y Colombia no se ven afectados; el renombrado está condicionado a PaisCL |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Aislamiento por país | El cambio debe estar condicionado a Chile (PaisCL) sin efectos colaterales en MX/CO |
| RNF-02 | Sin impacto en datos | Solo se modifica la capa de presentación (encabezados/etiquetas); no se altera la data, el modelo ni la lógica del reporte |
| RNF-03 | Mantenibilidad | Preferir centralizar las etiquetas por país para facilitar futuros ajustes de nomenclatura |
| RNF-04 | Trazabilidad | El cambio queda versionado y documentado (revisión técnica de Alexis Herrera) |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| SIGA — SP `sp_reporte_contratos` | Validar si los encabezados provienen del stored procedure o de la capa de aplicación/export |
| Reporte de contratos (Excel/CSV) | Artefacto de salida afectado por el renombrado |
| Vistas de la app (Chile) | Pantallas donde aparecen las etiquetas a renombrar |

**Datos mínimos involucrados:** campos de presentación "Estado Beneficiario", "Colonia" y "RFC" (solo su etiqueta visible). No cambia el modelo de datos ni el contenido de las columnas.

**Esquema de permisos:** cambio de solo presentación; no modifica lectura/escritura de datos ni introduce nuevos accesos. No requiere validación humana adicional más allá de la revisión técnica.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Nomenclatura correcta en CL | 0 reportes/vistas de Chile mostrando "Estado Beneficiario", "Colonia" o "RFC" tras el despliegue |
| Sin regresión en MX/CO | 0 cambios en la nomenclatura de exports/vistas de México y Colombia |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Headers provenientes de múltiples fuentes (SP + capa de app) | Cambiar solo una fuente dejaría la nomenclatura inconsistente |
| Afectar por error exports/vistas de MX/CO | Rompería la nomenclatura vigente de otros países |
| Consumidores/parsers downstream que dependan de los nombres actuales de columnas | Un cambio de encabezado podría romper procesos que leen el archivo por nombre de columna |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Existe discriminación por país (PaisCL) | El reporte/vistas permiten condicionar la presentación por país |
| Cambio solo de presentación | Renombrar etiquetas no altera datos ni lógica de negocio |
| Sin consumidores externos | No hay clientes externos que dependan de los encabezados actuales |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Origen de headers | ¿Los encabezados provienen del SP `sp_reporte_contratos` o de la capa de aplicación/export? |
| Alcance en vistas | ¿En las vistas en pantalla también aplica RFC→RUT, o solo Estado→Región y Colonia→Comuna? |
| Consumidores downstream | ¿Existen parsers/integraciones que lean el reporte por nombre de columna y puedan romperse? |
| Vistas afectadas | ¿Qué pantallas/vistas específicas, además del export, muestran estas etiquetas en Chile? |
| Fecha objetivo | ¿Hay una fecha/prioridad de entrega comprometida? |
