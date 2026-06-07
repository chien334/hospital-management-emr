CREATE OR REPLACE FUNCTION sp_wardinv_report_transferreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "DepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "Quantity" INT,
    "Remarks" VARCHAR,
    "CreatedBy" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardinv_report_transferreport"
    createdby/date: rusha/06-05-2019
    description: to get the details of stock transfer from ward to inventory 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    
    */
    
    BEGIN
      IF ((p_fromdate IS NOT NULL) AND (p_todate IS NOT NULL))
    		THEN
    			RETURN QUERY SELECT 
    			    (trans."CreatedOn")::date::timestamp AS "Date",
    			    dep."DepartmentName"::VARCHAR,
    			    itm."ItemName"::VARCHAR,
    			    trans."Quantity"::INT,
    			    trans."Remarks"::VARCHAR, 
    			    trans."CreatedBy"::VARCHAR 
    			FROM "WARD_INV_Transaction" AS trans
    			JOIN "WARD_INV_Stock" AS stk ON stk."StockId" = trans."StockId"
    			JOIN "MST_Department" AS dep ON dep."DepartmentId" = stk."DepartmentId"
    			JOIN "INV_MST_Item" AS itm ON itm."ItemId" = stk."ItemId"		
    			WHERE stk."StoreId" = p_storeid 
    			  AND (trans."CreatedOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE;
    		END IF;	
    END;
END;
$$ LANGUAGE plpgsql;