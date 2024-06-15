/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/1cfP1Y4fuSiCymqrwsmlWRqYz6jGhZSgH1mpPvF1XO5g/edit#gid=353010335
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): 
	Tagada Message demand survey
	
	We will send Inapp to 50k merchants to know their response on-
	1. How many Tagada Message do they need in a month
	2. How much they want to pay for Tagada message in a month
	
	Will send message to 50k merchants
	- SPU 10k
	- PU 10k
	- 3RAU 10k
	- LT 20k
	
	Conditions
	- Retained and active in last 3 days
	- Grocery, Pharmacy, Wholesaler, SR
*/

drop table if exists data_vajapora.help_a; 
create table data_vajapora.help_a as 
select distinct mobile_no 
from tallykhata.tallykhata_sync_event_fact_final 
where 
	event_name='app_opened'
	and event_date>=current_date-3 and event_date<current_date; 

drop table if exists data_vajapora.help_b; 
create table data_vajapora.help_b as 
select 
	*, 
	case when bi_business_type in('Grocery Business', 'Other wholesaler goods/services business', 'Pharmacy Business') then 1 else 0 end if_desired_bi_type,
	case when bi_business_type in('OTHER BUSINESS') then 1 else 0 end if_other_bi_type
from 
	(select 
		mobile_no, 
		case 
			when mobile_no in
				(select mobile_no
				from tallykhata.tk_spu_aspu_data 
				where 
					pu_type='SPU'
					and report_date=current_date-1
				)
				then 'SPU'
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
	) tbl1 
	
	inner join 
	
	data_vajapora.help_a tbl2 using(mobile_no)
	
	inner join
	
	(select mobile mobile_no, bi_business_type
	from tallykhata.tallykhata_user_personal_info
	) tbl3 using(mobile_no); 

select 
	mobile_no, shop_name, segment, bi_business_type, 
	coalesce(tagada_used_months, 0) tagada_used_months, coalesce(ceil(tagada_usage_per_month), 0) tagada_used_per_month, 
	seq serial
from 
	(select *, row_number() over(partition by segment order by if_desired_bi_type desc, if_other_bi_type asc) seq
	from data_vajapora.help_b
	where segment in('3RAU', 'LTU', 'PU', 'SPU')
	) tbl1 
	
	left join
	
	(select mobile mobile_no, coalesce(shop_name, merchant_name, business_name) shop_name
	from tallykhata.tallykhata_user_personal_info
	) tbl2 using(mobile_no)
	
	left join 
	
	(select 
		merchant_mobile mobile_no, 
		count(distinct left(created_at::text, 7)) tagada_used_months, 
		count(id)*1.00/count(distinct left(created_at::text, 7)) tagada_usage_per_month
	from public.notification_tagadasms 
	group by 1
	) tbl3 using(mobile_no)
where 
	(segment in('3RAU', 'PU', 'SPU') and seq<=10000) 
	or 
	(segment in('LTU') and seq<=20000)
order by 3, 7; 
