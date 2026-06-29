#!/usr/bin/env python3
import csv
from pathlib import Path
import openpyxl

BASE_DIR = Path(__file__).resolve().parents[2]
INPUT_DIR = BASE_DIR / "input"
OUTPUT_DIR = BASE_DIR / "solution" / "generated_csv"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

EXPORTS = [
    {
        "source": "IBIS adatbázis.xlsx",
        "sheet": "bquxjob_40c87724_19ef8c91041",
        "target": "hu_ibis_raw.csv",
        "headers": [
            "market", "DealerCode", "FINIS", "MLI", "Months", "LOC_RRP",
            "LOC_BDN", "USD_RRP", "USD_BDN", "billed_revenue", "qty"
        ],
        "header_row": 1,
    },
    {
        "source": "MLI Classification.xlsx",
        "sheet": "Alteryx",
        "target": "mli_classification_alteryx_raw.csv",
        "headers": [
            "text_mli", "mli_description", "basket", "mpl_code", "pct_code", "cg_code"
        ],
        "header_row": 1,
    },
    {
        "source": "SOR adatbázis Parts Price.xlsx",
        "sheet": "bquxjob_545ed8bd_19ef8c7a7dd",
        "target": "hu_sor_parts_price_raw.csv",
        "headers": [
            "EDWAO25_FINIS_C", "EDWAO25_ISO2_CNTRY_C", "EDWAO25_VALID_FROM_Y",
            "EDWAO25_VALID_UNTIL_Y", "EDWAO25_FINIS_X", "EDWAO25_MLI_C",
            "EDWAO25_BASIC_DISCOUNT_P", "EDWAO25_RTL_OR_NET_PRICE_A", "EDWAO25_ACTIVE_F"
        ],
        "header_row": 1,
    },
]

def clean_value(value):
    if value is None:
        return ""
    return str(value)

for spec in EXPORTS:
    workbook_path = INPUT_DIR / spec["source"]
    workbook = openpyxl.load_workbook(workbook_path, read_only=True, data_only=True)
    worksheet = workbook[spec["sheet"]]
    output_path = OUTPUT_DIR / spec["target"]

    with output_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.writer(output_file)
        writer.writerow(spec["headers"])
        for row_index, row in enumerate(worksheet.iter_rows(values_only=True), start=1):
            if row_index <= spec["header_row"]:
                continue
            values = [clean_value(value) for value in row[:len(spec["headers"])]]
            if any(value != "" for value in values):
                writer.writerow(values)

    print(f"Wrote {output_path}")
