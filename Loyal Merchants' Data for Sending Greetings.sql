/*
- Viz: 
- Data: 
- Function: 
- Table: data_vajapora.greetings_data
- File: 
- Path: 
- Document/Presentation: 
- Email thread: Request For Providing TK Merchants Data!
- Notes (if any): 
*/

-- drop table if exists data_vajapora.greetings_data;
-- create table data_vajapora.greetings_data as
select 
	mobile_no,
	case when shop_name is null or shop_name='' then name else shop_name end shop_name, 
	case 
		when tk_age>=90 and tk_age<180 then '3 months plus'
		when tk_age>=180 and tk_age<270 then '6 months plus'
		when tk_age>=270 and tk_age<365 then '9 months plus'
		when tk_age>=365 then '1 year plus'
		else 'none'
	end status
from 
	(select mobile_no, count(event_date) active_days
	from tallykhata.tallykhata_user_date_sequence_final 
	where event_date>='2021-07-01' and event_date<'2021-08-01'
	group by 1
	having count(event_date)>=2
	) tbl1
	
	inner join 
	
	(select mobile_number mobile_no, current_date-date(created_at)+1 tk_age
	from public.register_usermobile 
	where current_date-date(created_at)+1>=90
	) tbl2 using(mobile_no)
	
	inner join 
	
	(select mobile mobile_no, shop_name, name
	from tallykhata.tallykhata_user_personal_info 
	) tbl3 using(mobile_no); 

/*
select status, count(mobile_no) merchants
from data_vajapora.greetings_data
group by 1
order by 2 desc; 
*/
