create or replace temporary table whirl_buckets as (
SELECT
  a.arr_id_chain
  ,a.bal_eoc_amt
  ,A.MEAS_PRD_ID AS STMT_MONTH
  , case 
      when A.MEAS_PRD_ID like '%2018%' then '2018' 
      when A.MEAS_PRD_ID like '%2019%' then '2019'
      when A.MEAS_PRD_ID like '%2020%' then '2020'
      end as year
  ,F.ORG_DESC as Partner
  ,E.ORG_CDE as ORG_CD
  ,case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as Bucket --very few accounts with stat_cde = 09 (bucket 8)
FROM DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC A
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
  ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
LEFT JOIN DB.PPDW.ORG_CDE F
  ON E.ORG_CDE = F.ORG_CDE
WHERE A.MEAS_PRD_ID >= '201801'
  AND E.ATH_CURR_ACCT_IND = '1'
  AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
);

select count(distinct arr_id_chain) from whirl_buckets 
  where year = '2018' 
  and bucket <> 0;

select count(distinct arr_id_chain) from whirl_buckets 
  where year = '2019' 
  and bucket <> 0;

select count(distinct arr_id_chain) from whirl_buckets 
  where year = '2020' 
  and bucket <> 0;
