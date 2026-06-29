# Technikai megoldás: NLD_SOR_2026_GCP_DID

## Stage: SOR

```sql
config {
  type: "table",
  schema: require("../../includes/config").stage_dataset,
  name: "nld_sor_stage"
}

js {
  const { raw_dataset } = require("../../includes/config");
}

SELECT
  TRIM(CAST(Market AS STRING)) AS market,
  TRIM(CAST(DealerCode AS STRING)) AS dealer_code,
  LPAD(TRIM(CAST(MLI AS STRING)), 4, "0") AS mli,
  TRIM(CAST(Months AS STRING)) AS months,
  TRIM(CAST(channel AS STRING)) AS channel,
  TRIM(CAST(payment AS STRING)) AS payment,
  SAFE_CAST(BusinessY AS INT64) AS business_year,
  SAFE_CAST(BusinessM AS INT64) AS business_month,
  SAFE_CAST(BusinessQ AS INT64) AS business_quarter,
  TRIM(CAST(MKTG AS STRING)) AS mktg,
  TRIM(CAST(UCC AS STRING)) AS ucc,
  SAFE_CAST(LOC_Invoiced AS NUMERIC) AS loc_invoiced,
  SAFE_CAST(LOC_BDN AS NUMERIC) AS loc_bdn,
  SAFE_CAST(LOC_RRP AS NUMERIC) AS loc_rrp,
  SAFE_CAST(USD_Invoiced AS NUMERIC) AS usd_invoiced,
  SAFE_CAST(USD_BDN AS NUMERIC) AS usd_bdn,
  SAFE_CAST(USD_RRP AS NUMERIC) AS usd_rrp,
  SAFE_CAST(qty AS NUMERIC) AS qty
FROM `${raw_dataset}.nld_sor`
```

## Stage: DID

```sql
config {
  type: "table",
  schema: require("../../includes/config").stage_dataset,
  name: "nld_did_stage"
}

js {
  const { raw_dataset } = require("../../includes/config");
}

SELECT DISTINCT
  TRIM(CAST(i22_iso_mktcd AS STRING)) AS market,
  TRIM(CAST(i22_dealer_cd AS STRING)) AS dealer_code,
  TRIM(CAST(i22_dlrname AS STRING)) AS dealer_name
FROM `${raw_dataset}.nld_did`
WHERE TRIM(CAST(i22_iso_mktcd AS STRING)) = "NLD"
```

## Intermediate

```sql
config {
  type: "table",
  schema: require("../../includes/config").intermediate_dataset,
  name: "nld_sor_enriched"
}

SELECT
  s.*,
  d.dealer_name,
  m.basket,
  m.pct
FROM ${ref("nld_sor_stage")} s
LEFT JOIN ${ref("nld_did_stage")} d
  ON s.market = d.market
 AND s.dealer_code = d.dealer_code
LEFT JOIN ${ref("mli_classification_stage")} m
  ON s.mli = m.mli
```

## Gold

```sql
config {
  type: "table",
  schema: require("../../includes/config").gold_dataset,
  name: "nld_sor_salesdata"
}

SELECT
  market AS Market,
  dealer_code AS DealerCode,
  dealer_name AS DealerName,
  mli AS MLI,
  basket AS Basket,
  pct AS PCT,
  months AS Months,
  channel,
  payment,
  business_year AS BusinessY,
  business_month AS BusinessM,
  business_quarter AS BusinessQ,
  mktg AS MKTG,
  ucc AS UCC,
  loc_invoiced AS LOC_Invoiced,
  loc_bdn AS LOC_BDN,
  loc_rrp AS LOC_RRP,
  usd_invoiced AS USD_Invoiced,
  usd_bdn AS USD_BDN,
  usd_rrp AS USD_RRP,
  qty
FROM ${ref("nld_sor_enriched")}
```

## Assertion

```sql
config {
  type: "assertion",
  schema: require("../../includes/config").gold_dataset,
  name: "assertion_nld_sor_did_join_coverage"
}

SELECT *
FROM ${ref("nld_sor_enriched")}
WHERE dealer_name IS NULL
```
