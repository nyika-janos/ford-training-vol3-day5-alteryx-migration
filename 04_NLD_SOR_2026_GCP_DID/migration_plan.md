# Migrációs terv: NLD_SOR_2026_GCP_DID

## Célállapot

```text
raw.nld_sor
raw.nld_did
raw.mli_classification_alteryx
stage.nld_sor_stage
stage.nld_did_stage
stage.mli_classification_stage
intermediate.nld_sor_enriched
gold.nld_sor_salesdata
```

## Lépések

1. SOR, DID és MLI fájlok betöltése raw BigQuery táblákba.
2. SOR stage létrehozása, a numerikus metrikákat `NUMERIC` típusra castolva.
3. DID stage létrehozása egyedi market/dealer/dealer name mappingként.
4. MLI stage létrehozása 4 karakterre paddingelt `MLI` mezővel.
5. SOR joinolása DID és MLI adatokkal a `nld_sor_enriched` modellben.
6. `nld_sor_salesdata` publikálása.
7. DID és MLI join coverage validálása.

## Validáció

```sql
SELECT COUNT(*) AS missing_dealer_name
FROM `PROJECT_ID.intermediate.nld_sor_enriched`
WHERE dealer_name IS NULL;
```

```sql
SELECT months, SUM(loc_bdn), SUM(loc_rrp), SUM(qty)
FROM `PROJECT_ID.gold.nld_sor_salesdata`
GROUP BY months
ORDER BY months;
```

## Kockázatok

- A DID ismétlődő dealer sorokat tartalmazhat; `SELECT DISTINCT` vagy group by szükséges, hogy ne duplikálja a SOR tényadatokat.
- A `DealerCode` vezető nullákat tartalmazhat, ezért stringként kell kezelni.
