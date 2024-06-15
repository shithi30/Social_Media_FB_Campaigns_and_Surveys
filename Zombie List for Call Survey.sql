
/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/1lLAva_M3ZMK_9xVXLFqwfMztesp3KfrydWGhmWux2Hc/edit#gid=156605372 
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Requesting For 500 Retained Zombie Data!
- Notes (if any): 
	Please provide us the 500 retained Zombie list with following requirements:
	
	1. TK registered mobile numbers
	2. Shop name
	3. Registration Date
	4. Business type
	5. District Name
	6. Thana Name
	
	Conditions:
	1. Merchant age more than >90 days
	2. Not activities within last 45 days
*/

select mobile_no, shop_name, reg_date, business_type, district_name, upazilla_name
from 
	(select mobile_no
	from cjm_segmentation.retained_users 
	where 
		report_date=current_date
		and tg ilike 'z%' 
	) tbl1 
	
	inner join 
		
	(select mobile_number mobile_no, date(created_at) reg_date 
	from public.register_usermobile 
	) tbl2 using(mobile_no)
	
	inner join 
	
	(select mobile mobile_no, shop_name, new_bi_business_type business_type
	from tallykhata.tallykhata_user_personal_info 
	where 
		shop_name is not null and shop_name!=''
		and new_bi_business_type is not null and new_bi_business_type!=''
	) tbl3 using(mobile_no)
		
	inner join 
	
	(select mobile mobile_no, district_name, upazilla_name 
	from tallykhata.tallykhata_clients_location_info 
	) tbl4 using(mobile_no)
	
	left join 
	
	(select mobile_no 
	from tallykhata.tallykhata_user_date_sequence_final 
	where event_date>=current_date-45 and event_date<current_date
	) tbl5 using(mobile_no)
where 
	tbl5.mobile_no is null 
	and reg_date<current_date-90
order by random()
limit 500; 
		