create or replace temporary table rpm_late_bucket_calls as (
select a.*
from ptnr_db_collab.lab_card_cb.collns_call_lvl_data a
where dialer_type = 'AUTO'
and call_dt between '2019-01-01' and '2020-11-30'
and acct_sor = 'WHIRL'
and ptnr_nm not in ('SAKS FIFTH AVENUE','NEIMAN MARCUS','BERGDORF GOODMAN')
and dlq_stat in ('dq60','dq90','dq120','dq150'));

select date_trunc('month',call_dt), case when dlq_stat in ('dq60','dq90') then 'Late' else 'Liquidate' end as dial_stage, count(distinct acct_id) as accounts_called
from rpm_late_bucket_calls group by 1,2 order by 2,1;

select case when dlq_stat in ('dq60','dq90') then 'Late' else 'Liquidate' end as dial_stage,
count(*) as num_calls, count(distinct acct_id) as accounts_called
from rpm_late_bucket_calls where call_dt between '2020-09-01' and '2020-11-30' group by 1 order by 1;

select call_dt, count(distinct acct_id) from ptnr_db_collab.lab_card_cb.collns_call_lvl_data group by 1 order by 1 desc;

show grants on ptnr_db_collab.lab_card_cb.collns_call_lvl_data;
