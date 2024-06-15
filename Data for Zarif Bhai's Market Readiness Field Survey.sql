/*
- Viz: https://docs.google.com/spreadsheets/d/1vGSSGoiuN0WA09q8wbCSGl28RZs89EilZATFPL_N-pM/edit#gid=0
- Data: 
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: RE: Request For Merchant List for MFS Market Readiness Survey
- Notes (if any): 
*/

-- right locations
drop table if exists data_vajapora.help_c; 
create table data_vajapora.help_c as
-- inside Dhaka
select mobile, upazilla_name "location"
from 
	(select mobile, upazilla_name
	from tallykhata.tallykhata_clients_location_info tbl1 
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
	or upazilla_name ilike '%Shah Ali%'

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
select mobile, union_name "location"
from tallykhata.tallykhata_clients_location_info
where union_name in('Bhatara')

union all

-- for Ati Bazar
select mobile, 'Ati Bazar' "location"
from tallykhata.tallykhata_clients_location_info 
where data_vajapora.lat_long_dist_meters(23.8077, 90.4331, lat::numeric, lng::numeric)<500

union all

-- for Sadars
select mobile, upazilla_name "location"
from tallykhata.tallykhata_clients_location_info  
where upazilla_name in
	('Bogra Sadar',
	'Jamalpur Sadar',
	'Sherpur Sadar')
	
union all
	
-- for districts
select mobile, district_name "location"
from tallykhata.tallykhata_clients_location_info 
where district_name in
	('Jessore',
	'Rajshahi',
	'Chittagong'
	); 

-- SPUs
drop table if exists data_vajapora.help_a;
create table data_vajapora.help_a as
select distinct mobile_no spu_mobile_no, lat spu_lat, lng spu_lng, "location", full_address
from 
	tallykhata.tk_spu_aspu_data tbl1 
	
	inner join 
	
	(select mobile mobile_no, "location"
	from data_vajapora.help_c
	) tbl2 using(mobile_no)
	
	inner join 
	
	(select mobile mobile_no, lat::numeric, lng::numeric
	from tallykhata.tallykhata_clients_location_info 
	) tbl3 using(mobile_no)
	
	inner join 
	
	(select 
	    mobile mobile_no, 
		concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) full_address
	from tallykhata.tallykhata_clients_location_info
	) tbl4 using(mobile_no)
	
	inner join 
	
	(select mobile_no 
	from cjm_segmentation.retained_users 
	where report_date=current_date
	) tbl5 using(mobile_no)
where 
	report_date=current_date-1
	and pu_type in('SPU', 'ASPU'); 

-- deliver: SPUs
select spu_mobile_no, "location", full_address, shop_name, new_bi_business_type 
from 
	data_vajapora.help_a tbl1 

	inner join 
	
	(select mobile spu_mobile_no, shop_name, new_bi_business_type 
	from tallykhata.tallykhata_user_personal_info
	) tbl3 using(spu_mobile_no);

-- light users
drop table if exists data_vajapora.help_d;
create table data_vajapora.help_d as
select mobile_no lite_mobile_no, lat lite_lat, lng lite_lng, "location"
from 
	(select mobile_no, count(event_date) days_used_in_lft
	from tallykhata.tallykhata_user_date_sequence_final 
	group by 1 
	having count(event_date)>29
	) tbl1 
	
	inner join 
	
	(select mobile_no, count(event_date) days_used_last_30_days
	from tallykhata.tallykhata_user_date_sequence_final 
	where event_date>=current_date-30
	group by 1 
	having count(event_date)>3
	) tbl2 using(mobile_no)

	inner join 

	(select mobile mobile_no, "location"
	from data_vajapora.help_c
	) tbl3 using(mobile_no)

	inner join 
	
	(select mobile mobile_no, lat::numeric, lng::numeric
	from tallykhata.tallykhata_clients_location_info 
	) tbl4 using(mobile_no)
	
	left join 
	
	(select spu_mobile_no mobile_no 
	from data_vajapora.help_a
	) tbl5 using(mobile_no)
where tbl5.mobile_no is null; 

drop table if exists data_vajapora.help_b;
create table data_vajapora.help_b as
select *
from 
	data_vajapora.help_d tbl1

	inner join 
	
	(select mobile_no lite_mobile_no
	from cjm_segmentation.retained_users 
	where report_date=current_date
	) tbl2 using(lite_mobile_no); 

-- light users adjacent to SPUs
do $$

declare 
	var_seq int:=1; 
	max_seq int; 
begin 
	raise notice 'New OP goes below.'; 

	-- all locations
	drop table if exists data_vajapora.help_f; 
	create table data_vajapora.help_f as
	select *, row_number() over(order by "location") seq 
	from 
		(select distinct "location"
		from data_vajapora.help_c
		) tbl1;
	
	-- number of locations
	select max(seq) into max_seq 
	from data_vajapora.help_f; 

	loop
		delete from data_vajapora.help_e 
		where "location"=(select "location" from data_vajapora.help_f where seq=var_seq); 
	
		insert into data_vajapora.help_e
		select spu_mobile_no, lite_mobile_no, "location", full_address, data_vajapora.lat_long_dist_meters(spu_lat, spu_lng, lite_lat, lite_lng) distance_meters
		from 
			(select spu_mobile_no, spu_lat, spu_lng, "location"
			from data_vajapora.help_a
			where "location"=(select "location" from data_vajapora.help_f where seq=var_seq)
			) tbl1
			
			inner join 
			
			(select lite_mobile_no, lite_lat, lite_lng, "location"
			from data_vajapora.help_b
			where "location"=(select "location" from data_vajapora.help_f where seq=var_seq)
			) tbl2 using("location")
			
			inner join 
			
			(select 
			    mobile lite_mobile_no, 
				concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) full_address
			from tallykhata.tallykhata_clients_location_info
			) tbl3 using(lite_mobile_no)
		where 
			data_vajapora.lat_long_dist_meters(spu_lat, spu_lng, lite_lat, lite_lng)>0
			and data_vajapora.lat_long_dist_meters(spu_lat, spu_lng, lite_lat, lite_lng)<100; 
			
		commit; 
		raise notice 'Data generated for loc: %', var_seq; 
		var_seq:=var_seq+1; 
		if var_seq=max_seq+1 then exit; 
		end if; 
	end loop; 
end $$; 

-- deliver: light users
select spu_mobile_no, lite_mobile_no, "location", full_address, shop_name, new_bi_business_type, distance_meters
from 
	data_vajapora.help_e tbl1 
	
	inner join 
	
	(select lite_mobile_no, min(distance_meters) distance_meters 
	from data_vajapora.help_e 
	group by 1
	) tbl2 using(lite_mobile_no, distance_meters)
	
	inner join 
	
	(select mobile lite_mobile_no, shop_name, new_bi_business_type 
	from tallykhata.tallykhata_user_personal_info
	) tbl3 using(lite_mobile_no)
order by spu_mobile_no, distance_meters asc; 

-- normal users
drop table if exists data_vajapora.help_g;
create table data_vajapora.help_g as
select distinct mobile_no normal_user_mobile_no, "location", full_address
from 
	(select mobile_no, count(created_datetime) txn_days 
	from tallykhata.tallykhata_transacting_user_date_sequence_final 
	group by 1 
	having count(created_datetime) in(1, 2)
	) tbl1 
	
	inner join 
	
	(select mobile mobile_no, "location"
	from data_vajapora.help_c
	) tbl2 using(mobile_no)
	
	inner join 
	
	(select 
	    mobile mobile_no, 
		concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) full_address
	from tallykhata.tallykhata_clients_location_info
	) tbl4 using(mobile_no)
	
	inner join 
	
	(select mobile_no 
	from cjm_segmentation.retained_users 
	where report_date=current_date
	) tbl5 using(mobile_no)
	
	left join 
	
	(select spu_mobile_no mobile_no
	from data_vajapora.help_a 
	
	union all 
	
	select lite_mobile_no mobile_no
	from data_vajapora.help_b 
	) tbl6 using(mobile_no)
where tbl6.mobile_no is null; 

-- deliver: normal users
select *
from 
	data_vajapora.help_g tbl1
	inner join 
	(select mobile normal_user_mobile_no, shop_name, new_bi_business_type 
	from tallykhata.tallykhata_user_personal_info
	) tbl2 using(normal_user_mobile_no); 
