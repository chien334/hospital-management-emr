CREATE OR REPLACE FUNCTION sp_bedinformation()
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'ref1';
    ref2 refcursor := 'ref2';
BEGIN
    -- Table 1: Bed Counts (Total, Available, Occupied)
    OPEN ref1 FOR
    SELECT 
        (SELECT COUNT(DISTINCT b."BedID") FROM "ADT_Bed" b 
         INNER JOIN "ADT_MAP_BedFeaturesMap" Map ON Map."BedId" = b."BedID" AND b."IsActive" = TRUE
         INNER JOIN "ADT_MST_Ward" ward ON ward."WardID" = Map."WardId" AND ward."IsActive" = TRUE
         INNER JOIN "ADT_MST_BedFeature" bf ON Map."BedFeatureId" = bf."BedFeatureId" AND bf."IsActive" = TRUE) AS "Total",
         
        (SELECT COUNT(DISTINCT b."BedID") FROM "ADT_Bed" b
         INNER JOIN "ADT_MAP_BedFeaturesMap" Map ON Map."BedId" = b."BedID" AND b."IsActive" = TRUE
         INNER JOIN "ADT_MST_Ward" ward ON ward."WardID" = Map."WardId" AND ward."IsActive" = TRUE
         INNER JOIN "ADT_MST_BedFeature" bf ON Map."BedFeatureId" = bf."BedFeatureId" AND bf."IsActive" = TRUE AND b."IsOccupied" = FALSE) AS "Available",
         
        (SELECT COUNT(DISTINCT b."BedID") FROM "ADT_Bed" b 
         INNER JOIN "ADT_MAP_BedFeaturesMap" Map ON Map."BedId" = b."BedID" AND b."IsActive" = TRUE
         INNER JOIN "ADT_MST_Ward" ward ON ward."WardID" = Map."WardId" AND ward."IsActive" = TRUE
         INNER JOIN "ADT_MST_BedFeature" bf ON Map."BedFeatureId" = bf."BedFeatureId" AND bf."IsActive" = TRUE AND b."IsOccupied" = TRUE) AS "Occupied";
    RETURN NEXT ref1;

    -- Table 2: Bed Details
    OPEN ref2 FOR
    SELECT 
        B."BedNumber" AS "BedNumber",
        F."BedFeatureName" AS "BedFeatureName",
        F."BedPrice" AS "BedPrice",
        B."IsOccupied" AS "IsOccupied",
        W."WardName" AS "WardName"
    FROM "ADT_Bed" B 
    INNER JOIN "ADT_MST_Ward" W ON B."WardId" = W."WardID" AND W."IsActive" = TRUE
    INNER JOIN "ADT_MAP_BedFeaturesMap" Map ON Map."BedId" = B."BedID"
    INNER JOIN "ADT_MST_BedFeature" F ON F."BedFeatureId" = Map."BedFeatureId";
    RETURN NEXT ref2;
END;
$$ LANGUAGE plpgsql;
