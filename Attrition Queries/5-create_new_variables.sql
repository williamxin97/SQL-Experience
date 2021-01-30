
-- acct opening month, acct closing month, months between complaint and attrition, days between opening acct and complaint, days netween complaint and attrition
create or replace table sb.user_aik604.iac_data as(
  select distinct *, 
  ceil(cast(datediff(day, '2019-01-01', open_dt) as float)/(30.4375)) as open_m, 
  ceil(cast(datediff(day, '2019-01-01', cls_dt) as float)/(30.4375)) as close_m,
  ceil(cast(datediff(day, date_received, cls_dt) as float)/(30.4375)) as com_dead_m,
  ceil(cast(datediff(day, date_received, open_dt) as float)) as open_com_d, 
  ceil(cast(datediff(day, date_received, cls_dt) as float)) as com_dead_d  
  from sb.user_aik604.iac_cut
);

-- setting 0 day deaths to instead be 1 day deaths, and null to 10000 for the sake of excel
update sb.user_aik604.iac_data
set com_dead_m = case
when com_dead_m = 0 then 1
when com_dead_m is null then 100000
else com_dead_m
end;
update sb.user_aik604.iac_data
set open_com_d = case
when open_com_d = 0 then 1
when open_com_d is null then 100000
else open_com_d
end;
update sb.user_aik604.iac_data
set com_dead_d = case
when com_dead_d = 0 then 1
when com_dead_d is null then 100000
else com_dead_d
end;
update sb.user_aik604.iac_data
set com_m = 100000
where com_m is null;
update sb.user_aik604.iac_data
set close_m = 100000
where close_m is null;

--You can see breakdown of complaint segments here
select segment, count(*) from sb.user_aik604.iac_data group by 1 order by 2 desc;
