CREATE OR REPLACE FUNCTION sp_lab_getalllabrequisitionforexternallab(
    p_patientname VARCHAR DEFAULT NULL,
    p_hospitalcode VARCHAR DEFAULT NULL,
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_labtestidcsv VARCHAR DEFAULT NULL,
    p_vendorid INT DEFAULT NULL,
    p_externallabstatus VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "RequisitionId" INT,
    "PatientName" VARCHAR,
    "VendorName" VARCHAR,
    "TestName" VARCHAR,
    "HospitalNo" VARCHAR,
    "ExternalLabSampleStatus" VARCHAR
) AS $$
BEGIN
    /*
    change history
    s.no.    updatedby/date                        remarks
    1       devn/13sept'23                       Initial Draft to get all lab requisitions sent to external lab.
    2       Santosh/13Sept'23                    externallabstatus filter is added to the sp to get data accourding to the sample                                            status
    */
    
    RETURN QUERY SELECT req.requisitionid
    	,pat.shortname AS "PatientName"
    	,vendor.vendorname
    	,test.labtestname AS "TestName"
    	,pat.patientcode AS "HospitalNo"
    	,req.externallabsamplestatus
    from (
    	(
    		select requisitionid
    			,labtestid
    			,patientid
    			,resultingvendorid
    			,externallabsamplestatus
    		from lab_testrequisition 
    		where (createdon)::date between p_fromdate
    				and p_todate and resultingvendorid = p_vendorid
    		) req 
    	inner join (
    		select (value)::int as "labtestid"
    		from string_split(p_labtestidcsv, ',')
    		where rtrim(value) <> ''
    		) testids on req.labtestid = testids.labtestid
    	inner join lab_mst_labvendors vendor on req.resultingvendorid = vendor.labvendorid
    	inner join pat_patient pat on req.patientid = pat.patientid
    	inner join lab_labtests test on testids.labtestid = test.labtestid
    	)
    where (p_patientname = '' or pat.shortname like p_patientname || '%')
    and (p_hospitalcode = '' or pat.patientcode = p_hospitalcode) and (p_externallabstatus='' or req.externallabsamplestatus = p_externallabstatus );
END;
$$ LANGUAGE plpgsql;