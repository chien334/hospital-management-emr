CREATE OR REPLACE FUNCTION sp_lab_getallsmsapplicabletests(
    p_fromdate DATE,
    p_todate DATE
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
    "IsSmsSend" BOOLEAN,
    "IsVerified" BOOLEAN,
    "Result" VARCHAR,
    "IsFileUploaded" BOOLEAN
) AS $$
DECLARE
    v_covidtestname VARCHAR := '';
    v_verificationparameter VARCHAR := '';
    v_isverificationrequired BOOLEAN := FALSE;
    v_verificationlevel INT := 0;
BEGIN
    /*
    sp name:	sp_lab_getallsmsapplicabletests
    author:		krishna bogati/sanjit raj shakya
    createdon:	2021-12-22
    remarks:	created sp to replace linq query from api in lab controller
    exec example: exec sp_lab_getallsmsapplicabletests p_fromdate = '2021-01-01', p_todate = '2021-12-22'
    */
    
    	
    	
    	
    	
    	
    	
    	select json_value(parametervalue, '$.DisplayName') into v_covidtestname from core_cfg_parameters
    	where parametergroupname = 'common' and parametername = 'CovidTestName' limit 1;
    
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
    		coalesce(lr.issmssend,0) AS "IsSmsSend", 
    		lr.isverified, 
    		ltcr.value AS "Result", 
    		coalesce(lr.isfileuploaded,0) AS "IsFileUploaded"
    	from 
    		lab_testrequisition as lr
    		inner join pat_patient as p on lr.patientid = (p.patientid)
    		inner join lab_labtests as lt on lr.labtestid = lt.labtestid
    		inner join lab_txn_testcomponentresult as ltcr on lr.requisitionid = ltcr.requisitionid
    	where 
    		lt.smsapplicable = 1 and 
    		lt.labtestname = v_covidtestname and
    		lr.orderstatus in ('report-generated','result-added') and
    		((v_isverificationrequired = 1 and lr.isverified = 1) or v_isverificationrequired = 0) and
    		ltcr.value in ('positive','negative') and
    		lr.isactive = 1 and
    		(lr.createdon)::date between p_fromdate and p_todate;
END;
$$ LANGUAGE plpgsql;