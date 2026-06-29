# Workflow elemzés: D/A/CH BPR SO SOC Switch Sample

## A csomag fájljai

```text
3_BPR_SO_Workflow_D_A_CH_2025_SOC_switch_sample.yxmd
input/Top_Bottom_MLI_db_sample.xlsx
input/BPR_SO_GCP_export_20260610_sample.csv
input/tbl_aktive_haendler_sample.xlsx
input/Month_mapping_sample.xlsx
input/Sellout_agreements_sample.xlsx
input/Sellout_channels_sample.xlsx
input/MLI_Master_sample.xlsx
input/tbl_Haendler_all_sample.xlsx
```

## Cél

Ez a legnagyobb workflow. D/A/CH BPR sell-out kimeneteket és scorecard jellegű aggregátumokat készít GCP sell-out adatokból, amelyeket dealer, channel, agreement, month és MLI master adatokkal gazdagít.

## Fő forrás

`input/BPR_SO_GCP_export_20260610_sample.csv`

```text
Market Code, HDLNR, Sell Out Channel, BESFlag, MLI Code,
Year_YYYY, Month_MM, Quantity, Base Discount
```

## Lookup források

```text
input/MLI_Master_sample.xlsx
input/Month_mapping_sample.xlsx
input/Sellout_agreements_sample.xlsx
input/Sellout_channels_sample.xlsx
input/tbl_aktive_haendler_sample.xlsx
input/tbl_Haendler_all_sample.xlsx
input/Top_Bottom_MLI_db_sample.xlsx
```

## Alteryx eszközminta

```text
DbFileInput: 8
Formula: 38
Filter: 25
Join: 23
Summarize: 21
Union: 18
CrossTab: 15
DbFileOutput: 10
```

## Feldolgozási logika

- Market normalizálása:
  - `DE -> DEU`
  - `AT -> AUT`
  - `CH -> CHE`
- `Markt_Haendlernummer` képzése market és `HDLNR` alapján.
- `BESFlag = 'BES'` rekordok kiszűrése.
- Sell-out tényadat joinolása:
  - sellout agreements táblára `Markt_Haendlernummer` alapján;
  - sellout channel mappingre SOR/channel code alapján;
  - MLI masterre `MLI Code = MLI_0000` alapján;
  - month mappingre month alapján;
  - dealer masterre dealer kulcs alapján.
- Származtatott címkék:
  - `Sell Out Vereinbarung = inkludiert / nicht inkludiert`
  - `Year_txt = actJ / VorJ`
  - `Wert = BDN / QTY`
- YTD, havi, scorecard és top/bottom MLI aggregátumok készítése.
- A CrossTab eszközök széles, Excel-kompatibilis kimeneteket hoznak létre. BigQuery-ben ezeket conditional aggregationnel vagy normalizált reporting táblákkal és BI oldali pivotokkal érdemes megvalósítani.

## Eredeti kimenetek

```text
BPR_SO_Data_DEU_sample.xlsx / DEU_BPR_SO_YTD
BPR_SO_Data_DEU_out_sample.xlsx / tbl_BPR_DEU_Sell_Out
BPR_SO_Data_DEU.accdb / DEU_BPR_SO_YTD
Top_Bottom_MLI_db_sample.xlsx / Sell-Out
Scorecard_DB_out_Sample.xlsx / tbl_SO_101_SC
Scorecard_DB_out_Sample.xlsx / tbl_SO_101_SC_Month_MM
Scorecard_DB_out_Sample.xlsx / tbl_SO_TPA_SC
Scorecard_DB_out_Sample.xls / tbl_SO_TPA_SC_Month_MM
Scorecard_DB_out_Sample.xlsb / tbl_SO_104_SC
Scorecard_DB_out_Sample.xlsb / tbl_SO_104_SC_Month_MM
```

## Javasolt GCP kimenetek

```text
gold.dach_bpr_deu_sell_out
gold.dach_bpr_deu_ytd
gold.dach_top_bottom_mli_sell_out
gold.dach_scorecard_101
gold.dach_scorecard_101_month
gold.dach_scorecard_tpa
gold.dach_scorecard_tpa_month
gold.dach_scorecard_104
gold.dach_scorecard_104_month
```
