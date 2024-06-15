/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/1fCOZqJqiz5e9BBtZAm04URPfNIapD3WiGfnauzi7mrI/edit#gid=0
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Required SU Lists
- Notes (if any): See Mahmud's work for better address.
*/

-- biz type by Mahmud
drop table if exists data_vajapora.help_c; 
create table data_vajapora.help_c as
select 
	mobile_no, 
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
		max(new_bi_business_type) new_bi_business_type
	from tallykhata.tallykhata_user_personal_info 
	group by 1
	) tbl3 using(mobile_no); 

select mobile_no, shop_name, merchant_name, biz_type, "location", shop_address, concat('https://maps.google.com/?q=',lat,',',lng) location_url, dist_meters, row_number() over(partition by "location" order by dist_meters asc) visit_serial  
from 
	(select 
		mobile mobile_no,
		case 
			when concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) ilike '%mirpur%' then 'Mirpur'
			when concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) ilike '%mohammadpur%' then 'Mohammadpur'
		end "location", 
		case 
			when concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) ilike '%mirpur%' then data_vajapora.lat_long_dist_meters(23.8223, 90.3654, lat::numeric, lng::numeric) 
			when concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) ilike '%mohammadpur%' then data_vajapora.lat_long_dist_meters(23.7662, 90.3589, lat::numeric, lng::numeric)    
		end dist_meters,
		lat, lng,
		concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address
	from tallykhata.tallykhata_clients_location_info
	where 
		   concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) ilike '%mirpur%'
		or concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) ilike '%mohammadpur%'
	) tbl1 
		
	inner join 
			
	(select distinct mobile_no
	from tallykhata.tk_spu_aspu_data 
	where 
		pu_type in('SPU')
		and report_date=current_date-1
	) tbl2 using(mobile_no)
	
	left join

	(select 
		mobile mobile_no, 
		max(case when shop_name is not null then shop_name else business_name end) shop_name,
		max(merchant_name) merchant_name
	from tallykhata.tallykhata_user_personal_info
	group by 1
	) tbl3 using(mobile_no)
	
	left join 
	
	(select mobile_no, biz_type 
	from data_vajapora.help_c
	) tbl4 using(mobile_no); 