CREATE OR REPLACE FUNCTION sp_wardreport_stockreport(
    p_itemid INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    filename: "sp_wardreport_stockreport"
    createdby/date: rusha/03-24-2019
    description: to get the stock details such as itemname, batchno, availableqty of each item selected by user 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/03-24-2019					   shows stock details by item wise
    2.		sanjit/02-03-2020					   substore integration
    */
    
    BEGIN
      IF (p_itemid != 0)
    		THEN
    			OPEN ref1 FOR SELECT 
    			    gen."GenericName"::VARCHAR,
    			    itm."ItemName"::VARCHAR,
    			    ward."BatchNo"::VARCHAR,
    			    SUM(ward."AvailableQuantity")::INT AS "quantity",
    			    ward."ExpiryDate"::TIMESTAMP, 
    			    ward."MRP"::DECIMAL 
    			FROM "WARD_Stock" AS ward 
    			JOIN "PHRM_MST_Item" AS itm ON ward."ItemId" = itm."ItemId" 
    			JOIN "PHRM_MST_Generic" AS gen ON itm."GenericId" = gen."GenericId"  
    			WHERE itm."ItemId" = p_itemid 
    			  AND ward."StoreId" = p_storeid
    			GROUP BY 
    			    itm."ItemName", 
    			    ward."MRP", 
    			    gen."GenericName", 
    			    ward."BatchNo", 
    			    ward."ExpiryDate";
                RETURN NEXT ref1;
    			
    		ELSIF (p_itemid = 0)	
    		THEN 
    		    OPEN ref2 FOR SELECT 
    		        gen."GenericName"::VARCHAR,
    		        itm."ItemName"::VARCHAR,
    		        ward."BatchNo"::VARCHAR,
    		        SUM(ward."AvailableQuantity")::INT AS "quantity",
    		        ward."ExpiryDate"::TIMESTAMP, 
    		        ward."MRP"::DECIMAL 
    		    FROM "WARD_Stock" AS ward 
    			JOIN "PHRM_MST_Item" AS itm ON ward."ItemId" = itm."ItemId" 
    			JOIN "PHRM_MST_Generic" AS gen ON itm."GenericId" = gen."GenericId"
    			WHERE ward."StoreId" = p_storeid
    			GROUP BY 
    			    itm."ItemName", 
    			    ward."MRP", 
    			    gen."GenericName", 
    			    ward."BatchNo", 
    			    ward."ExpiryDate";
                RETURN NEXT ref2;
    		END IF;
    END;
END;
$$ LANGUAGE plpgsql;