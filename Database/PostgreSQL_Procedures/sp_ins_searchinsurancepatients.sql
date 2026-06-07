DROP FUNCTION IF EXISTS sp_ins_searchinsurancepatients(CHARACTER VARYING, INTEGER);

CREATE OR REPLACE FUNCTION sp_ins_searchinsurancepatients(
    p_searchtxt VARCHAR DEFAULT NULL,
    p_rowcounts INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor;
    v_insproviderid INT;
BEGIN
    p_rowcounts := COALESCE(p_rowcounts, 200); -- default rowscount=200
    
    IF p_searchtxt = 'null' THEN
        p_searchtxt := NULL;
    END IF;
    
    v_insproviderid := (
        SELECT "InsuranceProviderId" 
        FROM "INS_CFG_InsuranceProviders"
        WHERE LOWER("InsuranceProviderName") = 'government insurance'
        LIMIT 1
    );

    OPEN ref FOR
    SELECT 
        pat."PatientId",
        pat."PatientCode",
        pat."ShortName",
        pat."FirstName",
        pat."LastName",
        pat."MiddleName",
        pat."PatientNameLocal",
        pat."Age",
        pat."Gender",
        pat."PhoneNumber",
        pat."DateOfBirth",
        pat."Address",
        pat."IsOutdoorPat",
        pat."CreatedOn",
        pat."CountryId",
        cntry."CountryName",
        pat."CountrySubDivisionId",
        sub."CountrySubDivisionName",
        pat."MunicipalityId",
        munc."MunicipalityName",  
        pat."MembershipTypeId",
        memb."MembershipTypeName",
        memb."DiscountPercent" AS "MembershipDiscountPercent",
        pat."PANNumber",
        pat."BloodGroup", 
        pat."Ins_HasInsurance"::VARCHAR,
        pat."Ins_NshiNumber",
        pat."Ins_InsuranceBalance",
        pat."Ins_LatestClaimCode" AS "LatestClaimCode",
        CASE 
            WHEN adm."PatientId" IS NOT NULL THEN 1
            ELSE 0 
        END AS "IsAdmitted",
        v_insproviderid AS "InsuranceProviderId"
    FROM "PAT_Patient" pat
    INNER JOIN "MST_Country" cntry ON pat."CountryId" = cntry."CountryId"
    INNER JOIN "MST_CountrySubDivision" sub ON pat."CountrySubDivisionId" = sub."CountrySubDivisionId"
    INNER JOIN "PAT_CFG_MembershipType" memb ON pat."MembershipTypeId" = memb."MembershipTypeId"
    LEFT JOIN (
        SELECT DISTINCT "PatientId" 
        FROM "ADT_PatientAdmission"
        WHERE "AdmissionStatus" = 'admitted'
    ) adm ON pat."PatientId" = adm."PatientId"
    LEFT JOIN "MST_Municipality" munc ON pat."MunicipalityId" = munc."MunicipalityId"
    WHERE pat."IsActive" = TRUE 
      AND pat."Ins_HasInsurance" = TRUE -- In PostgreSQL, Ins_HasInsurance is a boolean column
      AND (
          COALESCE(pat."Ins_NshiNumber", '') LIKE '%' || COALESCE(p_searchtxt, '') || '%'
          OR pat."PatientCode" LIKE '%' || COALESCE(p_searchtxt, '') || '%'
          OR pat."ShortName" LIKE '%' || COALESCE(p_searchtxt, '') || '%'  
          OR COALESCE(pat."PhoneNumber", '') LIKE '%' || COALESCE(p_searchtxt, '') || '%'
      )
    ORDER BY pat."PatientId" DESC
    LIMIT p_rowcounts;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;