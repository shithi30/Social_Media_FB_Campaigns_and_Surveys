/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/1sMuKTDDX2wZ-wqLDYwbfgEj7N37Z3FEX1XmZWb0NnSw/edit#gid=0
- Function: 
- Table:
- File: 
- Path: 
- Presentation: 
- Email thread: Daily Employee tracking data from Tallykhata
- Notes (if any): More appropriate assumptions, calculations needed. 
*/

-- table given to Shovan
drop table if exists data_vajapora.to_get_loc;
create table data_vajapora.to_get_loc as
select row_number() over(order by tallykhata_user_id) id, * 
from 
	(select tallykhata_user_id, lat, long, created_at 
	from public.locations
	) tbl1 
	
	inner join 
	
	(select mobile_number mobile_no, tallykhata_user_id
	from public.register_usermobile
	where mobile_number in 
		('01980001476',
		'01980001483',
		'01980001678',
		'01980001575',
		'01980001449',
		'01980001576',
		'01980001490',
		'01980001420'
		)
	) tbl2 using(tallykhata_user_id); 

-- detailed locations from Shovan's table
select distinct mobile_no, created_at location_datetime, division, district, upazilla, "union"
from 
	data_vajapora.to_get_loc tbl1
	inner join 
	data_vajapora.loctation_info_sample_2 tbl2 using(tallykhata_user_id) -- table by Shovan
where date(created_at)>='2021-06-01'
order by 1, 2; 
