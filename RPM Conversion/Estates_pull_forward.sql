--Pull monthly Estates CO for RPM portfolios
create or replace temporary table rpm_estates as (
select a.account_id as omega_acct_id, a.previous_account_ID as arr_id_chain,
a.charge_off_date,
b.CHARGEOFFBALANCE,
b.CHARGEOFF_PRINCIPAL, reason_type_cd, COLL_STAT_U28_CDE, COLL_STAT_U28_CHNG_DT
from card_db.phdp_card.rcvry_acct_srvc_account as a
inner join card_db.phdp_card.rcvry_trxn_srvc_journal as b
on a.account_id = b.account_id and a.snap_dt=b.snap_dt
join db.ppdw_credit.arr_snap_dly c
on a.previous_account_id = c.arr_id_chain
and c.ath_curr_acct_ind  = 1
join CARD_DB.PHDP_CARD.RCVRY_ACCT_SRVC_CHARGE_OFF_REASON d
on a.account_id = d.account_id
and a.snap_dt = d.snap_dt
where a.snap_dt=(select max(snap_dt) from card_db.phdp_card.rcvry_acct_srvc_account)
and charge_off_date >= '2018-01-01'
and ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
and ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
and ORG_CDE NOT IN ('601', '602')
and reason_type_cd = 'DECEASED'
);

select concat(extract(YEAR from charge_off_date),LPAD(extract(MONTH from charge_off_date),2,'0')) as YYYYMM,
count(distinct arr_id_chain),sum(chargeoffbalance) from rpm_estates group by 1 order by 1;

select concat(extract(YEAR from charge_off_date),LPAD(extract(MONTH from charge_off_date),2,'0')) as YYYYMM,
sum(chargeoffbalance) from rpm_estates group by 1 order by 1;
