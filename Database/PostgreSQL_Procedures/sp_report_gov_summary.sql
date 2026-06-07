DROP FUNCTION IF EXISTS sp_report_gov_summary(DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS sp_report_gov_summary(TIMESTAMP, TIMESTAMP) CASCADE;
DROP FUNCTION IF EXISTS sp_report_gov_summary(TIMESTAMP WITHOUT TIME ZONE, TIMESTAMP WITHOUT TIME ZONE) CASCADE;

CREATE OR REPLACE FUNCTION sp_report_gov_summary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
    ref6 refcursor := 'cursor6';
    ref7 refcursor := 'cursor7';
    ref8 refcursor := 'cursor8';
    ref9 refcursor := 'cursor9';
    v_vaccdepartmentname VARCHAR := (
        SELECT "ParameterValue" 
        FROM "CORE_CFG_Parameters" 
        WHERE "ParameterName" = 'immunizationdeptname' 
          AND "ParameterGroupName" = 'Common' 
        LIMIT 1
    );
    v_deptid INT := (
        SELECT "DepartmentId" 
        FROM "MST_Department" 
        WHERE "DepartmentName" = v_vaccdepartmentname 
        LIMIT 1
    );
BEGIN
    -- table 1
    OPEN ref1 FOR 
    SELECT * 
    FROM fn_mr_hospsummary_getopanderservices((p_fromdate)::DATE, (p_todate)::DATE);
    RETURN NEXT ref1;

    -- table 2
    -- diagnosis and other services
    OPEN ref2 FOR 
    SELECT "ReportingItemName", "Unit", "TotalCount"
    FROM fn_mr_hospsummary_getdiagnosticandotherservices((p_fromdate)::DATE, (p_todate)::DATE)
    ORDER BY "OrderPriority" ASC, "ReportingItemName" DESC;
    RETURN NEXT ref2;

    -- table 3
    OPEN ref3 FOR 
    SELECT * 
    FROM fn_mr_hospsummary_getfreeservices((p_fromdate)::DATE, (p_todate)::DATE);
    RETURN NEXT ref3;

    -- total immunization patient served
    OPEN ref4 FOR 
    SELECT COUNT(*) AS "totalvaccinationclientserved"
    FROM "PAT_PatientVisits" patv 
    WHERE patv."DepartmentId" = v_deptid
      AND patv."IsActive" = TRUE
      AND patv."BillingStatus" != 'returned'
      AND (patv."VisitDate")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE;
    RETURN NEXT ref4;

    -- table 5
    -- inpatient referred out count table
    OPEN ref5 FOR 
    SELECT 
        COALESCE(SUM(CASE WHEN pat."Gender" = 'Male' THEN 1 ELSE 0 END), 0) AS "ipro_malecount",
        COALESCE(SUM(CASE WHEN pat."Gender" = 'Female' THEN 1 ELSE 0 END), 0) AS "ipro_femalecount"
    FROM "MR_RecordSummary" mrs
    INNER JOIN "ADT_DischargeType" dt ON mrs."DischargeTypeId" = dt."DischargeTypeId"
    INNER JOIN "PAT_Patient" pat ON mrs."PatientId" = pat."PatientId"
    INNER JOIN "ADT_PatientAdmission" adm ON mrs."PatientVisitId" = adm."PatientVisitId"
    WHERE dt."DischargeTypeName" = 'Referred'
      AND (adm."DischargeDate")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE;
    RETURN NEXT ref5;

    -- table 6
    -- total patient admitted table 
    OPEN ref6 FOR 
    SELECT COUNT("PatientId") AS "totalpatientsadmitted"
    FROM "ADT_PatientAdmission" 
    WHERE "AdmissionStatus" != 'cancel'
      AND ("AdmissionDate")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE;
    RETURN NEXT ref6;

    -- table 7
    -- total inpatient days table
    OPEN ref7 FOR 
    SELECT fn_mr_hospsummary_gettotalinpatientdays((p_fromdate)::DATE, (p_todate)::DATE) AS "totalinpatientdays";
    RETURN NEXT ref7;

    -- we need patient count, hence taking distinct patientid
    OPEN ref8 FOR 
    SELECT COUNT(DISTINCT pat."PatientId") AS "totllabserviceprovidedpersoncount"
    FROM "BIL_TXN_BillingTransactionItems" btxi 
    INNER JOIN "PAT_Patient" pat ON pat."PatientId" = btxi."PatientId"
    INNER JOIN "BIL_TXN_BillingTransaction" inv ON btxi."BillingTransactionId" = inv."BillingTransactionId"
    LEFT JOIN "BIL_TXN_InvoiceReturnItems" brtn ON btxi."BillingTransactionItemId" = brtn."BillingTransactionItemId"
    WHERE brtn."BillReturnItemId" IS NULL
      AND (inv."CreatedOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE
      AND btxi."ServiceDepartmentId" IN (
          SELECT "ServiceDepartmentId" 
          FROM "BIL_MST_ServiceDepartment" 
          WHERE "IntegrationName" = 'LAB'
      );
    RETURN NEXT ref8;

    -- table 9
    OPEN ref9 FOR 
    SELECT 
        COALESCE(SUM(CASE WHEN pt."Gender" = 'Male' THEN 1 ELSE 0 END), 0) AS "opreferred_malecount",
        COALESCE(SUM(CASE WHEN pt."Gender" = 'Female' THEN 1 ELSE 0 END), 0) AS "opreferred_femalecount"
    FROM (
        SELECT "PatientId", "PatientVisitId", "IsPatientReferred", "IsActive" 
        FROM "MR_TXN_Outpatient_FinalDiagnosis" 
        GROUP BY "PatientVisitId", "PatientId", "IsPatientReferred", "IsActive"
    ) ofd
    INNER JOIN "PAT_Patient" pt ON pt."PatientId" = ofd."PatientId"
    INNER JOIN "PAT_PatientVisits" ptv ON ptv."PatientVisitId" = ofd."PatientVisitId"
    WHERE ofd."IsActive" = TRUE 
      AND ofd."IsPatientReferred" = TRUE 
      AND (ptv."VisitDate")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE;
    RETURN NEXT ref9;
END;
$$ LANGUAGE plpgsql;