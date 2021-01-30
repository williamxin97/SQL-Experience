
create or replace table case_sample as 
(
    select distinct 
        e.svc_ownr_cd
        ,case
          WHEN e.svc_ownr_cd IN ('000010','000011', '000051', '000088','000086','000090','000091') THEN 'Mainstreet'
          WHEN e.svc_ownr_cd IN ('000022','000023', '000052', '000087', '000089') THEN 'Upmarket'
          when e.svc_ownr_cd in ('000114','000115') then 'Walmart PLCC'
          when e.svc_ownr_cd in ('000118','000119','000120','000121') then 'Walmart Cobrand'
          else 'Other'
          end as segment
        , a.*
        , a.created as creation_date, a.closeddate as closed_date
        , b.value as what_created_issue
        , c.rootcause as root_cause
        , d.action as action_done
    from card_db_collab.lab_channels_complaints.SP_FLFT_SUBMISSIONS a
    left join card_db_collab.lab_channels_complaints.SP_FLFT_LOOKUP_WHATCREATEDTHIS b
      on a.whatcreatedthisissue = b.id
    left join card_db_collab.lab_channels_complaints.SP_FLFT_LOOKUP_rootcause c
      on a.rootcause = c.id
    left join card_db_collab.lab_channels_complaints.SP_FLFT_LOOKUP_ACTION d
      on a.action = d.id
    left join db.pcdw.t2_acct_stat_hist_bc e
      on a.accountid = e.acct_id
      and e.acct_sfx_num = 0
      and e.provdr_1_id = 1
    where a.closeddate between '2020-08-01' and '2020-08-31'
      and root_cause is not null
      and what_created_issue is not null
      and action_done is not null
      and what_created_issue not like '%Digital%'   
);

/*
select * from case_sample 
  where  
    (
      upper(resolutionnotes) like any ('%GOODWILL%', '%GW UPDATE%','%FCRA%','%FAIR CREDIT REPORTING ACT%')
      or upper(issuedescription) like any ('%GOODWILL%', '%GW UPDATE%','%FCRA%','%FAIR CREDIT REPORTING ACT%')
      or upper(what_created_issue) like '%GOODWILL%'
      or upper(root_cause) like '%GOODWILL%'
    )
    and segment like '%Walmart%';
    
select * from case_sample 
  where  
    (
      root_cause like '%Credit Bureaus%'
    )
    and segment like '%Walmart%';
*/
    

    
create or replace table target_samp as (
  select * from case_sample 
    where  
      (
        upper(resolutionnotes) like any ('%GOODWILL%', '%GW UPDATE%','%FCRA%','%FAIR CREDIT REPORTING ACT%')
        or upper(issuedescription) like any ('%GOODWILL%', '%GW UPDATE%','%FCRA%','%FAIR CREDIT REPORTING ACT%')
        or upper(what_created_issue) like '%GOODWILL%'
        or upper(root_cause) like '%GOODWILL%'
        or root_cause like '%Credit Bureaus%'
      )
      and segment like '%Walmart%'
);
/*create or replace table target_samp as select * from case_sample
    where ((issuedescription ilike any ('%ACDV Deletion%', '%Offer 30796, post DNR%', '%reinsertion%', '%deleted tradeline%')
    )
    or (resolutionnotes ilike any ('%ACDV Deletion%', '%Offer 30796, post DNR%', '%reinsertion%', '%deleted tradeline%')
    ))
;*/

create or replace table non_target_samp as select * from case_sample
    where ID not in (select ID from target_samp);
    
--select submitterslob, count(id) from case_sample group by 1 order by 2 desc;

create or replace table final_sample as 
(
    select 'Non-Target' as target_or_not, ID as case_id, creation_date, closed_date, 'Servicing' as category, what_created_issue, root_cause, action_done, accountid, segment, submitterslob, issuedescription
        from (select * from (select * from non_target_samp 
            where submitterslob in ('Servicing Case Management (SCM)', 'BCS', 'HVSS')) 
          sample row(20 ROWS))
    union all
    select 'Non-Target' as target_or_not, ID as case_id, creation_date, closed_date, 'Fraud' as category, what_created_issue, root_cause, action_done, accountid, segment, submitterslob, issuedescription
        from (select * from (select * from non_target_samp 
            where submitterslob = 'FDO') 
          sample row(5 ROWS))
    union all
    select 'Non-Target' as target_or_not, ID as case_id, creation_date, closed_date, 'Customer Resiliency' as category, what_created_issue, root_cause, action_done, accountid, segment, submitterslob, issuedescription
        from (select * from (select * from non_target_samp 
            where submitterslob in ('Collections', 'Recoveries')) 
          sample row(5 ROWS))
    union all
    select 'Target-Related' as target_or_not, ID as case_id, creation_date, closed_date, 'Servicing' as category, what_created_issue, root_cause, action_done, accountid, segment, submitterslob, issuedescription
        from (select * from (select * from target_samp 
            where submitterslob in ('Servicing Case Management (SCM)', 'BCS', 'HVSS') ) 
          sample row(7 ROWS))
    union all
    select 'Target-Related' as target_or_not, ID as case_id, creation_date, closed_date, 'Servicing' as category, what_created_issue, root_cause, action_done, accountid, segment, submitterslob, issuedescription
        from (select * from (select * from target_samp 
            where submitterslob = 'FDO' ) 
          sample row(7 ROWS))
    union all
    select 'Target-Related' as target_or_not, ID as case_id, creation_date, closed_date, 'Servicing' as category, what_created_issue, root_cause, action_done, accountid, segment, submitterslob, issuedescription
        from (select * from (select * from target_samp 
            where submitterslob in ('Collections', 'Recoveries') ) 
          sample row(6 ROWS))
);

select * from final_sample;
