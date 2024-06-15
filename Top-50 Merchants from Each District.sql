/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/1lLAva_M3ZMK_9xVXLFqwfMztesp3KfrydWGhmWux2Hc/edit#gid=0
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Fwd: Request for Merchant info
- Notes (if any): Some districts could not fulfill 50 quota, it's okay. 
*/

do $$

declare
	max_seq int:=64;
	var_seq int:=1;
	var_dist text;
begin 	
	raise notice '% districts to analyze.', max_seq; 

	-- all districts
	drop table if exists data_vajapora.help_f;
	create table data_vajapora.help_f as
	select *, row_number() over(order by district_name) seq
	from 
		(select distinct district_name
		from tallykhata.tallykhata_clients_location_info
		) tbl1;
	
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
	from tallykhata.tallykhata.daily_times_spent_individual_data
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

	-- desired BI-types
	drop table if exists data_vajapora.help_g;
	create table data_vajapora.help_g as
	select mobile mobile_no
	from tallykhata.tallykhata_user_personal_info
	where 
		bi_business_type ilike '%grocery%'
		or bi_business_type ilike '%pharmacy%';

	-- generate top-50 merchants for each district
	loop
		select district_name 
		into var_dist
		from data_vajapora.help_f
		where seq=var_seq; 
	
		delete from data_vajapora.top_50_from_each_district
		where district_name=var_dist; 
	
		insert into data_vajapora.top_50_from_each_district
		select *
		from 
			(select *, row_number() over(order by malik_dilo_nilo_trt desc, usage_last_7_days desc, mins_with_tk_last_7_days desc) seq
			from 
				(select var_dist district_name, mobile mobile_no
				from tallykhata.tallykhata_clients_location_info
				where district_name=var_dist
				) tbl1 
				inner join 
				data_vajapora.help_b tbl2 using(mobile_no)
				inner join 
				data_vajapora.help_c tbl3 using(mobile_no)
				inner join 
				data_vajapora.help_d tbl4 using(mobile_no)
				inner join 
				data_vajapora.help_e tbl5 using(mobile_no)
				inner join 
				data_vajapora.help_g tbl6 using(mobile_no)
			) tbl1
		order by seq
		limit 50; 
		
		raise notice '%. Merchants identified for district: %', var_seq, var_dist;
		var_seq:=var_seq+1;
		if var_seq=max_seq+1 then exit;
		end if; 
	end loop; 
end $$; 

select *
from data_vajapora.top_50_from_each_district; 

select district_name, count(mobile_no) merchants_identified
from data_vajapora.top_50_from_each_district
group by 1; 

select
	district_name, 
	seq top_n,
	mobile_no, 
	upazilla_name,
	last_active_date, 
	bi_business_type, 
	business_name, 
	merchant_name
from 
	data_vajapora.top_50_from_each_district tbl1

	left join

	(select 
		mobile mobile_no, 
		bi_business_type, 
		case when business_name is not null then business_name else shop_name end business_name,
		merchant_name
	from tallykhata.tallykhata_user_personal_info
	) tbl2 using(mobile_no)
	
	left join 
		
	(select mobile mobile_no, upazilla_name
	from tallykhata.tallykhata_clients_location_info
	) tbl3 using(mobile_no)
order by 1, 2; 