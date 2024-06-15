/*
- Viz: https://docs.google.com/spreadsheets/d/1Yo8227ETNfRoDDWWIh_ve_VZOTsc5bI-q5i4xLQjEQE/edit#gid=296168647
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
*/

select mobile_no, reg_in_weeks
from 
	(select *, row_number() over(partition by reg_in_weeks) seq
	from 
		(-- transacting merchants with >=5 days of transaction in 7 days
		select mobile_no, count(created_datetime) previous_use
		from tallykhata.tallykhata_transacting_user_date_sequence_final 
		where created_datetime>'2021-11-21'::date-7 and created_datetime<='2021-11-21'::date 
		group by 1 
		having count(created_datetime)>=5
		) tbl1 
		
		inner join 
		
		(-- registration cohorts
		select 
			mobile_number mobile_no, 
			date(created_at) reg_date, 
			case 
				when current_date-date(created_at)<=21 then 'reg in 3 weeks' 
				when current_date-date(created_at)<=42 then 'reg in 4 to 6 weeks'
				when current_date-date(created_at)<=63 then 'reg in 7 to 9 weeks' 
				else 'reg in 10 or more weeks' 
			end reg_in_weeks
		from public.register_usermobile 
		) tbl2 using(mobile_no)
		
		left join 
		
		(-- merchants transacting after the said 7 days
		select distinct mobile_no 
		from tallykhata.tallykhata_transacting_user_date_sequence_final  
		where created_datetime>'2021-11-21'::date 
		) tbl3 using(mobile_no)
	where tbl3.mobile_no is null
	) tbl1 
where seq<=50; 
		