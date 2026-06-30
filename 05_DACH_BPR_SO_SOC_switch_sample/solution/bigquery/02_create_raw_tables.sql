CREATE OR REPLACE TABLE `ford-training-430008.05_dach_bpr_so_raw.bpr_so_gcp_export_raw` (
  market_code STRING,
  hdlnr STRING,
  sell_out_channel STRING,
  bes_flag STRING,
  mli_code STRING,
  year_yyyy STRING,
  month_mm STRING,
  quantity STRING,
  base_discount STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.05_dach_bpr_so_raw.mli_master_raw` (
  id STRING,
  aktiv STRING,
  cy STRING,
  mli_oil STRING,
  mli_0000 STRING,
  mli STRING,
  bezeichnung STRING,
  bu STRING,
  business_unit STRING,
  program_mli_groups STRING,
  mli_num STRING,
  finanz_trans_etc STRING,
  garantie STRING,
  mli_txt STRING,
  cb_mli STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.05_dach_bpr_so_raw.month_mapping_raw` (
  month_no STRING,
  month_txt STRING,
  month_mm STRING,
  month_eng_short STRING,
  month_eng_long STRING,
  month_ger_short STRING,
  month_ger_long STRING,
  quartal STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.05_dach_bpr_so_raw.sellout_agreements_raw` (
  nsc_iso STRING,
  markt_haendlernummer STRING,
  haendlernummer STRING,
  soc_qlf STRING,
  soc_sor STRING,
  soc_num STRING,
  soc_num_txt STRING,
  eigene_werkstatt_mit_strecke STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.05_dach_bpr_so_raw.sellout_channels_raw` (
  sellout_channel STRING,
  sor_code STRING,
  channel_name STRING,
  kategorie_old STRING,
  kategorie_new STRING,
  cluster STRING,
  soc_num_txt STRING,
  cluster_fcsd STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.05_dach_bpr_so_raw.tbl_haendler_all_raw` (
  markt STRING,
  haendlernummer STRING,
  markt_haendlernummer STRING,
  poolinggruppe_sellout STRING,
  region_teile STRING,
  thg STRING,
  haendlername STRING,
  tn_teilebonus_status STRING,
  tn_teilebonus_101_freie_werkstatt STRING,
  tn_teilebonus_104_service_u_karosserie_kettengebunden STRING,
  reporting_inkludiert_teile STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.05_dach_bpr_so_raw.tbl_aktive_haendler_raw` (
  markt STRING,
  markt_haendlernummer STRING,
  haendlernummer STRING,
  haendlerstatus STRING,
  region_teile STRING,
  thg STRING,
  tn_teilebonus_status STRING,
  reporting_inkludiert_teile STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.05_dach_bpr_so_raw.top_bottom_mli_raw` (
  region STRING,
  thg_betreuer_name STRING,
  pg STRING,
  mli_txt STRING,
  fb_afsb STRING,
  markt_haendlernummer STRING,
  tn_teilebonus_status STRING,
  mli_num STRING,
  mli_oil STRING,
  business_unit STRING,
  program_mli_groups STRING,
  finanz_trans_etc STRING,
  actj STRING,
  vorj STRING,
  wert STRING
);