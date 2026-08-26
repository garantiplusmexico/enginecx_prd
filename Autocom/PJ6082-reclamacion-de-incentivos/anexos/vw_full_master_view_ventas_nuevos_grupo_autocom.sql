  -- "db-bi-quiterqbi".vw_full_master_view_ventas_nuevos_grupo_autocom source

CREATE OR REPLACE VIEW "db-bi-quiterqbi".vw_full_master_view_ventas_nuevos_grupo_autocom AS
WITH
  ventas_nuevos AS (
   WITH
     ventas_nuevos AS (
      SELECT DISTINCT
        'Datos Autocom' bandera_fuente
      , referencia
      , num_factura
      , bandera_cancelacion
      , CAST(fec_factura AS date) fec_factura
      , CAST(fec_entrega AS date) fec_entrega
      , concesionario
      , nom_concesionario
      , concat(concat(concesionario, ' - '), nom_concesionario) ln_concesionario
      , id_vendedor
      , nom_vendedor
      , concat(concat(id_vendedor, ' - '), nom_vendedor) venderor
      , idv
      , ud
      , segmento
      , marca
      , modelo
      , version
      , anio_vehiculo
      , vin
      , des_codigo_financiera
      , tipo_venta
      , desc_tipo_venta
      , des_tipo_venta_destino
      , tipo_venta_calculada
      , desc_origen
      , cuenta id_cliente
      , nombre_cliente
      , tipo_cliente_venta
      , cod_postal_cliente
      , CAST(imp_total_factura AS double) imp_total_factura
      , CAST(imp_subtotal AS double) imp_subtotal
      , CAST(imp_iva AS double) imp_iva
      , CAST(imp_costo AS double) imp_costo
      , CAST(imp_concepto_impuesto_auto_nuevo AS double) imp_concepto_impuesto_auto_nuevo
      , CAST(imp_concepto_tot_incentivos AS double) imp_concepto_tot_incentivos
      FROM
        "db-bi-quiterqbi".vw_master_view_ventas_nuevos
      WHERE ((NOT (bandera_cancelacion IN ('INTERCAMBIO'))) AND (NOT (desc_tipo_venta LIKE '%INTERCAMBIO%')) AND (NOT (desc_tipo_venta LIKE '%PASO%')))
UNION ALL       SELECT DISTINCT
        'Datos Honda' bandera_fuente
      , referencia
      , num_factura
      , bandera_cancelacion
      , CAST(fec_factura AS date) fec_factura
      , CAST(fec_entrega AS date) fec_entrega
      , concat('Ho', concesionario) concesionario
      , nom_concesionario
      , concat(concat(concesionario, ' - '), nom_concesionario) ln_concesionario
      , id_vendedor
      , nom_vendedor
      , concat(concat(id_vendedor, ' - '), nom_vendedor) venderor
      , idv
      , ud
      , segmento
      , marca
      , modelo
      , version
      , anio_vehiculo
      , vin
      , des_codigo_financiera
      , tipo_venta
      , desc_tipo_venta
      , des_tipo_venta_destino
      , tipo_venta_calculada
      , desc_origen
      , cuenta id_cliente
      , nombre_cliente
      , tipo_cliente_venta
      , cod_postal_cliente
      , CAST(imp_total_factura AS double) imp_total_factura
      , CAST(imp_subtotal AS double) imp_subtotal
      , CAST(imp_iva AS double) imp_iva
      , CAST(imp_costo AS double) imp_costo
      , CAST(imp_concepto_impuesto_auto_nuevo AS double) imp_concepto_impuesto_auto_nuevo
      , 0 imp_concepto_tot_incentivos
      FROM
        "db-bi-quiterqbi".vw_master_view_ventas_nuevos_honda
      WHERE ((NOT (desc_tipo_venta LIKE '%INTERCAMBIO%')) AND (NOT (desc_tipo_venta LIKE '%PASO%')))
UNION ALL       SELECT DISTINCT
        'Datos Hyundai' bandera_fuente
      , referencia
      , num_factura
      , bandera_cancelacion
      , CAST(fec_factura AS date) fec_factura
      , CAST(fec_entrega AS date) fec_entrega
      , concesionario
      , nom_concesionario
      , concat(concat(concesionario, ' - '), nom_concesionario) ln_concesionario
      , id_vendedor
      , nom_vendedor
      , concat(concat(id_vendedor, ' - '), nom_vendedor) venderor
      , idv
      , ud
      , segmento
      , marca
      , modelo
      , version
      , anio_vehiculo
      , vin
      , des_codigo_financiera
      , tipo_venta
      , desc_tipo_venta
      , des_tipo_venta_destino
      , tipo_venta_calculada
      , desc_origen
      , cuenta id_cliente
      , nombre_cliente
      , tipo_cliente_venta
      , cod_postal_cliente
      , CAST(imp_total_factura AS double) imp_total_factura
      , CAST(imp_subtotal AS double) imp_subtotal
      , CAST(imp_iva AS double) imp_iva
      , CAST(imp_costo AS double) imp_costo
      , CAST(imp_concepto_impuesto_auto_nuevo AS double) imp_concepto_impuesto_auto_nuevo
      , CAST(imp_concepto_tot_incentivos AS double) imp_concepto_tot_incentivos
      FROM
        "db-bi-quiterqbi".vw_master_view_ventas_nuevos_hyundai
      WHERE ((NOT (desc_tipo_venta LIKE '%INTERCAMBIO%')) AND (NOT (desc_tipo_venta LIKE '%PASO%')))
UNION ALL       SELECT DISTINCT
        'Datos Toyota' bandera_fuente
      , referencia
      , num_factura
      , bandera_cancelacion
      , CAST(fec_factura AS date) fec_factura
      , CAST(fec_entrega AS date) fec_entrega
      , concat('To', concesionario) concesionario
      , nom_concesionario
      , concat(concat(concesionario, ' - '), nom_concesionario) ln_concesionario
      , id_vendedor
      , nom_vendedor
      , concat(concat(id_vendedor, ' - '), nom_vendedor) venderor
      , idv
      , ud
      , segmento
      , marca
      , modelo
      , version
      , anio_vehiculo
      , vin
      , des_codigo_financiera
      , tipo_venta
      , desc_tipo_venta
      , des_tipo_venta_destino
      , tipo_venta_calculada
      , desc_origen
      , cuenta id_cliente
      , nombre_cliente
      , tipo_cliente_venta
      , cod_postal_cliente
      , CAST(imp_total_factura AS double) imp_total_factura
      , CAST(imp_subtotal AS double) imp_subtotal
      , CAST(imp_iva AS double) imp_iva
      , CAST(imp_costo AS double) imp_costo
      , CAST(imp_concepto_impuesto_auto_nuevo AS double) imp_concepto_impuesto_auto_nuevo
      , CAST(imp_concepto_tot_incentivos AS double) imp_concepto_tot_incentivos
      FROM
        "db-bi-quiterqbi".vw_master_view_ventas_nuevos_toyota
      WHERE ((NOT (desc_tipo_venta LIKE '%INTERCAMBIO%')) AND (NOT (desc_tipo_venta LIKE '%PASO%')))
   ) 
,    marcas AS (
      SELECT DISTINCT
        concesionario
      , grupo_corporativo
      FROM
        "db-bi-quiterqbi".vw_full_master_view_concesionarios_grupo_autocom
   ) 
,    mes_cierre AS (
      SELECT *
      FROM
        (
 VALUES 
           ROW ('Enero 2025', DATE '2025-01-03', DATE '2025-01-31')
         , ROW ('Febrero 2025', DATE '2025-02-01', DATE '2025-02-28')
         , ROW ('Marzo 2025', DATE '2025-03-01', DATE '2025-03-31')
         , ROW ('Abril 2025', DATE '2025-04-01', DATE '2025-04-30')
         , ROW ('Mayo 2025', DATE '2025-05-01', DATE '2025-06-02')
         , ROW ('Junio 2025', DATE '2025-06-03', DATE '2025-06-30')
         , ROW ('Julio 2025', DATE '2025-07-01', DATE '2025-08-01')
         , ROW ('Agosto 2025', DATE '2025-08-02', DATE '2025-09-01')
         , ROW ('Septiembre 2025', DATE '2025-09-02', DATE '2025-09-30')
         , ROW ('Octubre 2025', DATE '2025-10-01', DATE '2025-10-31')
         , ROW ('Noviembre 2025', DATE '2025-11-01', DATE '2025-12-02')
         , ROW ('Diciembre 2025', DATE '2025-12-02', DATE '2026-01-02')
      )  t (mes_cierre, inicio, cierre)
   ) 
   SELECT DISTINCT
     ventas_nuevos.bandera_fuente
   , ventas_nuevos.bandera_cancelacion
   , ventas_nuevos.referencia
   , ventas_nuevos.num_factura
   , ventas_nuevos.fec_factura
   , date_format(date(ventas_nuevos.fec_factura), '%Y%m') Fec_periodo_factura
   , ventas_nuevos.fec_entrega
   , marcas.grupo_corporativo
   , ventas_nuevos.concesionario
   , ventas_nuevos.nom_concesionario
   , ventas_nuevos.ln_concesionario
   , ventas_nuevos.id_vendedor
   , ventas_nuevos.nom_vendedor
   , ventas_nuevos.venderor
   , ventas_nuevos.idv
   , ventas_nuevos.ud
   , ventas_nuevos.segmento
   , (CASE WHEN (modelo IN ('370 Z', 'SUPRA')) THEN 'COUPE' WHEN (modelo IN ('DOLPHIN', 'ORA 03', 'ELANTRA HB', 'GRAND I10', 'HB20', 'CHEVROLET', 'FORTE COUPE 5P', 'RIO COUPE 5P', 'CHEVROLET', 'MARCH')) THEN 'HATCHBACK' WHEN (modelo IN ('ODYSSEY', 'SIENNA')) THEN 'MINIVAN' WHEN (modelo IN ('PICK UP SHARK DM-O', 'SHARK DMO GL', 'SHARK DMO GS', 'HUNTER', 'STAR TRUCK', 'POER COMERCIAL', 'FRONTIER', 'FRONTIER LE 2.5L 4 CIL', 'FRONTIER V6', 'NP300', 'HILUX', 'TACOMA', 'TUNDRA')) THEN 'PICK UP' WHEN (modelo IN ('KARAVAN')) THEN 'REMOLQUE' WHEN (modelo IN ('ACURA ILX', 'ACURA INTEGRA', 'ACURA TLX', 'BYD SEAL AWD', 'KING DM-i SEDAN', 'SEAL EV, SEDAN', 'ALSVIN', 'EADO PLUS', 'ACCORD', 'CITY', 'CIVIC', 'ELANTRA', 'ELANTRA HIBRIDO', 'GRAND I10', 'HB20', 'IONIQ', 'FORTE SEDAN 4P', 'K3', 'K4', 'NEW FORTE', 'RIO SEDAN 4P', 'ALTIMA', 'K3', 'SENTRA', 'V-DRIVE', 'VERSA', 'CAMRY', 'COROLLA', 'PRIUS', 'YARIS')) THEN 'SEDAN' WHEN (modelo IN ('ACURA ADX', 'ACURA MDX', 'ACURA RDX', 'ATTO 8 DM-P', 'M9 GL', 'SEALION 7', 'SONG PLUS DMI', 'SONG PRO DMi,SUV', 'TANG EV', 'YUAN PRO', 'CS35 PLUS', 'CS55 PLUS', 'CS75', 'CS95', 'DEEPAL', 'UNI-K', '300', 'H6', 'HAVAL H6', 'JOLION', 'TANK 500 MHEV Luxury', 'BR-V', 'CR-V', 'HRV', 'PILOT', 'CRETA', 'CRETA', 'CRETA GRAND', 'PALISADE', 'PALISADE', 'SANTA FE', 'SANTA FE HIBRIDA', 'TUCSON', 'TUCSON HIBRIDO', 'TUCSON HIBRIDO', 'QX50 2.0', 'QX60', 'QX80', 'EV6', 'NEW  SPORTAGE', 'NEW SOUL', 'NIRO', 'SELTOS', 'SONET', 'SORENTO', 'TELLURIDE', 'KICKS', 'MAGNITE', 'PATHFINDER', 'XTRAIL', '4RUNNER', 'AVANZA', 'HIGHLANDER', 'RAIZE', 'RAV4', 'SEQUOIA')) THEN 'SUV' WHEN (modelo IN ('HONOR S', 'URVAN', 'HIACE')) THEN 'VAN' WHEN (modelo IN ('KARAVAN', 'OUTLANDER', 'PWC', 'SPY', 'SSV', 'PWC', 'OUTLANDER', 'SSV', 'SSV', 'OUTLANDER', 'PWC', 'KARAVAN', 'OUTLANDER', 'PWC', 'SSV', 'MOTOCICLETA MARCA SEGWAY', 'OUTLANDER')) THEN 'VEHICULO RECREATIVO' END) segmento_bi
   , ventas_nuevos.marca
   , ventas_nuevos.modelo
   , ventas_nuevos.version
   , ventas_nuevos.anio_vehiculo
   , ventas_nuevos.vin
   , ventas_nuevos.des_codigo_financiera
   , ventas_nuevos.tipo_venta
   , ventas_nuevos.desc_tipo_venta
   , ventas_nuevos.des_tipo_venta_destino
   , ventas_nuevos.tipo_venta_calculada
   , ventas_nuevos.desc_origen
   , ventas_nuevos.id_cliente
   , ventas_nuevos.nombre_cliente
   , ventas_nuevos.tipo_cliente_venta
   , ventas_nuevos.cod_postal_cliente
   , ventas_nuevos.imp_total_factura
   , ventas_nuevos.imp_subtotal
   , ventas_nuevos.imp_iva
   , ventas_nuevos.imp_costo
   , ventas_nuevos.imp_concepto_impuesto_auto_nuevo
   , ventas_nuevos.imp_concepto_tot_incentivos
   , (CASE WHEN (upper(ventas_nuevos.concesionario) IN ('HO1', 'HO6', '101', 'AC1', 'AC6', '94', '95', '68', '96', '69', 'HO3', 'HO2', 'HY1', '93', '89', '90', 'TO3', 'TO1', '8')) THEN '01 - CDMX' WHEN (upper(ventas_nuevos.concesionario) IN ('18', '15', '45', '17', '20', '67')) THEN U&'02 - Quer\00E9taro' WHEN (upper(ventas_nuevos.concesionario) IN ('82', '83', '84', '5', '1', '11', '13', '7', '10', '12', '14')) THEN '03 - Michoacan' WHEN (upper(ventas_nuevos.concesionario) IN ('22', '86', '85', '81', '42', '43', '2', '21', '6')) THEN '04 - Guanajuato' WHEN (upper(ventas_nuevos.concesionario) IN ('47')) THEN '06 - Hidalgo' WHEN (upper(ventas_nuevos.concesionario) IN ('44')) THEN '05 - Puebla' WHEN (upper(ventas_nuevos.concesionario) IN ('103')) THEN '07 - Cuernavaca' ELSE '08 - VALIDAR ESTADO' END) estado
   FROM
     ((ventas_nuevos
   LEFT JOIN marcas ON (ventas_nuevos.concesionario = marcas.concesionario))
   LEFT JOIN mes_cierre ON (CAST(ventas_nuevos.fec_factura AS DATE) BETWEEN mes_cierre.inicio AND mes_cierre.cierre))
   ORDER BY 1 ASC, 2 ASC, 3 ASC
) 
, colaboradores_base AS (
   SELECT DISTINCT
     CAST(periodo AS VARCHAR) periodo
   , id_quiter
   , TRANSLATE(UPPER(trim(BOTH FROM usuario)), U&'\00C1\00C9\00CD\00D3\00DA\00DC\00D1', 'AEIOUUN') vendedor_norm
   , id_agencia
   , agencia
   FROM
     "db-bi-quiterqbi".Cat_Usuarios_Full
) 
, colaboradores_primer_periodo AS (
   SELECT
     vendedor_norm
   , MIN(periodo) primer_periodo
   FROM
     colaboradores_base
   GROUP BY vendedor_norm
) 
, colaboradores_fallback AS (
   SELECT DISTINCT
     cb.vendedor_norm
   , cb.id_agencia
   , cb.agencia
   FROM
     (colaboradores_base cb
   INNER JOIN colaboradores_primer_periodo cpp ON ((cb.vendedor_norm = cpp.vendedor_norm) AND (cb.periodo = cpp.primer_periodo)))
) 
SELECT DISTINCT
  vn.*
, COALESCE(c1.id_agencia, c2.id_agencia) id_agencia_colaborador
, COALESCE(c1.agencia, c2.agencia) agencia_colaborador
FROM
  ((ventas_nuevos vn
LEFT JOIN colaboradores_base c1 ON ((c1.vendedor_norm = TRANSLATE(UPPER(trim(BOTH FROM SUBSTRING(vn.nom_vendedor, (STRPOS(vn.nom_vendedor, ' - ') + 3)))), U&'\00C1\00C9\00CD\00D3\00DA\00DC\00D1', 'AEIOUUN')) AND (c1.periodo = vn.Fec_periodo_factura)))
LEFT JOIN colaboradores_fallback c2 ON (c2.vendedor_norm = TRANSLATE(UPPER(trim(BOTH FROM SUBSTRING(vn.nom_vendedor, (STRPOS(vn.nom_vendedor, ' - ') + 3)))), U&'\00C1\00C9\00CD\00D3\00DA\00DC\00D1', 'AEIOUUN')));