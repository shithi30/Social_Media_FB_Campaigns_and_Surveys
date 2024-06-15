/*
- Viz: https://docs.google.com/spreadsheets/d/1cfP1Y4fuSiCymqrwsmlWRqYz6jGhZSgH1mpPvF1XO5g/edit#gid=809856607
- Data: 
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): 
	Hi Mahmud, we will survey this SPU churn segment ('ch-zombie' and 'ch-uninstalled'). Please share 200 users number from each month.
	From Jul 20 to Nov 21.
	Information:
	
	TK mobile number
	Biz name
	Owner name
	Biz Type
	Registration Date
	First SPU date
	Last Active date
	Address
	Thana
	District
	
	Kindly share the list.
*/

drop table if exists data_vajapora.help_a; 
create table data_vajapora.help_a as
select mobile_no, reg_month, reg_date, coalesce(segment, 'uninstalled') segment
from 
	(select left(date(created_at)::text, 7) reg_month, date(created_at) reg_date, mobile_number mobile_no
	from public.register_usermobile  
	) tbl1 
	
	left join 
	
	(select distinct mobile_no
	from tallykhata.tk_spu_aspu_data 
	where pu_type='SPU'
	) tbl2 using(mobile_no)
	
	left join 
	
	(select mobile_no
	from tallykhata.tk_spu_aspu_data 
	where 
		pu_type='SPU'
		and report_date=current_date-1
	) tbl3 using(mobile_no)
	
	left join 
	
	(select 
		mobile_no, 
		case 
			when tg in('3RAUCb','3RAU Set-A','3RAU Set-B','3RAU Set-C','3RAUTa','3RAUTa+Cb','3RAUTacs') then '3RAU'
			when tg in('LTUCb','LTUTa') then 'LTU'
			when tg in('NT--') then 'NT'
			when tg in('NB0','NN1','NN2-6') then 'NN'
			when tg in('PSU') then 'PSU'
			when tg in('PUCb','PU Set-A','PU Set-B','PU Set-C','PUTa','PUTa+Cb','PUTacs') then 'PU'
			when tg in('ZCb','ZTa','ZTa+Cb') then 'Zombie' 
		end segment
	from cjm_segmentation.retained_users 
	where report_date=current_date
	) tbl4 using(mobile_no)
where 
	reg_date>='2020-07-01'::date and reg_date<'2021-12-01'::date
	and tbl2.mobile_no is not null 
	and tbl3.mobile_no is null 
	and (segment='Zombie' or segment is null); 

drop table if exists data_vajapora.help_b; 
create table data_vajapora.help_b as
select mobile_no, max(event_date) last_active_date 
from tallykhata.tallykhata_user_date_sequence_final
where event_date<current_date
group by 1; 

select 
	mobile_no,
	reg_month,
	segment,
	reg_date,
	shop_name,
	merchant_name,
	bi_business_type,
	district_name,
	upazilla_name,
	shop_address,
	first_spu_date,
	last_active_date,
	"serial"
from 
	(select *, row_number() over(partition by reg_month order by if_desired_bi_type desc) serial
	from 
		data_vajapora.help_a tbl1 
		
		inner join 
		
		(select 
			mobile mobile_no, 
			coalesce(shop_name, business_name) shop_name, 
			merchant_name, 
			bi_business_type, 
			case when bi_business_type='OTHER BUSINESS' then 0 else 1 end if_desired_bi_type
		from tallykhata.tallykhata_user_personal_info
		) tbl2 using(mobile_no)
		
		inner join 
		
		(select mobile mobile_no, district_name, upazilla_name, concat(division_name, ', ', district_name, ', ', upazilla_name, ', ', union_name, ', ', city_corporation_name) shop_address                           
		from tallykhata.tallykhata_clients_location_info
		) tbl3 using(mobile_no)
		
		inner join 
		
		(select mobile_no, min(report_date) first_spu_date 
		from tallykhata.tk_spu_aspu_data 
		where pu_type='SPU'
		group by 1
		) tbl4 using(mobile_no)
	
		inner join 
		
		data_vajapora.help_b tbl5 using(mobile_no)
	) tbl1 
where serial<=200; 
		
