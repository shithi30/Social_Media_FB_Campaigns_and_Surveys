/*
- Viz: 
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
Bhai ei sequence e good user ra ase: 
Khulna > Rangpur > Mymensingh > Barisal > Sylhet
Khulnay shobche beshi ase. 
Sorry for delay in serving your request.
*/

select division_name, count(mobile_no) merchants
from 
	(select mobile_no
	from tallykhata.tk_spu_aspu_data 
	where 
		pu_type in('SPU')
		and report_date=current_date-1
	) tbl1 
	
	inner join 
		
	(select mobile mobile_no, max(division_name) division_name
	from tallykhata.tallykhata_clients_location_info 
	group by 1 
	) tbl2 using(mobile_no)
group by 1 
order by 2 desc; 