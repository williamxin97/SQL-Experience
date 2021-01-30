--The case when statement for "segment_wal" is sequentially evaluated: The first expression that evaluates TRUE is used
-- That's why the 'Walmart' case needs to be written before the 'Partnerships' case
--Two date fields are included: the first for sortability and the second for readability


select 
      date_trunc('MONTH',report_date) as yr_mo
      ,concat(b.mth_abrv_nm,'-',substring(b.yr_num,3,2)) as month
      ,case when cnsmr_type_desc ilike ('%walmart%') then 'Walmart'
          when bbflag = 'PA' then 'Partnerships'
          when mapped_segment ilike '%upmarket%' then 'Upmarket'
          when mapped_segment = 'Retail/PLCC' then 'Partnerships'
          else mapped_segment end as segment_wal
      ,tier
      ,count(distinct cmplant_id || data_source) as qty 
    from w_CR_COMPLAINTS a
    left join db.POPS.DATE_DIM b
        on a.report_date = b.data_dt
    where rlike(feedback_type,'Customer.+|Complaint','i') 
    group by 1,2,3,4
    order by 4 asc, 1 asc
;

