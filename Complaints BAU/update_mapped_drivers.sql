use warehouse CARD_Q_CHANNELS;
use database Card_Db_Collab;
use schema lab_complaints_discovery;

--Create Import Table for Mapped Drivers
CREATE OR REPLACE TEMPORARY TABLE mapped_drivers_import (
Concat_Drivers varchar(200),
Mapped_Driver varchar(200),
Mapped_Check varchar(200),
Mapped_Driver_With_TBD varchar(200),
Tier varchar(200)
)

--Set stage properties for data import
STAGE_FILE_FORMAT = (TYPE = 'csv' FIELD_DELIMITER= ',');  


PUT file://C:\Users\aik604\Downloads\Mapped_Drivers.csv @%mapped_drivers_import;

--Load formatted Mapped Drivers data into the import table
COPY INTO mapped_drivers_import from (select a.$1, a.$2, a.$3, Case When a.$3 = 'Not Mapped' Then 'Other (TBD)' Else a.$2 End, a.$4 from '@%mapped_drivers_import' a);

--Create final Mapped Drivers table, removing pasted headers from Tableau
CREATE OR REPLACE TABLE card_db_collab.lab_complaints_discovery.mapped_drivers as (
select a.*
,current_date as Load_Date
from mapped_drivers_import as a
where upper(Tier) != 'TIER'
);

--Create Import Table for Mapped Segment
CREATE OR REPLACE TEMPORARY TABLE mapped_segment_import (
Cnsmr_Type_Desc varchar(200),
Mapped_Cnsmr_Type varchar(200),
Concat_Cnsmr_Type_Segment varchar(200),
Mapped_Segment varchar(200),
Mapped_Check varchar(200),
Mapped_Segment_With_TBD varchar(200),
Segment varchar(200),
Tier varchar(200)
)

--Set stage properties for data import
STAGE_FILE_FORMAT = (TYPE = 'csv' FIELD_DELIMITER= ',');


PUT file://C:\Users\aik604\Downloads\mapped_segment.csv @%mapped_segment_import;

--Load formatted Mapped Segment data into the import table
COPY INTO mapped_segment_import from (select a.$1, a.$2, a.$3, a.$4, a.$5, Case When a.$5 = 'Not Mapped' Then 'Undetermined' Else a.$4 End, a.$6, a.$7 from '@%mapped_segment_import' a);

--Create final Mapped Segment table, removing pasted headers from Tableau
CREATE OR REPLACE TABLE card_db_collab.lab_complaints_discovery.mapped_segment as (
select a.*
,current_date as Load_Date
from mapped_segment_import as a
where upper(Tier) != 'TIER'
);

--Grant access to the Mapped Drivers & Mapped Segment tables via data roles
grant select on card_db_collab.lab_complaints_discovery.mapped_drivers to phdp_card;
grant select on card_db_collab.lab_complaints_discovery.mapped_segment to phdp_card;
grant select on card_db_collab.lab_complaints_discovery.mapped_drivers to phdp_card_npi;
grant select on card_db_collab.lab_complaints_discovery.mapped_segment to phdp_card_npi;

--Grant access to the Mapped Drivers & Mapped Segment tables to Anuj (he is missing data roles)
grant select on card_db_collab.lab_complaints_discovery.mapped_drivers to SNOW_QWX893_role;
grant select on card_db_collab.lab_complaints_discovery.mapped_segment to SNOW_QWX893_role;

grant select on card_db_collab.lab_complaints_discovery.mapped_drivers to SNOW_SCP491_role;
grant select on card_db_collab.lab_complaints_discovery.mapped_segment to SNOW_SCP491_role;
