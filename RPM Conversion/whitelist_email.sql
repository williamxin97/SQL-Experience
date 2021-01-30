--Driver table for all cycling (non-dormant) RPM accounts
create or replace table rpm_driver as (
select a.arr_id_chain
from DB.PPDW_CREDIT.ARR_PERFM_SNAP_EOC a
LEFT JOIN DB.PPDW_CREDIT.ARR_SNAP_DLY E
ON A.ARR_ID_CHAIN = E.ARR_ID_CHAIN
--WHERE A.MEAS_PRD_ID = concat(extract(YEAR from current_date - 14),LPAD(extract(MONTH from current_date - 14),2,'0')) --run before 13th of month to get previous month data
where a.meas_prd_id = '202009'
AND E.ATH_CURR_ACCT_IND = '1'
AND E.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and E.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
 --Exclude Neiman and Bergdorf Goodman
and E.ORG_CDE NOT IN ('601')--Exclude Lord and Taylor and Saks
AND E.ATH_CURR_ACCT_IND = '1'
);

--Attach latest email addresses to each account
create or replace table rpm_email as (
select a.arr_id_chain,
h.EMAIL_ADDR_N1_TEXT,h.EMAIL_ADDR_N2_TEXT,
CASE
WHEN A.ORG_CDE IN ('004','005','202','226','601','602','855','857') THEN 'Active'
ELSE 'Inactive' END AS PARTNER_STATUS,
F.ORG_DESC as Partner,
A.ORG_CDE as ORG_CD,
h.start_addr_dt, case when A.DLQ_STAT_CDE in ('00','01') then 00 else A.DLQ_STAT_CDE-1 end as Bucket
FROM DB.PPDW_CREDIT.ARR_SNAP_DLY A
LEFT JOIN DB.PPDW.PTNR D
ON A.PTNR_ID = D.PTNR_ID
LEFT JOIN DB.PPDW.ORG_CDE F
ON A.ORG_CDE = F.ORG_CDE
left join db.ppdw_secured.arr_addr_eom h
on a.arr_id_chain = h.arr_id_chain
and h.start_addr_dt = (select max(start_addr_dt) from db.ppdw.arr_addr_eom i where i.arr_id_chain = h.arr_id_chain)
WHERE A.ATH_CURR_ACCT_IND = '1'
AND A.ARR_ID_CHAIN in (select distinct ARR_ID_CHAIN from rpm_driver)
AND A.ORG_CDE NOT IN ('190','192','193') -- Exclude Canada
and A.ORG_CDE NOT IN ('202','855','857') --Exclude Helzberg, Justice and Maurices
and A.ORG_CDE NOT IN ('004','005') --Exclude Neiman and Bergdorf Goodman
and A.ORG_CDE NOT IN ('601', '602')--Exclude Lord and Taylor and Saks
AND A.ATH_CURR_ACCT_IND = '1'
);

--select DLQ_STAT_CDE from DB.PPDW_CREDIT.ARR_SNAP_DLY limit 100;
--Find whitelist status of email addresses
create or replace table whitelist_status as (
select EMAIL_ADR, WHTLST_STAT_CD   from (
select j.*, row_number() over (partition by email_adr order by EMAIL_ENGGMT_TS desc) as r1
from db.PEDW_SECURED.HDR_WHTLST_EMAIL j
where (UPPER(email_adr) in (select distinct UPPER(trim(EMAIL_ADDR_N1_TEXT)) from rpm_email) or UPPER(email_adr) in (select distinct UPPER(trim(EMAIL_ADDR_N2_TEXT)) from rpm_email))
)
where r1 = 1
);

--select * from db.PEDW_SECURED.HDR_WHTLST_EMAIL limit 10;
--Add flag for first email address and first whitelist status
create or replace table rpm_email_one_final as (
select a.*, case when (NULLIF(LTRIM(RTRIM(EMAIL_ADDR_N1_TEXT)), '')) is null or upper(trim(EMAIL_ADDR_N1_TEXT)) in ('NONE@CAPITALONE-NO-EMAIL.COM', 'NONE@CAPITALONE.COM', 'INVALID@INVALID.COM','NONE@CAPTIALONE.COM',
'NONE@CAPONE.COM','NONE@NONE.COM','EMAIL@WEBSITE.COM','NA@NA.COM',
'NOEMAIL@NOEMAIL.COM', 'NO@EMAIL.COM', 'NONE@CAPITOLONE.COM', 'INVALID.INVALID@INVALID.COM', 'NOMAIL@CAPITALONE.COM', 'NOEMAIL@CAPITALONE.COM','CAPITALONE@CAPITALONE.COM',
'NONE@YAHOO.COM', 'NONE@CAPITAL.COM', 'NONE@GMAIL.COM', 'NOEMAIL@GMAIL.COM', 'NOEMAIL@YAHOO.COM', 'INVALID@INVALID.INVALID', 'NON@CAPITALONE.COM', 'NON@CAPONE.COM',
'NA@CAPITALONE.COM', 'NOEMAIL@EMAIL.COM', 'NONE@CAP1.COM', 'NULL@NULL.COM', 'NO@NO.COM', 'INVALID@CAPITALONE.COM', 'NONE@EMAIL.COM', 'NOEMAIL@CAPITALONE-NO-EMAIL.COM',
'CAPITALONE@NONE.COM', 'NONONE@CAPITALONE.COM', 'NONE@CAP.COM', 'NONE@CAPITLAONE.COM', 'NONE@NO.COM', 'NOEMAIL@CAPONE.COM', '123@YAHOO.COM', 'NOEMAIL@AOL.COM', 'NONE@NOMAIL.COM',
'CAPITALONE@YAHOO.COM', 'NONAME@CAPONE.COM' ,'NONE@AOL.COM' ,'NOMORE@ATT.NET', 'NO@CAPONE.COM', 'CHASE@CHASE.COM', 'X@GMAIL.COM', 'NA@CAPONE.COM', 'CAPITAL@ONE.COM',
'NONAME@CAPITALONE.COM', 'NOEMAIL@NO.COM', 'NA@YAHOO.COM', 'NOEMAIL@NONE.COM')
or upper(TRIM(EMAIL_ADDR_N1_TEXT)) ilike('NONE@%') or upper(TRIM(EMAIL_ADDR_N1_TEXT)) ilike('NOEMAIL@%') or upper(TRIM(EMAIL_ADDR_N1_TEXT)) ilike('NA@%') or upper(TRIM(EMAIL_ADDR_N1_TEXT)) ilike('NULL@%')
or upper(TRIM(EMAIL_ADDR_N1_TEXT)) in  ('SUPPORT@FREEDOMDEBTRELIEF.COM', 'SERVICE@NATIONALDEBTRELIEF.COM', 'SERVICE@GITMEIDLAW.COM', 'ADMIN@ACCSDEBT.COM', 'CUSTOMERCARE@ARETEFINANCIALFREEDOM.COM',
'SUPPORT@FREEDOM.COM', 'SUCESS@NATIONALDEBTRELIEF.COM', 'SUPPORT@FREEDOMDEBITRELIEF.COM', 'SUPPORT@SETTLEIT.COM', 'EMAIL-SUPPORT@FREEDOMDEBTRELIEF.COM', 'INFO@FREEDOMDEBTRELIEF.COM',
'SUPPORT@ARETEFINANCIALFREEDOM.COM', 'SUPPORT@ACCSDEBT.COM', 'SUPPORT@CFTPAY.COM', 'CUSTOMERCARE@CENTURYSS.COM', 'HELP@DMBFINANCIAL.COM', 'SUPPORT@FREEDOMRELIEF.COM')
then 0 else 1 end as email_one_flag, whtlst_stat_cd as whtlst_stat_cd_one
from rpm_email a
left join whitelist_status b
on UPPER(trim(a.EMAIL_ADDR_N1_TEXT)) = UPPER(EMAIL_ADR)
);

--Add flag for second email address and second whitelist status
create or replace table rpm_email_two_final as (
select a.*, case when (NULLIF(LTRIM(RTRIM(EMAIL_ADDR_N2_TEXT)), '')) is null or upper(trim(EMAIL_ADDR_N2_TEXT)) in ('NONE@CAPITALONE-NO-EMAIL.COM', 'NONE@CAPITALONE.COM', 'INVALID@INVALID.COM','NONE@CAPTIALONE.COM',
'NONE@CAPONE.COM','NONE@NONE.COM','EMAIL@WEBSITE.COM','NA@NA.COM',
'NOEMAIL@NOEMAIL.COM', 'NO@EMAIL.COM', 'NONE@CAPITOLONE.COM', 'INVALID.INVALID@INVALID.COM', 'NOMAIL@CAPITALONE.COM', 'NOEMAIL@CAPITALONE.COM','CAPITALONE@CAPITALONE.COM',
'NONE@YAHOO.COM', 'NONE@CAPITAL.COM', 'NONE@GMAIL.COM', 'NOEMAIL@GMAIL.COM', 'NOEMAIL@YAHOO.COM', 'INVALID@INVALID.INVALID', 'NON@CAPITALONE.COM', 'NON@CAPONE.COM',
'NA@CAPITALONE.COM', 'NOEMAIL@EMAIL.COM', 'NONE@CAP1.COM', 'NULL@NULL.COM', 'NO@NO.COM', 'INVALID@CAPITALONE.COM', 'NONE@EMAIL.COM', 'NOEMAIL@CAPITALONE-NO-EMAIL.COM',
'CAPITALONE@NONE.COM', 'NONONE@CAPITALONE.COM', 'NONE@CAP.COM', 'NONE@CAPITLAONE.COM', 'NONE@NO.COM', 'NOEMAIL@CAPONE.COM', '123@YAHOO.COM', 'NOEMAIL@AOL.COM', 'NONE@NOMAIL.COM',
'CAPITALONE@YAHOO.COM', 'NONAME@CAPONE.COM' ,'NONE@AOL.COM' ,'NOMORE@ATT.NET', 'NO@CAPONE.COM', 'CHASE@CHASE.COM', 'X@GMAIL.COM', 'NA@CAPONE.COM', 'CAPITAL@ONE.COM',
'NONAME@CAPITALONE.COM', 'NOEMAIL@NO.COM', 'NA@YAHOO.COM', 'NOEMAIL@NONE.COM')
or upper(TRIM(EMAIL_ADDR_N2_TEXT)) ilike('NONE@%') or upper(TRIM(EMAIL_ADDR_N2_TEXT)) ilike('NOEMAIL@%') or upper(TRIM(EMAIL_ADDR_N2_TEXT)) ilike('NA@%') or upper(TRIM(EMAIL_ADDR_N2_TEXT)) ilike('NULL@%')
or upper(TRIM(EMAIL_ADDR_N2_TEXT)) in  ('SUPPORT@FREEDOMDEBTRELIEF.COM', 'SERVICE@NATIONALDEBTRELIEF.COM', 'SERVICE@GITMEIDLAW.COM', 'ADMIN@ACCSDEBT.COM', 'CUSTOMERCARE@ARETEFINANCIALFREEDOM.COM',
'SUPPORT@FREEDOM.COM', 'SUCESS@NATIONALDEBTRELIEF.COM', 'SUPPORT@FREEDOMDEBITRELIEF.COM', 'SUPPORT@SETTLEIT.COM', 'EMAIL-SUPPORT@FREEDOMDEBTRELIEF.COM', 'INFO@FREEDOMDEBTRELIEF.COM',
'SUPPORT@ARETEFINANCIALFREEDOM.COM', 'SUPPORT@ACCSDEBT.COM', 'SUPPORT@CFTPAY.COM', 'CUSTOMERCARE@CENTURYSS.COM', 'HELP@DMBFINANCIAL.COM', 'SUPPORT@FREEDOMRELIEF.COM')
then 0 else 1 end as email_two_flag, whtlst_stat_cd as whtlst_stat_cd_two
from rpm_email_one_final a
left join whitelist_status b
on UPPER(trim(a.EMAIL_ADDR_N2_TEXT)) = UPPER(EMAIL_ADR)
);

--Set fake/empty email addresses (none@capitalone.com) to be zero in flag
update rpm_email_one_final
set whtlst_stat_cd_one =  null where email_one_flag = 0;

update rpm_email_two_final
set whtlst_stat_cd_two =  null where email_two_flag = 0;

--If one email address exists and if whitelist status is GoodToSend, email address is whitelisted
create or replace table rpm_email_final as (
select a.*,
case
when (email_one_flag=1 or email_two_flag = 1) then 1
else 0
end as email_flag,
case
when (whtlst_stat_cd_one = 'GoodToSend' or whtlst_stat_cd_two = 'GoodToSend') then 'GoodToSend'
when (whtlst_stat_cd_one = 'ServicingOnly' or whtlst_stat_cd_two = 'ServicingOnly') then 'ServicingOnly'
when (whtlst_stat_cd_one = 'DoNotSend' or whtlst_stat_cd_two = 'DoNotSend') then 'DoNotSend'
else null
end as whtlst_stat_cd
from rpm_email_two_final a

);

--Status of email for all accounts
select email_flag, whtlst_stat_cd, count(distinct arr_id_chain)
from rpm_email_final group by 1,2 order by 1,2;

select partner_status, email_flag, whtlst_stat_cd, count(distinct arr_id_chain)
from rpm_email_final where bucket in (0,1,2,3,4,5,6) group by 1,2,3 order by 1,2,3;


--Repeat for DQ accounts
select email_flag, whtlst_stat_cd, count(distinct arr_id_chain)
from rpm_email_final where bucket <> 0 group by 1,2 order by 1,2;

select partner_status, email_flag, whtlst_stat_cd, count(distinct arr_id_chain)
from rpm_email_final where bucket in (1,2,3,4,5,6) 
group by 1,2,3 order by 1,2,3;

--Status of email for all accounts
select CASE
WHEN ORG_CD IN ('004','005','226','601','602') THEN 'Active'
WHEN ORG_CD IN ('329','222','176','420','800') then 'Inactive - Powersports'
when ORG_CD IN ('856') then 'Inactive - Dressbarn'
when org_cd in ('593') then 'Inactives - Furniture Row' --keep as Inactives
ELSE 'Inactive - Other' END AS PARTNER_STATUS,
email_flag, whtlst_stat_cd, count(distinct arr_id_chain)
from rpm_email_final group by 1,2,3 order by 1,2,3;

--Repeat for DQ accounts
select CASE
WHEN ORG_CD IN ('004','005','226','601','602') THEN 'Active'
WHEN ORG_CD IN ('329','222','176','420','800') then 'Inactive - Powersports'
when ORG_CD IN ('856') then 'Inactive - Dressbarn'
when org_cd in ('593') then 'Inactives - Furniture Row' --keep as Inactives
ELSE 'Inactive - Other' END AS PARTNER_STATUS,
email_flag, whtlst_stat_cd, count(distinct arr_id_chain)
from rpm_email_final where bucket <> 0 group by 1,2,3 order by 1,2,3;

select * from db.pedw_secured.EC_CUST_ACCT_EMAIL_ADR_BC limit 100;



create or replace table t2_acct as(
  SELECT a.acct_id
    , b.email_adr_txt 
    ,case
      WHEN a.svc_ownr_cd IN ('000010','000011', '000051', '000088','000086','000090','000091') THEN 'Mainstreet'
      WHEN a.svc_ownr_cd IN ('000022','000023', '000052', '000087', '000089') THEN 'Upmarket'
      when a.svc_ownr_cd in ('000114','000115') then 'Walmart PLCC'
      when a.svc_ownr_cd in ('000118','000119','000120','000121') then 'Walmart Cobrand'
      else 'Other'
      end as segment
    , c.cyc_pdue_bkt_num
  from db.pcdw.t2_stmt c
  left join db.pcdw.t2_acct_stat_hist_bc a
    on a.acct_id = c.acct_id
  left join db.pedw_secured.EC_CUST_ACCT_EMAIL_ADR_BC b
    on c.acct_id = b.acct_id
    and b.cust_acct_role_type_cd = 'PR'
  where a.acct_sfx_num = 0
  --and b.cust_acct_role_type_cd = 'PR'
  --and a.clsd_reas_cd = '*2'
  and c.acct_sfx_num = 0
  and c.stmt_end_dt between '2020-09-01' and '2020-09-30'
);
/*
--select * from db.pcdw.t2_stmt limit 100;
create or replace table temp as (
  select acct_id, cyc_pdue_bkt_num, stmt_end_dt, max(stmt_end_dt) over (partition by acct_id) as latest
    from db.pcdw.t2_stmt
    where acct_sfx_num = 0
    and stmt_end_dt >= '2020-09-01'
    );
    
--select * from temp2 limit 10;
create or replace table temp2 as (
  select * from temp
    where stmt_end_dt = latest);
    
create or replace table t2_acct as (
  select a.*, b.cyc_pdue_bkt_num as bucket
    from t2_acct a
    left join temp2 b
    on a.acct_id = b.acct_id
    );
    
--select * from t2_acct limit 100;
*/

create or replace table t2_whitelist_status as (
  select EMAIL_ADR, WHTLST_STAT_CD  from 
    (
    select j.*, row_number() over (partition by email_adr order by EMAIL_ENGGMT_TS desc) as r1
    from db.PEDW_SECURED.HDR_WHTLST_EMAIL j
    where UPPER(email_adr) in (select distinct UPPER(trim(EMAIL_ADR_TXT)) from t2_acct)
    )
  where r1 = 1
);

create or replace table t2_email_final as (
select a.*, case when (NULLIF(LTRIM(RTRIM(EMAIL_ADR_TXT)), '')) is null or upper(trim(EMAIL_ADR_TXT)) in ('NONE@CAPITALONE-NO-EMAIL.COM', 'NONE@CAPITALONE.COM', 'INVALID@INVALID.COM','NONE@CAPTIALONE.COM',
'NONE@CAPONE.COM','NONE@NONE.COM','EMAIL@WEBSITE.COM','NA@NA.COM',
'NOEMAIL@NOEMAIL.COM', 'NO@EMAIL.COM', 'NONE@CAPITOLONE.COM', 'INVALID.INVALID@INVALID.COM', 'NOMAIL@CAPITALONE.COM', 'NOEMAIL@CAPITALONE.COM','CAPITALONE@CAPITALONE.COM',
'NONE@YAHOO.COM', 'NONE@CAPITAL.COM', 'NONE@GMAIL.COM', 'NOEMAIL@GMAIL.COM', 'NOEMAIL@YAHOO.COM', 'INVALID@INVALID.INVALID', 'NON@CAPITALONE.COM', 'NON@CAPONE.COM',
'NA@CAPITALONE.COM', 'NOEMAIL@EMAIL.COM', 'NONE@CAP1.COM', 'NULL@NULL.COM', 'NO@NO.COM', 'INVALID@CAPITALONE.COM', 'NONE@EMAIL.COM', 'NOEMAIL@CAPITALONE-NO-EMAIL.COM',
'CAPITALONE@NONE.COM', 'NONONE@CAPITALONE.COM', 'NONE@CAP.COM', 'NONE@CAPITLAONE.COM', 'NONE@NO.COM', 'NOEMAIL@CAPONE.COM', '123@YAHOO.COM', 'NOEMAIL@AOL.COM', 'NONE@NOMAIL.COM',
'CAPITALONE@YAHOO.COM', 'NONAME@CAPONE.COM' ,'NONE@AOL.COM' ,'NOMORE@ATT.NET', 'NO@CAPONE.COM', 'CHASE@CHASE.COM', 'X@GMAIL.COM', 'NA@CAPONE.COM', 'CAPITAL@ONE.COM',
'NONAME@CAPITALONE.COM', 'NOEMAIL@NO.COM', 'NA@YAHOO.COM', 'NOEMAIL@NONE.COM')
or upper(TRIM(EMAIL_ADR_TXT)) ilike('NONE@%') or upper(TRIM(EMAIL_ADR_TXT)) ilike('NOEMAIL@%') or upper(TRIM(EMAIL_ADR_TXT)) ilike('NA@%') or upper(TRIM(EMAIL_ADR_TXT)) ilike('NULL@%')
or upper(TRIM(EMAIL_ADR_TXT)) in  ('SUPPORT@FREEDOMDEBTRELIEF.COM', 'SERVICE@NATIONALDEBTRELIEF.COM', 'SERVICE@GITMEIDLAW.COM', 'ADMIN@ACCSDEBT.COM', 'CUSTOMERCARE@ARETEFINANCIALFREEDOM.COM',
'SUPPORT@FREEDOM.COM', 'SUCESS@NATIONALDEBTRELIEF.COM', 'SUPPORT@FREEDOMDEBITRELIEF.COM', 'SUPPORT@SETTLEIT.COM', 'EMAIL-SUPPORT@FREEDOMDEBTRELIEF.COM', 'INFO@FREEDOMDEBTRELIEF.COM',
'SUPPORT@ARETEFINANCIALFREEDOM.COM', 'SUPPORT@ACCSDEBT.COM', 'SUPPORT@CFTPAY.COM', 'CUSTOMERCARE@CENTURYSS.COM', 'HELP@DMBFINANCIAL.COM', 'SUPPORT@FREEDOMRELIEF.COM')
then 0 else 1 end as email_flag, whtlst_stat_cd as whtlst_stat_cd_one
from t2_acct a
left join t2_whitelist_status b
on UPPER(trim(a.EMAIL_ADR_TXT)) = UPPER(EMAIL_ADR)
);

update t2_email_final
set whtlst_stat_cd_one =  null where email_flag = 0;


select case when segment ilike '%walmart%' then 'Walmart' else segment end as segment, email_flag, whtlst_stat_cd_one, count(distinct acct_id)
from t2_email_final where cyc_pdue_bkt_num  in (0,1,2,3,4,5,6) group by 1,2,3 order by 1,2,3;

--select count(distinct acct_id) from t2_email_final where cyc_pdue_bkt_num in (0,1,2,3,4,5,6) and segment ilike '%Mainstreet%';
--select count(distinct acct_id) from t2_acct where cyc_pdue_bkt_num in (0,1,2,3,4,5,6) and segment ilike '%Upmarket%';

--Repeat for DQ accounts
select case when segment ilike '%walmart%' then 'Walmart' else segment end as segment, email_flag, whtlst_stat_cd_one, count(distinct acct_id)
from t2_email_final where cyc_pdue_bkt_num in (1,2,3,4,5,6) group by 1,2,3 order by 1,2,3;

select  email_flag, whtlst_stat_cd_one, count(distinct acct_id)
from t2_email_final group by 1,2 order by 1,2;

--Repeat for DQ accounts
select email_flag, whtlst_stat_cd_one, count(distinct acct_id)
from t2_email_final where bucket <> 0 group by 1,2 order by 1,2;
