/*
- Viz: https://docs.google.com/spreadsheets/d/17JJcWTdpJQgTih7iywy3A8Hngs3FFNtv9p5oaJB3BDM/edit#gid=731922454
- Data: 
- Function: 
- Table:
- File: 
- Presentation: 
- Email thread: 
- Notes (if any): 

Important analysis:
-------------------------------
How many user daily visiting/clicking --> tagada_share (event)
How many user daily visiting/clicking --> tagada_empty_confirm_dialog (event)
-------------------------------------------
Event name : tagada_share
Notes: This means how many merchant share tagada message through social media.
---------------------------------------------
Event name : tagada_empty_confirm_dialog
Notes: This means daily how many users use their own cost tagada sms

*/

select *
from 
	(-- FB Tagada and paid Tagada 
	select 
		event_date tagada_date, 
		
		count(case when event_name='tagada_share' then pk_id else null end) fb_tagada_clicks, 
		count(distinct case when event_name='tagada_share' then mobile_no else null end) fb_tagada_merchants,
		count(distinct case when event_name='tagada_share' then rau_10_mobile else null end) fb_tagada_merchants_10_rau,
		count(distinct case when event_name='tagada_share' then rau_3_mobile else null end) fb_tagada_merchants_3_rau,
		
		count(case when event_name='tagada_empty_confirm_dialog' then pk_id else null end) paid_tagada_clicks, 
		count(distinct case when event_name='tagada_empty_confirm_dialog' then mobile_no else null end) paid_tagada_merchants,
		count(distinct case when event_name='tagada_empty_confirm_dialog' then rau_10_mobile else null end) paid_tagada_merchants_10_rau,
		count(distinct case when event_name='tagada_empty_confirm_dialog' then rau_3_mobile else null end) paid_tagada_merchants_3_rau
	from 
		(select pk_id, mobile_no, event_name, event_date
		from tallykhata.tallykhata_sync_event_fact_final   
		where event_name in('tagada_share', 'tagada_empty_confirm_dialog') 
		) tbl1 
		
		left join 
		
		(select mobile_no rau_10_mobile, rau_date rau_10_date
		from tallykhata.tallykahta_regular_active_user_new
		where rau_category=10
		) tbl2 on(tbl1.event_date=tbl2.rau_10_date and tbl1.mobile_no=tbl2.rau_10_mobile)
		
		left join 
		
		(select mobile_no rau_3_mobile, rau_date rau_3_date
		from tallykhata.tallykhata_regular_active_user
		where rau_category=3
		) tbl3 on(tbl1.event_date=tbl3.rau_3_date and tbl1.mobile_no=tbl3.rau_3_mobile)
	group by 1 
	) tbl1 
	
	inner join 
	
	(-- free Tagada
	select 
		tagada_date,
		count(id) free_tagada_sent,
		count(distinct mobile_no) free_tagada_merchants,
		count(distinct rau_10_mobile) free_tagada_merchants_10_rau,
		count(distinct rau_3_mobile) free_tagada_merchants_3_rau
	from 
		(select id, date tagada_date, merchant_mobile mobile_no
		from public.notification_tagadasms
		) tbl1 
		
		left join 
			
		(select mobile_no rau_10_mobile, rau_date rau_10_date
		from tallykhata.tallykahta_regular_active_user_new
		where rau_category=10
		) tbl2 on(tbl1.tagada_date=tbl2.rau_10_date and tbl1.mobile_no=tbl2.rau_10_mobile)
		
		left join 
		
		(select mobile_no rau_3_mobile, rau_date rau_3_date
		from tallykhata.tallykhata_regular_active_user
		where rau_category=3
		) tbl3 on(tbl1.tagada_date=tbl3.rau_3_date and tbl1.mobile_no=tbl3.rau_3_mobile)
	group by 1
	) tbl2 using(tagada_date)
where tagada_date>='2021-05-10' and tagada_date<current_date 
order by 1 asc; 
