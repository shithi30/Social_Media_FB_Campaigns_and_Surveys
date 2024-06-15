/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/1lLAva_M3ZMK_9xVXLFqwfMztesp3KfrydWGhmWux2Hc/edit#gid=907841916
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Requesting for data
- Notes (if any):
*/

-- generate top-50 merchants for each district
drop table if exists data_vajapora.temp_a; 
create table data_vajapora.temp_a as
select 
	merchant_name,
	mobile_no, 
	shop_name, 
	shop_address, 
	area_type,
	district_name, 
	-- distance, 
	row_number() over(partition by district_name order by distance asc) visit_serial  
from 
	(select 
		*, 
		case 
			when district_name='Gopalganj' then data_vajapora.lat_long_dist_meters(23.0488, 89.8879, lat::numeric, lng::numeric) 
			when district_name='Faridpur' then data_vajapora.lat_long_dist_meters(23.5424, 89.6309, lat::numeric, lng::numeric) 
			when district_name='Rajbari' then data_vajapora.lat_long_dist_meters(23.7151, 89.5875, lat::numeric, lng::numeric) 
			when district_name='Manikganj' then data_vajapora.lat_long_dist_meters(23.8617, 90.0003, lat::numeric, lng::numeric) 
		end distance, 
		row_number() over(partition by district_name) seq
	from 
		(select mobile mobile_no, district_name, concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address, area_type, lat, lng
		from tallykhata.tallykhata_clients_location_info
		where 
			district_name in
				('Gopalganj',
				'Faridpur',
				'Rajbari', 
				'Manikganj'
				)
			and (city_corporation_name ilike '%city%' or city_corporation_name ilike '%sadar%' or city_corporation_name ilike '%municipality%' or city_corporation_name ilike '%paurashava%')                                               
			and 
			    (  data_vajapora.lat_long_dist_meters(23.0488, 89.8879, lat::numeric, lng::numeric)<=7000 -- Gopalganj
				or data_vajapora.lat_long_dist_meters(23.5424, 89.6309, lat::numeric, lng::numeric)<=100000 -- Faridpur
				or data_vajapora.lat_long_dist_meters(23.7151, 89.5875, lat::numeric, lng::numeric)<=7000 -- Rajbari
				or data_vajapora.lat_long_dist_meters(23.8617, 90.0003, lat::numeric, lng::numeric)<=4000 -- Manikganj
				)			
		) tbl1 
		
		inner join 
		
		(select distinct mobile_no
		from tallykhata.tk_spu_aspu_data 
		where 
			pu_type in('SPU')
			and report_date=current_date-1
		) tbl2 using(mobile_no)
	) tbl1
	
	left join

	(select 
		mobile mobile_no, 
		max(case when shop_name is not null then shop_name else business_name end) shop_name,
		max(merchant_name) merchant_name
	from tallykhata.tallykhata_user_personal_info
	group by 1
	) tbl2 using(mobile_no)
where seq<=50; 

select *
from data_vajapora.temp_a;

-- sanity check
select district_name, count(*) merchants
from data_vajapora.temp_a
group by 1; 