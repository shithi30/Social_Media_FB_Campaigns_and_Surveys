/*
- Viz: 
- Data: 
- Function: 
- Table:
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: Re: Need location for attached list
- Notes (if any): 
*/

-- import the numbers to DWH from Excel/csv via Python

select tallykhata_user_id, mobile_no, division, district, upazilla, "union"
from 
	(select concat(0, "Number") mobile_no
	from data_vajapora.misc
	) tbl1 
	
	inner join 
	
	(select tallykhata_user_id, mobile_number as mobile_no
	from public.register_usermobile 
	) tbl2 using(mobile_no)
	
	left join 

	(select tallykhata_user_id, division, district, upazilla, "union"
	from tallykhata.tk_user_location_final
	) tbl3 using(tallykhata_user_id); 