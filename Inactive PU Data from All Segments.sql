/*
- Viz: https://docs.google.com/spreadsheets/d/1cfP1Y4fuSiCymqrwsmlWRqYz6jGhZSgH1mpPvF1XO5g/edit#gid=1797120935
- Data: 
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Regarding PU Analysis!
- Notes (if any): 
*/

-- lifetime PUs
drop table if exists data_vajapora.help_a; 
create table data_vajapora.help_a as
select distinct mobile_no 
from tallykhata.tk_power_users_10; 

-- lifetime PUs with last active date
drop table if exists data_vajapora.help_d; 
create table data_vajapora.help_d as
select * 
from 
	data_vajapora.help_a tbl1 
	inner join 
	(select mobile_no, max(event_date) max_active_date 
	from tallykhata.tallykhata_sync_event_fact_final 
	where 
		event_date<current_date 
		and event_name='app_opened'
	group by 1
	) tbl2 using(mobile_no); 

-- active last 30 days	
drop table if exists data_vajapora.help_b; 
create table data_vajapora.help_b as
select distinct mobile_no, 1 active_last_30_days 
from tallykhata.tallykhata_sync_event_fact_final 
where 
	event_date>=current_date-30 and event_date<current_date 
	and event_name='app_opened'; 

-- lifetime PUs inactive for the last 30 days, with last active date
drop table if exists data_vajapora.help_c; 
create table data_vajapora.help_c as
select *
from 
	data_vajapora.help_d tbl1 
	left join 
	data_vajapora.help_b tbl2 using(mobile_no)
where active_last_30_days is null; 

-- inactive PUs satisfying all criteria 
drop table if exists data_vajapora.help_e; 
create table data_vajapora.help_e as
select *, row_number() over(partition by if_retained, segment order by mobile_no) seq
from 
	(select
		mobile_no,
		registration_date, 
		shop_name, 
		bi_business_type, 
		max_active_date, 
		district_name, 
		upazilla_name, 
		case when if_retained=1 then 'yes' else 'no' end if_retained, 
		coalesce(segment, 'uninstalled') segment
	from 
		-- lifetime PUs inactive for the last 30 days, with last active date
		data_vajapora.help_c tbl1
		
		left join 
		
		(-- if in retained base
		select 
			mobile_no, 
			1 if_retained, 
			case 
				when tg in('3RAUCb','3RAU Set-A','3RAU Set-B','3RAU Set-C','3RAUTa','3RAUTa+Cb','3RAUTacs') then '3RAU'
				when tg in('LTUCb','LTUTa') then 'LTU'
				when tg in('NT--') then 'NT'
				when tg in('NB0','NN1','NN2-6') then 'NN'
				when tg in('PSU') then 'PSU'
				when tg in('PUCb','PU Set-A','PU Set-B','PU Set-C','PUTa','PUTa+Cb','PUTacs') then 'PU'
				when tg in('ZCb','ZTa','ZTa+Cb') then 'Zombie' 
				else 'rest'
			end segment
		from cjm_segmentation.retained_users 
		where report_date=current_date
		) tbl2 using(mobile_no)
		
		inner join 
		
		(-- general info.
		select
			mobile mobile_no, 
			coalesce(shop_name, merchant_name, business_name) shop_name, 
			registration_date, 
			bi_business_type
		from tallykhata.tallykhata_user_personal_info 
		where bi_business_type in('Grocery Business', 'Pharmacy Business') -- bottleneck
		) tbl3 using(mobile_no)
		
		inner join 
		
		(-- location info. 
		select mobile mobile_no, district_name, upazilla_name
		from tallykhata.tallykhata_clients_location_info  
		) tbl4 using(mobile_no)
	) tbl1 
where segment in('NT', 'Zombie', 'LTU', 'PSU', 'uninstalled'); -- applicable segments
	
-- data to deliver 
select 
	mobile_no,
	registration_date,
	shop_name,
	bi_business_type,
	max_active_date,
	district_name,
	upazilla_name,
	if_retained,
	segment
from data_vajapora.help_e
where seq<=300; 
	
-- distribution 
select if_retained, segment, count(mobile_no) merchants
from data_vajapora.help_e
group by 1, 2
order by 3 desc; 
