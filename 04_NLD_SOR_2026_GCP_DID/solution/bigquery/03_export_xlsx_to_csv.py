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
        "source": "SOR_NLD_input.xlsx",
        "sheet": "Sheet1",
        "target": "nld_sor_raw.csv",
        "headers": [
            "Market", "DealerCode", "MLI", "Months", "channel", "payment",
            "BusinessY", "BusinessM", "BusinessQ", "MKTG", "UCC", "channel_1",
            "LOC_Invoiced", "LOC_BDN", "LOC_RRP", "USD_Invoiced", "USD_BDN",
            "USD_RRP", "qty"
        ],
        "header_row": 1,
    },
    {
        "source": "DID_NLD_input.xlsx",
        "sheet": "Sheet1",
        "target": "nld_did_raw.csv",
        "headers": ["i22_parts_alias", "i22_iso_mktcd", "i22_dealer_cd", "i22_dlrname"],
        "header_row": 1,
    },
    {
        "source": "MLI Classification.xlsx",
        "sheet": "Alteryx",
        "target": "mli_classification_alteryx_raw.csv",
        "headers": ["text_mli", "mli_description", "basket", "mpl_code", "pct_code", "cg_code"],
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
            values = [clean_value(value) for value in row[:len(spec["headers"])] ]
            if any(value != "" for value in values):
                writer.writerow(values)

    print(f"Wrote {output_path}")
