CREATE OR REPLACE FUNCTION sp_lab_getalllabprovisionalfinalreports(
    p_barcodenumber INT DEFAULT 0,
    p_samplenumber INT DEFAULT 0,
    p_patientid INT DEFAULT 0,
    p_startdate TIMESTAMP DEFAULT NULL,
    p_enddate TIMESTAMP DEFAULT NULL,
    p_categorylist VARCHAR DEFAULT NULL,
    p_labtype VARCHAR DEFAULT NULL,
    p_isforlabmaster BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    "SampleCodeFormatted" VARCHAR,
    "SampleCode" VARCHAR,
    "SampleDate" TIMESTAMP,
    "LabReportId" INT,
    "VisitType" VARCHAR,
    "RunNumType" VARCHAR,
    "IsPrinted" BOOLEAN,
    "BarCodeNumber" VARCHAR,
    "WardName" VARCHAR,
    "LabTestName" VARCHAR,
    "BillingStatus" VARCHAR,
    "RequisitionId" INT,
    "LabTestId" INT,
    "SampleCollectedBy" VARCHAR,
    "VerifiedBy" VARCHAR,
    "IsVerified" BOOLEAN,
    "ResultAddedBy" VARCHAR,
    "HasInsurance" BOOLEAN,
    "PrintCount" INT,
    "PrintedBy" VARCHAR,
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PhoneNumber" TIMESTAMP,
    "Gender" VARCHAR,
    "PatientName" VARCHAR,
    "ReportGeneratedBy" DECIMAL,
    "ReportGeneratedById" INT,
    "LabCategoryId" INT,
    "AllowOutpatientWithProvisional" TIMESTAMP,
    "BillingStatus_1" VARCHAR
) AS $$
DECLARE
    v_allowprovisionalprintstr VARCHAR;
    v_allowprovisionalprint BOOLEAN := FALSE;
BEGIN
    DROP TABLE IF EXISTS v_categorytbl;
    CREATE TEMP TABLE v_categorytbl (
        CategoryId int
    );
    begin
    	
    	v_allowprovisionalprintstr := (select parametervalue from core_cfg_parameters where lower(parametergroupname)='lab' and parametername='AllowLabReportToPrintOnProvisional');
    	
    	if(v_allowprovisionalprintstr = 'true' or v_allowprovisionalprintstr = '1')
    	then 
    	v_allowprovisionalprint := 1;
    	end if;
    
    	
    	insert into v_categorytbl
    	select value from string_split(p_categorylist, ',') where rtrim(value) <> '';
    		RETURN QUERY SELECT req.samplecodeformatted, req.samplecode, (req.samplecreatedon)::date AS "SampleDate", req.labreportid, req.visittype, req.runnumbertype AS "RunNumType", report.isprinted, req.barcodenumber, req.wardname, req.labtestname, req.billingstatus, req.requisitionid, req.labtestid, req.samplecreatedby AS "SampleCollectedBy", req.verifiedby AS "VerifiedBy", req.isverified, req.resultaddedby AS "ResultAddedBy", req.hasinsurance, req.printcount, req.printedby, pat.patientid, pat.patientcode, pat.dateofbirth, pat.phonenumber, pat.gender, pat.shortname AS "PatientName", emp.fullname AS "ReportGeneratedBy", report.createdby AS "ReportGeneratedById", test.labtestcategoryid AS "LabCategoryId", v_allowprovisionalprint AS "AllowOutpatientWithProvisional", case lower(req.billingstatus) 
    		when 'provisional' then 'provisional' 
    		when 'unpaid' then 'paid'
    		when 'paid' then 'paid'
    		else '' end AS "BillingStatus_1" from lab_testrequisition req 
    		join pat_patient pat on req.patientid = pat.patientid
    		join lab_txn_labreports report on req.labreportid = report.labreportid
    		join lab_labtests test on req.labtestid = test.labtestid
    		left join emp_employee emp on report.createdby = emp.employeeid
    		where req.orderstatus = 'report-generated' and 
    		(req.barcodenumber = (case p_barcodenumber when 0 then req.barcodenumber else p_barcodenumber end)) and
    		(req.samplecode = (case p_samplenumber when 0 then req.samplecode else p_samplenumber end)) and
    		(req.patientid = (case p_patientid when 0 then req.patientid else p_patientid end)) and
    		(report.createdon is not null) and 
    		((report.createdon)::date between (p_startdate)::date and (p_enddate)::date) and 
    		(test.labtestcategoryid in (select categoryid from v_categorytbl)) and 
    		(lower(req.billingstatus) in ('paid','unpaid','provisional')) and
    		(req.labtypename = (case p_isforlabmaster when 1 then req.labtypename else p_labtype end));		 
    end;
END;
$$ LANGUAGE plpgsql;