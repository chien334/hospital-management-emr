CREATE OR REPLACE FUNCTION sp_lab_getallimucasedata(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP
)
RETURNS TABLE (
    "RequisitionId" INT,
    "PatientName" VARCHAR,
    "LabTestName" VARCHAR,
    "SampleCollectedOnDateTime" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "PatientCode" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "Result" VARCHAR,
    "IsFileUploaded" BOOLEAN
) AS $$
DECLARE
    v_testcsv VARCHAR := '';
    v_verificationparameter VARCHAR := '';
    v_isverificationrequired BOOLEAN := FALSE;
    v_verificationlevel INT := 0;
    v_json VARCHAR := (select ParameterValue FROM CORE_CFG_Parameters
	WHERE ParameterGroupName = 'LAB' AND ParameterName = 'LabIMUenabledTests');
BEGIN
    /*
    sp name:	"sp_lab_getallimucasedata"
    author:		dev narayan chaudhary
    createdon:	2022-03-28
    remarks:	stored procedure that provides all tests list for imu upload
    exec example: exec sp_lab_getallimucasedata p_fromdate = '2022-02-01', p_todate = '2022-03-28'
    */
    
    	
    	
    	
    	
    	
    	
    	
    	select string_agg(imutestlist.danphelabtestname,',') into v_testcsv from json_to_recordset(v_json::json) as imutestlist(
    		    danphelabtestname varchar(100)
    		); 
    
    	select parametervalue into v_verificationparameter from core_cfg_parameters
    	where parametergroupname = 'lab' and parametername = 'LabReportVerificationNeededB4Print' limit 1;
    
    	v_isverificationrequired := cast (json_value(v_verificationparameter, '$.EnableVerificationStep') as boolean);
    	v_verificationlevel := cast (json_value(v_verificationparameter, '$.VerificationLevel') as int);
    
    
    	RETURN QUERY SELECT 
    		lr.requisitionid, 
    		p.shortname AS "PatientName", 
    		lr.labtestname, 
    		lr.samplecollectedondatetime, 
    		p.dateofbirth, 
    		p.age, 
    		p.gender, 
    		p.patientcode, 
    		coalesce(p.phonenumber,'') AS "PhoneNumber", 
    		ltcr.value AS "Result", 
    		coalesce(lr.isuploadedtoimu,0) AS "IsFileUploaded"
    	from 
    		lab_testrequisition as lr
    		inner join pat_patient as p on lr.patientid = (p.patientid)
    		inner join lab_labtests as lt on lr.labtestid = lt.labtestid
    		inner join lab_txn_testcomponentresult as ltcr on lr.requisitionid = ltcr.requisitionid
    	where 
    		lt.labtestname in (select value from string_split(v_testcsv,',')) and
    		lr.orderstatus in ('report-generated','result-added') and
    		((v_isverificationrequired = 1 and lr.isverified = 1) or v_isverificationrequired = 0) and
    		ltcr.value in ('positive','negative') and
    		lr.isactive = 1 and
    		(lr.createdon)::date between p_fromdate and p_todate;
END;
$$ LANGUAGE plpgsql;