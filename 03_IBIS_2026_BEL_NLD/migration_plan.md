# Migrációs terv: IBIS_2026_BEL_NLD

## Célállapot

```text
raw.ibis_nld
raw.ibis_bel
raw.nld_parts
raw.mli_classification_alteryx
stage.ibis_sales_stage
stage.nld_parts_stage
stage.mli_classification_stage
intermediate.ibis_bel_nld_enriched
gold.ibis_nld_salesdata
gold.ibis_nld_salesdata_finis
gold.ibis_bel_salesdata
gold.ibis_bel_salesdata_finis
```

## Lépések

1. BEL, NLD, parts és MLI fájlok betöltése raw BigQuery táblákba.
2. BEL és NLD IBIS inputok unionolása egy közös staged táblába `market` mezővel.
3. `MLI` normalizálása 4 számjegyre, `FINIS` stringként megtartva.
4. Join MLI klasszifikációval.
5. Join parts adatokkal `FINIS` alapján.
6. Market szintű és FINIS szintű gold kimenetek létrehozása.
7. Totalok validálása market/month/MLI szerint.

## Validáció

```sql
SELECT market, MDSMT_MNTHYR_Y, SUM(Sum_billed_revenue), SUM(Sum_gross_pieces)
FROM `PROJECT_ID.gold.ibis_market_salesdata`
GROUP BY market, MDSMT_MNTHYR_Y
ORDER BY market, MDSMT_MNTHYR_Y;
```

## Kockázatok

- A parts input NLD névvel érkezett; meg kell erősíteni, hogy a BEL FINIS kimenet is ugyanezt a parts mastert használja-e production környezetben.
- Az MLI klasszifikációnál az `Alteryx` sheetet kell használni.
