CREATE OR REPLACE FUNCTION sp_dashboard_pat_hospitalmanagement(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "Label" VARCHAR,
    "Count" INT
) AS $$
BEGIN
    /*
     sp_dashboard_pat_hospitalmanagement '2022-1-05'
    filename: "sp_dashboard_pat_hospitalmanagement"
    createdby/date:nirmala/2022-1-05
    description: .
    remarks:    a
    change history
    s.no.    updatedby/date                        remarks
    1       nirmala/2022-1-05                created the script
    */
    
    	RETURN QUERY SELECT 'OPD' AS "Label"
    		,count(patientid) AS "Count"
    	from bil_txn_billingtransactionitems
    	where servicedepartmentname like '%OPD%'
    		and (createdon)::date between (p_fromdate)::date
    			and (p_todate)::date
    	
    	union all
    	
    	select 'Lab' AS "Label"
    		,count(patientid) AS "Count"
    	from lab_testrequisition
    	where orderstatus in (
    			'active'
    			,'result-added'
    			)
    		and (createdon)::date between (p_fromdate)::date
    			and (p_todate)::date
    	
    	union all
    	
    	select 'NewPatient' AS "Label"
    		,count(patientid) AS "Count"
    	from pat_patient
    	where (createdon)::date between (p_fromdate)::date
    			and (p_todate)::date
    	
    	union all
    	
    	select 'Admission' AS "Label"
    		,count(patientid) AS "Count"
    	from adt_patientadmission
    	where admissionstatus = 'admitted'
    		and (createdon)::date between (p_fromdate)::date
    			and (p_todate)::date
    	
    	union all
    	
    	select 'Discharge' AS "Label"
    		,count(patientid) AS "Count"
    	from adt_patientadmission
    	where admissionstatus = 'discharged'
    		and (createdon)::date between (p_fromdate)::date
    			and (p_todate)::date;
END;
$$ LANGUAGE plpgsql;