
--mapped driver attrition rates for upmarket in 2019
-- com_m is relative to 2019-01-01, but you can use date_received as well
--this query looks at customers who complained and attrited, versus all customers who complained
select b.mapped_driver, a.att/b.total as att_rate from 
    (select mapped_driver, count(*) as att from sb.user_aik604.iac_final
    where tier = 'Tier 2' 
    and com_m between 1 and 12
    and lower(segment) like 'upmarket%'
    and com_dead_m = 1
    group by 1) a
    left join
    (select mapped_driver, count(acct_id) as total from sb.user_aik604.iac_final
    where tier = 'Tier 2' 
    and com_m between 1 and 12
    and lower(segment) like 'upmarket%'
    group by 1) b
    on a.mapped_driver = b.mapped_driver
    order by 2 desc
;