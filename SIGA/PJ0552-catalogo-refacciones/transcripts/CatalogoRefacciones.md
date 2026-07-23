# Nota — CatalogoRefacciones

**Solicita:** Operaciones / Averías — Alexis Salvador Herrera García (alexis.herrera@gplusseguros.mx)
**Tipo:** B. Feature web/API
**Sistema:** SIGA

## Problema
El catálogo de refacciones es limitado y difícil de actualizar; nuevos componentes no
pueden registrarse.

## Mejora propuesta
Permitir la actualización y creación de nuevas refacciones por parte del área autorizada.

## Consideraciones para desarrollo
- El CRUD de refacciones ya existe (`RefaccionesController`).
- Implementar carga masiva por Excel (nota del documento).
- Permisos para que el área autorizada pueda crear/editar refacciones.
- Validar impacto en refacciones permitidas / no permitidas por producto.

## Importancia e impacto de negocio
- Importancia: Media
- Impacto: Eficiencia operativa | Administración operativa.
- Catálogo de refacciones actualizable; agiliza la resolución de averías y reduce la
  dependencia de TI para el mantenimiento.
