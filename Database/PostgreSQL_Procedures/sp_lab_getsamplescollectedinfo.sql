CREATE OR REPLACE FUNCTION sp_lab_getsamplescollectedinfo(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_selectedlab VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientName" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PatientCode" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "TestCategoryName" VARCHAR,
    "LabTestName" VARCHAR,
    "BarCodeNumber" VARCHAR,
    "SampleCodeFormatted" VARCHAR,
    "SampleCreatedOn" TIMESTAMP,
    "LabTestSpecimen" VARCHAR,
    "SampleCollectedOnDateTime" TIMESTAMP
) AS $$
BEGIN
    /*
    filename: sp_appt_getpatientvisitstickerinfo
    createdby/date: anjana/feb/22/2021
    description: get list of lab items whose sample collection is completed.  
    
    change history
    s.no.    updatedby/date                        remarks
    1.      anjana/feb/22/2021                   initial draft
    2.      anjana/march/9/2021					added samplecollectedondatetime on select
    */
    
    
    RETURN QUERY SELECT 
    	pat.patientid,
    	pat.shortname AS "PatientName",
    	pat.age,
    	pat.gender,
    	pat.dateofbirth,
    	pat.patientcode,
    	pat.phonenumber,
    	cat.testcategoryname,
    	test.labtestname,
    	req.barcodenumber,
    	req.samplecodeformatted,
    	req.samplecreatedon,
    	req.labtestspecimen,
    	req.samplecollectedondatetime
    
      from lab_testrequisition req join pat_patient pat on pat.patientid=req.patientid
    			join lab_labtests test on test.labtestid = req.labtestid 
    			join lab_testcategory cat on cat.testcategoryid = test.labtestcategoryid 
                where req.orderstatus != lower('active')
    			and (req.createdon)::date between coalesce(p_fromdate, (current_timestamp)::date) and coalesce(p_todate, (current_timestamp)::date) 
    			and req.billingstatus != 'cancel' and req.billingstatus != 'returned'			
    			and req.labtypename = lower(p_selectedlab)
    			order by req.barcodenumber asc;
END;
$$ LANGUAGE plpgsql;