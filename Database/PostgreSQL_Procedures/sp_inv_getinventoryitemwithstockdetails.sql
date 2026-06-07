CREATE OR REPLACE FUNCTION sp_inv_getinventoryitemwithstockdetails(

)
RETURNS TABLE (
    "ItemId" INT,
    "ItemName" VARCHAR,
    "Code" VARCHAR,
    "BatchNo" VARCHAR,
    "UOMName" VARCHAR,
    "ItemCategory" VARCHAR,
    "IsFixedAssets" BOOLEAN,
    "ItemType" VARCHAR,
    "Description" VARCHAR,
    "StoreId" INT,
    "AvailableQuantity" INT
) AS $$
BEGIN
    /*  
    filename: "sp_inv_getinventorystock"  
    createdby/date: rohit/6jul'23
    Description: To get inventory item with stock details
    Remarks:      
    Change History  
    S.No.    UpdatedBy/Date               Remarks  
    1.       Rohit/6Jul'23               initial script
    */
    
    RETURN QUERY SELECT 
        item."ItemId",
        item."ItemName",
        item."Code",
        stk."BatchNo",
        uom."UOMName",
        itemcat."ItemCategoryName" AS "ItemCategory",
        item."IsFixedAssets",
        item."ItemType",
        item."Description",
        strstk."StoreId",
        SUM(COALESCE(strstk."AvailableQuantity", 0))::INT AS "AvailableQuantity"
    FROM "INV_MST_Item" item
    INNER JOIN "INV_MST_ItemCategory" itemcat ON item."ItemCategoryId" = itemcat."ItemCategoryId"
    INNER JOIN "INV_MST_UnitOfMeasurement" uom ON item."UnitOfMeasurementId" = uom."UOMId"
    LEFT JOIN "INV_TXN_StoreStock" strstk ON item."ItemId" = strstk."ItemId"
    LEFT JOIN "INV_MST_Stock" stk ON strstk."StockId" = stk."StockId"
    WHERE item."IsActive" = TRUE
    GROUP BY 
        item."ItemId",
        item."ItemName",
        item."Code",
        stk."BatchNo",
        uom."UOMName",
        itemcat."ItemCategoryName",
        item."IsFixedAssets",
        item."ItemType",
        item."Description",
        strstk."StoreId";
END;
$$ LANGUAGE plpgsql;