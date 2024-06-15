/*
- Viz: 
- Data: 
- Function: 
- Table:
- File: 
- Path: 
- Document/Presentation/Dashboard: 
- Email thread: 
- Notes (if any): 
- Ref: Clustering of Merchants Within 500m Radius.txt
*/

do $$

declare 
	var_seq int:=1; 
begin 
	raise notice 'New OP goes below:'; 
	
	-- merchants with lat-lng pairs
	drop table if exists data_vajapora.help_a;
	create table data_vajapora.help_a as
	select *
	from digital_credit.tallycredit_user_lat_lng;
	
	-- centroids of picked locations
	drop table if exists data_vajapora.help_b;
	create table data_vajapora.help_b as
	select 
		union_name, 
		avg(lat::numeric) avg_lat, 
		avg(lng::numeric) avg_lng, 
		count(tk_mobile) merchants,
		row_number() over(order by union_name) seq
	from data_vajapora.help_a
	group by 1;
	/*select 
		city_corporation_name, 
		avg(lat::numeric) avg_lat, 
		avg(lng::numeric) avg_lng, 
		count(tk_mobile) merchants,
		row_number() over(order by city_corporation_name) seq
	from data_vajapora.help_a
	group by 1;*/
	
	-- assign clusters anew (6 mins)
	truncate table data_vajapora.help_cluster_2; 
	loop	
		insert into data_vajapora.help_cluster_2
		select *, (select seq from data_vajapora.help_b where seq=var_seq) grp -- cluster
		from 
			data_vajapora.help_a tbl1
			
			inner join 
			
			(-- merchants within given radius
			select tk_mobile
			from 
				(select *, 2*atan2(sqrt(a), sqrt(1-a))*r dist_meters
				from 
					(select *, sin(dlat/2)*sin(dlat/2)+cos(lat1*pi()/180)*cos(lat2 *pi()/180)*sin(dlon/2)*sin(dlon/2) a
					from 
						(select *, lat2*pi()/180-lat1*pi()/180 dlat, lon2*pi()/180-lon1*pi()/180 dlon
						from 
							(select 
								tk_mobile, 
								6371000 r, 
								-- centroids
								(select avg_lat from data_vajapora.help_b where seq=var_seq) lat1, 
								(select avg_lng from data_vajapora.help_b where seq=var_seq) lon1,
								lat::numeric lat2, lng::numeric lon2
							from data_vajapora.help_a 
							) tbl3
						) tb4
					) tbl5
				) tbl6
			where dist_meters<=500 -- radius
			) tbl2 using(tk_mobile);
				
		raise notice 'Data generated for: %', var_seq;
		var_seq:=var_seq+1;
		if var_seq=(select max(seq) from data_vajapora.help_b)+1 then exit;
		end if; 
	end loop;
	
end $$; 

-- see clusters assigned
drop table if exists data_vajapora.tallycredit_user_lat_lng_clustered;
create table data_vajapora.tallycredit_user_lat_lng_clustered as
select *
from 
	data_vajapora.help_a tbl1 
	
	left join 

	(select tk_mobile, grp
	from 
		data_vajapora.help_cluster_2 tbl1
		
		inner join 
		
		(-- select last cluster in case of multiple clusters
		select tk_mobile, max(grp) grp 
		from data_vajapora.help_cluster_2
		group by 1
		) tbl2 using(tk_mobile, grp)
	) tbl2 using(tk_mobile); 

select *
from data_vajapora.tallycredit_user_lat_lng_clustered;

-- see how many clusters created
select grp, count(tk_mobile) merchants
from data_vajapora.tallycredit_user_lat_lng_clustered
group by 1
order by 2 desc; 
