DROP FUNCTION IF EXISTS sp_bedinformation();

CREATE OR REPLACE FUNCTION sp_bedinformation()
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    OPEN ref1 FOR 
    SELECT * FROM 
    	(
            SELECT COUNT(DISTINCT b."BedID") AS "total" 
            FROM "ADT_Bed" b 
            INNER JOIN "ADT_MAP_BedFeaturesMap" map ON map."BedId" = b."BedID" AND b."IsActive" = TRUE
            INNER JOIN "ADT_MST_Ward" ward ON ward."WardID" = map."WardId" AND ward."IsActive" = TRUE
            INNER JOIN "ADT_MST_BedFeature" bf ON map."BedFeatureId" = bf."BedFeatureId" AND bf."IsActive" = TRUE
        ) AS total,
    	(
            SELECT COUNT(DISTINCT b."BedID") AS "available" 
            FROM "ADT_Bed" b
            INNER JOIN "ADT_MAP_BedFeaturesMap" map ON map."BedId" = b."BedID" AND b."IsActive" = TRUE
            INNER JOIN "ADT_MST_Ward" ward ON ward."WardID" = map."WardId" AND ward."IsActive" = TRUE
            INNER JOIN "ADT_MST_BedFeature" bf ON map."BedFeatureId" = bf."BedFeatureId" AND bf."IsActive" = TRUE AND b."IsOccupied" = FALSE
        ) AS available,
    	(
            SELECT COUNT(DISTINCT b."BedID") AS "occupied" 
            FROM "ADT_Bed" b 
            INNER JOIN "ADT_MAP_BedFeaturesMap" map ON map."BedId" = b."BedID" AND b."IsActive" = TRUE
            INNER JOIN "ADT_MST_Ward" ward ON ward."WardID" = map."WardId" AND ward."IsActive" = TRUE
            INNER JOIN "ADT_MST_BedFeature" bf ON map."BedFeatureId" = bf."BedFeatureId" AND bf."IsActive" = TRUE AND b."IsOccupied" = TRUE
        ) AS occupied;
        
    RETURN NEXT ref1;
    
    OPEN ref2 FOR 
    SELECT 
        b."BedNumber",
        f."BedFeatureName",
        f."BedPrice",
        b."IsOccupied",
        w."WardName" 
    FROM "ADT_Bed" b 
    INNER JOIN "ADT_MST_Ward" w ON b."WardId" = W."WardID" AND w."IsActive" = TRUE
    INNER JOIN "ADT_MAP_BedFeaturesMap" map ON map."BedId" = b."BedID"
    INNER JOIN "ADT_MST_BedFeature" f ON f."BedFeatureId" = map."BedFeatureId";
    
    RETURN NEXT ref2;
END;
$$ LANGUAGE plpgsql;