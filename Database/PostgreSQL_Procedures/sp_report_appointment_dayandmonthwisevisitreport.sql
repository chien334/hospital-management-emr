CREATE OR REPLACE FUNCTION sp_report_appointment_dayandmonthwisevisitreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_departmentid INT DEFAULT NULL,
    p_reporttype VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    filename: exec "sp_report_appointment_dayandmonthwisevisitreport"
     p_fromdate  = '2023-03-06',
    p_todate  ='2023-06-27' , 
    p_departmentid  =  null,
    p_reporttype  = 'Month'
    createdby/date: bibek, 21stjune'23
    Description: This SP will generate a Day and Month wise Department Stat report for Appointment
    
    Change History
    S.No.    UpdatedBy/Date            Remarks
    1      Bibek:21June'23             initial script 
    2	   bibek:22ndjune'23		   Remove Department from Month Wise Query
    3.     Bibek:2ndJuly'23		       group by the sum of month 
    */
    begin
    	if p_reporttype = 'day'
    	then
    		open ref1 for select dept.departmentname
    			,visitdate
    			,trim(to_char(visitdate, 'Month')) as monthname
    			,trim(to_char(visitdate, 'Day')) as dayname
    			,sum(case 
    					when appointmenttype = 'new'
    						then 1
    					else 0
    					end) as newtotal
    			,sum(case 
    					when appointmenttype = 'followup'
    						then 1
    					else 0
    					end) as followuptotal
    			,sum(case 
    					when appointmenttype = 'new'
    						then 1
    					else 0
    					end) || sum(case 
    					when appointmenttype = 'followup'
    						then 1
    					else 0
    					end) as totalvisit
    		from pat_patientvisits vst
    		join mst_department dept on vst.departmentid = dept.departmentid
    		where (visitdate)::date between (p_fromdate)::date
    				and (p_todate)::date
    			and visittype <> 'inpatient' and appointmenttype in ('New','followup') and billingstatus <> 'returned'
    			and coalesce(nullif(p_departmentid, 0), vst.departmentid) = vst.departmentid
    		group by vst.visitdate
    			,trim(to_char(vst.visitdate, 'Day'))
    			,dept.departmentname;
        return next ref1;
    	
    	elsif p_reporttype = 'month'
    	then
    	open ref2 for select sum(a.newtotal) as newtotal ,sum(a.followuptotal) as followuptotal,sum(a.newtotal+a.followuptotal) as totalvisit, monthname from 
    		(select sum(case 
    					when appointmenttype = 'new'
    						then 1
    					else 0
    					end) as newtotal
    			,sum(case 
    					when appointmenttype = 'followup'
    						then 1
    					else 0
    					end) as followuptotal
    			,sum(case 
    					when appointmenttype = 'new'
    						then 1
    					else 0
    					end) || count(case 
    					when appointmenttype = 'followup'
    						then 1
    					else 0
    					end) as totalvisit
    			,trim(to_char(visitdate, 'Month')) as monthname
    		from pat_patientvisits vst
    		join mst_department dept on vst.departmentid = dept.departmentid
    		where (visitdate)::date between (p_fromdate)::date
    			and (p_todate)::date
    			and visittype <> 'inpatient' and appointmenttype in ('New','followup') and billingstatus <> 'returned'
    			and coalesce(nullif(p_departmentid, 0), vst.departmentid) = vst.departmentid
    			group by  trim(to_char(visitdate, 'Month'))
    			,dept.departmentname) a 
    			group by monthname;
        return next ref2;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;