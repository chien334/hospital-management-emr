CREATE OR REPLACE FUNCTION sp_inventoryoverallstocklist(
    p_storeid integer DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
BEGIN
    OPEN ref FOR
    SELECT mstItem."ItemId"
        ,mstItem."ItemCategoryId"
        ,mstItem."ItemName"
        ,ss."AvailableQuantity" as "AvailQuantity"
        ,ss."StoreId"
        ,mstItem."MinStockQuantity" as "MinQuantity"
        ,mstItem."Code" as "ItemCode"
        ,mstItem."ItemType"
        ,mstItem."IsColdStorageApplicable"
        ,sub."SubCategoryName"
        ,unit."UOMId"
        ,unit."UOMName"
        ,mstItem."IsFixedAssets"
    FROM "INV_MST_Item" mstItem
    INNER JOIN (
        SELECT "ItemId"
            ,"StoreId"
            ,ROUND(SUM("AvailableQuantity")::numeric, 4) as "AvailableQuantity"
        FROM "INV_TXN_StoreStock"
        GROUP BY "ItemId", "StoreId"
    ) ss ON ss."ItemId" = mstItem."ItemId"
    INNER JOIN "INV_MST_ItemSubCategory" sub ON sub."SubCategoryId" = mstItem."SubCategoryId"
    INNER JOIN "INV_MST_UnitOfMeasurement" unit ON unit."UOMId" = mstItem."UnitOfMeasurementId"
    WHERE ss."StoreId" = p_storeid
    ORDER BY mstItem."ItemName";

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;
