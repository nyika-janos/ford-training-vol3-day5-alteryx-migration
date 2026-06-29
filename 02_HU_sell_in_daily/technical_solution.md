# Technikai megoldás: HU napi sell-in

## Stage: MLI klasszifikáció

```sql
config {
  type: "table",
  schema: require("../../includes/config").stage_dataset,
  name: "mli_classification_stage"
}

js {
  const { raw_dataset } = require("../../includes/config");
}

SELECT DISTINCT
  LPAD(TRIM(CAST(`Text MLI` AS STRING)), 4, "0") AS mli,
  TRIM(CAST(`MLI DESCRIPTION` AS STRING)) AS mli_description,
  TRIM(CAST(Basket AS STRING)) AS basket,
  TRIM(CAST(`MPL Code` AS STRING)) AS mpl,
  TRIM(CAST(`PCT\ncode` AS STRING)) AS pct,
  TRIM(CAST(`CG\nCode` AS STRING)) AS gc
FROM `${raw_dataset}.mli_classification_alteryx`
WHERE `Text MLI` IS NOT NULL
```

## Stage: IBIS

```sql
config {
  type: "table",
  schema: require("../../includes/config").stage_dataset,
  name: "hu_ibis_stage"
}

js {
  const { raw_dataset } = require("../../includes/config");
}

SELECT
  TRIM(CAST(market AS STRING)) AS market,
  TRIM(CAST(DealerCode AS STRING)) AS dealer_code,
  TRIM(CAST(FINIS AS STRING)) AS finis,
  LPAD(TRIM(CAST(MLI AS STRING)), 4, "0") AS mli,
  TRIM(CAST(Months AS STRING)) AS months,
  SAFE_CAST(LOC_RRP AS NUMERIC) AS loc_rrp,
  SAFE_CAST(LOC_BDN AS NUMERIC) AS loc_bdn,
  SAFE_CAST(USD_RRP AS NUMERIC) AS usd_rrp,
  SAFE_CAST(USD_BDN AS NUMERIC) AS usd_bdn,
  SAFE_CAST(billed_revenue AS NUMERIC) AS billed_revenue,
  SAFE_CAST(qty AS NUMERIC) AS qty,
  SUBSTR(TRIM(CAST(Months AS STRING)), 1, 4) AS year,
  SUBSTR(TRIM(CAST(Months AS STRING)), 5, 2) AS month
FROM `${raw_dataset}.hu_ibis`
```

## Stage: SOR parts price

```sql
config {
  type: "table",
  schema: require("../../includes/config").stage_dataset,
  name: "hu_sor_parts_price_stage"
}

js {
  const { raw_dataset } = require("../../includes/config");
}

SELECT
  TRIM(CAST(EDWAO25_FINIS_C AS STRING)) AS finis,
  SAFE_CAST(EDWAO25_BASIC_DISCOUNT_P AS NUMERIC) AS basic_discount_pct,
  SAFE_CAST(EDWAO25_RTL_OR_NET_PRICE_A AS NUMERIC) AS rtl_or_net_price,
  SAFE_CAST(EDWAO25_RTL_OR_NET_PRICE_A AS NUMERIC)
    - SAFE_CAST(EDWAO25_RTL_OR_NET_PRICE_A AS NUMERIC)
      * SAFE_CAST(EDWAO25_BASIC_DISCOUNT_P AS NUMERIC) AS calculated_bdn_unit
FROM `${raw_dataset}.hu_sor_parts_price`
WHERE TRIM(CAST(EDWAO25_ISO2_CNTRY_C AS STRING)) = "HU"
  AND TRIM(CAST(EDWAO25_ACTIVE_F AS STRING)) = "Y"
```

## Intermediate

```sql
config {
  type: "table",
  schema: require("../../includes/config").intermediate_dataset,
  name: "hu_sell_in_enriched"
}

WITH parts_price AS (
  SELECT
    finis,
    MAX(calculated_bdn_unit) AS calculated_bdn_unit
  FROM ${ref("hu_sor_parts_price_stage")}
  GROUP BY finis
)

SELECT
  i.*,
  m.basket,
  m.mpl,
  m.pct,
  m.gc,
  COALESCE(p.calculated_bdn_unit * i.qty * 1000, i.loc_bdn) AS calculated_bdn
FROM ${ref("hu_ibis_stage")} i
LEFT JOIN ${ref("mli_classification_stage")} m
  ON i.mli = m.mli
LEFT JOIN parts_price p
  ON i.finis = p.finis
```

## Gold

```sql
config {
  type: "table",
  schema: require("../../includes/config").gold_dataset,
  name: "hu_sell_in"
}

SELECT
  market,
  dealer_code AS DealerCode,
  mli AS MLI,
  basket AS Basket,
  months AS Months,
  year,
  month,
  pct AS PCT,
  SUM(loc_rrp) AS LOC_RRP,
  SUM(loc_bdn) AS LOC_BDN,
  SUM(usd_rrp) AS USD_RRP,
  SUM(usd_bdn) AS USD_BDN,
  SUM(billed_revenue) AS billed_revenue,
  SUM(qty) AS qty,
  SUM(calculated_bdn) AS Sum_Calculated_BDN
FROM ${ref("hu_sell_in_enriched")}
GROUP BY market, DealerCode, MLI, Basket, Months, year, month, PCT
```
