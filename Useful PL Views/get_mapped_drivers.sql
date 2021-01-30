--Join January 2020 complaints to their mapped drivers

select a.*, b.mapped_driver 
  from card_db_collab.lab_channels_complaints.cmplant_pl a
  left join card_db_collab.lab_complaints_discovery.mapped_drivers b
      on TRIM(replace(a.primary_driver || a.primary_subdriver,',')) = b.concat_drivers
      and Upper(a.Tier) = Upper(b.Tier)
  where a.date_received between '2020-01-01' and '2020-01-31';
 
