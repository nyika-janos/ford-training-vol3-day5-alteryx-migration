# Technikai megoldás: D/A/CH BPR SO SOC Switch Sample

## Rövid válasz az eredményegyezőségre

Ha ugyanazokat az input extractokat használjuk, mint amelyeket az Alteryx workflow kapott, akkor a Dataform gold táblák ugyanazt a logikai eredményt célozzák, mint az Alteryx D/A/CH BPR sell-out, YTD, top/bottom MLI és scorecard kimenetei.

Az egyezőség feltételei:

- a `BPR_SO_GCP_export_20260610_sample.csv` ugyanazt a GCP sell-out fact exportot tartalmazza;
- a lookup fájlok ugyanazt az állapotot képviselik, mint az Alteryx futáskor;
- `DE`, `AT`, `CH` market kódokat ugyanúgy normalizáljuk `DEU`, `AUT`, `CHE` értékekre;
- `MLI Code` mindenhol 4 karakterre paddingelve van;
- `HDLNR` és dealer kulcsok stringként maradnak;
- `BESFlag = 'BES'` sorok kiszűrésre kerülnek;
- a CrossTab jellegű Alteryx outputokat BigQuery-ben conditional aggregationnel állítjuk elő.

Fontos: a lokális sample alapján az MLI, month és dealer master coverage teljes, de a sellout agreement lookup részleges. Ezért az agreement coverage validációs query, nem blokkoló assertion.

## Elkészített solution mappa

```text
solution/
  README.md
  bigquery/
    01_create_datasets.sql
    02_create_raw_tables.sql
    03_export_inputs_to_csv.py
    04_load_csv.sh
    05_validation_queries.sql
    schema_*.json
  generated_csv/
    bpr_so_gcp_export_raw.csv
    mli_master_raw.csv
    month_mapping_raw.csv
    sellout_agreements_raw.csv
    sellout_channels_raw.csv
    tbl_haendler_all_raw.csv
    tbl_aktive_haendler_raw.csv
    top_bottom_mli_raw.csv
  dataform/
    workflow_settings.yaml
    includes/config.js
    definitions/stage/*.sqlx
    definitions/intermediate/dach_sellout_enriched.sqlx
    definitions/gold/*.sqlx
    definitions/assertions/*.sqlx
```

## 1. Projekt- és dataset-nevek

A tréning project:

```text
ford-training-430008
```

Datasetek:

```text
05_dach_bpr_so_raw
05_dach_bpr_so_stage
05_dach_bpr_so_intermediate
05_dach_bpr_so_gold
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

Futtatás a `05_DACH_BPR_SO_SOC_switch_sample` mappából:

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
05_dach_bpr_so_raw.bpr_so_gcp_export_raw
05_dach_bpr_so_raw.mli_master_raw
05_dach_bpr_so_raw.month_mapping_raw
05_dach_bpr_so_raw.sellout_agreements_raw
05_dach_bpr_so_raw.sellout_channels_raw
05_dach_bpr_so_raw.tbl_haendler_all_raw
05_dach_bpr_so_raw.tbl_aktive_haendler_raw
05_dach_bpr_so_raw.top_bottom_mli_raw
```

A raw táblákban minden mező `STRING`. A széles dealer és MLI Excel fájlokból csak a workflow logikához szükséges oszlopokat exportáljuk, hogy a training séma kezelhető maradjon.

Futtatás:

```bash
bq query --use_legacy_sql=false < solution/bigquery/02_create_raw_tables.sql
```

## 4. Inputok CSV-vé alakítása

Fájl:

```text
solution/bigquery/03_export_inputs_to_csv.py
```

Bemenetek:

```text
input/BPR_SO_GCP_export_20260610_sample.csv
input/MLI_Master_sample.xlsx
input/Month_mapping_sample.xlsx
input/Sellout_agreements_sample.xlsx
input/Sellout_channels_sample.xlsx
input/tbl_Haendler_all_sample.xlsx
input/tbl_aktive_haendler_sample.xlsx
input/Top_Bottom_MLI_db_sample.xlsx
```

Futtatás:

```bash
python3 solution/bigquery/03_export_inputs_to_csv.py
```

A lokálisan generált CSV sorok száma headerrel együtt:

```text
bpr_so_gcp_export_raw.csv       38673
mli_master_raw.csv               1001
month_mapping_raw.csv              13
sellout_agreements_raw.csv       2041
sellout_channels_raw.csv           19
tbl_aktive_haendler_raw.csv      1343
tbl_haendler_all_raw.csv         3408
top_bottom_mli_raw.csv           1179
```

## 5. CSV schema JSON fájlok

A `solution/bigquery/schema_*.json` fájlokat a `bq load` használja explicit sémaként. Így nem kell autodetectre hagyatkozni, és nem sérülnek az azonosítók.

## 6. CSV-k betöltése BigQuery-be

Fájl:

```text
solution/bigquery/04_load_csv.sh
```

Futtatás:

```bash
bash solution/bigquery/04_load_csv.sh
```

Alapértelmezett project, location és dataset:

```bash
PROJECT_ID="ford-training-430008"
LOCATION="europe-west4"
RAW_DATASET="05_dach_bpr_so_raw"
```

## 7. Dataform repository létrehozása

GCP Console-ban:

1. BigQuery -> Dataform.
2. Create repository.
3. Repository név például:

```text
05-dach-bpr-so-soc-switch
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
defaultDataset: 05_dach_bpr_so_gold
vars:
  raw_dataset: 05_dach_bpr_so_raw
  stage_dataset: 05_dach_bpr_so_stage
  intermediate_dataset: 05_dach_bpr_so_intermediate
  gold_dataset: 05_dach_bpr_so_gold
  report_year: 2026
```

A `report_year` váltja ki az Alteryx `DateTimeToday()` alapú `actJ` / `VorJ` logikát a tréningben kontrollálható módon.

## 9. Stage modellek

Stage táblák:

```text
dach_bpr_sellout_stage
mli_master_stage
month_mapping_stage
sellout_agreements_stage
sellout_channels_stage
tbl_haendler_all_stage
tbl_aktive_haendler_stage
top_bottom_mli_stage
```

A legfontosabb fact stage logika:

```sql
CASE UPPER(TRIM(CAST(market_code AS STRING)))
  WHEN "DE" THEN "DEU"
  WHEN "AT" THEN "AUT"
  WHEN "CH" THEN "CHE"
  ELSE UPPER(TRIM(CAST(market_code AS STRING)))
END AS nsc
```

Dealer kulcs:

```sql
CONCAT(
  nsc,
  CASE
    WHEN STARTS_WITH(hdlnr, "00") THEN CONCAT(RIGHT(hdlnr, 3), "00")
    ELSE hdlnr
  END
) AS markt_haendlernummer
```

BES szűrés:

```sql
WHERE COALESCE(bes_flag, "") != "BES"
```

## 10. Intermediate modell

Fájl:

```text
solution/dataform/definitions/intermediate/dach_sellout_enriched.sqlx
```

Joinok:

```sql
LEFT JOIN sellout_agreements_stage
  ON sellout.markt_haendlernummer = agreements.markt_haendlernummer

LEFT JOIN sellout_channels_stage
  ON COALESCE(agreements.soc_sor, sellout.sell_out_channel) = channels.sor_code

LEFT JOIN mli_master_stage
  ON sellout.mli_code = mli.mli_code

LEFT JOIN tbl_haendler_all_stage
  ON sellout.markt_haendlernummer = dealer.markt_haendlernummer

LEFT JOIN month_mapping_stage
  ON sellout.month_mm = month_mapping.month_mm
```

Coverage flag mezők:

```text
AgreementMappingFound
ChannelMappingFound
MliMappingFound
DealerMappingFound
ActiveDealerMappingFound
MonthMappingFound
```

## 11. Gold modellek

Kimenetek:

```text
dach_bpr_sellout_detail
dach_bpr_deu_sell_out
dach_bpr_deu_ytd
dach_top_bottom_mli_sell_out
dach_scorecard_101
dach_scorecard_101_month
dach_scorecard_tpa
dach_scorecard_tpa_month
dach_scorecard_104
dach_scorecard_104_month
```

### Részletes sell-out

`dach_bpr_sellout_detail` megtartja a gazdagított fact grainjét, és BI/debug célra ad teljes transzformált alapot.

### DEU sell-out

`dach_bpr_deu_sell_out` a német kimenetet aggregálja:

```text
nsc, region, thg, pg, dealer, SOC, agreement, MLI, év, hónap
```

Metrikák:

```text
bdn = SUM(base_discount)
qty = SUM(quantity)
```

### DEU YTD

`dach_bpr_deu_ytd` conditional aggregationgel állítja elő az Alteryx CrossTabhoz hasonló current/prior year oszlopokat:

```text
prior_year_bdn
current_year_bdn
prior_year_qty
current_year_qty
r12m_bdn
r12m_qty
```

### Top/bottom MLI

`dach_top_bottom_mli_sell_out` két részből áll:

- `Wert = 'BDN'`
- `Wert = 'QTY'`

Mindkét rész `actJ` és `VorJ` oszlopokat állít elő.

### Scorecardok

Scorecard outputok:

```text
dach_scorecard_101
dach_scorecard_101_month
dach_scorecard_tpa
dach_scorecard_tpa_month
dach_scorecard_104
dach_scorecard_104_month
```

A havi változatok `Month_MM` szerint is bontanak. A nem havi változatok ugyanazt a logikát aggregálják hónap nélkül.

## 12. Assertionök

Dataform assertion fájlok:

```text
assertion_dach_required_fields.sqlx
assertion_dach_mli_join_coverage.sqlx
assertion_dach_month_join_coverage.sqlx
assertion_dach_gold_not_empty.sqlx
```

Ellenőrzések:

- kötelező fact mezők nem üresek;
- minden sell-out sor kap MLI mappinget;
- minden sell-out sor kap month mappinget;
- a gold detail tábla nem üres.

Az agreement/channel coverage szándékosan nem assertion, mert a sample alapján részleges.

## 13. Validációs queryk

Fájl:

```text
solution/bigquery/05_validation_queries.sql
```

Futtatás a Dataform run után:

```bash
bq query --use_legacy_sql=false < solution/bigquery/05_validation_queries.sql
```

Ellenőrzi:

- raw táblák sorszámát;
- stage market/év/hónap aggregált metrikáit;
- lookup coverage flag-eket;
- DEU gold hónap szerinti aggregált metrikáit.

## 14. Lokális sample coverage

A generált CSV-k alapján:

```text
fact_rows_after_bes_filter: 38668
missing_mli:                0
missing_month:              0
missing_agreement:          31699
missing_dealer:             0
```

Ez azt jelenti, hogy az MLI, month és dealer master join teljes a sample-ben, a sellout agreement lookup viszont részleges.

## 15. Alteryx összevetési checklist

1. Raw sorok száma megegyezik az input fájlokkal.
2. `dach_bpr_sellout_stage` sorok száma megegyezik a `BESFlag != 'BES'` szűrés utáni fact sorokkal.
3. MLI és month assertion nem ad vissza sort.
4. `dach_bpr_deu_sell_out` hónap szerinti `bdn` és `qty` összegei megegyeznek az Alteryx DEU outputtal.
5. `dach_top_bottom_mli_sell_out` `actJ` / `VorJ` aggregációi összevethetők a Top_Bottom_MLI_db sample outputtal.
6. Scorecard táblák esetén a BigQuery conditional aggregation helyettesíti az Alteryx CrossTab eszközöket.

## 16. Production forrás opció

A training solution fájl alapú CSV betöltést használ. Production migrációban a raw Excel/CSV export lépés kiváltható közvetlen BigQuery source táblákkal vagy scheduled extracttel.

A Dataform logika ettől nem változik: csak a raw dataset tábláit kell ugyanazzal a sémával feltölteni, majd a stage -> intermediate -> gold modelleket futtatni.
