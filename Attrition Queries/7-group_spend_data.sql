
--we want to find trailing and forward one month, three month, and one year spend totals
create or replace table sb.user_aik604.iac_spend as (
  select *, 
  cast(datediff(day, date_received, trxn_dt) as float)/(31) as trxn_age_1, 
  cast(datediff(day, date_received, trxn_dt) as float)/(92) as trxn_age_3,
  cast(datediff(day, date_received, trxn_dt) as float)/(365) as trxn_age_12
  from sb.user_aik604.iac_spend
);


update sb.user_aik604.iac_spend
set trxn_age_1 = case
    when trxn_age_1 > 0 then ceil(trxn_age_1)
    when trxn_age_1 < 0 then floor(trxn_age_1)
    when trxn_age_1 = 0 then -1
    else trxn_age_1 end;
update sb.user_aik604.iac_spend
set trxn_age_3 = case
    when trxn_age_3 > 0 then ceil(trxn_age_3)
    when trxn_age_3 < 0 then floor(trxn_age_3)
    when trxn_age_3 = 0 then -1
    else trxn_age_3 end;

update sb.user_aik604.iac_spend
set trxn_age_12 = case
    when trxn_age_12 > 0 then ceil(trxn_age_12)
    when trxn_age_12 < 0 then floor(trxn_age_12)
    when trxn_age_12 = 0 then -1
    else trxn_age_12 end;


create or replace table sb.user_aik604.iac_spend_12 as(
  select acct_id, trxn_age_12, primary_driver, primary_subdriver, tier, sum(trxn_amt) as spend_12, date_received, mapped_driver
  from sb.user_aik604.iac_spend
  where trxn_age_12 between -1 and 1
  and (trxn_dt <= cls_dt or cls_dt is null)
  group by 2,5, 3,4,1,7,8
  order by 2,5,3,4,1,7,8
);

create or replace table sb.user_aik604.iac_spend_3 as(
  select acct_id, trxn_age_3, primary_driver, primary_subdriver, tier, sum(trxn_amt) as spend_3, date_received, mapped_driver
  from sb.user_aik604.iac_spend
  where trxn_age_3 between -1 and 1
  and (trxn_dt <= cls_dt or cls_dt is null)
  group by 2,5, 3,4,1,7,8
  order by 2,5,3,4,1,7,8
);

create or replace table sb.user_aik604.iac_spend_1 as(
  select acct_id, trxn_age_1, primary_driver, primary_subdriver, tier, sum(trxn_amt) as spend_1, date_received, mapped_driver
  from sb.user_aik604.iac_spend
  where trxn_age_1 between -1 and 1
  and (trxn_dt <= cls_dt or cls_dt is null)
  group by 2,5, 3,4,1,7,8
  order by 2,5,3,4,1,7,8
);


create or replace table sb.user_aik604.iac_final as(
  select distinct x.*, a.spend_12, b.spend_3, c.spend_1, d.spend_12 as spend_12f, e.spend_3 as spend_3f, f.spend_1 as spend_1f
  from sb.user_aik604.iac_data x
  left join (select * from sb.user_aik604.iac_spend_12 where trxn_age_12 = -1) a
  on x.acct_id = a.acct_id
  and x.date_received = a.date_received
  and x.tier = a.tier
  and x.mapped_driver = a.mapped_driver
  and x.primary_subdriver = a.primary_subdriver
  left join (select * from sb.user_aik604.iac_spend_3 where trxn_age_3 = -1) b
  on x.acct_id = b.acct_id
  and x.date_received = b.date_received
  and x.tier = b.tier
  and x.mapped_driver = b.mapped_driver
  and x.primary_subdriver = b.primary_subdriver
  left join (select * from sb.user_aik604.iac_spend_1 where trxn_age_1 = -1) c
  on x.acct_id = c.acct_id
  and x.date_received = c.date_received
  and x.tier = c.tier
  and x.mapped_driver = c.mapped_driver
  and x.primary_subdriver = c.primary_subdriver
  left join (select * from sb.user_aik604.iac_spend_12 where trxn_age_12 = 1) d
  on x.acct_id = d.acct_id
  and x.date_received = d.date_received
  and x.tier = d.tier
  and x.mapped_driver = d.mapped_driver
  and x.primary_subdriver = d.primary_subdriver
  left join (select * from sb.user_aik604.iac_spend_3 where trxn_age_3 = 1) e
  on x.acct_id = e.acct_id
  and x.date_received = e.date_received
  and x.tier = e.tier
  and x.mapped_driver = e.mapped_driver
  and x.primary_subdriver = e.primary_subdriver
  left join (select * from sb.user_aik604.iac_spend_1 where trxn_age_1 = 1) f
  on x.acct_id = f.acct_id
  and x.date_received = f.date_received
  and x.tier = f.tier
  and x.mapped_driver = f.mapped_driver
  and x.primary_subdriver = f.primary_subdriver
);
create or replace table sb.user_aik604.iac_final as select * from sb.user_aik604.iac_final where com_dead_d >= 1;
