-- 1. Raw sorok száma inputonként.
SELECT 'ibis_nld_raw' AS table_name, COUNT(*) AS row_count FROM `ford-training-430008.03_ibis_bel_nld_raw.ibis_nld_raw`
UNION ALL
SELECT 'ibis_bel_raw' AS table_name, COUNT(*) AS row_count FROM `ford-training-430008.03_ibis_bel_nld_raw.ibis_bel_raw`
UNION ALL
SELECT 'mli_classification_alteryx_raw' AS table_name, COUNT(*) AS row_count FROM `ford-training-430008.03_ibis_bel_nld_raw.mli_classification_alteryx_raw`
UNION ALL
SELECT 'nld_parts_raw' AS table_name, COUNT(*) AS row_count FROM `ford-training-430008.03_ibis_bel_nld_raw.nld_parts_raw`;

-- 2. Stage szintű market és hónap ellenőrzés.
SELECT
  market,
  MDSMT_MNTHYR_Y,
  COUNT(*) AS row_count,
  SUM(billed_revenue) AS billed_revenue,
  SUM(gross_revenue) AS gross_revenue,
  SUM(LOC_BDN) AS LOC_BDN,
  SUM(gross_pieces) AS gross_pieces
FROM `ford-training-430008.03_ibis_bel_nld_stage.ibis_sales_stage`
GROUP BY market, MDSMT_MNTHYR_Y
ORDER BY market, MDSMT_MNTHYR_Y;

-- 3. MLI mapping coverage. Ideális esetben 0 sor.
SELECT
  market,
  COUNT(*) AS missing_mli_rows
FROM `ford-training-430008.03_ibis_bel_nld_intermediate.ibis_bel_nld_enriched`
WHERE MliMappingFound = FALSE
GROUP BY market;

-- 4. FINIS parts coverage. Ez információs kontroll, mert az input NLD parts extract.
SELECT
  market,
  COUNT(*) AS missing_parts_rows
FROM `ford-training-430008.03_ibis_bel_nld_intermediate.ibis_bel_nld_enriched`
WHERE PartsMappingFound = FALSE
GROUP BY market;

-- 5. Gold eredmények market/hónap kontrollja.
SELECT
  market,
  MDSMT_MNTHYR_Y,
  COUNT(*) AS grouped_rows,
  SUM(Sum_billed_revenue) AS billed_revenue,
  SUM(Sum_gross_revenue) AS gross_revenue,
  SUM(Sum_LOC_BDN) AS LOC_BDN,
  SUM(Sum_gross_pieces) AS gross_pieces
FROM `ford-training-430008.03_ibis_bel_nld_gold.ibis_market_salesdata`
GROUP BY market, MDSMT_MNTHYR_Y
ORDER BY market, MDSMT_MNTHYR_Y;
