--select acct_sfx_num from DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC limit 100;

--FICO
select A.MEAS_PRD_ID AS STMT_MONTH,
CASE
 WHEN E.ORG_CDE IN ('226') THEN 'Active - Menards' --RPM1
    WHEN E.ORG_CDE IN ('329','222','176','420','800') then 'Inactive - Powersports' --RPM1
    when E.ORG_CDE IN ('856') then 'Inactive - Dressbarn' --RPM1
    when E.ORG_CDE IN ('004','005') then 'Active - Neiman and Bergdorf Goodman' --RPM2
    when E.ORG_CDE IN ('602') then 'Inactive - Lord and Taylor and Saks' --RPM2
    ELSE 'Inactive - Other' --RPM1
    end as partner_group
--F.ORG_DESC as Partner,
--E.ORG_CDE as ORG_CD,
--case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as Bucket, --very few accounts with stat_cde = 09 (bucket 8)
, avg(E.FICO_NEXT_GENRN_SCORE) as avg_fico

FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
LEFT JOIN DB.PPDW.PTNR D
ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
ON E.ORG_CDE = F.ORG_CDE
WHERE A.MEAS_PRD_ID >= '202009'
AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and E.ORG_CDE NOT IN ('202','855','857','601') --Exclude Helzberg, Justice and Maurices
and A.DLQ_STAT_CDE < 8
and E.FICO_NEXT_GENRN_SCORE >= 300
and E.FICO_NEXT_GENRN_SCORE <= 850
and e.ath_curr_acct_ind = 1
AND E.ATH_CURR_ACCT_IND = '1'
group by 1,2 order by partner_group asc;

--BB
create or replace temporary table fico_prep as (
select a.acct_id, a.stmt_end_dt, a.cl_amt, a.curr_bal, a.cyc_pdue_bkt_num,
case
  WHEN svc_ownr_cd IN ('000010','000011', '000051', '000088','000086','000090','000091') THEN 'Mainstreet (US Card)'    
  WHEN svc_ownr_cd IN ('000022','000023', '000052', '000087', '000089') THEN 'Upmarket (US Card)'    
  when a.svc_ownr_cd in ('000114','000115','000118','000119','000120','000121') then 'Walmart'
  --when a.svc_ownr_cd in ('000114','000115') then 'Walmart PLCC'
  --when a.svc_ownr_cd in ('000118','000119','000120','000121') then 'Walmart Cobrand'
    else 'Other'   
end as lob	          
from db.pcdw.t2_stmt a  
where a.stmt_end_dt >= '2020-08-01'
and a.acct_sfx_num = 0
and a.cyc_pdue_bkt_num in (0,1,2,3,4,5,6) );
--where svc_ownr_cd in ('000114','000115','000118','000119','000120','000121') and a.stmt_end_dt > '2019-10-01');


create or replace temporary table fico as (
  select a.*, b.fico_score
  from fico_prep as a
  left join (
    select z.*
    from (
      select a.*, b.EFICO_5_SCORE_VAL as fico_score, b.EFICO_SCORE_CRETN_DT_TXT as score_dt,
      row_number() over(partition by a.acct_id, a.stmt_end_dt order by b.EFICO_SCORE_CRETN_DT_TXT desc) as R1
      from fico_prep as a
      left join db.pcdw.cr_rpt_efx as b
      on a.acct_id = b.acct_id
      and b.EFICO_SCORE_CRETN_DT_TXT between add_months(a.stmt_end_dt,-1) and a.stmt_end_dt
      ) as z
    where z.R1 = 1
    ) as b
  on a.acct_id = b.acct_id
  and a.stmt_end_dt = b.stmt_end_dt
  )
;
/*
select concat(extract(YEAR from stmt_end_dt),LPAD(extract(MONTH from stmt_end_dt),2,'0')) as YYYYMM, lob,
case	
    when fico_score <= 550 then '<550'	
    when fico_score > 550 and fico_score <= 600 then '551-600'	
    when fico_score > 600 and fico_score <= 650 then '601-650'	
    when fico_score > 650 and fico_score <= 700 then '651-700'	
    when fico_score > 700 and fico_score <= 750 then '701-750'	
    when fico_score > 750 and fico_score <= 800 then '751-800'	
    when fico_score > 800 and fico_score <= 850 then '801-850'	
    when fico_score > 850 or fico_score < 300 then 'Invalid'	
    when fico_score is null then 'Null'
    else 'Other' 	
end as fico_band,
count (distinct acct_id), sum(curr_bal)
from fico group by 1,2,3 order by 1,2,3;

select concat(extract(YEAR from stmt_end_dt),LPAD(extract(MONTH from stmt_end_dt),2,'0')) as YYYYMM, lob, cyc_pdue_bkt_num, avg(fico_score) from fico
where fico_score >= 300 and fico_score <= 850 and lob <> 'Other' and cyc_pdue_bkt_num in (0,1,2,3,4,5,6) group by 1,2,3 order by 1,2,3;

select concat(extract(YEAR from stmt_end_dt),LPAD(extract(MONTH from stmt_end_dt),2,'0')) as YYYYMM, lob, avg(fico_score) from fico 
where fico_score >= 300 and fico_score <= 850
group by 1,2 order by 1,2;*/

select
  concat(extract(YEAR from stmt_end_dt), LPAD(extract(MONTH from stmt_end_dt),2,'0')) as YYYYMM
  , lob
  , avg(fico_score) ,count (distinct acct_id), sum(curr_bal) from fico
where fico_score >= 300 and fico_score <= 850 
and lob <> 'Other' 
and cyc_pdue_bkt_num in (0,1,2,3,4,5,6) 
group by 1,2 order by 1,2;

