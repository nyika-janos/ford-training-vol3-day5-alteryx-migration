-- Raw sorszámok.
SELECT "hu_ibis_raw" AS table_name, COUNT(*) AS row_count
FROM `ford-training-430008.02_hu_sell_in_raw.hu_ibis_raw`
UNION ALL
SELECT "mli_classification_alteryx_raw", COUNT(*)
FROM `ford-training-430008.02_hu_sell_in_raw.mli_classification_alteryx_raw`
UNION ALL
SELECT "hu_sor_parts_price_raw", COUNT(*)
FROM `ford-training-430008.02_hu_sell_in_raw.hu_sor_parts_price_raw`;

-- Gold havi totalok.
SELECT
  month,
  SUM(LOC_BDN) AS sum_loc_bdn,
  SUM(billed_revenue) AS sum_billed_revenue,
  SUM(qty) AS sum_qty,
  SUM(Sum_Calculated_BDN) AS sum_calculated_bdn
FROM `ford-training-430008.02_hu_sell_in_gold.hu_sell_in`
GROUP BY month
ORDER BY month;

-- Join coverage ellenőrzés.
SELECT COUNT(*) AS missing_mli_mapping
FROM `ford-training-430008.02_hu_sell_in_intermediate.hu_sell_in_enriched`
WHERE Basket IS NULL;

-- Parts price coverage információ. Ez nem hiba, mert a workflow LOC_BDN fallbacket használ.
SELECT COUNT(*) AS missing_parts_price_rows
FROM `ford-training-430008.02_hu_sell_in_intermediate.hu_sell_in_enriched`
WHERE PartsPriceFound = FALSE;
