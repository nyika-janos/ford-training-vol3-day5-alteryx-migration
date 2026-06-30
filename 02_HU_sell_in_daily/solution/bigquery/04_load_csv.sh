#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="ford-training-430008"
RAW_DATASET="02_hu_sell_in_raw"
CSV_DIR="solution/generated_csv"
SCHEMA_DIR="solution/bigquery"

bq load \
  --project_id="${PROJECT_ID}" \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter="," \
  --quote='"' \
  --allow_quoted_newlines=true \
  --encoding=UTF-8 \
  "${RAW_DATASET}.hu_ibis_raw" \
  "${CSV_DIR}/hu_ibis_raw.csv" \
  "${SCHEMA_DIR}/schema_hu_ibis_raw.json"

bq load \
  --project_id="${PROJECT_ID}" \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter="," \
  --quote='"' \
  --allow_quoted_newlines=true \
  --encoding=UTF-8 \
  "${RAW_DATASET}.mli_classification_alteryx_raw" \
  "${CSV_DIR}/mli_classification_alteryx_raw.csv" \
  "${SCHEMA_DIR}/schema_mli_classification_alteryx_raw.json"

bq load \
  --project_id="${PROJECT_ID}" \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter="," \
  --quote='"' \
  --allow_quoted_newlines=true \
  --encoding=UTF-8 \
  "${RAW_DATASET}.hu_sor_parts_price_raw" \
  "${CSV_DIR}/hu_sor_parts_price_raw.csv" \
  "${SCHEMA_DIR}/schema_hu_sor_parts_price_raw.json"
