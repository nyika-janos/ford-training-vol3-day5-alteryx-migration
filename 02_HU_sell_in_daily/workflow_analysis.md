# Workflow elemzés: HU napi sell-in

## A csomag fájljai

```text
Workflow to get sell-in data daily on HU market_tianze.yxmd
input/IBIS adatbázis.xlsx
input/MLI Classification.xlsx
input/SOR adatbázis Parts Price.xlsx
```

## Cél

A workflow napi HU sell-in kimenetet készít úgy, hogy az IBIS értékesítési adatokat MLI klasszifikációval és SOR alkatrészár adatokkal egészíti ki.

## Források

`input/IBIS adatbázis.xlsx`

```text
market, DealerCode, FINIS, MLI, Months, LOC_RRP, LOC_BDN,
USD_RRP, USD_BDN, billed_revenue, qty
```

`input/MLI Classification.xlsx`, `Alteryx` sheet

```text
Text MLI, MLI DESCRIPTION, Basket, MPL Code, PCT code, CG Code
```

`input/SOR adatbázis Parts Price.xlsx`

```text
EDWAO25_FINIS_C, EDWAO25_ISO2_CNTRY_C, EDWAO25_VALID_FROM_Y,
EDWAO25_VALID_UNTIL_Y, EDWAO25_FINIS_X, EDWAO25_MLI_C,
EDWAO25_BASIC_DISCOUNT_P, EDWAO25_RTL_OR_NET_PRICE_A,
EDWAO25_ACTIVE_F
```

## Alteryx eszközminta

```text
DbFileInput: 3
Join: 2
Formula: 5
Summarize: 2
Union: 1
DbFileOutput: 1
```

## Feldolgozási logika

- MLI klasszifikáció normalizálása:
  - `MLI = PadLeft([MLI], 4, '0')`
  - `MPL Code` átnevezése `MPL` névre, `PCT code` átnevezése `PCT` névre, `CG Code` átnevezése `GC` névre.
- IBIS adatok joinolása az MLI klasszifikációval `MLI` alapján.
- SOR egység BDN számítása:
  - `RTL_OR_NET_PRICE - RTL_OR_NET_PRICE * BASIC_DISCOUNT_P`
- SOR ár aggregálása `FINIS` szerint, a maximális számított BDN megtartásával.
- IBIS adatok joinolása SOR parts price adatokkal `FINIS` alapján.
- Sorszintű fallback BDN számítása:
  - `(calculated_bdn_unit * qty) * 1000`
  - ha null, akkor `LOC_BDN`.
- Származtatott mezők:
  - `year = left(Months, 4)`
  - `month = right(Months, 2)`
- Aggregálás market, dealer, MLI, basket, hónap és PCT szerint.

## Kimenet

Eredeti kimenet:

```text
HU_Sell_in.xlsx / Sheet1
```

Javasolt GCP kimenet:

```text
gold.hu_sell_in
```
