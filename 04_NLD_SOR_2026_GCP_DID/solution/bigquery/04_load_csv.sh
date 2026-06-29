#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-ford-training-430008}"
LOCATION="${LOCATION:-europe-west4}"
RAW_DATASET="${RAW_DATASET:-04_nld_sor_raw}"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CSV_DIR="${BASE_DIR}/solution/generated_csv"
SCHEMA_DIR="${BASE_DIR}/solution/bigquery"

bq --project_id="${PROJECT_ID}" --location="${LOCATION}" load \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter=',' \
  --quote='"' \
  "${RAW_DATASET}.nld_sor_raw" \
  "${CSV_DIR}/nld_sor_raw.csv" \
  "${SCHEMA_DIR}/schema_nld_sor_raw.json"

bq --project_id="${PROJECT_ID}" --location="${LOCATION}" load \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter=',' \
  --quote='"' \
  "${RAW_DATASET}.nld_did_raw" \
  "${CSV_DIR}/nld_did_raw.csv" \
  "${SCHEMA_DIR}/schema_nld_did_raw.json"

bq --project_id="${PROJECT_ID}" --location="${LOCATION}" load \
  --replace \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --field_delimiter=',' \
  --quote='"' \
  "${RAW_DATASET}.mli_classification_alteryx_raw" \
  "${CSV_DIR}/mli_classification_alteryx_raw.csv" \
  "${SCHEMA_DIR}/schema_mli_classification_alteryx_raw.json"
