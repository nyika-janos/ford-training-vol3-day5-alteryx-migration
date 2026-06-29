CREATE OR REPLACE TABLE `ford-training-430008.03_ibis_bel_nld_raw.ibis_nld_raw` (
  market STRING,
  MKT_CUSTOMER_ID_C STRING,
  SSA_TRADE_N STRING,
  billing_country STRING,
  FINIS STRING,
  MLI STRING,
  MDSMT_MNTHYR_Y STRING,
  LOC_BDN STRING,
  gross_revenue STRING,
  billed_revenue STRING,
  gross_pieces STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.03_ibis_bel_nld_raw.ibis_bel_raw` (
  market STRING,
  MKT_CUSTOMER_ID_C STRING,
  SSA_TRADE_N STRING,
  billing_country STRING,
  FINIS STRING,
  MLI STRING,
  MDSMT_MNTHYR_Y STRING,
  LOC_BDN STRING,
  gross_revenue STRING,
  billed_revenue STRING,
  gross_pieces STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.03_ibis_bel_nld_raw.mli_classification_alteryx_raw` (
  text_mli STRING,
  mli_description STRING,
  basket STRING,
  mpl_code STRING,
  pct_code STRING,
  cg_code STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.03_ibis_bel_nld_raw.nld_parts_raw` (
  part_description STRING,
  FINIS STRING
);
