/*
- Viz: https://docs.google.com/spreadsheets/d/13kyabfTt57rti2APpA0AblB6s-Is8e2yZMR5QzeFyF8/edit#gid=1487493961
- Data: 
- Function: 
- Table:
- Instructions: 
- Format: 
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): 
*/

select 
	seq,
	mobile_no_raw, 
	mobile,
	union_name,
	upazilla_name,
	district_name,
	division_name
from 
	(select 
		seq, 
		mobile_no mobile_no_raw, 
		case  
			when length(replace(translate(mobile_no, '০১২৩৪৫৬৭৮৯', '0123456789'), '-', ''))<11 then concat('0', replace(translate(mobile_no, '০১২৩৪৫৬৭৮৯', '0123456789'), '-', '')) 
			else replace(translate(mobile_no, '০১২৩৪৫৬৭৮৯', '0123456789'), '-', '')
		end mobile
	from data_vajapora.phones -- imported from .csv
	) tbl1
	
	left join 
	
	(select mobile, union_name, upazilla_name, district_name, division_name
	from tallykhata.tallykhata_clients_location_info
	) tbl2 using(mobile)
order by 1; 
