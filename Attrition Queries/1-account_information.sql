
--WARNING: This analysis completely omits customers who have been involuntarily terminated
--Attrition is counted as (voluntary attrition) / (customers who don't voluntarily attrite + voluntary attrition)
--Make sure to keep this data bias in mind
 

-- Join 2 databases that have account information that we need
--Find all recent voluntary closures and non-closures using the clsd_reas_cd field

create or replace table sb.user_aik604.close_v as(
  SELECT a.acct_id, a.cls_dt, a.clsd_reas_cd, b.open_dt 
  from db.pcdw.t2_acct_stat_hist_bc a
  left join db.pcdw.t2_acct_snap_bc b
  on a.acct_id = b.acct_id
  where a.snap_dt >= '2019-01-01'
  and a.acct_sfx_num = 0
  and (upper(a.clsd_reas_cd) in ('V1','V2','V3','V4','V5','V6','V7','V8','V9','W1','W2','W3','W4','W5','W6','W7','W8','W9')  or a.clsd_reas_cd = '*2')
);

--We need to fix some data inconsistencies in the closure fields
create or replace table temp_close as (
  select distinct * from sb.user_aik604.close_v
);

update temp_close
set cls_dt = '2050-01-01'
where cls_dt is null;

create or replace table temp_close as (
select acct_id, min(cls_dt) as cls_dt from temp_close group by 1
);

update temp_close
set cls_dt = null
where cls_dt = '2050-01-01';

create or replace table sb.user_aik604.close_v_fix as (
  select distinct a.*, b.clsd_reas_cd, b.open_dt
  from temp_close a
  left join sb.user_aik604.close_v b
  on a.acct_id = b.acct_id
);
