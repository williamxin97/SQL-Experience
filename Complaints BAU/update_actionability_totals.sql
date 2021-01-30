use warehouse CARD_Q_CHANNELS;
use database Card_Db_Collab;
use schema lab_complaints_discovery;

select
Case When Upper(a.DATA_SOURCE)='MANUAL' then date_trunc('MONTH',(dateadd(month,-1,a.load_date))) Else date_trunc('MONTH',a.DATE_RECEIVED) End as YM_Report_Date,
'Actionability Tagged' as Cmplant_Type,
count(distinct (Case WHEN b.Actionability is not null THEN Upper(a.cmplant_id || a.data_source) Else Null END)) AS Num_Complaints

from card_db_collab.lab_channels_complaints.cmplant_pl as a

Left outer join card_db_collab.lab_complaints_discovery.tagged_raw as b
on Upper(a.Cmplant_ID || a.Data_Source) = Upper(b.Cmplant_ID_Data_Source)

where YM_report_date >= '2018-01-01'
and Upper(a.Tier) = 'TIER 3'
group by 1,2

UNION ALL

select
Case When Upper(a.DATA_SOURCE)='MANUAL' then date_trunc('MONTH',(dateadd(month,-1,a.load_date))) Else date_trunc('MONTH',a.DATE_RECEIVED) End as YM_Report_Date,
'Total T3 Complaints' as Cmplant_Type,
count(distinct Upper(a.Cmplant_ID || a.Data_Source)) as Num_Complaints

from card_db_collab.lab_channels_complaints.cmplant_pl as a

Left outer join card_db_collab.lab_complaints_discovery.tagged_raw as b
on Upper(a.Cmplant_ID || a.Data_Source) = Upper(b.Cmplant_ID_Data_Source)

where YM_report_date >= '2018-01-01'
and Upper(a.Tier) = 'TIER 3'
group by 1,2
order by 1,2 asc
