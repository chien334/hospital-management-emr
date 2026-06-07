DROP FUNCTION IF EXISTS sp_ins_getvisitlistofvaliddays(CHARACTER VARYING, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION sp_ins_getvisitlistofvaliddays(
    p_searchtxt VARCHAR DEFAULT NULL,
    p_rowcounts INT DEFAULT 200,
    p_dayslimit INT DEFAULT 1
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor;
    v_now TIMESTAMP;
    v_validdate TIMESTAMP;
BEGIN
    v_now := CURRENT_TIMESTAMP;
    v_validdate := v_now - (p_dayslimit || ' day')::INTERVAL;
    
    IF p_searchtxt = 'null' THEN
        p_searchtxt := NULL;
    END IF;
    
    p_rowcounts := COALESCE(p_rowcounts, 200);

    OPEN ref FOR
    SELECT  
        visit."PatientVisitId", 
        visit."ParentVisitId", 
        dept."DepartmentId",
        dept."DepartmentName",
        visit."PerformerId", 
        visit."PerformerName", 
        visit."VisitDate", 
        visit."VisitTime", 
        visit."VisitType", 
        visit."AppointmentType", 
        pat."PatientId", 
        pat."PatientCode", 
        pat."FirstName", 
        pat."MiddleName", 
        pat."LastName", 
        pat."ShortName", 
        pat."PhoneNumber", 
        pat."DateOfBirth", 
        pat."Gender", 
        pat."CountryId", 
        pat."PANNumber", 
        pat."MembershipTypeId", 
        pat."Address", 
        pat."Email", 
        pat."LandLineNumber",
        visit."ClaimCode",
        pat."Ins_NshiNumber",
        visit."Ins_HasInsurance",
        visit."QueueNo", 
        visit."BillingStatus" AS "BillStatus"
    FROM "PAT_PatientVisits" AS visit
    INNER JOIN "MST_Department" AS dept ON visit."DepartmentId" = dept."DepartmentId"
    INNER JOIN "PAT_Patient" AS pat ON visit."PatientId" = pat."PatientId"
    WHERE pat."IsActive" = TRUE
      AND visit."IsActive" = TRUE
      AND visit."Ins_HasInsurance" = TRUE
      AND visit."VisitDate" >= v_validdate
      AND visit."VisitDate" <= v_now
      AND LOWER(visit."VisitType") != 'inpatient'
      AND LOWER(visit."BillingStatus") != 'returned'
      AND (
          pat."PatientCode" LIKE '%' || COALESCE(p_searchtxt, '') || '%' 
          OR COALESCE(pat."Ins_NshiNumber", '') LIKE '%' || COALESCE(p_searchtxt, '') || '%'
          OR pat."ShortName" LIKE '%' || COALESCE(p_searchtxt, '') || '%' 
          OR COALESCE(pat."PhoneNumber", '') LIKE '%' || COALESCE(p_searchtxt, '') || '%'
      )
    ORDER BY visit."PatientVisitId" DESC 
    LIMIT p_rowcounts;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;