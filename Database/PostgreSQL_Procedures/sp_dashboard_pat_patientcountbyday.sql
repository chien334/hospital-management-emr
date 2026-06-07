CREATE OR REPLACE FUNCTION sp_dashboard_pat_patientcountbyday(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_datediff INT := (
			SELECT DATEDIFF(day, p_fromdate, p_todate)
			);
BEGIN
    /*
     sp_dashboard_pat_patientcountbyday '2022-1-05'
    filename: "sp_dashboard_pat_patientcountbyday"
    createdby/date: nirmala/rohit/2022-1-05
    description: .
    remarks:    a
    change history
    s.no.    updatedby/date                        remarks
    1      nirmala/rohit/2022-1-05                created the script
    */
    begin
    	
    
    	if (v_datediff <= 7)
    then open ref1 for select  to_char(pat.createdon, 'YYYY-MM-DD') as "label",
    			visit.visittype,
    			count(pat.patientid) as "patientcount"
    		from pat_patient pat inner join pat_patientvisits visit on pat.patientid=visit.patientid
    		where (pat.createdon)::date between p_fromdate
    				and p_todate
    		group by to_char(pat.createdon, 'YYYY-MM-DD')
    			,extract(month from pat.createdon)
    			,extract(day from pat.createdon),visit.visittype
    		order by extract(month from pat.createdon)
    			,extract(day from pat.createdon),visit.visittype limit 7;
        return next ref1;  
    	else
    	
    		
    		open ref2 for select		'' as label,
    			'inpatient' as visittype,
    			count(pat.patientid) as "patientcount" 
    		from pat_patient pat inner join 
    		pat_patientvisits visit on pat.patientid=visit.patientid
    		where visittype='InPatient' and (pat.createdon)::date between p_fromdate and p_todate  
    		union all
    		select 
    		'' as label,
    			'outpatient' as visittype,
    			count(pat.patientid) as "patientcount" 
    		from pat_patient pat inner join 
    		pat_patientvisits visit on pat.patientid=visit.patientid 
    		where visittype='OutPatient'and (pat.createdon)::date between p_fromdate and p_todate;
        return next ref2;  
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;