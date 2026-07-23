# Condensado — CatalogoRefacciones

## Decisiones
- Tipo de proyecto: B. Feature web/API sobre SIGA.
- Habilitar creación/actualización de refacciones por el área autorizada (no solo TI).

## Alcance / requerimientos
- CRUD de refacciones ya existe (`RefaccionesController`) → se extiende, no se crea de cero.
- Carga masiva de refacciones por Excel.
- Esquema de permisos: solo el área autorizada puede crear/editar refacciones.
- Validar impacto en refacciones permitidas / no permitidas por producto.

## Actores
- Solicita/patrocina: Operaciones / Averías — Alexis Salvador Herrera García
  (alexis.herrera@gplusseguros.mx).
- Área autorizada (a definir con precisión) que mantendrá el catálogo.
- TI (hoy responsable del mantenimiento; se busca reducir su dependencia).

## Riesgos / pendientes
- Definir con exactitud qué rol/área es "el área autorizada".
- Impacto de altas/ediciones sobre la relación refacción ↔ producto (permitidas/no permitidas).
- Reglas y validaciones de la carga masiva por Excel (formato, errores, duplicados).

## Fechas / hitos
- (Sin fechas definidas aún.)
