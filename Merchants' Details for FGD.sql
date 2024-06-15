/*
- Viz: https://docs.google.com/spreadsheets/d/1qHOnI6QZlAlyESVRWOCKvqjLOvgnYPOetoX59X9f97E/edit#gid=0
- Data: 
- Function: 
- Table:
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): 
	Nazrul, We have invited 18 merchants in a FGD tomorrow. Kindly share below information-
	1. Name
	2. Biz Name
	3. Biz type
	4. Age with TK
	5. Last active date
	6. How many days used in last 30 days
	7. Number of customer added
	8. Number of supplier added
	9. TRT in last 30 days
	10. TRV in last 30 days
	11. % of credit txn out of all txn
	I am sharing number one-to-one.
*/

select 
	mobile_no, shop_name, business_type, age_with_tk, last_active_date, 
	case when active_days_last_30_days is not null then active_days_last_30_days else 0 end active_days_last_30_days, 
	case when added_customers is not null then added_customers else 0 end added_customers, 
	case when added_suppliers is not null then added_suppliers else 0 end added_suppliers, 
	case when trt_last_30_days is not null then trt_last_30_days else 0 end trt_last_30_days, 
	case when trv_last_30_days is not null then trv_last_30_days else 0 end trv_last_30_days, 
	case when all_txns is not null then all_txns else 0 end all_txns, 
	case when cred_txns is not null then cred_txns else 0 end cred_txns, 
	cred_txn_pct
from 
	(select mobile mobile_no, shop_name, bi_business_type business_type, current_date-registration_date age_with_tk
	from tallykhata.tallykhata_user_personal_info 
	where mobile in('01748209099','01889177405','01710077440','01846479537','01718994353','01633632747','01981101185','01631693554','01625257885','01683207240','01915555270','01616060506','01719926166','01777234449','01915338408','01711152258','01711312216','01768681616','01609780167','01995739797','01999300989','01758673628','01911011416')
	) tbl1 
	
	left join 
	
	(select mobile_no, max(event_date) last_active_date
	from tallykhata.tallykhata_user_date_sequence_final 
	where mobile_no in('01748209099','01889177405','01710077440','01846479537','01718994353','01633632747','01981101185','01631693554','01625257885','01683207240','01915555270','01616060506','01719926166','01777234449','01915338408','01711152258','01711312216','01768681616','01609780167','01995739797','01999300989','01758673628','01911011416')
	group by 1
	) tbl2 using(mobile_no)
	
	left join 
	
	(select mobile_no, count(event_date) active_days_last_30_days
	from tallykhata.tallykhata_user_date_sequence_final 
	where 
		event_date>=current_date-30 and event_date<current_date
		and mobile_no in('01748209099','01889177405','01710077440','01846479537','01718994353','01633632747','01981101185','01631693554','01625257885','01683207240','01915555270','01616060506','01719926166','01777234449','01915338408','01711152258','01711312216','01768681616','01609780167','01995739797','01999300989','01758673628','01911011416')
	group by 1
	) tbl3 using(mobile_no)
	
	left join 
	
	(select mobile_no, count(contact) added_customers
	from public.account 
	where 
		type in(2)
		and mobile_no in('01748209099','01889177405','01710077440','01846479537','01718994353','01633632747','01981101185','01631693554','01625257885','01683207240','01915555270','01616060506','01719926166','01777234449','01915338408','01711152258','01711312216','01768681616','01609780167','01995739797','01999300989','01758673628','01911011416')
	group by 1
	) tbl4 using(mobile_no)
	
	left join 
	
	(select mobile_no, count(contact) added_suppliers
	from public.account 
	where 
		type in(3)
		and mobile_no in('01748209099','01889177405','01710077440','01846479537','01718994353','01633632747','01981101185','01631693554','01625257885','01683207240','01915555270','01616060506','01719926166','01777234449','01915338408','01711152258','01711312216','01768681616','01609780167','01995739797','01999300989','01758673628','01911011416')
	group by 1
	) tbl5 using(mobile_no)
	
	left join 
	
	(select mobile_no, count(auto_id) trt_last_30_days, sum(input_amount) trv_last_30_days
	from tallykhata.tallykhata_fact_info_final
	where 
		created_datetime>=current_date-30 and created_datetime<current_date
		and mobile_no in('01748209099','01889177405','01710077440','01846479537','01718994353','01633632747','01981101185','01631693554','01625257885','01683207240','01915555270','01616060506','01719926166','01777234449','01915338408','01711152258','01711312216','01768681616','01609780167','01995739797','01999300989','01758673628','01911011416')
	group by 1
	) tbl6 using(mobile_no)
			
	left join 
	
	(select 
		mobile_no, 
		count(auto_id) all_txns, 
		count(case when txn_type like '%CREDIT%' then auto_id else null end) cred_txns,
		count(case when txn_type like '%CREDIT%' then auto_id else null end)*1.00/count(auto_id) cred_txn_pct
	from tallykhata.tallykhata_fact_info_final
	where 
		mobile_no in('01748209099','01889177405','01710077440','01846479537','01718994353','01633632747','01981101185','01631693554','01625257885','01683207240','01915555270','01616060506','01719926166','01777234449','01915338408','01711152258','01711312216','01768681616','01609780167','01995739797','01999300989','01758673628','01911011416')
	group by 1
	) tbl7 using(mobile_no); 


