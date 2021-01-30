

--Pull out all data

select full_month, month, tier, mapped_driver, count(distinct cmplant_id2) as cnt
    from sb_complaints 
    where full_month between dateadd(month,-2,date_trunc('month',current_date)) and dateadd(month,-1,date_trunc('month',current_date))
    group by 1,2,3,4 order by 3,4,1 asc
;

