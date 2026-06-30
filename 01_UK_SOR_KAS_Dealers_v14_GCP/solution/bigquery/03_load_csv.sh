#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="ford-training-430008"
RAW_DATASET="01_uk_sor_raw"
TABLE_NAME="uk_sor_kas_dealers_raw"
CSV_PATH="input/Input_UK_SOR_KAS_Dealers_v14_GCP.csv"
SCHEMA_PATH="solution/bigquery/schema_uk_sor_kas_dealers_raw.json"

bq load \
  --project_id="${PROJECT_ID}" \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter="," \
  --quote='"' \
  --allow_quoted_newlines=true \
  --encoding=UTF-8 \
  "${RAW_DATASET}.${TABLE_NAME}" \
  "${CSV_PATH}" \
  "${SCHEMA_PATH}"
