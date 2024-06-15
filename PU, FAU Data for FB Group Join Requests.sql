/*
- Viz: 
- Data: 
- Function: 
- Table: data_vajapora.pu_18_jul_21_fb_grp, data_vajapora.fau_18_jul_21_fb_grp
- File: 
- Path: 
- Document/Presentation: 
- Email thread: Data requirement: PU & FAU
- Notes (if any): 
*/

drop table if exists data_vajapora.pu_18_jul_21_fb_grp;
create table data_vajapora.pu_18_jul_21_fb_grp as
select distinct mobile_no
from tallykhata.tk_power_users_10 
where report_date=current_date-1 
limit 5000; 

drop table if exists data_vajapora.fau_18_jul_21_fb_grp; 
create table data_vajapora.fau_18_jul_21_fb_grp as
select distinct mobile mobile_no
from tallykhata.fau_for_dashboard
where 
	report_date=current_date-1
	and category in('fau', 'fau-1')
limit 5000;
