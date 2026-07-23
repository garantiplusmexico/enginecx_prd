# PRD - Omitir Datos Distribuidor Chile

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Omitir Datos Distribuidor Chile |
| **Área / empresa** | Garantiplus Chile |
| **Versión** | v0.1 |
| **Fecha** | 2026-07-23 |
| **Autores** | Alejandro Govea (alejandro.govea@garantiplus.mx) |
| **Revisión / liderazgo** | Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx) |
| **Tipo de proyecto** | Feature web (ajuste de UI) |

## 1. Resumen ejecutivo

El formulario de registro y edición de distribuidores en SIGA para Chile muestra actualmente los campos **Cuenta Bancaria** y **CLABE**. La CLABE (Clave Bancaria Estandarizada) es un identificador bancario **exclusivo de México**, por lo que carece de sentido en Chile; el campo Cuenta Bancaria tampoco forma parte del registro esperado del distribuidor chileno.

Este proyecto **oculta ambos campos en la interfaz de Chile** (vista `_EditCHL` de distribuidores), tanto en el alta (Create) como en la edición (Edit), mejorando la claridad del formulario para la administración local. Es un cambio de bajo esfuerzo y bajo riesgo, enfocado en experiencia de usuario.

El alcance se limita a la **capa de UI para Chile**: **no se eliminan columnas de base de datos** ni se afectan México/Colombia. Los valores ya capturados en distribuidores existentes se conservan intactos en BD.

**Resultado esperado:** un formulario de distribuidor CHL más limpio y coherente con la realidad bancaria local, sin impacto en captación ni fidelización.

Flujo resumido: **Admin abre formulario distribuidor CHL** → **UI oculta Cuenta Bancaria y CLABE** → **Admin completa datos aplicables** → **Guarda (Create/Edit) sin bloqueos**

## 2. Contexto y problema

- **Hoy:** la vista `_EditCHL` de distribuidores renderiza los campos Cuenta Bancaria y CLABE heredados del formulario base (pensado para México). La administración local de Chile los ve aunque no apliquen.
- **Dolor:** campos irrelevantes/confusos en el formulario chileno; la CLABE no existe como concepto bancario en Chile, lo que genera fricción y datos sin sentido.
- **Por qué ahora:** mejora de bajo costo de la experiencia de administración local; alinea el formulario con la operación real de Chile.
- **Distinción de dominio:** **CLABE** = identificador bancario estandarizado **exclusivo de México** (18 dígitos); no tiene equivalente en el registro de distribuidores de Chile.

## 3. Objetivo del producto

Ocultar los campos **Cuenta Bancaria** y **CLABE** en la interfaz de registro y edición de distribuidores de **Chile** (`_EditCHL`), tanto en Create como en Edit, sin eliminar las columnas de base de datos ni afectar a otros países, de modo que el formulario refleje únicamente los datos aplicables a la operación chilena.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Administración local Chile | Registra y edita distribuidores en SIGA para Chile; usuario directo del formulario. |
| Equipo de desarrollo (TI Engine) | Implementa el ocultamiento en la vista `_EditCHL` y valida Create/Edit. |
| Revisión / liderazgo técnico | Valida el alcance y la implementación del ajuste. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Ocultar Cuenta Bancaria en UI CHL | El campo Cuenta Bancaria no se muestra en la vista `_EditCHL` de distribuidores (Create y Edit). |
| Ocultar CLABE en UI CHL | El campo CLABE no se muestra en la vista `_EditCHL` de distribuidores (Create y Edit). |
| Guardado sin bloqueos en CHL | El alta y edición de distribuidor CHL se completan correctamente aun sin capturar Cuenta Bancaria/CLABE. |
| Conservación de datos previos | Los valores ya guardados en distribuidores CHL existentes se mantienen intactos en BD; el ocultamiento es solo visual. |

**Principio rector del MVP:** cambio **exclusivo de UI para Chile**, sin eliminar ni migrar columnas de BD y sin afectar los formularios de México ni Colombia.

## 6. Fuera de alcance

- **Eliminar las columnas Cuenta Bancaria/CLABE de la base de datos:** no se toca el esquema; solo se oculta en UI. Se habilitaría si el negocio confirma que el dato nunca se usará para Chile.
- **Cambios en los formularios de México y Colombia:** el ajuste es específico de Chile; CLABE sigue aplicando en México.
- **Migración o limpieza de datos existentes en CHL:** los valores ya capturados se conservan; no se ejecuta borrado masivo.
- **Rediseño general del formulario de distribuidor:** solo se ocultan estos dos campos, sin reordenar ni rediseñar el resto.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Ocultar Cuenta Bancaria en `_EditCHL` | El campo Cuenta Bancaria no debe renderizarse en la vista de distribuidores de Chile, en alta y edición. |
| RF-02 | Ocultar CLABE en `_EditCHL` | El campo CLABE no debe renderizarse en la vista de distribuidores de Chile, en alta y edición. |
| RF-03 | Create de distribuidor CHL sin campos ocultos | El alta de un distribuidor de Chile debe completarse correctamente sin capturar Cuenta Bancaria ni CLABE. |
| RF-04 | Edit de distribuidor CHL sin campos ocultos | La edición de un distribuidor de Chile debe guardarse correctamente sin exigir ni mostrar Cuenta Bancaria ni CLABE. |
| RF-05 | Conservar valores existentes | Al editar un distribuidor CHL que ya tenga Cuenta Bancaria/CLABE, los valores se conservan en BD (no se limpian por ocultarlos). |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Aislamiento por país | El cambio aplica solo a la vista/flujo de Chile; México y Colombia no se ven afectados. |
| RNF-02 | Integridad de datos | No se eliminan columnas ni datos; el esquema de BD permanece igual. |
| RNF-03 | Consistencia Create/Edit | El comportamiento (campos ocultos, guardado sin bloqueo) debe ser idéntico en alta y edición. |
| RNF-04 | Mantenibilidad | La ocultación debe implementarse de forma clara y localizada en la vista CHL, sin duplicar lógica innecesaria. |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| SIGA — módulo de distribuidores (vista `_EditCHL`) | Lectura/escritura del registro de distribuidor CHL; es donde se ocultan los campos. |
| Base de datos SIGA (columnas Cuenta Bancaria / CLABE) | Se conservan sin cambios de esquema; pueden quedar nulas/vacías en altas nuevas de CHL. |

**Datos mínimos afectados:** columnas de Cuenta Bancaria y CLABE del distribuidor (se mantienen en el modelo; solo se ocultan en la vista de Chile).

**Esquema de permisos:** sin cambios respecto al actual — los mismos roles que hoy administran distribuidores CHL siguen operando; no se agregan ni bloquean permisos.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Campos ocultos correctamente | Cuenta Bancaria y CLABE no aparecen en `_EditCHL` (verificación funcional en Create y Edit). |
| Alta/edición CHL sin errores | 0 errores de guardado en Create/Edit de distribuidor CHL tras el cambio. |
| Sin regresión en otros países | Formularios de México y Colombia siguen mostrando los campos y guardando sin cambios. |

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| Validación server-side exige CLABE/Cuenta como obligatorias | El guardado de CHL podría bloquearse si el modelo valida esos campos como requeridos; requiere hacerlos opcionales para CHL. |
| Lógica compartida entre países | Si la vista/validación es común, ocultar en CHL podría afectar México/Colombia si no se aísla bien. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| Existe una vista específica de Chile | El formulario CHL se maneja en una vista `_EditCHL` separable de la de otros países. |
| Las columnas admiten valores vacíos/nulos | La BD acepta registros CHL sin Cuenta Bancaria/CLABE sin romper integridad. |
| Datos previos se conservan | Los valores ya capturados en CHL permanecen en BD tras el cambio. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Validación | ¿Cuenta Bancaria y CLABE son obligatorios hoy en la validación server-side del distribuidor? Si lo son, ¿se deben volver opcionales solo para CHL? |
| Alcance de la vista | ¿`_EditCHL` es exclusiva de Chile o comparte parciales/validación con México/Colombia? |
| Nulabilidad en BD | ¿Las columnas Cuenta Bancaria/CLABE admiten NULL/vacío para altas nuevas de CHL sin efectos colaterales? |
