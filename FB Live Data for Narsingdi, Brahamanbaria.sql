/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/1lLAva_M3ZMK_9xVXLFqwfMztesp3KfrydWGhmWux2Hc/edit#gid=1869281681
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

-- used nilo-dilo
drop table if exists data_vajapora.help_b;
create table data_vajapora.help_b as
select mobile_no, count(auto_id) malik_dilo_nilo_trt
from tallykhata.tallykhata_fact_info_final 
where txn_type in('MALIK_NILO', 'MALIK_DILO')
group by 1
having count(auto_id)>0;
	
-- mins with TK
drop table if exists data_vajapora.help_c;
create table data_vajapora.help_c as
select mobile_no, sum(sec_with_tk)/60.00 mins_with_tk_last_7_days
from tallykhata.daily_times_spent_individual_data
where event_date>=current_date-7 and event_date<current_date
group by 1;
	
-- PUs
drop table if exists data_vajapora.help_d;
create table data_vajapora.help_d as
select distinct mobile_no
from tallykhata.tk_power_users_10
where report_date=current_date-1;

-- active last 7 days
drop table if exists data_vajapora.help_e;
create table data_vajapora.help_e as
select mobile_no, count(event_date) usage_last_7_days, max(event_date) last_active_date
from tallykhata.tallykhata_user_date_sequence_final 
where event_date>=current_date-7 and event_date<current_date
group by 1;

-- generate top-50 merchants for each district
drop table if exists data_vajapora.help_a; 
create table data_vajapora.help_a as
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
			when district_name='Narsingdi' then data_vajapora.lat_long_dist_meters(23.9193, 90.7176, lat::numeric, lng::numeric) 
			when district_name='Brahamanbaria' then data_vajapora.lat_long_dist_meters(23.9675, 91.1119, lat::numeric, lng::numeric) 
		end distance, 
		row_number() over(partition by district_name order by malik_dilo_nilo_trt desc, usage_last_7_days desc, mins_with_tk_last_7_days desc) seq
	from 
		(select mobile mobile_no, district_name, concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address, area_type, lat, lng
		from tallykhata.tallykhata_clients_location_info
		where 
			district_name in('Narsingdi', 'Brahamanbaria')
			and (city_corporation_name ilike '%city%' or city_corporation_name ilike '%sadar%' or city_corporation_name ilike '%municipality%' or city_corporation_name ilike '%paurashava%')                                               
			and 
				(data_vajapora.lat_long_dist_meters(23.9193, 90.7176, lat::numeric, lng::numeric)<=2000 -- Narsingdi
				or 
				data_vajapora.lat_long_dist_meters(23.9675, 91.1119, lat::numeric, lng::numeric)<=2000 -- Brahamanbaria
				)			
		) tbl1 
		inner join 
		data_vajapora.help_b tbl2 using(mobile_no)
		inner join 
		data_vajapora.help_c tbl3 using(mobile_no)
		inner join 
		data_vajapora.help_d tbl4 using(mobile_no)
		inner join 
		data_vajapora.help_e tbl5 using(mobile_no)
	) tbl1
	
	left join

	(select 
		mobile mobile_no, 
		case when shop_name is not null then shop_name else business_name end shop_name,
		merchant_name
	from tallykhata.tallykhata_user_personal_info
	) tbl2 using(mobile_no)
where seq<=50; 

select *
from data_vajapora.help_a; 

-- sanity check
select district_name, count(*) merchants
from data_vajapora.help_a
group by 1; 

