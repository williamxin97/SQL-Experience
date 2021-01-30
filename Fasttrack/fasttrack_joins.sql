-- join fasttrack cases to related tables that join integer fields to text


--there are a lot of try_to transformations because join functions require exact matches. 
--Some fields are not consistent in integer/float/string format
--Usually, if the underlying tables are created correctly with good design practice, try_to functions are not necessary


create or replace table case_sample as 
    select distinct a.*, a.created as creation_date, a.closeddate as closed_date,
        b.value as what_created_issue, c.rootcause as root_cause, d.action as action_done
    from card_db_collab.lab_channels_complaints.SP_FLFT_SUBMISSIONS a
    left join card_db_collab.lab_channels_complaints.SP_FLFT_LOOKUP_WHATCREATEDTHIS b
    on a.whatcreatedthisissue = b.id
    left join card_db_collab.lab_channels_complaints.SP_FLFT_LOOKUP_rootcause c
    on a.rootcause = c.id
    left join card_db_collab.lab_channels_complaints.SP_FLFT_LOOKUP_ACTION d
    on a.action = d.id
    where a.closeddate between '2020-07-01' and '2020-07-31'
    and root_cause is not null
    and what_created_issue is not null
    and action_done is not null
    and what_created_issue not like '%Digital%'
    ;

