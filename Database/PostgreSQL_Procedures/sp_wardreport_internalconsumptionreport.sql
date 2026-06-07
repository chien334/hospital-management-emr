CREATE OR REPLACE FUNCTION sp_wardreport_internalconsumptionreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "ConsumedDate" TIMESTAMP,
    "DepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "ConsumedBy" VARCHAR,
    "Quantity" INT
) AS $$
BEGIN
    /*
    filename: "sp_wardreport_internalconsumptionreport"
    createdby/date: rajib/02-10-2020
    description: to get the internal consumption details of items from different ward 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rajib/2/18/2020							update storeid
    2.		rajib/2/26/2020							update consumptionitemid
    */
    
    BEGIN
      IF ((p_fromdate IS NOT NULL) AND (p_todate IS NOT NULL) AND (p_storeid IS NOT NULL))
    		THEN
    			RETURN QUERY SELECT 
    			    (consum."CreatedOn")::date::timestamp AS "ConsumedDate", 
    			    depitm."DepartmentName"::VARCHAR,
    			    consumitem."ItemName"::VARCHAR, 
    			    consum."ConsumedBy"::VARCHAR, 
    			    consumitem."Quantity"::INT AS "Quantity" 
    			FROM "WARD_InternalConsumption" AS consum 
    			JOIN "WARD_InternalConsumptionItems" AS consumitem ON consum."ConsumptionId" = consumitem."ConsumptionId"
    			JOIN "MST_Department" AS depitm ON consum."DepartmentId" = depitm."DepartmentId"
    			WHERE consum."SubStoreId" = p_storeid 
    			  AND (consum."CreatedOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE
    			GROUP BY 
    			    (consum."CreatedOn")::DATE,
    			    depitm."DepartmentName",
    			    consumitem."ItemName",
    			    consum."ConsumedBy",
    			    consumitem."Quantity",
    			    consumitem."ConsumptionItemId";
    		END IF;		
    END;
END;
$$ LANGUAGE plpgsql;