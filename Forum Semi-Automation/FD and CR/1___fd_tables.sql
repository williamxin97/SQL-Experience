use warehouse CARD_Q_CHANNELS;
use database Card_Db_Collab;
use schema lab_complaints_discovery;


--fd_long goes back 17 months not including the most recent month (16 total months)
--fd_short goes back 21 weeks not including the most recent week (20 total weeks)

-- They're named fd_long and fd_short, but they're not filtered for fraud and dispute just yet
-- Some analyses like to look at Walmart as a separate segment, so one column accounts for that

create or replace temporary table fd_long as (
select distinct
  a.mapped_driver_with_tbd as mapped_driver
  ,b.mapped_segment
  ,pl.*
  ,case
    when upper(pl.data_source) = 'MANUAL' then dateadd(day,-date_part(day,pl.load_date),pl.load_date)
    else pl.date_received
  end as report_date
  ,pl.cmplant_id || pl.data_source as cmplant_id2
  
from
  card_db_collab.lab_channels_complaints.cmplant_pl as pl
join card_db_collab.lab_complaints_discovery.mapped_drivers as a
  on
    trim(upper(replace(pl.primary_driver, ',', '')) || upper(replace(pl.primary_subdriver, ',' ,''))) = upper(a.concat_drivers)
    and upper(pl.tier) = upper(a.tier)
join card_db_collab.lab_complaints_discovery.mapped_segment as b
  on 
    TRIM(replace(pl.CNSMR_TYPE_DESC || Coalesce(pl.SEGMENT,'UNKNOWN'),',')) = TRIM(replace(b.CNSMR_TYPE_DESC || Coalesce(b.SEGMENT,'UNKNOWN'),','))
    and Upper(pl.Tier) = Upper(b.Tier)
where
  report_date between dateadd(month,-16,date_trunc('month',current_date)) and  dateadd(day,-1,date_trunc('month',current_date))
  --and upper(bbflag) = 'BB'
  and (pl.cmplant_case_src_catg_desc <> 'Agent' or pl.cmplant_case_src_catg_desc is null)
  and not (pl.tier = 'Tier 1'
          and trim(case when pl.cmplant_case_src_catg_desc is null then 'a' else pl.cmplant_case_src_catg_desc end) = '')
);

create or replace temporary table fd_long as (
select *
  ,date_trunc('month', report_date) as data_month
  ,case when cnsmr_type_desc ilike ('%walmart%') then 'Walmart'
          when bbflag = 'PA' then 'Partnerships'
          when mapped_segment ilike '%upmarket%' then 'Upmarket'
          when mapped_segment = 'Retail/PLCC' then 'Partnerships'
          else mapped_segment 
  end as segment_wal 
  from fd_long
);

create or replace temporary table fd_short as (
select distinct
  a.mapped_driver_with_tbd as mapped_driver
  ,b.mapped_segment
  ,pl.*
  ,case
    when upper(pl.data_source) = 'MANUAL' then dateadd(day,-date_part(day,pl.load_date),pl.load_date)
    else pl.date_received
  end as report_date
  ,pl.cmplant_id || pl.data_source as cmplant_id2
  
from
  card_db_collab.lab_channels_complaints.cmplant_pl as pl
join card_db_collab.lab_complaints_discovery.mapped_drivers as a
  on
    trim(upper(replace(pl.primary_driver, ',', '')) || upper(replace(pl.primary_subdriver, ',' ,''))) = upper(a.concat_drivers)
    and upper(pl.tier) = upper(a.tier)
join card_db_collab.lab_complaints_discovery.mapped_segment as b
  on 
    TRIM(replace(pl.CNSMR_TYPE_DESC || Coalesce(pl.SEGMENT,'UNKNOWN'),',')) = TRIM(replace(b.CNSMR_TYPE_DESC || Coalesce(b.SEGMENT,'UNKNOWN'),','))
    and Upper(pl.Tier) = Upper(b.Tier)
where
  report_date between dateadd(week,-20,date_trunc('week',current_date)) and  dateadd(day,-1,date_trunc('week',current_date))
  --and upper(bbflag) = 'BB'
  and (pl.cmplant_case_src_catg_desc <> 'Agent' or pl.cmplant_case_src_catg_desc is null)
  and not (pl.tier = 'Tier 1'
          and trim(case when pl.cmplant_case_src_catg_desc is null then 'a' else pl.cmplant_case_src_catg_desc end) = '')
);

create or replace temporary table fd_short as (
select *
  ,date_trunc('week', report_date) as data_week
  ,case when cnsmr_type_desc ilike ('%walmart%') then 'Walmart'
          when bbflag = 'PA' then 'Partnerships'
          when mapped_segment ilike '%upmarket%' then 'Upmarket'
          when mapped_segment = 'Retail/PLCC' then 'Partnerships'
          else mapped_segment 
  end as segment_wal 
  from fd_short
);

