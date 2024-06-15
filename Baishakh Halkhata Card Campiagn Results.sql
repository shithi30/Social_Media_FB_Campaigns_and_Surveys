/*
- Viz: https://docs.google.com/spreadsheets/d/1cfP1Y4fuSiCymqrwsmlWRqYz6jGhZSgH1mpPvF1XO5g/edit#gid=449397006
- Data: 
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): Masum Bh. messages for details
*/

-- parsed logs
drop table if exists data_vajapora.log_halkhata_cards; 
create table data_vajapora.log_halkhata_cards as
select *
from data_vajapora.access_log_202204_13_14_15_16; 


-- land
drop table if exists data_vajapora.halkhata_card_land_info; 
create table data_vajapora.halkhata_card_land_info as
select * 
from 
	(select 
		split_part(split_part(log_string, '[', 2), ']', 1)::date land_date, 	
		split_part(split_part(log_string, 'GET /halkhata?mobile=', 2), '&', 1) land_mobile_no
	from data_vajapora.log_halkhata_cards
	where log_string ilike '%GET /halkhata?mobile=%'
	) tbl1 
where length(land_mobile_no)=11
order by 1; 
	

-- click card
drop table if exists data_vajapora.halkhata_card_click_info; 
create table data_vajapora.halkhata_card_click_info as
select 
	split_part(split_part(log_string, '[', 2), ']', 1)::date click_date, 	
	split_part(split_part(split_part(log_string, '/', 5), '?', 1), ' ', 1)::bigint click_id
from data_vajapora.log_halkhata_cards
where 
	log_string ilike '%halkhatacard%'
	and split_part(split_part(split_part(log_string, '/', 5), '?', 1), ' ', 1) ~ '^[0-9\.]+$'
order by 1;

-- share card
select id share_id, mobile share_mobile_no, card, created_at::date share_date 
from test.usercards -- import from dump 
where card in(16, 17, 18); 



-- day-to-day merics
select report_date, merchants_landed, merchants_shared_cards, card_clicks, cards_shared, times_landed
from 
	(-- date-wise landing
	select 
		land_date report_date, 
		count(distinct land_mobile_no) merchants_landed, 
		count(land_mobile_no) times_landed
	from data_vajapora.halkhata_card_land_info
	group by 1
	) tbl1 
	
	inner join 
	
	(-- date-wise click
	select click_date report_date, count(click_id) card_clicks
	from data_vajapora.halkhata_card_click_info
	group by 1
	) tbl2 using(report_date)
	
	inner join 
	
	(-- date-wise card sharing
	select
		created_at::date report_date,
		count(distinct mobile) merchants_shared_cards,
		count(id) cards_shared
	from test.usercards 
	where card in(16, 17, 18)
	group by 1
	) tbl3 using(report_date)
where report_date>='2022-04-13'::date and report_date<='2022-04-17'::date
order by 1; 



-- all landing
select count(distinct land_mobile_no) merchants_landed, count(land_mobile_no) times_landed 
from data_vajapora.halkhata_card_land_info
where land_date>='2022-04-13'::date and land_date<='2022-04-17'::date;

-- all click
select count(click_id) card_clicks
from data_vajapora.halkhata_card_click_info
where click_date>='2022-04-13'::date and click_date<='2022-04-17'::date; 

-- all card sharing
select
	count(distinct mobile) as merchants_shared_cards,
	count(id) cards_shared
from test.usercards
where 
	card in(16, 17, 18)
	and created_at::date>='2022-04-13'::date and created_at::date<='2022-04-17'::date; 



-- card-wise, BI-type-wise card sharing info
select 
	card, 
	count(distinct share_mobile_no) merchants_shared, 
	count(distinct case when bi_business_type ilike '%grocery%' then share_mobile_no else null end) merchants_shared_grocery, 
	count(distinct case when bi_business_type ilike '%electronics%' then share_mobile_no else null end) merchants_shared_electronics, 
	count(distinct case when bi_business_type ilike '%wholesaler%' then share_mobile_no else null end) merchants_shared_wholesaler, 
	count(distinct case when bi_business_type ilike '%personal%' then share_mobile_no else null end) merchants_shared_personal, 
	count(distinct 
	case when 
		(bi_business_type not ilike '%grocery%' 
		and bi_business_type not ilike '%electronics%'
		and bi_business_type not ilike '%wholesaler%'
		and bi_business_type not ilike '%personal%'
		) 
		or bi_business_type is null
	then share_mobile_no else null end
	) merchants_shared_others, 
	count(share_id) total_shared 
from 
	(select id share_id, mobile share_mobile_no, card, created_at::date share_date 
	from test.usercards 
	where card in(16, 17, 18)
	) tbl1 
	
	left join 
	
	(select mobile share_mobile_no, bi_business_type 
	from tallykhata.tallykhata_user_personal_info 
	) tbl2 using(share_mobile_no)
where share_date>='2022-04-13'::date and share_date<='2022-04-17'::date
group by 1; 

-- OS-wise, TG-wise card sharing info
select
	split_part(os_version, '.', 1)::int os,
	count(distinct tbl1.share_mobile_no) total_merchants, 
	count(distinct case when tg in('3RAUCb','3RAU Set-A','3RAU Set-B','3RAU Set-C','3RAUTa','3RAUTa+Cb','3RAUTacs') then tbl1.share_mobile_no else null end) "3RAU",
	count(distinct case when tg in('LTUCb','LTUTa') then tbl1.share_mobile_no else null end) "LTU",
	count(distinct case when tg in('NB0','NN1','NN2-6') then tbl1.share_mobile_no else null end) "NN",
	count(distinct case when tg in('NT--') then tbl1.share_mobile_no else null end) "NT",
	count(distinct case when tg in('PSU') then tbl1.share_mobile_no else null end) "PSU",
	count(distinct case when tg in('PUCb','PU Set-A','PU Set-B','PU Set-C','PUTa','PUTa+Cb','PUTacs') then tbl1.share_mobile_no else null end) "PU",
	count(distinct case when tg in('SPU') then tbl1.share_mobile_no else null end) "SPU",
	count(distinct case when tg in('ZCb','ZTa','ZTa+Cb') then tbl1.share_mobile_no else null end) "Zombie",
	count(distinct case when tg is null then tbl1.share_mobile_no else null end) "others"
from 
	(select id share_id, mobile share_mobile_no, card, created_at::date share_date 
	from test.usercards 
	where card in(16, 17, 18)
	) tbl1

	left join 

	(select mobile_no, report_date, tg
	from cjm_segmentation.retained_users
	where report_date=current_date-1
	) tbl2 on(tbl1.share_mobile_no=tbl2.mobile_no)
	
	left join 
	
	(select mobile_no, os_version
	from 
		(select id, mobile mobile_no, os_version
		from public.registered_users
		) tbl1 
		
		inner join 
		
		(select mobile mobile_no, max(id) id 
		from public.registered_users 
		group by 1
		) tbl2 using(mobile_no, id)
	) tbl3 on(tbl1.share_mobile_no=tbl3.mobile_no)
where share_date>='2022-04-13'::date and share_date<='2022-04-17'::date
group by 1
order by 1;

-- share distribution
select 
	case 
		when cards_shared>10 then '11 or more'
		else cards_shared::text 
	end shared_times,
	count(mobile) merchants_shared_cards
from 
	(select
		mobile,
		count(id) cards_shared
	from test.usercards
	where 
		card in(16, 17, 18)
		and created_at::date>='2022-04-13'::date and created_at::date<='2022-04-17'::date
	group by 1
	) tbl1 
group by 1
order by 1; 

/*
-- attempt to convert Unicode Link String to Bangla native font 
select 
	'%E0%A7%AF%E0%A7%AF%E0%A7%AC%E0%A7%A7' unicode_string,
	convert('%E0%A7%AF%E0%A7%AF%E0%A7%AC%E0%A7%A7', 'UTF-8', 'ISO-8859-1'); 

select 
	'%E0%A6%B0%E0%A7%81%E0%A6%AA%E0%A6%BE%20%E0%A6%AC%E0%A7%87%E0%A6%97%E0%A6%AE%20' unicode_string,
	convert('%E0%A6%B0%E0%A7%81%E0%A6%AA%E0%A6%BE%20%E0%A6%AC%E0%A7%87%E0%A6%97%E0%A6%AE%20', 'UTF-8', 'ISO-8859-1'); 

-- select convert('%E0%A7%AF%E0%A7%AF%E0%A7%AC%E0%A7%A7' using iso_8859_1_to_utf_8);
*/
