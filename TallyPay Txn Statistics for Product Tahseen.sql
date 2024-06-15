/*
- Viz: https://docs.google.com/spreadsheets/d/1koaJde0hU0hq8-ifQksDqF1ljygiDWHnfPvVza5d5LU/edit#gid=805620123
- Data: 
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): Run on NP DWH. 
*/

select 
	act_type, 
	count(distinct mobile_no) users, 
	count(id) trt, 
	sum(amount::numeric) trv
from 
	(-- Add Money
	select *, 'Add Money' act_type
	from 
		(select id, amount, from_id, to_id, txn_time, type_name, txn_type, status
		from ods_tp.backend_db__np_txn_log
		where 
			txn_type in('CASH_IN_FROM_BANK', 'CASH_IN_FROM_CARD')
			and status='COMPLETE'
		) tbl1 
		inner join 
	    (select user_id to_id, wallet_no mobile_no, bank_account_status
		from ods_tp.backend_db__profile
		) tbl2 using(to_id)
		
	union all
	
	-- Mobile Recharge
	select *, 'Mobile Recharge' act_type
	from 
		(select id, amount, from_id, to_id, txn_time, type_name, txn_type, status
		from ods_tp.backend_db__np_txn_log
		where 
			txn_type in('MOBILE_RECHARGE')
			and status='COMPLETE'
		) tbl1 
		inner join 
	    (select user_id from_id, wallet_no mobile_no, bank_account_status
		from ods_tp.backend_db__profile
		) tbl2 using(from_id)
		
	union all
	
	-- Credit Collection Using Payment Link (Nagad)
	select *, 'Credit Collection Using Payment Link (Nagad)' act_type
	from 
		(select id, amount, from_id, to_id, txn_time, type_name, txn_type, status
		from ods_tp.backend_db__np_txn_log
		where 
			txn_type in('CREDIT_COLLECTION')
			and external_identifier='NAGAD'
			and status='COMPLETE'
		) tbl1 
		inner join 
	    (select user_id to_id, wallet_no mobile_no, bank_account_status
		from ods_tp.backend_db__profile
		) tbl2 using(to_id)
	
	union all
	   
	-- Credit Collection using Payment Link (Card)
	select *, 'Credit Collection using Payment Link (Card)' act_type
	from 
		(select id, amount, from_id, to_id, txn_time, type_name, txn_type, status
		from ods_tp.backend_db__np_txn_log
		where 
			txn_type='CREDIT_COLLECTION'
			and external_identifier in('CARD', 'MASTERCARD')
			and status='COMPLETE'
		) tbl1 
		inner join 
	    (select user_id to_id, wallet_no mobile_no, bank_account_status
		from ods_tp.backend_db__profile
		) tbl2 using(to_id)
		
	union all
	   
	-- Money Out (City Bank)
	select *, 'Money Out (City Bank)' act_type
	from 
		(select id, amount, from_id, to_id, txn_time, type_name, txn_type, status
		from ods_tp.backend_db__np_txn_log
		where 
			txn_type in('CASH_OUT_TO_BANK')
			and external_identifier='CIBLBDDH'
			and status='COMPLETE'
		) tbl1 
		inner join 
	    (select user_id from_id, wallet_no mobile_no, bank_account_status
		from ods_tp.backend_db__profile
		) tbl2 using(from_id)
		
	union all
	   
	-- Money Out (BEFTN)
	select *, 'Money Out (BEFTN)' act_type
	from 
		(select id, amount, from_id, to_id, txn_time, type_name, txn_type, status
		from ods_tp.backend_db__np_txn_log
		where 
			txn_type in('CASH_OUT_TO_BANK')
			and external_identifier!='CIBLBDDH'
			and status='COMPLETE'
		) tbl1 
		inner join 
	    (select user_id from_id, wallet_no mobile_no, bank_account_status
		from ods_tp.backend_db__profile
		) tbl2 using(from_id)
	) tbl1 
	
	inner join 
	
	(-- 5.0.3 merchants with TP wallets
	select distinct mobile mobile_no
	from foreign_schema_tk.registered_users
	where 1=1
	    and mobile in 
	        (select distinct p.wallet_no mobile_no
	        from ods_tp.backend_db__profile p 
	        left join ods_tp.backend_db__document as d on p.user_id  = d.user_id 
	        left join ods_tp.backend_db__bank_account  as a on p.user_id  = a.user_id
	        left join ods_tp.backend_db__mfs_account as m on p.user_id  = m.user_id
	        where 1=1
	        and upper(d.doc_type) ='NID'
	        and p.created_at::date>='2022-09-21'
	        and p.bank_account_status = 'VERIFIED'
	        )
	    and device_status='active' 
	    and app_version_number=116
	) tbl2 using(mobile_no)
where 1=1
	/* -- omitting PSL employees
	and mobile_no not like '0198000%'
	and mobile_no not like'0190444%'
	and mobile_no not like '0140444%'*/
	and bank_account_status='VERIFIED'
group by 1; 

/* misc. stats */

select *
from 
	(-- profiles transacted
	select from_id id
	from ods_tp.backend_db__np_txn_log
	where status='COMPLETE'
	union 
	select to_id id
	from ods_tp.backend_db__np_txn_log
	where status='COMPLETE'
	) tbl1 
	
	inner join 
	
	(-- their phone numbers
	select user_id id, wallet_no mobile_no, bank_account_status
	from ods_tp.backend_db__profile
	) tbl2 using(id)

	inner join 
	
	(-- 5.0.3 merchants with TP wallets
	select distinct mobile mobile_no
	from foreign_schema_tk.registered_users
	where 1=1
	    and mobile in 
	        (select distinct p.wallet_no mobile_no
	        from ods_tp.backend_db__profile p 
	        left join ods_tp.backend_db__document as d on p.user_id  = d.user_id 
	        left join ods_tp.backend_db__bank_account  as a on p.user_id  = a.user_id
	        left join ods_tp.backend_db__mfs_account as m on p.user_id  = m.user_id
	        where 1=1
	        and upper(d.doc_type) ='NID'
	        and p.created_at::date>='2022-09-21'
	        and p.bank_account_status = 'VERIFIED'
	        )
	    and device_status='active' 
	    and app_version_number>111
	) tbl3 using(mobile_no); 

select 
	count(tbl1.mobile_no) merchants_above_111, 
	count(tbl2.mobile_no) merchants_above_111_wallet, 
	count(tbl3.mobile_no) merchants_above_111_transacted
from 
	(-- merchants in >=112
	select mobile mobile_no, app_version_name, app_version_number, date(updated_at) update_date
	from foreign_schema_tk.registered_users
	where 
	    device_status='active'
	    and app_version_number>111
	) tbl1 
	
	left join 
	
	(-- has wallet
	select distinct p.wallet_no mobile_no
	from ods_tp.backend_db__profile p 
	left join ods_tp.backend_db__document as d on p.user_id  = d.user_id 
	left join ods_tp.backend_db__bank_account  as a on p.user_id  = a.user_id
	left join ods_tp.backend_db__mfs_account as m on p.user_id  = m.user_id
	where 1=1
	and upper(d.doc_type) ='NID'
	and p.created_at::date>='2022-09-21'
	and p.bank_account_status = 'VERIFIED'
	) tbl2 using(mobile_no)
	
	left join 
	
	(-- merchants transacted
	select distinct mobile_no
	from 
		(-- profiles transacted
		select from_id id
		from ods_tp.backend_db__np_txn_log
		where status='COMPLETE'
		union 
		select to_id id
		from ods_tp.backend_db__np_txn_log
		where status='COMPLETE'
		) tbl1 
		
		inner join 
		
		(-- their phone numbers
		select user_id id, wallet_no mobile_no, bank_account_status
		from ods_tp.backend_db__profile
		) tbl2 using(id)
	) tbl3 using(mobile_no); 

select 
	count(mobile_no) new_version_users, 
	count(case when update_date=reg_date then mobile_no else null end) new_version_reg_users, 
	count(case when update_date!=reg_date then mobile_no else null end) new_version_updated_users
from 
	(select id, mobile mobile_no, app_version_name, app_version_number, date(updated_at) update_date
	from public.registered_users
	where 
	    device_status='active'
	    and app_version_number=116 
	) tbl1 
	
	inner join 
	    
	(select mobile_number mobile_no, date(created_at) reg_date 
	from public.register_usermobile 
	) tbl2 using(mobile_no); 