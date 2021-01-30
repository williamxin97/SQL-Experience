Select date_trunc('MONTH',sale_date) as Sale_Month, count(distinct a.account_ID) as Accts_Sold
from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT a
join CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ASSET_SALES b
on a.account_ID = b.account_ID
where b.sale_date > '2020-01-01'
and a.previous_system_of_record = 'WHIRL'
group by 1
order by 1 asc;

select * from null_acct limit 100;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT where account_id in (select account_id from null_acct) limit 100;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT where account_id in (select account_id from non_null_acct) and detailed_psor = 'HBC'
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION where account_id = '974135634' order by transaction_posting_date desc;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS where account_id = '974135634';

select charge_off_reason_cd, count(distinct account_id) from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT 
  where account_id in (select account_id from null_acct)
  and previous_system_of_record = 'WHIRL'
group by 1 order by 2 desc;


select detailed_psor, count(distinct account_id) from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT 
  where account_id in (select account_id from null_acct)
  and previous_system_of_record = 'WHIRL'
group by 1 order by 2 desc;

select count(*) from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION where transaction_posting_date >= '2020-01-01';
select count(distinct account_id, transaction_posting_date, transaction_amount, total_recoveries) from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION where transaction_posting_date >= '2020-01-01';

select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION  limit 100;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT limit 100;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ASSET_SALES limit 100;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS  limit 100;
select distinct data_dt from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT limit 1000;
select distinct data_dt from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT limit 1000;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION where transaction_amount <> total_recoveries limit 1000;

select strategy, count(distinct account_id) as qty from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS where start_date >= '2020-01-01' group by 1 order by 2 desc;



select ever_sold, final_sold_status_flag, count(account_id) as qty from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ASSET_SALES group by 1,2 order by 3 desc;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ASSET_SALES limit 100;
select count(distinct account_id) from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS limit 100;
select * from card_db.phdp_card.rcvry_chrstc_srvc_characteristics limit 100;
select * from cond_1_2_acct limit 100;
select count(account_id) from temp_sold2;
select count(distinct account_id) from temp_sold2;

create or replace table accts_sold as (
  select a.*, b.characteristic, b.characteristic_entered_date
  from cond_1_2_acct a 
  left join temp_sold2 b
  on a.account_id = b.account_id
  --and b.snap_dt = '2020-10-02'
);

create or replace table temp_sold as (
  select account_id, max(characteristic_entered_date) as char_enter
  from card_db.phdp_card.rcvry_chrstc_srvc_characteristics
  where account_id in (select account_id from cond_1_2_acct)
  and snap_dt = '2020-10-04'
  group by 1
);

create or replace table temp_sold2 as (
  select b.account_id, b.characteristic_entered_date, b.characteristic
  from temp_sold a
  left join card_db.phdp_card.rcvry_chrstc_srvc_characteristics b
  on a.account_id = b.account_id
  and a.char_enter = b.characteristic_entered_date
  and b.snap_dt = '2020-10-04'
);

select characteristic, count(distinct account_id) from accts_sold where end_date is not null group by 1 order by 2 desc;
select * from accts_sold where end_date is not null and characteristic = 'PARTNER' limit 1000;
select * from card_db.phdp_card.rcvry_chrstc_srvc_characteristics where account_id = '398205716' order by snap_dt desc limit 100;

select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ASSET_SALES limit 100;

select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS where strategy = 'SALES' limit 1000;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS where account_id = '561451485' limit 1000;

select strategy, count(distinct account_id)
  from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS
  where end_date is null
  and account_id in (select distinct account_id from funny_sales where transaction_posting_date >= end_date)
  group by 1 order by 2 desc;

select * from funny_sales 
  where transaction_posting_date >= start_date
  and (transaction_posting_date <= end_date or end_date is null)
    limit 100;
    
create or replace table cond_1_acct as (
select distinct account_id, start_date, end_date from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS
where strategy = 'SALES');

/*create or replace table cond_1_2_acct as (
select distinct account_id, start_date, end_date from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT
where account_id in (select account_id from cond_1_acct)
and previous_system_of_record = 'WHIRL'
and account_type <> 'CANADIAN');*/

create or replace table cond_1_2_acct as (
select distinct a.* 
  from cond_1_acct a
  left join CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT b
  on a.account_id = b.account_id
where b.previous_system_of_record = 'WHIRL'
  and b.account_type <> 'CANADIAN');

create or replace table funny_sales as(
select a.*, b.start_date, b.end_date
  from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION a
  left join cond_1_2_acct b
  on a.account_id = b.account_id
  where start_date is not null
  and transaction_posting_date >= '2020-01-01'
  order by transaction_posting_date desc);

/*
*/
--select * from co_pay2 where sale_date is null limit 1000;
--select * from co_pay2 where upper(strategy) like '%LEGAL%'  limit 1000;
--select * from co_pay2 where upper(strategy) like '%SERVICE_ONLY%'  and charge_off_date >= '2019-01-01' limit 1000;
--select * from	db.ppdw_credit.arr_snap_dly where arr_id_chain = '00123851781';
select * from co_pay where strategy = 'SALES' order by transaction_posting_date desc limit 1000;

create or replace table card_dupes as (
  select *, count(arr_id_acct) over (partition by arr_id_acct) as dupes from db.ppdw_secured.pshp_plstc_card_bc);

create or replace table acct_id_to_plstc as (
  select plstc_card_num, arr_id_acct, arr_id_chain, edw_publn_id
    , max(edw_publn_id) over (partition by arr_id_acct, arr_id_chain) as edw
    , max(plstc_card_num) over (partition by arr_id_acct, arr_id_chain, edw_publn_id) as plstc
    ,dupes
  from card_dupes
);
create or replace table acct_id_to_plstc as (
  select distinct *
  from acct_id_to_plstc
  where edw_publn_id = edw
  and plstc_card_num = plstc
);
/*create or replace table acct_id_to_plstc as (
  select distinct *
  from acct_id_to_plstc
  where plstc_card_num = plstc
);*/
select count(distinct arr_id_acct) from acct_id_to_plstc;
select count(distinct arr_id_chain) from acct_id_to_plstc;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION limit 100;
select count(distinct arr_id_chain) from db.ppdw_credit.arr_snap_dly;
create or replace temporary table all_plstc as select plstc_card_num, length(plstc_card_num) as digits from db.ppdw_secured.pshp_plstc_card_bc;
select digits, count(plstc_card_num) from all_plstc group by 1 order by 2 desc;
select plstc_card_num from all_plstc where digits = 19 order by 1 asc limit 1000;
select count(distinct arr_id_chain) from db.ppdw_secured.pshp_plstc_card_bc;
select * from	card_db_proc.prd_customer_resiliency.rcvry_characteristics limit 100;


create or replace table co_pay as (
  select 
    a.account_id, b.account_type, a.transaction_id, b.previous_account_id, b.previous_system_of_record
    , a.transaction_posting_date, a.transaction_amount, a.total_recoveries, b.charge_off_date, c.sale_date, c.ever_sold
    , b.charge_off_reason_cd, d.strategy, b.pre_charge_off_acct_num
    , cast(datediff(day, b.charge_off_date, transaction_posting_date) as float)/(30.4375) as co_pay_month
    , cast(datediff(day, b.charge_off_date, '2020-10-01') as float)/(30.4375) as age
  from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION a
  left join CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT b
    on a.account_id = b.account_id
  left join CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ASSET_SALES c
    on a.account_id = c.account_id
  left join CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS d
    on a.account_id = d.account_id
    and a.transaction_posting_date >= d.start_date
    and ((a.transaction_posting_date <= d.end_date) or (d.end_date is null))
  where b.previous_system_of_record = 'WHIRL'
  and a.transaction_posting_date >= '2017-01-01'
);
/*create or replace table co_pay2 as (
  select distinct a.*, b.strategy, b.start_date as placement_st_dt, b.end_date as placement_end_dt
  from co_pay a
  left join CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PLACEMENTS b
  on a.account_id = b.account_id
  and a.transaction_posting_date >= b.start_date
  and ((a.transaction_posting_date <= b.end_date) or (b.end_date is null))
);*/
create or replace table co_pay2 as (
  select 
    case
      when upper(strategy) in ('SERVICE_ONLY','FRESH_CHARGE_OFF','SALES_ELIGIBLE','SELF_PAYER','PARTNERSHIP','CONTINGENCY','UNKNOWN','INBOUND','CHARGED_OFF_ERROR') then 'REGULAR'
      --when upper(strategy) = 'CHARGED_OFF_ERROR' then NULL
      when ((strategy is null) and (upper(charge_off_reason_cd) like '%BANKRUPT%')) then 'BANKRUPTCY'
      when ((strategy is null) and (upper(charge_off_reason_cd) like '%BAD_DEBT%')) then 'REGULAR'
      when ((strategy is null) and (upper(charge_off_reason_cd) like '%DECEASED%')) then 'ESTATES'
      when ((strategy is null) and (upper(charge_off_reason_cd) like '%SETTLED_PRE_CHARGE_OFF%')) then 'REGULAR'
      else strategy
      end as strat_cat
    , case
      when ((strategy is null) and (upper(charge_off_reason_cd) like '%BAD_DEBT%')) then 'BAD_DEBT'
      when ((strategy is null) and (upper(charge_off_reason_cd) like '%SETTLED_PRE_CHARGE_OFF%')) then 'SETTLED_PRE_CHARGE_OFF'
      else strategy
      end as reg_strat
    /*,case
      when (upper(strategy) = 'SALES' and total_recoveries < 0) then 0
      else total_recoveries
      end as mod_recoveries
      */
    ,*
    from co_pay
);
/*create or replace table co_pay3 as (
  select a.*, b.plstc_card_num as plstc_arr, length(ltrim(pre_charge_off_acct_num,'0'))
  from co_pay2 a
  left join acct_id_to_plstc b
  on a.previous_account_id = b.arr_id_chain
  );*/
  
create or replace table co_pay3 as (
  select *, length(ltrim(pre_charge_off_acct_num,'0')) as digits
  from co_pay2 
  );
/*select strat_cat, count(distinct account_id)
  from co_pay3
  where upper(charge_off_reason_cd) like '%BANKRUPT%'
  and account_type <> 'CANADIAN'
  and transaction_posting_date >= '2018-01-01'
  group by 1 order by 2 desc;
  */
--select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ASSET_SALES where account_id = '1003809759';
--select * from co_pay3 where strat_cat = 'SALES' and transaction_posting_date >= '2020-01-01' limit 1000;
--select count(*) from co_pay4;
create or replace table co_pay4 as(
  select a.*, b.transaction_amount as t_amount_2, b.total_recoveries as t_recov_2, b.transaction_posting_date as t_pdate_2, c.transaction_amount as t_amount_3, c.total_recoveries as t_recov_3, c.transaction_posting_date as t_pdate_3
  from co_pay3 a
  left join co_pay3 b
  on a.account_id = b.account_id
  and a.transaction_amount = -1 * b.transaction_amount
  and a.transaction_amount < 0
  and a.transaction_posting_date > b.transaction_posting_date
  left join co_pay3 c
  on a.account_id = c.account_id
  and a.transaction_amount = -1 * b.transaction_amount
  and a.transaction_amount > 0
  and a.transaction_posting_date < b.transaction_posting_date
);

create or replace table co_pay3 as select * from co_pay3 where account_type <> 'CANADIAN';
create or replace table co_pay4 as select * from co_pay4 where account_type <> 'CANADIAN';

update co_pay3
set co_pay_month = case
    when co_pay_month > 0 then ceil(co_pay_month)
    when co_pay_month < 0 then floor(co_pay_month)
    when co_pay_month = 0 then -1
    else co_pay_month end;
    
update co_pay3
set age = case
    when age > 0 then ceil(age)
    when age < 0 then floor(age)
    when age = 0 then -1
    else age end;

select count(*) from co_pay4;
select count(*) from co_pay3;
select count(*) from co_pay4;
select * from co_pay4 where transaction_amount < 0 limit 1000;

/*select date_trunc('year', transaction_posting_date), -1 * sum(total_recoveries)
  from co_pay4
  where strat_cat = 'SALES'
  and transaction_amount < 0
  and transaction_posting_date > sale_date
  and t_amount_2 is null
  group by 1 order by 1 asc;
*/
select * from co_pay3 limit 100;

select date_trunc('year',transaction_posting_date) as yr, co_pay_month, sum(total_recoveries) from co_pay3
  where transaction_posting_date between  '2020-01-01' and '2020-09-30'
  and strat_cat <> 'SALES'
  and co_pay_month <= 2.05
  and (digits <> 16 or digits is null)
  group by 1,2 order by 1,2 asc
;

select date_trunc('year',transaction_posting_date) as yr, age, sum(total_recoveries) from co_pay3
  where transaction_posting_date between  '2017-01-01' and '2020-09-30'
  and strat_cat <> 'SALES'
  and (digits <> 16 or digits is null)
  group by 1,2 order by 1,2 asc
;


  
select date_trunc('month', transaction_posting_date), strat_cat, sum(total_recoveries)
  from co_pay3
  where transaction_posting_date >= '2017-01-01'
  and account_type <> 'CANADIAN'
  --and ever_sold is null
  and strat_cat <> 'SALES'
  --and strat_cat is null
  and (digits <> 16 or digits is null)
  group by 1,2 order by 2,1 asc
;

select date_trunc('month', transaction_posting_date), reg_strat, sum(total_recoveries)
  from co_pay3
  where transaction_posting_date >= '2017-01-01'
  and account_type <> 'CANADIAN'
  --and ever_sold is null
  and strat_cat = 'REGULAR'
  --and strat_cat is null
  and (digits <> 16 or digits is null)
  group by 1,2 order by 2,1 asc
;


select date_trunc('month', transaction_posting_date), 'SALES' as strategy, -1 * sum(total_recoveries)
  from co_pay4
  where strat_cat = 'SALES'
  and transaction_amount < 0
  and transaction_posting_date > sale_date
  and t_amount_2 is null
  and transaction_posting_date >= '2017-01-01'
  and account_type <> 'CANADIAN'
  and (digits <> 16 or digits is null)
  group by 1 order by 1 asc;
select date_trunc('month', transaction_posting_date), 'SALES' as strategy, sum(total_recoveries)
  from co_pay4
  where strat_cat = 'SALES'
  and transaction_amount > 0
  and transaction_posting_date > sale_date
  and t_amount_3 is null
  and transaction_posting_date >= '2017-01-01'
  and account_type <> 'CANADIAN'
  and (digits <> 16 or digits is null)
  group by 1 order by 1 asc;

select * from co_pay3 where plstc_arr is not null and pre_charge_off_acct_num is null limit 100;

create or replace table card_num as (
select distinct account_id, previous_account_id as prev, plstc_arr as plstc, pre_charge_off_acct_num as num from co_pay3
where transaction_posting_date >= '2017-01-01'
  --and ever_sold is null
  and strat_cat <> 'SALES');


select count(distinct plstc) from card_num;
select count(distinct num) from card_num;

select count(distinct num) from card_num where num is null;

select count(distinct prev) from card_num where plstc is not null and num is null;
select count(distinct prev) from card_num where plstc is null and num is not null;

select * from card_num;
create or replace table digits_card as select plstc, length(ltrim(plstc,'0')) as digits
  from card_num
  ;
create or replace table digits_num as select num, length(ltrim(num,'0')) as digits
  from card_num
  ;
  
create or replace table digits_card as select distinct plstc_arr, length(ltrim(plstc_arr,'0')) as digits
  from co_pay3
  where transaction_posting_date >= '2017-01-01'
  --and ever_sold is null
  and strat_cat <> 'SALES'
  --and strat_cat is null
  --and plstc_arr is not null
  ;
create or replace table digits_num as select distinct pre_charge_off_acct_num, length(ltrim(pre_charge_off_acct_num,'0')) as digits
  from co_pay3
  where transaction_posting_date >= '2017-01-01'
  --and ever_sold is null
  and strat_cat <> 'SALES'
  --and strat_cat is null
  --and pre_charge_off_acct_num is not null
  ;
select * from digits limit 100;
select digits, count(*) as qty from digits_num group by 1 order by 1 desc;
select digits, count(plstc) as qty from digits_card group by 1 order by 1 desc;

/*  
select date_trunc('year', transaction_posting_date), sum(total_recoveries)
  from co_pay4
  where strat_cat = 'SALES'
  and transaction_amount > 0
  and transaction_posting_date > sale_date
  and t_amount_3 is null
  group by 1 order by 1 asc;
*/  
/*select account_type, count(distinct account_id)
  from co_pay3
  where strat_cat is null
  and account_type <> 'CANADIAN'
  and transaction_posting_date >= '2018-01-01'
  group by 1 order by 2 desc;
*/  
create or replace table null_acct as select distinct account_id
  from co_pay3
  where strat_cat is null
  and account_type <> 'CANADIAN'
  and transaction_posting_date >= '2019-01-01'
  ;
  
create or replace table non_null_acct as select distinct account_id
  from co_pay3
  where strat_cat is not null
  and account_type <> 'CANADIAN'
  and transaction_posting_date >= '2019-01-01'
  ;

  
select charge_off_reason_cd, count(distinct account_id) from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT 
  where account_id in (select account_id from null_acct) 
  group by 1 order by 2 desc;
  
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT where account_id = '224252106';
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT where previous_account_id like '%49989469165%';
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT limit 1000;
  
select date_trunc('month', transaction_posting_date), 'SALES' as strategy, sum(total_recoveries)
  from co_pay4
  where strat_cat = 'SALES'
  and transaction_amount > 0
  and transaction_posting_date > sale_date
  and t_amount_3 is null
  and transaction_posting_date >= '2017-01-01'
  and account_type <> 'CANADIAN'
  group by 1 order by 1 asc;
  
select strat_cat, count(distinct account_id) from co_pay3 group by 1 order by 2 desc;

select date_trunc('month', transaction_posting_date), strat_cat, sum(total_recoveries)
  from co_pay3
  where transaction_posting_date >= '2017-01-01'
  and account_type <> 'CANADIAN'
  --and ever_sold is null
  and strat_cat <> 'SALES'
  --and strat_cat is null
  group by 1,2 order by 2,1 asc
;

select date_trunc('month', transaction_posting_date), reg_strat, sum(total_recoveries)
  from co_pay3
  where transaction_posting_date >= '2017-01-01'
  and account_type <> 'CANADIAN'
  --and ever_sold is null
  and strat_cat = 'REGULAR'
  --and strat_cat is null
  group by 1,2 order by 2,1 asc
;


select * from co_pay3
  where transaction_posting_date >= '2019-01-01'
  --and ever_sold is null
  and strat_cat <> 'SALES'
  --and strat_cat is null
limit 100;

select sum(transaction_amount) from co_pay 
where ever_sold is null
and transaction_posting_date >= '2018-01-01'
and transaction_posting_date >= charge_off_date
;

select * from db.ppdw_credit.arr_snap_dly  limit 100;
select * from	db.ppdw_credit.arr_perfm_snap_eoc limit 100;

select * from db.ppdw_secured.pshp_plstc_card_bc limit 100;

select * from db.ppdw_secured.pshp_plstc_card_bc where plstc_card_num like '%5243371208075128%';
select * from db.ppdw_secured.pshp_plstc_card_bc where arr_id_chain like '%8894558095028366%';

select * from db.ppdw_secured.pshp_plstc_card_bc where plstc_card_num like '%49989469165%';
select * from db.ppdw_secured.pshp_plstc_card_bc where plstc_card_num like '%7598589146%';
select * from db.ppdw_secured.pshp_plstc_card_bc where arr_id_chain like '%481288645%';

select count(distinct plstc_card_num) from db.ppdw_secured.pshp_plstc_card_bc;

102740962, 489280595
214379026, 133615140
prev 8894558095028366
acct 140798307
num 5243371208075128
;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION where account_id like '%102740962%' order by transaction_posting_date desc;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION where account_id like '%548178789%' order by transaction_posting_date desc;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION where account_id like '%481288645%' order by transaction_posting_date desc;
--select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_PAYMENTS_TRANSACTION limit 100;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT where previous_account_id like '%8894558095028366%';
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT where account_id like '%214379026%';
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT where previous_account_i d like '%489280595%';
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT where previous_account_id like '%133615140%';

select * from db.ppdw_secured.pshp_plstc_card_bc limit 100;
select * from CARD_DB_PROC.PRD_CUSTOMER_RESILIENCY.RCVRY_ACCOUNT limit 100;

create or replace table temp as (
select distinct a.account_id, a.previous_account_id, b.plstc_card_num from
  (select distinct account_id, previous_account_id from co_pay3) a
  left join db.ppdw_secured.pshp_plstc_card_bc b
  on a.account_id = b.arr_id_acct
 );
  
select * from temp limit 1000;

select count(distinct plstc_card_num) from acct_id_to_plstc;


select * from card_dupes where dupes >= 2 
--order by arr_id_acct asc 
limit 100;

create or replace table co_pay3 as select * from co_pay3 where account_type <> 'CANADIAN';
select account_type, count(account_id) from co_pay3 group by 1 order by 2 desc;
select * from co_pay3 limit 100;

select 
