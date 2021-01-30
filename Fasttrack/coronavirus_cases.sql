--coronavirus cases: This query looks at two text fields to see if they mention coronavirus

create or replace table cv_samp as select * from comp_samp 
    where ((issuedescription ilike any ('%CORONA%','%COVID%','%VIRUS%','%EPIDEMIC%','%PANDEMIC%','%OUTBREAK%')
    and not(issuedescription ilike any ('%ANTIVIRUS%','%ANTI VIRUS%','%ANTI-VIRUS%','%COMPUTER%')))
    or (resolutionnotes ilike any ('%CORONA%','%COVID%','%VIRUS%','%EPIDEMIC%','%PANDEMIC%','%OUTBREAK%')
    and not(resolutionnotes ilike any ('%ANTIVIRUS%','%ANTI VIRUS%','%ANTI-VIRUS%','%COMPUTER%'))))
;

create or replace table non_cv as select * from comp_samp
    where ID not in (select ID from cv_samp);
    
create or replace table c_sample as 
    select 'Non-Coronavirus' as coronavirus_or_not, ID as case_id, creation_date, close_date, 'Servicing' as category, what_created_issue, root_cause, action_done, accountid, submitterslob, issuedescription
        from (select * from (select * from non_cv where submitterslob in ('Servicing Case Management (SCM)', 'BCS', 'HVSS')) sample row(20 ROWS))
    union all
    select 'Non-Coronavirus' as coronavirus_or_not, ID as case_id, creation_date, close_date, 'Fraud' as category, what_created_issue, root_cause, action_done, accountid, submitterslob, issuedescription
        from (select * from (select * from non_cv where submitterslob = 'FDO') sample row(5 ROWS))
    union all
    select 'Non-Coronavirus' as coronavirus_or_not, ID as case_id, creation_date, close_date, 'Customer Resiliency' as category, what_created_issue, root_cause, action_done, accountid, submitterslob, issuedescription
        from (select * from (select * from non_cv where submitterslob in ('Collections', 'Recoveries')) sample row(5 ROWS))
    union all
    select 'Coronavirus-Related' as coronavirus_or_not, ID as case_id, creation_date, close_date, 'Servicing' as category, what_created_issue, root_cause, action_done, accountid, submitterslob, issuedescription
        from (select * from (select * from cv_samp where submitterslob in ('Servicing Case Management (SCM)', 'BCS', 'HVSS')) sample row(20 ROWS))
;
select * from c_sample;
