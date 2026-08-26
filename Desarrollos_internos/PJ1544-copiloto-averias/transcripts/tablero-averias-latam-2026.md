# Tablero de Averías LATAM — datos extraídos

**Fuente:** `tablero_averias_latam (12).html`, tablero operativo entregado por David Simancas el 2026-08-25.
**Corte de datos:** 14/08/2026 10:57. Periodo con datos de 2026: enero a julio.
**Nota:** el HTML original pesa 4.6 MB (dataset embebido de 16 800 averías 2021-2026); no se versiona en este repositorio. Este archivo recoge los agregados relevantes para el PRD.

## Volumen y desenlace — 2026 (enero–julio)

| País | Averías | No procede garantía | Cerrada | Aceptada | Solucionada | Taller | Registrada | Validación | Cancelada |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| **México** | **1 582** | **604 (38.2%)** | 535 (33.8%) | 185 (11.7%) | 96 (6.1%) | 85 (5.4%) | 34 (2.1%) | 26 (1.6%) | 13 (0.8%) |
| **Chile** | 519 | 91 (17.5%) | 292 (56.3%) | 8 (1.5%) | 10 (1.9%) | 41 (7.9%) | 36 (6.9%) | 2 (0.4%) | 37 (7.1%) |
| **Colombia** | 749 | 344 (45.9%) | 274 (36.6%) | 65 (8.7%) | 8 (1.1%) | 9 (1.2%) | 3 (0.4%) | 14 (1.9%) | 30 (4.0%) |

Averías por mes en México 2026: ene 212 · feb 217 · mar 231 · abr 205 · may 250 · jun 278 · jul 189.

Tiempo de respuesta registrado por el tablero (campo `TRES`, en **días**):

| País | Media | Mediana | p90 |
| --- | ---: | ---: | ---: |
| México | 16.5 d | 4.1 d | 50.1 d |
| Chile | 24.1 d | 18.1 d | 56.9 d |
| Colombia | 17.6 d | 2.9 d | 62.1 d |

Técnicos con carga en México 2026: EDUARDO ALVAREZ (759) · MIGUEL ANGEL RODRIGUEZ (735) · Juan Carlos Trejo (88).

## Motivos de rechazo — México 2026 (604 averías no procedentes)

| # | Motivo | Vol. | % |
| ---: | --- | ---: | ---: |
| 1 | Intervalo de Mantenimiento Excedido | 176 | 29.1% |
| 2 | Daño por uso o degradación | 150 | 24.8% |
| 3 | Componente excluido | 95 | 15.7% |
| 4 | Falta al proceso o incompleto (Distribuidor) | 44 | 7.3% |
| 5 | Fuga excluida | 41 | 6.8% |
| 6 | Influencia Externa | 24 | 4.0% |
| 7 | Sin Vigencia | 18 | 3.0% |
| 8 | Preexistente | 14 | 2.3% |
| 9 | Mala Reparación Anterior | 11 | 1.8% |
| 10 | Componente No incluido en cobertura | 7 | 1.2% |
| 11 | Falta al proceso o incompleto (Cliente) | 6 | 1.0% |
| 12 | Falta de relación en DOT | 5 | 0.8% |
| 13 | Periodo de Espera | 4 | 0.7% |
| 14 | Falta de relación en kms | 3 | 0.5% |
| 15 | Negligencia de uso | 2 | 0.3% |
| — | Otros (VIN, campaña, sin motivo) | 4 | 0.7% |

## Motivos de rechazo — LATAM 2026 (1 039 averías no procedentes, los tres países)

Daño por uso o degradación 219 (21.1%) · Intervalo de Mantenimiento Excedido 177 (17.0%) · Componente excluido 120 (11.5%) · DESGASTE NATURAL DE PIEZAS 78 (7.5%) · Componente No incluido en cobertura 63 (6.1%) · Fuga excluida 57 (5.5%) · Elemento no cubierto 52 (5.0%) · Falta al proceso o incompleto (Distribuidor) 49 (4.7%) · Influencia Externa 32 (3.1%) · COMPONENTE NO INCLUIDO EN LA GARANTIA 26 (2.5%) · OPERACION NO INCLUIDA 24 (2.3%) · Elemento de desgaste 20 (1.9%) · Sin Vigencia 19 (1.8%) · Preexistente 15 (1.4%) · AVERIA POR GOLPE 14 (1.3%) · Mala Reparación Anterior 13 (1.3%).

## Componentes rechazados con más frecuencia (captura del tablero, corte LATAM)

ANTICONGELANTE 342 · ACEITE DE TRANSMISION 277 · Compresor de A/C 204 · BOMBA DE AGUA 175 · Transmisión 159 · ACEITE 153 · CAJA DE DIRECCION 135 · JUNTA 130 · ESTEREO 119 · Soporte de Motor 111.

## Catálogos que expone el tablero (y que la API de SIGA no publica)

- **Estatus de avería (11):** No procede garantía · Cerrada · Cancelada · Aceptada · Solucionada · Taller · Registrada · Validación · Prueba-QA · Excepción no aprobada · Excepción en revisión.
- **Motivos de rechazo: 56 valores**, con duplicados y variantes de mayúsculas entre países (p. ej. `Componente excluido` / `COMPONENTE EXCLUIDO DE COBERTURA` / `Elemento excluido` / `Elemento excluido de cobertura`).
- **Componentes: 890 valores. Marcas: 208. Modelos: 1 035. Talleres: 1 607. Distribuidores: 1 211. Proyectos: 17. Técnicos: 25.**
- **Parámetros de negocio del tablero:** se consideran aprobadas las averías con importe de indemnización > 0; umbral de aprobación esperado ≤ 48%; umbral de siniestralidad 70%. Nota literal en el código del tablero: *"% aprobación: la expectativa es que sea BAJA (≤48%)"*.
