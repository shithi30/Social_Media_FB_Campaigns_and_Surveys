/*
- Viz: https://docs.google.com/spreadsheets/d/1cfP1Y4fuSiCymqrwsmlWRqYz6jGhZSgH1mpPvF1XO5g/edit#gid=1928695789
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
drop table if exists data_vajapora.log_21_feb_cards; 
create table data_vajapora.log_21_feb_cards as
select * 
from data_vajapora.log_20220219
union all
select * 
from data_vajapora.log_20220220
union all
select * 
from data_vajapora.log_20220221
union all
select * 
from data_vajapora.log_20220222; 



-- land
drop table if exists data_vajapora.ekushe_card_land_info; 
create table data_vajapora.ekushe_card_land_info as
select 
	split_part(split_part(log_string, '[', 2), ']', 1)::date land_date, 	
	split_part(split_part(log_string, '/feb21camp?mobile=', 2), '&', 1) land_mobile_no
from data_vajapora.log_21_feb_cards
where log_string ilike '%feb21camp%'
order by 1;

-- click card
drop table if exists data_vajapora.ekushe_card_click_info; 
create table data_vajapora.ekushe_card_click_info as
select 
	split_part(split_part(log_string, '[', 2), ']', 1)::date click_date, 	
	split_part(split_part(split_part(log_string, '/', 5), '?', 1), ' ', 1)::int click_id
from data_vajapora.log_21_feb_cards
where 
	log_string ilike '%feb21card%'
	and split_part(split_part(split_part(log_string, '/', 5), '?', 1), ' ', 1) ~ '^[0-9\.]+$'
order by 1;

-- share card
select id share_id, mobile share_mobile_no, card, created_at::date share_date 
from test.usercards -- import from dump 
where card in(12, 13, 14, 15); 



-- day-to-day merics
select * 
from 
	(-- date-wise landing
	select 
		land_date report_date, 
		count(distinct land_mobile_no) merchants_landed
	from data_vajapora.ekushe_card_land_info
	group by 1
	) tbl1 
	
	inner join 
	
	(-- date-wise click
	select click_date report_date, count(click_id) card_clicks
	from data_vajapora.ekushe_card_click_info
	group by 1
	) tbl2 using(report_date)
	
	inner join 
	
	(-- date-wise card sharing
	select
		created_at::date report_date,
		count(distinct mobile) merchants_shared_cards,
		count(id) cards_shared
	from test.usercards 
	where card in(12, 13, 14, 15)
	group by 1
	) tbl3 using(report_date)
where report_date>='2022-02-20'::date and report_date<='2022-02-22'::date
order by 1; 



-- all landing
select count(distinct land_mobile_no) merchants_landed
from data_vajapora.ekushe_card_land_info
where land_date>='2022-02-20'::date and land_date<='2022-02-22'::date;

-- all click
select count(click_id) card_clicks
from data_vajapora.ekushe_card_click_info
where click_date>='2022-02-20'::date and click_date<='2022-02-22'::date; 

-- all card sharing
select
	count(distinct mobile) as merchants_shared_cards,
	count(id) cards_shared
from test.usercards
where 
	card in(12, 13, 14, 15)
	and created_at::date>='2022-02-20'::date and created_at::date<='2022-02-22'::date; 



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
	where card in(12, 13, 14, 15)
	) tbl1 
	
	left join 
	
	(select mobile share_mobile_no, bi_business_type 
	from tallykhata.tallykhata_user_personal_info 
	) tbl2 using(share_mobile_no)
where share_date>='2022-02-20'::date and share_date<='2022-02-22'::date
group by 1; 
