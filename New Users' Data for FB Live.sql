/*
- Viz: 
- Data: 
- Table:
- File: fb_live_numbers.csv
- Email thread: Data Requirement: last 30 days registered
- Notes (if any): 
*/

drop table if exists data_vajapora.fb_live_numbers;
create table data_vajapora.fb_live_numbers as
select distinct mobile, registration_date reg_date 
from tallykhata.tallykhata_user_personal_info 
where registration_date>current_date-30; 
select *
from data_vajapora.fb_live_numbers;