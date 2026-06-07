CREATE OR REPLACE FUNCTION sp_wardreport_requisitionreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "RequisitionId" INT,
    "DispatchId" INT,
    "RequestedDate" TIMESTAMP,
    "DispatchDate" TIMESTAMP,
    "ItemName" VARCHAR,
    "RequestedQty" INT,
    "DispatchQty" INT,
    "MRP" VARCHAR,
    "TotalAmt" DECIMAL,
    "RequestedByUser" VARCHAR,
    "DispatchedByUser" VARCHAR,
    "ReceivedBy" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardreport_requisitionreport"
    createdby/date: rusha/03-26-2019
    description: to get the requsition and dispatch details of stock such as wardname, itemname, batchno, requestedqty, mrp of each item selected by user 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/03-26-2019					   get stock details of requisition and dispatch of item from different ward
    2.		sanjit/01-09-2020					   added requested by user and dispatched by user and receivedby user.
    3.		sanjit/03-20-2020					   substore integration
    */
    
    BEGIN
      IF ((p_fromdate IS NOT NULL) AND (p_todate IS NOT NULL))
    		THEN
    			RETURN QUERY SELECT 
    			    req."RequisitionId"::INT,
    			    disp."DispatchId"::INT,
    			    (req."CreatedOn")::date::timestamp AS "RequestedDate",
    			    (dispitm."CreatedOn")::date::timestamp AS "DispatchDate", 
    			    itm."ItemName"::VARCHAR,
    			    SUM(reqitm."Quantity")::INT AS "RequestedQty",
    			    SUM(dispitm."Quantity")::INT AS "DispatchQty",
    			    dispitm."MRP"::VARCHAR, 
    			    ROUND(SUM(dispitm."Quantity") * COALESCE(dispitm."MRP", 0), 2)::DECIMAL AS "TotalAmt",
    			    (SELECT "FullName"::VARCHAR FROM "EMP_Employee" AS emp1 WHERE emp1."EmployeeId" = req."CreatedBy") AS "RequestedByUser",
    			    (SELECT "FullName"::VARCHAR FROM "EMP_Employee" AS emp2 WHERE emp2."EmployeeId" = dispitm."CreatedBy") AS "DispatchedByUser",
    			    disp."ReceivedBy"::VARCHAR AS "ReceivedBy"
    			FROM "WARD_Requisition" AS req
    			JOIN "WARD_RequisitionItems" AS reqitm ON req."RequisitionId" = reqitm."RequisitionId"
    			JOIN "PHRM_MST_Item" AS itm ON reqitm."ItemId" = itm."ItemId"
    			LEFT JOIN "WARD_Dispatch" AS disp ON req."RequisitionId" = disp."RequisitionId" AND req."StoreId" = disp."StoreId"
    			LEFT JOIN "WARD_DispatchItems" AS dispitm ON reqitm."RequisitionItemId" = dispitm."RequisitionItemId" AND disp."DispatchId" = dispitm."DispatchId"
    			WHERE req."StoreId" = p_storeid 
    			  AND (req."CreatedOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE
    			GROUP BY 
    			    req."CreatedOn",
    			    dispitm."CreatedOn",
    			    reqitm."Quantity",
    			    itm."ItemName", 
    			    dispitm."MRP", 
    			    dispitm."Quantity",
    			    req."CreatedBy",
    			    dispitm."CreatedBy",
    			    req."RequisitionId",
    			    disp."DispatchId",
    			    disp."ReceivedBy",
    			    dispitm."DispatchItemId";
    		END IF;		
    END;
END;
$$ LANGUAGE plpgsql;