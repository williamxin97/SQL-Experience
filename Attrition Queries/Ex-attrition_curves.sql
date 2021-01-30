
--Here is cumulative attrition rate by tier for upmarket
--Notice how the data is capped off at October. This is unnecessary for 2019 data but is necessary for newer data
-- Analyses must be capped off or else recent complaints will dilute the attrition rate. 
-- Someone who complains just yesterday will not have had time to attrite
--This data is wide data, which is necessary for Google Slides
select DEATH, T1_RATE, T2_RATE from ((select 0 as DEATH, 0 as T1_RATE, 0 as T2_RATE) union all
( select a.DEATH, a.T1_RATE, b.T2_RATE from
  (select distinct com_dead_d as DEATH, 
    (count(*) over (order by com_dead_d))/(select count(*) from sb.user_aik604.iac_final where tier = 'Tier 1' 
    and com_m between 1 and 10
    and lower(segment) like 'upmarket%') as T1_RATE from sb.user_aik604.iac_final
    where tier = 'Tier 1' 
    and com_m between 1 and 10
    and lower(segment) like 'upmarket%'
    order by 1 asc) a
left join (select distinct com_dead_d as DEATH, 
    (count(*) over (order by com_dead_d))/(select count(*) from sb.user_aik604.iac_final where tier = 'Tier 2' 
    and com_m between 1 and 10
    and lower(segment) like 'upmarket%') as T2_RATE from sb.user_aik604.iac_final
    where tier = 'Tier 2' 
    and com_m between 1 and 10
    and lower(segment) like 'upmarket%'
    order by 1 asc) b
 on a.DEATH = b.DEATH)
 )
    order by 1 asc;

--Here is the same data but in long data format
select DAY, RATE, TIER from ((select 0 as DAY, 0 as RATE, 'Tier 1' as TIER) union all
                             (select 0 as DAY, 0 as RATE, 'Tier 2' as TIER) union all
  (select distinct com_dead_d as DAY, 
    (count(*) over (order by com_dead_d))/(select count(*) from sb.user_aik604.iac_final where tier = 'Tier 1' 
    and com_m between 1 and 10
    and lower(segment) like 'upmarket%') as RATE, 'Tier 1' as TIER from sb.user_aik604.iac_final
    where tier = 'Tier 1' 
    and com_m between 1 and 10
    and lower(segment) like 'upmarket%'
    and com_dead_d <= 120
    order by 1 asc)
  union all
  (select distinct com_dead_d as DAY, 
    (count(*) over (order by com_dead_d))/(select count(*) from sb.user_aik604.iac_final where tier = 'Tier 2' 
    and com_m between 1 and 10
    and lower(segment) like 'upmarket%') as RATE, 'Tier 2' as TIER from sb.user_aik604.iac_final
    where tier = 'Tier 2' 
    and com_m between 1 and 10
    and lower(segment) like 'upmarket%'
    and com_dead_d <= 120
    order by 1 asc)
 )
order by 3,1 asc;