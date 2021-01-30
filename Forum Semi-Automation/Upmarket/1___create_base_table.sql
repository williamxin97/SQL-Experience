use warehouse CARD_Q_CHANNELS;
use database Card_Db_Collab;
use schema lab_complaints_discovery;


-- past 26 months of data excluding current month (25 months total: ex: 01/01/2018 - 01/31/2020 if current date is 02/05/2020)

create or replace temporary table um_complaints as (
    select
        discovery.mapped_driver_with_tbd as mapped_driver 
        ,pl.*
        ,case 
            when upper(pl.data_source) = 'MANUAL' then dateadd(day,-date_part(day,pl.load_date),pl.load_date) 
	    else pl.date_received 
	    end as report_date
	,pl.cmplant_id || pl.data_source as cmplant_id2
	from card_db_collab.lab_channels_complaints.cmplant_pl as pl
    join card_db_collab.lab_complaints_discovery.mapped_drivers as discovery
        on trim(upper(replace(pl.primary_driver, ',', '')) || upper(replace(pl.primary_subdriver, ',' ,''))) = upper(discovery.concat_drivers) and upper(pl.tier) = upper(discovery.tier)
    where report_date BETWEEN dateadd(month,-25,date_trunc('month',current_date)) AND dateadd(day,-1,date_trunc('month',current_date))
    and (pl.segment) in('Upmarket Lenders','Upmarket Spenders')
    and upper(bbflag) = 'BB'
    and (pl.cmplant_case_src_catg_desc <> 'Agent' or pl.cmplant_case_src_catg_desc is null)
    and not (pl.tier = 'Tier 1' and trim(case when pl.cmplant_case_src_catg_desc is null then 'a' else pl.cmplant_case_src_catg_desc end) = '')
);

-- Get better date formatting
create or replace temporary table um_complaints as (
    select a.*
    	, date_trunc('Month', report_date) as full_month
	, concat(b.mth_abrv_nm,'-',substring(b.yr_num,3,2)) as month
    from um_complaints a
    left join db.POPS.DATE_DIM b
    on a.report_date = b.data_dt
);
