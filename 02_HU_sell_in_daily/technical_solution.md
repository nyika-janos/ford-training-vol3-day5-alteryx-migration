# Technikai megoldás: HU napi sell-in

## Rövid válasz az eredményegyezőségre

Ha ugyanazokat az input extractokat használjuk, mint amelyeket az Alteryx workflow kapott, akkor a Dataform `gold.hu_sell_in` tábla ugyanazt a logikai eredményt célozza, mint az Alteryx `HU_Sell_in.xlsx / Sheet1` kimenete.

Az egyezőség feltételei:

- az `IBIS adatbázis.xlsx` ugyanazt a BigQuery/IBIS exportot tartalmazza;
- a `MLI Classification.xlsx` fájlból az `Alteryx` sheetet használjuk;
- a `SOR adatbázis Parts Price.xlsx` ugyanazt a HU aktív parts price exportot tartalmazza;
- `MLI` mindenhol 4 karakterre paddingelve van;
- `FINIS` stringként marad, hogy ne vesszenek el vezető nullák;
- a SOR parts price számítás ugyanaz:
  - `Calculated_BDN = EDWAO25_RTL_OR_NET_PRICE_A - EDWAO25_RTL_OR_NET_PRICE_A * EDWAO25_BASIC_DISCOUNT_P`;
- a végső fallback ugyanaz:
  - `COALESCE(parts_price.Calculated_BDN * qty * 1000, LOC_BDN)`;
- a végső aggregáció ugyanazon grainen történik: `market`, `DealerCode`, `MLI`, `Basket`, `Months`, `year`, `month`, `PCT`.

Fontos: production környezetben akkor lesz teljesen ugyanaz az eredmény, ha a forrás BigQuery lekérdezések ugyanarra az időszakra és forrásállapotra futnak. A mellékelt Excel fájlokkal a migráció logikája reprodukálható és tesztelhető.

## Elkészített solution mappa

A futtatható tréninganyag ide került:

```text
solution/
  README.md
  bigquery/
    01_create_datasets.sql
    02_create_raw_tables.sql
    03_export_xlsx_to_csv.py
    04_load_csv.sh
    05_validation_queries.sql
    schema_hu_ibis_raw.json
    schema_mli_classification_alteryx_raw.json
    schema_hu_sor_parts_price_raw.json
  generated_csv/
  dataform/
    workflow_settings.yaml
    includes/config.js
    definitions/stage/mli_classification_stage.sqlx
    definitions/stage/hu_ibis_stage.sqlx
    definitions/stage/hu_sor_parts_price_stage.sqlx
    definitions/intermediate/hu_sell_in_enriched.sqlx
    definitions/gold/hu_sell_in.sqlx
    definitions/assertions/assertion_hu_ibis_required_fields.sqlx
    definitions/assertions/assertion_hu_mli_join_coverage.sqlx
    definitions/assertions/assertion_hu_gold_not_empty.sqlx
```

## 1. Projekt- és dataset-nevek

A tréning project:

```text
ford-training-430008
```

A 02-es workflow datasetjei `02_` prefixszel kezdődnek, hogy BigQuery Explorerben ABC rendezéssel együtt látszódjanak:

```text
02_hu_sell_in_raw
02_hu_sell_in_stage
02_hu_sell_in_intermediate
02_hu_sell_in_gold
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

Tartalom:

```sql
CREATE SCHEMA IF NOT EXISTS `ford-training-430008.02_hu_sell_in_raw`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.02_hu_sell_in_stage`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.02_hu_sell_in_intermediate`
OPTIONS(location = "europe-west4");

CREATE SCHEMA IF NOT EXISTS `ford-training-430008.02_hu_sell_in_gold`
OPTIONS(location = "europe-west4");
```

Futtatás a `02_HU_sell_in_daily` mappából:

```bash
bq query --use_legacy_sql=false < solution/bigquery/01_create_datasets.sql
```

## 3. Raw táblák létrehozása

Fájl:

```text
solution/bigquery/02_create_raw_tables.sql
```

Raw táblák:

```text
02_hu_sell_in_raw.hu_ibis_raw
02_hu_sell_in_raw.mli_classification_alteryx_raw
02_hu_sell_in_raw.hu_sor_parts_price_raw
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

A BigQuery `bq load` közvetlenül CSV-t kezel egyszerűen. Ezért az Excel inputokat először CSV-be exportáljuk.

Fájl:

```text
solution/bigquery/03_export_xlsx_to_csv.py
```

Bemenetek:

```text
input/IBIS adatbázis.xlsx
input/MLI Classification.xlsx
input/SOR adatbázis Parts Price.xlsx
```

Exportált CSV-k:

```text
solution/generated_csv/hu_ibis_raw.csv
solution/generated_csv/mli_classification_alteryx_raw.csv
solution/generated_csv/hu_sor_parts_price_raw.csv
```

Futtatás:

```bash
python3 solution/bigquery/03_export_xlsx_to_csv.py
```

A script explicit sheeteket használ:

```text
IBIS adatbázis.xlsx                  -> bquxjob_40c87724_19ef8c91041
MLI Classification.xlsx              -> Alteryx
SOR adatbázis Parts Price.xlsx       -> bquxjob_545ed8bd_19ef8c7a7dd
```

Az MLI exportnál a problémás Excel fejléceket normalizált raw oszlopnevekre alakítjuk:

```text
Text MLI        -> text_mli
MLI DESCRIPTION -> mli_description
Basket          -> basket
MPL Code        -> mpl_code
PCT\ncode        -> pct_code
CG\nCode         -> cg_code
```

## 5. CSV schema JSON fájlok

Fájlok:

```text
solution/bigquery/schema_hu_ibis_raw.json
solution/bigquery/schema_mli_classification_alteryx_raw.json
solution/bigquery/schema_hu_sor_parts_price_raw.json
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
hu_ibis_raw.csv                       -> 02_hu_sell_in_raw.hu_ibis_raw
mli_classification_alteryx_raw.csv    -> 02_hu_sell_in_raw.mli_classification_alteryx_raw
hu_sor_parts_price_raw.csv            -> 02_hu_sell_in_raw.hu_sor_parts_price_raw
```

Alapértelmezett project és dataset:

```bash
PROJECT_ID="ford-training-430008"
RAW_DATASET="02_hu_sell_in_raw"
```

## 7. Dataform repository létrehozása

Ehhez a workflow-hoz a Dataform forráskód külön publikus GitHub repositoryban van, a workflow folder nevével:

```text
https://github.com/nyika-janos/02_HU_sell_in_daily
```

GCP Console-ban:

1. BigQuery -> Dataform.
2. Create repository.
3. Repository név például:

```text
02-hu-sell-in-daily
```

4. Region:

```text
europe-west4
```

5. A repositoryt össze kell kapcsolni a fenti GitHub repositoryval, hogy a Dataform forráskód a saját GitHub repositoryban maradjon.
6. Default branch: `main`.
7. A Dataform projekt gyökere az a könyvtár legyen, ahol a `workflow_settings.yaml` található. Ha a teljes workflow folder van a GitHub repóban, akkor ez `solution/dataform/`; ha csak a Dataform projekt tartalma lett feltöltve, akkor a repo gyökere.

Ezzel a Dataform workspace nem kézi másolással, hanem GitHub remote-ból kapja a `workflow_settings.yaml`, `definitions/`, `includes/` és `package.json` fájlokat.

## 8. Dataform konfiguráció

Fájl:

```text
solution/dataform/workflow_settings.yaml
```

Tartalom:

```yaml
defaultProject: ford-training-430008
defaultLocation: europe-west4
defaultDataset: 02_hu_sell_in_gold

vars:
  raw_dataset: 02_hu_sell_in_raw
  stage_dataset: 02_hu_sell_in_stage
  intermediate_dataset: 02_hu_sell_in_intermediate
  gold_dataset: 02_hu_sell_in_gold
```

## 9. Dataform stage modellek

### MLI klasszifikáció

Fájl:

```text
solution/dataform/definitions/stage/mli_classification_stage.sqlx
```

Feladata:

- `text_mli` 4 karakterre paddingelése;
- Alteryx mezőnevek előállítása:
  - `MPL`
  - `PCT`
  - `GC`
  - `Basket`.

### IBIS stage

Fájl:

```text
solution/dataform/definitions/stage/hu_ibis_stage.sqlx
```

Feladata:

- `DealerCode`, `FINIS`, `MLI`, `Months` stringként tartása;
- `MLI` padding 4 karakterre;
- pénzügyi és mennyiségi mezők `NUMERIC` típusra castolása;
- `year` és `month` kinyerése `Months` mezőből.

### SOR parts price stage

Fájl:

```text
solution/dataform/definitions/stage/hu_sor_parts_price_stage.sqlx
```

Feladata:

- csak HU aktív rekordok megtartása:
  - `EDWAO25_ISO2_CNTRY_C = 'HU'`
  - `EDWAO25_ACTIVE_F = 'Y'`
- unit szintű `Calculated_BDN` számítása.

## 10. Intermediate modell

Fájl:

```text
solution/dataform/definitions/intermediate/hu_sell_in_enriched.sqlx
```

Logika:

1. SOR parts price aggregálása `FINIS` szerint:

```sql
MAX(Calculated_BDN) AS Calculated_BDN_unit
```

2. IBIS join MLI mappinggel:

```sql
i.MLI = m.MLI
```

3. IBIS join parts price táblával:

```sql
i.FINIS = p.FINIS
```

4. Technikai coverage flag és fallback calculated BDN:

```sql
p.Calculated_BDN_unit IS NOT NULL AS PartsPriceFound
```

5. Fallback calculated BDN:

```sql
COALESCE(p.Calculated_BDN_unit * i.qty * 1000, i.LOC_BDN) AS Calculated_BDN
```

## 11. Gold modell

Fájl:

```text
solution/dataform/definitions/gold/hu_sell_in.sqlx
```

Grain:

```text
market, DealerCode, MLI, Basket, Months, year, month, PCT
```

Metrikák:

```text
LOC_RRP
LOC_BDN
USD_RRP
USD_BDN
billed_revenue
qty
Sum_Calculated_BDN
```

## 12. Assertions

Fájlok:

```text
solution/dataform/definitions/assertions/assertion_hu_ibis_required_fields.sqlx
solution/dataform/definitions/assertions/assertion_hu_mli_join_coverage.sqlx
solution/dataform/definitions/assertions/assertion_hu_gold_not_empty.sqlx
```

Ellenőrzések:

- kötelező IBIS kulcsmezők ne legyenek nullok;
- MLI mapping join coverage;
- gold tábla ne legyen üres.

## 13. Validációs lekérdezések

Fájl:

```text
solution/bigquery/05_validation_queries.sql
```

Futtatás:

```bash
bq query --use_legacy_sql=false < solution/bigquery/05_validation_queries.sql
```

Fő validáció:

```sql
SELECT
  month,
  SUM(LOC_BDN) AS sum_loc_bdn,
  SUM(billed_revenue) AS sum_billed_revenue,
  SUM(qty) AS sum_qty,
  SUM(Sum_Calculated_BDN) AS sum_calculated_bdn
FROM `ford-training-430008.02_hu_sell_in_gold.hu_sell_in`
GROUP BY month
ORDER BY month;
```

## 14. Mit kell Alteryx ellen visszamérni?

Mivel ez a workflow aggregál, a legfontosabb ellenőrzések:

1. Raw IBIS sorszám.
2. MLI mapping találati arány.
3. Parts price FINIS találati arány.
4. Gold havi totalok:
   - `LOC_BDN`
   - `billed_revenue`
   - `qty`
   - `Sum_Calculated_BDN`
5. Mintasorok ellenőrzése `DealerCode`, `MLI`, `Months`, `PCT` kombinációra.

## 15. Production source opció

A mellékelt Excel fájlok exportok. Production migrációban két lehetőség van:

1. Az Excel exportok helyett az eredeti BigQuery lekérdezésekből készülnek raw/source view-k.
2. Egy upstream betöltési folyamat tölti a `02_hu_sell_in_raw.*` táblákat.

A Dataform transzformációs réteg mindkét esetben változatlan maradhat, ha a raw sémák kompatibilisek. A `PartsPriceFound` mező csak intermediate validációs mező, a gold kimenetbe nem kerül be.
