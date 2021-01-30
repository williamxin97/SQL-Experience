create or replace table temp_cd as (
SELECT
  a.arr_id_chain
  ,A.MEAS_PRD_ID AS STMT_MONTH
  ,CASE
    WHEN E.ORG_CDE IN ('226','601') THEN 'Active'
    WHEN E.ORG_CDE IN ('329','222','176','420','800') then 'Inactive - Powersports'
    when E.ORG_CDE IN ('856') then 'Inactive - Dressbarn'
    when E.ORG_CDE IN ('593') then 'Inactives - Furniture Row' --keep as 'Inactives'
    ELSE 'Inactive - Other' END AS PARTNER_STATUS
  ,F.ORG_DESC as Partner
  ,E.ORG_CDE as ORG_CD
  ,case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as Bucket --very few accounts with stat_cde = 09 (bucket 8)
  , bal_eoc_amt as bal
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
LEFT JOIN DB.PPDW.PTNR D
  ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
  ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
  ON E.ORG_CDE = F.ORG_CDE
left join db.ppdw_credit.arr_perfm_snap_eom cd
  on a.arr_id_chain = cd.arr_id_chain
  and a.meas_prd_id = cd.meas_prd_id
WHERE A.MEAS_PRD_ID >= '201901'
  AND E.ATH_CURR_ACCT_IND = '1'
  AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
  and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
  and E.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
  and E.ORG_CDE NOT IN ('601')--Exclude Lord and Taylor and Saks
  and cd.cease_desist_cde in ('AT','CD','PA')
);



create or replace table cd_trans as select a.*, b.stmt_month as month2, b.bucket as bucket2, b.bal as bal2
  from temp_cd a
  left join temp_cd b
  on a.arr_id_chain = b.arr_id_chain
  and a.stmt_month = b.stmt_month - 1
  and (a.stmt_month = b.stmt_month - 1 or a.stmt_month = b.stmt_month - 89)
  where a.stmt_month >= '201901'
  and month2 is not null;
  

/*select stmt_month, month2, bucket
  , case when bucket2 is null then 100 else bucket2 end as bucket2
  , sum(bal), sum(bal2) from cd_trans 
  where (bucket2 is null or (bucket2 - bucket)<=1)
  and month2 is not null
  group by 1,2,3,4 order by 1,2,3,4;*/
  
select bucket
  , case when bucket2 is null then 100 else bucket2 end as bucket2
  , sum(bal), sum(bal2) from cd_trans 
  where (bucket2 is null or (bucket2 - bucket)<=1)
  and month2 is not null
  group by 1,2 order by 1,2;

select * from
(select stmt_month, bucket
  , sum(bal) as bals from cd_trans 
  where bucket2 is null or (bucket2 - bucket)<=1
  group by 1,2 order by 1,2)
pivot (sum(bals) for bucket in (0,1,2,3,4,5,6,7))
order by stmt_month asc;

create or replace temporary table temp_non_cd as (
SELECT
  a.arr_id_chain
  ,A.MEAS_PRD_ID AS STMT_MONTH
  ,CASE
    WHEN E.ORG_CDE IN ('226','601') THEN 'Active'
    WHEN E.ORG_CDE IN ('329','222','176','420','800') then 'Inactive - Powersports'
    when E.ORG_CDE IN ('856') then 'Inactive - Dressbarn'
    when E.ORG_CDE IN ('593') then 'Inactives - Furniture Row' --keep as 'Inactives'
    ELSE 'Inactive - Other' END AS PARTNER_STATUS
  ,F.ORG_DESC as Partner
  ,E.ORG_CDE as ORG_CD
  ,case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as Bucket --very few accounts with stat_cde = 09 (bucket 8)
  , bal_eoc_amt as bal
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
LEFT JOIN DB.PPDW.PTNR D
  ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
  ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
  ON E.ORG_CDE = F.ORG_CDE
left join db.ppdw_credit.arr_perfm_snap_eom cd
  on a.arr_id_chain = cd.arr_id_chain
  and a.meas_prd_id = cd.meas_prd_id
WHERE A.MEAS_PRD_ID >= '201901'
  AND E.ATH_CURR_ACCT_IND = '1'
  AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
  and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
  and E.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
  and E.ORG_CDE NOT IN ('601')--Exclude Lord and Taylor and Saks
);


create or replace temporary table non_cd_sample as select distinct arr_id_chain from temp_non_cd limit 1000000;

create or replace temporary table non_cd_trans as select a.*, b.stmt_month as month2, b.bucket as bucket2, b.bal as bal2
  from temp_non_cd a
  left join temp_non_cd b
  on a.arr_id_chain = b.arr_id_chain
  and (a.stmt_month = b.stmt_month - 1 or a.stmt_month = b.stmt_month - 89)
  where a.stmt_month >= '201901'
  and month2 is not null
  and a.arr_id_chain in (select arr_id_chain from non_cd_sample);
  

/*select stmt_month, month2, bucket
  , case when bucket2 is null then 100 else bucket2 end as bucket2
  , sum(bal), sum(bal2) from non_cd_trans 
  where (bucket2 is null or (bucket2 - bucket)<=1)
  and month2 is not null
  group by 1,2,3,4 order by 1,2,3,4;*/

select bucket
  , case when bucket2 is null then 100 else bucket2 end as bucket2
  , sum(bal), sum(bal2) from non_cd_trans 
  where (bucket2 is null or (bucket2 - bucket)<=1)
  and month2 is not null
  group by 1,2 order by 1,2;
    
select * from
(select stmt_month, bucket
  , sum(bal) as bals from non_cd_trans 
  where bucket2 is null or (bucket2 - bucket)<=1
  group by 1,2 order by 1,2)
pivot (sum(bals) for bucket in (0,1,2,3,4,5,6,7))
order by stmt_month asc;
