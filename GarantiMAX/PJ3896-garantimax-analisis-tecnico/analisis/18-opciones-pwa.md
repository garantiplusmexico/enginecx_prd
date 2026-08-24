# 18 · Opciones para la PWA

| Campo | Detalle |
|---|---|
| Capítulo | C17 |
| Requerimiento(s) | RF-19 |
| Etapa | A — T-25 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

> Contrastadas contra lo que hoy resuelve el offline de terreno (C9/T-15). Los datos de uso real (cuántos asesores la usan, qué tan crítico es el offline) siguen pendientes de A6 — se marca explícitamente dónde ese hueco limita la comparación a lo cualitativo.

---

## Opción 1 — Dejarla en el mismo proyecto, reutilizando vistas (lo que hay hoy)

| Criterio | Evaluación |
|---|---|
| **Qué es** | Lo confirmado en C9/T-15: mismo bundle, mismo build, un `if (standalone) return <MiDiaMovil />` en `App.tsx`. |
| **Pros** | Cero costo de mantenimiento adicional — un solo repositorio, un solo pipeline de CI, un solo despliegue. Los cambios de dominio (ej. una regla de negocio de `visitas`) se hacen una vez y sirven a ambas superficies. Aprovecha directamente todo lo que ya funciona: `AuthProvider`, `getSupabase()`, los hooks de datos de `visitas`. |
| **Contras** | El acoplamiento es real (C9 §4): `visitas` es el módulo con más dependencias salientes del sistema (8, C2/T-07) — cualquier cambio ahí puede afectar tanto el dashboard como la PWA sin que sea obvio a simple vista. El bundle de escritorio y el de terreno comparten pipeline de build, aunque `globIgnores` (C9) ya mitiga bastante el peso real descargado. |
| **Esfuerzo de cualquier escenario de migración (E1-E4)** | Si el backend migra pero el front se conserva (E1/E3/E4 con front React), esta opción **no cambia nada** — sigue siendo el mismo `if`. Si el front se rehace (E2, Razor), esta opción **desaparece** — Razor no tiene el mismo modelo de PWA embebida con detección de standalone dentro del mismo árbol de render; habría que resolver el offline de terreno como un proyecto aparte necesariamente. |

## Opción 2 — Extraerla a proyecto o app separada, consumiendo la misma API

| Criterio | Evaluación |
|---|---|
| **Qué implica** | Separar `visitas` (70 archivos) de su árbol de dependencias actual (`auth`, `config`, `induccion`, `resumen`, `salas`, `solicitudes`, `vendedores`, `warroom` — C2/T-07) y re-implementar el bootstrapping de autenticación de forma independiente, más `idbStore.ts` y el mecanismo de cola completo (C9). |
| **Pros** | Bundle de terreno verdaderamente aislado (sin arrastrar nada de escritorio); ciclo de despliegue independiente (un cambio en Facturación no obliga a re-desplegar la PWA); más fácil de auditar como superficie propia. Es la opción que mejor prepara el terreno si algún día se decide ir a app nativa (Opción 3), porque ya separa la lógica de negocio de terreno del resto. |
| **Contras** | **Esfuerzo alto, no por la PWA en sí sino por la centralidad de `visitas`** (C9 §4, ya señalado) — hay que decidir qué se duplica (ej. una copia ligera de auth) y qué se consume vía API de un backend compartido. Si el backend aún no está unificado detrás de una API clara (hoy es Supabase directo desde el front, sin una capa de API intermedia), extraer la PWA obliga primero a definir esa API — trabajo que de todas formas hace falta en E1/E2/E3/E4. |
| **Cuándo tiene más sentido** | Si el escenario elegido ya construye una API .NET intermedia (E1, E2, E3, E4) — en ese punto, la PWA consumiendo esa misma API como cliente separado es una extensión natural, no un proyecto adicional grande. |

## Opción 3 — App nativa o híbrida

| Criterio | Evaluación |
|---|---|
| **Qué implica** | Reconstruir la experiencia de terreno como app nativa (Swift/Kotlin) o híbrida (React Native, .NET MAUI). |
| **Pros** | Acceso a capacidades de dispositivo que una PWA no cubre completamente — cámara avanzada, notificaciones push nativas confiables, geolocalización en segundo plano, biometría. **Estos son exactamente los puntos que quedan como pregunta abierta** (A6, `preguntas-abiertas.md`): sin saber si la operación realmente necesita alguna de estas capacidades hoy, este pro es hipotético, no confirmado. |
| **Contras** | El esfuerzo más alto de las tres opciones, por un margen amplio — es, en la práctica, reconstruir `visitas` completo (70 archivos, el módulo más grande después de `postventa` y `hunter`) en una plataforma distinta, más la lógica de sincronización offline que hoy ya funciona con IndexedDB (C9) y tendría que rehacerse con el almacenamiiento nativo de la plataforma elegida. |
| **Cuándo se justifica** | Solo si A6 confirma una necesidad de capacidad de dispositivo que la PWA genuinamente no puede resolver — hoy no hay evidencia de código que indique que el sistema ya intentó y falló con capacidades de PWA (no hay, por ejemplo, un manejo defectuoso de la cámara que sugiera que se topó con un límite técnico). |

---

## Matriz de decisión rápida (según A6, cuando llegue)

| Si A6 confirma... | Opción recomendada por este análisis |
|---|---|
| El offline hoy funciona bien y no se necesitan capacidades de dispositivo nuevas | **Opción 1** si el front se conserva (E0/E1/E3/E4); **Opción 2** si el front se rehace (E2) |
| Se necesita una API intermedia de todas formas (cualquier escenario que no sea E0) | **Opción 2**, aprovechando el trabajo de la API ya hecho para el resto del sistema |
| Se confirma una necesidad real de capacidad de dispositivo (cámara avanzada, push nativo, geolocalización en segundo plano) | **Opción 3**, y solo entonces — es la más cara de las tres |

---

## Cobertura declarada (RNF-11)

Las tres opciones evaluadas con pros, contras y esfuerzo relativo (100%, RF-19). **Limitación explícita:** sin los datos de uso real de A6 (cuántos asesores, qué tan crítico es el offline, qué capacidades de dispositivo faltan), la comparación es **cualitativa, no cuantificada** — declarado aquí en vez de fingir precisión que los datos no sostienen.
