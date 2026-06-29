-- 1. Raw sorok száma inputonként.
SELECT 'nld_sor_raw' AS table_name, COUNT(*) AS row_count FROM `ford-training-430008.04_nld_sor_raw.nld_sor_raw`
UNION ALL
SELECT 'nld_did_raw' AS table_name, COUNT(*) AS row_count FROM `ford-training-430008.04_nld_sor_raw.nld_did_raw`
UNION ALL
SELECT 'mli_classification_alteryx_raw' AS table_name, COUNT(*) AS row_count FROM `ford-training-430008.04_nld_sor_raw.mli_classification_alteryx_raw`;

-- 2. Stage aggregált metrikák hónapra.
SELECT
  Months,
  COUNT(*) AS row_count,
  SUM(LOC_Invoiced) AS LOC_Invoiced,
  SUM(LOC_BDN) AS LOC_BDN,
  SUM(LOC_RRP) AS LOC_RRP,
  SUM(USD_Invoiced) AS USD_Invoiced,
  SUM(USD_BDN) AS USD_BDN,
  SUM(USD_RRP) AS USD_RRP,
  SUM(qty) AS qty
FROM `ford-training-430008.04_nld_sor_stage.nld_sor_stage`
GROUP BY Months
ORDER BY Months;

-- 3. DID dealer coverage. Ideális esetben 0 sor, de sample inputnál ellenőrizni kell.
SELECT
  COUNT(*) AS missing_did_rows
FROM `ford-training-430008.04_nld_sor_intermediate.nld_sor_enriched`
WHERE DidMappingFound = FALSE;

-- 4. MLI coverage. Ideális esetben 0 sor.
SELECT
  COUNT(*) AS missing_mli_rows
FROM `ford-training-430008.04_nld_sor_intermediate.nld_sor_enriched`
WHERE MliMappingFound = FALSE;

-- 5. Gold aggregált kontroll hónapra.
SELECT
  Months,
  COUNT(*) AS row_count,
  SUM(LOC_Invoiced) AS LOC_Invoiced,
  SUM(LOC_BDN) AS LOC_BDN,
  SUM(LOC_RRP) AS LOC_RRP,
  SUM(USD_Invoiced) AS USD_Invoiced,
  SUM(USD_BDN) AS USD_BDN,
  SUM(USD_RRP) AS USD_RRP,
  SUM(qty) AS qty
FROM `ford-training-430008.04_nld_sor_gold.nld_sor_salesdata`
GROUP BY Months
ORDER BY Months;
