CREATE OR REPLACE FUNCTION sp_wardreport_breakagereport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ItemName" VARCHAR,
    "Quantity" INT,
    "MRP" VARCHAR,
    "TotalAmt" DECIMAL,
    "Remarks" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardreport_breakagereport"
    createdby/date: rusha/03-26-2019
    description: to get the details of breakage items from different ward 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/03-29-2019					   get details of breakage items
    2.		sanjit/02-03-2020						substore integration
    */
    
    BEGIN
      IF ((p_fromdate IS NOT NULL) AND (p_todate IS NOT NULL) AND (p_storeid IS NOT NULL))
    		THEN
    			RETURN QUERY SELECT 
    			    (transc."CreatedOn")::date::timestamp AS "Date", 
    			    itm."ItemName"::VARCHAR, 
    			    transc."Quantity"::INT,
    			    stk."MRP"::VARCHAR,
    			    ROUND((stk."MRP" * transc."Quantity")::numeric, 2)::DECIMAL AS "TotalAmt",
    			    transc."Remarks"::VARCHAR 
    			FROM "WARD_Transaction" AS transc
    			JOIN "PHRM_MST_Item" AS itm ON transc."ItemId" = itm."ItemId"
    			JOIN "WARD_Stock" AS stk ON transc."StockId" = stk."StockId" AND transc."ItemId" = stk."ItemId" 
    			WHERE transc."StoreId" = p_storeid 
    			  AND transc."TransactionType" = 'BreakageItem' 
    			  AND (transc."CreatedOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE
    			GROUP BY 
    			    (transc."CreatedOn")::DATE, 
    			    itm."ItemName", 
    			    transc."Quantity",
    			    transc."Remarks",
    			    stk."MRP",
    			    transc."CreatedOn";
    		END IF;	
    END;
END;
$$ LANGUAGE plpgsql;