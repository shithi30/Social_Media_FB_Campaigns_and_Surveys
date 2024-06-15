/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/14isAzMutxpj3MqjMxvvLSFjaDSuV-YcVNXZBNtPVjCU/edit#gid=0
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Need super User data
- Notes (if any): by Jahangir Alam
*/

-- biz type by Mahmud
drop table if exists data_vajapora.help_c; 
create table data_vajapora.help_c as
select 
	mobile_no, 
	shop_name, 
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
		max(case when shop_name is not null then shop_name else business_name end) shop_name
	from tallykhata.tallykhata_user_personal_info 
	group by 1
	) tbl3 using(mobile_no); 

-- necessary info. 
select mobile_no, shop_name, biz_type business_type, location_url
from 
	(select mobile_no
	from cjm_segmentation.retained_users 
	where 
		report_date=current_date-1 
		and tg like '%SPU%'
	) tbl1 
	
	inner join 
		
	(select mobile mobile_no, lat::numeric, lng::numeric, concat('https://maps.google.com/?q=',lat,',',lng) location_url
	from tallykhata.tallykhata_clients_location_info
	where data_vajapora.lat_long_dist_meters(23.7286, 90.3854, lat::numeric, lng::numeric)<=700
	) tbl2 using(mobile_no) 
	
	inner join 
	
	data_vajapora.help_c tbl3 using(mobile_no)
where biz_type is not null
limit 25; 
