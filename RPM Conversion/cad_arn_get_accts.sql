create or replace temporary table current_whirl_7 as (
select b.*, c.CEASE_DESIST_CDE, a.arr_id_acct from  db.ppdw_credit.arr_snap_dly b
join db.ppdw_credit.arr_perfm_snap_eom c
on b.arr_id_chain = c.arr_id_chain
and c.meas_prd_id = '202011'
join db.ppdw_secured.pshp_plstc_card_bc a
on b.arr_id_chain = a.arr_id_chain
--join db.ppdw_credit.arr_perfm_snap_eoc d
--on b.arr_id_chain = d.arr_id_chain
--and c.meas_prd_id = d.meas_prd_id
where B.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and B.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
and B.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
and B.ORG_CDE NOT IN ('601') --Exclude Lord and Taylor and Saks
and b.ath_curr_acct_ind = 1
and c.cease_desist_cde in ('AT','CD','PA')
--and (b.BLK_1_CDE_DT is null or b.BLK_1_CDE_DT > dateadd(YEAR, -2, '2020-06-01'))
--and (b.BLK_2_CDE_DT is null or b.BLK_2_CDE_DT > dateadd(YEAR, -2, '2020-06-01'))
);
select count(distinct arr_id_chain) from current_whirl_7;
select count(distinct c.arr_id_chain) from  db.ppdw_credit.arr_snap_dly b
join db.ppdw_credit.arr_perfm_snap_eom c
on b.arr_id_chain = c.arr_id_chain
and c.meas_prd_id = '202011'
join db.ppdw_secured.pshp_plstc_card_bc a
on b.arr_id_chain = a.arr_id_chain
--join db.ppdw_credit.arr_perfm_snap_eoc d
--on b.arr_id_chain = d.arr_id_chain
--and c.meas_prd_id = d.meas_prd_id
where B.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and B.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
and B.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
and B.ORG_CDE NOT IN ('601') --Exclude Lord and Taylor and Saks
and b.ath_curr_acct_ind = 1
--and c.cease_desist_cde in ('AT','CD','PA')
;
-- select cease_desist_cde, count(distinct arr_id_chain) from current_whirl_7 group by 1 order by 1

--Create driver table of C&D cycling TSYS accounts
create or replace temporary table current_tsys_7 as (
select a.*
from db.pcdw.t2_acct_stat_hist_bc a
where a.acct_sfx_num = 0
and CSTM_DATA_81 = 20

);
select count(distinct acct_id) from db.pcdw.t2_acct_stat_hist_bc;
--Create driver table of C&D cycling Omega accounts
create or replace temporary table current_omega_7
as(
select a.*, b.characteristic
from card_db.phdp_card.rcvry_acct_srvc_account as a
join card_db.phdp_card.rcvry_chrstc_srvc_characteristics b
on a.account_id = b.account_id and a.snap_dt = b.snap_dt
--inner join card_db.phdp_card.rcvry_trxn_srvc_journal as b
--on a.account_id = b.account_id and a.snap_dt=b.snap_dt and a.snap_dt=current_date-1  and b.snap_dt = current_date-1
--where a.previous_account_ID in (select acct_id from walmart_accts_inventory)  and charge_off_date = '2020-02-08'
where a.snap_dt = (select max(snap_dt) from card_db.phdp_card.rcvry_acct_srvc_account)
and characteristic = 'CEASE_AND_DESIST'
);


select count( distinct arr_id_chain) from current_whirl_7 limit 100;
select count(distinct acct_id) from current_tsys_7;
select count(distinct account_id) from current_omega_7 limit 100;


--Link WHIRL accounts to enterprise IDs
create or replace temporary table whirl_escid_7 as (
select * from cdi_master_file_20200719 a
join current_whirl_7 b
on a.acct_id = TO_VARCHAR (b.arr_id_acct)
);

--Link TSYS accounts to enterprise IDs
create or replace temporary table tsys_escid_7 as (
select b.*, a.escid, a.ent_cust_id from cdi_master_file_20200719 a
join current_tsys_7 b
on a.acct_id = TO_VARCHAR (b.acct_id)
);

--Link Omega accounts to enterprise IDs
create or replace temporary table omega_escid_7 as (
select b.*, a.escid, a.ent_cust_id from cdi_master_file_20200719 a
join current_omega_7 b
on a.acct_id = TO_VARCHAR (b.account_id)
);

/*
select sor_id, count(distinct escid) from whirl_escid_7 group by 1
select * from whirl_escid_7 limit 100;
select org_cde, count(distinct arr_id_chain) from whirl_escid_7  group by 1 order by 2 desc
select sor_id, count(*) from rpm_escid_7 group by 1 order by 1 --limit 100;
select count(distinct arr_id_chain) from rpm_escid_7 limit 100;
select count(*) from overlap limit 100;
select count(distinct ent_cust_id) from overlap
*/

--Find WHIRL accounts that overlap onto TSYS
create or replace temporary table tsys_overlap_whirl_7  as (
select a.*, b.pdue_catg_cd, b.chrgof_reas_cd, b.clsd_reas_cd, b.CSTM_DATA_81, c.CEASE_DESIST_CDE from cdi_master_file_20200719 a
join db.pcdw.t2_acct_stat_hist_bc b
on TO_VARCHAR(a.acct_id) = TO_VARCHAR(b.acct_id)
and b.acct_sfx_num = 0
--and b.provdr_1_id = 1
join whirl_escid_7 c
on a.ent_cust_id = c.ent_cust_id
and a.sor_id = 7
);

--Find WHIRL accounts that overlap onto Omega
create or replace temporary table omega_overlap_whirl_7 as (
select a.*, c.characteristic, d.CEASE_DESIST_CDE
from cdi_master_file_20200719 a
join card_db.phdp_card.rcvry_acct_srvc_account as b
on TO_VARCHAR(a.acct_id) = TO_VARCHAR(b.account_id)
join card_db.phdp_card.rcvry_chrstc_srvc_characteristics c
on b.account_id = c.account_id and b.snap_dt = c.snap_dt
join whirl_escid_7 d
on a.ent_cust_id = d.ent_cust_id
and a.sor_id = 6
where b.snap_dt = (select max(snap_dt) from card_db.phdp_card.rcvry_acct_srvc_account)
--and characteristic = 'CEASE_AND_DESIST'
);

--Find TSYS accounts that overlap onto WHIRL
create or replace temporary table whirl_overlap_tsys_7 as (
select b.arr_id_chain, a.*, e.CSTM_DATA_81, d.CEASE_DESIST_CDE from cdi_master_file_20200719 a
join db.ppdw_secured.pshp_plstc_card_bc b
on TO_VARCHAR(a.acct_id) = TO_VARCHAR(b.arr_id_acct)
join db.ppdw_credit.arr_snap_dly c
on b.arr_id_chain = c.arr_id_chain
join db.ppdw_credit.arr_perfm_snap_eom d
on b.arr_id_chain = d.arr_id_chain
and d.meas_prd_id = '202011'
join tsys_escid_7 e
on a.ent_cust_id = e.ent_cust_id
and a.sor_id = 207
where c.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and c.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
and c.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
and c.ORG_CDE NOT IN ('601') --Exclude Lord and Taylor and Saks
and c.ath_curr_acct_ind = 1
);

----Find Omega accounts that overlap on WHIRL
create or replace temporary table whirl_overlap_omega_7 as (
select b.arr_id_chain, a.*, e.characteristic, d.CEASE_DESIST_CDE
from cdi_master_file_20200719 a
join db.ppdw_secured.pshp_plstc_card_bc b
on TO_VARCHAR(a.acct_id) = TO_VARCHAR(b.arr_id_acct)
join db.ppdw_credit.arr_snap_dly c
on b.arr_id_chain = c.arr_id_chain
join db.ppdw_credit.arr_perfm_snap_eom d
on b.arr_id_chain = d.arr_id_chain
and d.meas_prd_id = '202011'
join omega_escid_7 e
on a.ent_cust_id = e.ent_cust_id
and sor_id = 207
where c.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and c.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
and c.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
and c.ORG_CDE NOT IN ('601') --Exclude Lord and Taylor and Saks
and c.ath_curr_acct_ind = 1
);

--select count(distinct escid) from tsys_escid_7
--select * from tsys_escid_7 where escid in (select distinct escid from DGTL_DB_COLLAB.lab_deca.cdi_master_file_20200202 where sor_id = 207) limit 100;
--select count(distinct escid) from DGTL_DB_COLLAB.lab_deca.cdi_master_file_20200202 where sor_id = 207


--Pull number of accounts where C&D statuses don't match
create or replace temporary table TOW as (select distinct acct_id from Tsys_overlap_whirl_7 where CSTM_DATA_81 <> 20);
create or replace temporary table OOW as (select distinct acct_id from omega_overlap_whirl_7 where characteristic <> 'CEASE_AND_DESIST');
create or replace temporary table WOT as (select distinct arr_id_chain from whirl_overlap_tsys_7 where CEASE_DESIST_CDE not in ('AT','CD','PA'));
create or replace temporary table WOO as (select distinct arr_id_chain from whirl_overlap_omega_7 where CEASE_DESIST_CDE not in ('AT','CD','PA'));

select count(distinct acct_id) from TOW;
select count(distinct acct_id) from OOW;
select count(distinct arr_id_chain) from WOT;
select count(distinct arr_id_chain) from WOO;



  
create or replace table WOT2 as
(
SELECT
  a.arr_id_chain
  ,case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as bkt
  , bal_eoc_amt as bal
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
  ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
WHERE A.MEAS_PRD_ID = '202011'
  and a.arr_id_chain in (select arr_id_chain from WOT)
  AND E.ATH_CURR_ACCT_IND = '1'
  AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
  and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
  and E.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
  and E.ORG_CDE NOT IN ('601')--Exclude Lord and Taylor and Saks
);

create or replace table WOO2 as
(
SELECT
  a.arr_id_chain
  ,case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as bkt
  , bal_eoc_amt as bal
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
  ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
WHERE A.MEAS_PRD_ID = '202011'
  and a.arr_id_chain in (select arr_id_chain from WOO)
  AND E.ATH_CURR_ACCT_IND = '1'
  AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
  and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
  and E.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
  and E.ORG_CDE NOT IN ('601')--Exclude Lord and Taylor and Saks
);

select 'T over W' as category
  , case when b.cyc_pdue_bkt_num >= 7 then 7 else b.cyc_pdue_bkt_num end as bkt, count(distinct a.acct_id) as accts, sum(curr_bal) as bals
  from TOW a
  left join db.pcdw.t2_stmt b
    on a.acct_id = b.acct_id
    and date_trunc('month',b.stmt_end_dt) = '2020-11-01'
  where bkt is not null
  group by 1,2 order by 2 asc;
  
select 'W over T' as category
  , case when bkt >= 7 then 7 else bkt end as bkt, count(distinct arr_id_chain) as accts, sum(bal) as bals
  from WOT2
  --where bkt is not null
  group by 1,2 order by 2 asc;
  
select 'W over O' as category
  , case when bkt >= 7 then 7 else bkt end as bkt, count(distinct arr_id_chain) as accts, sum(bal) as bals
  from WOO2
  --where bkt is not null
  group by 1,2 order by 2 asc;
