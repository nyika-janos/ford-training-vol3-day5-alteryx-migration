# Migrációs terv: UK_SOR_KAS_Dealers_v14_GCP

## Célállapot

A workflow két BigQuery/Dataform kimenetre migrálható:

```text
raw.uk_sor_kas_dealers
stage.uk_sor_kas_dealers_stage
gold.uk_sor_kas_dealers
gold.uk_sor_kas_dealers_cv
```

## Lépések

1. Az `input/Input_UK_SOR_KAS_Dealers_v14_GCP.csv` betöltése a `raw.uk_sor_kas_dealers` táblába.
2. Stage modell készítése, amely trimeli a fontos string mezőket és parse-olja az `INV_DATE` mezőt.
3. A teljes kimenet létrehozása `gold.uk_sor_kas_dealers` néven.
4. A `PV_CV = 'CV'` kompatibilitási view létrehozása `gold.uk_sor_kas_dealers_cv` néven.
5. Sorszámok validálása:
   - a raw sorszám egyezzen a teljes gold kimenettel az elvárt deduplikáció után;
   - a `PV_CV = 'CV'` sorszám egyezzen a CV kimenettel.

## Adatminőségi ellenőrzések

- `MARKET` nem lehet null.
- `DEALER` nem lehet null.
- `VIN` nem lehet null ott, ahol a downstream riport ezt elvárja.
- `PV_CV` csak ismert értékeket tartalmazzon, például `PV` és `CV`.

## Átállás

Miután a CSV-alapú futás validálva lett, a `raw.uk_sor_kas_dealers` helyett Dataform source deklarációval érdemes a production SOR BigQuery view-ra vagy lekérdezéskimenetre mutatni.
