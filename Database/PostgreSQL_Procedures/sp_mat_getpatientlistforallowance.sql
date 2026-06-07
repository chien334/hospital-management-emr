CREATE OR REPLACE FUNCTION sp_mat_getpatientlistforallowance(
    p_searchtxt VARCHAR DEFAULT NULL,
    p_issearchall BOOLEAN DEFAULT FALSE,
    p_rowcounts INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
     filename: "sp_mat_getpatientlistforallowance" 
     created: 17-nov'21/Dhanashri
     Description: To Get the Patients Info For Maternity Allowance Payment + Patients matching given search conditions.
                -- Returns upto 200 patients
     Change History
     S.No.    Date/User              Change          Remarks
     1.       17-Nov'21/dhanashri                  created sp for get patient list for maternity allowance payment
     2.       19-nov'21/Aniket					   Updated query with select pat.patient
     3.       21-Nov'21/aniket					   updated query with select pat.dateofbirth 
    */
    
    if(p_issearchall = false) 
    	then  
    		p_rowcounts := coalesce(p_rowcounts,200);--default rowscount=200
    		if(p_searchtxt='null')
    		then
    			p_searchtxt := null;
    		end if;
    		open ref1 for select 
    		  pat.patientid,pat.patientcode,pat.firstname,pat.lastname,pat.shortname,pat.age,pat.gender,pat.phonenumber,pat.address,adt.dischargedate,pvs.visitcode,pat.dateofbirth
    		  from adt_patientadmission adt
    		  join pat_patient pat on adt.patientid = pat.patientid
    		  join pat_patientvisits pvs on adt.patientvisitid = pvs.patientvisitid
    		  where pat.isactive=1 and  admissioncase = 'Safe Mother Program' and admissionstatus = 'Discharged'and pat.gender='Female' and 
    			   (coalesce(pvs.visitcode,'') like '%' || coalesce(p_searchtxt,'') || '%'
    			   or pat.patientcode like '%' || coalesce(p_searchtxt,'') || '%'
    			   or pat.shortname like '%' || coalesce(p_searchtxt,'') || '%'  
    			   or coalesce(pat.phonenumber,'') like '%' || coalesce(p_searchtxt,'') || '%')
    		order by adt.dischargedate desc limit p_rowcounts;
        return next ref1; 
    	
    else
    	 
    	p_rowcounts := coalesce(p_rowcounts,200);--default rowscount=200
    		if(p_searchtxt='null')
    		then
    			p_searchtxt := null;
    		end if;
    		open ref2 for select 
    			pat.patientid,pat.patientcode,pat.firstname,pat.lastname,pat.shortname,pat.age,pat.gender,pat.phonenumber,pat.address,adt.dischargedate,pvs.visitcode,pat.dateofbirth
    			from adt_patientadmission adt
    			join pat_patient pat on adt.patientid = pat.patientid
    			join pat_patientvisits pvs on adt.patientvisitid = pvs.patientvisitid
    			where  pat.isactive=1 and  admissionstatus = 'Discharged' and
    				(coalesce(pvs.visitcode ,'') like '%' || coalesce(p_searchtxt,'') || '%'
    				 or pat.patientcode like '%' || coalesce(p_searchtxt,'') || '%'
    				 or pat.shortname like '%' || coalesce(p_searchtxt,'') || '%'  
    				 or coalesce(pat.phonenumber,'') like '%' || coalesce(p_searchtxt,'') || '%')
    			order by adt.dischargedate desc limit p_rowcounts;
        return next ref2; 
    	end if;
END;
$$ LANGUAGE plpgsql;