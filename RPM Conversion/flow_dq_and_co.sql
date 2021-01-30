--Omega COs
select concat(extract(YEAR from charge_off_date),LPAD(extract(MONTH from charge_off_date),2,'0')) as YYYYMM,
CASE
WHEN ORG_CDE IN ('004','005','226','601','602') THEN 'Active'
WHEN ORG_CDE IN ('329','222','176','420','800') then 'Inactive - Powersports'
when ORG_CDE IN ('856') then 'Inactive - Dressbarn'
ELSE 'Inactive - Other' END AS PARTNER_STATUS,
sum(chargeoffbalance)
from card_db.phdp_card.rcvry_acct_srvc_account as a
inner join card_db.phdp_card.rcvry_trxn_srvc_journal as b
on a.account_id = b.account_id and a.snap_dt=b.snap_dt and a.snap_dt=current_date-1  and b.snap_dt = current_date-1
join db.ppdw_credit.ARR_SNAP_LOW_PT c
on a.previous_account_id = c.arr_id_chain
and ATH_CURR_ACCT_IND = 1
and a.charge_off_date = c.snap_dt
where ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
and ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
and ORG_CDE NOT IN ('601', '602')--Exclude Lord and Taylor and Saks
and charge_off_date between '2019-01-01' and '2020-05-31'
group by 1,2
order by 1,2;

--Monthly Inventory and Flow Rates
SELECT
A.MEAS_PRD_ID AS STMT_MONTH,
CASE
WHEN E.ORG_CDE IN ('004','005','226','601','602') THEN 'Active'
WHEN E.ORG_CDE IN ('329','222','176','420','800') then 'Inactive - Powersports'
when E.ORG_CDE IN ('856') then 'Inactive - Dressbarn'
ELSE 'Inactive - Other' END AS PARTNER_STATUS,
F.ORG_DESC as Partner,
E.ORG_CDE as ORG_CD,
case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as Bucket, --very few accounts with stat_cde = 09 (bucket 8)
count (distinct A.ARR_ID_CHAIN) as num_accts,
sum (A.BAL_EOC_AMT) as total_bal
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
LEFT JOIN DB.PPDW.PTNR D
ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
ON E.ORG_CDE = F.ORG_CDE
WHERE A.MEAS_PRD_ID >= '201908'
AND E.ATH_CURR_ACCT_IND = '1'
AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
and E.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
and E.ORG_CDE NOT IN ('601', '602')--Exclude Lord and Taylor and Saks
group by 1,2,3,4,5 order by 1,2,3,4,5;

--MS, UM, WMT Inventory for Flow rates and DQ rates
select concat(extract(YEAR from stmt_end_dt),LPAD(extract(MONTH from stmt_end_dt),2,'0')) as YYYYMM,
CASE
WHEN svc_ownr_cd IN ('000010','000011', '000051', '000088','000086','000090','000091') THEN 'US Card Mainstreet'
WHEN svc_ownr_cd IN ('000022','000023', '000052', '000087', '000089') THEN 'US Card Upmarket'
--WHEN svc_ownr_cd IN ('000114','000115','000116','000117') THEN 'Walmart PLCC'
--WHEN svc_ownr_cd IN ('000118','000119','000120','000121') THEN 'Walmart Cobrand'
WHEN svc_ownr_cd IN ('000114','000115','000116','000117','000118','000119','000120','000121') THEN 'Walmart'
end as lob,
cyc_pdue_bkt_num,
count(distinct acct_id), sum(curr_bal)
from db.pcdw.t2_stmt
where cyc_pdue_bkt_num in ('00','01','02','03','04','05','06','07')
and stmt_end_dt >= '2019-8-01'
and svc_ownr_cd in ('000010','000011', '000051', '000088','000086','000090','000091','000022','000023', '000052', '000087', '000089',
'000114','000115','000116','000117','000118','000119','000120','000121')
and chrgof_cd is null
and acct_sfx_num = 0
group by 1,2,3
order by 1,2,3;


SELECT
  A.MEAS_PRD_ID AS STMT_MONTH
  ,CASE
    WHEN E.ORG_CDE IN ('004','005','226','601','602') THEN 'Active - Menards' --RPM1
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
