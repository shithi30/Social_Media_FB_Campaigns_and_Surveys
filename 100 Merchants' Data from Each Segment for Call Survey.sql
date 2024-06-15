/*
- Viz: https://docs.google.com/spreadsheets/d/14orjplGLjSd2ZYPS5ktRDmuKpPx1gi7HBCcet2oOPMo/edit#gid=1367670527
- Data: 
- Function: 
- Table:
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Request For Providing New CJM Segmented Data!
- Notes (if any): Check if EODs are run right before generating data. 
*/

-- today: '2021-09-20'::date

-- retained merchants of today: use Python for this
drop table if exists data_vajapora.help_d;
create table data_vajapora.help_d as 
select tbl2.mobile_no, reg_date, '2021-09-20'::date-reg_date+1 days_with_tk
from 
	(select concat('0', mobile_no) mobile_no
	from data_vajapora.retained_today
	) tbl1 
	
	inner join 
	
	(select mobile_number mobile_no, date(created_at) reg_date 
	from public.register_usermobile
	where date(created_at)<='2021-09-20'::date
	) tbl2 using(mobile_no); 

-- 3RAU statistics
drop table if exists data_vajapora.help_a;
create table data_vajapora.help_a as
select mobile_no, max(rau_date) max_3_rau_date, count(rau_date) rau_days
from tallykhata.tallykhata_regular_active_user
where 
	rau_category=3
	and rau_date<='2021-09-20'::date
group by 1; 

-- PU statistics
drop table if exists data_vajapora.help_c;
create table data_vajapora.help_c as
select mobile_no, max(report_date) max_pu_date, count(distinct report_date) pu_days
from tallykhata.tk_power_users_10
where report_date<='2021-09-20'::date
group by 1; 

-- all features combined
drop table if exists data_vajapora.help_b;
create table data_vajapora.help_b as
select 
	tbl1.*, 
	case when tbl2.created_datetime is null then 0 else 1 end if_first_day_active,
	case when tbl3.txn_days is null then 0 else tbl3.txn_days end txn_days,
	case when tbl4.rau_days is null then 0 else tbl4.rau_days end days_in_3_rau,
	tbl4.max_3_rau_date, 
	'2021-09-20'::date-tbl4.max_3_rau_date days_after_last_3_rau,
	case when tbl5.mobile_no is null then 0 else 1 end if_pu_yesterday,
	case when tbl7.mobile_no is null then 0 else 1 end if_3_rau_yesterday, 
	case when active_last_30_days is null then 0 else active_last_30_days end active_last_30_days,
	case when tbl8.pu_days is null then 0 else tbl8.pu_days end days_in_pu,
	tbl8.max_pu_date
from 
	data_vajapora.help_d tbl1 
	
	left join 
	
	(select mobile_no, created_datetime 
	from tallykhata.tallykhata_transacting_user_date_sequence_final 
	) tbl2 on(tbl1.mobile_no=tbl2.mobile_no and tbl1.reg_date=tbl2.created_datetime)
	
	left join 
	
	(select mobile_no, count(created_datetime) txn_days 
	from tallykhata.tallykhata_transacting_user_date_sequence_final  
	where created_datetime<='2021-09-20'::date
	group by 1 
	) tbl3 on(tbl1.mobile_no=tbl3.mobile_no)
	
	left join 
	
	data_vajapora.help_a tbl4 on(tbl1.mobile_no=tbl4.mobile_no)
	
	left join 
	
	(select distinct mobile_no
	from tallykhata.tk_power_users_10
	where report_date='2021-09-20'::date-1
	) tbl5 on(tbl1.mobile_no=tbl5.mobile_no)
	
	left join 
	
	(select mobile_no, count(created_datetime) active_last_30_days
	from tallykhata.tallykhata_transacting_user_date_sequence_final
	where created_datetime>='2021-09-20'::date-30 and created_datetime<'2021-09-20'::date 
	group by 1
	) tbl6 on(tbl1.mobile_no=tbl6.mobile_no)
	
	left join 
	
	(select distinct mobile_no
	from tallykhata.tallykhata_regular_active_user
	where 
		rau_category=3
		and rau_date='2021-09-20'::date-1
	) tbl7 on(tbl1.mobile_no=tbl7.mobile_no)
	
	left join 
	
	data_vajapora.help_c tbl8 on(tbl1.mobile_no=tbl8.mobile_no); 

-- segmented user-base
drop table if exists data_vajapora.help_e;
create table data_vajapora.help_e as
select 
	*,
	case
		when days_with_tk=1 and if_first_day_active=0 then 'S01 age 1: day-01 not transacted' -- S1
		when days_with_tk=1 and if_first_day_active=1 then 'S02 age 1: day-01 transacted' -- S2
		
		when days_with_tk>=2 and days_with_tk<=7 and txn_days=0 then 'S03 age 2-7: no transaction' -- S3
		when days_with_tk>=2 and days_with_tk<=7 and days_in_3_rau=0 then 'S04 age 2-7: did not enter 3RAU' -- S4
		when days_with_tk>=2 and days_with_tk<=7 and days_in_3_rau!=0 then 'S05 age 2-7: entered 3RAU' -- S5
		
		when days_with_tk>=8 and days_with_tk<=29 and if_pu_yesterday=1 then 'S12(1) age 8-29: PU yesterday' -- S12(1)
		when days_with_tk>=8 and days_with_tk<=29 and txn_days=0 then 'S08 age 8-29: no txn till now' -- S8
		when days_with_tk>=8 and days_with_tk<=29 and '2021-09-20'::date-max_3_rau_date=0 and days_in_3_rau=1 then 'S09 age 8-29: today 3RAU 1st' -- S9
		when days_with_tk>=8 and days_with_tk<=29 and '2021-09-20'::date-max_3_rau_date=0 and days_in_3_rau>1 then 'S10 age 8-29: today 3RAU cont.' -- S10
		when days_with_tk>=8 and days_with_tk<=29 and '2021-09-20'::date-max_3_rau_date=1 then 'S06 age 8-29: was 3RAU yesterday' -- S6
		when days_with_tk>=8 and days_with_tk<=29 and '2021-09-20'::date-max_3_rau_date>1 then 'S07 age 8-29: gaps after 3RAU' -- S7
		when days_with_tk>=8 and days_with_tk<=29 and max_3_rau_date is null then 'S11 age 8-29: low usage' -- S11
		
		when days_with_tk>29 and txn_days=0 then 'S13 age >29: no transaction' -- S13
		when days_with_tk>29 and active_last_30_days=0 then 'S14 age >29: inactive last 29 days' -- S14
		when days_with_tk>29 and if_pu_yesterday=1 and active_last_30_days<20 then 'S12(2) age >29: was PU yesterday' -- S12(2)
		when days_with_tk>29 and if_pu_yesterday=1 and active_last_30_days>=20 then 'S15 age >29: was SPU yesterday' -- S15
		when days_with_tk>29 and days_in_3_rau=0 then 'S16 age >29: not entered 3RAU till now' -- S16
		when days_with_tk>29 and if_3_rau_yesterday=1 then 'S17 age >29: 3RAU yesterday' -- S17
		
		-- remaining
		when days_with_tk>29 and days_in_pu=0 then 'S18 age >29: never became PU' -- S18
		when days_with_tk>29 and days_in_pu>0 and '2021-09-20'::date-max_pu_date!=0 then 'S19 age >29: once PU currently not' -- S19
		when days_with_tk>29 and days_in_pu>0 and '2021-09-20'::date-max_pu_date=0 then 'S21? age >29: once PU currently PU' -- S21?
		
		else 'unknown'
	end cjm_segment
from data_vajapora.help_b; 

-- distribution of segments
select *
from 
	(select left(cjm_segment, 3) cjm_segment, count(*) merchants
	from data_vajapora.help_e 
	group by 1 
	
	union 
	
	-- for 'uninstalled'
	select 'S20 uninstalled' cjm_segment, count(mobile_no) merchants
	from 
		(select mobile_number mobile_no
		from public.register_usermobile
		) tbl1 
		
		left join 
			
		(select mobile_no
		from data_vajapora.help_d
		) tbl2 using(mobile_no)
	where tbl2.mobile_no is null
	) tbl1
order by 1;
	
-- 100 merchants from each segment
select mobile_no, shop_name, cjm_segment
from 
	(select mobile_no, cjm_segment 
	from
		(select *, row_number() over(partition by cjm_segment) seq 
		from data_vajapora.help_e
		) tbl1
	where seq<=100
	
	union
	
	(-- for 'uninstalled'
	select mobile_no, 'S20 uninstalled' cjm_segment
	from 
		(select mobile_number mobile_no
		from public.register_usermobile
		) tbl1 
		
		left join 
			
		(select mobile_no
		from data_vajapora.help_d
		) tbl2 using(mobile_no)
	where tbl2.mobile_no is null
	order by random()
	limit 100
	)
	) tbl1 
	
	left join 
	
	(-- shop names
	select mobile mobile_no, case when shop_name is null then merchant_name else shop_name end shop_name
	from tallykhata.tallykhata_user_personal_info 
	) tbl2 using(mobile_no)
where cjm_segment not like '%S21?%' -- eliminate extra segment (by us)
order by 3; 
	