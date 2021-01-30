--BBflag and Tier

select * from (
  select 
    bbflag, tier, count(*) as qty
  from card_db_collab.lab_channels_complaints.cmplant_pl
  where date_received >= '2020-01-01'
  group by 1,2)
pivot(sum(qty) for tier in ('Tier 1', 'Tier 2', 'Tier 3'))
order by 2 desc;
-------------------
--Date and Tier
select * from (select date_trunc('MONTH',date_received) as month, tier, count(*) as qty
    from card_db_collab.lab_channels_complaints.cmplant_pl
    where date_received between '2019-05-01' and '2020-04-30'
    group by 1,2)
pivot(sum(qty) for tier in ('Tier 1', 'Tier 2', 'Tier 3'))
order by month asc;
-------------------
--Driver and Tier
----The first set of queries are the optimal queries, and the second set of queries is more of an exercise
----The second set of queries was performed to get all tiers into one table, which is useful for automation

----First queries

create or replace table pl_with_mapped_driver as (
  select a.*, b.mapped_driver
    from card_db_collab.lab_channels_complaints.cmplant_pl a
    left join card_db_collab.lab_complaints_discovery.mapped_drivers b
        on TRIM(replace(a.primary_driver || a.primary_subdriver,',')) = b.concat_drivers
        and Upper(a.Tier) = Upper(b.Tier)
    where a.date_received >= '2020-01-01');

select mapped_driver, count(*) as "Tier 1"
  from pl_with_mapped_driver
  where tier = 'Tier 1'
  group by 1
  order by 2 desc;
  
select mapped_driver, count(*) as "Tier 2"
  from pl_with_mapped_driver
  where tier = 'Tier 2'
  group by 1
  order by 2 desc;
  
select mapped_driver, count(*) as "Tier 3"
  from pl_with_mapped_driver
  where tier = 'Tier 3'
  group by 1
  order by 2 desc;
  
  
----Second set of queries

----Join PL to mapped drivers

create or replace table pl_with_mapped_driver as (
  select a.*, b.mapped_driver
    from card_db_collab.lab_channels_complaints.cmplant_pl a
    left join card_db_collab.lab_complaints_discovery.mapped_drivers b
        on TRIM(replace(a.primary_driver || a.primary_subdriver,',')) = b.concat_drivers
        and Upper(a.Tier) = Upper(b.Tier)
    where a.date_received >= '2020-01-01');

----Top 5 drivers in each tier, unioned

create or replace table top_drivers as (
  select distinct mapped_driver from
  ((select mapped_driver from 
        (select mapped_driver, count(*) from pl_with_mapped_driver
            where tier = 'Tier 1' 
            group by 1 order by 2 desc limit 5)
  )
  union all
  (select mapped_driver from 
        (select mapped_driver, count(*) from pl_with_mapped_driver
            where tier = 'Tier 2' 
            group by 1 order by 2 desc limit 5)
  )
  union all
  (select mapped_driver from 
        (select mapped_driver, count(*) from pl_with_mapped_driver
            where tier = 'Tier 3' 
            group by 1 order by 2 desc limit 5)
  ))
);

----2020 volumes by top drivers and tier
----This was only performed to get all tiers to fit into one table
----Optimally, you should instead have 3 separate tables with the top drivers for each tier

select x.mapped_driver, a."Tier 1", b."Tier 2", c."Tier 3" from 
  top_drivers x
  left join 
  (select mapped_driver, count(*) as "Tier 1"
    from pl_with_mapped_driver 
    where tier = 'Tier 1'
    group by 1 order by 2 desc) a
  on x.mapped_driver = a.mapped_driver
  left join 
  (select mapped_driver, count(*) as "Tier 2"
    from pl_with_mapped_driver 
    where tier = 'Tier 2'
    group by 1 order by 2 desc) b
  on x.mapped_driver = b.mapped_driver
  left join 
  (select mapped_driver, count(*) as "Tier 3"
    from pl_with_mapped_driver 
    where tier = 'Tier 3'
    group by 1 order by 2 desc) c
  on x.mapped_driver = c.mapped_driver
  order by 2 desc;
---------------------------------------


--Partner and Tier
select partner, count(*) as qty from CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.CMPLANT_PL 
    where bbflag = 'PA' 
    and date_received >= '2020-01-01'
    and partner is not NULL
    group by 1 order by 2 desc;

----Example for complaints for Bass/Cab
select cmplant_cmnt_txt, cmplant_id, acct_id from CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.CMPLANT_PL 
    where partner in ('Cabelas','Bass Pro Shops')
    and date_received >= '2020-01-01'
;
---------------------------------------

--Segment and BBflag

select * from (
  select 
    bbflag, 
    case when segment like '%Upmarket%' then 'Upmarket'
    when segment in ('Terminated','PA Unknown','Other','Cobrand/PLCC Unknown','BB Unknown') then 'Other'
    when segment is null then 'Other'
    else segment end as segment, 
    count(*) as qty
  from card_db_collab.lab_channels_complaints.cmplant_pl
  where date_received >= '2020-01-01'
  group by 1,2)
pivot(sum(qty) for bbflag in ('BB', 'PA'))
order by 3 desc;
---------------------------------------

--Segment and Tier

select * from (
  select 
    case when segment like '%Upmarket%' then 'Upmarket'
    when segment in ('Terminated','PA Unknown','Other','Cobrand/PLCC Unknown','BB Unknown') then 'Other'
    when segment is null then 'Other'
    else segment end as segment,
    tier, count(*) as qty
  from card_db_collab.lab_channels_complaints.cmplant_pl
  where date_received >= '2020-01-01'
  group by 1,2)
pivot(sum(qty) for tier in ('Tier 1', 'Tier 2', 'Tier 3'))
order by 2 desc;
---------------------------------------

--Source and Tier

select * from (
  select 
    data_source, tier, count(*) as qty
  from card_db_collab.lab_channels_complaints.cmplant_pl
  where date_received >= '2020-01-01'
  group by 1,2)
pivot(sum(qty) for tier in ('Tier 1', 'Tier 2', 'Tier 3'))
order by 1 desc;
---------------------------------------


