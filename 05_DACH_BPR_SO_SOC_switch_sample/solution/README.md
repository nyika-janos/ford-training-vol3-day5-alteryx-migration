# D/A/CH BPR SO SOC Switch megoldás

Ez a mappa a `3_BPR_SO_Workflow_D_A_CH_2025_SOC_switch_sample.yxmd` workflow BigQuery + Dataform migrációs megoldását tartalmazza.

## Futtatási sorrend

Az alábbi parancsokat a `05_DACH_BPR_SO_SOC_switch_sample` mappából futtasd.

1. BigQuery datasetek létrehozása:

```bash
bq query --use_legacy_sql=false < solution/bigquery/01_create_datasets.sql
```

2. Raw táblák létrehozása:

```bash
bq query --use_legacy_sql=false < solution/bigquery/02_create_raw_tables.sql
```

3. Inputok exportálása CSV-be:

```bash
python3 solution/bigquery/03_export_inputs_to_csv.py
```

4. CSV-k betöltése BigQuery-be:

```bash
bash solution/bigquery/04_load_csv.sh
```

5. Dataform repository létrehozása GCP-ben, majd a `solution/dataform/` mappa tartalmának bemásolása a repositoryba.

6. Dataform futtatása:

```text
stage -> intermediate -> gold -> assertions
```

## Mit állít elő?

```text
05_dach_bpr_so_gold.dach_bpr_sellout_detail
05_dach_bpr_so_gold.dach_bpr_deu_sell_out
05_dach_bpr_so_gold.dach_bpr_deu_ytd
05_dach_bpr_so_gold.dach_top_bottom_mli_sell_out
05_dach_bpr_so_gold.dach_scorecard_101
05_dach_bpr_so_gold.dach_scorecard_101_month
05_dach_bpr_so_gold.dach_scorecard_tpa
05_dach_bpr_so_gold.dach_scorecard_tpa_month
05_dach_bpr_so_gold.dach_scorecard_104
05_dach_bpr_so_gold.dach_scorecard_104_month
```
