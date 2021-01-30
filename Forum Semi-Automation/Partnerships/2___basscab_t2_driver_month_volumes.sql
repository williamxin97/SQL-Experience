
--create long data view of mapped driver volume by month, for the past 6 months (excluding the current month)

SELECT
    date_trunc('MONTH', pl.date_received) as data_month
    , concat(b.mth_abrv_nm,'-',substring(b.yr_num,3,2)) as month
    , case when discovery.MAPPED_DRIVER ilike 'Fraud' or discovery.MAPPED_DRIVER ilike 'Disputes' then 'Fraud & Disputes'
    else discovery.mapped_driver end as mapped_driver 
    , count(pl.cmplant_id || pl.data_source) as mapped_driver_volume
  FROM card_db_collab.lab_channels_complaints.cmplant_pl pl
   LEFT OUTER  JOIN card_db_collab.lab_complaints_discovery.mapped_drivers AS discovery
  	ON trim(upper(replace(pl.primary_driver, ',', '')) || upper(replace(pl.PRIMARY_SUBDRIVER, ',' ,''))) = upper(discovery.concat_drivers)
  	AND upper(pl.tier) = upper(discovery.tier)
   left join db.POPS.DATE_DIM b
    on pl.date_received = b.data_dt 
  WHERE pl.tier = 'Tier 2'
  AND   pl.BBflag = 'PA'
  AND   (pl.CNSMR_TYPE_DESC ilike '%Cabela%' OR pl.CNSMR_TYPE_DESC ilike '%Bass%')
  AND pl.date_received between dateadd(month,-6,date_trunc('month',current_date)) and  dateadd(day,-1,date_trunc('month',current_date))
  group by 3,1,2
  ORDER BY 2 asc;




