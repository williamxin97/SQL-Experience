--Create the base table

set (start_date,end_date)=('2018-01-01','2020-05-31');

create or replace temporary table sbc_complaints as (
  select
  discovery.mapped_driver_with_tbd as mapped_driver, 
  pl.*,
  case when upper(pl.data_source) = 'MANUAL' then dateadd(day,-date_part(day,pl.load_date),pl.load_date) 
    else pl.date_received end as report_date,
  pl.cmplant_id || pl.data_source as cmplant_id2  --for distinct complaint counting
  
  from card_db_collab.lab_channels_complaints.cmplant_pl as pl
  join card_db_collab.lab_complaints_discovery.mapped_drivers as discovery
  
  on trim(upper(replace(pl.primary_driver, ',', '')) || upper(replace(pl.primary_subdriver, ',' ,''))) = upper(discovery.concat_drivers) and upper(pl.tier) = upper(discovery.tier)
  where report_date between $start_date and $end_date
  and upper(pl.segment) = 'SMALL BUSINESS'
  and (pl.cmplant_case_src_catg_desc <> 'Agent' or pl.cmplant_case_src_catg_desc is null)
  and not (pl.tier = 'Tier 1' and trim(case when pl.cmplant_case_src_catg_desc is null then 'a' else pl.cmplant_case_src_catg_desc end) = '')
);

--Complaint and Inquiry Counts by tier by month since Jan2019
select
  tier,
  extract(year from date_received) as complaint_year,
  extract(month from date_received) as complaint_month,
  count(distinct cmplant_id2) as cnt
from sbc_complaints
where report_date >= '2019-01-01'
group by 1,2,3 order by 1,2,3;

--2020 Annual Membership Fee complaint detail from new customers around 1 year anniversary
select
  cmplant_cmnt_txt, acct_id, agent_eid, acct_age, report_date
from sbc_complaints
where tier in ('Tier 2', ‘Tier 3’)
and primary_driver = 'Fees and Interest Charges'
and primary_subdriver = 'Membership Fees'
and acct_age between 330 and 400
and report_date >= ‘2020-01-01’
order by 5;


--Month over month complaint mapped driver comparison (Apr20 vs May20)
select
  tier,
  mapped_driver,
  extract(year from report_date) as complaint_year,
  extract(month from report_date) as complaint_month,
  count(distinct cmplant_id2) as cnt
from sbc_complaints
where report_date >= '2020-04-01'
group by 1,2,3,4 order by 1,2,3,4;


--Corona-virus related Tier 3 complaints in May20
select *
from sbc_complaints
where tier = ‘Tier 3’
and (upper(cmplant_cmnt_txt) like '%CORONA%'
  or upper(cmplant_cmnt_txt) like '%COVID%'
  or upper(cmplant_cmnt_txt) like '%VIRUS%'
  or upper(cmplant_cmnt_txt) like '%EPIDEMIC%'
  or upper(cmplant_cmnt_txt) like '%PANDEMIC%')
  and not(upper(cmplant_cmnt_txt) like '%ANTIVIRUS%'
  or upper(cmplant_cmnt_txt) like '%ANTI VIRUS%')
order by report_date;


--LOB filtering…
-- segment = ‘Small Business’
-- segment in(‘Upmarket Lenders’,’Upmarket Spenders’)
-- segment = ‘Mainstreet’
-- upper(cnsmr_type_desc) ilike (‘%WALMART%’)
