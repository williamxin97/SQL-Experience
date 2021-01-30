--These sets of queries will output a pivot table that shows partner volume by month for tier 2 partner complaints

--create long data view of partner volume by month, for the past 14 months (excluding the current month)

select date_trunc('month', date_received) as data_month
    ,concat(b.mth_abrv_nm,'-',substring(b.yr_num,3,2)) as month
    ,case when cnsmr_type_desc ilike '%bass%' then 'BassCab'
        when cnsmr_type_desc ilike '%cabela%' then 'BassCab'
        when cnsmr_type_desc ilike '%gm%' then 'GM'
        when cnsmr_type_desc in ('UP', 'UP Disaffiliated') then 'Union Plus'
        when cnsmr_type_desc ilike '%union%' then 'Union Plus'
        when cnsmr_type_desc ilike '%lord%' then 'Lord and Taylor'
        when cnsmr_type_desc ilike '%menards%' then 'Menards'
        when cnsmr_type_desc ilike '%sony%' then 'Sony'
        when cnsmr_type_desc ilike '%saks%' then 'Saks'
        when cnsmr_type_desc ilike '%kohl%' then 'Kohls'
        else 'Other' end as partner
    , count(*) as partner_volume
    
    from card_db_collab.lab_channels_complaints.cmplant_pl pl
    left join db.POPS.DATE_DIM b
    on pl.date_received = b.data_dt
    
    where bbflag = 'PA' 
    and date_received between dateadd(month,-13,date_trunc('month',current_date)) and  dateadd(day,-1,date_trunc('month',current_date))
    and tier = 'Tier 2'
    and cnsmr_type_desc not ilike ('%walmart%')
    group by 1,2,3
    order by 1 asc
;

        
