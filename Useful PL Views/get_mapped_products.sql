
--This section joins to product segmentation data and finds the most recent product the customer had before complaining
-- For the month of January 2020

create or replace temporary table joined_products as (
  select distinct * from 
    (select *
      , row_number() over (partition by acct_id order by effective_start_date desc) as row_num 
    from 
     (select a.*, b.product_family_name, b.product_line_name, b.effective_start_date 
        from card_db_collab.lab_channels_complaints.cmplant_pl a
        left join CARD_DB.PHDP_CARD.MATCHBOX_PRODUCT_REGISTRY_ACCOUNT_PRODUCT b
        on a.acct_id = b.account_id
        where date_received >= effective_start_date
        and date_received between '2020-01-01' and '2020-01-31'
      )
    )
    where row_num = 1
);
