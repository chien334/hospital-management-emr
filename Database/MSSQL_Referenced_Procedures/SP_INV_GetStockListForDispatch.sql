CREATE PROCEDURE SP_INV_GetStockListForDispatch
 @StoreId INT =NULL
 AS
 /*
FileName: [SP_INV_GetStockListForDispatch]
CreatedBy/date: Rohit/7May'23
Description: To get the inventory stock list by StoreId to dispatch
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rohit/7May'23                        created the script
*/
BEGIN
SELECT 
    SS.ItemId AS ItemId, 
    I.ItemName AS ItemName, 
    I.Description AS Description, 
    C.ItemCategoryName AS ItemCategory, 
    I.Code AS ItemCode, 
    ISNULL(U.UOMName, 'N/A') AS ItemUOM, 
    SSM.BatchNo AS BatchNo, 
    SUM(SS.AvailableQuantity) AS AvailableQuantity, 
    SSM.CostPrice AS CostPrice, 
    I.IsFixedAssets AS IsFixedAsset, 
    (
        SELECT 
            FAS.BarCodeNumber AS BarCodeNumber, 
            FAS.FixedAssetStockId AS StockId
        FROM 
            INV_TXN_FixedAssetStock AS FAS 
        WHERE 
            FAS.ItemId = SS.ItemId 
            AND FAS.IsActive = 1 
            AND FAS.StoreId = @StoreId 
            AND FAS.SubStoreId IS NULL 
        FOR JSON PATH
    ) AS BarCodeList
FROM 
    INV_TXN_StoreStock AS SS
    INNER JOIN INV_MST_Stock AS SSM ON SS.StockId = SSM.StockId
    INNER JOIN INV_MST_Item AS I ON SS.ItemId = I.ItemId 
    INNER JOIN INV_MST_ItemCategory AS C ON I.ItemCategoryId = C.ItemCategoryId
    LEFT JOIN INV_MST_UnitOfMeasurement AS U ON I.UnitOfMeasurementId = U.UOMId 
WHERE 
    SS.StoreId = @StoreId 
    AND SS.IsActive = 1 
    AND SS.AvailableQuantity > 0 
GROUP BY 
    SS.ItemId, 
    SSM.BatchNo, 
    C.ItemCategoryName, 
    I.IsFixedAssets,
    I.ItemName, 
    I.Description, 
    I.Code, 
    U.UOMName, 
    SSM.CostPrice
END