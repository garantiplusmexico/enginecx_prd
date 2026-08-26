SELECT
     ftvenbi_pr.referencia_fq referencia
   , ftvenbi_pr.idv_fq idv
   , sum((CASE WHEN (upper(ftvenbi_pr.desc_concepto) = 'IMPUESTO ISAN') THEN CAST(ftvenbi_pr.imp_concepto AS double) ELSE 0 END)) imp_concepto_impuesto_auto_nuevo
   , sum((CASE WHEN (upper(ftvenbi_pr.desc_concepto) LIKE '%PUBLICIDAD%') THEN CAST(ftvenbi_pr.imp_concepto AS double) ELSE 0 END)) imp_concepto_publicidad
   , sum((CASE WHEN (upper(ftvenbi_pr.desc_concepto) LIKE '%INCENTIVO%') THEN CAST(ftvenbi_pr.imp_concepto AS double) ELSE 0 END)) imp_concepto_tot_incentivos
   FROM
     "db-qbi-kor".ftvenbi_pr ftvenbi_pr
   WHERE ((upper(ftvenbi_pr.cod_concepto) <> 'PVU') AND (CAST(ftvenbi_pr.fec_factura AS date) BETWEEN CAST('2022-01-01' AS date) AND date_add('day', -1, CAST(date_format(date_add('hour', -6, current_timestamp), '%Y-%m-%d') AS date))) AND (upper(ftvenbi_pr.desc_concepto) <> '') AND (upper(ftvenbi_pr.desc_concepto) IS NOT NULL))
   GROUP BY referencia_fq, idv_fq
UNION ALL    SELECT
     ftvenbi_pr.referencia_fq referencia
   , ftvenbi_pr.idv_fq idv
   , sum((CASE WHEN (upper(ftvenbi_pr.desc_concepto) = 'IMPUESTO ISAN') THEN CAST(ftvenbi_pr.imp_concepto AS double) ELSE 0 END)) imp_concepto_impuesto_auto_nuevo
   , sum((CASE WHEN (upper(ftvenbi_pr.desc_concepto) LIKE '%PUBLICIDAD%') THEN CAST(ftvenbi_pr.imp_concepto AS double) ELSE 0 END)) imp_concepto_publicidad
   , sum((CASE WHEN (upper(ftvenbi_pr.desc_concepto) LIKE '%INCENTIVO%') THEN CAST(ftvenbi_pr.imp_concepto AS double) ELSE 0 END)) imp_concepto_tot_incentivos
   FROM
     "db-bi-quiterqbi-kor".ftvenbi_pr ftvenbi_pr
   WHERE ((upper(ftvenbi_pr.cod_concepto) <> 'PVU') AND (upper(ftvenbi_pr.desc_concepto) <> '') AND (upper(ftvenbi_pr.desc_concepto) IS NOT NULL) AND (CAST(ftvenbi_pr.fec_factura AS date) BETWEEN CAST('2024-01-01' AS date) AND CAST('2024-12-31' AS date)) AND (year_ = 2026) AND (month_ = '01') AND (day_ = '01'))
   GROUP BY referencia_fq, idv_fq