SELECT
  A.MEAS_PRD_ID AS STMT_MONTH
  ,CASE
    WHEN E.ORG_CDE IN ('226') THEN 'Active - Menards' --RPM1
    WHEN E.ORG_CDE IN ('329','222','176','420','800') then 'Inactive - Powersports' --RPM1
    when E.ORG_CDE IN ('856') then 'Inactive - Dressbarn' --RPM1
    when E.ORG_CDE IN ('202','855','857') then 'Helzberg, Justice, and Maurices' --RPM2
    when E.ORG_CDE IN ('004','005') then 'Neiman and Bergdorf Goodman' --RPM2
    when E.ORG_CDE IN ('601', '602') then 'Lord and Taylor and Saks' --RPM2
    ELSE 'Inactive - Other' --RPM1
    END AS PARTNER_STATUS
  ,F.ORG_DESC as Partner
  ,E.ORG_CDE as ORG_CD
  ,case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as Bucket --very few accounts with stat_cde = 09 (bucket 8)
 ,count (distinct A.ARR_ID_CHAIN) as num_accts
 ,sum (A.BAL_EOC_AMT) as total_bal
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
LEFT JOIN DB.PPDW.PTNR D
ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
ON E.ORG_CDE = F.ORG_CDE
WHERE A.MEAS_PRD_ID >= '201901'
AND E.ATH_CURR_ACCT_IND = '1'
AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
group by 1,2,3,4,5 order by 1,2,3,4,5;
