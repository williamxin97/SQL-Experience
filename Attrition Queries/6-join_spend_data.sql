
--Pull spend data for everyone in the dataset who complained
--  no one really knows what all of these filters do
--This will take some time to run

create or replace table sb.user_aik604.iac_spend as (
  select acct_id, trxn_amt, trxn_dt from db.pcdw.t2_postd_trxn
  where acct_id in (select acct_id from sb.user_aik604.iac_data)
  and trxn_dt between '2018-06-01' and '2030-01-01'
  and trxn_post_dt between '2018-06-01' and '2030-01-01'
  and tsys_tcat_cd = '0001' -- purchase related transactions (purchase: 0001; cash advance: 0002; ATM cash advance: 0003; Convience cash advance: 0004)
  AND trxn_amt > 0.08 -- excluding those suspicious account validation trxns < 8 cents
  AND provdr_1_id = 1 -- US accounts only
  AND acct_sfx_num = 0 -- Nothing that could have been lost, stolen, hit by fraud
  AND tsys_tcat_class_cd = 'PR' -- Purchase related transactions only
  AND TSYS_TBAL_CD = '0001' -- some debit PFC transactions fall into TBAL 4 & 7
  AND TSYS_TRXN_POSTG_CD IN ('DBT', 'CRT') -- only debit or credit trxns, excluding PFC, CBR, DAJ, FDA, MSD
  AND mrch_catg_cd IS NOT NULL
  AND mrch_catg_cd <> 0
  AND tsys_orig_tcat_cd IN ('0001','0009','0020','0022','0024','0048','0057','0058')
  AND tsys_trxn_cd NOT IN ('0403', '0132', '0133', '0162', '0163', '0186', '0187', '0197', '0198', 
                           '0404','0451', '0452', '0479', '0481', '0368','0369', '0370', '0371', 
                           '0480', '7263','7239', '7267', '7240', '0375','0813', '0812', '7261', '7251')
);

--iac_spend stands for info, complaints, and spend

create or replace table sb.user_aik604.iac_spend as (
  select distinct a.trxn_amt, a.trxn_dt, b.acct_id, b.segment, b.stat_segment, b.cls_dt, b.open_dt, b.tier, b.mapped_driver, b.primary_driver, b.primary_subdriver, b.date_received
  from sb.user_aik604.iac_data b
  left join sb.user_aik604.iac_spend a
  on a.acct_id = b.acct_id
);
