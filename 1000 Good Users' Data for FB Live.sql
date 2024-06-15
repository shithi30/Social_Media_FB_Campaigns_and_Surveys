/*
- Viz: https://docs.google.com/spreadsheets/d/1dwsquwlYAu9QEWia6eROOBog58TgHSST_5m9HE2yJ9A/edit#gid=401570360
- Data: https://docs.google.com/spreadsheets/d/1dwsquwlYAu9QEWia6eROOBog58TgHSST_5m9HE2yJ9A/edit#gid=0
- Function: 
- Table:
- File: 
- Presentation: 
- Email thread: Good Users for FB Live
- Notes (if any): was later given for all BI-types, 27 from each
*/

select new_bi_business_type, mobile_no, district_name, upazilla_name
from 
	(select *, row_number() over(partition by new_bi_business_type) user_seq
	from 
		(select mobile mobile_no
		from tallykhata.fau_for_dashboard
		where 
			report_date=current_date-1
			and category in('fau', 'fau-1')
		) tbl1 
		
		inner join 
		
		(select mobile mobile_no, new_bi_business_type 
		from tallykhata.tallykhata_user_personal_info 
		) tbl2 using(mobile_no)
		
		inner join 
		
		(select mobile mobile_no, district_name, upazilla_name
		from data_vajapora.tk_users_location_sample_final
		) tbl3 using(mobile_no)
	) tbl1
where 
	new_bi_business_type in 
	(-- top-05 BI-types
	select new_bi_business_type
	from 
		(select mobile mobile_no
		from tallykhata.fau_for_dashboard
		where 
			report_date=current_date-1
			and category in('fau', 'fau-1')
		) tbl1 
		
		inner join 
		
		(select mobile mobile_no, new_bi_business_type 
		from tallykhata.tallykhata_user_personal_info 
		) tbl2 using(mobile_no)
	group by 1
	order by count(mobile_no) desc
	limit 5
	)
	and user_seq<=200; -- 200 from each BI-type

/* 27 top users from each BI-type */
-- summary data
select 	new_bi_business_type, count(mobile_no) top_merchants
from 
	(-- detailed data
	select new_bi_business_type, mobile_no, district_name, upazilla_name, user_seq
	from 
		(select *, row_number() over(partition by new_bi_business_type order by fau_dates desc) user_seq
		from 
			(select mobile mobile_no, count(distinct report_date) fau_dates 
			from tallykhata.fau_for_dashboard
			where category in('fau', 'fau-1')
			group by 1 
			) tbl1
					
			inner join 
					
			(select mobile mobile_no, new_bi_business_type 
			from tallykhata.tallykhata_user_personal_info 
			) tbl2 using(mobile_no)
			
			inner join 
			
			(select mobile mobile_no, district_name, upazilla_name
			from data_vajapora.tk_users_location_sample_final
			) tbl3 using(mobile_no)
		) tbl1
	where user_seq<=27
	) tbl1
group by 1 
order by 2 desc; 
	
	