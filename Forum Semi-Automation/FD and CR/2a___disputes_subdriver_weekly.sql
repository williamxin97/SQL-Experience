set mapped_d = 'Disputes';

-- To change the the number of subdrivers, change the numbers in part 1a, 1c,
-- At the moment there are 5 subdrivers, and 1 "Other" subdriver for a total of 6.

--1. Find top primary_subdrivers. 
-- In the end there will be 5 subdrivers and 1 'Other' subdriver.
-- "5" is chosen because the 6th most common subdriver is "NA"

create or replace temporary table top_psd as select primary_subdriver, row_number() over (order by qty desc) as rank from
  (select primary_subdriver, count(*) as qty from fd_short 
    where tier = 'Tier 2'
    and mapped_driver = $mapped_d
    group by 1 order by 2 desc limit 5
  );
  
create or replace temporary table psd_table as select *,
    case when primary_subdriver in (select primary_subdriver from top_psd) then primary_subdriver 
    else 'Other'
    end as p_subdriver
    from fd_short
    where tier = 'Tier 2'
    and mapped_driver = $mapped_d;

 
--2. Get data

--Aggregate volumes before pivoting
-- Also joins tier 1 volumes

create or replace temporary table temp_data as
  (select date_trunc('week',report_date) as week
    , p_subdriver
    , count(distinct cmplant_id) as driver_volume
    from psd_table group by 1,2
  )  
  union all
  
  (select date_trunc('week',report_date) as week
    , 'Tier 1' as p_subdriver
    , count(distinct cmplant_id) as driver_volume
    from fd_short
    where tier = 'Tier 1'
    and mapped_driver = $mapped_d 
    group by 1)
;


select 
	week
	, concat(b.day_of_mth_num, '-', b.mth_abrv_nm) as short_week
	, p_subdriver
	, driver_volume
  from temp_data a
  left join db.POPS.DATE_DIM b
  on a.week = b.data_dt
  order by 1 asc;

