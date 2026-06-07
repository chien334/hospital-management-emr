CREATE OR REPLACE FUNCTION sp_lab_getpatandreportinfoforfinalreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_labtypename VARCHAR DEFAULT 'op-lab',
    p_categoryidcsv VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PhoneNumber" TIMESTAMP,
    "Gender" VARCHAR,
    "PatientName" VARCHAR,
    "FirstName" VARCHAR,
    "LastName" VARCHAR,
    "Email" VARCHAR,
    "SampleCodeFormatted" VARCHAR,
    "VisitType" VARCHAR,
    "RunNumberType" VARCHAR,
    "IsFileUploadedToTeleMedicine" BOOLEAN,
    "IsPrinted" BOOLEAN,
    "BillingStatus" VARCHAR,
    "BarCodeNumber" VARCHAR,
    "ReportId" INT,
    "WardName" VARCHAR,
    "ReportGeneratedBy" DECIMAL,
    "LabTestCSV" VARCHAR,
    "LabRequisitionIdCSV" INT,
    "AllowOutpatientWithProvisional" TIMESTAMP,
    "IsValidToPrint" INT
) AS $$
DECLARE
    v_allowprovisionalprintstr VARCHAR;
    v_allowprovisionalprint BOOLEAN := FALSE;
    v_isverificationenabled BOOLEAN;
    v_verificationparam VARCHAR := (Select ParameterValue 
                                           from CORE_CFG_Parameters 
										   where ParameterName='LabReportVerificationNeededB4Print');
BEGIN
    /*
    file: sp_lab_getpatandreportinfoforfinalreport
    created: anish/sud:6sep'21
    Description: To get patient info, report info, etc in a date range for Final Reports Grid
    NOTE: 
       * Returned  And Cancelled items are excluded from this.
       * Provisional Print restriction (parameterized) is checked here
       * our default labtype is op-lab (it may not be passed from some hospitals, hence pre-assigned it.
    Change History:
    S.No.  ChangedBy/Date               Remarks
    1.    Anish/Sud:6Sep'21             needed new sp since for final report since previous was processing more data and hence taking more time
    2.    anish/10sep'21                Correction in Verification Filter, which was missing earlier.
    3.    Dev /23Jan' 22                added new fileds in select query like firstname, lastname, email,isfileuploadedtotelemedicine etc.
    4.   krishna/dev:14thdec'22			Query optimization 
    */
    BEGIN
    
    
    v_allowprovisionalprintstr := (Select ParameterValue 
                                     from CORE_CFG_Parameters 
    								 where LOWER(ParameterGroupName)='lab' and ParameterName='allowlabreporttoprintonprovisional');
    
    IF(v_allowprovisionalprintstr = 'true' OR v_allowprovisionalprintstr = '1')
    THEN 
      v_allowprovisionalprint := 1;
    END IF;
    
    
    
    v_isverificationenabled := (SELECT JSON_VALUE(v_verificationparam, '$.enableverificationstep'));
    
    
    --Declare v_categoryidtbl Table(CategoryId int)
    --Insert into v_categoryidtbl
    --Select value from string_split(p_categoryidcsv, ',') where RTRIM(value) <> ''
    
    RETURN QUERY SELECT pat.PatientId,
    pat.PatientCode, 
    pat.DateOfBirth, 
    pat.PhoneNumber, 
    pat.Gender, 
    pat.ShortName AS "PatientName",
    pat.FirstName,
    pat.LastName,
    pat.Email,
    req.SampleCodeFormatted, 
    req.VisitType, 
    req.RunNumberType, 
    req.IsFileUploadedToTeleMedicine,
    COALESCE(rpt.IsPrinted,0) AS "IsPrinted", 
    req.BillingStatus,
    req.BarCodeNumber, 
    rpt.LabReportId AS "ReportId", 
    req.WardName,
    emp.FullName AS "ReportGeneratedBy",
    string_agg(req.LabTestName, ',') AS "LabTestCSV",
    string_agg(req.RequisitionId, ',')  AS "LabRequisitionIdCSV",
    v_allowprovisionalprint AS "AllowOutpatientWithProvisional",
    CASE WHEN v_allowprovisionalprint=1 then 1 
         WHEN req.VisitType='inpatient' OR req.VisitType='emergency' THEN 1
         WHEN req.BillingStatus !='provisional' THEN 1
         ELSE 0 END AS "IsValidToPrint"
    FROM LAB_TestRequisition req 
    INNER JOIN LAB_LabTests tst on req.LabTestId=tst.LabTestId
    INNER JOIN LAB_TestCategory allCat on allCat.TestCategoryId=tst.LabTestCategoryId
    INNER JOIN (Select (value)::int AS "CategoryId" from string_split(p_categoryidcsv, ',') where RTRIM(value) <> '') selCat 
    on selCat.CategoryId=allCat.TestCategoryId
    INNER JOIN PAT_Patient pat on req.PatientId=pat.PatientId
    INNER JOIN LAB_TXN_LabReports rpt on req.LabReportId=rpt.LabReportId
    LEFT JOIN EMP_Employee emp on rpt.CreatedBy = emp.EmployeeId
    
    Where (rpt.CreatedOn)::Date Between p_fromdate and p_todate
         --checking for default labtypename if it's null
         and coalesce(req.labtypename,'op-lab')= coalesce(p_labtypename,'op-lab')
       --and req.billingstatus <>'cancel'
       --and req.billingstatus <>'returned'
       and req.billingstatus not in ('cancel','returned')
       and req.orderstatus = 'report-generated'
       and (req.isverified=1 or coalesce(req.isverified,0)=v_isverificationenabled)
    
    group by pat.patientid,
        pat.patientcode, 
        pat.dateofbirth, 
        pat.phonenumber, 
        pat.gender, 
        pat.shortname,
        req.samplecodeformatted, 
        req.visittype, 
        req.runnumbertype, 
        rpt.isprinted, 
        req.billingstatus,
        req.barcodenumber, 
        rpt.labreportid, 
        req.wardname, 
        emp.fullname,
    	pat.firstname,
    	pat.lastname,
    	pat.email,
    	req.isfileuploadedtotelemedicine;
    end;
END;
$$ LANGUAGE plpgsql;