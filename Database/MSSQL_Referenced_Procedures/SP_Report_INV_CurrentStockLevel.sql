CREATE PROCEDURE [dbo].[SP_Report_INV_CurrentStockLevel] 
@StoreIds NVARCHAR(400) = '',
@showZeroQuantity BIT = 1
AS
/*
Execution Example:
	exec SP_Report_INV_CurrentStockLevel @StoreIds='7,8'
	exec SP_Report_INV_CurrentStockLevel @StoreIds='13', @showZeroQuantity = 0
Change History
S.No.    UpdatedBy/Date					Remarks
1		NageshBB/22 Sep 2020			updated script for get subcategory name column
2		NageshBB/08 Dec 2020			updated script for fix wrong storeId get issue resolution when main storeId is not there
3       sanjit/ramesh/rohit/9thSep'21   updated after Inv Stock refactoring
4     Sanjit/Sud:10Jun'22               Removed UNION with FixedAssetTables since we've now taken all stocks in same table.
*/
BEGIN
	SELECT 
		store.StoreId,
		store.Name as StoreName,
		itm.ItemType,
		subCat.SubCategoryName,
		itm.ItemId,
		itm.Code, 
		itm.ItemName,
		SUM(storeStk.AvailableQuantity) as AvailableQuantity,
		SUM(storeStk.AvailableQuantity * stkMaster.CostPrice) as StockValue
	FROM INV_TXN_StoreStock storeStk
		INNER JOIN INV_MST_Stock stkMaster on storeStk.StockId = stkMaster.StockId
		INNER JOIN PHRM_MST_Store store on storeStk.StoreId = store.StoreId
		INNER JOIN INV_MST_Item itm on storeStk.ItemId = itm.ItemId
		INNER JOIN INV_MST_ItemSubCategory subCat on subCat.SubCategoryId = itm.SubCategoryId
	WHERE 
		stkMaster.IsActive = 1 
		AND storeStk.StoreId IN (SELECT value FROM STRING_SPLIT(@StoreIds, ',') WHERE RTRIM(value) <> '')
	GROUP BY
		itm.ItemType,
		subCat.SubCategoryName,
		itm.ItemId,
		itm.Code, 
		itm.ItemName,
		store.StoreId,
		store.Name
	HAVING
		SUM(storeStk.AvailableQuantity) > 0 OR @showZeroQuantity = 1 --to disable quantity filter if showZeroQuantity is true

END