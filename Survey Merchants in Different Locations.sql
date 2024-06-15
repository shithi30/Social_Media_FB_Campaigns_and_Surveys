/*
- Viz: 
- Data: 
	- holistic: https://docs.google.com/spreadsheets/d/1lLAva_M3ZMK_9xVXLFqwfMztesp3KfrydWGhmWux2Hc/edit#gid=596921701 
	- filtered by locations: https://docs.google.com/spreadsheets/d/1lLAva_M3ZMK_9xVXLFqwfMztesp3KfrydWGhmWux2Hc/edit#gid=167763067
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Required Merchant Number with Address
- Notes (if any): 
*/

-- TRV >= 3 times more of Tally TRV (last 30 days)
drop table if exists data_vajapora.help_a; 
create table data_vajapora.help_a as
select 
	mobile_no, 
	sum(input_amount) total_trv, 
	sum(case when txn_type in('CREDIT_SALE_RETURN', 'CREDIT_PURCHASE', 'CREDIT_PURCHASE_RETURN', 'CREDIT_SALE') then input_amount else 0 end) credit_trv
from tallykhata.tallykhata_fact_info_final 
where 
	created_datetime>=current_date-30 and created_datetime<current_date
	and is_suspicious_txn=0
group by 1; 

drop table if exists data_vajapora.help_b; 
create table data_vajapora.help_b as
select mobile_no mobile, new_bi_business_type
from 
	(select mobile_no
	from data_vajapora.help_a
	where total_trv>=3*credit_trv
	) tbl0 
	
	inner join 

	(-- Grocery & Pharmacy 
	select distinct mobile mobile_no, new_bi_business_type
	from tallykhata.tallykhata_user_personal_info 
	where new_bi_business_type in('Grocery', 'Pharmacy')
	) tbl1 using(mobile_no)
	
	inner join 
	
	(-- >=30 txn days in total
	select mobile_no, count(created_datetime) txn_days 
	from tallykhata.tallykhata_transacting_user_date_sequence_final 
	group by 1 
	having count(created_datetime)>29
	) tbl2 using(mobile_no)
	
	inner join 
	
	(-- 20 txn/week
	select mobile_no, count(auto_id) txns_last_week 
	from tallykhata.tallykhata_fact_info_final 
	where created_datetime>=current_date-7 and created_datetime<current_date
	group by 1 
	having count(auto_id)>19
	) tbl3 using(mobile_no)
	
	inner join 
	
	(-- 20 minute/week
	select mobile_no, sum(sec_with_tk) time_last_week
	from tallykhata.daily_times_spent_individual_data 
	where event_date>=current_date-7 and event_date<current_date
	group by 1 
	having sum(sec_with_tk)>20*60-1
	) tbl4 using(mobile_no);

-- shop names
drop table if exists data_vajapora.help_c; 
create table data_vajapora.help_c as
select mobile, shop_name, new_bi_business_type
from 
	data_vajapora.help_b tbl1 
	left join 
	(select mobile, case when shop_name is not null then shop_name else merchant_name end shop_name
	from tallykhata.tallykhata_user_personal_info
	) tbl2 using(mobile); 

-- holistic set
select *
from 
	data_vajapora.help_c tbl1 
	left join 
	(select mobile, district_name, concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address
	from tallykhata.tallykhata_clients_location_info 
	) tbl2 using(mobile); 

-- set by locations
drop table if exists data_vajapora.survey_merchants_locations; 
create table data_vajapora.survey_merchants_locations as
-- inside Dhaka
select mobile, shop_name, upazilla_name "location", new_bi_business_type
from 
	(select mobile, shop_name, upazilla_name, new_bi_business_type
	from 
		tallykhata.tallykhata_clients_location_info tbl1 
		inner join 
		data_vajapora.help_c tbl2 using(mobile)
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

-- for Bhatara, Chapai
select mobile, shop_name, union_name "location", new_bi_business_type
from 
	tallykhata.tallykhata_clients_location_info tbl1 
	inner join 
	data_vajapora.help_c tbl2 using(mobile)
where union_name in('Bhatara', 'Chapai Nababganj Paurashava')

union all

-- for Sadars
select mobile, shop_name, upazilla_name "location", new_bi_business_type
from 
	tallykhata.tallykhata_clients_location_info tbl1 
	inner join 
	data_vajapora.help_c tbl2 using(mobile)
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
select mobile, shop_name, district_name "location", new_bi_business_type
from 
	tallykhata.tallykhata_clients_location_info tbl1 
	inner join 
	data_vajapora.help_c tbl2 using(mobile)
where district_name in
	('Jessore',
	'Rajshahi',
	'Chittagong'
	); 

select *
from 
	data_vajapora.survey_merchants_locations tbl1 
	inner join 
	(select mobile, concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address
	from tallykhata.tallykhata_clients_location_info 
	) tbl2 using(mobile); 
	