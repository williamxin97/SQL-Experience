
-- info_and_complaints has both customer information and complaints joined together
create or replace table sb.user_aik604.info_and_complaints as (
  select distinct a.*, 
      b.tier,  b.primary_driver, b.primary_subdriver, b.date_received, b.driver_category, b.segment, b.partner, b.cmplant_cmnt_txt, length(b.cmplant_cmnt_txt) as len,
      c.svc_ownr_cd as stat_segment
  from sb.user_aik604.close_v_fix a
  left join card_db_collab.lab_channels_complaints.cmplant_pl b
  on a.acct_id = b.acct_id
  left join db.pcdw.t2_acct_stat_hist_bc c
  on b.acct_id = c.acct_id
  and b.date_received <= c.snap_dt
);


-- The cmplant_pl already has segment information for all complaints.
-- This section is to get segment information for all customers, not just complaining ones
-- The codes may need to be updated. Last update was 7/15/2020.

create or replace table sb.user_aik604.info_and_complaints as (
  select distinct a.*, 
      b.tier,  b.primary_driver, b.primary_subdriver, b.date_received, b.driver_category, b.segment, b.partner, b.cmplant_cmnt_txt, length(b.cmplant_cmnt_txt) as len,
      case 
        WHEN c.svc_ownr_cd IN ('000045','000047','000048','000049','000050','000054','000055','000058','000059','000060','000061') THEN 'Legacy Cobrand Inactive'
        WHEN c.svc_ownr_cd IN ('000020','000021','000031','000032','000036') THEN 'Misc Inactive'
        WHEN c.svc_ownr_cd IN ('000010','000011','000051','000086','000088','000089','000090','000091') THEN 'MainStreet'
        WHEN c.svc_ownr_cd IN ('000022','000023','000052','000087') THEN 'UpMarket'
        WHEN c.svc_ownr_cd IN ('000035','000053','000135') THEN 'Small Business'
        WHEN c.svc_ownr_cd IN ('000056','000057','000084','000085') THEN 'Sony'
        WHEN c.svc_ownr_cd IN ('000093','000094') THEN 'UP'
        WHEN c.svc_ownr_cd IN ('000097','000098') THEN 'IBT'
        WHEN c.svc_ownr_cd IN ('000099','000100','000101','000102','000103') THEN 'GM'
        WHEN c.svc_ownr_cd IN ('000104','000105') THEN 'Bass Pro'
        WHEN c.svc_ownr_cd IN ('000106','000107') THEN 'Cabelas'
        WHEN c.svc_ownr_cd IN ('000108') THEN 'Justice'
        WHEN c.svc_ownr_cd IN ('000110') THEN 'Dressbarn'
        WHEN c.svc_ownr_cd IN ('000113') THEN 'Maurices'
        WHEN c.svc_ownr_cd IN ('000114','000115','000116','000117','000118','000119','000120','000121') THEN 'Walmart'
        WHEN c.svc_ownr_cd IN ('000095','000096') THEN 'Costco'
        WHEN c.svc_ownr_cd IN ('000040','000041','000042','000043','000044','000072','000073','000074','000075','000076') THEN 'Canada'
        ELSE 'other'        
        end as stat_segment
  from sb.user_aik604.close_v_fix a
  left join card_db_collab.lab_channels_complaints.cmplant_pl b
  on a.acct_id = b.acct_id
  left join db.pcdw.t2_acct_stat_hist_bc c
  on a.acct_id = c.acct_id
  and c.snap_dt >= '2019-01-01'
);
