-- =====================================================================
-- EXPLORACION ATHENA - Reclamacion de Incentivos (Autocom / Hyundai)
-- Objetivo: encontrar la tabla (o definir la vista) que integre todo lo
-- que el motor de validacion necesita, ANTES de planear el desarrollo.
--
-- Correr en orden. Los bloques 0 y 1 no escanean datos (solo metadatos):
-- son gratis y son los que mas informacion dan.
--
-- REGLA PERMANENTE: en "db-bi-quiterqbi-kor" SIEMPRE fijar una particion
-- (year_/month_/day_). Cada particion es un snapshot completo de toda la
-- historia; sin fijarla los importes se multiplican por N dias cargados.
-- (Verificado: 53,674 filas exportadas = 685 lineas reales x 78 particiones,
--  con 0 celdas de diferencia entre el snapshot del 02-jun y el del 24-ago.)
-- =====================================================================


-- =====================================================================
-- BLOQUE 0 - Inventario: que bases y que tablas existen
-- Responde: cuantas fuentes hay realmente y como se llaman.
-- =====================================================================

-- 0.1 Bases disponibles
SELECT DISTINCT table_schema
FROM information_schema.tables
ORDER BY 1;

-- 0.2 Tablas por base (ajustar el IN con lo que devuelva 0.1)
SELECT table_schema, table_name, table_type
FROM information_schema.tables
WHERE table_schema IN ('db-qbi-kor', 'db-bi-quiterqbi-kor')
ORDER BY table_schema, table_name;


-- =====================================================================
-- BLOQUE 1 - Buscar las columnas que faltan, en TODAS las tablas
-- Responde: donde vive el VIN, el modelo, la version y el destino del bono.
-- Quiter suele nombrar el VIN como bastidor / chasis / serie.
-- =====================================================================

-- 1.1 VIN
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE regexp_like(lower(column_name), 'vin|bastidor|chasis|serie|niv')
ORDER BY table_schema, table_name, column_name;

-- 1.2 Modelo / version / anio modelo
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE regexp_like(lower(column_name), 'model|version|acabado|gama|linea|anio|year_model')
ORDER BY table_schema, table_name, column_name;

-- 1.3 Llave de cruce idv (que tablas se pueden unir con ftvenbi_pr)
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE regexp_like(lower(column_name), '^idv|_idv|idvehic')
ORDER BY table_schema, table_name;

-- 1.4 Destino del bono / financiamiento / nota de credito
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE regexp_like(lower(column_name), 'abono|credito|nota|financ|enganche|tasa|bono|incent|rebate')
ORDER BY table_schema, table_name, column_name;


-- =====================================================================
-- BLOQUE 2 - LA PREGUNTA BLOQUEANTE: hasta donde llega cada fuente
-- Responde: db-qbi-kor esta viva, o el feed de Quiter esta detenido?
-- El export de crudos solo llega al 18-oct-2025. Si ambas paran ahi,
-- el proyecto no puede arrancar.
-- =====================================================================

-- 2.1 Cobertura de la base VIVA (sin filtro de particion, como la sumatoria)
SELECT
    min(CAST(fec_factura AS date))  AS primera_factura,
    max(CAST(fec_factura AS date))  AS ultima_factura,
    count(*)                        AS lineas,
    count(DISTINCT referencia_fq)   AS operaciones
FROM "db-qbi-kor".ftvenbi_pr
WHERE upper(desc_concepto) LIKE '%INCENTIVO%';

-- 2.2 Cobertura de la base ARCHIVO (particion fijada; ajustar con 2.4)
SELECT
    min(CAST(fec_factura AS date))  AS primera_factura,
    max(CAST(fec_factura AS date))  AS ultima_factura,
    count(*)                        AS lineas,
    count(DISTINCT referencia_fq)   AS operaciones
FROM "db-bi-quiterqbi-kor".ftvenbi_pr
WHERE upper(desc_concepto) LIKE '%INCENTIVO%'
  AND year_ = '2026' AND month_ = '8' AND day_ = '24';

-- 2.3 Volumen por mes en la VIVA: confirma si hay hueco o corte seco
SELECT date_format(CAST(fec_factura AS date), '%Y-%m') AS mes,
       count(*)                          AS lineas,
       sum(CAST(imp_concepto AS double)) AS importe
FROM "db-qbi-kor".ftvenbi_pr
WHERE upper(desc_concepto) LIKE '%INCENTIVO%'
  AND CAST(fec_factura AS date) >= DATE '2025-01-01'
GROUP BY 1
ORDER BY 1;

-- 2.4 Ultima particion realmente disponible en el archivo
SELECT year_, month_, day_, count(*) AS filas
FROM "db-bi-quiterqbi-kor".ftvenbi_pr
WHERE year_ = '2026'
GROUP BY year_, month_, day_
ORDER BY CAST(year_ AS int) DESC, CAST(month_ AS int) DESC, CAST(day_ AS int) DESC
LIMIT 10;


-- =====================================================================
-- BLOQUE 3 - Catalogo REAL de conceptos (sin el filtro '%INCENTIVO%')
-- Responde: que otros conceptos existen que son incentivo pero no se
-- llaman "incentivo" (seguro gratis, comision de apertura, coreana,
-- flotilla, demo, loyalty...). El boletin lista 9 categorias Edifact.
-- Contexto: en el export solo aparecieron RE2 (684 lineas) y RE1 (1).
-- =====================================================================

SELECT cod_concepto, desc_concepto, cta_concepto,
       count(*)                          AS lineas,
       count(DISTINCT referencia_fq)     AS operaciones,
       min(CAST(imp_concepto AS double)) AS importe_min,
       max(CAST(imp_concepto AS double)) AS importe_max,
       sum(CAST(imp_concepto AS double)) AS importe_total
FROM "db-qbi-kor".ftvenbi_pr
WHERE CAST(fec_factura AS date) >= DATE '2025-01-01'
GROUP BY cod_concepto, desc_concepto, cta_concepto
ORDER BY lineas DESC;

-- 3.1 cta_concepto viene como "2" en el export: es la cuenta contable real
--     o esta truncada? Si son pocos valores distintos, esta truncada.
SELECT cta_concepto, count(*) AS n
FROM "db-qbi-kor".ftvenbi_pr
GROUP BY cta_concepto
ORDER BY n DESC
LIMIT 50;


-- =====================================================================
-- BLOQUE 4 - La tabla de vehiculos (VIN + modelo + version)
-- Sustituir <TABLA_VEH>, <COL_VIN>, <COL_MODELO>, <COL_VERSION> con lo
-- que salga del bloque 1. Candidatas tipicas en Quiter: ftvehbi_pr,
-- ftvehbi, dimvehiculo.
-- =====================================================================

-- 4.1 Perfilar la candidata
SELECT * FROM "db-qbi-kor".<TABLA_VEH> LIMIT 20;

-- 4.2 El join por idv funciona? Cuantas lineas quedan sin VIN/modelo?
SELECT
    count(*)                   AS lineas_incentivo,
    count(v.idv_fq)            AS con_match,
    count(*) - count(v.idv_fq) AS sin_match,
    count(DISTINCT CASE WHEN v.<COL_VIN> IS NULL THEN i.idv_fq END) AS unidades_sin_vin
FROM "db-qbi-kor".ftvenbi_pr i
LEFT JOIN "db-qbi-kor".<TABLA_VEH> v ON v.idv_fq = i.idv_fq
WHERE upper(i.desc_concepto) LIKE '%INCENTIVO%';

-- 4.3 Los valores de modelo/version del DMS empatan con los del anexo?
--     El anexo usa: "GRAND I10 HB MY26" / "GL MID AT", "CRETA MY26" / "GLS PREMIUM".
--     Si el DMS usa otra nomenclatura, hace falta una tabla de homologacion.
SELECT <COL_MODELO>, <COL_VERSION>, count(*) AS unidades
FROM "db-qbi-kor".<TABLA_VEH>
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 100;


-- =====================================================================
-- BLOQUE 5 - Notas de credito
-- El PRD cruza NC (con IVA) contra incentivo (sin IVA) por VIN.
-- Responde: donde viven las NC y como se asocian a la unidad.
-- =====================================================================

SELECT table_schema, table_name
FROM information_schema.tables
WHERE regexp_like(lower(table_name), 'abono|nota|credit|devol|rebate')
ORDER BY 1, 2;

-- 5.1 En ftvenbi_pr, ref_abono solo se llena en cancelaciones (65 de 685
--     en el export). Confirmar que la NC de incentivo NO vive aqui:
SELECT desc_tipo_venta,
       count(*)         AS lineas,
       count(ref_abono) AS con_ref_abono,
       sum(CASE WHEN CAST(imp_concepto AS double) < 0 THEN 1 ELSE 0 END) AS negativas
FROM "db-qbi-kor".ftvenbi_pr
WHERE upper(desc_concepto) LIKE '%INCENTIVO%'
GROUP BY desc_tipo_venta;


-- =====================================================================
-- BLOQUE 6 - Destino del bono (precio / enganche / tasa / accesorios / seguro)
-- Es lo que decide cual de las 2 tablas del anexo aplica.
-- En el export, las 13 columnas de financiamiento venian 100% vacias y
-- des_tipo_venta_destino = CONTADO en el 100% de las 685 lineas. Hay que
-- saber si de verdad no hubo credito, o si esas columnas no se pueblan.
-- =====================================================================

-- 6.1 Hay operaciones de credito en el universo completo?
SELECT des_tipo_venta_destino,
       count(*)              AS lineas,
       count(des_tipo_finan) AS con_tipo_finan,
       count(nom_entidad)    AS con_entidad,
       count(imp_financiado) AS con_imp_financiado
FROM "db-qbi-kor".ftvenbi_pr
WHERE CAST(fec_factura AS date) >= DATE '2025-01-01'
GROUP BY des_tipo_venta_destino;

-- 6.2 Y en las lineas de incentivo especificamente?
SELECT des_tipo_venta_destino, count(*) AS lineas
FROM "db-qbi-kor".ftvenbi_pr
WHERE upper(desc_concepto) LIKE '%INCENTIVO%'
GROUP BY des_tipo_venta_destino;


-- =====================================================================
-- BLOQUE 7 - CONTRATO OBJETIVO DE LA VISTA
-- Esto es el "listo" de la exploracion. Si ninguna tabla lo entrega,
-- esta es la vista que hay que pedirle a TI de Autocom.
-- Grano: una fila por linea de incentivo capturada en Quiter.
-- =====================================================================
/*
  LLAVE Y TRAZABILIDAD
    vin                        -- llave de cruce del sistema      [HOY NO ESTA]
    idv                        -- id interno de la unidad         [ok]
    referencia                 -- operacion                       [ok]
    num_factura                                                   [ok]
    fec_factura                -- determina el boletin vigente    [ok]
    tipo_venta                 -- nueva / cancelacion / demo      [ok]
    ref_abono                  -- referencia cancelada, p/ netear [ok]

  QUE SE VENDIO   -> sin esto no hay importe esperado
    modelo                                                        [HOY NO ESTA]
    version                                                       [HOY NO ESTA]
    anio_modelo                                                   [HOY NO ESTA]
    precio_lista                                                  [HOY NO ESTA]

  COMO SE APLICO  -> decide cual tabla del anexo aplica
    tipo_operacion             -- contado / credito               [siempre CONTADO]
    destino_bono               -- precio/enganche/tasa/accesorios/seguro [NO ESTA]
    bono_aplicado_a_reduccion  -- booleano derivado               [NO ESTA]

  QUE SE CAPTURO  -> el dato bajo sospecha
    cod_concepto                                                  [ok, solo RE1/RE2]
    desc_concepto                                                 [ok]
    cta_concepto               -- viene como "2", verificar       [dudoso]
    imp_concepto               -- aportacion de la marca SIN IVA  [ok]

  CONTABLE
    nota_credito_id            -- NC por el importe CON IVA       [HOY NO ESTA]
    imp_nota_credito                                              [HOY NO ESTA]
    imp_beneficio              -- utilidad; alimenta Fase 3       [ok]

  REGLA DE VALIDACION QUE ESTO HABILITA:
    imp_concepto == round(aportacion_HMM_con_IVA_del_anexo / 1.16)  +/- 1 peso
    Verificado contra las 54 filas del anexo de julio 2026: cuadra en las 54,
    con desviacion maxima de 1 peso por redondeo.
*/
