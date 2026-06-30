-- 1. Raw sorok száma inputonként.
SELECT 'bpr_so_gcp_export_raw' AS table_name, COUNT(*) AS row_count FROM `ford-training-430008.05_dach_bpr_so_raw.bpr_so_gcp_export_raw`
UNION ALL SELECT 'mli_master_raw', COUNT(*) FROM `ford-training-430008.05_dach_bpr_so_raw.mli_master_raw`
UNION ALL SELECT 'month_mapping_raw', COUNT(*) FROM `ford-training-430008.05_dach_bpr_so_raw.month_mapping_raw`
UNION ALL SELECT 'sellout_agreements_raw', COUNT(*) FROM `ford-training-430008.05_dach_bpr_so_raw.sellout_agreements_raw`
UNION ALL SELECT 'sellout_channels_raw', COUNT(*) FROM `ford-training-430008.05_dach_bpr_so_raw.sellout_channels_raw`
UNION ALL SELECT 'tbl_haendler_all_raw', COUNT(*) FROM `ford-training-430008.05_dach_bpr_so_raw.tbl_haendler_all_raw`
UNION ALL SELECT 'tbl_aktive_haendler_raw', COUNT(*) FROM `ford-training-430008.05_dach_bpr_so_raw.tbl_aktive_haendler_raw`
UNION ALL SELECT 'top_bottom_mli_raw', COUNT(*) FROM `ford-training-430008.05_dach_bpr_so_raw.top_bottom_mli_raw`;

-- 2. Stage market/hónap kontroll.
SELECT nsc, year_yyyy, month_mm, COUNT(*) AS row_count, SUM(quantity) AS quantity, SUM(base_discount) AS base_discount
FROM `ford-training-430008.05_dach_bpr_so_stage.dach_bpr_sellout_stage`
GROUP BY nsc, year_yyyy, month_mm
ORDER BY nsc, year_yyyy, month_mm;

-- 3. Lookup coverage kontroll.
SELECT
  COUNTIF(AgreementMappingFound = FALSE) AS missing_agreement_rows,
  COUNTIF(ChannelMappingFound = FALSE) AS missing_channel_rows,
  COUNTIF(MliMappingFound = FALSE) AS missing_mli_rows,
  COUNTIF(DealerMappingFound = FALSE) AS missing_dealer_rows,
  COUNTIF(MonthMappingFound = FALSE) AS missing_month_rows
FROM `ford-training-430008.05_dach_bpr_so_intermediate.dach_sellout_enriched`;

-- 4. Gold DEU hónap aggregált kontroll.
SELECT year_yyyy, month_mm, SUM(bdn) AS bdn, SUM(qty) AS qty
FROM `ford-training-430008.05_dach_bpr_so_gold.dach_bpr_deu_sell_out`
GROUP BY year_yyyy, month_mm
ORDER BY year_yyyy, month_mm;
