/*
- Viz: 305.png
- Data: https://docs.google.com/spreadsheets/d/17JJcWTdpJQgTih7iywy3A8Hngs3FFNtv9p5oaJB3BDM/edit#gid=379455376
- Table:
- File: 
- Email thread: 
- Notes (if any):
*/

-- combining users pitched till 09-May-21
drop table if exists data_vajapora.prospect_2000_reached_09_may; 
create table data_vajapora.prospect_2000_reached_09_may as
select *, 'Voice + SMS' modality
from data_vajapora.prospect_voice_plus_sms
union all
select *, 'Only Voice' modality
from data_vajapora.prospect_only_voice;

-- campaign results
select 
	reg_date,
	count(distinct case when typ='FMCG' and modality='Voice + SMS' then reg_mobile_no else null end) reg_fmcg_voice_plus_sms,
	count(distinct case when typ='MFS' and modality='Voice + SMS' then reg_mobile_no else null end) reg_mfs_voice_plus_sms,
	count(distinct case when typ='FMCG' and modality='Only Voice' then reg_mobile_no else null end) reg_fmcg_only_voice,
	count(distinct case when typ='MFS' and modality='Only Voice' then reg_mobile_no else null end) reg_mfs_only_voice
from 
	(select concat('0', mobile_no) mobile_no, typ, modality
	from data_vajapora.prospect_2000_reached_09_may 
	) tbl1 
	
	left join 
	
	(select mobile reg_mobile_no, date(created_at) reg_date
	from public.registered_users
	where created_at is not null
	) tbl2 on(tbl1.mobile_no=tbl2.reg_mobile_no)
group by 1
having reg_date is not null
order by 1 desc; 