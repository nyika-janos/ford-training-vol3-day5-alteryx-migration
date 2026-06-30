#!/usr/bin/env python3
import csv
from pathlib import Path
import openpyxl

BASE_DIR = Path(__file__).resolve().parents[2]
INPUT_DIR = BASE_DIR / "input"
OUTPUT_DIR = BASE_DIR / "solution" / "generated_csv"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

CSV_EXPORTS = [
    {
        "source": "BPR_SO_GCP_export_20260610_sample.csv",
        "target": "bpr_so_gcp_export_raw.csv",
        "source_headers": ["Market Code", "HDLNR", "Sell Out Channel", "BESFlag", "MLI Code", "Year_YYYY", "Month_MM", "Quantity", "Base Discount"],
        "target_headers": ["market_code", "hdlnr", "sell_out_channel", "bes_flag", "mli_code", "year_yyyy", "month_mm", "quantity", "base_discount"],
    }
]

XLSX_EXPORTS = [
    {
        "source": "MLI_Master_sample.xlsx",
        "sheet": "Sheet1",
        "target": "mli_master_raw.csv",
        "columns": {
            "ID": "id", "Aktiv": "aktiv", "CY": "cy", "MLI_OIL": "mli_oil", "MLI_0000": "mli_0000",
            "MLI": "mli", "Bezeichnung": "bezeichnung", "BU": "bu", "BUSINESS_UNIT": "business_unit",
            "Program_MLI_Groups": "program_mli_groups", "MLI_NUM": "mli_num", "Finanz Trans etc": "finanz_trans_etc",
            "Garantie": "garantie", "MLI_txt": "mli_txt", "CB_MLI": "cb_mli"
        },
    },
    {
        "source": "Month_mapping_sample.xlsx",
        "sheet": "Sheet1",
        "target": "month_mapping_raw.csv",
        "columns": {
            "Month_no": "month_no", "Month_txt": "month_txt", "Month_MM": "month_mm", "Month_eng_short": "month_eng_short",
            "Month_eng_long": "month_eng_long", "Month_ger_short": "month_ger_short", "Month_ger_long": "month_ger_long", "Quartal": "quartal"
        },
    },
    {
        "source": "Sellout_agreements_sample.xlsx",
        "sheet": "Sheet1",
        "target": "sellout_agreements_raw.csv",
        "columns": {
            "NSC_ISO": "nsc_iso", "Markt_Haendlernummer": "markt_haendlernummer", "Haendlernummer": "haendlernummer",
            "SOC_qlf": "soc_qlf", "SOC_SOR": "soc_sor", "SOC_num": "soc_num", "SOC_num_txt": "soc_num_txt",
            "eigene_Werkstatt_mit_Strecke": "eigene_werkstatt_mit_strecke"
        },
    },
    {
        "source": "Sellout_channels_sample.xlsx",
        "sheet": "Sheet1",
        "target": "sellout_channels_raw.csv",
        "columns": {
            "SellOut Channel": "sellout_channel", "SOR_Code": "sor_code", "Channel Name": "channel_name",
            "Kategorie_old": "kategorie_old", "Kategorie_new": "kategorie_new", "Cluster": "cluster",
            "SOC_num_txt": "soc_num_txt", "Cluster_FCSD": "cluster_fcsd"
        },
    },
    {
        "source": "tbl_Haendler_all_sample.xlsx",
        "sheet": "Sheet1",
        "target": "tbl_haendler_all_raw.csv",
        "columns": {
            "Markt": "markt", "Haendlernummer": "haendlernummer", "Markt_Haendlernummer": "markt_haendlernummer",
            "Poolinggruppe_SellOut": "poolinggruppe_sellout", "Region_Teile": "region_teile", "THG": "thg",
            "Haendlername": "haendlername", "TN_Teilebonus_Status": "tn_teilebonus_status",
            "TN_Teilebonus_101_Freie_Werkstatt": "tn_teilebonus_101_freie_werkstatt",
            "TN_Teilebonus_104_Service_u_Karosserie_Kettengebunden": "tn_teilebonus_104_service_u_karosserie_kettengebunden",
            "Reporting_inkludiert_Teile": "reporting_inkludiert_teile"
        },
    },
    {
        "source": "tbl_aktive_haendler_sample.xlsx",
        "sheet": "Sheet1",
        "target": "tbl_aktive_haendler_raw.csv",
        "columns": {
            "Markt": "markt", "Markt_Haendlernummer": "markt_haendlernummer", "Haendlernummer": "haendlernummer",
            "Haendlerstatus": "haendlerstatus", "Region_Teile": "region_teile", "THG": "thg",
            "TN_Teilebonus_Status": "tn_teilebonus_status", "Reporting_inkludiert_Teile": "reporting_inkludiert_teile"
        },
    },
    {
        "source": "Top_Bottom_MLI_db_sample.xlsx",
        "sheet": "Sell-Out",
        "target": "top_bottom_mli_raw.csv",
        "columns": {
            "Region": "region", "THG_Betreuer_Name": "thg_betreuer_name", "PG": "pg", "MLI_txt": "mli_txt",
            "FB_AFSB": "fb_afsb", "Markt_Haendlernummer": "markt_haendlernummer", "TN_Teilebonus_Status": "tn_teilebonus_status",
            "MLI_NUM": "mli_num", "MLI_OIL": "mli_oil", "BUSINESS_UNIT": "business_unit",
            "Program_MLI_Groups": "program_mli_groups", "Finanz Trans etc": "finanz_trans_etc",
            "actJ": "actj", "VorJ": "vorj", "Wert": "wert"
        },
    },
]

def clean(value):
    if value is None:
        return ""
    return str(value)

for spec in CSV_EXPORTS:
    input_path = INPUT_DIR / spec["source"]
    output_path = OUTPUT_DIR / spec["target"]
    with input_path.open(newline="", encoding="utf-8-sig") as input_file, output_path.open("w", newline="", encoding="utf-8") as output_file:
        reader = csv.DictReader(input_file)
        writer = csv.writer(output_file)
        writer.writerow(spec["target_headers"])
        for row in reader:
            writer.writerow([clean(row.get(source_header)) for source_header in spec["source_headers"]])
    print(f"Wrote {output_path}")

for spec in XLSX_EXPORTS:
    workbook = openpyxl.load_workbook(INPUT_DIR / spec["source"], read_only=True, data_only=True)
    worksheet = workbook[spec["sheet"]]
    rows = worksheet.iter_rows(values_only=True)
    source_headers = [clean(value) for value in next(rows)]
    index_by_header = {header: index for index, header in enumerate(source_headers)}
    missing = [header for header in spec["columns"] if header not in index_by_header]
    if missing:
        raise ValueError(f"Missing headers in {spec['source']}: {missing}")

    target_headers = list(spec["columns"].values())
    source_order = list(spec["columns"].keys())
    output_path = OUTPUT_DIR / spec["target"]
    with output_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.writer(output_file)
        writer.writerow(target_headers)
        for row in rows:
            values = [clean(row[index_by_header[source_header]]) for source_header in source_order]
            if any(value != "" for value in values):
                writer.writerow(values)
    print(f"Wrote {output_path}")
