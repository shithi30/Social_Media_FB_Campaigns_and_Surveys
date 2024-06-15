/*
- Viz: https://docs.google.com/spreadsheets/d/1t_By3e36_-P3gY--LZcTm2MoQRcG_5wAYTXuyace750/edit#gid=1435277768
- Data: 
- Function: 
- Table:
- Instructions: Masum Bhai's logs (shared via Skype) have been parsed. 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): 

We have analyzed merchants' new year card sharing tendencies. 
Findings:
- card no. 7 has been shared by the most merchants 
- grocery merchants have shared most of the cards 
- 01-Jan-22 witnessed the highest no. of shares 
- card generation to share ratio: ~20% 

*/

-- land
drop table if exists data_vajapora.new_year_card_land_info; 
create table data_vajapora.new_year_card_land_info as
select 
	-- *,
	split_part(split_part(record, '[', 2), ']', 1)::date land_date, 	
	split_part(split_part(record, '/newyearcamp?mobile=', 2), '&', 1) land_mobile_no
from data_vajapora.log_as_csv_2
where record ilike '%newyearcamp%';

select *
from data_vajapora.new_year_card_land_info
limit 1000;

-- generate card
drop table if exists data_vajapora.new_year_card_generation_info; 
create table data_vajapora.new_year_card_generation_info as
select 
	-- *,
	split_part(split_part(record, '[', 2), ']', 1)::date generate_date, 	
	split_part(split_part(split_part(record, '/', 5), '?', 1), ' ', 1)::int generate_id
from data_vajapora.log_as_csv_2
where 
	record ilike '%newyearcard%'
	and split_part(split_part(split_part(record, '/', 5), '?', 1), ' ', 1) ~ '^[0-9\.]+$'; 

select *
from data_vajapora.new_year_card_generation_info
limit 1000;

-- share card
select id share_id, mobile share_mobile_no, card, created_at::date share_date 
from test.usercards 
where card>6; 

-- day-to-day merics
select * 
from 
	(-- date-wise landing
	select 
		land_date report_date, 
		count(distinct land_mobile_no) merchants_landed, 
		count(land_mobile_no) times_landed
	from data_vajapora.new_year_card_land_info
	group by 1
	) tbl1 
	
	inner join 
	
	(-- date-wise generation
	select generate_date report_date, count(generate_id) cards_generated
	from data_vajapora.new_year_card_generation_info
	group by 1
	) tbl2 using(report_date)
	
	inner join 
	
	(-- date-wise card sharing
	select
		created_at::date report_date,
		count(distinct mobile) merchants_shared_cards,
		count(id) cards_shared
	from test.usercards
	where card>6
	group by 1
	) tbl3 using(report_date)
where report_date>'2021-12-30'::date and report_date<'2022-01-03'::date
order by 1; 

-- all landing
select count(land_mobile_no) times_landed, count(distinct land_mobile_no) merchants_landed
from data_vajapora.new_year_card_land_info
where land_date>'2021-12-30'::date and land_date<'2022-01-03'::date;

-- all generation
select count(generate_id) cards_generated
from data_vajapora.new_year_card_generation_info
where generate_date>'2021-12-30'::date and generate_date<'2022-01-03'::date;

-- all card sharing
select
	count(distinct mobile) as merchants_shared_cards,
	count(id) cards_shared
from test.usercards
where 
	card>6
	and created_at::date>'2021-12-30'::date and created_at::date<'2022-01-03'::date; 

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
	where card>6
	) tbl1 
	
	left join 
	
	(select mobile share_mobile_no, bi_business_type 
	from tallykhata.tallykhata_user_personal_info 
	) tbl2 using(share_mobile_no)
where share_date>'2021-12-30'::date and share_date<'2022-01-03'::date
group by 1; 