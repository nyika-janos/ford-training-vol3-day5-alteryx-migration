#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-ford-training-430008}"
LOCATION="${LOCATION:-europe-west4}"
RAW_DATASET="${RAW_DATASET:-05_dach_bpr_so_raw}"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CSV_DIR="${BASE_DIR}/solution/generated_csv"
SCHEMA_DIR="${BASE_DIR}/solution/bigquery"

load_table() {
  local table_name="$1"
  bq --project_id="${PROJECT_ID}" --location="${LOCATION}" load     --replace     --source_format=CSV     --skip_leading_rows=1     --field_delimiter=','     --quote='"'     "${RAW_DATASET}.${table_name}"     "${CSV_DIR}/${table_name}.csv"     "${SCHEMA_DIR}/schema_${table_name}.json"
}

load_table bpr_so_gcp_export_raw
load_table mli_master_raw
load_table month_mapping_raw
load_table sellout_agreements_raw
load_table sellout_channels_raw
load_table tbl_haendler_all_raw
load_table tbl_aktive_haendler_raw
load_table top_bottom_mli_raw
