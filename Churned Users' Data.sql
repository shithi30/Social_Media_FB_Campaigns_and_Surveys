/*
- Viz: https://docs.google.com/spreadsheets/d/17JJcWTdpJQgTih7iywy3A8Hngs3FFNtv9p5oaJB3BDM/edit#gid=608930865
- Data: churned_users.csv in E:\SureCash Work
- Function: 
- Table:
- File: 
- Presentation: 
- Email thread: Churned Users' List
- Notes (if any): 
*/

-- registered more than 2 months back 
drop table if exists data_vajapora.help_a;
create table data_vajapora.help_a as
select mobile_number mobile_no, date(created_at) reg_date 
from public.register_usermobile 
where date(created_at)<=current_date-60; 

-- has activity in the last 2 months
drop table if exists data_vajapora.help_b; 
create table data_vajapora.help_b as
select distinct mobile_no 
from tallykhata.event_transacting_fact 
where event_date>current_date-60; 

-- registered more than 2 months back, but has no activity in the last 2 months 
drop table if exists data_vajapora.help_c;
create table data_vajapora.help_c as 
select mobile_no
from 
	data_vajapora.help_a tbl1 
	left join 
	data_vajapora.help_b tbl2 using(mobile_no)
where tbl2.mobile_no is null; 

-- merchants with their last active date and total days of activity
drop table if exists data_vajapora.help_d;
create table data_vajapora.help_d as 
select mobile_no, max(event_date) last_active_date, count(distinct event_date) total_active_days 
from tallykhata.event_transacting_fact 
group by 1; 

-- registered more than 2 months back, has no activity in the last 2 months and has been active at least 3 days prior to that
select count(mobile_no) spec_merchant_count
from 
	data_vajapora.help_c tbl1
	inner join 
	data_vajapora.help_d tbl2 using(mobile_no)
where total_active_days>=3; 

-- registered more than 2 months back, has no activity in the last 2 months and has been active at least 3 days prior to that
select mobile_no
from 
	data_vajapora.help_c tbl1
	inner join 
	data_vajapora.help_d tbl2 using(mobile_no)
where total_active_days>=3; 

-- distribution of such users 
select 
	case 
		when total_active_days<=9 then concat('0', total_active_days::varchar) 
		when total_active_days<=10 then total_active_days::varchar 
		else 'greater than 10 days' 
	end total_active_days_cat, 
	count(mobile_no) spec_merchant_count
from 
	data_vajapora.help_c tbl1
	inner join 
	data_vajapora.help_d tbl2 using(mobile_no)
group by 1
order by 1; 
