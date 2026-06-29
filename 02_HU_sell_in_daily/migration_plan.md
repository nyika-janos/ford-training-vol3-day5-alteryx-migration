# Migrációs terv: HU napi sell-in

## Célállapot

```text
raw.hu_ibis
raw.hu_sor_parts_price
raw.mli_classification_alteryx
stage.hu_ibis_stage
stage.hu_sor_parts_price_stage
stage.mli_classification_stage
intermediate.hu_sell_in_enriched
gold.hu_sell_in
```

## Lépések

1. Mindhárom Excel forrás betöltése raw BigQuery táblákba.
2. A vezető nullákat tartalmazó kulcsmezőket stringként kell stage-elni:
   - `FINIS`
   - `MLI`
   - `DealerCode`
   - `Months`
3. `hu_sor_parts_price_stage` létrehozása csak aktív HU rekordokkal.
4. `hu_sell_in_enriched` létrehozása MLI és SOR price joinokkal.
5. A végső aggregált `hu_sell_in` tábla létrehozása.
6. Havi totalok validálása az Alteryx kimenettel vagy forrásszintű aggregációs elvárásokkal.

## Validáló lekérdezések

```sql
SELECT month, SUM(LOC_BDN), SUM(billed_revenue), SUM(qty)
FROM `PROJECT_ID.gold.hu_sell_in`
GROUP BY month
ORDER BY month;
```

## Kockázatok

- `FINIS`, `MLI` és dealer kódok nem castolhatók integerre.
- A számított BDN-ben szereplő `* 1000` szorzót üzleti oldalon vissza kell igazolni a reconciliáció során.
- Az Alteryx aktuális extractokkal dolgozik; production környezetben stabil source view-kat vagy napi raw snapshotokat érdemes használni.
