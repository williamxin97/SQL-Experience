create or replace temporary table pnr_10 as
(
SELECT
  a.arr_id_chain
  ,A.MEAS_PRD_ID AS STMT_MONTH
  ,CASE
    WHEN E.ORG_CDE IN ('226') THEN 'Active'
    WHEN E.ORG_CDE IN ('329','222','176','420','800') then 'Inactive - Powersports'
    when E.ORG_CDE IN ('856') then 'Inactive - Dressbarn'
    when E.ORG_CDE IN ('593') then 'Inactives - Furniture Row' --keep as 'Inactives'
    when E.ORG_CDE IN ('602') then 'Inactives - L&T' --keep as 'Inactives'
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
WHERE A.MEAS_PRD_ID = '202010'
  and a.meas_prd_id = '202010'
  AND E.ATH_CURR_ACCT_IND = '1'
  AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
  and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
  and E.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
  and E.ORG_CDE NOT IN ('601')--Exclude Lord and Taylor and Saks
);

create or replace temporary table pnr_11 as
(
SELECT
  a.arr_id_chain
  ,A.MEAS_PRD_ID AS STMT_MONTH
  ,CASE
    WHEN E.ORG_CDE IN ('004','005','226','601','602') THEN 'Active'
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
WHERE A.MEAS_PRD_ID = '202011'
  and a.meas_prd_id = '202011'
  AND E.ATH_CURR_ACCT_IND = '1'
  AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
  and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
  and E.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
  and E.ORG_CDE NOT IN ('601')--Exclude Lord and Taylor and Saks
);



create or replace temporary table pnr_trans as select a.*, b.bucket as bucket2, b.bal as bal2
  from pnr_10 a
  left join pnr_11 b
  on a.arr_id_chain = b.arr_id_chain;
  

select bucket, bucket2, sum(bal), sum(bal2) from pnr_trans group by 1,2 order by 1,2;
