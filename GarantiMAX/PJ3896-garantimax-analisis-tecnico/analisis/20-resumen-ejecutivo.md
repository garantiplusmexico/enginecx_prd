# 20 · Resumen ejecutivo del análisis

| Campo | Detalle |
|---|---|
| Capítulo | C19 |
| Requerimiento(s) | RF-22 |
| Etapa | A (preliminar) — T-27 · B (actualizado) — T-38 |
| Versión | 1.0 — **PRELIMINAR** |
| Fecha | 2026-08-24 |
| Estado | 🟡 Preliminar — se actualiza al cierre de la Etapa B (T-38) |

> Documento corto para Dirección. Sin detalle técnico — el detalle completo, con evidencia archivo por archivo, vive en los 19 capítulos de `analisis/`.

---

## Qué se hizo

Se documentó GarantiMAX de punta a punta —tecnología, los 24 módulos de negocio, el modelo de datos, las 46 funciones de servidor, las integraciones externas, el uso de tiempo real y la PWA de terreno— y se evaluó su calidad en cuatro frentes: arquitectura, seguridad, rendimiento y proceso de desarrollo. Todo con evidencia citada: cada afirmación de este análisis se puede rastrear a un archivo, una línea de código o una configuración concreta.

**Esto se hizo sin acceso a la base de datos ni a la API de SIGA** (dos permisos que aún no llegan). Por eso el análisis se dividió en dos partes: lo que ya se puede afirmar leyendo el código completo del sistema (**esta entrega**), y lo que falta verificar contra la base real y contra SIGA (**pendiente, sin fecha, a la espera de esos dos accesos**).

## El hallazgo que requiere atención inmediata

Se encontró una tabla de la base de datos (información de cobranza y estado crediticio de clientes) con un permiso de lectura que parece no exigir ningún tipo de autenticación. **Se escaló el mismo día que se detectó**, antes de terminar el análisis. No se pudo confirmar contra la base real (falta el acceso), pero la evidencia en el código es clara y merece revisarse con prioridad en cuanto se obtenga ese acceso.

## Lo que la documentación reveló sobre el propio sistema

- **La documentación existente del proyecto no cubre ni el 75% de sus módulos** — 7 de 24, incluido el más grande y más crítico (gestión de casos de garantía), no tenían ni una línea de descripción antes de este análisis. Es la confirmación directa del problema que motivó este proyecto.
- **El sistema tiene partes bien construidas.** La lógica de cálculo más delicada (cobertura de garantías, plazos, pagos) vive separada de la pantalla, es código simple de revisar y ya tiene pruebas automáticas. Es, en la práctica, la parte del sistema más fácil de conservar o de trasladar si se decide migrar.
- **El sistema tiene deuda de calidad real, pero manejable.** No hay pruebas automáticas de la interfaz visual (solo de los cálculos internos), la protección de tipos de datos está parcialmente desactivada, y el sistema de servidor no tiene ninguna alerta si algo falla en segundo plano. Son huecos conocidos, corregibles con trabajo planificado — no señales de que el sistema esté mal construido.

## Los cinco caminos posibles, comparados en igualdad de condiciones

Se evaluaron cinco opciones con los mismos criterios, sin favorecer de entrada ni la tecnología actual ni el estándar corporativo:

| Opción | En una frase |
|---|---|
| **E0** — Conservar todo | Se queda como está, con gobierno y corrección de lo encontrado en este análisis. |
| **E1** — Cambiar solo el backend | Se conserva la pantalla, se reconstruye todo lo de detrás en el estándar corporativo. |
| **E2** — Rehacer todo | Se reconstruye completo, pantalla incluida, en el estándar corporativo. |
| **E3** — Híbrido | Se reconstruye el backend, pero se conserva el tiempo real (War Room, call center) como está. |
| **E4** — Partir por negocio | Se reconstruye solo la parte de garantías/siniestros; la parte comercial (seguimiento de vendedores) se queda donde está, porque no existe un equivalente en ningún otro sistema de la empresa. |

## La recomendación de hoy — y por qué es preliminar

**El candidato más prometedor, con la información disponible hoy, es E4** — porque la pieza más cara y riesgosa de reconstruir (el tiempo real) resulta estar concentrada justo en la mitad del sistema que E4 propone conservar. No es una recomendación cerrada: **falta el dato de costo real y falta confirmar que separar el sistema en dos partes es técnicamente limpio** — dos cosas que solo se pueden verificar con acceso a la base de datos, que hoy no se tiene.

**Lo que sí se puede decir con confianza:** no hay evidencia de que rehacer todo el sistema desde cero (E2) esté justificado. El sistema tiene calidad suficiente para construir sobre él.

## Qué falta para cerrar la decisión

1. **Acceso de lectura a la base de datos** — para confirmar el hallazgo de seguridad y para saber cuánto pesa cada mitad del sistema (dato que decide si E4 es viable).
2. **Costo real de la plataforma actual** (Supabase y Vercel) — hoy no se tiene esa cifra.
3. **Acceso a la documentación de la API de SIGA** — para saber si ya existe una forma de reemplazar la carga manual de Excel que hoy alimenta al sistema.

---

*Este resumen se reemplaza por su versión definitiva al cierre de la Etapa B (T-38), cuando esos tres puntos estén resueltos.*
