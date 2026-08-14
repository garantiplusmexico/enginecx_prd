# OP-06: Actualizar los rangos mínimo y máximo para la captura de las cédulas de identidad de Colombia

## Problema
El sistema exige mínimo 10 dígitos en documentos de identidad; documentos válidos con menos dígitos deben rellenarse artificialmente con ceros.
Actualmente aún existen algunas cédulas de 7 dígitos; las cédulas nuevas son las que piden 10 dígitos.

## Solución
- Dejar el rango de 7 a 10.
- El NIT si son de 10.
- Permitir documentos de identidad con menos de 10 dígitos.
- Definir regla de validación configurable por país.
