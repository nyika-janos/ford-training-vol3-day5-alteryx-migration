# IBIS 2026 BEL/NLD GCP megoldás

Ez a mappa az `IBIS_2026_BEL_NLD.yxmd` workflow BigQuery + Dataform migrációs megoldását tartalmazza.

A Dataform forráskód publikus GitHub repositoryban is elérhető:

```text
https://github.com/nyika-janos/03_IBIS_2026_BEL_NLD
```

## Futtatási sorrend

Az alábbi parancsokat a `03_IBIS_2026_BEL_NLD` mappából futtasd.

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

5. Dataform repository létrehozása GCP-ben, majd összekapcsolása a fenti GitHub repositoryval. A Dataform projekt gyökere az a könyvtár legyen, ahol a `workflow_settings.yaml` található: ebben a megoldásban `solution/dataform/`, vagy a GitHub repo gyökere, ha csak ennek a mappának a tartalma lett feltöltve.

6. Dataform futtatása:

```text
stage -> intermediate -> gold -> assertions
```

## Mit állít elő?

Az Alteryx BEL/NLD IBIS kimeneteinek megfelelő BigQuery táblákat/view-kat:

```text
03_ibis_bel_nld_gold.ibis_market_salesdata
03_ibis_bel_nld_gold.ibis_market_salesdata_finis
03_ibis_bel_nld_gold.ibis_nld_salesdata
03_ibis_bel_nld_gold.ibis_bel_salesdata
03_ibis_bel_nld_gold.ibis_nld_salesdata_finis
03_ibis_bel_nld_gold.ibis_bel_salesdata_finis
```

## Fontos

A raw Excel fájlok a workflow BigQuery inputjainak exportjai. Ha ugyanazokat az inputokat töltjük be, akkor a Dataform gold táblák az Alteryx transzformációival ekvivalens eredményt céloznak: BEL/NLD sales union, MLI mapping join, FINIS parts join és sales aggregáció.
