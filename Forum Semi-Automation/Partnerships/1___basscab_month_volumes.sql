--pull T3 volume by month for Basscab/Cabelas

SELECT 
         date_trunc('MONTH',a.data_dt) as yr_mo,
	 concat(a.mth_abrv_nm,'-',substring(a.yr_num,3,2)) as month,
         count(pl.cmplant_id || pl.data_source) as T3_volume
from db.POPS.DATE_DIM a
left join card_db_collab.lab_channels_complaints.cmplant_pl pl
    on a.data_dt = pl.date_received
AND tier = 'Tier 3'
AND   BBflag = 'PA'
AND   (CNSMR_TYPE_DESC ilike '%Cabela%' OR CNSMR_TYPE_DESC ilike '%Bass%')
JOIN card_db_collab.lab_complaints_discovery.mapped_drivers AS discovery
	ON trim(upper(replace(pl.primary_driver, ',', '')) || upper(replace(pl.PRIMARY_SUBDRIVER, ',' ,''))) = upper(discovery.concat_drivers)
	AND upper(pl.tier) = upper(discovery.tier)
where   a.data_dt BETWEEN dateadd(month,-13,date_trunc('month',current_date)) AND dateadd(day,-1,date_trunc('month',current_date))
GROUP BY 1,2
order by 1 asc;

--pull T2 volume by month for Basscab/Cabelas, split out by partner

SELECT 
         date_trunc('MONTH',a.data_dt) as yr_mo,
	 concat(a.mth_abrv_nm,'-',substring(a.yr_num,3,2)) as month,
         count(pl.cmplant_id || pl.data_source) as T2_volume
from db.POPS.DATE_DIM a
left join card_db_collab.lab_channels_complaints.cmplant_pl pl
    on a.data_dt = pl.date_received
AND tier = 'Tier 2'
AND   BBflag = 'PA'
AND   (CNSMR_TYPE_DESC ilike '%Cabela%' OR CNSMR_TYPE_DESC ilike '%Bass%')
JOIN card_db_collab.lab_complaints_discovery.mapped_drivers AS discovery
	ON trim(upper(replace(pl.primary_driver, ',', '')) || upper(replace(pl.PRIMARY_SUBDRIVER, ',' ,''))) = upper(discovery.concat_drivers)
	AND upper(pl.tier) = upper(discovery.tier)
where   a.data_dt BETWEEN dateadd(month,-13,date_trunc('month',current_date)) AND dateadd(day,-1,date_trunc('month',current_date))
GROUP BY 1,2
order by 1 asc;
