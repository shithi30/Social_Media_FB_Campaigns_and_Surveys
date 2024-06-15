/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/1lLAva_M3ZMK_9xVXLFqwfMztesp3KfrydWGhmWux2Hc/edit#gid=304089991
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Requesting for data
- Notes (if any): No data found for 'Satkhira', 'Narail', 'Jessore'
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
			when district_name='Khulna' then data_vajapora.lat_long_dist_meters(22.8456, 89.5403, lat::numeric, lng::numeric) 
			when district_name='Satkhira' then data_vajapora.lat_long_dist_meters(22.3155, 89.1115, lat::numeric, lng::numeric) 
			when district_name='Narail' then data_vajapora.lat_long_dist_meters(23.1163, 89.5840, lat::numeric, lng::numeric) 
			when district_name='Bagerhat' then data_vajapora.lat_long_dist_meters(22.6555, 89.7662, lat::numeric, lng::numeric) 
			when district_name='Jessore' then data_vajapora.lat_long_dist_meters(23.1778, 89.1801, lat::numeric, lng::numeric) 
			when district_name='Kushtia' then data_vajapora.lat_long_dist_meters(23.9088, 89.1220, lat::numeric, lng::numeric) 
			when district_name='Magura' then data_vajapora.lat_long_dist_meters(23.4855, 89.4198, lat::numeric, lng::numeric) 
			when district_name='Chuadanga' then data_vajapora.lat_long_dist_meters(23.6418, 88.8577, lat::numeric, lng::numeric) 
			when district_name='Jhenaidah' then data_vajapora.lat_long_dist_meters(23.5528, 89.1754, lat::numeric, lng::numeric) 
			when district_name='Meherpur' then data_vajapora.lat_long_dist_meters(23.8052, 88.6724, lat::numeric, lng::numeric) 
		end distance, 
		row_number() over(partition by district_name) seq
	from 
		(select mobile mobile_no, district_name, concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address, area_type, lat, lng
		from tallykhata.tallykhata_clients_location_info
		where 
			district_name in
				('Khulna',
				'Satkhira',
				'Narail',
				'Bagerhat',
				'Jessore',
				'Kushtia',
				'Magura',
				'Chuadanga',
				'Jhenaidah',
				'Meherpur'
				)
			and (city_corporation_name ilike '%city%' or city_corporation_name ilike '%sadar%' or city_corporation_name ilike '%municipality%' or city_corporation_name ilike '%paurashava%')                                               
			and 
			    (data_vajapora.lat_long_dist_meters(22.8456, 89.5403, lat::numeric, lng::numeric)<=5000 -- Khulna
				or 
				data_vajapora.lat_long_dist_meters(22.3155, 89.1115, lat::numeric, lng::numeric)<=5000 -- Satkhira
				or 
				data_vajapora.lat_long_dist_meters(23.1163, 89.5840, lat::numeric, lng::numeric)<=5000 -- Narail
				or 
				data_vajapora.lat_long_dist_meters(22.6555, 89.7662, lat::numeric, lng::numeric)<=5000 -- Bagerhat
				or 
				data_vajapora.lat_long_dist_meters(23.1778, 89.1801, lat::numeric, lng::numeric)<=5000 -- Jessore
				or 
				data_vajapora.lat_long_dist_meters(23.9088, 89.1220, lat::numeric, lng::numeric)<=5000 -- Kushtia
				or 
				data_vajapora.lat_long_dist_meters(23.4855, 89.4198, lat::numeric, lng::numeric)<=5000 -- Magura
				or 
				data_vajapora.lat_long_dist_meters(23.6418, 88.8577, lat::numeric, lng::numeric)<=5000 -- Chuadanga
				or 
				data_vajapora.lat_long_dist_meters(23.5528, 89.1754, lat::numeric, lng::numeric)<=5000 -- Jhenaidah
				or 
				data_vajapora.lat_long_dist_meters(23.8052, 88.6724, lat::numeric, lng::numeric)<=5000 -- Meherpur
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