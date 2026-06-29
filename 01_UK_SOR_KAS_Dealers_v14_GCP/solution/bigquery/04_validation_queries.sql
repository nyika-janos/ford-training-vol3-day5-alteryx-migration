-- Raw sorok száma.
SELECT COUNT(*) AS raw_rows
FROM `ford-training-430008.01_uk_sor_raw.uk_sor_kas_dealers_raw`;

-- Alteryx filter ágak szerinti bontás.
SELECT
  PV_CV,
  COUNT(*) AS row_count
FROM `ford-training-430008.01_uk_sor_raw.uk_sor_kas_dealers_raw`
GROUP BY PV_CV
ORDER BY PV_CV;

-- Dataform gold kimenetek reconciliációja.
SELECT
  (SELECT COUNT(*) FROM `ford-training-430008.01_uk_sor_gold.uk_sor_kas_dealers`) AS standard_rows,
  (SELECT COUNT(*) FROM `ford-training-430008.01_uk_sor_gold.uk_sor_kas_dealers_cv`) AS cv_rows,
  (SELECT COUNT(*) FROM `ford-training-430008.01_uk_sor_raw.uk_sor_kas_dealers_raw`) AS raw_rows;

-- A standard + CV kimenet együtt adja ki a raw sorokat, ha nincs null/eltérő PV_CV.
SELECT
  (
    SELECT COUNT(*) FROM `ford-training-430008.01_uk_sor_gold.uk_sor_kas_dealers`
  )
  +
  (
    SELECT COUNT(*) FROM `ford-training-430008.01_uk_sor_gold.uk_sor_kas_dealers_cv`
  ) AS gold_rows_total,
  (
    SELECT COUNT(*) FROM `ford-training-430008.01_uk_sor_raw.uk_sor_kas_dealers_raw`
  ) AS raw_rows;
