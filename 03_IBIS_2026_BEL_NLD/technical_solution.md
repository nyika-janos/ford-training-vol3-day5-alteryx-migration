# Technikai megoldás: IBIS_2026_BEL_NLD

## Stage: IBIS sales

```sql
config {
  type: "table",
  schema: require("../../includes/config").stage_dataset,
  name: "ibis_sales_stage"
}

js {
  const { raw_dataset } = require("../../includes/config");
}

WITH unioned AS (
  SELECT * FROM `${raw_dataset}.ibis_nld`
  UNION ALL
  SELECT * FROM `${raw_dataset}.ibis_bel`
)

SELECT
  TRIM(CAST(market AS STRING)) AS market,
  TRIM(CAST(MKT_CUSTOMER_ID_C AS STRING)) AS customer_id,
  TRIM(CAST(SSA_TRADE_N AS STRING)) AS trade_name,
  TRIM(CAST(billing_country AS STRING)) AS billing_country,
  TRIM(CAST(FINIS AS STRING)) AS finis,
  LPAD(TRIM(CAST(MLI AS STRING)), 4, "0") AS mli,
  TRIM(CAST(MDSMT_MNTHYR_Y AS STRING)) AS month_yyyymm,
  SAFE_CAST(LOC_BDN AS NUMERIC) AS loc_bdn,
  SAFE_CAST(gross_revenue AS NUMERIC) AS gross_revenue,
  SAFE_CAST(billed_revenue AS NUMERIC) AS billed_revenue,
  SAFE_CAST(gross_pieces AS NUMERIC) AS gross_pieces
FROM unioned
```

## Stage: Parts

```sql
config {
  type: "table",
  schema: require("../../includes/config").stage_dataset,
  name: "nld_parts_stage"
}

js {
  const { raw_dataset } = require("../../includes/config");
}

SELECT DISTINCT
  TRIM(CAST(FINIS AS STRING)) AS finis,
  TRIM(CAST(part_description AS STRING)) AS part_description
FROM `${raw_dataset}.nld_parts`
WHERE FINIS IS NOT NULL
```

## Intermediate

```sql
config {
  type: "table",
  schema: require("../../includes/config").intermediate_dataset,
  name: "ibis_bel_nld_enriched"
}

SELECT
  s.market,
  s.customer_id,
  s.trade_name,
  s.billing_country,
  s.finis,
  p.part_description,
  s.mli,
  m.basket,
  m.pct,
  s.month_yyyymm,
  s.loc_bdn,
  s.gross_revenue,
  s.billed_revenue,
  s.gross_pieces
FROM ${ref("ibis_sales_stage")} s
LEFT JOIN ${ref("mli_classification_stage")} m
  ON s.mli = m.mli
LEFT JOIN ${ref("nld_parts_stage")} p
  ON s.finis = p.finis
```

## Gold: market sales

```sql
config {
  type: "table",
  schema: require("../../includes/config").gold_dataset,
  name: "ibis_market_salesdata"
}

SELECT
  market,
  customer_id AS MKT_CUSTOMER_ID_C,
  trade_name AS SSA_TRADE_N,
  month_yyyymm AS MDSMT_MNTHYR_Y,
  mli AS MLI,
  basket AS Basket,
  SUM(billed_revenue) AS Sum_billed_revenue,
  SUM(gross_revenue) AS Sum_gross_revenue,
  SUM(loc_bdn) AS Sum_LOC_BDN,
  SUM(gross_pieces) AS Sum_gross_pieces
FROM ${ref("ibis_bel_nld_enriched")}
GROUP BY market, MKT_CUSTOMER_ID_C, SSA_TRADE_N, MDSMT_MNTHYR_Y, MLI, Basket
```

## Gold: FINIS sales

```sql
config {
  type: "table",
  schema: require("../../includes/config").gold_dataset,
  name: "ibis_market_salesdata_finis"
}

SELECT
  market,
  customer_id AS MKT_CUSTOMER_ID_C,
  trade_name AS SSA_TRADE_N,
  month_yyyymm AS MDSMT_MNTHYR_Y,
  mli AS MLI,
  basket AS Basket,
  pct AS PCT,
  finis AS FINIS,
  part_description,
  SUM(billed_revenue) AS Sum_billed_revenue,
  SUM(gross_revenue) AS Sum_gross_revenue,
  SUM(loc_bdn) AS Sum_LOC_BDN,
  SUM(gross_pieces) AS Sum_gross_pieces
FROM ${ref("ibis_bel_nld_enriched")}
GROUP BY market, MKT_CUSTOMER_ID_C, SSA_TRADE_N, MDSMT_MNTHYR_Y, MLI, Basket, PCT, FINIS, part_description
```

## Országspecifikus view-k

```sql
SELECT * FROM ${ref("ibis_market_salesdata")} WHERE market = "NLD";
SELECT * FROM ${ref("ibis_market_salesdata")} WHERE market = "BEL";
SELECT * FROM ${ref("ibis_market_salesdata_finis")} WHERE market = "NLD";
SELECT * FROM ${ref("ibis_market_salesdata_finis")} WHERE market = "BEL";
```
