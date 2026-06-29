# Technikai megoldás: D/A/CH BPR SO SOC Switch Sample

## Stage: sell-out fact

```sql
config {
  type: "table",
  schema: require("../../includes/config").stage_dataset,
  name: "dach_bpr_sellout_stage"
}

js {
  const { raw_dataset } = require("../../includes/config");
}

WITH base AS (
  SELECT
    CASE TRIM(CAST(`Market Code` AS STRING))
      WHEN "DE" THEN "DEU"
      WHEN "AT" THEN "AUT"
      WHEN "CH" THEN "CHE"
      ELSE ""
    END AS nsc,
    TRIM(CAST(HDLNR AS STRING)) AS hdlnr,
    TRIM(CAST(`Sell Out Channel` AS STRING)) AS sell_out_channel,
    TRIM(CAST(BESFlag AS STRING)) AS bes_flag,
    LPAD(TRIM(CAST(`MLI Code` AS STRING)), 4, "0") AS mli_code,
    SAFE_CAST(Year_YYYY AS INT64) AS year_yyyy,
    LPAD(TRIM(CAST(Month_MM AS STRING)), 2, "0") AS month_mm,
    SAFE_CAST(Quantity AS NUMERIC) AS quantity,
    SAFE_CAST(`Base Discount` AS NUMERIC) AS base_discount
  FROM `${raw_dataset}.dach_bpr_so_gcp_export`
)

SELECT
  *,
  CONCAT(
    nsc,
    CASE
      WHEN STARTS_WITH(hdlnr, "00") THEN CONCAT(RIGHT(hdlnr, 3), "00")
      ELSE hdlnr
    END
  ) AS markt_haendlernummer
FROM base
WHERE COALESCE(bes_flag, "") != "BES"
```

## Intermediate: gazdagított sell-out

```sql
config {
  type: "table",
  schema: require("../../includes/config").intermediate_dataset,
  name: "dach_sellout_enriched"
}

js {
  const { raw_dataset, report_date } = require("../../includes/config");
}

WITH agreements AS (
  SELECT
    TRIM(CAST(Markt_Haendlernummer AS STRING)) AS markt_haendlernummer,
    TRIM(CAST(Haendlernummer AS STRING)) AS haendlernummer,
    SAFE_CAST(SOC_qlf AS INT64) AS soc_qlf,
    TRIM(CAST(SOC_SOR AS STRING)) AS soc_sor,
    TRIM(CAST(SOC_num_txt AS STRING)) AS soc_num_txt,
    TRIM(CAST(eigene_Werkstatt_mit_Strecke AS STRING)) AS eigene_werkstatt_mit_strecke
  FROM `${raw_dataset}.dach_sellout_agreements`
),
channels AS (
  SELECT
    TRIM(CAST(SOR_Code AS STRING)) AS sor_code,
    TRIM(CAST(`Channel Name` AS STRING)) AS channel_name,
    TRIM(CAST(Cluster AS STRING)) AS cluster,
    TRIM(CAST(SOC_num_txt AS STRING)) AS soc_num_txt,
    TRIM(CAST(Cluster_FCSD AS STRING)) AS cluster_fcsd
  FROM `${raw_dataset}.dach_sellout_channels`
),
mli AS (
  SELECT
    LPAD(TRIM(CAST(MLI_0000 AS STRING)), 4, "0") AS mli_code,
    TRIM(CAST(BU AS STRING)) AS bu,
    TRIM(CAST(BUSINESS_UNIT AS STRING)) AS business_unit,
    TRIM(CAST(MLI_txt AS STRING)) AS mli_txt,
    TRIM(CAST(MLI_NUM AS STRING)) AS mli_num,
    TRIM(CAST(MLI_OIL AS STRING)) AS mli_oil,
    TRIM(CAST(Program_MLI_Groups AS STRING)) AS program_mli_groups,
    TRIM(CAST(`Finanz Trans etc` AS STRING)) AS finanz_trans_etc
  FROM `${raw_dataset}.dach_mli_master`
),
dealer AS (
  SELECT
    TRIM(CAST(Markt_Haendlernummer AS STRING)) AS markt_haendlernummer,
    TRIM(CAST(Region_Teile AS STRING)) AS region,
    TRIM(CAST(THG AS STRING)) AS thg,
    TRIM(CAST(Haendlername AS STRING)) AS haendlername,
    TRIM(CAST(Poolinggruppe_SellOut AS STRING)) AS pg
  FROM `${raw_dataset}.dach_tbl_haendler_all`
),
month_map AS (
  SELECT
    LPAD(TRIM(CAST(Month_no AS STRING)), 2, "0") AS month_mm,
    TRIM(CAST(Month_ger_short AS STRING)) AS month_ger_short,
    SAFE_CAST(Quartal AS INT64) AS quartal
  FROM `${raw_dataset}.dach_month_mapping`
)

SELECT
  s.nsc,
  s.markt_haendlernummer,
  COALESCE(a.haendlernummer, s.hdlnr) AS haendlernummer,
  d.region,
  d.thg,
  d.haendlername,
  d.pg,
  s.sell_out_channel,
  COALESCE(a.soc_sor, s.sell_out_channel) AS soc_sor,
  COALESCE(a.soc_num_txt, c.soc_num_txt) AS soc_num_txt,
  c.channel_name,
  c.cluster,
  c.cluster_fcsd,
  a.soc_qlf,
  CASE WHEN a.soc_qlf = 1 THEN "inkludiert" ELSE "nicht inkludiert" END AS sell_out_vereinbarung,
  s.mli_code,
  m.mli_txt,
  m.mli_num,
  m.mli_oil,
  m.bu,
  m.business_unit,
  m.program_mli_groups,
  m.finanz_trans_etc,
  s.year_yyyy,
  s.month_mm,
  mm.month_ger_short,
  mm.quartal,
  CASE
    WHEN s.year_yyyy = EXTRACT(YEAR FROM ${report_date}) THEN "actJ"
    ELSE "VorJ"
  END AS year_txt,
  s.quantity,
  s.base_discount
FROM ${ref("dach_bpr_sellout_stage")} s
LEFT JOIN agreements a
  ON s.markt_haendlernummer = a.markt_haendlernummer
LEFT JOIN channels c
  ON COALESCE(a.soc_sor, s.sell_out_channel) = c.sor_code
LEFT JOIN mli m
  ON s.mli_code = m.mli_code
LEFT JOIN dealer d
  ON s.markt_haendlernummer = d.markt_haendlernummer
LEFT JOIN month_map mm
  ON s.month_mm = mm.month_mm
```

## Gold: DEU sell-out

```sql
config {
  type: "table",
  schema: require("../../includes/config").gold_dataset,
  name: "dach_bpr_deu_sell_out"
}

SELECT
  nsc,
  region,
  thg,
  pg,
  markt_haendlernummer,
  haendlernummer,
  soc_num_txt,
  sell_out_vereinbarung,
  cluster,
  bu,
  business_unit,
  program_mli_groups,
  finanz_trans_etc,
  mli_code,
  mli_txt,
  mli_num,
  mli_oil,
  year_yyyy,
  month_mm,
  month_ger_short,
  year_txt,
  SUM(base_discount) AS bdn,
  SUM(quantity) AS qty
FROM ${ref("dach_sellout_enriched")}
WHERE nsc = "DEU"
GROUP BY
  nsc, region, thg, pg, markt_haendlernummer, haendlernummer,
  soc_num_txt, sell_out_vereinbarung, cluster, bu, business_unit,
  program_mli_groups, finanz_trans_etc, mli_code, mli_txt, mli_num,
  mli_oil, year_yyyy, month_mm, month_ger_short, year_txt
```

## Gold: top/bottom MLI

```sql
config {
  type: "table",
  schema: require("../../includes/config").gold_dataset,
  name: "dach_top_bottom_mli_sell_out"
}

WITH agg AS (
  SELECT
    region,
    thg,
    pg,
    markt_haendlernummer,
    mli_txt,
    mli_num,
    mli_oil,
    business_unit,
    program_mli_groups,
    finanz_trans_etc,
    year_txt,
    SUM(base_discount) AS bdn,
    SUM(quantity) AS qty
  FROM ${ref("dach_sellout_enriched")}
  GROUP BY
    region, thg, pg, markt_haendlernummer, mli_txt, mli_num,
    mli_oil, business_unit, program_mli_groups, finanz_trans_etc, year_txt
)

SELECT
  region AS Region,
  thg AS THG_Betreuer_Name,
  pg AS PG,
  mli_txt AS MLI_txt,
  markt_haendlernummer AS Markt_Haendlernummer,
  mli_num AS MLI_NUM,
  mli_oil AS MLI_OIL,
  business_unit AS BUSINESS_UNIT,
  program_mli_groups AS Program_MLI_Groups,
  finanz_trans_etc AS `Finanz Trans etc`,
  SUM(IF(year_txt = "actJ", bdn, NULL)) AS actJ,
  SUM(IF(year_txt = "VorJ", bdn, NULL)) AS VorJ,
  "BDN" AS Wert
FROM agg
GROUP BY Region, THG_Betreuer_Name, PG, MLI_txt, Markt_Haendlernummer,
  MLI_NUM, MLI_OIL, BUSINESS_UNIT, Program_MLI_Groups, `Finanz Trans etc`

UNION ALL

SELECT
  region AS Region,
  thg AS THG_Betreuer_Name,
  pg AS PG,
  mli_txt AS MLI_txt,
  markt_haendlernummer AS Markt_Haendlernummer,
  mli_num AS MLI_NUM,
  mli_oil AS MLI_OIL,
  business_unit AS BUSINESS_UNIT,
  program_mli_groups AS Program_MLI_Groups,
  finanz_trans_etc AS `Finanz Trans etc`,
  SUM(IF(year_txt = "actJ", qty, NULL)) AS actJ,
  SUM(IF(year_txt = "VorJ", qty, NULL)) AS VorJ,
  "QTY" AS Wert
FROM agg
GROUP BY Region, THG_Betreuer_Name, PG, MLI_txt, Markt_Haendlernummer,
  MLI_NUM, MLI_OIL, BUSINESS_UNIT, Program_MLI_Groups, `Finanz Trans etc`
```

## Scorecard minta

```sql
config {
  type: "table",
  schema: require("../../includes/config").gold_dataset,
  name: "dach_scorecard_101"
}

js {
  const { report_date } = require("../../includes/config");
}

SELECT
  pg AS PG,
  markt_haendlernummer AS Markt_Haendlernummer,
  program_mli_groups AS Program_MLI_Groups,
  soc_num_txt AS SOC_num_txt,
  sell_out_vereinbarung AS TN_Teilebonus_Status,
  SUM(IF(year_yyyy = EXTRACT(YEAR FROM ${report_date}) - 1, base_discount, 0)) AS prior_year_bdn,
  SUM(IF(year_yyyy = EXTRACT(YEAR FROM ${report_date}), base_discount, 0)) AS current_year_bdn,
  SUM(IF(year_yyyy = EXTRACT(YEAR FROM ${report_date}) - 1, quantity, 0)) AS prior_year_qty,
  SUM(IF(year_yyyy = EXTRACT(YEAR FROM ${report_date}), quantity, 0)) AS current_year_qty
FROM ${ref("dach_sellout_enriched")}
WHERE soc_num_txt = "101-channel text"
GROUP BY PG, Markt_Haendlernummer, Program_MLI_Groups, SOC_num_txt, TN_Teilebonus_Status
```
