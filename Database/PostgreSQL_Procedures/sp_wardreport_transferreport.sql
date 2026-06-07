CREATE OR REPLACE FUNCTION sp_wardreport_transferreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL,
    p_status INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ItemName" VARCHAR,
    "TransferQty" INT,
    "Remarks" VARCHAR,
    "TransferedBy" VARCHAR,
    "ReceivedBy" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardreport_transferreport"
    createdby/date: rusha/03-26-2019
    description: to get the details of report of ward to ward tranfer and ward to pharmacy trannsfer of stock 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/03-29-2019						shows report of ward to ward transfer and ward to pharmacy transfer
    2.		sanjit/01-09-2020						added received by field in both transfer cases.
    3.		sanjit/05-22-2020						corrected date format
    */
    
    BEGIN
      IF ((p_fromdate IS NOT NULL) AND (p_todate IS NOT NULL)) 
    		THEN
    			 RETURN QUERY SELECT 
    			    (transc."CreatedOn")::date::timestamp AS "Date",
    			    itm."ItemName"::VARCHAR, 
    			    transc."Quantity"::INT AS "TransferQty",
    			    transc."Remarks"::VARCHAR,
    			    transc."CreatedBy"::VARCHAR AS "TransferedBy",
    			    transc."ReceivedBy"::VARCHAR AS "ReceivedBy" 
    			FROM "WARD_Transaction" AS transc
    			JOIN "PHRM_MST_Item" AS itm ON transc."ItemId" = itm."ItemId"
    			WHERE transc."StoreId" = p_storeid 
    			  AND transc."TransactionType" = 'WardToPharmacy' 
    			  AND (transc."CreatedOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE
    			GROUP BY 
    			    itm."ItemName", 
    			    transc."Quantity",
    			    transc."Remarks",
    			    transc."CreatedOn",
    			    transc."CreatedBy",
    			    transc."ReceivedBy";
    		END IF;	
    END;
END;
$$ LANGUAGE plpgsql;