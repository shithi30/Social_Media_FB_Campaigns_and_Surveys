/*
- Viz: 
- Data: 
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Re: Request for merchant list for survey
- Notes (if any): 
*/

-- nuclear merchants to visit
drop table if exists data_vajapora.survey_merchants_locations; 
create table data_vajapora.survey_merchants_locations as
-- inside Dhaka
select *
from 
	(select 
	    mobile, 
	    lat, lng, 
		division_name, district_name, upazilla_name, union_name, city_corporation_name,
		upazilla_name location_for_survey, 
		concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address
	from 
		tallykhata.tallykhata_clients_location_info tbl1 
		inner join 
		(-- PUs
		select mobile_no mobile
		from tallykhata.tk_power_users_10 
		where report_date=current_date-1
		
		union 
		
		-- SPUs
		select mobile_no mobile
		from tallykhata.tk_power_users_10 
		where 
			report_date=current_date-1
			and total_active_days>=20
		) tbl2 using(mobile)
	where district_name='Dhaka'
	) tbl1
where 
	-- Dhaka North
	   upazilla_name ilike '%Turag%'
	or upazilla_name ilike '%Uttara%'
	or upazilla_name ilike '%khan%'
	or upazilla_name ilike '%Biman%'
	or upazilla_name ilike '%Khilkhet%'
	or upazilla_name ilike '%Badda%'
	or upazilla_name ilike '%Rampura%'
	or upazilla_name ilike '%Hatirjheel%'
	or upazilla_name ilike '%Shilpanchal%'
	or upazilla_name ilike '%Tejgaon%'
	or upazilla_name ilike '%Sher-E-Bangla nagar%'
	or upazilla_name ilike '%Mohammadpur%'
	or upazilla_name ilike '%Adabor%'
	or upazilla_name ilike '%Darussalam%'
	or upazilla_name ilike '%Mirpur%'
	or upazilla_name ilike '%Pallabi%'
	or upazilla_name ilike '%Rupnagar%'
	or upazilla_name ilike '%Shahali%'
	or upazilla_name ilike '%Kafrul%'
	or upazilla_name ilike '%Bhashantek%'
	or upazilla_name ilike '%Cantonment%'
	or upazilla_name ilike '%Banani%'
	or upazilla_name ilike '%Gulshan%'
	or upazilla_name ilike '%Savar%'
	or upazilla_name ilike '%Ashulia%'

	-- Dhaka South
	or upazilla_name ilike '%Paltan%'
	or upazilla_name ilike '%Motijheel%'
	or upazilla_name ilike '%Sabujbagh%'
	or upazilla_name ilike '%Khilgaon%'
	or upazilla_name ilike '%Mugda%'
	or upazilla_name ilike '%Shahjahanpur%'
	or upazilla_name ilike '%Shampur%'
	or upazilla_name ilike '%Jatrabari%'
	or upazilla_name ilike '%Demra%'
	or upazilla_name ilike '%Kadamtali%'
	or upazilla_name ilike '%Gandaria%'
	or upazilla_name ilike '%Wari%'
	or upazilla_name ilike '%Ramna%'
	or upazilla_name ilike '%Shahbag%'
	or upazilla_name ilike '%Dhanmondi%'
	or upazilla_name ilike '%Hazaribagh%'
	or upazilla_name ilike '%Kalabgan%'
	or upazilla_name ilike '%Kotwali%'
	or upazilla_name ilike '%Sutrapur%'
	or upazilla_name ilike '%Lalbagh%'
	or upazilla_name ilike '%Bangsal%'
	or upazilla_name ilike '%Chawkbazar%'
	or upazilla_name ilike '%Kamrangirchar%'
	or upazilla_name ilike '%Demra%'
	or upazilla_name ilike '%Nawabganj%'
	or upazilla_name ilike '%Keraniganj%'
	
union all

-- for Bhatara
select 
    mobile, 
    lat, lng, 
	division_name, district_name, upazilla_name, union_name, city_corporation_name,
	union_name location_for_survey, 
	concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address
from 
	tallykhata.tallykhata_clients_location_info tbl1 
	inner join 
	(-- PUs
	select mobile_no mobile
	from tallykhata.tk_power_users_10 
	where report_date=current_date-1
	
	union 
	
	-- SPUs
	select mobile_no mobile
	from tallykhata.tk_power_users_10 
	where 
		report_date=current_date-1
		and total_active_days>=20
	) tbl2 using(mobile)
where union_name='Bhatara'

union all

-- for Sadars
select 
    mobile, 
    lat, lng, 
	division_name, district_name, upazilla_name, union_name, city_corporation_name,
	upazilla_name location_for_survey, 
	concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address
from 
	tallykhata.tallykhata_clients_location_info tbl1 
	inner join 
	(-- PUs
	select mobile_no mobile
	from tallykhata.tk_power_users_10 
	where report_date=current_date-1
	
	union 
	
	-- SPUs
	select mobile_no mobile
	from tallykhata.tk_power_users_10 
	where 
		report_date=current_date-1
		and total_active_days>=20
	) tbl2 using(mobile)
where upazilla_name in
	('Bogra Sadar',
	'Jamalpur Sadar',
	'Joypurhat Sadar',
	'Naogaon Sadar',
	'Natore Sadar',
	'Pabna Sadar',
	'Sherpur Sadar',
	'Sirajganj Sadar',
	'Tangail Sadar'
	)
	
union all
	
-- for districts
select 
    mobile, 
    lat, lng, 
	division_name, district_name, upazilla_name, union_name, city_corporation_name,
	district_name location_for_survey, 
	concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address
from 
	tallykhata.tallykhata_clients_location_info tbl1 
	inner join 
	(-- PUs
	select mobile_no mobile
	from tallykhata.tk_power_users_10 
	where report_date=current_date-1
	
	union 
	
	-- SPUs
	select mobile_no mobile
	from tallykhata.tk_power_users_10 
	where 
		report_date=current_date-1
		and total_active_days>=20
	) tbl2 using(mobile)
where district_name in
	(-- Chapainawabganj not found
	'Jessore',
	'Rajshahi',
	'Chittagong'
	); 

select *
from data_vajapora.survey_merchants_locations; 

-- LTU merchants to visit
drop table if exists data_vajapora.survey_ltu_merchants_locations;
create table data_vajapora.survey_ltu_merchants_locations as
select *
from 
	(select *, data_vajapora.lat_long_dist_meters(lat_ltu, lng_ltu, lat_location, lng_location) distance_from_survey_location
	from 
		(select mobile_no mobile, tg
		from cjm_segmentation.retained_users
		where 
			report_date=current_date-1
			and tg in('LTUTa', 'LTUCb')
		) tbl1 
			
		inner join 
			
		(select mobile, lat::numeric lat_ltu, lng::numeric lng_ltu
		from tallykhata.tallykhata_clients_location_info 
		) tbl2 using(mobile), 
	
		(select location_for_survey, avg(lat::numeric) lat_location, avg(lng::numeric) lng_location
		from data_vajapora.survey_merchants_locations
		group by 1
		) tbl3
	) tbl1 
where distance_from_survey_location<=500; 

select *
from data_vajapora.survey_ltu_merchants_locations;
	