#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-ford-training-430008}"
LOCATION="${LOCATION:-europe-west4}"
RAW_DATASET="${RAW_DATASET:-03_ibis_bel_nld_raw}"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CSV_DIR="${BASE_DIR}/solution/generated_csv"
SCHEMA_DIR="${BASE_DIR}/solution/bigquery"

bq --project_id="${PROJECT_ID}" --location="${LOCATION}" load \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter=',' \
  --quote='"' \
  "${RAW_DATASET}.ibis_nld_raw" \
  "${CSV_DIR}/ibis_nld_raw.csv" \
  "${SCHEMA_DIR}/schema_ibis_sales_raw.json"

bq --project_id="${PROJECT_ID}" --location="${LOCATION}" load \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter=',' \
  --quote='"' \
  "${RAW_DATASET}.ibis_bel_raw" \
  "${CSV_DIR}/ibis_bel_raw.csv" \
  "${SCHEMA_DIR}/schema_ibis_sales_raw.json"

bq --project_id="${PROJECT_ID}" --location="${LOCATION}" load \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter=',' \
  --quote='"' \
  "${RAW_DATASET}.mli_classification_alteryx_raw" \
  "${CSV_DIR}/mli_classification_alteryx_raw.csv" \
  "${SCHEMA_DIR}/schema_mli_classification_alteryx_raw.json"

bq --project_id="${PROJECT_ID}" --location="${LOCATION}" load \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter=',' \
  --quote='"' \
  "${RAW_DATASET}.nld_parts_raw" \
  "${CSV_DIR}/nld_parts_raw.csv" \
  "${SCHEMA_DIR}/schema_nld_parts_raw.json"
