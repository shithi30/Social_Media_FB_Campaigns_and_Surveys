/*
- Viz: 
- Data: 
- Function: 
- Table:
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Regarding Custom Messaging Campaign!
- Notes (if any): 
	Require 300 users data on bellows segments:
	FAU - 60 ( 60% Clicked & 40% Non Clicked)
	PU - 60 ( 60% Clicked & 40% Non Clicked)
	3RAU - 60 ( 60% Clicked & 40% Non Clicked)
	New - 60 ( 60% Clicked & 40% Non Clicked)
	Winback - 60 ( 60% Clicked & 40% Non Clicked)
*/

-- retained campaigns launched yesterday
drop table if exists data_vajapora.help_a; 
create table data_vajapora.help_a as
select campaign_id, request_id, min(start_datetime) start_datetime, max(end_datetime) end_datetime
from 
    (select 
        request_id,
        case when schedule_time is not null then schedule_time else created_at end start_datetime, 
        case when schedule_time is not null then schedule_time else created_at end+interval '10 hours' end_datetime
    from public.notification_bulknotificationsendrequest
    ) tbl1 

    inner join 

    (select id request_id, title campaign_id
    from public.notification_bulknotificationrequest
    ) tbl2 using(request_id) 
where campaign_id in('CM210906-01', 'CM210906-02')
group by 1, 2; 

-- status of yesterday's DAUs
drop table if exists data_vajapora.help_b;
create table data_vajapora.help_b as
select 
	tbl1.mobile_no,
	case when tbl7.mobile_no is null then 0 else 1 end if_clicked,
	case when tbl2.mobile_no is null then 0 else 1 end if_fau,
	case when tbl3.mobile_no is null then 0 else 1 end if_3rau,
	case when tbl4.mobile_no is null then 0 else 1 end if_pu,
	case when tbl5.mobile_no is null then 0 else 1 end if_new,
	case when tbl6.mobile_no is null then 0 else 1 end if_winback
from 
	(select mobile_no
	from tallykhata.tallykhata_user_date_sequence_final 
	where event_date=current_date-1
	) tbl1 
	
	left join 
	
	(select mobile mobile_no
	from tallykhata.fau_for_dashboard
	where 
		report_date=current_date-1
		and category in('fau', 'fau-1')
	) tbl2 using(mobile_no)
	
	left join 
	
	(select mobile_no
	from tallykhata.tallykhata_regular_active_user
	where
		rau_date=current_date-1
		and rau_category=3
	) tbl3 using(mobile_no)
	
	left join 
	
	(select distinct mobile_no 
	from tallykhata.tk_power_users_10
	where report_date=current_date-1
	) tbl4 using(mobile_no)
	
	left join 
	
	(select mobile_number mobile_no 
	from public.register_usermobile 
	where date(created_at)=current_date-1
	) tbl5 using(mobile_no)
	
	left join 
	
	(select mobile_no
	from tallykhata.tallykhata_user_date_sequence_final 
	where event_date<current_date-1
	group by 1
	having current_date-1-max(event_date)>10
	) tbl6 using(mobile_no)
	
	left join 
	
	(select distinct mobile_no
	from tallykhata.tallykhata_sync_event_fact_final
	where 
		event_name in('inbox_message_open')
		and 
			((event_timestamp>='2021-09-06 11:52:18' and event_timestamp<='2021-09-06 21:52:18') 
			or
			(event_timestamp>='2021-09-06 17:39:07' and event_timestamp<='2021-09-07 03:39:07')) 
	) tbl7 using(mobile_no); 
		
-- 300 merchants' data
-- FAU > 3RAU > PU > winback > new

-- FAU
(select mobile_no, 1 if_clicked, 'FAU' category
from data_vajapora.help_b
where 
	if_fau=1
	and if_clicked=1
limit 36
) 

union all

(select mobile_no, 0 if_clicked, 'FAU' category
from data_vajapora.help_b
where 
	if_fau=1
	and if_clicked=0
limit 24
) 

union all

-- 3RAU
(select mobile_no, 1 if_clicked, '3RAU' category
from data_vajapora.help_b
where 
	if_fau=0 and if_3rau=1
	and if_clicked=1
limit 36
) 

union all

(select mobile_no, 0 if_clicked, '3RAU' category
from data_vajapora.help_b
where 
	if_fau=0 and if_3rau=1
	and if_clicked=0
limit 24
) 

union all

-- PU
(select mobile_no, 1 if_clicked, 'PU' category
from data_vajapora.help_b
where 
	if_fau=0 and if_3rau=0 and if_pu=1
	and if_clicked=1
limit 36
) 

union all

(select mobile_no, 0 if_clicked, 'PU' category
from data_vajapora.help_b
where 
	if_fau=0 and if_3rau=0 and if_pu=1
	and if_clicked=0
limit 24
) 

union all

-- winback
(select mobile_no, 1 if_clicked, 'winback' category
from data_vajapora.help_b
where 
	if_fau=0 and if_3rau=0 and if_pu=0 and if_winback=1
	and if_clicked=1
limit 36
) 

union all

(select mobile_no, 0 if_clicked, 'winback' category
from data_vajapora.help_b
where 
	if_fau=0 and if_3rau=0 and if_pu=0 and if_winback=1
	and if_clicked=0
limit 24
) 

union all

-- new
(select mobile_no, 1 if_clicked, 'new' category
from data_vajapora.help_b
where 
	if_fau=0 and if_3rau=0 and if_pu=0 and if_winback=0 and if_new=1
	and if_clicked=1
limit 36
)

union all

(select mobile_no, 0 if_clicked, 'new' category
from data_vajapora.help_b
where 
	if_fau=0 and if_3rau=0 and if_pu=0 and if_winback=0 and if_new=1
	and if_clicked=0
limit 24
); 
