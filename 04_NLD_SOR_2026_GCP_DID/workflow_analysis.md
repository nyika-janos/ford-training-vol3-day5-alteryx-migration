# Workflow elemzés: NLD_SOR_2026_GCP_DID

## A csomag fájljai

```text
NLD_SOR_2026_GCP_DID.yxmd
input/MLI Classification.xlsx
input/DID_NLD_input.xlsx
input/SOR_NLD_input.xlsx
```

## Cél

A workflow az NLD SOR sell-out adatokat DID dealer nevekkel és MLI klasszifikációval gazdagítja, majd NLD sales data kimenetet ír.

## Források

`input/SOR_NLD_input.xlsx`

```text
Market, DealerCode, MLI, Months, channel, payment, BusinessY,
BusinessM, BusinessQ, MKTG, UCC, channel_1, LOC_Invoiced,
LOC_BDN, LOC_RRP, USD_Invoiced, USD_BDN, USD_RRP, qty
```

`input/DID_NLD_input.xlsx`

```text
i22_parts_alias, i22_iso_mktcd, i22_dealer_cd, i22_dlrname
```

`input/MLI Classification.xlsx`, `Alteryx` sheet

```text
Text MLI, MLI DESCRIPTION, Basket, MPL Code, PCT code, CG Code
```

## Alteryx eszközminta

```text
DbFileInput: 3
Join: 2
Summarize: 2
Unique: 1
DbFileOutput: 1
```

## Feldolgozási logika

- DID dealer lista aggregálása egyedi market/dealer/dealer name szintre.
- SOR joinolása DID-re `Market`, `DealerCode` alapján.
- SOR joinolása MLI klasszifikációra `MLI` alapján.
- A SOR metrikák megtartása dealer és MLI attribútumokkal kiegészítve.

## Kimenet

Eredeti kimenet:

```text
NLD_SOR_SalesData_2026.xlsx / SalesData
```

Javasolt GCP kimenet:

```text
gold.nld_sor_salesdata
```
