# PRD - Plataforma de Inspección de Vehículos — Grupo Cofiño

|**Campo**|**Detalle**|
|-|-|
|**Proyecto**|Plataforma de Inspección de Vehículos — Grupo Cofiño|
|**Área / empresa**|Invarat|
|**Versión**|v0.3|
|**Fecha**|2026-06-29|
|**Autores**|Rodolfo Maldonado|
|**Revisión / liderazgo**|Pendiente de confirmar (¿Aldo Álvarez como Director de TI?)|
|**Tipo de proyecto**|Feature web / API|

> \\\\\\\*\\\\\\\*Nota de versión (v0.3).\\\\\\\*\\\\\\\* Integra la reunión Invarat–Grupo Cofiño del 2026-06-18. Cambios
> principales respecto a v0.2: (1) se elimina la carga de evidencia fotográfica \\\\\\\*\\\\\\\*por elemento\\\\\\\*\\\\\\\*
> del checklist; las fotos se toman en el peritaje y se agrupan \\\\\\\*\\\\\\\*por categoría\\\\\\\*\\\\\\\*; (2) se registra
> como estrategia de implementación la \\\\\\\*\\\\\\\*reutilización del flujo de videoperitaje existente\\\\\\\*\\\\\\\*
> (rebranding Grupo Cofiño); (3) se suaviza el supuesto de región (México) por la mención de
> \\\\\\\*\\\\\\\*Guatemala\\\\\\\*\\\\\\\*. La sección \\\\\\\*\\\\\\\*11 (Eventos para BI) se omite\\\\\\\*\\\\\\\* intencionalmente por ser un proyecto
> tipo B (Feature web/API) sin eventos de BI en el MVP; la numeración canónica se conserva.

\---

## 1\. Resumen ejecutivo

La Plataforma de Inspección de Vehículos de Grupo Cofiño es una aplicación web operada por Invarat que permite a sus colaboradores realizar inspecciones físicas de vehículos seminuevos de forma unificada, eliminando la doble captura de información que hoy existe entre dos plataformas distintas (valuaciones y videoperitajes). La plataforma está dirigida a los inspectores/peritos de Invarat que operan para el cliente Grupo Cofiño, y al público general que necesita consultar la validez de un vehículo inspeccionado.

El problema actual es que el proceso de inspección requiere que el perito registre la información del vehículo y cargue fotografías en dos sistemas separados: primero en la plataforma de valuaciones de Invarat y luego en la plataforma de videoperitajes, donde se genera el reporte final. Esta duplicidad genera fricción operativa, aumenta el tiempo de inspección y eleva el riesgo de inconsistencias entre ambos registros. Adicionalmente, la llegada de Grupo Cofiño como cliente nuevo requiere una plataforma con su propia identidad de marca. La solución se apoya en el **flujo de videoperitaje ya existente** (el mismo que opera para otros clientes), rebrandeado para Grupo Cofiño; el detalle de cómo se construye técnicamente se define en la planeación, no en este PRD.

El MVP contempla el flujo completo de inspección en una sola plataforma: captura de datos del vehículo, llenado del checklist (Pasa / No pasa / No aplica por elemento), registro de evidencia fotográfica **agrupada por categoría** resaltando los daños, generación automática del reporte de inspección y del certificado de validez, y un portal público de consulta por VIN mediante código QR. No se contempla integración con sistemas externos ni módulos de analítica en esta versión.

El resultado esperado es reducir el tiempo operativo del proceso de inspección al eliminar la doble captura, ofrecer a Grupo Cofiño una plataforma con su propia identidad de marca, y dar al cliente final un mecanismo confiable y accesible (QR + VIN) para verificar la validez de su vehículo en cualquier momento.

**\[Datos del vehículo]** → **\[Checklist por categoría + fotos de daños]** → **\[Revisión y cierre de inspección]** → **\[Generación de reporte + certificado PDF]** → **\[Consulta pública vía QR + VIN]**

\---

## 2\. Contexto y problema

**Proceso actual:** El perito de Invarat realiza la inspección física del vehículo en dos etapas en plataformas distintas. Primero accede a la plataforma de valuaciones de Invarat, donde registra los datos del vehículo y llena un checklist por categorías, cargando fotografías como evidencia. Posteriormente, accede a la plataforma de videoperitajes, donde vuelve a capturar los datos del vehículo y las imágenes para generar el reporte de inspección en PDF. En ocasiones el perito se apoya en personal interno o externo que toma las fotografías en vivo a través de la liga de videoperitaje, sin necesidad de tener un usuario propio en el sistema.

**Dolor concreto:** La doble captura representa un proceso redundante que duplica el tiempo del perito, aumenta el riesgo de inconsistencias entre ambos registros y genera dependencia de dos herramientas con formatos e identidades visuales que no corresponden a Grupo Cofiño como cliente ni a Invarat.

**Driver de negocio:** La incorporación de Grupo Cofiño como cliente nuevo —y con tiempo de entrega ajustado— exige una plataforma con identidad de marca propia para los documentos generados (reporte y certificado). No es viable adaptar las plataformas actuales compartidas para cumplir este requerimiento, por lo que se opta por **reutilizar y rebrandear el flujo de videoperitaje existente** como base operativa.

**Distinción clave para el equipo de desarrollo:**

* **Reporte de inspección:** documento técnico detallado que muestra el resultado de cada elemento evaluado (Pasa / No pasa / No aplica) con las fotografías de evidencia agrupadas por categoría. Es el documento operativo de la inspección.
* **Certificado de validez:** documento ejecutivo dirigido al cliente final, que resume el resultado general de la inspección y contiene el código QR para consulta pública. Es el documento comercial/legal que se entrega al comprador del vehículo.

\---

## 3\. Objetivo del producto

Desarrollar una plataforma web con identidad visual de Invarat/Grupo Cofiño que permita a los peritos realizar el proceso completo de inspección de vehículos en un solo sistema, desde la captura de datos y evidencia fotográfica hasta la generación de los documentos oficiales (reporte de inspección y certificado de validez), disponibles para descarga directa y consulta pública mediante código QR + VIN. La mejora esperada es la eliminación total de la doble captura y la unificación del flujo operativo en una sola herramienta, reduciendo el tiempo por inspección y garantizando consistencia en la información.

\---

## 4\. Usuarios y actores

|**Usuario / Actor**|**Rol en el proceso**|
|-|-|
|Colaborador de Invarat (Inspector / Administrador)|Realiza la inspección: captura datos del vehículo, llena el checklist, registra fotografías y genera los documentos PDF. También administra la plataforma: gestiona usuarios, consulta historial de inspecciones. Es el mismo perfil con doble función ("todólogo").|
|Personal de apoyo interno/externo|Apoya ocasionalmente la toma de fotografías en vivo conectándose a la liga del videoperitaje. No tiene usuario propio: el perito permanece conectado y administra la sesión. No accede directamente al sistema.|
|Consultor público (cliente final u otra persona con el VIN)|Accede a la plataforma pública sin necesidad de login, ingresa el VIN tras escanear el QR del certificado, y descarga el reporte de inspección y/o el certificado de validez.|

\---

## 5\. Alcance MVP y funcionalidades

|**Funcionalidad**|**Descripción**|
|-|-|
|Gestión de inspecciones|El colaborador puede crear una nueva inspección capturando los datos administrativos y del vehículo: VIN, marca, modelo, versión, año, color exterior, color interior, kilometraje, placas, tipo de combustible, motor, agencia/distribuidor, lugar de verificación, municipio, estado y nombre del perito asignado. Cada inspección se asocia a un folio de videoperitaje.|
|Checklist de inspección por categorías|La inspección incluye un checklist basado en el reporte de inspección de Invarat, organizado en categorías y subcategorías con sus elementos predefinidos. El perito evalúa cada elemento con una de tres opciones: **Pasa**, **No pasa** o **No aplica**. Los elementos marcados como "Requiere validación" se muestran con esa etiqueta visible en el checklist y en el reporte. Ver detalle de categorías y elementos en RF-04.|
|Registro de evidencia fotográfica por categoría|Las fotografías se toman durante el peritaje (en vivo o cargadas) y se agrupan **por categoría** (documentación, carrocería, etc.), no por cada elemento individual del checklist. El criterio operativo es **resaltar los daños**, no etiquetar todos los elementos. Las imágenes agrupadas se incluyen en el reporte PDF bajo su categoría.|
|Sección de Faltantes|Al final del checklist, el perito puede agregar una lista libre de conceptos faltantes detectados durante la inspección (sin costo asociado). Esta sección aparece en el reporte PDF.|
|Generación de reporte de inspección PDF|Al guardar la inspección, el sistema genera automáticamente un reporte PDF con la identidad visual de Invarat/Grupo Cofiño. El reporte incluye: datos administrativos, datos del vehículo, informe fotográfico por categoría, resultado por elemento (Pasa / No pasa / No aplica) organizado por categoría, sección de faltantes, y valoración final con hallazgos.|
|Generación de certificado de validez PDF|El sistema genera un certificado PDF con la identidad visual de Invarat/Grupo Cofiño que incluye: folio de inspección, datos del vehículo (VIN, marca, modelo, año, kilometraje), agencia/distribuidor emisora, fecha de emisión, fecha de vigencia y un código QR. El certificado está orientado al cliente final como documento comercial/legal.|
|Portal público de consulta vía QR + VIN|El código QR del certificado dirige a una página pública (sin login) donde el usuario ingresa el VIN del vehículo, el sistema valida si la unidad está certificada y, de estarlo, permite descargar ambos documentos: el reporte de inspección y el certificado de validez. Siempre se sirve la versión más reciente de los documentos asociados al VIN. La página está disponible 24/7.|
|Autenticación de colaboradores|Los colaboradores de Invarat acceden a la plataforma mediante usuario y contraseña. No hay acceso público al módulo de inspección.|
|Gestión de usuarios|El colaborador con rol de administrador puede crear, editar y desactivar cuentas de otros colaboradores dentro de la plataforma.|
|Historial de inspecciones|El colaborador puede consultar el listado de inspecciones realizadas, con capacidad de buscar y acceder al detalle de cada una.|

El principio rector del MVP es **unificar en un solo flujo** lo que hoy requiere dos plataformas, priorizando la experiencia del perito (sin doble captura) y la disponibilidad de los documentos para el cliente final. El equipo prioriza **salir con lo estrictamente necesario** (los dos documentos rebrandeados + el portal público de consulta) y deja las mejoras de conveniencia para una etapa posterior. El MVP no toma decisiones sobre la lógica de aprobación automática del certificado ni sobre el significado operativo de la etiqueta "Requiere validación" — esas reglas de negocio deben definirse antes del diseño técnico.

\---

## 6\. Fuera de alcance

* **Carga / etiquetado de evidencia fotográfica por cada elemento del checklist:** las fotos se registran agrupadas por categoría, no ítem por ítem. Esta capacidad fue descartada explícitamente por el equipo operativo (genera trabajo excesivo). Podría reconsiderarse si un cliente futuro lo exige.
* **Edición de campos de captura ya registrados:** habilitar la corrección de campos de una inspección existente quedó identificado como deseable pero diferido a una **segunda etapa** ("si da tiempo"); no es parte del MVP comprometido.
* **Integración con sistemas externos (plataforma de valuaciones, SIGA u otros):** la plataforma opera de forma independiente. No se conecta ni reemplaza los sistemas actuales de Invarat para otros clientes. Se incluirá cuando exista un caso de negocio que lo justifique.
* **Aplicación móvil nativa (iOS / Android):** el inspector accede desde el navegador web. Una app nativa requeriría ciclos de desarrollo y aprobación adicionales fuera del alcance.
* **Cálculo / valuación económica del vehículo:** Grupo Cofiño no solicitó cálculo de daños. La plataforma no calcula ni muestra precio de compra/venta ni costos de reacondicionamiento por elemento (ver pregunta abierta sobre costeo de daños en §14).
* **Envío automático de documentos (WhatsApp, email, SMS):** el cliente final obtiene los documentos únicamente a través del portal público QR + VIN. El envío activo no fue solicitado.
* **Dashboard de métricas o módulo de BI:** no se construirá un módulo de analítica en el MVP. No fue solicitado; podría habilitarse en fase posterior.
* **Historial de versiones de inspección:** cuando una inspección se edita, el sistema conserva únicamente la versión más reciente. No se almacenan versiones anteriores.

\---

## 7\. Flujos principales

### Flujo 1 — Inspección y generación de documentos

```mermaid
flowchart TD
    A(\\\\\\\[Colaborador inicia sesión]) --> B\\\\\\\[Crear inspección asociada a folio de videoperitaje]
    B --> C\\\\\\\[Capturar datos del vehículo y administrativos]
    C --> D\\\\\\\[Tomar / cargar fotografías del peritaje]
    D --> E\\\\\\\[Agrupar fotografías por categoría, resaltando daños]
    E --> F\\\\\\\[Llenar checklist: Pasa / No pasa / No aplica por elemento]
    F --> G\\\\\\\[Agregar faltantes si aplica]
    G --> H\\\\\\\[Revisar y guardar inspección]
    H --> I\\\\\\\[Generar reporte de inspección PDF]
    H --> J\\\\\\\[Generar certificado de validez PDF con QR]
    I --> K(\\\\\\\[Documentos disponibles para descarga y consulta pública])
    J --> K
```

El flujo de inspección parte de un folio de videoperitaje. Las fotografías se obtienen durante el peritaje (en vivo o cargadas) y se organizan por categoría; el perito no etiqueta cada elemento con una imagen, sino que resalta los daños relevantes. El checklist se evalúa con Pasa / No pasa / No aplica por elemento. La generación de ambos documentos ocurre al guardar/cerrar la inspección. La distinción de elementos con "Requiere validación" es visible durante el llenado y queda registrada en el reporte, pero no bloquea la generación del certificado en el MVP (pendiente de definir la regla de negocio).

\---

### Flujo 2 — Consulta pública vía QR + VIN

```mermaid
flowchart TD
    A(\\\\\\\[Usuario escanea QR del certificado]) --> B\\\\\\\[Accede a portal público]
    B --> C\\\\\\\[Ingresa VIN del vehículo]
    C --> D{¿VIN existe y está certificado?}
    D -- No --> E\\\\\\\[Mostrar mensaje: VIN no encontrado / no certificado]
    D -- Sí --> F\\\\\\\[Mostrar opciones de descarga]
    F --> G\\\\\\\[Descargar reporte de inspección PDF]
    F --> H\\\\\\\[Descargar certificado de validez PDF]
```

Este flujo es completamente público, sin autenticación. El portal valida si la unidad está certificada y sirve siempre la versión más reciente de los documentos asociados al VIN consultado, lo que cubre los casos de reinspección o corrección de datos. Es el único punto de acceso para el cliente final y debe estar disponible 24/7.

\---

### Flujo 3 — Edición / Reinspección

```mermaid
flowchart TD
    A(\\\\\\\[Colaborador accede al historial]) --> B\\\\\\\[Busca inspección por VIN u otros datos]
    B --> C\\\\\\\[Selecciona inspección existente]
    C --> D\\\\\\\[Edita datos del vehículo y/o checklist]
    D --> E\\\\\\\[Guarda cambios]
    E --> F\\\\\\\[Sistema regenera reporte PDF y certificado PDF]
    F --> G(\\\\\\\[Portal público actualizado con versión más reciente])
```

Cuando una inspección requiere corrección o reinspección, el colaborador la localiza desde el historial, realiza los cambios y guarda; el sistema reemplaza los documentos anteriores por la nueva versión. **Nota de alcance:** la edición de campos ya capturados no está habilitada hoy en el flujo de videoperitaje reutilizado y su habilitación se difiere a una segunda etapa (ver §6 y §14). No se conservan versiones previas de la inspección.

\---

## 8\. Requerimientos funcionales

|**ID**|**Requerimiento**|**Descripción**|
|-|-|-|
|RF-01|Autenticación de colaboradores|El sistema debe permitir el acceso mediante usuario y contraseña. Solo los colaboradores autenticados pueden crear, editar y consultar inspecciones.|
|RF-02|Gestión de usuarios|El colaborador con rol de administrador puede crear, editar y desactivar cuentas de otros colaboradores.|
|RF-03|Creación de inspección|El sistema debe permitir crear una inspección, asociada a un folio de videoperitaje, capturando: VIN, marca, modelo, versión, año, color exterior, color interior, kilometraje, placas, combustible, motor, agencia/distribuidor, lugar de verificación, municipio, estado y perito asignado.|
|RF-04|Checklist por categorías y elementos|El sistema debe presentar el checklist organizado en las siguientes categorías, subcategorías y elementos predefinidos, con opción Pasa / No pasa / No aplica por elemento (sin imagen por elemento): **Documentación:** Factura, Tarjeta de circulación, Pagos de refrendo, Verificación vigente, Manual de servicio y mantenimiento. **Carrocería Exterior:** Cofre/Capó, Fascia/Defensa delantera, Salpicadera/Aleta delantera izquierda, Puerta delantera izquierda, Puerta trasera izquierda, Estribo izquierdo, Costado trasero izquierdo, Tapa de cajuela, Fascia/Defensa trasera, Costado trasero derecho, Puerta trasera derecha, Puerta delantera derecha, Estribo derecho, Salpicadera/Aleta delantera derecha, Techo. **Iluminación y Señalización:** Faro delantero derecho, Faro antiniebla derecho, Faro delantero izquierdo, Faro antiniebla izquierdo, Calavera trasera izquierda, Calavera trasera derecha, Stop central trasero, Intermitentes/Direccionales, Luz de reversa. **Cristales:** Parabrisas, Cristal delantero izquierdo, Cristal trasero izquierdo, Medallón trasero, Cristal trasero derecho, Cristal delantero derecho, Espejos/retrovisores. **Llantas y Neumáticos:** Neumático delantero izquierdo, Neumático trasero izquierdo, Neumático delantero derecho, Neumático trasero derecho, Neumático de refacción, Rin delantero izquierdo, Rin trasero izquierdo, Rin delantero derecho, Rin trasero derecho. **Interiores — Puertas:** Tapa vestidura puerta delantera izquierda, Tapa vestidura puerta trasera izquierda, Tapa vestidura puerta trasera derecha, Tapa vestidura puerta delantera derecha, Tapa vestidura cajuela, Vestidura o cielo de techo, Alfombra. **Interiores — Asientos:** Asiento delantero izquierdo, Asiento delantero derecho, Asientos traseros, Vestidura asiento delantero izquierdo, Vestidura asiento delantero derecho, Vestidura asientos traseros. **Interiores — Tablero y consola central:** Tablero, Volante, Palanca de velocidades, Consola central, Guantera, Cenicero, Radio, Navegador. **Interiores — Cierre centralizado y elevadores:** Cierre centralizado, Elevador delantero izquierdo, Elevador trasero izquierdo, Elevador trasero derecho, Elevador delantero derecho. **Mecánica — Motor y sistema de alimentación:** Sustitución de aceite motor y filtros, Revisión de soportes de motor, Revisión y estado de bandas, Sustitución banda de distribución, Comprobación testigos de avería, Revisión de fugas, Funcionamiento turbo. **Mecánica — Caja de cambios y transmisión:** Prueba de caja de cambios, Revisión de fugas, Revisión de soportes de transmisión, Revisión de juntas homocinéticas. **Mecánica — Embrague y diferencial:** Comprobación de fugas en bomba y bombín, Comprobación de trepidación, Comprobar ruido en collarín, Control del accionamiento de embrague, Control de fugas de aceite por retenes, Comprobación posibles ruidos internos. **Mecánica — Dirección y suspensión:** Comprobación de holguras, Comprobación de ruidos en bomba o servo. **Mecánica — ABS/Frenos:** Comprobación de estanqueidad, Control del estado y nivel de líquido, Testigo ABS. **Mecánica — Refrigeración:** Bomba de agua, Comprobación de motor de ventilador, Control de funcionamiento de los testigos, Control y nivel del líquido. **Mecánica — Sistema eléctrico/Radio/Instrumentación:** Comprobación funcionamiento general, Control carga alternador, Comprobación de testigos, Funcionamiento de radio, Motores eléctricos (elevadores y actuadores). **Mecánica — Aire acondicionado:** Comprobación de funcionamiento interno, Comprobación encendida de motor de ventilador, Comprobación de compresor. **Mecánica — Bolsa de aire:** Testigos encendidos.|
|RF-05|Etiqueta "Requiere validación"|Los elementos configurados como "Requiere validación" deben mostrar esa etiqueta de forma visible durante el llenado del checklist y en el reporte PDF generado.|
|RF-06|Sección de Faltantes|El sistema debe permitir al perito agregar una lista libre de conceptos faltantes al final de la inspección, sin costo asociado. Estos faltantes deben incluirse en el reporte PDF.|
|RF-07|Registro de evidencia fotográfica por categoría|El sistema debe permitir registrar (toma en vivo o carga) fotografías asociadas a la inspección, agrupadas por categoría del checklist (no por elemento individual). Estas imágenes se incluyen en el reporte PDF bajo su categoría.|
|RF-08|Generación de reporte de inspección PDF|Al guardar la inspección, el sistema debe generar un PDF con identidad visual de Invarat/Grupo Cofiño que incluya: portada, datos administrativos y del vehículo, informe fotográfico por categoría, resultado por elemento (Pasa/No pasa/No aplica) organizado por categoría, sección de faltantes, y valoración final con hallazgos.|
|RF-09|Generación de certificado de validez PDF|Al guardar la inspección, el sistema debe generar un PDF con identidad visual de Invarat/Grupo Cofiño que incluya folio, datos del vehículo, agencia emisora, fecha de emisión, fecha de vigencia y código QR de consulta pública.|
|RF-10|Portal público de consulta|El sistema debe contar con una página pública (sin login) accesible desde el QR del certificado, donde al ingresar el VIN se valide si la unidad está certificada y se puedan descargar el reporte de inspección y el certificado de validez en su versión más reciente.|
|RF-11|Regeneración de documentos en reinspección|Al guardar cambios sobre una inspección existente, el sistema debe regenerar ambos PDFs y actualizarlos en el portal público. (La edición de campos ya capturados se difiere a 2ª etapa — ver §6 y §14.)|
|RF-12|Historial de inspecciones|El sistema debe mostrar un listado de todas las inspecciones realizadas, con capacidad de búsqueda y acceso al detalle de cada una.|

\---

## 9\. Requerimientos no funcionales

|**ID**|**Requerimiento**|**Descripción**|
|-|-|-|
|RNF-01|Disponibilidad 24/7|La plataforma, incluyendo el portal público de consulta, debe estar disponible las 24 horas los 7 días de la semana. Se debe definir un SLA de uptime mínimo (sugerido: 99.5%).|
|RNF-02|Seguridad de acceso|El módulo de inspección debe estar protegido por autenticación. Las contraseñas deben almacenarse con hash seguro. Se debe implementar control de roles (administrador vs. inspector).|
|RNF-03|Protección de datos sensibles|La información del vehículo y las imágenes de inspección se consideran datos sensibles y deben tratarse conforme a la regulación de protección de datos del país de operación (LFPDPPP en México; confirmar marco aplicable si la operación incluye Guatemala — ver §14). Se debe definir política de retención y acceso a los datos.|
|RNF-04|Trazabilidad|El sistema debe registrar quién creó o editó cada inspección y en qué fecha/hora, para efectos de auditoría.|
|RNF-05|Manejo de errores|El sistema debe mostrar mensajes claros ante errores (VIN no encontrado, fallo en carga de imagen, error en generación de PDF) sin exponer detalles técnicos al usuario.|
|RNF-06|Experiencia de usuario|La interfaz debe ser responsiva y funcional desde navegador web en computadora y dispositivo móvil, sin requerir instalación de aplicación nativa.|
|RNF-07|Rendimiento en carga de imágenes|El sistema debe definir un tamaño máximo por imagen y aplicar compresión si es necesario, para evitar impacto en el rendimiento y costo de almacenamiento.|
|RNF-08|Escalabilidad|La arquitectura debe soportar el crecimiento en número de inspecciones y usuarios sin degradación de rendimiento. TI debe definir la capacidad esperada inicial.|
|RNF-09|Observabilidad|El sistema debe generar logs de operación (accesos, errores, generación de documentos) para monitoreo técnico por parte de TI.|
|RNF-10|Identidad visual|Todos los elementos de la plataforma (UI, PDFs generados) deben respetar la identidad visual de Invarat/Grupo Cofiño. Los assets (logo, colores, tipografía, plantillas) deben ser entregados antes del inicio del diseño.|

\---

## 10\. Integraciones y datos

|**Integración / Fuente**|**Uso esperado**|
|-|-|
|Flujo de videoperitaje existente (Invarat)|**Estrategia de implementación:** la plataforma reutiliza y extiende el flujo de videoperitaje ya en operación (rebranding Grupo Cofiño), en lugar de construirse desde cero. El detalle técnico de la reutilización se define en la planeación.|
|Almacenamiento de imágenes (por definir por TI)|Almacenamiento y recuperación de las fotografías de evidencia registradas durante la inspección. Debe soportar alta disponibilidad 24/7.|
|Almacenamiento de documentos PDF (por definir por TI)|Almacenamiento persistente de los reportes de inspección y certificados de validez generados, accesibles en cualquier momento desde el portal público.|
|Servicio de generación de PDF (por definir por TI)|Generación de los documentos PDF con la identidad visual de Invarat/Grupo Cofiño a partir de los datos de la inspección.|

**Datos mínimos requeridos para operar el MVP:**

* Inspección: folio (de videoperitaje), VIN, marca, modelo, versión, año, color exterior, color interior, kilometraje, placas, combustible, motor, agencia/distribuidor, lugar de verificación, municipio, estado, perito, fecha de inspección, fecha de vigencia del certificado, notas.
* Elemento de checklist: categoría, subcategoría, nombre del elemento, estado (Pasa/No pasa/No aplica), flag "Requiere validación".
* Evidencia fotográfica: imagen, categoría asociada (no elemento individual), inspección asociada.
* Faltante: concepto (texto libre), asociado a la inspección.
* Usuario: nombre, correo, contraseña (hash), rol, estado (activo/inactivo).

**Esquema de permisos:**

El colaborador autenticado puede leer y escribir inspecciones, gestionar el checklist, registrar imágenes y generar documentos PDF. El administrador adicionalmente puede gestionar usuarios. El portal público solo puede leer los documentos PDF finales asociados a un VIN; no puede acceder a datos del checklist, imágenes intermedias ni información de usuarios. Ninguna operación de escritura está disponible en el portal público.

\---

## 12\. Métricas de éxito

|**Métrica**|**Descripción**|
|-|-|
|Número de inspecciones realizadas|Total de inspecciones creadas en la plataforma por período (semana/mes). Línea base y meta a definir con operación.|
|Tiempo promedio de inspección|Tiempo transcurrido desde la creación de la inspección hasta la generación de los documentos. Permite medir la reducción vs. el proceso actual de doble captura. Línea base a definir con operación.|
|Número de certificados generados|Total de certificados PDF generados exitosamente por período.|
|Número de consultas por QR/VIN|Total de accesos al portal público de consulta por período, como indicador de uso del certificado por parte del cliente final.|
|Disponibilidad de la plataforma|Porcentaje de uptime mensual de la plataforma y del portal público. Meta sugerida: ≥99.5%.|

\---

## 13\. Riesgos y supuestos

### Riesgos

|**Riesgo**|**Impacto potencial**|
|-|-|
|Los assets de identidad visual de Invarat/Grupo Cofiño (logo, colores, plantillas PDF) no se entregan a tiempo|Bloqueo en el diseño de la UI y en la generación de los documentos PDF; retraso en la entrega.|
|El flujo de videoperitaje reutilizado no soporta alguna necesidad del MVP (p. ej. campos editables, rebranding completo)|Retrabajo o alcance adicional no previsto si la base existente impone limitaciones.|
|El tiempo de entrega es ajustado ("ya tenemos el tiempo encima")|Riesgo de recortar verificación/calidad; obliga a priorizar lo estrictamente necesario para el primer release.|
|La regla de negocio de "Requiere validación" no se define antes del diseño técnico|El equipo no puede implementar correctamente el comportamiento esperado, generando retrabajo.|
|El número de elementos del checklist (más de 80 ítems) impacta el tiempo de llenado y la usabilidad en móvil|La experiencia del perito puede degradarse si la interfaz no está optimizada para un checklist extenso en pantallas pequeñas.|

### Supuestos

|**Supuesto**|**Descripción**|
|-|-|
|Se reutiliza el flujo de videoperitaje existente como base|El MVP se construye extendiendo/rebrandeando el sistema de videoperitaje en operación, no desde cero. Las capacidades actuales de ese sistema se asumen disponibles salvo que se indique lo contrario.|
|El listado de elementos del checklist es el del reporte de inspección de Invarat|Las categorías, subcategorías y elementos del reporte de Invarat son el insumo definitivo para el checklist. Cualquier ajuste debe confirmarse antes del desarrollo.|
|Grupo Cofiño entrega los assets de marca antes de iniciar el diseño|Logo, colores, tipografía y referencia de plantilla para los PDFs deben estar disponibles al inicio del proyecto.|
|Región de operación por confirmar|El proceso opera en español. La región (México y/o Guatemala) y, con ella, el marco de protección de datos aplicable, está por confirmar (ver §14). No se contempla multi-región técnica compleja en el MVP.|
|Un VIN corresponde a una sola inspección activa|El sistema almacena una única inspección por VIN. Si se requiere corrección o reinspección, se regeneran los documentos. No se conservan versiones históricas.|
|TI de Invarat define la infraestructura de almacenamiento y hosting|Las decisiones sobre dónde alojar imágenes, PDFs y la aplicación corresponden al equipo de TI y no están dentro del alcance de este PRD.|

\---

## 14\. Preguntas abiertas

|**Tema**|**Pregunta abierta**|
|-|-|
|Región y regulación de datos|¿La plataforma operará solo en México, solo en Guatemala, o en ambos? El transcript menciona operación en Guatemala ("allá no tenemos quién ayude"). De ello depende el marco de protección de datos aplicable (LFPDPPP u otro).|
|Costeo de daños|¿Se requiere "ponerle precio" a los daños encontrados (como mencionó Rodolfo) o se confirma que Grupo Cofiño NO pidió cálculo de daños? Hay una aparente contradicción a resolver.|
|Campos editables|¿La edición de campos ya capturados entra en el MVP o se difiere a una segunda etapa? El equipo lo dejó como "si da tiempo".|
|Revisión y liderazgo|¿Aldo Álvarez participa como revisor técnico del proyecto, o hay otro responsable de TI designado?|
|Checklist — "Requiere validación"|¿La etiqueta bloquea la generación del certificado hasta que alguien la resuelva, o es únicamente informativa? ¿Quién valida y cómo se registra?|
|Checklist — Elementos con validación obligatoria|¿Cuáles elementos deben marcarse como "Requiere validación"? (En el reporte de Invarat se identificaron: Factura original, Facturas previas en refacturación, Tarjeta de circulación actualizada.) ¿Hay más?|
|Certificado — Fecha de vigencia|¿Cómo se calcula la fecha de vigencia del certificado? (¿X días desde la emisión? ¿La define el perito manualmente?)|
|Certificado — Condición de generación|¿El certificado se genera siempre al completar la inspección, o solo cuando los elementos "Requiere validación" han sido resueltos?|
|Infraestructura|¿Dónde se alojarán las imágenes y los PDFs? ¿Tamaño máximo permitido por imagen? ¿Los PDFs se generan una vez al guardar o dinámicamente al solicitarlos?|
|Identidad visual|¿Existe manual de marca o lineamientos visuales para la plataforma y los PDFs? ¿Quién los entrega y en qué plazo?|
|Seguridad|¿Se requiere autenticación de dos factores (2FA) para los colaboradores, o es suficiente usuario y contraseña?|
|Portal público|¿El portal debe mostrar una pantalla especial si el certificado venció (fecha de vigencia superada)?|



