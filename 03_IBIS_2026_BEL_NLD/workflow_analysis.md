# Workflow elemzés: IBIS_2026_BEL_NLD

## A csomag fájljai

```text
IBIS_2026_BEL_NLD.yxmd
input/MLI Classification.xlsx
input/NLD_IBIS_input.xlsx
input/BEL_IBIS_input.xlsx
input/NLD_parts_input.xlsx
```

## Cél

A workflow BEL és NLD 2026-os IBIS sales kimeneteket készít. Az IBIS sales adatokat MLI klasszifikációval gazdagítja, aggregálja a sales metrikákat, majd FINIS/part-description szintű kimeneteket is létrehoz.

## Források

`input/NLD_IBIS_input.xlsx` és `input/BEL_IBIS_input.xlsx`

```text
market, MKT_CUSTOMER_ID_C, SSA_TRADE_N, billing_country, FINIS,
MLI, MDSMT_MNTHYR_Y, LOC_BDN, gross_revenue, billed_revenue,
gross_pieces
```

`input/NLD_parts_input.xlsx`

```text
part_description, FINIS
```

`input/MLI Classification.xlsx`, `Alteryx` sheet

```text
Text MLI, MLI DESCRIPTION, Basket, MPL Code, PCT code, CG Code
```

## Alteryx eszközminta

```text
DbFileInput: 5
Join: 4
Filter: 4
Summarize: 4
DbFileOutput: 4
```

## Feldolgozási logika

- NLD és BEL IBIS extractok beolvasása.
- Sales adatok joinolása MLI klasszifikációval `MLI` alapján.
- Sales adatok aggregálása customer, trade name, market, month, MLI és basket szerint.
- Összegzett metrikák:
  - `billed_revenue`
  - `gross_revenue`
  - `LOC_BDN`
  - `gross_pieces`
- FINIS joinolása part description adatokkal.
- Market szintű sales kimenetek és FINIS szintű kimenetek létrehozása.

## Kimenetek

Eredeti kimenetek:

```text
NLD IBIS SalesData_2026.xlsx / SalesData
NLD IBIS SalesData_2026.xlsx / SalesData FINIS
BEL IBIS SalesData_2026.xlsx / SalesData
BEL IBIS SalesData_Finis_2026.xlsx / SalesData
```

Javasolt GCP kimenetek:

```text
gold.ibis_nld_salesdata
gold.ibis_nld_salesdata_finis
gold.ibis_bel_salesdata
gold.ibis_bel_salesdata_finis
```
