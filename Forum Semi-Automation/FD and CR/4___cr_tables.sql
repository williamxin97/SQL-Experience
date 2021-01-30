
-----------
CREATE OR REPLACE Temporary TABLE cr_complaints_holder as (

select a.*
,case when a.DATA_SOURCE = 'Manual' then dateadd(day,-date_part(day,a.load_date),a.load_date) else a.DATE_RECEIVED end as report_date
,d.cost_ctr_id
,CASE When Upper(a.Tier) = 'TIER 3' and Upper(a.Primary_Driver) in ('COLLECTIONS','COLLECTIONS - EXTERNAL','COLLECTIONS - INTERNAL','HARDSHIP','THIRD PARTY DEBT MANAGEMENT') then 'COLLECTIONS'
      When Upper(a.Tier) = 'TIER 3' and Upper(a.Primary_Driver) in ('ACCOUNT CODED CORRECTLY','ACCOUNT NOT CODED CORRECTLY','ASSET SALES','BANKRUPTCY - DISCHARGED','BANKRUPTCY - NOTICE OF INTENT TO FILE','DECEASED ACCOUNTHOLDERS','IRS FORMS','LEGAL PROCESSING','LEGAL PROCESS','RECOVERIES','RECOVERIES - EXTERNAL','RECOVERIES - INTERNAL','REPOSSESSION') then 'RECOVERIES' 
      When Upper(a.Tier) in ('TIER 2', 'TIER 1') and COST_CTR_ID in ('13630','13635','13103','13063','13634','13636','13120','13125','13170','13126','14293','13075','13631','13061','13124','13151','14942','13072','13076','13667','13082','13629','14245') then 'COLLECTIONS'
      When Upper(a.Tier) in ('TIER 2', 'TIER 1') and COST_CTR_ID in ('13190','13191','13192','13193','13194','13658','13195') then 'RECOVERIES'
      When Upper(a.Tier) = 'TIER 1' and Upper(a.CNSMR_TYPE_DESC) in ('RECOVERIES LEGAL','RECOVERIES FIRMS','RECOVERIES AGENCIES','RECOVERIES CONTINGENCY','RECOVERIES DCM','RECOVERIES') then 'RECOVERIES'
      Else Null
      End as Coll_Recov_Ind
,e.Mapped_Driver
,f.Mapped_Segment
,f.Mapped_Cnsmr_Type

from Card_DB_Collab.lab_channels_complaints.cmplant_pl_bb as a

left outer join HRDW_DB.PHDP_HR_NONAPI_NO_UK.ENT_WORKR_PT as d
on UPPER(a.agent_eid) = UPPER(d.emp_ent_user_id)
and a.date_received = d.snap_dt

left outer join card_db_collab.lab_complaints_discovery.mapped_drivers as e --b
on TRIM(replace(a.primary_driver || a.primary_subdriver,',')) = e.concat_drivers
and Upper(a.Tier) = Upper(e.Tier)

left outer join card_db_collab.lab_complaints_discovery.mapped_segment as f --c
on TRIM(replace(a.CNSMR_TYPE_DESC || Coalesce(a.SEGMENT,'UNKNOWN'),',')) = TRIM(replace(f.CNSMR_TYPE_DESC || Coalesce(f.SEGMENT,'UNKNOWN'),','))
and Upper(a.Tier) = Upper(f.Tier)

Where report_date between dateadd(month,-16,date_trunc('month',current_date)) and  dateadd(day,-1,date_trunc('month',current_date))
and UPPER(Coll_Recov_Ind) in ('COLLECTIONS','RECOVERIES')

UNION

select a.*
,case when a.DATA_SOURCE = 'Manual' then dateadd(day,-date_part(day,a.load_date),a.load_date) else a.DATE_RECEIVED end as report_date
,d.cost_ctr_id
,CASE When Upper(a.Tier) = 'TIER 3' and Upper(a.Primary_Driver) in ('COLLECTIONS','COLLECTIONS - EXTERNAL','COLLECTIONS - INTERNAL','HARDSHIP','THIRD PARTY DEBT MANAGEMENT') then 'COLLECTIONS'
      When Upper(a.Tier) = 'TIER 3' and Upper(a.Primary_Driver) in ('ACCOUNT CODED CORRECTLY','ACCOUNT NOT CODED CORRECTLY','ASSET SALES','BANKRUPTCY - DISCHARGED','BANKRUPTCY - NOTICE OF INTENT TO FILE','DECEASED ACCOUNTHOLDERS','IRS FORMS','LEGAL PROCESSING','LEGAL PROCESS','RECOVERIES','RECOVERIES - EXTERNAL','RECOVERIES - INTERNAL','REPOSSESSION') then 'RECOVERIES' 
      When Upper(a.Tier) in ('TIER 2', 'TIER 1') and COST_CTR_ID in ('13630','13635','13103','13063','13634','13636','13120','13125','13170','13126','14293','13075','13631','13061','13124','13151','14942','13072','13076','13667','13082','13629','14245') then 'COLLECTIONS'
      When Upper(a.Tier) in ('TIER 2', 'TIER 1') and COST_CTR_ID in ('13190','13191','13192','13193','13194','13658','13195') then 'RECOVERIES'
      When Upper(a.Tier) = 'TIER 1' and Upper(a.CNSMR_TYPE_DESC) in ('RECOVERIES LEGAL','RECOVERIES FIRMS','RECOVERIES AGENCIES','RECOVERIES CONTINGENCY','RECOVERIES DCM','RECOVERIES') then 'RECOVERIES'
      Else Null
      End as Coll_Recov_Ind
,e.Mapped_Driver
,f.Mapped_Segment
,f.Mapped_Cnsmr_Type

from Card_DB_Collab.lab_channels_complaints.cmplant_pl as a

left outer join HRDW_DB.PHDP_HR_NONAPI_NO_UK.ENT_WORKR_PT as d
on UPPER(a.agent_eid) = UPPER(d.emp_ent_user_id)
and a.date_received = d.snap_dt

left outer join card_db_collab.lab_complaints_discovery.mapped_drivers as e --b
on TRIM(replace(a.primary_driver || a.primary_subdriver,',')) = e.concat_drivers
and Upper(a.Tier) = Upper(e.Tier)

left outer join card_db_collab.lab_complaints_discovery.mapped_segment as f --c
on TRIM(replace(a.CNSMR_TYPE_DESC || Coalesce(a.SEGMENT,'UNKNOWN'),',')) = TRIM(replace(f.CNSMR_TYPE_DESC || Coalesce(f.SEGMENT,'UNKNOWN'),','))
and Upper(a.Tier) = Upper(f.Tier)

Where report_date between dateadd(month,-16,date_trunc('month',current_date)) and  dateadd(day,-1,date_trunc('month',current_date))
and UPPER(Coll_Recov_Ind) in ('COLLECTIONS','RECOVERIES')
);

CREATE OR REPLACE temporary TABLE w_cr_complaints as (

Select a.*
,b.DEBT_MGR_RTR_ACCT_NUM as Router
,c.HOME_RTR_CD
,c.CLASS_1_STAT_CD
,c.PLCMT_STRT_DT
,c.PLCMT_END_DT
,e.*
--Case Statement that uses the CLIO Primary_Subdriver to determine the Non-Collections or Recoveries Primary Driver
,CASE When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ACCOUNT_INFORMATION_AVAILABLE_CREDIT' then 'Account Information'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ACCOUNT_INFORMATION_BALANCE' then 'Account Information'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ACCOUNT_INFORMATION_PERSONAL_INFORMATION' then 'Account Information'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ACCOUNT_STATUS_CLOSE_ACCOUNT' then 'Account Status'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ACCOUNT_STATUS_DECEASED_ESTATES' then 'Account Status'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ACCOUNT_STATUS_OTHER' then 'Account Status'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ACCOUNT_STATUS_RESTRICTED_OR_SUSPENDED_ACCOUNT' then 'Account Status'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ACCOUNT_TERMS_APR' then 'FC & APR'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ACCOUNT_TERMS_CREDIT_LIMIT' then 'Line Management (CLIP & CLD)'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ACCOUNT_TERMS_REWARDS' then 'Rewards'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'AUTHORIZATIONS' then 'Authorizations'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'BALANCE_TRANSFER' then 'Interest Savings Program (ISP)'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'BALANCE_TRANSFER_APR' then 'Interest Savings Program (ISP)'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'CARD_DELIVERY_AND_ISSUANCE' then 'Fulfillment'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'CARD_NOT_WORKING_DECLINED' then 'Authorizations'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'CASH_ADVANCE_AND_PIN' then 'System'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'CASH_ADVANCE_FEES' then 'Fees'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'CREDIT_BUREAUS' then 'Credit Bureaus'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'DISPUTES_MERCHANT_BLOCK' then 'Authorizations'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'DISPUTES_POLICIES_PROCEDURES' then 'Disputes'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'DISPUTES_REBILLED' then 'Disputes'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'DISPUTES_RECURRING_CHARGES' then 'Payments'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'DISPUTES_TIME_TO_RESOLVE' then 'Disputes'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'FINANCE_INTEREST_CHARGES' then 'FC & APR'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'FRAUD_ACCOUNT_COMPROMISE' then 'Fraud'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'FRAUD_CONCERN_OR_MESSAGING' then 'Fraud'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'FRAUD_DID_NOT_APPLY_FOR_ACCOUNT' then 'Fraud'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'FRAUD_LOST_STOLEN_CARD' then 'Fraud'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'FRAUD_REBILLED' then 'Fraud'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'FRAUD_TIME_TO_RESOLVE' then 'Fraud'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'MEMBERSHIP_FEES' then 'Fees'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'ONLINE_ENROLLMENT_ACCESS_ISSUES' then 'System'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PASSWORD_RESET_ONE_TIME_PIN' then 'System'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PAST_DUE_AND_OVERLIMIT_FEES' then 'Fees'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PAY_BY_PHONE' then 'Payments'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PAYMENT_CALCULATIONS' then 'Payments'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PAYMENT_ERRORS' then 'Payments'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PAYMENT_HOLD' then 'Payments'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PAYMENT_OPTIONS' then 'Payments'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PAYMENT_POSTING_TIMEFRAMES' then 'Payments'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PAYMENTS_DUE_DATE' then 'Fulfillment'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PRIVACY' then 'Privacy'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'PRODUCT' then 'Product'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'REWARDS_REDEMPTION' then 'Rewards'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'STATEMENTS' then 'Fulfillment'
      When upper(data_source) like 'T1%' AND upper(Primary_Subdriver) = 'TRAVEL_NOTIFICATION' then 'Authorizations'
      When upper(data_source) like 'T1%' then 'Other (TBD)' --Captures any additional CLIO Values not in the above Case Statement
      When upper(tier) = 'TIER 1' then Primary_Driver --If Tier 1 Inquiry is not using CLIO Values (ie. Tagged by an Agent) we want to pull in that Primary_Driver to create a singular field
      ELSE Null --Null values for Tier 2 and Tier 3
      End as Non_CR_CLIO_Primary_Driver

from cr_complaints_holder as a

left outer join DB.PRDM.RCVRY_ACCT as b
on a.ACCT_ID = b.SRC_SYS_ACCT_ID

left outer join DB.PRDM.RCVRY_ACCT_AGY_PLCMT as c 
on b.DEBT_MGR_RTR_ACCT_NUM = c.DEBT_MGR_RTR_ACCT_NUM
and a.DATE_RECEIVED	between c.PLCMT_STRT_DT and IFNULL(c.PLCMT_END_DT, current_date)

left outer join Card_Db_Collab.lab_complaints_discovery.tagged_raw as e
on Upper(e.cmplant_id_data_source) = Upper(a.cmplant_id||a.data_source) 

);
