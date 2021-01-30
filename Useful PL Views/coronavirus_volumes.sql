
--Pull all Tier 2 coronavirus-related complaints since March 2020
select *
  from CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.CMPLANT_PL
  where  (upper(cmplant_cmnt_txt) like '%CORONA%'
OR upper(cmplant_cmnt_txt) like '%COVID%'
OR upper(cmplant_cmnt_txt) like '%VIRUS%'
OR upper(cmplant_cmnt_txt) like '%EPIDEMIC%'
OR upper(cmplant_cmnt_txt) like '%OUTBREAK%'
OR upper(cmplant_cmnt_txt) like '%PANDEMIC%')
and (not(upper(cmplant_cmnt_txt) like '%ANTIVIRUS%'
OR upper(cmplant_cmnt_txt) like '%ANTI VIRUS%'))
  and date_received >= '2020-03-01'
  and tier in = 'Tier 2';
  
--Pull all Tier 2 complaints since March 2020
select *
  from CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.CMPLANT_PL
  where date_received >= '2020-03-01'
  and tier in = 'Tier 2';


--Weekly totals of coronavirus-related complaints
select 
  tier, 
  date_trunc('WEEK', date_received) as week,
  count(*) as qty
  from CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.CMPLANT_PL
  where  (upper(cmplant_cmnt_txt) like '%CORONA%'
OR upper(cmplant_cmnt_txt) like '%COVID%'
OR upper(cmplant_cmnt_txt) like '%VIRUS%'
OR upper(cmplant_cmnt_txt) like '%EPIDEMIC%'
OR upper(cmplant_cmnt_txt) like '%OUTBREAK%'
OR upper(cmplant_cmnt_txt) like '%PANDEMIC%')
and (not(upper(cmplant_cmnt_txt) like '%ANTIVIRUS%'
OR upper(cmplant_cmnt_txt) like '%ANTI VIRUS%'))
  and date_received >= '2020-03-01'
  and tier in ('Tier 2', 'Tier 3')
  group by 1,2 order by 1,2 asc;
  
--One way to do weekly coronavirus complaints by segment and primary subdriver
select
  case when segment like '%Upmarket%' then 'Upmarket' when segment in ('BB Unknown','Other','Cobrand/PLCC Unknown') then null else segment end as segment_f,
  primary_subdriver,
  count(distinct case when date_received between '2020-03-01' and '2020-03-07' then cmplant_id else null end) As "3-1",
  count(distinct case when date_received between '2020-03-08' and '2020-03-14'  then cmplant_id else null end) As "3-8",
  count(distinct case when date_received between '2020-03-15' and '2020-03-21'then cmplant_id else null end) As "3-15",
  count(distinct case when date_received between '2020-03-22' and '2020-03-28'then cmplant_id else null end) As "3-22",
  count(distinct case when date_received between '2020-03-29' and '2020-04-4' then cmplant_id else null end) As "3-29",
  count(distinct case when date_received between '2020-04-5' and '2020-04-11' then cmplant_id else null end) As "4-5",
  count(distinct case when date_received between '2020-04-12' and '2020-04-18' then cmplant_id else null end) As "4-12",
  count(distinct case when date_received between '2020-04-19' and '2020-04-25' then cmplant_id else null end) As "4-19",
  count(distinct case when date_received between '2020-04-26' and '2020-05-02' then cmplant_id else null end) As "4-26",
  count(distinct case when date_received between '2020-05-03' and '2020-05-09' then cmplant_id else null end) As "5-3",
  count(distinct case when date_received between '2020-03-01' and '2020-05-09' then cmplant_id else null end) as total
from CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.CMPLANT_PL
where  (upper(cmplant_cmnt_txt) like '%CORONA%'
OR upper(cmplant_cmnt_txt) like '%COVID%'
OR upper(cmplant_cmnt_txt) like '%VIRUS%'
OR upper(cmplant_cmnt_txt) like '%EPIDEMIC%'
OR upper(cmplant_cmnt_txt) like '%OUTBREAK%'
OR upper(cmplant_cmnt_txt) like '%PANDEMIC%')
and (not(upper(cmplant_cmnt_txt) like '%ANTIVIRUS%'
OR upper(cmplant_cmnt_txt) like '%ANTI VIRUS%'))
and tier in ('Tier 2', 'Tier 3')
group by 1,2
qualify rank()over(partition by segment_f order by total desc) <= 10
order by segment_f, Total desc;


--Top10 are top 10 primary subdrivers for all complaints

create or replace table top10 as select primary_subdriver from (select primary_subdriver, count(*) as qty
from CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.CMPLANT_PL
where date_received >= '2020-03-01'
and tier in ('Tier 2', 'Tier 3')
group by 1 order by 2 desc limit 10);

--Top10cv are top 10 primary subdrivers for coronavirus complaints

create or replace table top10cv as select primary_subdriver from (select primary_subdriver, count(*) as qty
from CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.CMPLANT_PL
where date_received >= '2020-03-01'
and (upper(cmplant_cmnt_txt) like '%CORONA%'
OR upper(cmplant_cmnt_txt) like '%COVID%'
OR upper(cmplant_cmnt_txt) like '%VIRUS%'
OR upper(cmplant_cmnt_txt) like '%EPIDEMIC%'
OR upper(cmplant_cmnt_txt) like '%PANDEMIC%'
OR upper(cmplant_cmnt_txt) like '%OUTBREAK%')
and (not(upper(cmplant_cmnt_txt) like '%ANTIVIRUS%'
OR upper(cmplant_cmnt_txt) like '%ANTI VIRUS%'))
and tier in ('Tier 2', 'Tier 3')
group by 1 order by 2 desc limit 10);

--Create excel view for weekly subdriver volumes for coronavirus complaints
create or replace table cv_weekly as 
select primary_subdriver, date_trunc('WEEK', date_received) as week, count(*) as qty 
from CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.CMPLANT_PL
where date_received >= '2020-03-01'
and (upper(cmplant_cmnt_txt) like '%CORONA%'
OR upper(cmplant_cmnt_txt) like '%COVID%'
OR upper(cmplant_cmnt_txt) like '%VIRUS%'
OR upper(cmplant_cmnt_txt) like '%EPIDEMIC%'
OR upper(cmplant_cmnt_txt) like '%PANDEMIC%'
OR upper(cmplant_cmnt_txt) like '%OUTBREAK%')
and (not(upper(cmplant_cmnt_txt) like '%ANTIVIRUS%'
OR upper(cmplant_cmnt_txt) like '%ANTI VIRUS%'))
and tier in ('Tier 2', 'Tier 3')
and primary_subdriver in (select * from top10cv)
group by 1,2 order by 1,2 asc;

--Create excel view for weekly subdriver volumes for all complaints
create or replace table all_weekly as 
select primary_subdriver, date_trunc('WEEK', date_received) as week, count(*) as qty 
from CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.CMPLANT_PL
where date_received >= '2020-03-01'
and tier in ('Tier 2', 'Tier 3')
and primary_subdriver in (select * from top10)
group by 1,2 order by 1,2 asc;

--Get volumes to plug into Excel
select * from cv_weekly;
select * from all_weekly;
