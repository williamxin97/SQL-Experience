
-- quick and dirty way of separating complaints by month

--Find the first complaint for each account every month
-- this tries to control for accounts that complain multiples times a month, so they don't get too over-represented in the data
--joining by max length agent comment text is done to try to control for some duplicates in the data

create or replace table sb.user_aik604.iac_cut as (
  select distinct b.*
  from 
    (select distinct acct_id, tier, min(date_received) over (partition by acct_id, com_m, tier) as date_received, max(len) over (partition by acct_id, date_received, tier) as len from sb.user_aik604.iac 
    where com_m is not null
    and tier is not null) a
  left join sb.user_aik604.iac b
  on  a.acct_id = b.acct_id
  and a.date_received = b.date_received
  and a.tier = b.tier
  and (a.len = b.len
  or (a.len is null and b.len is null))
  where (b.cls_dt is null or b.clsd_reas_cd <> '*2')
);