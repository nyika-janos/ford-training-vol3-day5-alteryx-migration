# Technikai megoldás: IBIS 2026 BEL/NLD

## Rövid válasz az eredményegyezőségre

Ha ugyanazokat az input extractokat használjuk, mint amelyeket az Alteryx workflow kapott, akkor a Dataform gold táblák ugyanazt a logikai eredményt célozzák, mint az Alteryx BEL és NLD IBIS kimenetei.

Az egyezőség feltételei:

- a `NLD_IBIS_input.xlsx` és `BEL_IBIS_input.xlsx` ugyanazokat az IBIS exportokat tartalmazza;
- a `MLI Classification.xlsx` fájlból az `Alteryx` sheetet használjuk;
- az `NLD_parts_input.xlsx` ugyanazt a parts lookup extractot tartalmazza;
- `MLI` mindenhol 4 karakterre paddingelve van;
- `FINIS` stringként marad, hogy ne vesszenek el vezető nullák;
- a sales metrikák `NUMERIC` típusra konvertálódnak a stage rétegben;
- az aggregáció ugyanazon grainen történik, mint az Alteryx summarize lépéseiben.

Fontos: a mellékelt `NLD_parts_input.xlsx` sample a lokális ellenőrzés alapján nem fed át az IBIS sample FINIS értékeivel. Ezért a FINIS parts coverage validációs query, nem blokkoló assertion. Az MLI mapping coverage a generált CSV-k alapján 0 hiányzó sort mutat.

## Elkészített solution mappa

```text
solution/
  README.md
  bigquery/
    01_create_datasets.sql
    02_create_raw_tables.sql
    03_export_xlsx_to_csv.py
    04_load_csv.sh
    05_validation_queries.sql
    schema_ibis_sales_raw.json
    schema_mli_classification_alteryx_raw.json
    schema_nld_parts_raw.json
  generated_csv/
    ibis_nld_raw.csv
    ibis_bel_raw.csv
    mli_classification_alteryx_raw.csv
    nld_parts_raw.csv
  dataform/
    workflow_settings.yaml
    includes/config.js
    definitions/stage/mli_classification_stage.sqlx
    definitions/stage/ibis_sales_stage.sqlx
    definitions/stage/nld_parts_stage.sqlx
    definitions/intermediate/ibis_bel_nld_enriched.sqlx
    definitions/gold/ibis_market_salesdata.sqlx
    definitions/gold/ibis_market_salesdata_finis.sqlx
    definitions/gold/ibis_nld_salesdata.sqlx
    definitions/gold/ibis_bel_salesdata.sqlx
    definitions/gold/ibis_nld_salesdata_finis.sqlx
    definitions/gold/ibis_bel_salesdata_finis.sqlx
    definitions/assertions/assertion_ibis_required_fields.sqlx
    definitions/assertions/assertion_ibis_mli_join_coverage.sqlx
    definitions/assertions/assertion_ibis_gold_not_empty.sqlx
```

## 1. Projekt- és dataset-nevek

A tréning project:

```text
ford-training-430008
```

A 03-as workflow datasetjei `03_` prefixszel kezdődnek, hogy BigQuery Explorerben ABC rendezéssel együtt látszódjanak:

```text
03_ibis_bel_nld_raw
03_ibis_bel_nld_stage
03_ibis_bel_nld_intermediate
03_ibis_bel_nld_gold
```

Location mindenhol:

```text
europe-west4
```

## 2. BigQuery datasetek létrehozása

Fájl:

```text
solution/bigquery/01_create_datasets.sql
```

Futtatás a `03_IBIS_2026_BEL_NLD` mappából:

```bash
bq query --use_legacy_sql=false < solution/bigquery/01_create_datasets.sql
```

A script négy datasetet hoz létre:

```sql
CREATE SCHEMA IF NOT EXISTS `ford-training-430008.03_ibis_bel_nld_raw`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.03_ibis_bel_nld_stage`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.03_ibis_bel_nld_intermediate`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.03_ibis_bel_nld_gold`
OPTIONS(location = "europe-west4");
```

## 3. Raw táblák létrehozása

Fájl:

```text
solution/bigquery/02_create_raw_tables.sql
```

Raw táblák:

```text
03_ibis_bel_nld_raw.ibis_nld_raw
03_ibis_bel_nld_raw.ibis_bel_raw
03_ibis_bel_nld_raw.mli_classification_alteryx_raw
03_ibis_bel_nld_raw.nld_parts_raw
```

A raw táblákban minden mező `STRING`. Ennek oka:

- `FINIS` és `MLI` azonosítók, nem numerikus üzleti metrikák;
- Excel importnál vezető nullák sérülhetnek;
- a típuskonverziót Dataform stage modellekben kontrolláltan végezzük.

Futtatás:

```bash
bq query --use_legacy_sql=false < solution/bigquery/02_create_raw_tables.sql
```

## 4. Excel inputok CSV-vé alakítása

A BigQuery `bq load` egyszerűen CSV-t kezel, ezért az Excel inputokat először CSV-be exportáljuk.

Fájl:

```text
solution/bigquery/03_export_xlsx_to_csv.py
```

Bemenetek:

```text
input/NLD_IBIS_input.xlsx
input/BEL_IBIS_input.xlsx
input/MLI Classification.xlsx
input/NLD_parts_input.xlsx
```

Exportált CSV-k:

```text
solution/generated_csv/ibis_nld_raw.csv
solution/generated_csv/ibis_bel_raw.csv
solution/generated_csv/mli_classification_alteryx_raw.csv
solution/generated_csv/nld_parts_raw.csv
```

Futtatás:

```bash
python3 solution/bigquery/03_export_xlsx_to_csv.py
```

A lokálisan generált CSV sorok száma headerrel együtt:

```text
ibis_nld_raw.csv                       1001
ibis_bel_raw.csv                       1001
mli_classification_alteryx_raw.csv      549
nld_parts_raw.csv                      1001
```

## 5. CSV schema JSON fájlok

Fájlok:

```text
solution/bigquery/schema_ibis_sales_raw.json
solution/bigquery/schema_mli_classification_alteryx_raw.json
solution/bigquery/schema_nld_parts_raw.json
```

Ezeket a `bq load` használja explicit sémaként, így nem kell autodetectre hagyatkozni.

## 6. CSV-k betöltése BigQuery-be

Fájl:

```text
solution/bigquery/04_load_csv.sh
```

Futtatás:

```bash
bash solution/bigquery/04_load_csv.sh
```

A script négy `bq load` hívást futtat:

```text
ibis_nld_raw.csv                       -> 03_ibis_bel_nld_raw.ibis_nld_raw
ibis_bel_raw.csv                       -> 03_ibis_bel_nld_raw.ibis_bel_raw
mli_classification_alteryx_raw.csv     -> 03_ibis_bel_nld_raw.mli_classification_alteryx_raw
nld_parts_raw.csv                      -> 03_ibis_bel_nld_raw.nld_parts_raw
```

Alapértelmezett project, location és dataset:

```bash
PROJECT_ID="ford-training-430008"
LOCATION="europe-west4"
RAW_DATASET="03_ibis_bel_nld_raw"
```

## 7. Dataform repository létrehozása

GCP Console-ban:

1. BigQuery -> Dataform.
2. Create repository.
3. Repository név például:

```text
03-ibis-2026-bel-nld
```

4. Region:

```text
europe-west4
```

5. A `solution/dataform/` mappa tartalmát másold be a Dataform repository gyökerébe.

## 8. Dataform konfiguráció

Fájl:

```text
solution/dataform/workflow_settings.yaml
```

Tartalom:

```yaml
defaultProject: ford-training-430008
defaultLocation: europe-west4
defaultDataset: 03_ibis_bel_nld_gold
vars:
  raw_dataset: 03_ibis_bel_nld_raw
  stage_dataset: 03_ibis_bel_nld_stage
  intermediate_dataset: 03_ibis_bel_nld_intermediate
  gold_dataset: 03_ibis_bel_nld_gold
```

Az `includes/config.js` innen olvassa a dataset neveket, ezért később elég egy helyen átírni a környezeti konfigurációt.

## 9. Stage modellek

### `mli_classification_stage.sqlx`

Normalizálja az MLI klasszifikációt:

```sql
SELECT DISTINCT
  LPAD(TRIM(CAST(text_mli AS STRING)), 4, "0") AS MLI,
  TRIM(CAST(mli_description AS STRING)) AS MLI_DESCRIPTION,
  TRIM(CAST(basket AS STRING)) AS Basket,
  TRIM(CAST(mpl_code AS STRING)) AS MPL,
  TRIM(CAST(pct_code AS STRING)) AS PCT,
  TRIM(CAST(cg_code AS STRING)) AS GC
FROM `${raw_dataset}.mli_classification_alteryx_raw`
WHERE text_mli IS NOT NULL
```

### `ibis_sales_stage.sqlx`

Unioneli az NLD és BEL IBIS inputokat, majd típusokat konvertál:

```sql
WITH source AS (
  SELECT * FROM `${raw_dataset}.ibis_nld_raw`
  UNION ALL
  SELECT * FROM `${raw_dataset}.ibis_bel_raw`
)

SELECT
  UPPER(TRIM(CAST(market AS STRING))) AS market,
  TRIM(CAST(MKT_CUSTOMER_ID_C AS STRING)) AS MKT_CUSTOMER_ID_C,
  TRIM(CAST(SSA_TRADE_N AS STRING)) AS SSA_TRADE_N,
  TRIM(CAST(billing_country AS STRING)) AS billing_country,
  TRIM(CAST(FINIS AS STRING)) AS FINIS,
  NULLIF(REGEXP_REPLACE(TRIM(CAST(FINIS AS STRING)), r"^0+", ""), "") AS FINIS_JOIN_KEY,
  LPAD(TRIM(CAST(MLI AS STRING)), 4, "0") AS MLI,
  TRIM(CAST(MDSMT_MNTHYR_Y AS STRING)) AS MDSMT_MNTHYR_Y,
  SAFE_CAST(LOC_BDN AS NUMERIC) AS LOC_BDN,
  SAFE_CAST(gross_revenue AS NUMERIC) AS gross_revenue,
  SAFE_CAST(billed_revenue AS NUMERIC) AS billed_revenue,
  SAFE_CAST(gross_pieces AS NUMERIC) AS gross_pieces,
  SUBSTR(TRIM(CAST(MDSMT_MNTHYR_Y AS STRING)), 1, 4) AS year,
  SUBSTR(TRIM(CAST(MDSMT_MNTHYR_Y AS STRING)), 5, 2) AS month
FROM source
```

### `nld_parts_stage.sqlx`

FINIS lookup normalizálás:

```sql
SELECT DISTINCT
  TRIM(CAST(FINIS AS STRING)) AS FINIS,
  NULLIF(REGEXP_REPLACE(TRIM(CAST(FINIS AS STRING)), r"^0+", ""), "") AS FINIS_JOIN_KEY,
  TRIM(CAST(part_description AS STRING)) AS part_description
FROM `${raw_dataset}.nld_parts_raw`
WHERE FINIS IS NOT NULL
```

## 10. Intermediate modell

Fájl:

```text
solution/dataform/definitions/intermediate/ibis_bel_nld_enriched.sqlx
```

Logika:

- IBIS sales stage join MLI klasszifikációval `MLI` alapján;
- IBIS sales stage join NLD parts lookup táblával normalizált `FINIS_JOIN_KEY` alapján;
- technikai coverage flag mezők létrehozása:
  - `MliMappingFound`
  - `PartsMappingFound`

A join:

```sql
FROM ${ref("ibis_sales_stage")} AS s
LEFT JOIN ${ref("mli_classification_stage")} AS m
  ON s.MLI = m.MLI
LEFT JOIN ${ref("nld_parts_stage")} AS p
  ON s.FINIS_JOIN_KEY = p.FINIS_JOIN_KEY
```

## 11. Gold modellek

### Market szintű salesdata

Fájl:

```text
solution/dataform/definitions/gold/ibis_market_salesdata.sqlx
```

Grain:

```text
market, MKT_CUSTOMER_ID_C, SSA_TRADE_N, billing_country, MLI, Basket, PCT, MDSMT_MNTHYR_Y, year, month
```

Metrikák:

```text
Sum_LOC_BDN
Sum_gross_revenue
Sum_billed_revenue
Sum_gross_pieces
```

### FINIS szintű salesdata

Fájl:

```text
solution/dataform/definitions/gold/ibis_market_salesdata_finis.sqlx
```

Grain:

```text
market, MKT_CUSTOMER_ID_C, SSA_TRADE_N, billing_country, FINIS, part_description, MLI, Basket, PCT, MDSMT_MNTHYR_Y, year, month
```

### Market-specifikus view-k

```text
ibis_nld_salesdata
ibis_bel_salesdata
ibis_nld_salesdata_finis
ibis_bel_salesdata_finis
```

Ezek a közös gold táblákból szűrnek `market = "NLD"` vagy `market = "BEL"` feltétellel.

## 12. Assertionök

Dataform assertion fájlok:

```text
assertion_ibis_required_fields.sqlx
assertion_ibis_mli_join_coverage.sqlx
assertion_ibis_gold_not_empty.sqlx
```

Ellenőrzések:

- kötelező mezők nem üresek: `market`, `FINIS`, `MLI`, `MDSMT_MNTHYR_Y`;
- minden IBIS sor kap MLI mappinget;
- a gold salesdata tábla nem üres.

A FINIS parts coverage szándékosan nem assertion, mert a jelenlegi sample alapján a parts extract nem fedi az IBIS sample FINIS tartományát.

## 13. Validációs queryk

Fájl:

```text
solution/bigquery/05_validation_queries.sql
```

Futtatás a Dataform run után:

```bash
bq query --use_legacy_sql=false < solution/bigquery/05_validation_queries.sql
```

A queryk ellenőrzik:

- raw táblák sorszámát;
- stage market/hónap aggregált metrikáit;
- hiányzó MLI mappingeket;
- hiányzó FINIS parts mappingeket;
- gold market/hónap aggregált metrikáit.

## 14. Alteryx összevetési checklist

A tréningen az egyezőséget így érdemes ellenőrizni:

1. Raw sorok száma megegyezik az Excel inputokkal.
2. `ibis_sales_stage` market/hónap összesített metrikái megegyeznek a raw IBIS inputokkal.
3. `assertion_ibis_mli_join_coverage` nem ad vissza sort.
4. `ibis_market_salesdata` market/hónap aggregált összegei megegyeznek az Alteryx salesdata kimenetekkel.
5. `ibis_market_salesdata_finis` grainje és metrikái megegyeznek az Alteryx FINIS kimenetekkel ott, ahol a parts lookup is fedést ad.

## 15. Production forrás opció

A training solution fájl alapú CSV betöltést használ. Production migrációban a raw Excel export lépés kiváltható közvetlen BigQuery source táblákkal vagy scheduled extracttel.

A Dataform logika ettől nem változik: csak a raw dataset tábláit kell ugyanazzal a sémával feltölteni, majd a stage -> intermediate -> gold modelleket futtatni.
