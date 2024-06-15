/*
- Viz: https://docs.google.com/spreadsheets/d/1cfP1Y4fuSiCymqrwsmlWRqYz6jGhZSgH1mpPvF1XO5g/edit#gid=1936942024
- Data: 
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

drop table if exists data_vajapora.help_c; 
create table data_vajapora.help_c as
select mobile_no, left(created_datetime::text, 7) year_month, count(distinct contact) customers_ret
from tallykhata.tallykhata_fact_info_final 
where 
	txn_type='CREDIT_SALE_RETURN'
	and created_datetime>='2022-03-01' and created_datetime<='2022-05-31'
group by 1, 2
having count(distinct contact)>9;

drop table if exists data_vajapora.help_b; 
create table data_vajapora.help_b as
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
	end biz_type
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
		max(new_bi_business_type) new_bi_business_type
	from tallykhata.tallykhata_user_personal_info 
	group by 1
	) tbl3 using(mobile_no); 

drop table if exists data_vajapora.help_a; 
create table data_vajapora.help_a as
select * 
from 
	(select distinct mobile_no 
	from cjm_segmentation.retained_users 
	where 
		report_date=current_date
		and tg in('SPU')
	) tbl1 
	
	inner join 
		
	(select mobile_number mobile_no 
	from public.register_usermobile 
	where current_date-date(created_at)>=365
	) tbl2 using(mobile_no)
	
	inner join 
	
	(select mobile_no
	from data_vajapora.help_c 
	group by 1 
	having count(*)>2
	) tbl3 using(mobile_no) 
	
	inner join 
	
	(select mobile_no 
	from data_vajapora.help_b
	where biz_type='GROCERY'
	) tbl4 using(mobile_no)

	left join 
		
	(select 
		mobile mobile_no, 
		max(registration_date) reg_date, 
		max(case when shop_name is not null then shop_name else business_name end) shop_name,
		max(merchant_name) merchant_name
	from tallykhata.tallykhata_user_personal_info 
	group by 1
	) tbl5 using(mobile_no)
	
	left join 
		
	(select mobile mobile_no, max(district_name) district, max(upazilla_name) thana  
	from tallykhata.tallykhata_clients_location_info 
	group by 1
	) tbl6 using(mobile_no); 

select * 
from data_vajapora.help_a
limit 400; 
