/*
- Viz: 
	- https://docs.google.com/spreadsheets/d/17JJcWTdpJQgTih7iywy3A8Hngs3FFNtv9p5oaJB3BDM/edit#gid=532111203
	- https://docs.google.com/spreadsheets/d/17JJcWTdpJQgTih7iywy3A8Hngs3FFNtv9p5oaJB3BDM/edit#gid=910278284
- Data: 
- Function: 
- Table:
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): data until 11-Sep-21
*/

-- retained merchants of today
drop table if exists data_vajapora.retained_today_help;
create table data_vajapora.retained_today_help as 
select concat('0', mobile_no) mobile_no
from data_vajapora.retained_today; 

-- merchants' customers' names: may need change
drop table if exists data_vajapora.merchant_customer_names;
create table data_vajapora.merchant_customer_names as
select *
from 
	(select mobile_no, contact, max(id) account_id
	from public.account 
	where type=2
	group by 1, 2
	) tbl1 
	
	inner join 
	
	(select id account_id, name
	from public.account  
	) tbl2 using(account_id); 

-- existing baki from all customers
drop table if exists data_vajapora.baki_from_customers;
create table data_vajapora.baki_from_customers as
select
	tbl1.mobile_no, 
	tbl1.account_id, 
	case when baki is null then 0 else baki end+start_balance baki
from 	
	(select mobile_no, id account_id, start_balance
	from public.account
	where type=2
	) tbl1

	left join 

	(select 
		mobile_no, 
		account_id,
		sum(case when txn_type=3 and txn_mode=1 and coalesce(amount, 0)>0 then amount else 0 end)
		-
		sum(case when txn_type=3 and txn_mode=1 and coalesce(amount_received, 0)>0 then amount_received else 0 end)
		baki
	from public.journal 
	where 
		is_active is true
		and date(create_date)<'2021-09-12'::date
	group by 1, 2
	) tbl2 using(mobile_no, account_id); 

-- retained merchants' sequenced baki customers
drop table if exists data_vajapora.baki_from_customers_seq;
create table data_vajapora.baki_from_customers_seq as
select *
from 
	(select *, row_number() over(partition by mobile_no order by baki desc) baki_customer_seq
	from data_vajapora.baki_from_customers
	) tbl1
	
	inner join 
	
	data_vajapora.retained_today_help tbl2 using(mobile_no)
	
	left join 
	
	data_vajapora.merchant_customer_names tbl3 using(mobile_no, account_id); 

-- output for selected merchants 
select mobile_no, account_id, contact, name, baki, baki_customer_seq
from data_vajapora.baki_from_customers_seq
where mobile_no in 
	('01300013624',
	'01300017050',
	'01300022386',
	'01300027238',
	'01300030782',
	'01300044533',
	'01300044736',
	'01300047195',
	'01300047536',
	'01300063339')
order by 1, 6; 
