------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------ Complaints Discovery --------------------------------------------------------------------
--------------------------------------------------------------- Complaints Tagging Script ------------------------------------------------------------------
-- Initial Script Creation by Mitchel "Mitch" Combs (TBS715) in April 2019                                                                                --
-- Updated: N/A                                                                                                                                           --
-- Platform: Snowflake, US Card                                                                                                                           --
-- Source tables: card_db_collab.lab_channels_complaints.cmplant_pl, card_db_collab.lab_complaints_discovery.mapped_drivers,                              --
--                card_db_collab.lab_complaints_discovery.mapped_segment                                                                                  --
-- Created tables: card_db_collab.lab_complaints_discovery.Tagged_Raw, card_db_collab.lab_complaints_discovery.Tagged_Final                               --
------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------
use warehouse card_q_channels;
use database card_db_collab;
use schema lab_complaints_discovery;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* Backup Data */
create or replace table card_db_collab.lab_complaints_discovery.tagged_raw_backup as(
select * from card_db_collab.lab_complaints_discovery.tagged_raw
);

/* 
create or replace temporary table card_db_collab.lab_complaints_discovery.tagged_final_backup as(
select * card_db_collab.lab_complaints_discovery.tagged_final
);
*/

/* Set Variables: 
     start_date       = first day of complaints for tagging, 
     end_date         = last day of complaints for tagging, 
     final_end_date   = date the "Tagged_Final" view goes through */
     
set (start_date,end_date,final_end_date)=('2018-01-01',current_date,'2020-01-31');

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Part I - Load Sheets Data into Snowflake */--------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TEMPORARY TABLE cmplant_load (
Cmplant_ID_Data_Source varchar(200),
L2 varchar(200),
Level1 varchar(200),
Level2 varchar(200),
Actionability varchar(200),
Root_Cause_Theme varchar(200),
Root_Cause_Detail varchar(200),
Honor_Uphold varchar(200),
Initial_PM varchar(6),
Tagging_PM varchar(6),
Tagging_Timestamp Timestamp
)

STAGE_FILE_FORMAT = (TYPE = 'csv' FIELD_DELIMITER= ',' skip_header = 1);

PUT file://C:\Users\aik604\Downloads\ComplaintsTagging\Data_Output.csv @%cmplant_load;

--Takes data from CSV file and inserts it into cmplant_load, while removing underscores '_' from L2, Level1, and Level2 columns
COPY INTO cmplant_load from (select a.$1, replace(a.$2,'_',' '), replace(a.$3,'_',' '), replace(a.$4,'_',' '), a.$5, a.$6, a.$7, a.$8, a.$9, a.$10, a.$11 from '@%cmplant_load' a);

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Part II - Side Load Tagged_Raw Table */------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
create or replace temporary table card_db_collab.lab_complaints_discovery.tagged_raw_transient as (
select distinct * from card_db_collab.lab_complaints_discovery.tagged_raw
);
--select count(distinct cmplant_id_data_source) from cmplant_load;
--select * from card_db_collab.lab_complaints_discovery.tagged_raw_transient;
--select * from card_db_collab.lab_complaints_discovery.data_extract where cmplant_id_data_source in (select cmplant_id_data_source from tagging_data);
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Part III - Recreate Tagged_Raw Table */------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Merge into tagged_raw_transient as b using (select distinct * from cmplant_load where L2 is Not Null OR Level1 is Not Null OR Level2 is Not Null OR Actionability is Not Null OR Root_Cause_Theme is Not Null OR Root_Cause_Detail is Not Null OR Honor_Uphold is Not Null OR Initial_PM is Not Null OR Tagging_PM is Not Null OR Tagging_Timestamp is Not Null) as a on b.cmplant_id_data_source = a.cmplant_id_data_source
  when matched then update set  b.L2 = a.L2,  
                                b.Level1 = a.Level1, 
                                b.Level2 = a.Level2, 
                                b.Actionability = a.Actionability, 
                                b.Root_Cause_Theme = a.Root_Cause_Theme, 
                                b.Root_Cause_Detail = a.Root_Cause_Detail,
                                b.Honor_Uphold = a.Honor_Uphold,
                                b.Initial_PM = a.Initial_PM,
                                b.Tagging_PM = a.Tagging_PM,
                                b.Tagging_Timestamp = a.Tagging_Timestamp
  when not matched then insert (Cmplant_ID_Data_Source, L2, Level1, Level2, Actionability, Root_Cause_Theme, Root_Cause_Detail, Honor_Uphold, Initial_PM, Tagging_PM, Tagging_Timestamp)
                        values (a.Cmplant_ID_Data_Source, a.L2, a.Level1, a.Level2, a.Actionability, a.Root_Cause_Theme, a.Root_Cause_Detail, a.Honor_Uphold, a.Initial_PM, a.Tagging_PM, a.Tagging_Timestamp);

COMMIT;
--select * from tagged_raw_transient;
create or replace table card_db_collab.lab_complaints_discovery.tagged_raw as (
select distinct * from tagged_raw_transient
where ((L2 is Not Null) OR (Level1 is Not Null) OR (Level2 is Not Null) OR (Actionability is Not Null) OR (Root_Cause_Theme is Not Null) OR (Root_Cause_Detail is Not Null) OR (Honor_Uphold is Not Null))
);
/* Grant Access to Tagged_Raw Table - Manually maintained list */
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_ehh714_role;
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_IZD571_role;
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_CRY092_role;
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_TFX240_role;
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_HMF187_role;
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_GCX655_role;
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_FUH586_role;
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_WQC801_role;
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_TBS715_role;
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_EIV440_role;
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to SNOW_YBF893_role;
grant select on card_db_collab.lab_channels_complaints.cmplant_pl to SNOW_MCF700_role;
grant select on card_db_collab.lab_complaints_discovery.mapped_drivers to SNOW_MCF700_role;
grant select on card_db_collab.lab_complaints_discovery.mapped_segment to SNOW_MCF700_role;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Part IV - Create Tagged_Final View */--------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
create or replace view card_db_collab.lab_complaints_discovery.tagged_final as(
select Cmplant_ID_Data_Source
,L2
,Level1
,Level2
,Actionability
,coalesce(Root_Cause_Theme,'TBD')
,coalesce(Root_Cause_Detail,'TBD')
,coalesce(Honor_Uphold,'TBD')
,Initial_PM
,Tagging_PM
,Tagging_Timestamp
from card_db_collab.lab_complaints_discovery.tagged_raw
left outer join card_db_collab.lab_channels_complaints.cmplant_pl as b
on upper(a.Cmplant_ID_Data_Source) = upper(b.cmplant_id || b.data_source)
where 
Case 
    When b.DATA_SOURCE='Manual' then dateadd(day,-date_part(day,b.load_date),b.load_date) 
    Else b.DATE_RECEIVED END < $final_end_date

or
(         L2                is not null
  and     Level1            is not null
  and     Level2            is not null
  and     Actionability     is not null
)
);
grant select on card_db_collab.lab_complaints_discovery.tagged_raw to phdp_card_npi;
*/

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Part V - Create Cmplant_Holder */------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
create or replace temporary table card_db_collab.lab_complaints_discovery.temp_cmplant_holder as (

select z.*
,ROW_NUMBER() OVER (PARTITION BY (z.cmplant_id || z.data_source) ORDER BY z.date_received ASC) AS rank_var
from (
select distinct a.*
,b.Mapped_Driver
,c.Mapped_Segment
,c.Mapped_Cnsmr_Type
,Case
    When Upper(cmplant_case_src_desc) = 'CFPB' then 'CFPB'
    When Upper(cmplant_case_src_desc) = 'BETTER BUSINESS BUREAU' then 'BBB'
    When Upper(CMPLANT_CASE_SRC_CATG_DESC) like 'EXECUTIVE%' then 'Executive Outreach'
    Else 'Other Agency'
    End as Mapped_Source
,Case
    When Upper(data_source) = 'OMNIUS' then f.val
    Else a.primary_resolution
    End as combined_primary_resolution
,Case 
    When Upper(combined_primary_resolution) in ('HONOR','HONOR EXEC REV') then 'Honor'
    When Upper(combined_primary_resolution) in ('PARTIAL UPHOLD','PARTIAL UPHOLD EXEC REV') then 'Partial Uphold'
    When Upper(combined_primary_resolution) in ('UPHOLD','UPHOLD EXEC REV') then 'Uphold'
    When Upper(combined_primary_resolution) is Null then 'Null'
    ELSE 'Other'
    End as Mapped_Primary_Resolution
,Case 
    When a.DATA_SOURCE='Manual' then dateadd(day,-date_part(day,a.load_date),a.load_date) 
    Else a.DATE_RECEIVED 
    End as Report_Date
,current_date as Table_Create_Dt
from card_db_collab.lab_channels_complaints.cmplant_pl as a

left outer join card_db_collab.lab_complaints_discovery.mapped_drivers as b
on TRIM(replace(a.primary_driver || a.primary_subdriver,',')) = b.concat_drivers
and Upper(a.Tier) = Upper(b.Tier)

left outer join card_db_collab.lab_complaints_discovery.mapped_segment as c
on TRIM(replace(a.CNSMR_TYPE_DESC || Coalesce(a.SEGMENT,'UNKNOWN'),',')) = TRIM(replace(c.CNSMR_TYPE_DESC || Coalesce(c.SEGMENT,'UNKNOWN'),','))
and Upper(a.Tier) = Upper(c.Tier)

-- Join statements for Omnius Data
left join CARD_DB_COLLAB.lab_channels_complaints.er_cn_fw_case d
on a.cmplant_id = d.case_num
left join CARD_DB_COLLAB.lab_channels_complaints.er_cn_rsltn e
on e.case_id = d.case_id
left join CARD_DB_COLLAB.lab_channels_complaints.er_cn_referencedata f
on e.rsltn_ctgry = f.id
left join CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.ER_CN_CMPLNT as actn
on d.case_id = actn.case_id
left join card_db_collab.lab_channels_complaints.er_cn_referencedata as actn_map
on actn.empl_mscndct_flg = actn_map.id

where report_date between $start_date and $end_date
and Upper(a.Tier) = 'TIER 3'
and upper(a.cmplant_id || a.data_source) not in (select distinct upper(Cmplant_ID_Data_Source) from card_db_collab.lab_complaints_discovery.tagged_raw where ((L2 is Not Null) AND (Level1 is Not Null) AND (Level2 is Not Null) AND (Actionability is Not Null) AND (Root_Cause_Theme is Not Null) AND (Root_Cause_Detail is Not Null) AND (Honor_Uphold is Not Null)))
/*
 * Adding actionability via Ominus case management system
 * 
 * beginning approximately ~10/15/2020, associates will begin determining actionability
 * within Omnius 2.0 case details. This clause is being added to prevent those already determined
 * from entering into this actionability process.
 *
 * - FIT392, 2020-10-21
 */
and (actn_map.val ilike any ('Yes', 'No', 'NA') or actn_map.val is null)
) as z
);

create or replace table card_db_collab.lab_complaints_discovery.cmplant_holder as (
select CMPLANT_ID
,ACCT_ID
,ACCT_INFO_TXT
,LOB
,LEAF_LOB
,CMPLANT_CATEGORY
,PRIMARY_DRIVER
,PRIMARY_SUBDRIVER
,AGENT_EID
,DATE_RECEIVED
,DATE_CLOSED
,LOAD_DATE
,REPORTING_CHANNEL
,CMPLANT_CATG_DESC
,CMPLANT_CASE_SRC_DESC
,CMPLANT_CASE_SRC_CATG_DESC
,CNSMR_TYPE_DESC
,CASE_STATUS
,IB_CNTCT_CHNL_DESC
,OB_CNTCT_CHNL_DESC
,CMPLANT_CMNT_TXT
,PRIMARY_RESOLUTION
,DATA_SOURCE
,FEEDBACK_TYPE
,BBFLAG
,TIER
,DRIVER_CATEGORY
,ECP_CATEGORY
,SEGMENT
,BRAND
,TRIP_IND
,ACCT_AGE
,STATUS
,PD
,PARTNER
,MAPPED_DRIVER
,MAPPED_SEGMENT
,MAPPED_CNSMR_TYPE
,MAPPED_SOURCE
,COMBINED_PRIMARY_RESOLUTION
,MAPPED_PRIMARY_RESOLUTION
,REPORT_DATE
,TABLE_CREATE_DT
from card_db_collab.lab_complaints_discovery.temp_cmplant_holder
where rank_var = 1
);

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Part VI - Get New Data */--------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--select * from card_db_collab.lab_complaints_discovery.tagged_raw where cmplant_id_data_source = '020050109014539Omnius';
--select * from card_db_collab.lab_complaints_discovery.cmplant_holder where cmplant_id = '20050109014539';
--select * from tagging_data where cmplant_id = '20050109014539';

create or replace table card_db_collab.lab_complaints_discovery.tagging_data as (select distinct
cmplant_id
,Case
    When Upper(b.Tagging_PM) = 'VIT200' then 'Katelyn'
    When Upper(b.Tagging_PM) = 'HMF187' then 'Lauren'
    When Upper(b.Tagging_PM) = 'FXQ298' then 'Megan'
    When Upper(b.Tagging_PM) = 'DMF634' then 'Tyler'
    When Upper(b.Tagging_PM) = 'TVN385' then 'Wendy'
    When Upper(b.Tagging_PM) = 'LEP775' then 'Ki'
    When Upper(b.Tagging_PM) = 'FLJ016' then 'Nean'
    When Upper(b.Tagging_PM) = 'TKH726' then 'Monico'
    When Upper(b.Tagging_PM) = 'EIV440' then 'Tomeka'
    When date_received < '2018-10-01' and Upper(Mapped_Driver) in ('CLD - RISK MGMT','CLIP','CLOSURE','FC & APR','FEES','INTEREST SAVINGS PROGRAM (ISP)','COLLECTIONS','RECOVERIES','CREDIT BUREAUS','PAYMENTS','SYSTEM') and Upper(BBFLAG) = 'BB' then 'Monico'
    When date_received < '2018-10-01' and Upper(Mapped_Driver) in ('AUTHORIZATIONS','CROSS SELL/CARD FEATURES','DISPUTES','FRAUD','FULFILLMENT','REWARDS','SERVICING','SCRA / ADA','SECURED CARD','DECISIONING','MARKETING / PRIVACY','OTHER (TBD)') and Upper(BBFLAG) = 'BB' then 'Nean'
    When date_received < '2018-10-01' and Upper(BBFLAG) = 'PA' then 'Nean'
    When Upper(Mapped_Driver) in ('AUTHORIZATIONS','CREDIT BUREAUS','FRAUD') and Upper(BBFLAG) = 'BB' then 'Katelyn'
    When Upper(Mapped_Driver) in ('PAYMENTS','REWARDS') and Upper(BBFLAG) = 'BB' then 'Megan'
    When Upper(Mapped_Driver) in ('COLLECTIONS','RECOVERIES','SCRA / ADA','SERVICING','SYSTEM') and Upper(BBFLAG) = 'BB' then 'Tyler'
    When Upper(Mapped_Driver) in ('CLD - RISK MGMT','CLIP','CLOSURE','CROSS SELL/CARD FEATURES','DECISIONING','FC & APR','FEES','INTEREST SAVINGS PROGRAM (ISP)','MARKETING / PRIVACY','SECURED CARD') and Upper(BBFLAG) = 'BB' then 'Wendy'
    When Upper(Mapped_Driver) in ('FULFILLMENT','DISPUTES') and Upper(BBFLAG) = 'BB' then 'Tomeka'
    When Upper(BBFLAG) = 'PA' and upper(cnsmr_type_desc) like '%WALMART%' then 'Megan'
    When Upper(BBFLAG) = 'PA' then 'Ki'
    Else NULL
    End as Current_PM
,acct_id
,case_status
,regexp_replace(coalesce(cmplant_cmnt_txt,'') || ' ' || coalesce(primary_resolution,''),'(\\d{4}[- _.]?\\d{4}[- _.]?\\d{4}[- _.]?\\d{4})|(\\d{3}[- _.]\\d{3}[- _.]\\d{4})|(\\d{10})|(\\d{3}[- _.]\\d{2}[- _.]\\d{4})|(\\d{9})','PCI_NPI_REMOVED') as cmplant_cmnt_txt
,replace(b.L2,' ','_') as L2_new
,replace(b.Level1,' ','_') as Level1_new
,replace(b.Level2,' ','_') as Level2_new
,b.Actionability as Actionability_new
,b.Root_Cause_Theme as Root_Cause_Theme_new
,b.Root_Cause_Detail as Root_Cause_Detail_new
,b.Honor_Uphold as Honor_Uphold_new
,a.Cmplant_ID || a.Data_Source as Cmplant_ID_Data_Source
,Mapped_Cnsmr_Type
,data_source
,Mapped_Driver
,Mapped_Primary_Resolution
,Mapped_Segment
,Mapped_Source
,date_trunc('MONTH',report_date) as Year_Month
,primary_driver
,primary_subdriver
,report_date
,Case
    When Upper(b.Initial_PM) = 'VIT200' then 'Katelyn'
    When Upper(b.Initial_PM) = 'HMF187' then 'Lauren'
    When Upper(b.Initial_PM) = 'FXQ298' then 'Megan'
    When Upper(b.Initial_PM) = 'DMF634' then 'Tyler'
    When Upper(b.Initial_PM) = 'TVN385' then 'Wendy'
    When Upper(b.Initial_PM) = 'LEP775' then 'Ki'
    When Upper(b.Initial_PM) = 'FLJ016' then 'Nean'
    When Upper(b.Initial_PM) = 'TKH726' then 'Monico'
    When Upper(b.Initial_PM) = 'EIV440' then 'Tomeka'
    Else Current_PM
    End as Initial_PM
,Coalesce(b.Initial_PM,
Case
    When date_received < '2018-10-01' and Upper(Mapped_Driver) in ('CLD - RISK MGMT','CLIP','CLOSURE','FC & APR','FEES','INTEREST SAVINGS PROGRAM (ISP)','COLLECTIONS','RECOVERIES','CREDIT BUREAUS','PAYMENTS','SYSTEM') and Upper(BBFLAG) = 'BB' then 'TKH726'
    When date_received < '2018-10-01' and Upper(Mapped_Driver) in ('AUTHORIZATIONS','CROSS SELL/CARD FEATURES','DISPUTES','FRAUD','FULFILLMENT','REWARDS','SERVICING','SCRA / ADA','SECURED CARD','DECISIONING','MARKETING / PRIVACY','OTHER (TBD)') and Upper(BBFLAG) = 'BB' then 'FLJ016'
    When date_received < '2018-10-01' and Upper(BBFLAG) = 'PA' then 'FLJ016'
    When Upper(Mapped_Driver) in ('AUTHORIZATIONS','CREDIT BUREAUS','FRAUD') and Upper(BBFLAG) = 'BB' then 'VIT200'
    When Upper(Mapped_Driver) in ('PAYMENTS','REWARDS') and Upper(BBFLAG) = 'BB' then 'FXQ298'
    When Upper(Mapped_Driver) in ('COLLECTIONS','RECOVERIES','SCRA / ADA','SERVICING','SYSTEM') and Upper(BBFLAG) = 'BB' then 'DMF634'
    When Upper(Mapped_Driver) in ('CLD - RISK MGMT','CLIP','CLOSURE','CROSS SELL/CARD FEATURES','DECISIONING','FC & APR','FEES','INTEREST SAVINGS PROGRAM (ISP)','MARKETING / PRIVACY','SECURED CARD') and Upper(BBFLAG) = 'BB' then 'TVN385'
    When Upper(Mapped_Driver) in ('FULFILLMENT','DISPUTES') and Upper(BBFLAG) = 'BB' then 'EIV440'
    When Upper(BBFLAG) = 'PA' and upper(cnsmr_type_desc) like '%WALMART%' then 'FXQ298'
    When Upper(BBFLAG) = 'PA' then 'LEP775'
    Else NULL
    End ) as Initial_PM_EID
,coalesce(b.Tagging_PM,Initial_PM_EID) as Current_PM_EID
,b.Tagging_Timestamp
from card_db_collab.lab_complaints_discovery.cmplant_holder as a
Left outer join card_db_collab.lab_complaints_discovery.tagged_raw as b
on Upper(b.Cmplant_ID_Data_Source) = Upper('0' || a.Cmplant_ID || a.Data_Source)
or Upper(b.Cmplant_ID_Data_Source) = Upper(a.Cmplant_ID || a.Data_Source)
where   L2_new                is null
or      Level1_new            is null
or      Level2_new            is null
or      Actionability_new     is null
or      root_cause_theme_new  is null
or      root_cause_detail_new is null
or      honor_uphold_new      is null
order by report_date asc);
select * from card_db_collab.lab_complaints_discovery.tagging_data;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Part VII - Create Data Extract */------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Create Temporary PL with Added Fields */
create or replace table card_db_collab.lab_complaints_discovery.temp_extract_cmplant_pl as (
select z.*
,ROW_NUMBER() OVER (PARTITION BY (z.cmplant_id || z.data_source) ORDER BY z.date_received ASC) AS rank_var
from (
select distinct a.*
,date_trunc('MONTH',a.date_received) as Year_Month
,Case
    When Upper(data_source) = 'OMNIUS' then f.val
    Else a.primary_resolution
    End as combined_primary_resolution
,Case 
    When Upper(combined_primary_resolution) in ('HONOR','HONOR EXEC REV') then 'Honor'
    When Upper(combined_primary_resolution) in ('PARTIAL UPHOLD','PARTIAL UPHOLD EXEC REV') then 'Partial Uphold'
    When Upper(combined_primary_resolution) in ('UPHOLD','UPHOLD EXEC REV') then 'Uphold'
    When Upper(combined_primary_resolution) is Null then 'Null'
    ELSE 'Other'
    End as Mapped_Primary_Resolution
,b.Mapped_Driver
,c.Mapped_Segment
,c.Mapped_Cnsmr_Type
,Case
    When Upper(cmplant_case_src_desc) = 'CFPB' then 'CFPB'
    When Upper(cmplant_case_src_desc) = 'BETTER BUSINESS BUREAU' then 'BBB'
    When Upper(CMPLANT_CASE_SRC_CATG_DESC) like 'EXECUTIVE%' then 'Executive Outreach'
    Else 'Other Agency'
    End as Mapped_Source
,case when a.DATA_SOURCE='Manual' then dateadd(day,-date_part(day,a.load_date),a.load_date) else a.DATE_RECEIVED end as report_date
,current_date as Table_Create_Dt
from card_db_collab.lab_channels_complaints.cmplant_pl as a

left outer join card_db_collab.lab_complaints_discovery.mapped_drivers as b
on TRIM(replace(a.primary_driver || a.primary_subdriver,',')) = b.concat_drivers
and Upper(a.Tier) = Upper(b.Tier)

left outer join card_db_collab.lab_complaints_discovery.mapped_segment as c
on TRIM(replace(a.CNSMR_TYPE_DESC || Coalesce(a.SEGMENT,'UNKNOWN'),',')) = TRIM(replace(c.CNSMR_TYPE_DESC || Coalesce(c.SEGMENT,'UNKNOWN'),','))
and Upper(a.Tier) = Upper(c.Tier)

-- Join statements for Omnius Data
left join CARD_DB_COLLAB.lab_channels_complaints.er_cn_fw_case d
on a.cmplant_id = d.case_num
left join CARD_DB_COLLAB.lab_channels_complaints.er_cn_rsltn e
on e.case_id = d.case_id
left join CARD_DB_COLLAB.lab_channels_complaints.er_cn_referencedata f
on e.rsltn_ctgry = f.id
left join CARD_DB_COLLAB.LAB_CHANNELS_COMPLAINTS.ER_CN_CMPLNT as actn
on d.case_id = actn.case_id
left join card_db_collab.lab_channels_complaints.er_cn_referencedata as actn_map
on actn.empl_mscndct_flg = actn_map.id

/*
 * Adding actionability via Ominus case management system
 * 
 * beginning approximately ~10/15/2020, associates will begin determining actionability
 * within Omnius 2.0 case details. This clause is being added to prevent those already determined
 * from entering into this actionability process.
 *
 * - FIT392, 2020-10-21
 */
where (actn_map.val ilike any ('Yes', 'No', 'NA') or actn_map.val is null)
) as z
);

create or replace table card_db_collab.lab_complaints_discovery.temp_cmplant_pl_1 as (
select CMPLANT_ID
,ACCT_ID
,ACCT_INFO_TXT
,LOB
,LEAF_LOB
,CMPLANT_CATEGORY
,PRIMARY_DRIVER
,PRIMARY_SUBDRIVER
,AGENT_EID
,DATE_RECEIVED
,DATE_CLOSED
,LOAD_DATE
,REPORTING_CHANNEL
,CMPLANT_CATG_DESC
,CMPLANT_CASE_SRC_DESC
,CMPLANT_CASE_SRC_CATG_DESC
,CNSMR_TYPE_DESC
,CASE_STATUS
,IB_CNTCT_CHNL_DESC
,OB_CNTCT_CHNL_DESC
,replace(CMPLANT_CMNT_TXT,'<br>',' ') as CMPLANT_CMNT_TXT
,replace(PRIMARY_RESOLUTION,'<br>',' ') as PRIMARY_RESOLUTION
,DATA_SOURCE
,FEEDBACK_TYPE
,BBFLAG
,TIER
,DRIVER_CATEGORY
,ECP_CATEGORY
,SEGMENT
,BRAND
,TRIP_IND
,ACCT_AGE
,STATUS
,PD
,PARTNER
,MAPPED_DRIVER
,MAPPED_SEGMENT
,MAPPED_CNSMR_TYPE
,MAPPED_SOURCE
,COMBINED_PRIMARY_RESOLUTION
,MAPPED_PRIMARY_RESOLUTION
,REPORT_DATE
,TABLE_CREATE_DT
from card_db_collab.lab_complaints_discovery.temp_extract_cmplant_pl
where rank_var = 1
);


create or replace table card_db_collab.lab_complaints_discovery.data_extract as (
select distinct
cmplant_id
,Case
    When Upper(b.Tagging_PM) = 'VIT200' then 'Katelyn'
    When Upper(b.Tagging_PM) = 'HMF187' then 'Lauren'
    When Upper(b.Tagging_PM) = 'FXQ298' then 'Megan'
    When Upper(b.Tagging_PM) = 'DMF634' then 'Tyler'
    When Upper(b.Tagging_PM) = 'TVN385' then 'Wendy'
    When Upper(b.Tagging_PM) = 'LEP775' then 'Ki'
    When Upper(b.Tagging_PM) = 'FLJ016' then 'Nean'
    When Upper(b.Tagging_PM) = 'TKH726' then 'Monico'
    When date_received < '2018-10-01' and Upper(Mapped_Driver) in ('CLD - RISK MGMT','CLIP','CLOSURE','FC & APR','FEES','INTEREST SAVINGS PROGRAM (ISP)','COLLECTIONS','RECOVERIES','CREDIT BUREAUS','PAYMENTS','SYSTEM') and Upper(BBFLAG) = 'BB' then 'Monico'
    When date_received < '2018-10-01' and Upper(Mapped_Driver) in ('AUTHORIZATIONS','CROSS SELL/CARD FEATURES','DISPUTES','FRAUD','FULFILLMENT','REWARDS','SERVICING','SCRA / ADA','SECURED CARD','DECISIONING','MARKETING / PRIVACY','OTHER (TBD)') and Upper(BBFLAG) = 'BB' then 'Nean'
    When date_received < '2018-10-01' and Upper(BBFLAG) = 'PA' then 'Nean'
    When Upper(Mapped_Driver) in ('AUTHORIZATIONS','CREDIT BUREAUS','FRAUD') and Upper(BBFLAG) = 'BB' then 'Katelyn'
    When Upper(Mapped_Driver) in ('PAYMENTS','REWARDS') and Upper(BBFLAG) = 'BB' then 'Megan'
    When Upper(Mapped_Driver) in ('COLLECTIONS','RECOVERIES','SCRA / ADA','SERVICING','SYSTEM') and Upper(BBFLAG) = 'BB' then 'Tyler'
    When Upper(Mapped_Driver) in ('CLD - RISK MGMT','CLIP','CLOSURE','CROSS SELL/CARD FEATURES','DECISIONING','FC & APR','FEES','INTEREST SAVINGS PROGRAM (ISP)','MARKETING / PRIVACY','SECURED CARD') and Upper(BBFLAG) = 'BB' then 'Wendy'
    When Upper(Mapped_Driver) in ('DISPUTES','FULFILLMENT') and Upper(BBFLAG) = 'BB' then 'Megan'
    When Upper(BBFLAG) = 'PA' and upper(cnsmr_type_desc) like '%WALMART%' then 'Megan'
    When Upper(BBFLAG) = 'PA' then 'Ki'
    Else NULL
    End as Current_PM
,acct_id
,case_status
,regexp_replace(coalesce(cmplant_cmnt_txt,'') || ' ' || coalesce(primary_resolution,''),'(\\d{4}[- _.]?\\d{4}[- _.]?\\d{4}[- _.]?\\d{4})|(\\d{3}[- _.]\\d{3}[- _.]\\d{4})|(\\d{10})|(\\d{3}[- _.]\\d{2}[- _.]\\d{4})|(\\d{9})','PCI_NPI_REMOVED') as cmplant_cmnt_txt
,replace(b.L2,'_',' ') as L2_new
,replace(b.Level1,'_',' ') as Level1_new
,replace(b.Level2,'_',' ') as Level2_new
,b.Actionability as Actionability_new
,b.Root_Cause_Theme as Root_Cause_Theme_new
,b.Root_Cause_Detail as Root_Cause_Detail_new
,b.Honor_Uphold as Honor_Uphold_new
,a.Cmplant_ID || a.Data_Source as Cmplant_ID_Data_Source
,Mapped_Cnsmr_Type
,data_source
,Mapped_Driver
,Mapped_Primary_Resolution
,Mapped_Segment
,Mapped_Source
,date_trunc('MONTH',report_date) as Year_Month
,primary_driver
,primary_subdriver
,report_date
,Case
    When Upper(b.Initial_PM) = 'VIT200' then 'Katelyn'
    When Upper(b.Initial_PM) = 'HMF187' then 'Lauren'
    When Upper(b.Initial_PM) = 'FXQ298' then 'Megan'
    When Upper(b.Initial_PM) = 'DMF634' then 'Tyler'
    When Upper(b.Initial_PM) = 'TVN385' then 'Wendy'
    When Upper(b.Initial_PM) = 'LEP775' then 'Ki'
    When Upper(b.Initial_PM) = 'FLJ016' then 'Nean'
    When Upper(b.Initial_PM) = 'TKH726' then 'Monico'
    When Upper(b.Initial_PM) = 'EIV440' then 'Tomeka'
    Else Current_PM
    End as Initial_PM
,Coalesce(b.Initial_PM,
Case
    When date_received < '2018-10-01' and Upper(Mapped_Driver) in ('CLD - RISK MGMT','CLIP','CLOSURE','FC & APR','FEES','INTEREST SAVINGS PROGRAM (ISP)','COLLECTIONS','RECOVERIES','CREDIT BUREAUS','PAYMENTS','SYSTEM') and Upper(BBFLAG) = 'BB' then 'TKH726'
    When date_received < '2018-10-01' and Upper(Mapped_Driver) in ('AUTHORIZATIONS','CROSS SELL/CARD FEATURES','DISPUTES','FRAUD','FULFILLMENT','REWARDS','SERVICING','SCRA / ADA','SECURED CARD','DECISIONING','MARKETING / PRIVACY','OTHER (TBD)') and Upper(BBFLAG) = 'BB' then 'FLJ016'
    When date_received < '2018-10-01' and Upper(BBFLAG) = 'PA' then 'FLJ016'
    When Upper(Mapped_Driver) in ('AUTHORIZATIONS','CREDIT BUREAUS','FRAUD') and Upper(BBFLAG) = 'BB' then 'VIT200'
    When Upper(Mapped_Driver) in ('PAYMENTS','REWARDS') and Upper(BBFLAG) = 'BB' then 'FXQ298'
    When Upper(Mapped_Driver) in ('COLLECTIONS','RECOVERIES','SCRA / ADA','SERVICING','SYSTEM') and Upper(BBFLAG) = 'BB' then 'DMF634'
    When Upper(Mapped_Driver) in ('CLD - RISK MGMT','CLIP','CLOSURE','CROSS SELL/CARD FEATURES','DECISIONING','FC & APR','FEES','INTEREST SAVINGS PROGRAM (ISP)','MARKETING / PRIVACY','SECURED CARD') and Upper(BBFLAG) = 'BB' then 'TVN385'
    When Upper(Mapped_Driver) in ('FULFILLMENT', 'DISPUTES') and Upper(BBFLAG) = 'BB' then 'EIV440'
    When Upper(BBFLAG) = 'PA' and upper(cnsmr_type_desc) like '%WALMART%' then 'FXQ298'
    When Upper(BBFLAG) = 'PA' then 'LEP775'
    Else NULL
    End ) as Initial_PM_EID
,coalesce(b.Tagging_PM,Initial_PM_EID) as Current_PM_EID
,b.Tagging_Timestamp

from card_db_collab.lab_complaints_discovery.temp_cmplant_pl_1 as a

Join card_db_collab.lab_complaints_discovery.tagged_raw as b
on Upper(a.Cmplant_ID || a.Data_Source) = Upper(b.Cmplant_ID_Data_Source)
order by report_date asc);


/* Create Data Extract for SFS O Drive */

/*WbExport  -type=xlsx
          -file='C:/Users/aik604/Downloads/All T3 Complaints With Tagging Data_Export.xlsx'
          -encoding=utf-8;
*/          
Select * from card_db_collab.lab_complaints_discovery.data_extract where L2_NEW <> 'Tier 2';
--select * from card_db_collab.lab_complaints_discovery.tagged_raw;
--select tagging_timestamp, count(*) from card_db_collab.lab_complaints_discovery.data_extract group by 1 order by 1 asc;

--select date_received, count(distinct cmplant_id) from card_db_collab.lab_channels_complaints.cmplant_pl where tier = 'Tier 3' group by 1 order by 1 desc;
