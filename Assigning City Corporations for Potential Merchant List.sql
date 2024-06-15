/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/1-ao6zoAcInUwHTraoqnsB0J5cO7dCyJnfg2sGos0iaw/edit#gid=0
- Function: 
- Table: I/P data_vajapora.whole_country_user_details_sorted, O/P data_vajapora.whole_country_user_details_sorted_clustered and data_vajapora.whole_country_user_details_sorted_clustered_2
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Re: Required potential Merchant list
- Notes (if any): 
	- Not all merchants will be covered. It's okay. 
	- 500m is mandatory for ease of visist. 
	- city corps added later as per Zarif Bhai's email specifications
*/

do $$

declare 
	var_lat numeric;
	var_lng numeric;
	var_seq int:=1; 
begin 
	raise notice 'New OP goes below:'; 
	
	-- merchants with lat-lng pairs
	drop table if exists data_vajapora.help_a;
	create table data_vajapora.help_a as
	select *
	from 
		(select *
		from digital_credit.whole_country_user_details_sorted 
		where flagged_biz_type in('GROCERY','pharmacy')
		) tbl1
		
		inner join 
		
		(select mobile, lat, lng
		from tallykhata.tallykhata_clients_location_info
		) tbl2 using(mobile);
	
	-- centroids of picked locations
	drop table if exists data_vajapora.help_b;
	create table data_vajapora.help_b as
	select 
		union_name, 
		avg(lat::numeric) avg_lat, 
		avg(lng::numeric) avg_lng, 
		count(mobile) merchants,
		row_number() over(order by union_name) seq
	from data_vajapora.help_a
	group by 1; 
	
	-- assign clusters anew (6 mins)
	truncate table data_vajapora.help_cluster; 
	loop	
		insert into data_vajapora.help_cluster
		select *, (select seq from data_vajapora.help_b where seq=var_seq) grp -- cluster
		from 
			data_vajapora.help_a tbl1
			
			inner join 
			
			(-- merchants within given radius
			select mobile
			from 
				(select *, 2*atan2(sqrt(a), sqrt(1-a))*r dist_meters
				from 
					(select *, sin(dlat/2)*sin(dlat/2)+cos(lat1*pi()/180)*cos(lat2 *pi()/180)*sin(dlon/2)*sin(dlon/2) a
					from 
						(select *, lat2*pi()/180-lat1*pi()/180 dlat, lon2*pi()/180-lon1*pi()/180 dlon
						from 
							(select 
								mobile, 
								6371000 r, 
								-- centroids
								(select avg_lat from data_vajapora.help_b where seq=var_seq) lat1, 
								(select avg_lng from data_vajapora.help_b where seq=var_seq) lon1,
								lat::numeric lat2, lng::numeric lon2
							from data_vajapora.help_a 
							) tbl3
						) tb4
					) tbl5
				) tbl6
			where dist_meters<=500 -- radius
			) tbl2 using(mobile);
				
		raise notice 'Data generated for: %', var_seq;
		var_seq:=var_seq+1;
		if var_seq=(select max(seq) from data_vajapora.help_b)+1 then exit;
		end if; 
	end loop;
	
end $$; 

-- see clusters assigned
drop table if exists data_vajapora.whole_country_user_details_sorted_clustered;
create table data_vajapora.whole_country_user_details_sorted_clustered as
select *
from 
	data_vajapora.help_a tbl1 
	
	left join 

	(select mobile, grp
	from 
		data_vajapora.help_cluster tbl1
		
		inner join 
		
		(-- select last cluster in case of multiple clusters
		select mobile, max(grp) grp 
		from data_vajapora.help_cluster
		group by 1
		) tbl2 using(mobile, grp)
	) tbl2 using(mobile); 

select *
from data_vajapora.whole_country_user_details_sorted_clustered;

-- see how many clusters created
select grp, count(mobile) merchants
from data_vajapora.help_cluster
group by 1
order by 2 desc; 

/* adding city corporations */

-- with city corporations
drop table if exists data_vajapora.whole_country_user_details_sorted_clustered_2;
create table data_vajapora.whole_country_user_details_sorted_clustered_2 as
select
	*,
	case 
		when city_corporation_name is not null then city_corporation_name
		when union_name in 
			('Turag',
			'Uttara Uttarkhan',
			'Dakkhinkhan',
			'Bimanbandar',
			'Khilkhet',
			'Vatara',
			'Badda',
			'Rampura',
			'Hatirjheel',
			'Tejgaon',
			'Sher-E-Bangla nagar',
			'Mohammadpur',
			'Adabor',
			'Darussalam',
			'Mirpur',
			'Pallabi',
			'Rupnagar',
			'Shah Ali',
			'Kafrul',
			'Bhashantek',
			'Cantonment',
			'Banani',
			'Gulshan'
			) then 'North City Corporation'
		when union_name in
			('Paltan',
			'Motijheel',
			'Sabujbagh',
			'Khilgaon',
			'Mugda',
			'Shahjahanpur',
			'Shampur',
			'Jatrabari',
			'Demra',
			'Kadamtali',
			'Gandaria',
			'Wari',
			'Ramna',
			'Shahbag',
			'Dhanmondi',
			'Hazaribagh',
			'Kalabgan',
			'Kotwali',
			'Sutrapur',
			'Lalbagh',
			'Bangsal',
			'Chawkbazar',
			'Kamrangirchar',
			'Keraniganj'
			) then 'South City Corporation'
		when union_name ilike '%bogra%' or union_name ilike '%bogura%' then 'Bogura Metro'
		when union_name ilike '%rajshahi%' then 'Rajshahi Metro'
		when union_name ilike '%chittagong%' or union_name ilike '%chattogram%' then 'Chittagong Metro'
		when union_name ilike '%sherpur%' then 'Sherpur Metro'
	end city_corporation_name_2
from data_vajapora.whole_country_user_details_sorted_clustered;

-- merchants from desired city corporations
select mobile, tallykhata_user_id, "name", shop_name, bi_business_type, business_type, business_age, business_address, device_brand, device_manufacturer, device_name, app_version_name, app_version_number, area_type, division, district, upazilla, "union", registration_date, rau_date, first_activity_date, last_activity_date, days_with_tallykhata, total_active_days, active_days_pct, active_days_journal, total_transaction_activity, cus_sup_add_activity, total_added_customer, total_added_supplier, active_days_in_last_7_days, last_7_days_trv, last_7_days_trt, active_days_in_last_15_days, last_15_days_trv, last_15_days_trt, active_days_in_last_30_days, last_30_days_trv, last_30_days_trt, active_days_in_last_60_days, last_60_days_trv, last_60_days_trt, active_days_in_last_90_days, last_90_days_trv, last_90_days_trt, total_credit_sales_trv, total_credit_sales_return_trv, total_cash_sales_trv, total_credit_purchase_trv, total_credit_purchase_return_trv, total_cash_purchase_trv, total_expense_trv, total_credit_sales_trt, total_credit_sales_return_trt, total_cash_sales_trt, total_credit_purchase_trt, total_credit_purchase_return_trt, total_cash_purchase_trt, total_expense_trt, total_trv_with_susp_txn, total_trt_with_susp_txn, total_trv_without_susp_txn, total_trt_without_susp_txn, sales_trv, sales_trt, credit_purchase_day_count, credit_sale_day_count, credit_sale_customer_count, credit_purchase_supplier_count, credit_sale_return_customer_count, credit_purchase_return_supplier_count, total_customer_count, total_supplier_count, data_generation_timestamp, score, flagged_biz_type, is_power_user, business_type_ad, division_name, division_id, district_name, district_id, upazilla_name, upazilla_id, union_name, union_id, city_corporation_id, new_bi_business_type, lat, lng, grp, city_corporation_name_2 city_corporation_name                   
from 
	(select *
	from data_vajapora.whole_country_user_details_sorted_clustered_2
	where city_corporation_name in('North City Corporation', 'South City Corporation')
	
	union 
	
	select *
	from data_vajapora.whole_country_user_details_sorted_clustered_2
	where city_corporation_name ilike '%bog%'
	
	union 
	
	select *
	from data_vajapora.whole_country_user_details_sorted_clustered_2
	where city_corporation_name ilike '%rajshahi%'
	
	union 
	
	select *
	from data_vajapora.whole_country_user_details_sorted_clustered_2
	where 
		city_corporation_name ilike '%chittagong%'
		or 
		city_corporation_name ilike '%chattogram%'
		
	union 
	
	select *
	from data_vajapora.whole_country_user_details_sorted_clustered_2
	where city_corporation_name ilike '%sherpur%'
	) tbl1; 

/* preferred changes made later */

-- with city corporations
drop table if exists test.whole_country_user_details_sorted_clustered_2_updated_3;
create table test.whole_country_user_details_sorted_clustered_2_updated_3 as
select
	*,
	case 
		when city_corporation_name is not null then city_corporation_name
		when
			union_name ilike '%Turag%' or
			union_name ilike '%Uttara Uttarkhan%' or
			union_name ilike '%Dakkhinkhan%' or
			union_name ilike '%Bimanbandar%' or
			union_name ilike '%Khilkhet%' or
			union_name ilike '%Vatara%' or
			union_name ilike '%Badda%' or
			union_name ilike '%Rampura%' or
			union_name ilike '%Hatirjheel%' or
			union_name ilike '%Tejgaon%' or
			union_name ilike '%Sher-E-Bangla nagar%' or
			union_name ilike '%Mohammadpur%' or
			union_name ilike '%Adabor%' or
			union_name ilike '%Darussalam%' or
			union_name ilike '%Mirpur%' or
			union_name ilike '%Pallabi%' or
			union_name ilike '%Rupnagar%' or
			union_name ilike '%Shah Ali%' or
			union_name ilike '%Kafrul%' or
			union_name ilike '%Bhashantek%' or
			union_name ilike '%Cantonment%' or
			union_name ilike '%Banani%' or
			union_name ilike '%Gulshan%' 
		then 'North City Corporation'
		when 
			union_name ilike '%Paltan%' or
			union_name ilike '%Motijheel%' or
			union_name ilike '%Sabujbagh%' or
			union_name ilike '%Khilgaon%' or
			union_name ilike '%Mugda%' or
			union_name ilike '%Shahjahanpur%' or
			union_name ilike '%Shampur%' or
			union_name ilike '%Jatrabari%' or
			union_name ilike '%Demra%' or
			union_name ilike '%Kadamtali%' or
			union_name ilike '%Gandaria%' or
			union_name ilike '%Wari%' or
			union_name ilike '%Ramna%' or
			union_name ilike '%Shahbag%' or
			union_name ilike '%Dhanmondi%' or
			union_name ilike '%Hazaribagh%' or
			union_name ilike '%Kalabgan%' or
			union_name ilike '%Kotwali%' or
			union_name ilike '%Sutrapur%' or
			union_name ilike '%Lalbagh%' or
			union_name ilike '%Bangsal%' or
			union_name ilike '%Chawkbazar%' or
			union_name ilike '%Kamrangirchar%' or
			union_name ilike '%Keraniganj%'
		then 'South City Corporation'
		when union_name ilike '%bogra%' or union_name ilike '%bogura%' then 'Bogura Metro'
		when union_name ilike '%rajshahi%' then 'Rajshahi Metro'
		when union_name ilike '%chittagong%' or union_name ilike '%chattogram%' then 'Chittagong Metro'
		when union_name ilike '%sherpur%' then 'Sherpur Metro'
	end city_corporation_name_4
from test.whole_country_user_details_sorted_clustered_2_updated_2; 


select city_corporation_name, count(mobile) merchants_found
from 
	(select mobile, tallykhata_user_id, "name", shop_name, bi_business_type, business_type, business_age, business_address, device_brand, device_manufacturer, device_name, app_version_name, app_version_number, area_type, division, district, upazilla, "union", registration_date, rau_date, first_activity_date, last_activity_date, days_with_tallykhata, total_active_days, active_days_pct, active_days_journal, total_transaction_activity, cus_sup_add_activity, total_added_customer, total_added_supplier, active_days_in_last_7_days, last_7_days_trv, last_7_days_trt, active_days_in_last_15_days, last_15_days_trv, last_15_days_trt, active_days_in_last_30_days, last_30_days_trv, last_30_days_trt, active_days_in_last_60_days, last_60_days_trv, last_60_days_trt, active_days_in_last_90_days, last_90_days_trv, last_90_days_trt, total_credit_sales_trv, total_credit_sales_return_trv, total_cash_sales_trv, total_credit_purchase_trv, total_credit_purchase_return_trv, total_cash_purchase_trv, total_expense_trv, total_credit_sales_trt, total_credit_sales_return_trt, total_cash_sales_trt, total_credit_purchase_trt, total_credit_purchase_return_trt, total_cash_purchase_trt, total_expense_trt, total_trv_with_susp_txn, total_trt_with_susp_txn, total_trv_without_susp_txn, total_trt_without_susp_txn, sales_trv, sales_trt, credit_purchase_day_count, credit_sale_day_count, credit_sale_customer_count, credit_purchase_supplier_count, credit_sale_return_customer_count, credit_purchase_return_supplier_count, total_customer_count, total_supplier_count, data_generation_timestamp, score, flagged_biz_type, is_power_user, business_type_ad, division_name, division_id, district_name, district_id, upazilla_name, upazilla_id, union_name, union_id, city_corporation_id, new_bi_business_type, lat, lng, grp, city_corporation_name_4 city_corporation_name   
	from test.whole_country_user_details_sorted_clustered_2_updated_3
	where 
		city_corporation_name_4 ilike '%north%'
		or 
		city_corporation_name_4 ilike '%south%'
		or
		city_corporation_name_4 ilike '%bog%'
		or 
		city_corporation_name_4 ilike '%rajshahi%'
		or 
		city_corporation_name_4 ilike '%sherpur%'
		or 
		city_corporation_name_4 ilike '%chatto%' or city_corporation_name_2 ilike '%chitta%'
	) tbl1 
group by 1; 



