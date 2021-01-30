select 
  concat(extract(YEAR from stmt_end_dt), LPAD(extract(MONTH from stmt_end_dt),2,'0')) as YYYYMM
  --,case
  --  WHEN svc_ownr_cd IN ('000010','000011', '000051', '000088','000086','000090','000091') THEN 'Mainstreet (US Card)'    
  --  WHEN svc_ownr_cd IN ('000022','000023', '000052', '000087', '000089') THEN 'Upmarket (US Card)'    
  --  when svc_ownr_cd in ('000114','000115','000118','000119','000120','000121') then 'Walmart'
    --when a.svc_ownr_cd in ('000114','000115') then 'Walmart PLCC'
    --when a.svc_ownr_cd in ('000118','000119','000120','000121') then 'Walmart Cobrand'
  --  else 'Other'   
  --end as lob
  , cyc_pdue_bkt_num as bucket
  , sum(curr_bal)  
  , count(distinct acct_id)
    
from db.pcdw.t2_stmt
where stmt_end_dt >= '2019-09-01'
and acct_sfx_num = 0
and bucket in (0,1,2,3,4,5,6,7)
and svc_ownr_cd IN ('000010','000011', '000051', '000088','000086','000090','000091','000022','000023', '000052', '000087', '000089')
group by 1,2 order by 1,2;
