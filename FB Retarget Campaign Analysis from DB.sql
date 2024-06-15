/*
- Viz: https://docs.google.com/spreadsheets/d/1RXgKF7FmiEq-oRMBB8SqYIdqvFZZxo73pcN8-eDdFmA/edit#gid=1359585078
- Data: 
- Function: 
- Table:
- Instructions: 
- Format: https://docs.google.com/spreadsheets/d/1RXgKF7FmiEq-oRMBB8SqYIdqvFZZxo73pcN8-eDdFmA/edit#gid=1689685979
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): 

Populate data_vajapora.retained_base_for_retarget from live: 
select  
    mobile_no,
    device_id,
    device_created_at,
    app_status_updated_at
from 
    (select device_id, updated_at app_status_updated_at, app_status
    from public.notification_fcmtoken 
    where app_status='ACTIVE' 
    ) tbl1 

    inner join 

    (select id, device_id, mobile mobile_no, created_at device_created_at, device_status
    from public.registered_users 
    ) tbl2 using(device_id)

    inner join 

    (select mobile mobile_no, max(id) id
    from public.registered_users 
    where device_status='active'
    group by 1
    ) tbl3 using(id, mobile_no); 
*/

do $$

declare 
	-- for Sep
	var_date date:='2021-09-18'::date;
	var_end_date date:='2021-10-08'::date;
	
	/*-- for Oct
	var_date date:='2021-10-18'::date;
	var_end_date date:='2021-11-08'::date;
	*/
begin
	raise notice 'New OP goes below:'; 

	/*-- TG for Sep
	drop table if exists data_vajapora.uninstalled_sept;
	create table data_vajapora.uninstalled_sept as
	select * from test.merchant_with_min_one_txn_sept
	union
	select * from test.merchant_with_no_txn_sept;*/

	/*-- TG for Oct
	drop table if exists data_vajapora.uninstalled_oct;
	create table data_vajapora.uninstalled_oct as
	select * from test.merchant_with_min_one_txn_oct
	union
	select * from test.merchant_with_no_txn_oct;*/

	loop
		delete from data_vajapora.retarget_analysis_db
		where created_date=var_date; 
		
		-- events on the day
		drop table if exists data_vajapora.help_a;
		create table data_vajapora.help_a as
		select created_at::date created_date, event_name, id, user_id mobile_no, message
		from public.eventapp_event
		where 
			event_name in('auth-verify-sign-in', '/api/auth/init')
			and created_at::date=var_date; 
	
		-- metrics
		insert into data_vajapora.retarget_analysis_db
		select *
		from 
			(select
				created_date,
				count(distinct case when event_name='/api/auth/init' and message='response generated for existing user' then mobile_no else null end) login_req_merchants,
				count(distinct case when event_name='auth-verify-sign-in' then mobile_no else null end) successful_login_req_merchants
			from 
				data_vajapora.help_a tbl1 
				inner join 
				data_vajapora.uninstalled_sept tbl2 using(mobile_no)
			group by 1
			) tbl1,
			
			(select count(mobile_no) reinstalled_users_with_active_app
			from 
				(select mobile_no
				from data_vajapora.retained_base_for_retarget
				where date(app_status_updated_at)=var_date
				) tbl1 
				inner join 
				data_vajapora.uninstalled_sept tbl2 using(mobile_no)
			) tbl2,
			
			(select count(mobile_no) reinstalled_and_transacted
			from 
				(select distinct mobile_no
				from tallykhata.tallykhata_transacting_user_date_sequence_final 
				-- where created_datetime>='2021-10-18' -- for campaign period
				where created_datetime>='2021-09-18' -- for non-campaign period
				) tbl1
				inner join 
				(select mobile_no
				from data_vajapora.retained_base_for_retarget
				where date(app_status_updated_at)=var_date
				) tbl2 using(mobile_no)
				inner join 
				data_vajapora.uninstalled_sept tbl3 using(mobile_no)
			) tbl3; 
		
		raise notice 'Data generated for: %', var_date; 
		var_date:=var_date+1;
		if var_date=var_end_date+1 then exit;
		end if; 
	end loop; 
end $$; 

select *
from 
	(-- campaign period
	select *, concat('day-', row_number() over(order by created_date asc)) day_n
	from data_vajapora.retarget_analysis_db
	where created_date>='2021-10-18' and created_date<='2021-11-08'
	order by 1
	limit 21
	) tbl1 
	
	inner join 
	
	(-- non-campaign period
	select *, concat('day-', row_number() over(order by created_date asc)) day_n
	from data_vajapora.retarget_analysis_db
	where created_date>='2021-09-18' and created_date<='2021-10-08'
	order by 1
	limit 21
	) tbl2 using(day_n); 

/*
-- reinstalled_and_transacted, for non-campaign period
do $$

declare 
	var_date date:='2021-09-18'::date;
begin
	raise notice 'New OP goes below:'; 
	loop
		insert into data_vajapora.help_a 
		select var_date create_date, count(mobile_no) reinstalled_and_transacted
		from 
			(select distinct mobile_no
			from tallykhata.tallykhata_transacting_user_date_sequence_final 
			where created_datetime>='2021-09-18' -- non-campaign period
			) tbl1
			inner join 
			(select mobile_no
			from data_vajapora.retained_base_for_retarget
			where date(app_status_updated_at)=var_date
			) tbl2 using(mobile_no)
			inner join 
			data_vajapora.uninstalled_sept tbl3 using(mobile_no);
		
		raise notice 'Data generated for: %', var_date; 
		var_date:=var_date+1;
		if var_date='2021-10-09'::date then exit;
		end if; 
	end loop;
end $$; 

select *
from data_vajapora.help_a;
*/
