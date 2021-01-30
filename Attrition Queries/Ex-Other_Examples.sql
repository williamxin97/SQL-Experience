--Preceding 3 months of spend of tier 2 mainstreet complaints in the first 6 months of 2019
select mapped_driver, primary_subdriver, sum(spend_3), count(acct_id) 
  from sb.user_aik604.iac_final
  where tier = 'Tier 2'
  and date_received between '2019-01-01' and '2019-06-30'
  and segment = 'Mainstreet'
  group by 1,2 order by 1,2 asc;
  
  
--Preceding 3 months of spend of tier 2 mainstreet complaints in the first 6 months of 2019, where the account was closed within a month of complaining
select mapped_driver, primary_subdriver, sum(spend_3), count(acct_id) 
  from sb.user_aik604.iac_final
  where tier = 'Tier 2'
  and date_received between '2019-01-01' and '2019-06-30'
  and segment = 'Mainstreet'
  and com_dead_m = 1
  group by 1,2 order by 1,2 asc;
