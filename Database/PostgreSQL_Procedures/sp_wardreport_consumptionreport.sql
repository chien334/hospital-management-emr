CREATE OR REPLACE FUNCTION sp_wardreport_consumptionreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ItemName" VARCHAR,
    "GenericName" VARCHAR,
    "Quantity" INT
) AS $$
BEGIN
    /*
    filename: "sp_wardreport_consumptionreport"
    createdby/date: rusha/03-26-2019
    description: to get the consumption details of items from different ward 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/03-29-2019					   add stock details of consumed item from different ward
    2.		sanjit/02-03-2020						substore integration
    3.      rajib/02-26-2020						update invoiceitemid
    */
    
    BEGIN
      IF ((p_fromdate IS NOT NULL) AND (p_todate IS NOT NULL) AND (p_storeid IS NOT NULL))
    		THEN
    			RETURN QUERY SELECT 
    			    (consum."CreatedOn")::date::timestamp AS "Date", 
    			    consum."ItemName"::VARCHAR, 
    			    gene."GenericName"::VARCHAR, 
    			    consum."Quantity"::INT AS "Quantity" 
    			FROM "WARD_Consumption" AS consum 
    			JOIN "PHRM_MST_Item" AS itm ON consum."ItemId" = itm."ItemId"
    			JOIN "PHRM_MST_Generic" AS gene ON itm."GenericId" = gene."GenericId"
    			WHERE consum."StoreId" = p_storeid 
    			  AND (consum."CreatedOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE
    			GROUP BY 
    			    (consum."CreatedOn")::DATE,
    			    consum."ItemName",
    			    consum."Quantity", 
    			    gene."GenericName",
    			    consum."InvoiceItemId";
    		END IF;		
    END;
END;
$$ LANGUAGE plpgsql;