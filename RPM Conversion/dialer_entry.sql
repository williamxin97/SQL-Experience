SELECT
  A.MEAS_PRD_ID AS STMT_MONTH,
  CASE
    WHEN E.ORG_CDE IN ('004','005','226') THEN 'Active'
    ELSE 'Inactive' END AS PARTNER_STATUS,
  case --Branded Book cuts for Day 2 dialing
    when BAL_EOC_AMT >= 700 and BAL_EOC_AMT < 1250 and BAL_EOC_AMT/nullif(A.CRED_LMT_AMT,0) >= 1.009 then 'Day 2'
    when BAL_EOC_AMT >= 1250 and BAL_EOC_AMT < 3000 and BAL_EOC_AMT/nullif(A.CRED_LMT_AMT,0) >= 0.934 then 'Day 2'
    when BAL_EOC_AMT >= 3000 and BAL_EOC_AMT < 5000 and BAL_EOC_AMT/nullif(A.CRED_LMT_AMT,0) >=0.702 then 'Day 2'
    when BAL_EOC_AMT >= 5000 and BAL_EOC_AMT/nullif(A.CRED_LMT_AMT,0) >= 0.589 then 'Day 2'
    else 'Day 14'
    end as dialing_category,
  count(distinct a.arr_id_chain)
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
LEFT JOIN DB.PPDW.PTNR D
  ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
  ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
  ON E.ORG_CDE = F.ORG_CDE
WHERE A.MEAS_PRD_ID >= '201903'
  AND E.ATH_CURR_ACCT_IND = '1'
  and a.dlq_stat_cde = '02' --Bucket 1 accounts only
  and E.CRED_LMT_AMT
  AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
  and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
  and E.ORG_CDE NOT IN ('601')--Exclude Lord and Taylor and Saks
group by 1,2,3 order by 1 asc, 2 asc, 3 desc;

create or replace temporary table dial_entry_cat as (
SELECT
  A.MEAS_PRD_ID AS STMT_MONTH,
  CASE
    WHEN E.ORG_CDE IN ('004','005','226') THEN 'Active'
    ELSE 'Inactive' END AS PARTNER_STATUS,
  case --Branded Book cuts for Day 2 dialing
    when BAL_EOC_AMT >= 700 and BAL_EOC_AMT < 1250 and BAL_EOC_AMT/nullif(A.CRED_LMT_AMT,0) >= 1.009 then 'Day 2'
    when BAL_EOC_AMT >= 1250 and BAL_EOC_AMT < 3000 and BAL_EOC_AMT/nullif(A.CRED_LMT_AMT,0) >= 0.934 then 'Day 2'
    when BAL_EOC_AMT >= 3000 and BAL_EOC_AMT < 5000 and BAL_EOC_AMT/nullif(A.CRED_LMT_AMT,0) >=0.702 then 'Day 2'
    when BAL_EOC_AMT >= 5000 and BAL_EOC_AMT/nullif(A.CRED_LMT_AMT,0) >= 0.589 then 'Day 2'
    else 'Day 14'
    end as dialing_category,
  a.arr_id_chain
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
LEFT JOIN DB.PPDW.PTNR D
  ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
  ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
  ON E.ORG_CDE = F.ORG_CDE
WHERE A.MEAS_PRD_ID >= '202001'
  AND E.ATH_CURR_ACCT_IND = '1'
  and a.dlq_stat_cde = '02' --Bucket 1 accounts only
  and E.CRED_LMT_AMT
  AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
  and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
  and E.ORG_CDE NOT IN ('601')--Exclude Lord and Taylor and Saks
);



--script to find pay rate and dialing segmentation breakdown for RPM Whirl customers in Bucket 1
create or replace temporary table rpm_self_pay as (
select
  A.MEAS_PRD_ID AS STMT_MONTH, A.arr_id_chain, A.DLQ_LAST_INTO_DT, G.post_dt,
  case when post_dt is not null then G.post_dt - A.DLQ_LAST_INTO_DT else 100 end as pay_day, --# days after delinquency payment posted (100 for non-paying customers)
  TRAN_AMT,
  CALL_DT,
  case when call_dt is not null then 1 else 0 end as call_flag, --whether account was dialed
--to_date(concat (substring (meas_prd_id, 1, 4), '-',substring (meas_prd_id, 5,2),'-',A.CYCLE_DAY_NUM),'YYYY-MM-DD') as stmt_end_dt,
  CASE
    WHEN E.ORG_CDE IN ('004','005','226') THEN 'Active'
    ELSE 'Inactive' END AS PARTNER_STATUS,
  F.ORG_DESC as Partner,
  E.ORG_CDE as ORG_CD,
  case --Existing WHIRL segmentation category based on FICO, balance and account age
    when E.org_cde in ('226') and A.BAL_EOC_AMT > 1000 and C.FICO_NEXT_GENRN_SCORE < 720 then 'Day 7 Entry'
    when E.org_cde not in ('226') and A.BAL_EOC_AMT > 1000 and datediff(month,E.OPEN_DT,A.DLQ_LAST_INTO_DT) > 24 and C.FICO_NEXT_GENRN_SCORE < 720 and c.FICO_NEXT_GENRN_SCORE>= 640 then 'Day 14 Entry'
    when E.org_cde not in ('226') and A.BAL_EOC_AMT > 1000 and datediff(month,E.OPEN_DT,A.DLQ_LAST_INTO_DT) > 24 and C.FICO_NEXT_GENRN_SCORE < 640 then 'Day 7 Entry'
    when E.org_cde not in ('226') and datediff(month,E.OPEN_DT,A.DLQ_LAST_INTO_DT) < 24 then 'Day 7 Entry'
    else 'Day 30 Entry'
    end as dialing_entry,
  case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as Bucket --very few accounts with stat_cde = 09 (bucket 8)
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
join DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC B --only fresh Bucket 1 accounts
  on a.arr_id_chain = b.arr_id_chain
  and a.meas_prd_id = b.meas_prd_id + 1
  and b.dlq_stat_cde in ('00','01')
  and A.ATH_SEQ_NUM = B.ATH_SEQ_NUM
left join db.ppdw_credit.ARR_SNAP_low_pt c
  on a.arr_id_chain = c.arr_id_chain
  and a.dlq_last_into_dt = c.snap_dt
LEFT JOIN DB.PPDW.PTNR D
  ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
  ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
  ON E.ORG_CDE = F.ORG_CDE
left join DB.PPDW.TRAN_HIST_DLY g --payment table
  on a.arr_id_chain = g.arr_id_chain
  and dateadd(month, 1, A.DLQ_LAST_INTO_DT) > g.post_dt
  and A.DLQ_LAST_INTO_DT <= g.post_dt
  and A.ATH_SEQ_NUM = G.ATH_SEQ_NUM
  and G.tran_cat_cde='028'
left join ptnr_db_collab.lab_card_cb.collns_call_lvl_data h --check if called within 30 days of delinquency
  on a.arr_id_chain = h.acct_id
  and dateadd(day, 30, A.DLQ_LAST_INTO_DT) > h.call_dt
  and A.DLQ_LAST_INTO_DT <= h.call_dt
WHERE A.MEAS_PRD_ID >= '202001'
  AND E.ATH_CURR_ACCT_IND = '1'
  and c.snap_dt > '2020-01-01'
  and c.ath_curr_acct_ind = 1
  and C.FICO_NEXT_GENRN_SCORE >= 300
  and C.FICO_NEXT_GENRN_SCORE <= 850
  and a.dlq_stat_cde in ('02')
  and a.cycle_day_num not in ('29','30','31')
  AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
  and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
  and E.ORG_CDE NOT IN ('601')--Exclude Lord and Taylor and Saks
);

create or replace temporary table month_level_rpm as (
select stmt_month, arr_id_chain, min(pay_day) as earliest_pay, max(call_flag) as call_flag, max(dialing_entry) as dialing_entry from rpm_self_pay group by 1,2 order by 1,2
);

--select * from month_level_rpm;
create or replace temporary table dial_pay as (
select stmt_month, arr_id_chain, min(pay_day) as earliest_pay,
);

select earliest_pay, dialing_entry, count(*) as qty from month_level_rpm group by 1,2;

select * from
(select dialing_entry, stmt_month, count(*) as qty from month_level_rpm group by 1,2 order by 2 asc)
pivot (sum(qty) for dialing_entry in ('Day 7 Entry', 'Day 14 Entry', 'Day 30 Entry')) order by 1 asc;

--select * from temp_old limit 100;
create or replace temporary table temp as
(select a.arr_id_chain, a.stmt_month, a.dialing_entry, b.dialing_category as dialing_2
from month_level_rpm a
left join dial_entry_cat b
on a.arr_id_chain = b.arr_id_chain
and a.stmt_month = b.stmt_month);

select dialing_entry as dial_1, dialing_2 as dial_2, count(*) as qty from temp where stmt_month >= '202001' and dial_2 is not null group by 1,2 order by 1,2 desc;
