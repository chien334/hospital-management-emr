CREATE OR REPLACE FUNCTION sp_wardinv_report_requisitiondispatchreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "RequisitionDate" TIMESTAMP,
    "DispatchDate" TIMESTAMP,
    "ItemName" VARCHAR,
    "SubCategoryName" VARCHAR,
    "SubCategoryId" INT,
    "RequestQty" INT,
    "ReceivedQuantity" INT,
    "PendingQuantity" INT,
    "DispatchedQuantity" INT,
    "Remark" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardinv_report_requisitiondispatchreport"
    createdby/date: rusha/06-04-2019
    description: to get stock details of requisition and dispatch from ward to inventory
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.
    2.		rohit/10oct'22							StoreId change to RequestFromStoreId and Join condition Fixed
    3.		Rohit/31Oct'22							requisitiondate and dispatcheddate fetched instead of createdon
    4.		rohit/6dec'22							subcategoryname and subcategory fetched to add frontend filter
    */
    
    RETURN QUERY SELECT 
        (req."RequisitionDate")::date::timestamp AS "RequisitionDate",
        (disitm."DispatchedDate")::date::timestamp AS "DispatchDate",
        itm."ItemName",
        sc."SubCategoryName",
        sc."SubCategoryId",
        COALESCE(reqitm."Quantity", 0)::INT AS "RequestQty",
        COALESCE(reqitm."ReceivedQuantity", 0)::INT AS "ReceivedQuantity",
        COALESCE(reqitm."PendingQuantity", 0)::INT AS "PendingQuantity",
        COALESCE(disitm."DispatchedQuantity", 0)::INT AS "DispatchedQuantity",
        reqitm."Remark"
    FROM "INV_TXN_RequisitionItems" AS reqitm
    JOIN "INV_TXN_Requisition" AS req ON req."RequisitionId" = reqitm."RequisitionId"
    LEFT JOIN "INV_TXN_DispatchItems" AS disitm ON disitm."RequisitionItemId" = reqitm."RequisitionItemId"
    JOIN "INV_MST_Item" AS itm ON itm."ItemId" = reqitm."ItemId"
    INNER JOIN "INV_MST_ItemSubCategory" sc ON itm."SubCategoryId" = sc."SubCategoryId"
    WHERE req."RequestFromStoreId" = p_storeid
      AND (req."RequisitionDate")::date BETWEEN (p_fromdate)::date AND (p_todate)::date;
END;
$$ LANGUAGE plpgsql;