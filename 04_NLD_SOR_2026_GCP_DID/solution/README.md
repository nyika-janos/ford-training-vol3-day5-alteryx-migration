# NLD SOR 2026 GCP DID megoldás

Ez a mappa a `NLD_SOR_2026_GCP_DID.yxmd` workflow BigQuery + Dataform migrációs megoldását tartalmazza.

## Futtatási sorrend

Az alábbi parancsokat a `04_NLD_SOR_2026_GCP_DID` mappából futtasd.

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

Megjegyzés: a DID dealer coverage a sample alapján részleges, ezért validációs queryben ellenőrizzük, nem blokkoló assertionként.

## Mit állít elő?

Az Alteryx NLD SOR outputjának megfelelő BigQuery gold táblát:

```text
04_nld_sor_gold.nld_sor_salesdata
```
