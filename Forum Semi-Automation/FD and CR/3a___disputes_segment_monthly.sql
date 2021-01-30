set mapped_d = 'Disputes';

--The data will show segment, month, tier, and quantity of complaints for each tier


select date_trunc('Month', report_date) as yr_mo
    ,concat(b.mth_abrv_nm,'-',substring(b.yr_num,3,2)) as month
    ,case when segment_wal not in ('Walmart', 'Upmarket', 'Mainstreet','Partnerships','Small Business') then 'Undetermined'
        else segment_wal end as segment
    ,tier
    ,count(*) as qty 
    from fd_long a
    left join db.POPS.DATE_DIM b
        on a.report_date = b.data_dt
    where mapped_driver = $mapped_d
    group by 1,2,3,4
    order by 4 asc,1 asc
; 

