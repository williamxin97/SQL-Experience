--This script looks at GM accounts and balances enrolled in concessionary + non-concessionary offers


SET start_date = '2019-01-01 00:00:00.000';
SET end_date = '2020-09-29 23:59:59.999';

-- Create toolsDB table for offers pulling/parsing relevant columns from the raw offers table
CREATE OR REPLACE TABLE toolsDB_BAP_DATA1 AS(
SELECT ofr_terms_id, sor_acct_id AS acct_id, sor_id, ofr_terms_detl_strc, ofr_id, snap_dt,
case
  when ofr_id = 17021 then 'Concessionary - 7.4% APR 3PDM'
  when ofr_id = 17022 then 'Concessionary - 1.9% APR 3PDM'
  when ofr_id = 17297 then 'Concessionary - Partnership 3PDM'
  when ofr_id between 18307 and 18311 then 'Non-Concessionary - STAR'
  when ofr_id = 18312 then 'Concessionary - LTPP'
  when ofr_id = 21449 then 'Concessionary - 9.9% APR 3PDM'
  when ofr_id = 30795 then 'Concessionary - Skip Pay'
  when ofr_id = 30805 then 'Concessionary - STO'
  when ofr_id = 100001 then 'Concessionary - EPCOT'
  when ofr_id = 100002 then 'Non-Concessionary - BAP CURE REAGE'
  when ofr_id = 100004 then 'Non-Concessionary - BAP CURE'
  when ofr_id = 100006 then 'Non-Concessionary - BAP BAU'
  when ofr_id = 100010 then 'BAP CONTROL'
  when ofr_id = 200011 then 'Concessionary - SETTLEMENTS-200011'
  when ofr_id = 200012 then 'Concessionary - SETTLEMENTS-200012'
  when ofr_id = 200013 then 'Concessionary - SETTLEMENTS-200013'
  when ofr_id = 200014 then 'Concessionary - SETTLEMENTS-200014'
  when ofr_id = 200015 then 'Concessionary - SETTLEMENTS-200015'
  when ofr_id = 300001 then 'Concessionary - SA FEE SUPPRESSION'
  when ofr_id = 400001 then 'Non-Concessionary - AUN SINGLE'
  when ofr_id = 400002 then 'Non-Concessionary - AUN MULTIPLE'
  when ofr_id = 500001 then 'Concessionary - EELB'
  else 'UNKNOWN' end as ofr_id_desc,
ofr_type_cd AS ofr_type, enrlmt_stat_cd, enrled_ts:: datetime dt_enrolled, enrled_Sys_Cd AS sys_enrolled,
ofr_flfld_ts:: datetime flfld_dt, ofr_brkn_ts:: datetime brkn_dt, cretd_ts:: datetime dt_cretd,
cretd_sys_nm AS sys_cretd, modd_ts :: datetime modd_dt, modd_sys_nm AS sys_modd, tot_paid_amt AS tot_amt_paid,
zeroifnull(parse_json(ofr_terms_detl_strc):"paymentAmount") AS pmt_Amt,
zeroifnull(parse_json(ofr_terms_detl_strc):"numberOfPayments") AS num_of_pmts,
parse_json(ofr_terms_detl_strc):"frequency" AS pmt_freq,
parse_json(ofr_terms_detl_strc):"startDate" AS pmt_strt_dt
FROM card_db.phdp_card_npi.OFR_TERMS
WHERE ofr_id IN(100001, 100002, 100003, 100004, 100005, 100006, 100007, 100008, 100009, 100010, 17021, 17022, 17297,18312, 21449, 200011, 200012, 200013, 200014, 200015, 300001, 400001, 400002, 500001)
--AND cretd_sys_nm = 'web'
AND snap_dt = (SELECT MAX(snap_dt) FROM card_db.phdp_card_npi.OFR_TERMS)
);

select * from card_db.phdp_card.OFR_TERMS limit 10;
/** For whatever reason the post Snowflake card_db.phdp_card_npi.OFR_TERMS table has each offer cloned 19 times,
so the following UNION dedupes the offers and leaves the user with a clean list. **/
CREATE OR REPLACE TABLE toolsDB_BAP_DATA1 AS(
SELECT * FROM toolsDB_BAP_DATA1
UNION
SELECT * FROM toolsDB_BAP_DATA1);


CREATE OR REPLACE TABLE toolsdb AS(
SELECT
/*****  Take important columns from toolsDB ********/
a.snap_dt, a.ofr_terms_id, a.acct_id, a.ofr_id, a.ofr_id_desc, a.ofr_type, a.enrlmt_stat_cd,
a.tot_amt_paid, a.pmt_amt, a.num_of_pmts, a.pmt_freq, a.pmt_strt_dt
-- Parse the ofr_terms_detl_strc column to identify the type of plan and test segment
,CASE WHEN split_part(ofr_terms_detl_strc,'"',18) in ('100001-C','100001-Control') AND ofr_id = 100010 THEN 'Non-Concessionary - EPCOT'
WHEN split_part(ofr_terms_detl_strc,'"',18) in ('100002-C','100002-Control')  AND ofr_id = 100010 THEN 'Non-Concessionary - CURE REAGE'
WHEN split_part(ofr_terms_detl_strc,'"',18) in ('100004-C','100004-Control')  AND ofr_id = 100010 THEN 'Non-Concessionary - CURE'
ELSE ofr_id_desc END test_segment
-- Create test cell divisions and enrollment flag
,CASE WHEN ofr_id_desc NOT IN ('CONTROL', 'BAU') THEN 'TEST' WHEN ofr_id_desc = 'BAU' then 'BAU' ELSE 'CONTROL' end AS test_cell,
CASE WHEN enrlmt_stat_cd <> 'PRESENTED' THEN 1 ELSE 0 END AS enroll_flag,
/****** Convert timezones **************/
convert_timezone('UTC', 'America/New_York', dt_cretd) AS input_ts_et, ------ dt_cretd column is used to determine input date; represents time of initial input creation
convert_timezone('UTC', 'America/New_York', dt_enrolled) AS ts_enrolled_et,
convert_timezone('UTC', 'America/New_York', flfld_dt) AS ts_flfld_et,
convert_timezone('UTC', 'America/New_York', brkn_dt) AS ts_brkn_et,
CAST(input_ts_et AS DATE) AS input_dt_et,
CAST(ts_enrolled_et AS DATE) AS enrolled_dt_et,
CAST(ts_flfld_et AS DATE) AS flfld_dt_et,
CAST(ts_brkn_et AS DATE) AS brkn_dt_et,
CASE WHEN flfld_dt_et IS NULL AND brkn_dt_et IS NOT NULL THEN brkn_dt_et
WHEN brkn_dt_et IS NULL AND flfld_dt_et IS NOT NULL THEN flfld_dt_et
END AS end_dt
-- Create months
,CASE WHEN dt_cretd < '2017-11-20 19:59:47' THEN '0-Pre-Asp'
ELSE SUBSTR(CAST(input_dt_et AS VARCHAR(20)), 1, 7) end mnth,
sys_cretd AS channel,
-- alternate offer column to identify cure vs cure reage control groups
case
when (split_part(ofr_terms_detl_strc,'"',18) in ('100002-C','100002-Control') and a.ofr_id = 100010) or a.ofr_id = 100002 then 'Non-Concessionary - CURE REAGE'
when (split_part(ofr_terms_detl_strc,'"',18) in ('100004-C','100004-Control') and a.ofr_id = 100010) or a.ofr_id = 100004 then 'Non-Concessionary - CURE'
when (split_part(ofr_terms_detl_strc,'"',18) in ('100001-C','100001-Control') and a.ofr_id = 100010) or a.ofr_id = 100001 then 'Non-Concessionary - EPCOT'
when a.ofr_id = '100008' then 'STAY DQ CHARGE OFF'
when a.ofr_id = '100009' then 'STAY DQ CURE'
when a.ofr_id = '100003' then 'CHARGE OFF'
when a.ofr_id = '100006' then 'BAU'
else 'OTHER' end as offer
FROM toolsDB_BAP_DATA1 a ------ Update with new toolsdb table, may need to adjust query with new column names or create new columns
);

--Add in concessionary column
create or replace table toolsdb as (select *
, case when test_segment like 'Concessionary%' then 'Concessionary'
  when test_segment like 'Non-Concessionary%' then 'Non-Concessionary'
  else 'Other'
  end as concess
from toolsdb);

--Only look at current offers
create or replace table current_offers as (
  select * from toolsdb
  where enrolled_dt_et is not null
  and end_dt is null
  and test_cell = 'TEST'
  and enrlmt_stat_cd <> 'CANCELLED'
  and enrlmt_stat_cd <> 'BROKEN'
  and enrlmt_stat_cd <> 'PRESENTED'
);

--Join to svc_ownr_cd
create or replace table current_offers_svc as (
  select a.*, b.svc_ownr_cd
  from current_offers a
  left join db.pcdw.t2_acct_stat_hist_bc b
  on a.acct_id = b.acct_id
  and b.acct_sfx_num = 0
  and b.provdr_1_id = 1);

--Filter for GM
create or replace table gm_offers as (select * from current_offers_svc 
where svc_ownr_cd in (99,100,101,102));

--Some accounts are enrolled in multiple programs. This filters for the most recent one
create or replace table gm_r_offers as (
  select b.*
  from (select acct_id, max(ts_enrolled_et) as max_dt from gm_offers group by 1) a
  left join
  gm_offers b
  on a.acct_id = b.acct_id
  and a.max_dt = b.ts_enrolled_et
);

--Find account statements for GM
create or replace table gm_bal as (
  select a.acct_id, a.test_segment, a.enrlmt_stat_cd, a.enrolled_dt_et, a.concess, b.stmt_end_dt, b.curr_bal as bal, b.cyc_pdue_bkt_num as bkt
  from gm_r_offers a
  left join db.pcdw.t2_stmt b
  on a.acct_id = b.acct_id
  and b.acct_sfx_num = 0
  and b.provdr_1_id = 1
  and b.stmt_end_dt >= '2020-01-01'
  );

--Only look at most recent statement for each account
create or replace table gm_r_bal as (
  select b.*
  from (select acct_id, max(stmt_end_dt) as max_dt from gm_bal group by 1) a
  left join gm_bal b
  on a.acct_id = b.acct_id
  and a.max_dt = b.stmt_end_dt
);

--For readability
create or replace table gm_r2_bal as(
  select *
  , case when upper(test_segment) like '%3PDM%' then '3PDM'
      when upper(test_segment) like '%FEE SUPP%' then 'SA - Specialty Assistance Fee Suppression'
      when upper(test_segment) like '%BAP CURE REAGE%' then 'BAP CURE REAGE - Build a Plan'
      when upper(test_segment) like '%BAP CURE%' then 'BAP CURE - Build a Plan'
      when upper(test_segment) like '%AUN%' then 'AUN - Auto Unrestriction'
      when upper(test_segment) like '%LTPP%' then 'LTPP - Long Term Payment Plan'
      end as offer
 from gm_r_bal);

--Output 1
select concess as concessionary, offer, count(acct_id) as accts, sum(bal) as total_balance 
  from gm_r2_bal 
  where bkt <= 6
  group by 1,2 order by 1,3 desc;
  
--Output 2
select concess as concessionary, offer, bkt as bucket, count(acct_id) as accts, sum(bal) as total_balance 
  from gm_r2_bal 
  where bucket <= 6
  group by 1,2,3 order by 1,2,3 asc;
select * from gm_r2_bal where offer like '%AUN%';
