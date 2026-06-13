CREATE OR REPLACE FUNCTION sp_pat_registeredpatientlist(
    p_searchtxt VARCHAR DEFAULT NULL,
    p_rowcounts INT DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "ShortName" VARCHAR,
    "FirstName" VARCHAR,
    "LastName" VARCHAR,
    "MiddleName" VARCHAR,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "PhoneNumber" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Address" VARCHAR,
    "IsOutdoorPat" BOOLEAN,
    "CreatedOn" TIMESTAMP,
    "WardNumber" VARCHAR
) AS $$
BEGIN
    if (p_searchtxt = 'null') then 
        p_searchtxt := null; 
    end if; 
    p_rowcounts := coalesce(p_rowcounts, 200); --default rowscount=200

    RETURN QUERY SELECT  
        pat."PatientId", 
        pat."PatientCode", 
        pat."ShortName", 
        pat."FirstName", 
        pat."LastName", 
        pat."MiddleName", 
        pat."Age", 
        pat."Gender", 
        pat."PhoneNumber", 
        pat."DateOfBirth", 
        (coalesce(pat."Address",'') || ' ' || coalesce(mun."MunicipalityName",'') || ' ' || coalesce(district."CountrySubDivisionName",''))::VARCHAR AS "Address", 
        pat."IsOutdoorPat", 
        pat."CreatedOn",
        pat."WardNumber"::VARCHAR AS "WardNumber"
    FROM 
        "PAT_Patient" pat 
        LEFT JOIN "MST_CountrySubDivision" district ON pat."CountrySubDivisionId" = district."CountrySubDivisionId"
        LEFT JOIN "MST_Municipality" mun ON pat."MunicipalityId" = mun."MunicipalityId"
    WHERE 
        pat."IsActive" = true 
        AND (
            pat."PatientCode" ILIKE '%' || coalesce(p_searchtxt, '') || '%' 
            OR pat."ShortName" ILIKE '%' || coalesce(p_searchtxt, '') || '%' 
            OR coalesce(pat."PhoneNumber", '') ILIKE '%' || coalesce(p_searchtxt, '') || '%'
        ) 
    ORDER BY 
        pat."PatientId" DESC 
    LIMIT p_rowcounts;
END;
$$ LANGUAGE plpgsql;