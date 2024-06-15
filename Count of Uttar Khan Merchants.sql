/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/17JJcWTdpJQgTih7iywy3A8Hngs3FFNtv9p5oaJB3BDM/edit#gid=116377894
- Function: 
- Table:
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): 
	- 239 merchants found as PU in last 7 days
	- 286 merchants found as 3RAU in last 7 days
*/

select 
	tbl1.mobile_no, 
	case when tbl3.mobile_no is not null then 'yes' else 'no' end if_pu_in_last_7_days,
	case when tbl4.mobile_no is not null then 'yes' else 'no' end if_3rau_in_last_7_days
	/* count(case when tbl3.mobile_no is not null then mobile_no else null end) if_pu_in_last_7_days,
	count(case when tbl4.mobile_no is not null then mobile_no else null end) if_3rau_in_last_7_days */
from 
	(select mobile mobile_no
	from tallykhata.tallykhata_user_personal_info 
	) tbl1 
	
	inner join 
	
	(select mobile mobile_no 
	from tallykhata.tallykhata_clients_location_info
	where union_name='Uttar Khan'
	) tbl2 using(mobile_no)
	
	left join 

	(select distinct mobile_no
	from tallykhata.tk_power_users_10 
	where report_date::date>=current_date-7 and report_date::date<current_date
	) tbl3 using(mobile_no)
	
	left join 
	
	(select distinct mobile_no 
	from tallykhata.regular_active_user_event
	where 
		rau_category=3
		and report_date::date>=current_date-7 and report_date::date<current_date
	) tbl4 using(mobile_no); 
