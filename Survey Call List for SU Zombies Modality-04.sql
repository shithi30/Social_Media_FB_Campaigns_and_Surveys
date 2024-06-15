/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/1cfP1Y4fuSiCymqrwsmlWRqYz6jGhZSgH1mpPvF1XO5g/edit?pli=1#gid=172352080
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): 
	4th modality here (F column): https://docs.google.com/spreadsheets/d/1cfP1Y4fuSiCymqrwsmlWRqYz6jGhZSgH1mpPvF1XO5g/edit?pli=1#gid=1529678974
*/

-- main base
drop table if exists data_vajapora.temp_a; 
create table data_vajapora.temp_a as
select tbl1.mobile_no, su_zombie_date, count(distinct created_datetime) txn_days_after_su_zombie
from 
	(select mobile_no, max(report_date) su_zombie_date
	from data_vajapora.txn_su_churn_7_days_txn_details
	where report_date>='07-May-22'::date
	group by 1
	order by random() 
	limit 1000
	) tbl1 
	
	left join 
	
	(select mobile_no, created_datetime
	from tallykhata.tallykhata_transacting_user_date_sequence_final 
	where created_datetime>='07-May-22'::date and created_datetime<current_date
	) tbl2 on(tbl1.mobile_no=tbl2.mobile_no and tbl1.su_zombie_date<tbl2.created_datetime)
group by 1, 2;
-- having (su_zombie_date+6+count(distinct created_datetime)::int)>=current_date-1; 

-- personal info. 
drop table if exists data_vajapora.temp_b; 
create table data_vajapora.temp_b as
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
	end biz_type, 
	reg_date, 
	shop_name, 
	merchant_name
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
		max(registration_date) reg_date, 
		max(case when shop_name is not null then shop_name else business_name end) shop_name,
		max(merchant_name) merchant_name
	from tallykhata.tallykhata_user_personal_info 
	group by 1
	) tbl3 using(mobile_no); 

-- all info. combined
select mobile_no, shop_name, merchant_name, biz_type, reg_date, su_zombie_date, txn_days_after_su_zombie, latest_tg, district, thana, last_active_date
from 
	data_vajapora.temp_a tbl1 
	
	left join 
	
	data_vajapora.temp_b tbl2 using(mobile_no)
	
	left join 
	
	(select 
		mobile_no, 
		case 
			when tg in('3RAUCb','3RAU Set-A','3RAU Set-B','3RAU Set-C','3RAUTa','3RAUTa+Cb','3RAUTacs') then '3RAU'
			when tg in('LTUCb','LTUTa') then 'LTU'
			when tg in('NB0','NN1','NN2-6') then 'NN'
			when tg in('NT--') then 'NT'
			when tg in('PSU') then 'PSU'
			when tg in('PUCb','PU Set-A','PU Set-B','PU Set-C','PUTa','PUTa+Cb','PUTacs') then 'PU'
			when tg in('SPU') then 'SU'
			when tg in('ZCb','ZTa','ZTa+Cb') then 'Zombie'
			else null
		end latest_tg 
	from cjm_segmentation.retained_users
	where report_date=current_date
	) tbl4 using(mobile_no)
	
	left join 
	
	(select mobile mobile_no, max(district_name) district, max(upazilla_name) thana  
	from tallykhata.tallykhata_clients_location_info 
	group by 1
	) tbl5 using(mobile_no)
	
	left join 
	
	(select mobile_no, max(event_date) last_active_date
	from tallykhata.tallykhata_user_date_sequence_final 
	where 
		mobile_no in(select mobile_no from data_vajapora.temp_a) 
		and event_date<=current_date
	group by 1
	) tbl6 using(mobile_no); 
