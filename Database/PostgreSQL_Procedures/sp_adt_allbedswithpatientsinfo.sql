DROP FUNCTION IF EXISTS sp_adt_allbedswithpatientsinfo();

CREATE OR REPLACE FUNCTION sp_adt_allbedswithpatientsinfo()
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor;
BEGIN
    OPEN ref FOR
    SELECT 
        W."WardID" AS "WardId", 
        W."WardName", 
        B."BedID", 
        B."BedNumber",
        B."BedCode", 
        F."BedFeatureName",
        F."BedPrice",
        B."IsOccupied", 
        B."IsReserved",
        patAdm."PatientId", 
        patAdm."PatientName", 
        patAdm."Gender", 
        CAST(patAdm."DateOfBirth" AS VARCHAR) AS "PatientDob",
        patAdm."AdmissionDate" AS "AdmissionDate",
        patAdm."PatientVisitId", 
        patAdm."VisitCode"
    FROM "ADT_Bed" B 
    INNER JOIN "ADT_MST_Ward" W ON B."WardId" = W."WardID" AND W."IsActive" = TRUE
    INNER JOIN "ADT_MAP_BedFeaturesMap" Map ON Map."BedId" = B."BedID"
    INNER JOIN "ADT_MST_BedFeature" F ON F."BedFeatureId" = Map."BedFeatureId"
    LEFT JOIN (
        SELECT  
            adm."PatientId", 
            pat."ShortName" AS "PatientName",
            adm."PatientVisitId",
            visit."VisitCode",
            pat."DateOfBirth", 
            pat."Gender",
            ward."WardName",  
            bed."BedID",  
            bed."BedCode", 
            bed."BedNumber", 
            adm."AdmissionDate"
        FROM "ADT_PatientAdmission" adm
        INNER JOIN "PAT_PatientVisits" visit ON adm."PatientVisitId" = visit."PatientVisitId"
        INNER JOIN "ADT_TXN_PatientBedInfo" bedInfo ON adm."PatientVisitId" = bedInfo."PatientVisitId"
        INNER JOIN "ADT_MST_Ward" ward ON bedInfo."WardId" = ward."WardID"
        INNER JOIN "ADT_Bed" bed ON bedInfo."BedId" = bed."BedID"
        INNER JOIN "PAT_Patient" pat ON adm."PatientId" = pat."PatientId"
        WHERE bedInfo."IsActive" = TRUE 
          AND bedInfo."OutAction" IS NULL
          AND adm."AdmissionStatus" = 'admitted'
    ) patadm ON B."BedID" = patadm."BedID"
    WHERE B."IsActive" = TRUE
    ORDER BY B."BedNumber";

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;