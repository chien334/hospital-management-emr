CREATE PROCEDURE [dbo].[SP_InventoryOverAllStockList]
@StoreId INT =NULL

AS
/*
FileName: SP_InventoryOverAllStockList 
CreatedBy/date: Rohit/2022-06-10
Description: SP to get overall stock for Inventory by StoreId.(Used: Inventory->Stock->List)
Remarks: Getting total Available Quantity at ItemLevel. Batch,Expiry,Cost etc seperation is not there.
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Rohit/2022-06-10                   Created initial script
2		 Rohit/2022-07-29					Round Off the available quantity
*/
BEGIN
    SELECT mstItem.ItemId
	,mstItem.ItemCategoryId
	,mstItem.ItemName
	,ss.AvailableQuantity as 'AvailQuantity'
    ,ss.StoreId
	,mstItem.MinStockQuantity 'MinQuantity'
	,mstItem.Code 'ItemCode'
	,mstItem.ItemType
	,mstItem.IsColdStorageApplicable
	,sub.SubCategoryName
	,unit.UOMId
	,unit.UOMName
	,mstItem.IsFixedAssets
FROM INV_MST_Item mstItem
INNER JOIN (
	SELECT ItemId
        ,StoreId
		,Round(SUM(AvailableQuantity),4) 'AvailableQuantity'
	FROM INV_TXN_StoreStock
	GROUP BY ItemId,StoreId
	) ss ON ss.ItemId = mstItem.ItemId
INNER JOIN INV_MST_ItemSubCategory sub ON sub.SubCategoryId = mstItem.SubCategoryId
INNER JOIN INV_MST_UnitOfMeasurement unit ON unit.UOMId = mstItem.UnitOfMeasurementId
WHERE ss.StoreId=@StoreId
ORDER BY mstItem.ItemName
END