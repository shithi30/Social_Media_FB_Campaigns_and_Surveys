/*
- Viz: 
- Data: https://docs.google.com/spreadsheets/d/17JJcWTdpJQgTih7iywy3A8Hngs3FFNtv9p5oaJB3BDM/edit#gid=1103597369
- Function: 
- Table:
- File: 
- Presentation: 
- Email thread: 
- Notes (if any): CTA count of GC210519-1, FB Share 0517
*/

-- extract start, end times of campaigns
select distinct campaign_id, min(start_datetime) start_datetime, max(end_datetime) end_datetime
from 
    (select 
        request_id,
        schedule_time start_datetime, 
        schedule_time+interval '24 hours' end_datetime,
        date(schedule_time) start_date
    from public.notification_bulknotificationsendrequest
    ) tbl1 

    inner join 

    (select id request_id, title campaign_id
    from public.notification_bulknotificationrequest
    ) tbl2 using(request_id) 
where campaign_id in('GC210519-1', 'FB Share 0517')
group by 1; 
/*
-- start, end times of campaigns
FB Share 0517	2021-05-18 19:30:00	2021-05-20 11:30:00
GC210519-1	    2021-05-20 19:30:00	2021-05-23 20:35:00
*/

-- get request IDs of the campaigns
select distinct campaign_id, request_id
from 
    (select 
        request_id,
        schedule_time start_datetime, 
        schedule_time+interval '24 hours' end_datetime,
        date(schedule_time) start_date
    from public.notification_bulknotificationsendrequest
    ) tbl1 

    inner join 

    (select id request_id, title campaign_id
    from public.notification_bulknotificationrequest
    ) tbl2 using(request_id) 
where campaign_id in('GC210519-1', 'FB Share 0517');  
/*
-- request IDs of the campaigns
FB Share 0517	1399
GC210519-1	    1425
GC210519-1	    1426
*/

-- get count of users who clicked
select count(distinct mobile_no) users_clicked
from 
	(select mobile mobile_no
	from public.notification_bulknotificationreceiver
	where request_id in(1425, 1426) -- change
	) tbl1 
	
	inner join 
	
	(select mobile_no, event_timestamp, event_name
	from tallykhata.tallykhata_sync_event_fact_final 
	where 
		event_timestamp>='2021-05-20 19:30:00' and event_timestamp<='2021-05-23 20:35:00' -- change
		and event_name='in_app_message_link_tap'
	) tbl2 using(mobile_no);
/*
-- count of users who clicked
Merchants clicked on FB Share 0517: 7,494
Merchants clicked on GC210519-1: 19,434
*/

-- users who were actually shot the message
select count(distinct mobile) users_rec
from public.notification_bulknotificationreceiver
where request_id in(1404); -- change
	
-- users initially targetted
select request_id, receiver_count
from public.notification_bulknotificationsendrequest
where request_id in(1399, 1425, 1426);
