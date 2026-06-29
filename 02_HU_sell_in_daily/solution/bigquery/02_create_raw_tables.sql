CREATE OR REPLACE TABLE `ford-training-430008.02_hu_sell_in_raw.hu_ibis_raw` (
  market STRING,
  DealerCode STRING,
  FINIS STRING,
  MLI STRING,
  Months STRING,
  LOC_RRP STRING,
  LOC_BDN STRING,
  USD_RRP STRING,
  USD_BDN STRING,
  billed_revenue STRING,
  qty STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.02_hu_sell_in_raw.mli_classification_alteryx_raw` (
  text_mli STRING,
  mli_description STRING,
  basket STRING,
  mpl_code STRING,
  pct_code STRING,
  cg_code STRING
);

CREATE OR REPLACE TABLE `ford-training-430008.02_hu_sell_in_raw.hu_sor_parts_price_raw` (
  EDWAO25_FINIS_C STRING,
  EDWAO25_ISO2_CNTRY_C STRING,
  EDWAO25_VALID_FROM_Y STRING,
  EDWAO25_VALID_UNTIL_Y STRING,
  EDWAO25_FINIS_X STRING,
  EDWAO25_MLI_C STRING,
  EDWAO25_BASIC_DISCOUNT_P STRING,
  EDWAO25_RTL_OR_NET_PRICE_A STRING,
  EDWAO25_ACTIVE_F STRING
);
