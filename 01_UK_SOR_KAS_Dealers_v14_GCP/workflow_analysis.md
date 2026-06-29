# Workflow elemzés: UK_SOR_KAS_Dealers_v14_GCP

## A csomag fájljai

```text
UK_SOR_KAS_Dealers_v14_GCP.yxmd
input/Input_UK_SOR_KAS_Dealers_v14_GCP.csv
```

## Cél

A workflow egy BigQuery SOR számla/ügyfél/kereskedő kivonatot olvas be, és UK/IE customer-after-service dealer riportkimeneteket készít. A mellékelt CSV az eredeti BigQuery input lekérdezés exportja, és már tartalmazza a lekérdezésben aliasolt mezőket.

## Forrás

`input/Input_UK_SOR_KAS_Dealers_v14_GCP.csv`

Fontosabb oszlopok:

```text
MARKET, DEALER, DEPARTMENT, PAYMENT_TYPE, INV_DATE, INVOICE_TYPE,
INV_TOTAL_LOCAL, VIN, REG_PLATE, VEH_TYPE, FUEL_TYPE, VEH_DESCRIPTION,
ACCOUNT_CODE, CUSTOMER_NAME_AGREGATED, CUSTOMER_ADD_AGREGATED,
LAST_NAME, FIRST_NAME, TITLE_, COMPANY_NAME_1, COMPANY_NAME_2,
STREET, REGION, CITY, COUNTY, POSTCODE, ADDR_1..ADDR_6,
HOME_TEL, WORK_TEL, PRO_TITLE, MOBILE_1, MOBILE_2,
EMAIL_1, EMAIL_2, SALUTATION, PV_CV, CUSTOMER_TYPE
```

## Alteryx eszközminta

```text
DbFileInput: 1
TextToColumns: 1
Select: 1
Filter: 1
DbFileOutput: 2
```

## Feldolgozási logika

- Széles SOR BigQuery kivonat beolvasása.
- A riporthoz szükséges mezők megtartása/átnevezése.
- Könnyű transzformáció TextToColumns és Select eszközökkel.
- A kimenet szétválasztása normál dealer és commercial vehicle ágra.
- A látható kimeneti bontás a `PV_CV` mező alapján történik, ahol a `CV` a commercial vehicle ág.

## Kimenetek

Eredeti Alteryx kimenetek:

```text
FORDUK_SOR_DEALERS_v1.xlsx / Sheet1
FORDUK_SOR_DEALERS_CV_v1.xlsx / Sheet1
```

Javasolt GCP kimenetek:

```text
gold.uk_sor_kas_dealers
gold.uk_sor_kas_dealers_cv
```

## Migrációs megjegyzések

- Visszateszteléshez a mellékelt CSV-t kell BigQuery raw táblába tölteni.
- Éles működésben a raw táblát az eredeti SOR BigQuery selecttel vagy source view-val érdemes kiváltani.
- Az olyan azonosítókat, mint `DEALER`, `ACCOUNT_CODE`, `VIN`, telefonszámok és irányítószámok, stringként kell kezelni.
