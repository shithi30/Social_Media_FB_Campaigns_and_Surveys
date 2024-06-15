/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/17JJcWTdpJQgTih7iywy3A8Hngs3FFNtv9p5oaJB3BDM/edit#gid=1165705690
- Function: 
- Table:
- File: 
- Presentation: 
- Email thread: 
- Notes (if any): 
*/

select 
	count(mobile) merchants,
	
	count(rau_3_mobile) rau_3,
	count(rau_10_mobile) rau_10,
	count(pu_mobile) pu,
	
	count(rau_3_mobile)*1.00/count(mobile) rau_3_pct,
	count(rau_10_mobile)*1.00/count(mobile) rau_10_pct,
	count(pu_mobile)*1.00/count(mobile) pu_pct
from 
	(-- Shovon's location table
	select distinct mobile
	from data_vajapora.tk_users_location_sample_final
	where union_name ilike '%bhatara%'
	
	union
	
	-- Shafiq Bhai's list by Minhaj Bhai
	select distinct mobile_no mobile
	from data_vajapora.ca_field_data_analysis
	where market_name ilike '%vhatara%'
	) tbl1
		
	left join 
	
	(select distinct mobile_no rau_3_mobile
	from tallykhata.tallykhata_regular_active_user 
	where rau_category=3
	) tbl2 on(tbl1.mobile=tbl2.rau_3_mobile)
	
	left join 
	
	(select distinct mobile_no rau_10_mobile
	from tallykhata.tallykahta_regular_active_user_new
	where rau_category=10
	) tbl3 on(tbl1.mobile=tbl3.rau_10_mobile)
	
	left join 
	
	(select distinct mobile_no pu_mobile
	from data_vajapora.tk_power_users_10
	) tbl4 on(tbl1.mobile=tbl4.pu_mobile); 
