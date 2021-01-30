--iac stands for info_and_complaints. I created a new table just so the old table is a backup
-- com_m is months between complaining and attrition. 


create or replace table sb.user_aik604.iac as (
  select distinct a.*
    , b.mapped_driver
    , ceil(cast(datediff(day, '2019-01-01', a.date_received) as float)/(30.4375)) as com_m
  from sb.user_aik604.info_and_complaints a
  left join card_db_collab.lab_complaints_discovery.mapped_drivers b
      on TRIM(replace(a.primary_driver || a.primary_subdriver,',')) = b.concat_drivers
      and Upper(a.Tier) = Upper(b.Tier)
  and a.open_dt is not null
);


--This section joins to product segmentation data and finds the most recent product the customer had before complaining

create or replace table sb.user_aik604.iac as (
  select distinct * from 
    (select *
      , row_number() over (partition by acct_id order by effective_start_date desc) as row_num 
    from 
     (select a.*, b.product_family_name, b.product_line_name, b.effective_start_date 
        from sb.user_aik604.iac a
        left join CARD_DB.PHDP_CARD.MATCHBOX_PRODUCT_REGISTRY_ACCOUNT_PRODUCT b
        on a.acct_id = b.account_id
        where date_received >= effective_start_date
      )
    )
    where row_num = 1
);
