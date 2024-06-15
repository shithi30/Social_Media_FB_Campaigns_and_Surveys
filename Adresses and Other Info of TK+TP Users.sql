/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/14isAzMutxpj3MqjMxvvLSFjaDSuV-YcVNXZBNtPVjCU/edit#gid=287045878
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: http://localhost:8888/notebooks/Import%20from%20csv%20to%20DB/Address%20from%20Lat-Lng.ipynb
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): 
	Nazrul bhai, need a list of TK users who registered in TP. Expected:
	- Mobile number
	- Name
	- Business name
	- Business type
	- Address/location (District, Upazilla, union/ward, street address)
	- Google map link
*/

-- biz type by Mahmud
drop table if exists data_vajapora.help_c; 
create table data_vajapora.help_c as
select 
	mobile_no, 
	shop_name, 
	merchant_name, 
	case 
		when business_type in('BAKERY_AND_CONFECTIONERY') then 'SWEETS AND CONFECTIONARY'
		when business_type in('ELECTRONICS') then 'ELECTRONICS STORE'
		when business_type in('MFS_AGENT','MFS_MOBILE_RECHARGE') then 'MFS-MOBILE RECHARGE STORE'
		when business_type in('GROCERY') then 'GROCERY'
		when business_type in('DISTRIBUTOR_OR_WHOLESALE','WHOLESALER','DEALER') then 'OTHER WHOLESELLER'
		when business_type in('HOUSEHOLD_AND_FURNITURE') then 'FURNITURE SHOP'
		when business_type in('STATIONERY') then 'STATIONARY BUSINESS'
		when business_type in('TAILORS') then 'TAILERS'
		when business_type in('PHARMACY') then 'PHARMACY'
		when business_type in('SHOE_STORE') then 'SHOE STORE'
		when business_type in('MOTOR_REPAIR') then 'VEHICLE-CAR SERVICING'
		when business_type in('COSMETICS') then 'COSMETICS AND PERLOUR'
		when business_type in('ROD_CEMENT') then 'CONSTRUCTION RAW MATERIAL'
		when business_type='' then upper(case when new_bi_business_type!='Other Business' then new_bi_business_type else null end) 
		else null 
	end biz_type
from 
	(select id, business_type 
	from public.register_tallykhatauser 
	) tbl1 
	
	inner join 
	
	(select mobile_no, max(id) id
	from public.register_tallykhatauser 
	group by 1
	) tbl2 using(id)
	
	inner join 
	
	(select 
		mobile mobile_no, 
		max(new_bi_business_type) new_bi_business_type, 
		max(coalesce(shop_name, business_name)) shop_name, 
		max(coalesce(merchant_name, name)) merchant_name
	from tallykhata.tallykhata_user_personal_info 
	group by 1
	) tbl3 using(mobile_no); 

-- necessary info. 
select 
	mobile_no, registration_date, 
	shop_name, merchant_name, biz_type business_type, 
	district_name, upazilla_name, union_name, location_url, 
	lat, lng
from 
	data_vajapora.wallet_open tbl0
	
	inner join 

	(select mobile_number mobile_no, date(created_at) registration_date
	from public.register_usermobile
	) tbl1 using(mobile_no)
	
	left join 
		
	(select mobile mobile_no, lat, lng, district_name, upazilla_name, union_name, concat('https://maps.google.com/?q=',lat,',',lng) location_url
	from tallykhata.tallykhata_clients_location_info
	) tbl2 using(mobile_no) 
	
	left join 
	
	data_vajapora.help_c tbl3 using(mobile_no); 

-- adding street address
select 
	mobile_no, registration_date, 
	shop_name, merchant_name, business_type, 
	district_name, upazilla_name, union_name, translate(replace(street_address, $$'$$, ''), '{}', '') full_address, location_url
from data_vajapora.help_a;
