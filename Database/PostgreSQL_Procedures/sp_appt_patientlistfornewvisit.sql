DROP FUNCTION IF EXISTS sp_appt_patientlistfornewvisit(CHARACTER VARYING, INTEGER, BOOLEAN, BOOLEAN);

CREATE OR REPLACE FUNCTION sp_appt_patientlistfornewvisit(
    p_searchtxt VARCHAR DEFAULT NULL,
    p_rowcounts INT DEFAULT NULL,
    p_searchusinghospitalno BOOLEAN DEFAULT FALSE,
    p_searchusingidcardno BOOLEAN DEFAULT FALSE
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor;
BEGIN
    IF p_searchtxt = '' THEN
        p_searchtxt := NULL;
    END IF;
    
    p_rowcounts := COALESCE(p_rowcounts, 200);

    OPEN ref FOR
    SELECT  
        pat."PatientId",
        pat."PatientCode",
        pat."ShortName",
        pat."FirstName",
        pat."LastName",
        pat."MiddleName",
        pat."Age",
        cntry."CountryName",
        pat."Gender",
        pat."PhoneNumber",
        pat."DateOfBirth",
        pat."Address",
        pat."IsOutdoorPat",
        pat."CreatedOn",
        pat."CountryId",
        pat."CountrySubDivisionId",
        pat."WardNumber",
        sub."CountrySubDivisionName",
        pat."MembershipTypeId",
        pat."PANNumber",
        pat."BloodGroup",
        pat."DialysisCode",
        CASE 
          WHEN adm."PatientId" IS NOT NULL THEN 1
          ELSE 0
        END AS "IsAdmitted",
        CAST(pat."Ins_HasInsurance" AS VARCHAR) AS "Ins_HasInsurance",
        pat."Ins_NshiNumber",
        pat."Ins_InsuranceBalance",
        pat."MunicipalityId",
        munc."MunicipalityName",
        pat."Email",
        pat."IDCardNumber",
        pat."Rank",
        pat."DependentId",
        pat."Posting",
        pat."EthnicGroup",
        mediMember."MemberNo" AS "MedicareMemberNo",
        patMap."PolicyNo" AS "PolicyNo",
        gur."GuarantorName" AS "CareTakerName",
        gur."PatientRelationship" AS "RelationWithCareTaker",
        gur."GuarantorPhoneNumber" AS "CareTakerContact"
    FROM "PAT_Patient" pat
    INNER JOIN "MST_Country" cntry ON pat."CountryId" = cntry."CountryId"
    INNER JOIN "MST_CountrySubDivision" sub ON pat."CountrySubDivisionId" = sub."CountrySubDivisionId"
    LEFT JOIN (
        SELECT DISTINCT "PatientId"
        FROM "ADT_PatientAdmission"
        WHERE "AdmissionStatus" = 'admitted'
    ) adm ON pat."PatientId" = adm."PatientId"
    LEFT JOIN "MST_Municipality" munc ON pat."MunicipalityId" = munc."MunicipalityId"
    LEFT JOIN "INS_MedicareMember" mediMember ON mediMember."PatientId" = pat."PatientId"
    LEFT JOIN (
        SELECT patMapScheme."PatientId", patMapScheme."PolicyNo" 
        FROM "PAT_MAP_PatientSchemes" patMapScheme 
        JOIN (
            SELECT "PatientId", "PatientVisitId", "SchemeId",
                   ROW_NUMBER() OVER (PARTITION BY "PatientId" ORDER BY "PatientVisitId" DESC) AS "row_num" 
            FROM "PAT_PatientVisits"
        ) patVis ON patMapScheme."PatientId" = patVis."PatientId" 
                 AND patMapScheme."LatestPatientVisitId" = patVis."PatientVisitId" 
                 AND patMapScheme."SchemeId" = patVis."SchemeId"
        WHERE patVis."row_num" = 1
    ) patMap ON pat."PatientId" = patMap."PatientId"
    LEFT JOIN "PAT_PatientGurantorInfo" gur ON pat."PatientId" = gur."PatientId"
    WHERE pat."IsActive" = TRUE
      AND (
        (
          (p_searchusinghospitalno = FALSE OR p_searchusinghospitalno IS NULL)
          AND (p_searchusingidcardno = FALSE OR p_searchusingidcardno IS NULL)
          AND (
            pat."PatientCode" LIKE '%' || COALESCE(p_searchtxt, '') || '%'
            OR pat."ShortName" LIKE '%' || COALESCE(p_searchtxt, '') || '%'
            OR COALESCE(pat."PhoneNumber", '') LIKE '%' || COALESCE(p_searchtxt, '') || '%'
          )
        )
        OR (
          p_searchusinghospitalno = TRUE
          AND pat."PatientCode" = COALESCE(p_searchtxt, pat."PatientCode")
        )
      )
    ORDER BY pat."PatientId" DESC 
    LIMIT p_rowcounts;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;