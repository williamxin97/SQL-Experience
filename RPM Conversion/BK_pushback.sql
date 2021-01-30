
create or replace temporary table rpm_monthly_bk13 as (
select a.*,b.BLK_1_CDE, b.BLK_1_CDE_DT,b.BLK_2_CDE, b.BLK_2_CDE_DT
from card_db_proc.prd_customer_resiliency.rcvry_account_r a
join db.ppdw_credit.arr_snap_low_pt b
on a.previous_account_id = b.arr_id_chain
and b.ath_curr_acct_ind = 1
and a.charge_off_date = b.snap_dt
where PREVIOUS_SYSTEM_OF_RECORD = 'WHIRL'
AND ORG NOT IN ('190','192','193') -- Exclude Canada
and ORG NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
and ORG NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
and ORG NOT IN ('601', '602')--Exclude Lord and Taylor and Saks
and charge_off_date >= '2019-01-01'
and CHARGE_OFF_REASON_CD = 'BANKRUPTCY_CHAPTER_13'
);

select concat(extract(YEAR from CHARGE_OFF_DATE),LPAD(extract(MONTH from CHARGE_OFF_DATE),2,'0')) as YYYYMM,
count(distinct account_id), sum(chargeoffbalance)
from rpm_monthly_bk13
group by 1 order by 1;

create or replace temporary table rpm_monthly_bk7 as (
select a.*, b.BLK_1_CDE, b.BLK_1_CDE_DT,b.BLK_2_CDE, b.BLK_2_CDE_DT from card_db_proc.prd_customer_resiliency.rcvry_account_r a
join db.ppdw_credit.arr_snap_low_pt b
on a.previous_account_id = b.arr_id_chain
and b.ath_curr_acct_ind = 1
and a.charge_off_date = b.snap_dt
where PREVIOUS_SYSTEM_OF_RECORD = 'WHIRL'
AND ORG NOT IN ('190','192','193') -- Exclude Canada
and ORG NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
and ORG NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
and ORG NOT IN ('601', '602')--Exclude Lord and Taylor and Saks
and charge_off_date >= '2019-01-01'
and CHARGE_OFF_REASON_CD = 'BANKRUPTCY_CHAPTER_7'
);

select concat(extract(YEAR from CHARGE_OFF_DATE),LPAD(extract(MONTH from CHARGE_OFF_DATE),2,'0')) as YYYYMM,
count(distinct account_id), sum(chargeoffbalance)
from rpm_monthly_bk7
group by 1 order by 1;
