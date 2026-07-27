# Módulo de Siniestros — Guía de Levantamiento de Requerimientos

## Objetivo

Definir una propuesta base para un módulo de gestión y seguimiento de siniestros integrado al CRM actual, que permita controlar el ciclo de vida de un siniestro relacionado con una póliza.

**Flujo general:** Póliza → Reporte → Registro → Validación → Seguimiento → Resolución → Cierre.

> **Uso del documento:** TI presenta esta estructura inicial y el área de negocio valida, corrige y complementa el proceso real, reglas, responsables, excepciones e integraciones.

---

## 1. Contexto actual

### Objetivo de la sesión

Entender cómo se gestiona actualmente un siniestro desde que el cliente lo reporta hasta su resolución.

### Preguntas

1. ¿Cómo se reporta actualmente un siniestro?
2. ¿Quién recibe el reporte?
3. ¿Dónde se registra?
4. ¿Quién da seguimiento?
5. ¿Qué actividades se realizan después del reporte?
6. ¿Qué sistemas intervienen?
7. ¿Qué información se maneja actualmente en Excel, correo u otros medios?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 2. Consulta de pólizas

El usuario debería poder localizar una póliza y consultar:

- Número de póliza.
- Asegurado.
- Contratante.
- Beneficiario.
- Aseguradora.
- Producto / ramo.
- Vigencia.
- Estatus.
- Bien asegurado.
- Coberturas.
- Suma asegurada.
- Deducible.
- Coaseguro.
- Ejecutivo / agente.

### Preguntas

1. ¿Qué información de la póliza necesitan consultar?
2. ¿Qué información debe mostrarse automáticamente?
3. ¿Qué datos pueden modificarse?
4. ¿La información proviene del CRM o de la aseguradora?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 3. Registro del siniestro

Datos sugeridos:

- Número de siniestro.
- Número de póliza.
- Asegurado.
- Fecha y hora del siniestro.
- Fecha y hora del reporte.
- Lugar.
- Tipo de siniestro.
- Causa.
- Descripción.
- Cobertura afectada.
- Bien afectado.
- Monto estimado.
- Canal de reporte.
- Número de siniestro de la aseguradora.
- Ajustador asignado.
- Estatus.

### Preguntas

1. ¿El siniestro se crea en el CRM o en la aseguradora?
2. ¿Qué datos son obligatorios?
3. ¿Quién puede registrar un siniestro?
4. ¿Se genera automáticamente un número de siniestro?
5. ¿Qué información debe enviarse a la aseguradora?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 4. Flujo y estados

### Flujo propuesto

**Reporte → Registro → Validación de cobertura → Asignación → Inspección / Ajuste → Documentación → Evaluación → Autorización / Rechazo → Reparación / Indemnización → Pago → Cierre**

### Estados propuestos

- Reportado.
- Registrado.
- En validación.
- En espera de documentos.
- Documentación completa.
- En ajuste.
- En reparación.
- En autorización.
- Autorizado.
- Rechazado.
- En proceso de pago.
- Pagado.
- Cerrado.
- Cancelado.

### Preguntas

1. ¿Cuáles son las etapas reales?
2. ¿El flujo cambia según el ramo?
3. ¿Qué estados utilizan actualmente?
4. ¿Quién puede cambiar cada estado?
5. ¿Qué condiciones deben cumplirse para cambiar de estado?
6. ¿Qué estados son automáticos?
7. ¿Qué estados requieren autorización?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 5. Gestión documental

El sistema debería permitir:

- Solicitar documentos.
- Definir documentos obligatorios.
- Cargar documentos.
- Clasificarlos.
- Validarlos.
- Registrar quién los cargó.
- Registrar fecha y hora.
- Consultar historial.

### Preguntas

1. ¿Qué documentos se solicitan por tipo de siniestro?
2. ¿Cuáles son obligatorios?
3. ¿Cambian según el ramo?
4. ¿Quién valida la documentación?
5. ¿Dónde se almacenan actualmente?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 6. Seguimiento y bitácora

Cada evento debería registrar:

- Fecha.
- Hora.
- Usuario.
- Actividad.
- Comentario.
- Cambio realizado.
- Estatus anterior.
- Nuevo estatus.

### Preguntas

1. ¿Qué actividades deben quedar registradas?
2. ¿Quién puede agregar comentarios?
3. ¿Qué información es obligatoria?
4. ¿Se requiere auditoría completa?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 7. Tareas y pendientes

Ejemplos:

- Solicitar factura.
- Validar fotografías.
- Confirmar reparación.
- Dar seguimiento con aseguradora.
- Solicitar documentación.

Datos sugeridos:

- Actividad.
- Responsable.
- Fecha de creación.
- Fecha límite.
- Prioridad.
- Estatus.
- Comentarios.

### Preguntas

1. ¿Qué tareas deben administrarse?
2. ¿Quién las asigna?
3. ¿Se requieren fechas límite?
4. ¿Se necesitan alertas de tareas vencidas?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 8. Integraciones

Posibles integraciones:

- CRM.
- Aseguradoras.
- Ajustadores.
- Talleres.
- Hospitales.
- Proveedores.
- Repositorio documental.
- ERP / Finanzas.

### Preguntas

1. ¿Con qué aseguradoras se necesita integrar?
2. ¿Existen APIs o webservices?
3. ¿Dónde se crea oficialmente el siniestro?
4. ¿Se requiere sincronizar estatus?
5. ¿Qué información se captura manualmente?
6. ¿Qué información puede obtenerse automáticamente?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 9. Notificaciones

Eventos posibles:

- Registro del siniestro.
- Cambio de estatus.
- Solicitud de documentos.
- Recepción de documentos.
- Asignación de ajustador.
- Autorización.
- Rechazo.
- Pago.
- Fecha límite próxima.

### Preguntas

1. ¿Qué notificaciones recibe el asegurado?
2. ¿Qué alertas necesita el equipo interno?
3. ¿Qué eventos deben automatizarse?
4. ¿Qué canales se utilizarán?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 10. Reportes y dashboard

Indicadores sugeridos:

- Siniestros abiertos.
- Siniestros cerrados.
- Siniestros por aseguradora.
- Siniestros por ramo.
- Siniestros por estatus.
- Siniestros por ejecutivo.
- Tiempo promedio de resolución.
- Siniestros pendientes.
- Documentación pendiente.
- Monto estimado.
- Monto pagado.

### Preguntas

1. ¿Qué indicadores necesitan?
2. ¿Qué reportes generan actualmente?
3. ¿Qué información necesita la gerencia?
4. ¿Qué filtros deben existir?
5. ¿Se requiere exportación a Excel o PDF?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 11. Roles y permisos

### Preguntas

1. ¿Qué perfiles participan?
2. ¿Quién puede consultar?
3. ¿Quién puede crear?
4. ¿Quién puede modificar?
5. ¿Quién puede cambiar estados?
6. ¿Quién puede cerrar un siniestro?
7. ¿Quién puede consultar información sensible?

**Respuestas:**

> _Capturar durante la sesión._

**Comentarios y acuerdos:**

> _Capturar durante la sesión._

---

## 12. Acuerdos y notas generales

**Acuerdos:**

> _Capturar durante la sesión._

**Pendientes:**

> _Capturar durante la sesión._

**Responsables:**

> _Capturar durante la sesión._

**Fecha compromiso:**

> _Capturar durante la sesión._

---

# Resultado esperado

Al finalizar la sesión, TI debería tener información suficiente para documentar:

1. Proceso actual (AS-IS).
2. Problemas y puntos de dolor.
3. Proceso futuro (TO-BE).
4. Actores y responsables.
5. Roles y permisos.
6. Estados y transiciones.
7. Reglas de negocio.
8. Datos requeridos.
9. Documentos.
10. Integraciones.
11. Notificaciones.
12. Reportes.
13. Excepciones.
14. Volumen y frecuencia.
15. Prioridad de funcionalidades.
