
create or replace temporary table whirl_full as (
SELECT
  A.MEAS_PRD_ID AS STMT_MONTH
  , a.arr_id_chain as acct
  , a.bal_eom_amt as bal
  ,CASE
    WHEN E.ORG_CDE IN ('226') THEN 'Active - Menards' --RPM1
    WHEN E.ORG_CDE IN ('329','222','176','420','800') then 'Inactive - Powersports' --RPM1
    when E.ORG_CDE IN ('856') then 'Inactive - Dressbarn' --RPM1
    when E.ORG_CDE IN ('004','005') then 'Active - Neiman and Bergdorf Goodman' --RPM2
    when E.ORG_CDE IN ('602') then 'Inactive - Lord and Taylor' --RPM2
    ELSE 'Inactive - Other' --RPM1
    END AS PARTNER_STATUS
  ,F.ORG_DESC as Partner
  ,E.ORG_CDE as ORG_CD
  ,case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as Bucket --very few accounts with stat_cde = 09 (bucket 8)
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOM A
LEFT JOIN DB.PPDW.PTNR D
ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
ON E.ORG_CDE = F.ORG_CDE
WHERE A.MEAS_PRD_ID >= '201909'
AND E.ATH_CURR_ACCT_IND = '1'
AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and E.ORG_CDE not IN ('202','855','857') -- 'Helzberg, Justice, and Maurices' --RPM2
and E.ORG_CDE not IN ('601') -- 'Saks' --RPM2
and E.ORG_CDE not IN ('004','005') --NMG
and bucket <= 6
and BAL_EOM_AMT > 0
);


create or replace temporary table whirl_now as (
SELECT
  A.MEAS_PRD_ID AS STMT_MONTH
  , a.arr_id_chain as acct
  , a.bal_eom_amt as bal
  ,CASE
    WHEN E.ORG_CDE IN ('226') THEN 'Active - Menards' --RPM1
    WHEN E.ORG_CDE IN ('329','222','176','420','800') then 'Inactive - Powersports' --RPM1
    when E.ORG_CDE IN ('856') then 'Inactive - Dressbarn' --RPM1
    when E.ORG_CDE IN ('004','005') then 'Active - Neiman and Bergdorf Goodman' --RPM2
    when E.ORG_CDE IN ('602') then 'Inactive - Lord and Taylor' --RPM2
    ELSE 'Inactive - Other' --RPM1
    END AS PARTNER_STATUS
  ,F.ORG_DESC as Partner
  ,E.ORG_CDE as ORG_CD
  ,case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as Bucket
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOm A
LEFT JOIN DB.PPDW.PTNR D
ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
ON E.ORG_CDE = F.ORG_CDE
WHERE A.MEAS_PRD_ID = '202009'
AND E.ATH_CURR_ACCT_IND = '1'
AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and E.ORG_CDE not IN ('202','855','857') -- 'Helzberg, Justice, and Maurices' --RPM2
and E.ORG_CDE not IN ('601') -- 'Saks' --RPM2
and E.ORG_CDE not IN ('004','005') --NMG
and bal_eom_amt > 0
and bucket <= 6
);

select * from whirl_now limit 100;

create or replace temporary table whirl_more_header as (
  select 
  b.stmt_month, a.* from
  (select distinct acct, partner_status, partner, org_cd from whirl_now) a
  left join (select distinct stmt_month from whirl_full) b
);
select * from whirl_more_header limit 10;
select * from whirl_full limit 10;


create or replace temporary table whirl_more as (
select
  coalesce(b.stmt_month, a.stmt_month) as stmt_month
  , coalesce( b.acct, a.acct) as acct
  , coalesce(b.bal, 0) as bal
  , coalesce(b.partner_status, a.partner_status) as partner_status
  , coalesce(b.partner, a.partner) as partner
  , coalesce(b.org_cd, a.org_cd) as org_cd
  , coalesce(b.bucket, 0) as bucket
  from whirl_more_header a
  full outer join whirl_full b
  on a.stmt_month = b.stmt_month
    and a.acct = b.acct
);

select stmt_month, partner_status, partner, org_cd, bucket, count(distinct acct) as accts, sum(bal) as total_Bal
from whirl_more
where stmt_month >= '202004'
group by 1,2,3,4,5 order by 1,2,3,4,5;
