# UK SOR KAS Dealers GCP megoldás

Ez a mappa az `UK_SOR_KAS_Dealers_v14_GCP.yxmd` workflow BigQuery + Dataform migrációs megoldását tartalmazza.

A Dataform forráskód publikus GitHub repositoryban is elérhető:

```text
https://github.com/nyika-janos/01_UK_SOR_KAS_Dealers_v14_GCP
```

## Futtatási sorrend

Az alábbi parancsokat a `01_UK_SOR_KAS_Dealers_v14_GCP` mappából futtasd.

1. BigQuery datasetek létrehozása:

```bash
bq query --use_legacy_sql=false < solution/bigquery/01_create_datasets.sql
```

2. Raw tábla létrehozása:

```bash
bq query --use_legacy_sql=false < solution/bigquery/02_create_raw_table.sql
```

3. CSV betöltése:

```bash
PROJECT_ID="ford-training-430008" \
RAW_DATASET="01_uk_sor_raw" \
CSV_PATH="input/Input_UK_SOR_KAS_Dealers_v14_GCP.csv" \
bash solution/bigquery/03_load_csv.sh
```

4. Dataform repository létrehozása GCP-ben, majd összekapcsolása a fenti GitHub repositoryval. A Dataform projekt gyökere az a könyvtár legyen, ahol a `workflow_settings.yaml` található: ebben a megoldásban `solution/dataform/`, vagy a GitHub repo gyökere, ha csak ennek a mappának a tartalma lett feltöltve.

5. Dataform futtatása:

```text
stage -> gold -> assertions
```

## Mit állít elő?

Az Alteryx két Excel kimenetének megfelelő BigQuery táblákat:

```text
01_uk_sor_gold.uk_sor_kas_dealers
01_uk_sor_gold.uk_sor_kas_dealers_cv
```

Az első tábla a `PV_CV != 'CV'` ág, a második a `PV_CV = 'CV'` ág.

## Fontos

A raw CSV a workflow BigQuery inputjának exportja. Ha ugyanazt a CSV-t töltjük be, és a Dataform modellek futnak, akkor a gold táblák az Alteryx CSV utáni transzformációival ekvivalens eredményt adnak: salutation split, uppercase/trim tisztítás, select/rename, majd PV/CV bontás.

Production környezetben a raw CSV-t ki lehet váltani az eredeti BigQuery SOR lekérdezéssel vagy egy stabil source view-val.
