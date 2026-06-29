# HU napi sell-in GCP megoldás

Ez a mappa a `Workflow to get sell-in data daily on HU market_tianze.yxmd` workflow BigQuery + Dataform migrációs megoldását tartalmazza.

## Futtatási sorrend

Az alábbi parancsokat a `02_HU_sell_in_daily` mappából futtasd.

1. BigQuery datasetek létrehozása:

```bash
bq query --use_legacy_sql=false < solution/bigquery/01_create_datasets.sql
```

2. Raw táblák létrehozása:

```bash
bq query --use_legacy_sql=false < solution/bigquery/02_create_raw_tables.sql
```

3. Excel inputok exportálása CSV-be:

```bash
python3 solution/bigquery/03_export_xlsx_to_csv.py
```

4. CSV-k betöltése BigQuery-be:

```bash
bash solution/bigquery/04_load_csv.sh
```

5. Dataform repository létrehozása GCP-ben, majd a `solution/dataform/` mappa tartalmának bemásolása a repositoryba.

6. Dataform futtatása:

```text
stage -> intermediate -> gold -> assertions
```

## Mit állít elő?

Az Alteryx `HU_Sell_in.xlsx / Sheet1` kimenetének megfelelő BigQuery táblát:

```text
02_hu_sell_in_gold.hu_sell_in
```

## Fontos

A raw Excel fájlok a workflow BigQuery inputjainak exportjai. Ha ugyanazokat az inputokat töltjük be, akkor a Dataform gold tábla az Alteryx CSV/Excel utáni transzformációival ekvivalens eredményt céloz: MLI padding, MLI mapping join, SOR parts price számítás, FINIS join, fallback BDN és végső aggregáció.
