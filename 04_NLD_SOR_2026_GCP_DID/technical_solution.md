# Technikai megoldás: NLD SOR 2026 GCP DID

## Rövid válasz az eredményegyezőségre

Ha ugyanazokat az input extractokat használjuk, mint amelyeket az Alteryx workflow kapott, akkor a Dataform `gold.nld_sor_salesdata` tábla ugyanazt a logikai eredményt célozza, mint az Alteryx `NLD_SOR_SalesData_2026.xlsx / SalesData` kimenete.

Az egyezőség feltételei:

- a `SOR_NLD_input.xlsx` ugyanazt a 2026-os NLD SOR exportot tartalmazza;
- a `DID_NLD_input.xlsx` ugyanazt a DID dealer master exportot tartalmazza;
- a `MLI Classification.xlsx` fájlból az `Alteryx` sheetet használjuk;
- `MLI` mindenhol 4 karakterre paddingelve van;
- `DealerCode` stringként marad, hogy a vezető nullák ne vesszenek el;
- a pénzügyi és mennyiségi mezők `NUMERIC` típusra konvertálódnak a stage rétegben;
- a végső output megtartja a SOR export grainjét, és DID/MLI lookup mezőkkel gazdagítja.

Fontos: a lokális sample ellenőrzés alapján az MLI mapping teljes, viszont a DID dealer mapping részleges. Ezért a DID coverage validációs queryként szerepel, nem blokkoló Dataform assertionként.

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
    schema_nld_sor_raw.json
    schema_nld_did_raw.json
    schema_mli_classification_alteryx_raw.json
  generated_csv/
    nld_sor_raw.csv
    nld_did_raw.csv
    mli_classification_alteryx_raw.csv
  dataform/
    workflow_settings.yaml
    includes/config.js
    definitions/stage/nld_sor_stage.sqlx
    definitions/stage/nld_did_stage.sqlx
    definitions/stage/mli_classification_stage.sqlx
    definitions/intermediate/nld_sor_enriched.sqlx
    definitions/gold/nld_sor_salesdata.sqlx
    definitions/assertions/assertion_nld_sor_required_fields.sqlx
    definitions/assertions/assertion_nld_sor_mli_join_coverage.sqlx
    definitions/assertions/assertion_nld_sor_gold_not_empty.sqlx
```

## 1. Projekt- és dataset-nevek

A tréning project:

```text
ford-training-430008
```

A 04-es workflow datasetjei `04_` prefixszel kezdődnek, hogy BigQuery Explorerben ABC rendezéssel együtt látszódjanak:

```text
04_nld_sor_raw
04_nld_sor_stage
04_nld_sor_intermediate
04_nld_sor_gold
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

Futtatás a `04_NLD_SOR_2026_GCP_DID` mappából:

```bash
bq query --use_legacy_sql=false < solution/bigquery/01_create_datasets.sql
```

A script négy datasetet hoz létre:

```sql
CREATE SCHEMA IF NOT EXISTS `ford-training-430008.04_nld_sor_raw`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.04_nld_sor_stage`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.04_nld_sor_intermediate`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.04_nld_sor_gold`
OPTIONS(location = "europe-west4");
```

## 3. Raw táblák létrehozása

Fájl:

```text
solution/bigquery/02_create_raw_tables.sql
```

Raw táblák:

```text
04_nld_sor_raw.nld_sor_raw
04_nld_sor_raw.nld_did_raw
04_nld_sor_raw.mli_classification_alteryx_raw
```

A raw táblákban minden mező `STRING`. Ennek oka:

- `DealerCode` és `MLI` azonosítók, nem numerikus üzleti metrikák;
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
input/SOR_NLD_input.xlsx
input/DID_NLD_input.xlsx
input/MLI Classification.xlsx
```

Exportált CSV-k:

```text
solution/generated_csv/nld_sor_raw.csv
solution/generated_csv/nld_did_raw.csv
solution/generated_csv/mli_classification_alteryx_raw.csv
```

Futtatás:

```bash
python3 solution/bigquery/03_export_xlsx_to_csv.py
```

A lokálisan generált CSV sorok száma headerrel együtt:

```text
nld_sor_raw.csv                       1001
nld_did_raw.csv                       1001
mli_classification_alteryx_raw.csv     549
```

## 5. CSV schema JSON fájlok

Fájlok:

```text
solution/bigquery/schema_nld_sor_raw.json
solution/bigquery/schema_nld_did_raw.json
solution/bigquery/schema_mli_classification_alteryx_raw.json
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

A script három `bq load` hívást futtat:

```text
nld_sor_raw.csv                       -> 04_nld_sor_raw.nld_sor_raw
nld_did_raw.csv                       -> 04_nld_sor_raw.nld_did_raw
mli_classification_alteryx_raw.csv    -> 04_nld_sor_raw.mli_classification_alteryx_raw
```

Alapértelmezett project, location és dataset:

```bash
PROJECT_ID="ford-training-430008"
LOCATION="europe-west4"
RAW_DATASET="04_nld_sor_raw"
```

## 7. Dataform repository létrehozása

GCP Console-ban:

1. BigQuery -> Dataform.
2. Create repository.
3. Repository név például:

```text
04-nld-sor-2026-gcp-did
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
defaultDataset: 04_nld_sor_gold
vars:
  raw_dataset: 04_nld_sor_raw
  stage_dataset: 04_nld_sor_stage
  intermediate_dataset: 04_nld_sor_intermediate
  gold_dataset: 04_nld_sor_gold
```

Az `includes/config.js` innen olvassa a dataset neveket, ezért később elég egy helyen átírni a környezeti konfigurációt.

## 9. Stage modellek

### `nld_sor_stage.sqlx`

A SOR raw inputot tisztítja és típusosítja:

```sql
SELECT
  UPPER(TRIM(CAST(Market AS STRING))) AS Market,
  TRIM(CAST(DealerCode AS STRING)) AS DealerCode,
  LPAD(TRIM(CAST(MLI AS STRING)), 4, "0") AS MLI,
  TRIM(CAST(Months AS STRING)) AS Months,
  TRIM(CAST(channel AS STRING)) AS channel,
  TRIM(CAST(payment AS STRING)) AS payment,
  SAFE_CAST(BusinessY AS INT64) AS BusinessY,
  SAFE_CAST(BusinessM AS INT64) AS BusinessM,
  SAFE_CAST(BusinessQ AS INT64) AS BusinessQ,
  TRIM(CAST(MKTG AS STRING)) AS MKTG,
  TRIM(CAST(UCC AS STRING)) AS UCC,
  TRIM(CAST(channel_1 AS STRING)) AS channel_1,
  SAFE_CAST(LOC_Invoiced AS NUMERIC) AS LOC_Invoiced,
  SAFE_CAST(LOC_BDN AS NUMERIC) AS LOC_BDN,
  SAFE_CAST(LOC_RRP AS NUMERIC) AS LOC_RRP,
  SAFE_CAST(USD_Invoiced AS NUMERIC) AS USD_Invoiced,
  SAFE_CAST(USD_BDN AS NUMERIC) AS USD_BDN,
  SAFE_CAST(USD_RRP AS NUMERIC) AS USD_RRP,
  SAFE_CAST(qty AS NUMERIC) AS qty
FROM `${raw_dataset}.nld_sor_raw`
```

### `nld_did_stage.sqlx`

A DID inputból egyedi dealer lookupot készít:

```sql
SELECT DISTINCT
  UPPER(TRIM(CAST(i22_iso_mktcd AS STRING))) AS Market,
  TRIM(CAST(i22_dealer_cd AS STRING)) AS DealerCode,
  TRIM(CAST(i22_dlrname AS STRING)) AS DealerName
FROM `${raw_dataset}.nld_did_raw`
WHERE UPPER(TRIM(CAST(i22_iso_mktcd AS STRING))) = "NLD"
  AND i22_dealer_cd IS NOT NULL
```

### `mli_classification_stage.sqlx`

Az MLI klasszifikációt normalizálja:

```sql
SELECT DISTINCT
  LPAD(TRIM(CAST(text_mli AS STRING)), 4, "0") AS MLI,
  TRIM(CAST(mli_description AS STRING)) AS MLI_DESCRIPTION,
  TRIM(CAST(basket AS STRING)) AS Basket,
  TRIM(CAST(mpl_code AS STRING)) AS MPL_Code,
  TRIM(CAST(pct_code AS STRING)) AS PCT,
  TRIM(CAST(cg_code AS STRING)) AS CG_Code
FROM `${raw_dataset}.mli_classification_alteryx_raw`
WHERE text_mli IS NOT NULL
```

## 10. Intermediate modell

Fájl:

```text
solution/dataform/definitions/intermediate/nld_sor_enriched.sqlx
```

Logika:

- SOR stage join DID dealer lookupra `Market`, `DealerCode` alapján;
- SOR stage join MLI klasszifikációra `MLI` alapján;
- technikai coverage flag mezők létrehozása:
  - `DidMappingFound`
  - `MliMappingFound`

A join:

```sql
FROM ${ref("nld_sor_stage")} AS s
LEFT JOIN ${ref("nld_did_stage")} AS d
  ON s.Market = d.Market
 AND s.DealerCode = d.DealerCode
LEFT JOIN ${ref("mli_classification_stage")} AS m
  ON s.MLI = m.MLI
```

## 11. Gold modell

Fájl:

```text
solution/dataform/definitions/gold/nld_sor_salesdata.sqlx
```

Kimenet:

```text
04_nld_sor_gold.nld_sor_salesdata
```

A gold tábla megtartja a SOR input grainjét, és hozzáadja a DID/MLI lookup mezőket:

```sql
SELECT
  Market,
  DealerCode,
  DealerName,
  MLI,
  Basket,
  Months,
  channel,
  payment,
  BusinessY,
  BusinessM,
  BusinessQ,
  LOC_Invoiced,
  LOC_BDN,
  LOC_RRP,
  USD_Invoiced,
  USD_BDN,
  USD_RRP,
  qty,
  channel_1,
  MPL_Code AS `MPL Code`,
  PCT,
  CG_Code AS `CG Code`
FROM ${ref("nld_sor_enriched")}
```

## 12. Assertionök

Dataform assertion fájlok:

```text
assertion_nld_sor_required_fields.sqlx
assertion_nld_sor_mli_join_coverage.sqlx
assertion_nld_sor_gold_not_empty.sqlx
```

Ellenőrzések:

- kötelező mezők nem üresek: `Market`, `DealerCode`, `MLI`, `Months`;
- minden SOR sor kap MLI mappinget;
- a gold salesdata tábla nem üres.

A DID coverage szándékosan nem assertion, mert a jelenlegi sample alapján részleges. Ezt a validációs SQL mutatja ki.

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
- stage hónap szerinti aggregált metrikáit;
- hiányzó DID dealer mappingeket;
- hiányzó MLI mappingeket;
- gold hónap szerinti aggregált metrikáit.

## 14. Lokális sample coverage

A generált CSV-k alapján:

```text
nld_sor_raw rows: 1000
missing_mli:      0
missing_did:      882
```

Ez azt jelenti, hogy az MLI join a sample-ben teljes, a DID lookup viszont nem fedi le az összes SOR dealer kódot.

## 15. Alteryx összevetési checklist

A tréningen az egyezőséget így érdemes ellenőrizni:

1. Raw sorok száma megegyezik az Excel inputokkal.
2. `nld_sor_stage` hónap szerinti aggregált pénzügyi és qty metrikái megegyeznek a raw SOR inputtal.
3. `assertion_nld_sor_mli_join_coverage` nem ad vissza sort.
4. `nld_sor_salesdata` oszloplistája megfelel az Alteryx végső select/output mezőinek.
5. A DID coverage eltéréseket külön kell egyeztetni az üzleti ownerrel, mert a sample DID input nem teljes dealer masternek tűnik.

## 16. Production forrás opció

A training solution fájl alapú CSV betöltést használ. Production migrációban a raw Excel export lépés kiváltható közvetlen BigQuery source táblákkal vagy scheduled extracttel.

A Dataform logika ettől nem változik: csak a raw dataset tábláit kell ugyanazzal a sémával feltölteni, majd a stage -> intermediate -> gold modelleket futtatni.
