# Technikai megoldás: UK_SOR_KAS_Dealers_v14_GCP

## Rövid válasz az eredményegyezőségre

Ha ugyanazt az inputot használjuk, mint amit az Alteryx workflow kap a BigQuery lekérdezésből, akkor a Dataform gold táblák ugyanazt a logikai eredményt adják, mint az Alteryx két Excel outputja:

```text
gold.uk_sor_kas_dealers     = Alteryx FORDUK_SOR_DEALERS_v1.xlsx / Sheet1
gold.uk_sor_kas_dealers_cv  = Alteryx FORDUK_SOR_DEALERS_CV_v1.xlsx / Sheet1
```

Az egyezőség feltételei:

- ugyanaz a source extract kerül a raw táblába;
- a `SALUTATION` split ugyanazzal a logikával fut: első szó = `SALUTATION`, maradék = `EMAIL`;
- a Data Cleansing lépésnek megfelelő uppercase/trim tisztítás elfogadott;
- a normál output `PV_CV != 'CV'`, a CV output `PV_CV = 'CV'`;
- a dátum/numerikus mezők típuseltéréseit validációkor figyelembe vesszük, mert az Excel és BigQuery nem mindig ugyanúgy jeleníti meg őket.

Ha nem a mellékelt CSV-ből, hanem újra az eredeti BigQuery SOR lekérdezésből indulunk, akkor csak akkor lesz teljesen ugyanaz az eredmény, ha ugyanarra a futási napra és ugyanarra a forrásállapotra fut. Az eredeti SQL `CURRENT_DATE - INTERVAL '10' DAY` szűrést használ, tehát időfüggő.

## Elkészített solution mappa

A futtatható tréninganyag ide került:

```text
solution/
  README.md
  bigquery/
    01_create_datasets.sql
    02_create_raw_table.sql
    03_load_csv.sh
    04_validation_queries.sql
    schema_uk_sor_kas_dealers_raw.json
  dataform/
    workflow_settings.yaml
    includes/config.js
    definitions/stage/uk_sor_kas_dealers_stage.sqlx
    definitions/gold/uk_sor_kas_dealers.sqlx
    definitions/gold/uk_sor_kas_dealers_cv.sqlx
    definitions/assertions/assertion_uk_sor_required_fields.sqlx
    definitions/assertions/assertion_uk_sor_gold_row_reconciliation.sqlx
```

## 1. Projekt- és dataset-nevek beállítása

A solution fájlokban a példa project id:

```text
ford-training-430008
```

Ezt a tréningen cserélni kell a tényleges GCP project id-ra.

Javasolt datasetek:

```text
01_uk_sor_raw
01_uk_sor_stage
01_uk_sor_gold
```

## 2. BigQuery datasetek létrehozása

Fájl:

```text
solution/bigquery/01_create_datasets.sql
```

Tartalom:

```sql
CREATE SCHEMA IF NOT EXISTS `ford-training-430008.01_uk_sor_raw`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.01_uk_sor_stage`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.01_uk_sor_gold`
OPTIONS(location = "europe-west4");
```

Futtatás:

```bash
bq query --use_legacy_sql=false < solution/bigquery/01_create_datasets.sql
```

## 3. Raw tábla létrehozása

Fájl:

```text
solution/bigquery/02_create_raw_table.sql
```

A raw tábla minden oszlopa `STRING`, mert az inputban több mező azonosító jellegű:

- dealer kód;
- telefonszám;
- rendszám;
- VIN;
- account code;
- email;
- postcode.

Így nem veszítünk vezető nullát, formátumot vagy speciális karaktert.

Futtatás:

```bash
bq query --use_legacy_sql=false < solution/bigquery/02_create_raw_table.sql
```

## 4. CSV schema JSON

Fájl:

```text
solution/bigquery/schema_uk_sor_kas_dealers_raw.json
```

Ez a `bq load` explicit sémája. A tréningen nem kell autodetectre hagyatkozni.

Részlet:

```json
[
  {"name": "MARKET", "type": "STRING", "mode": "NULLABLE"},
  {"name": "DEALER", "type": "STRING", "mode": "NULLABLE"},
  {"name": "DEPARTMENT", "type": "STRING", "mode": "NULLABLE"}
]
```

A teljes schema JSON a solution mappában van.

## 5. CSV betöltése BigQuery-be

Input fájl:

```text
input/Input_UK_SOR_KAS_Dealers_v14_GCP.csv
```

Load script:

```text
solution/bigquery/03_load_csv.sh
```

Futtatás a workflow mappából:

```bash
cd 01_UK_SOR_KAS_Dealers_v14_GCP

PROJECT_ID="ford-training-430008" \
RAW_DATASET="01_uk_sor_raw" \
CSV_PATH="input/Input_UK_SOR_KAS_Dealers_v14_GCP.csv" \
SCHEMA_PATH="solution/bigquery/schema_uk_sor_kas_dealers_raw.json" \
bash solution/bigquery/03_load_csv.sh
```

A script ezt csinálja:

```bash
bq load \
  --project_id="${PROJECT_ID}" \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter="," \
  --quote='"' \
  --allow_quoted_newlines=true \
  --encoding=UTF-8 \
  "${RAW_DATASET}.${TABLE_NAME}" \
  "${CSV_PATH}" \
  "${SCHEMA_PATH}"
```

## 6. Dataform repository létrehozása

GCP Console-ban:

1. BigQuery -> Dataform.
2. Create repository.
3. Repository név például:

```text
uk-sor-kas-dealers
```

4. Region:

```text
europe-west4
```

5. A repository workspace-be be kell másolni a `solution/dataform/` mappa tartalmát.

Alternatív tréningopció: a `solution/dataform/` mappa teljes tartalma lehet egy Git repo alapja is.

## 7. Dataform konfiguráció

Fájl:

```text
solution/dataform/workflow_settings.yaml
```

Tartalom:

```yaml
defaultProject: ford-training-430008
defaultLocation: europe-west4
defaultDataset: 01_uk_sor_gold

vars:
  raw_dataset: 01_uk_sor_raw
  stage_dataset: 01_uk_sor_stage
  gold_dataset: 01_uk_sor_gold
```

A project id itt már a tréning projectre van állítva: `ford-training-430008`.

## 8. Dataform modellek

### Stage

Fájl:

```text
solution/dataform/definitions/stage/uk_sor_kas_dealers_stage.sqlx
```

Feladata:

- raw CSV mezők beolvasása;
- string mezők `TRIM` + `UPPER` tisztítása az Alteryx Data Cleansing alapján;
- `INV_DATE` parse-olása;
- `INV_TOTAL_LOCAL` numerikus mezővé alakítása;
- `SALUTATION` szétbontása:
  - első token -> `SALUTATION`;
  - maradék -> `EMAIL`;
- eredeti `SALUTATION` mező elhagyása;
- Alteryx Select szerinti oszlopsorrend előállítása.

### Gold standard output

Fájl:

```text
solution/dataform/definitions/gold/uk_sor_kas_dealers.sqlx
```

Logika:

```sql
SELECT *
FROM ${ref("uk_sor_kas_dealers_stage")}
WHERE PV_CV != "CV"
```

Ez felel meg az Alteryx filter `True` ágának és a `FORDUK_SOR_DEALERS_v1.xlsx` outputnak.

### Gold CV output

Fájl:

```text
solution/dataform/definitions/gold/uk_sor_kas_dealers_cv.sqlx
```

Logika:

```sql
SELECT *
FROM ${ref("uk_sor_kas_dealers_stage")}
WHERE PV_CV = "CV"
```

Ez felel meg az Alteryx filter `False` ágának és a `FORDUK_SOR_DEALERS_CV_v1.xlsx` outputnak.

## 9. Assertions

Fájlok:

```text
solution/dataform/definitions/assertions/assertion_uk_sor_required_fields.sqlx
solution/dataform/definitions/assertions/assertion_uk_sor_gold_row_reconciliation.sqlx
```

Ellenőrzések:

- kötelező mezők ne legyenek nullok:
  - `MARKET`
  - `DEALER`
  - `PV_CV`
- stage sorszám egyezzen a két gold kimenet összegével.

## 10. Validációs lekérdezések

Fájl:

```text
solution/bigquery/04_validation_queries.sql
```

Futtatás:

```bash
bq query --use_legacy_sql=false < solution/bigquery/04_validation_queries.sql
```

Fontosabb ellenőrzés:

```sql
SELECT
  (
    SELECT COUNT(*) FROM `ford-training-430008.01_uk_sor_gold.uk_sor_kas_dealers`
  )
  +
  (
    SELECT COUNT(*) FROM `ford-training-430008.01_uk_sor_gold.uk_sor_kas_dealers_cv`
  ) AS gold_rows_total,
  (
    SELECT COUNT(*) FROM `ford-training-430008.01_uk_sor_raw.uk_sor_kas_dealers_raw`
  ) AS raw_rows;
```

## 11. Mit kell még validálni Alteryx ellen?

Az első workflow esetén nincs aggregáció, ezért az egyezés főleg sor- és oszlopszintű:

1. Raw sorszám.
2. `PV_CV != 'CV'` sorszám.
3. `PV_CV = 'CV'` sorszám.
4. Oszloplista és oszlopsorrend.
5. Mintasor összehasonlítás:
   - `VIN`;
   - `DEALER`;
   - `INV_DATE`;
   - `INV_TOTAL_LOCAL`;
   - `SALUTATION`;
   - `EMAIL`.

## 12. Production source opció

A mellékelt CSV a BigQuery input query exportja. Production migrációban két lehetőség van:

1. A CSV helyett az eredeti BigQuery SQL-ből létrehozunk egy `raw/source` view-t.
2. A meglévő upstream pipeline tölti a `01_uk_sor_raw.uk_sor_kas_dealers_raw` táblát.

Az első opció előnye, hogy közelebb marad az Alteryxhez. A második opció előnye, hogy egyszerűbb tréning- és batch-folyamatot ad.
