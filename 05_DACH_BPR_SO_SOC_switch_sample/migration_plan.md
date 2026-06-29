# Migrációs terv: D/A/CH BPR SO SOC Switch Sample

## Célállapot

```text
raw.dach_bpr_so_gcp_export
raw.dach_mli_master
raw.dach_month_mapping
raw.dach_sellout_agreements
raw.dach_sellout_channels
raw.dach_tbl_aktive_haendler
raw.dach_tbl_haendler_all
raw.dach_top_bottom_mli_reference
stage.dach_bpr_sellout_stage
intermediate.dach_sellout_enriched
gold.dach_bpr_deu_sell_out
gold.dach_bpr_deu_ytd
gold.dach_top_bottom_mli_sell_out
gold.dach_scorecard_*
```

## Lépések

1. A workflow mappában lévő összes input fájl betöltése raw BigQuery táblákba.
2. `dach_bpr_sellout_stage` létrehozása:
   - market code normalizálása;
   - `Markt_Haendlernummer` képzése;
   - quantity és base discount castolása;
   - `BES` rekordok eltávolítása.
3. Lookup táblák stage-elése vagy CTE-ként használata az enrichment modellben.
4. `dach_sellout_enriched` létrehozása agreement, channel, MLI, dealer és month joinokkal.
5. Normalizált gold fact kimenetek létrehozása.
6. Scorecard kompatibilitási táblák létrehozása conditional aggregationnel.
7. Totalok reconciliációja market, year, month és channel szerint.

## Validáció

```sql
SELECT nsc, year_yyyy, month_mm, SUM(base_discount), SUM(quantity)
FROM `PROJECT_ID.intermediate.dach_sellout_enriched`
GROUP BY nsc, year_yyyy, month_mm
ORDER BY nsc, year_yyyy, month_mm;
```

```sql
SELECT soc_num_txt, SUM(base_discount), SUM(quantity)
FROM `PROJECT_ID.intermediate.dach_sellout_enriched`
GROUP BY soc_num_txt
ORDER BY soc_num_txt;
```

## Kockázatok

- A workflow sok CrossTab kimenetet tartalmaz. Először normalizált táblákat érdemes építeni, és csak utána a szükséges széles Excel-kompatibilis view-kat.
- Az Alteryx `DateTimeToday()` logikáját konfigurálható Dataform `report_date` változóval kell kiváltani.
- A scorecard filtereket, például `101-channel text`, TPA és `104`, a `Sellout_channels_sample.xlsx` alapján üzletileg vissza kell igazolni.
