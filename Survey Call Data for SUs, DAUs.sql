/*
- Viz: 
- Data: 
	-  Data Set-1: SC-SU-C0522: https://docs.google.com/spreadsheets/d/1cfP1Y4fuSiCymqrwsmlWRqYz6jGhZSgH1mpPvF1XO5g/edit#gid=17094737
	-  Data Set-2: SC-DAU-C0522: https://docs.google.com/spreadsheets/d/1cfP1Y4fuSiCymqrwsmlWRqYz6jGhZSgH1mpPvF1XO5g/edit#gid=527425032
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Request For Survey Data!
- Notes (if any): 
*/

/*
Data Set-1: SC-SU-C0522
# Conditions:
1. Whose tag was SU on March & April 2022 but not used for the last 15 days
2. From retained/uninstalled base
*/

-- main base
drop table if exists data_vajapora.temp_a; 
create table data_vajapora.temp_a as
select distinct mobile_no 
from 
	(select mobile_no 
	from tallykhata.tk_spu_aspu_data 
	where 
		pu_type in('SPU') 
		and report_date='2022-04-30'::date
	) tbl1 
	
	left join 
		
	(select mobile_no 
	from tallykhata.tallykhata_user_date_sequence_final 
	where event_date>current_date-16
	) tbl2 using(mobile_no)
where tbl2.mobile_no is null; 

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
select mobile_no, shop_name, merchant_name, biz_type, reg_date, tg_before_eid, tg_after_eid, district, thana, last_active_date
from 
	data_vajapora.temp_a tbl1 
	
	inner join 
	
	data_vajapora.temp_b tbl2 using(mobile_no)
	
	inner join 

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
		end tg_before_eid 
	from cjm_segmentation.retained_users
	where report_date='2022-04-27'
	) tbl3 using(mobile_no)
	
	inner join 
	
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
		end tg_after_eid 
	from cjm_segmentation.retained_users
	where report_date=current_date
	) tbl4 using(mobile_no)
	
	inner join 
	
	(select mobile mobile_no, max(district_name) district, max(upazilla_name) thana  
	from tallykhata.tallykhata_clients_location_info 
	group by 1
	) tbl5 using(mobile_no)
	
	inner join 
	
	(select mobile_no, max(event_date) last_active_date
	from tallykhata.tallykhata_user_date_sequence_final 
	where 
		mobile_no in(select mobile_no from data_vajapora.temp_a) 
		and event_date<=current_date
	group by 1
	) tbl6 using(mobile_no)
where biz_type is not null
order by random()
limit 100; 

/*
Data Set-2: SC-DAU-C0522
# Conditions:
1. Who used(txn) TK in March & April for at least 5 days each month but did not open the app on May 2022
2. From retained base
*/

-- main base
drop table if exists data_vajapora.temp_a; 
create table data_vajapora.temp_a as
select distinct mobile_no 
from 
	(select mobile_no
	from tallykhata.tallykhata_transacting_user_date_sequence_final 
	where left(created_datetime::text, 7)='2022-03'
	group by 1
	having count(created_datetime)>4
	) tbl1 
	
	inner join 
	
	(select mobile_no
	from tallykhata.tallykhata_transacting_user_date_sequence_final 
	where left(created_datetime::text, 7)='2022-04'
	group by 1
	having count(created_datetime)>4
	) tbl3 using(mobile_no)
	
	left join 
		
	(select mobile_no 
	from tallykhata.tallykhata_user_date_sequence_final 
	where event_date>='2022-05-01'
	) tbl2 using(mobile_no)
where tbl2.mobile_no is null; 

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
select mobile_no, shop_name, merchant_name, biz_type, reg_date, tg_before_eid, tg_after_eid, district, thana, last_active_date
from 
	data_vajapora.temp_a tbl1 
	
	inner join 
	
	data_vajapora.temp_b tbl2 using(mobile_no)
	
	inner join 

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
		end tg_before_eid 
	from cjm_segmentation.retained_users
	where report_date='2022-04-27'
	) tbl3 using(mobile_no)
	
	inner join 
	
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
		end tg_after_eid 
	from cjm_segmentation.retained_users
	where report_date=current_date
	) tbl4 using(mobile_no)
	
	inner join 
	
	(select mobile mobile_no, max(district_name) district, max(upazilla_name) thana  
	from tallykhata.tallykhata_clients_location_info 
	group by 1
	) tbl5 using(mobile_no)
	
	inner join 
	
	(select mobile_no, max(event_date) last_active_date
	from tallykhata.tallykhata_user_date_sequence_final 
	where 
		mobile_no in(select mobile_no from data_vajapora.temp_a) 
		and event_date<=current_date
	group by 1
	) tbl6 using(mobile_no)
where biz_type is not null
order by random()
limit 100; 