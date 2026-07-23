# Notas — Estado Colonia Chile

**Solicita:** Operaciones / Chile
**Revisión técnica:** Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx)

## Problema
En el reporte Excel de contratos, los campos Estado Beneficiario y Colonia utilizan
nomenclatura mexicana que no corresponde a Chile.

## Mejora propuesta
Renombrar en el reporte Excel para Chile:
- Estado Beneficiario -> Region Beneficiario
- Colonia -> Comuna
- RFC -> RUT

## Consideraciones para desarrollo
Renombrar headers en export Excel de contratos Chile (PaisCL):
- Estado Beneficiario -> Region Beneficiario
- Colonia -> Comuna
- RFC -> RUT

No modificar exports de Mexico/Colombia. Validar SP `sp_reporte_contratos` si los headers
vienen de ahi.

## Importancia e impacto de negocio
- Importancia: Baja
- Impacto: Administracion | Reportes
- Nomenclatura local en Excel Chile; mejora claridad de reportes internos sin impacto en
  clientes.

## Alcance adicional (vistas)
En el pais Chile se deben cambiar algunas etiquetas en reportes y algunas vistas: donde se
coloque "Estado Beneficiario" poner "Region Beneficiario", y donde se coloque "Colonia" poner
"Comuna". Se presenta principalmente en archivos de descarga o exportacion Excel (CSV).
