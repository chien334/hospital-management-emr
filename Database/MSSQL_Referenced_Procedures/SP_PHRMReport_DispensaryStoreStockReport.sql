CREATE PROCEDURE [dbo].[SP_PHRMReport_DispensaryStoreStockReport] @Status VARCHAR(200) = NULL
AS
/*
FileName: [SP_PHRMReport_DispensaryStoreStockReport]
CreatedBy/date: Rusha/2019-04-10
Description: To get the Stock Value of both dispensary and store wise
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.       Rusha/06-11-2019						updated script for dispensary and store stock item
2.		 Naveed/13-12-2019						updated script for exclude zero quantity Items from Report
3.       Sanjit/11-06-2021                      updated script to handle stock redesign. script uses same table for dispensary and store
4.       Rohit/13Feb'23						    MRP-> SalePrice
*/
BEGIN
	SELECT I.ItemName
		,S.BatchNo
		,S.ExpiryDate
		,S.SalePrice
		,SUM(SS.AvailableQuantity) StockQty
		,STR.Name StoreName
	FROM PHRM_TXN_StoreStock SS
	INNER JOIN PHRM_MST_Stock S ON SS.StockId = S.StockId
	INNER JOIN PHRM_MST_Item I ON SS.ItemId = I.ItemId
	INNER JOIN PHRM_MST_Store STR ON SS.StoreId = STR.StoreId
	WHERE SS.AvailableQuantity > 0
		AND (
			@Status = 'all'
			OR (
				@Status = 'store'
				AND STR.Category = 'store'
				)
			OR (
				@Status = 'dispensary'
				AND STR.Category = 'dispensary'
				)
			)
	GROUP BY SS.ItemId
		,I.ItemName
		,S.BatchNo
		,S.ExpiryDate
		,S.SalePrice
		,STR.Name
END