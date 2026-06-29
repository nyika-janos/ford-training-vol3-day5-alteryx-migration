CREATE OR REPLACE TABLE `ford-training-430008.04_nld_sor_raw.nld_sor_raw` (
  Market STRING,
  DealerCode STRING,
  MLI STRING,
  Months STRING,
  channel STRING,
  payment STRING,
  BusinessY STRING,
  BusinessM STRING,
  BusinessQ STRING,
  MKTG STRING,
  UCC STRING,
  channel_1 STRING,
  LOC_Invoiced STRING,
  LOC_BDN STRING,
  LOC_RRP STRING,
  USD_Invoiced STRING,
  USD_BDN STRING,
  USD_RRP STRING,
  qty STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.04_nld_sor_raw.nld_did_raw` (
  i22_parts_alias STRING,
  i22_iso_mktcd STRING,
  i22_dealer_cd STRING,
  i22_dlrname STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.04_nld_sor_raw.mli_classification_alteryx_raw` (
  text_mli STRING,
  mli_description STRING,
  basket STRING,
  mpl_code STRING,
  pct_code STRING,
  cg_code STRING
);
