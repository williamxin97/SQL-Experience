(select
  full_month
  ,month
  ,tier
  ,case 
    when upper(cmplant_case_src_desc) = 'CFPB' then 'CFPB'
    when upper(CMPLANT_CASE_SRC_CATG_DESC) like 'EXECUTIVE%' then 'Executive Outreach'
    else 'Other Agency' end as mapped_source
  ,count(distinct cmplant_id2) as cnt
  from sb_complaints
  where tier = 'Tier 3'
  group by 1,2,3,4 order by 1,2,3,4)
  
union all 
  
(select
  full_month
  ,month
  ,tier
  ,case 
    when upper(data_source) = 'IRIS_CALL' then 'IRIS Call'
    when upper(data_source) = 'MANUAL' then 'Manual'
    when upper(data_source) = 'CHORDIANT' then 'Case'
    when upper(data_source) = 'IRIS_CASE' then 'Case'
    when upper(data_source) = 'OMNIUS' then 'Case'
    else 'Other' end as mapped_source
  ,count(distinct cmplant_id2) as cnt
  from sb_complaints
  where tier = 'Tier 2'
  group by 1,2,3,4 order by 1,2,3,4)

union all

(select
  full_month
  ,month
  ,tier
  ,case
    when upper(data_source) = 'MANUAL' then 'Manual'
    when upper(data_source) = 'IRIS_CALL' then 'IRIS Call'
    when upper(data_source) like 'T1%' then 'Inquiry Model'
    else 'Other' end as mapped_source
  ,count(distinct cmplant_id2) as cnt
  from sb_complaints
  where tier = 'Tier 1'
  group by 1,2,3,4 order by 1,2,3,4);
