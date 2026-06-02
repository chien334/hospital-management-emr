CREATE PROCEDURE SP_INV_GetInventoryItemWithStockDetails
AS
/*  
FileName: [SP_INV_GetInventoryStock]  
CreatedBy/date: Rohit/6Jul'23
Description: To get inventory item with stock details
Remarks:      
Change History  
S.No.    UpdatedBy/Date               Remarks  
1.       Rohit/6Jul'23               Initial Script
*/
BEGIN
    SELECT item.ItemId
	,item.ItemName
	,item.Code
	,stk.BatchNo
	,uom.UOMName
	,itemcat.ItemCategoryName 'ItemCategory'
	,item.IsFixedAssets
	,item.ItemType
	,item.Description
	,strstk.StoreId
	,SUM(ISNULL(strstk.AvailableQuantity,0)) 'AvailableQuantity'
FROM INV_MST_Item item
INNER JOIN INV_MST_ItemCategory itemcat ON item.ItemCategoryId = itemcat.ItemCategoryId
INNER JOIN INV_MST_UnitOfMeasurement uom ON item.UnitOfMeasurementId = uom.UOMId
LEFT JOIN INV_TXN_StoreStock strstk ON item.ItemId = strstk.ItemId
LEFT JOIN INV_MST_Stock stk ON strstk.StockId = stk.StockId
where item.IsActive =1
GROUP BY item.ItemId
	,item.ItemName
	,item.Code
	,stk.BatchNo
	,uom.UOMName
	,itemcat.ItemCategoryName
	,item.IsFixedAssets
	,item.ItemType
	,item.Description
	,strstk.StoreId
END