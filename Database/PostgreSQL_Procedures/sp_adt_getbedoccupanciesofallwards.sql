DROP FUNCTION IF EXISTS sp_adt_getbedoccupanciesofallwards();

CREATE OR REPLACE FUNCTION sp_adt_getbedoccupanciesofallwards()
RETURNS TABLE (
    "WardName" VARCHAR,
    "WardId" INT,
    "Occupied" INT,
    "Vacant" INT,
    "Reserved" INT,
    "Total" INT
) AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        x.wardname::VARCHAR AS "WardName",
        x.wardid::INT AS "WardId",
        x.occupied::INT AS "Occupied",
        x.vacant::INT AS "Vacant",
        x.reserved::INT AS "Reserved",
        (x.occupied + x.vacant + x.reserved)::INT AS "Total"  
    FROM 
    (	
        SELECT  
            y.wardid,
            y.wardname,
            COUNT(CASE WHEN y.isoccupied = TRUE AND y.bdia = TRUE AND y.wia = TRUE AND y.bfia = TRUE THEN 1 END)::INT AS occupied,
            COUNT(CASE WHEN y.isoccupied = FALSE AND y.bdia = TRUE AND y.wia = TRUE AND y.bfia = TRUE THEN 1 END)::INT AS vacant,
            0::INT AS reserved
        FROM (
            SELECT DISTINCT 
                bd."BedID" AS bedid,
                bd."BedCode" AS bedcode, 
                ward."WardID" AS wardid,
                bd."IsOccupied" AS isoccupied,
                ward."WardName" AS wardname,
                bd."IsActive" AS bdia,
                ward."IsActive" AS wia,
                bf."IsActive" AS bfia 
            FROM "ADT_Bed" bd		 
            INNER JOIN "ADT_MAP_BedFeaturesMap" map ON map."BedId" = bd."BedID"
            INNER JOIN "ADT_MST_Ward" ward ON ward."WardID" = map."WardId" 	
            INNER JOIN "ADT_MST_BedFeature" bf ON map."BedFeatureId" = bf."BedFeatureId"
            WHERE ward."IsActive" = TRUE
        ) AS y 
        GROUP BY y.wardname, y.wardid
    ) AS x	
    ORDER BY x.wardname;
END;
$$ LANGUAGE plpgsql;