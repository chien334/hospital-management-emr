CREATE OR REPLACE FUNCTION sp_appt_patientlistfornewvisit(
    p_searchtxt varchar DEFAULT '',
    p_rowcounts integer DEFAULT 200,
    p_searchusinghospitalno boolean DEFAULT FALSE,
    p_searchusingidcardno boolean DEFAULT FALSE
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
    v_searchtxt varchar := p_searchtxt;
    v_rowcounts integer := p_rowcounts;
    v_searchusinghospitalno boolean := p_searchusinghospitalno;
    v_searchusingidcardno boolean := p_searchusingidcardno;
BEGIN
    IF v_searchtxt = '' THEN
        v_searchtxt := NULL;
    END IF;

    IF v_searchusinghospitalno IS NULL THEN
        v_searchusinghospitalno := FALSE;
    END IF;

    IF v_searchusingidcardno IS NULL THEN
        v_searchusingidcardno := FALSE;
    END IF;

    IF v_rowcounts IS NULL THEN
        v_rowcounts := 200;
    END IF;

    OPEN ref FOR
    SELECT pat."PatientId"
        ,pat."PatientCode"
        ,pat."ShortName"
        ,pat."FirstName"
        ,pat."LastName"
        ,pat."MiddleName"
        ,pat."Age"
        ,cntry."CountryName"
        ,pat."Gender"
        ,pat."PhoneNumber"
        ,pat."DateOfBirth"
        ,pat."Address"
        ,pat."IsOutdoorPat"
        ,pat."CreatedOn"
        ,pat."CountryId"
        ,pat."CountrySubDivisionId"
        ,pat."WardNumber"
        ,sub."CountrySubDivisionName"
        ,pat."MembershipTypeId"
        ,pat."PANNumber"
        ,pat."BloodGroup"
        ,pat."DialysisCode"
        ,CASE 
            WHEN adm."PatientId" IS NOT NULL THEN 1
            ELSE 0
         END AS "IsAdmitted"
        ,pat."Ins_HasInsurance"
        ,pat."Ins_NshiNumber"
        ,pat."Ins_InsuranceBalance"
        ,pat."MunicipalityId"
        ,munc."MunicipalityName"
        ,pat."Email"
        ,pat."IDCardNumber"
        ,pat."Rank"
        ,pat."DependentId"
        ,pat."Posting"
        ,pat."EthnicGroup"
        ,mediMember."MemberNo" AS "MedicareMemberNo"
        ,patMap."PolicyNo" AS "PolicyNo"
        ,gur."GuarantorName" AS "CareTakerName"
        ,gur."PatientRelationship" AS "RelationWithCareTaker"
        ,gur."GuarantorPhoneNumber" AS "CareTakerContact"
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
                   ROW_NUMBER() OVER (PARTITION BY "PatientId" ORDER BY "PatientVisitId" DESC) AS row_num 
            FROM "PAT_PatientVisits"
        ) patVis ON patMapScheme."PatientId" = patVis."PatientId" 
                 AND patMapScheme."LatestPatientVisitId" = patVis."PatientVisitId" 
                 AND patMapScheme."SchemeId" = patVis."SchemeId"
        WHERE patVis.row_num = 1
    ) patMap ON pat."PatientId" = patMap."PatientId"
    LEFT JOIN "PAT_PatientGurantorInfo" gur ON pat."PatientId" = gur."PatientId"
    WHERE pat."IsActive" = TRUE
      AND (
        (
          (COALESCE(v_searchusinghospitalno, FALSE) = FALSE AND COALESCE(v_searchusingidcardno, FALSE) = FALSE)
          AND (
            pat."PatientCode" LIKE '%' || COALESCE(v_searchtxt, '') || '%'
            OR pat."ShortName" LIKE '%' || COALESCE(v_searchtxt, '') || '%'
            OR COALESCE(pat."PhoneNumber", '') LIKE '%' || COALESCE(v_searchtxt, '') || '%'
          )
        )
        OR (
          COALESCE(v_searchusinghospitalno, FALSE) = TRUE
          AND pat."PatientCode" = COALESCE(v_searchtxt, pat."PatientCode")
        )
      )
    ORDER BY pat."PatientId" DESC
    LIMIT v_rowcounts;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;
