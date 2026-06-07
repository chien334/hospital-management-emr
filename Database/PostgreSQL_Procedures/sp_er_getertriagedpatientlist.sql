DROP FUNCTION IF EXISTS sp_er_getertriagedpatientlist(INTEGER);

CREATE OR REPLACE FUNCTION sp_er_getertriagedpatientlist(
    p_selectedcase INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor;
BEGIN
    OPEN ref FOR
    SELECT 
        erPat."ERPatientId",
        erPat."ERPatientNumber",
        erPat."PatientId",
        erPat."PatientVisitId",
        pat."PatientCode",
        erPat."VisitDateTime",
        erPat."FirstName",
        erPat."MiddleName",
        erPat."LastName",
        erPat."Gender",
        erPat."Age",
        erPat."Age" || '/' || SUBSTRING(erPat."Gender", 1, 1) AS "AgeSex",
        erPat."DateOfBirth",
        erPat."ContactNo",
        erPat."Address",
        erPat."ReferredBy",
        erPat."ReferredTo",
        erPat."PerformerId",
        erPat."PerformerName",
        erPat."ConditionOnArrival",
        moa."ModeOfArrivalName",
        moa."ModeOfArrivalId",
        erPat."CareOfPerson",
        erPat."ERStatus",
        erPat."TriageCode",
        erPat."TriagedBy",
        erPat."TriagedOn",
        erPat."CreatedBy",
        erPat."CreatedOn",
        erPat."ModifiedBy",
        erPat."ModifiedOn",
        erPat."IsActive",
        erPat."OldPatientId",
        erPat."IsExistingPatient",
        pat."ShortName" AS "FullName",
        pat."CountryId",
        pat."CountrySubDivisionId",
        (
            SELECT employee."FullName"
            FROM "ER_Patient" emrPat
            INNER JOIN "EMP_Employee" employee ON emrPat."TriagedBy" = employee."EmployeeId"
            WHERE emrPat."ERPatientId" = erPat."ERPatientId"
                AND emrPat."ERStatus" = 'triaged' 
            LIMIT 1
        ) AS "TriagedByName",
        (
            (SELECT row_to_json(t) FROM (
                SELECT patC.*
                FROM "ER_Patient_Cases" patC
                INNER JOIN "PAT_Patient" patient ON patC."ERPatientId" = patient."PatientId"
                WHERE patC."IsActive" = TRUE
                    AND patC."ERPatientId" = erPat."ERPatientId"
                ORDER BY patC."PatientCaseId" DESC
            ) AS "t")::text
        ) AS "PatientCases",
        patientSchemeMap."SchemeId",
        patientSchemeMap."PriceCategoryId",
        scheme."SchemeName",
        priceCat."PriceCategoryName"
    FROM "ER_Patient" erPat
    INNER JOIN "PAT_Patient" pat ON erPat."PatientId" = pat."PatientId"
    LEFT JOIN "ER_ModeOfArrival" moa ON erPat."ModeOfArrival" = moa."ModeOfArrivalId"
    INNER JOIN "PAT_PatientVisits" visit ON erPat."PatientVisitId" = visit."PatientVisitId"
    LEFT JOIN "PAT_MAP_PatientSchemes" patientSchemeMap ON visit."PatientId" = patientSchemeMap."PatientId"
        AND visit."SchemeId" = patientSchemeMap."SchemeId"
    INNER JOIN "BIL_CFG_Scheme" scheme ON patientSchemeMap."SchemeId" = scheme."SchemeId"
    LEFT JOIN "BIL_CFG_PriceCategory" priceCat ON patientSchemeMap."PriceCategoryId" = priceCat."PriceCategoryId"
    WHERE erPat."ERStatus" = 'triaged'
        AND erPat."IsActive" = TRUE
        AND COALESCE(erPat."FinalizedStatus", '') = ''
        AND (
            p_selectedcase = 0
            OR p_selectedcase = (
                SELECT epc."MainCase"
                FROM "ER_Patient_Cases" epc
                WHERE epc."ERPatientId" = erPat."ERPatientId"
                    AND epc."IsActive" = TRUE
                ORDER BY epc."PatientCaseId" DESC 
                LIMIT 1
            )
        )
    ORDER BY erPat."ERPatientId" DESC;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;