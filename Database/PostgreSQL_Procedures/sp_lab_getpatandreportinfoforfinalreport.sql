DROP FUNCTION IF EXISTS sp_lab_getpatandreportinfoforfinalreport(date, date, varchar, varchar);
DROP FUNCTION IF EXISTS sp_lab_getpatandreportinfoforfinalreport(timestamp without time zone, timestamp without time zone, varchar, varchar);
DROP FUNCTION IF EXISTS sp_lab_getpatandreportinfoforfinalreport(timestamp without time zone, timestamp without time zone, unknown, text);

CREATE OR REPLACE FUNCTION sp_lab_getpatandreportinfoforfinalreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_labtypename VARCHAR DEFAULT 'op-lab',
    p_categoryidcsv VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "PhoneNumber" VARCHAR,
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
    "ReportGeneratedBy" VARCHAR,
    "LabTestCSV" TEXT,
    "LabRequisitionIdCSV" TEXT,
    "AllowOutpatientWithProvisional" INT,
    "IsValidToPrint" INT
) AS $$
DECLARE
    v_allowprovisionalprintstr VARCHAR;
    v_allowprovisionalprint INT := 0;
    v_isverificationenabled BOOLEAN;
    v_verificationparam VARCHAR;
BEGIN
    /*
    file: sp_lab_getpatandreportinfoforfinalreport
    created: anish/sud:6sep'21
    Description: To get patient info, report info, etc in a date range for Final Reports Grid
    Updated for PostgreSQL compatibility.
    */
    
    SELECT "ParameterValue" INTO v_verificationparam 
    FROM "CORE_CFG_Parameters" 
    WHERE "ParameterName" = 'LabReportVerificationNeededB4Print'
    LIMIT 1;

    SELECT "ParameterValue" INTO v_allowprovisionalprintstr 
    FROM "CORE_CFG_Parameters" 
    WHERE LOWER("ParameterGroupName")='lab' AND "ParameterName"='allowlabreporttoprintonprovisional'
    LIMIT 1;
    
    IF(v_allowprovisionalprintstr = 'true' OR v_allowprovisionalprintstr = '1') THEN 
      v_allowprovisionalprint := 1;
    END IF;
    
    v_isverificationenabled := COALESCE(CAST(v_verificationparam::json->>'EnableVerificationStep' AS BOOLEAN), FALSE);
    
    RETURN QUERY SELECT 
        pat."PatientId",
        pat."PatientCode", 
        pat."DateOfBirth", 
        pat."PhoneNumber", 
        pat."Gender", 
        pat."ShortName" AS "PatientName",
        pat."FirstName",
        pat."LastName",
        pat."Email",
        req."SampleCodeFormatted", 
        req."VisitType", 
        req."RunNumberType", 
        req."IsFileUploadedToTeleMedicine",
        COALESCE(rpt."IsPrinted", false) AS "IsPrinted", 
        req."BillingStatus",
        CAST(req."BarCodeNumber" AS VARCHAR) AS "BarCodeNumber", 
        rpt."LabReportId" AS "ReportId", 
        req."WardName",
        emp."FullName" AS "ReportGeneratedBy",
        string_agg(req."LabTestName", ',') AS "LabTestCSV",
        string_agg(CAST(req."RequisitionId" AS VARCHAR), ',')  AS "LabRequisitionIdCSV",
        v_allowprovisionalprint AS "AllowOutpatientWithProvisional",
        CASE WHEN v_allowprovisionalprint=1 THEN 1 
             WHEN req."VisitType"='inpatient' OR req."VisitType"='emergency' THEN 1
             WHEN req."BillingStatus" !='provisional' THEN 1
             ELSE 0 END AS "IsValidToPrint"
    FROM "LAB_TestRequisition" req 
    INNER JOIN "LAB_LabTests" tst on req."LabTestId" = tst."LabTestId"
    INNER JOIN "LAB_TestCategory" allCat on allCat."TestCategoryId" = tst."LabTestCategoryId"
    INNER JOIN (
        SELECT (val)::int AS "CategoryId" 
        FROM regexp_split_to_table(p_categoryidcsv, ',') AS val 
        WHERE trim(val) <> ''
    ) selCat on selCat."CategoryId" = allCat."TestCategoryId"
    INNER JOIN "PAT_Patient" pat on req."PatientId" = pat."PatientId"
    INNER JOIN "LAB_TXN_LabReports" rpt on req."LabReportId" = rpt."LabReportId"
    LEFT JOIN "EMP_Employee" emp on rpt."CreatedBy" = emp."EmployeeId"
    WHERE (rpt."CreatedOn")::Date Between p_fromdate::Date and p_todate::Date
         AND coalesce(req."LabTypeName",'op-lab') = coalesce(p_labtypename,'op-lab')
         AND req."BillingStatus" not in ('cancel','returned')
         AND req."OrderStatus" = 'report-generated'
         AND (req."IsVerified" = true or coalesce(req."IsVerified", false) = v_isverificationenabled)
    GROUP BY 
        pat."PatientId",
        pat."PatientCode", 
        pat."DateOfBirth", 
        pat."PhoneNumber", 
        pat."Gender", 
        pat."ShortName",
        pat."FirstName",
        pat."LastName",
        pat."Email",
        req."SampleCodeFormatted", 
        req."VisitType", 
        req."RunNumberType", 
        req."IsFileUploadedToTeleMedicine",
        rpt."IsPrinted", 
        req."BillingStatus",
        req."BarCodeNumber", 
        rpt."LabReportId", 
        req."WardName", 
        emp."FullName";
END;
$$ LANGUAGE plpgsql;