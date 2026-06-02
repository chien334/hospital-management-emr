CREATE PROCEDURE [dbo].[SP_PHRMReport_NarcoticsDispensaryStoreStockReport] @StoreId INT = NULL
AS
/*
FileName: [SP_PHRMReport_NarcoticsDispensaryStoreStockReport]
CreatedBy/date: Ashish/12-02-2020
Description: To get the Stock Value of both dispensary and store wise for Narcotics Stock report
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Sanjit/Ramesh/25Jul21        updated after stock refactoring 
2      Rohit/6thApr22				Added StoreId to Fetch StoreId
3      Rusha/21thJuly22				Added Generic name in column
4      Rohit/13Feb'23				MRP-> SalePrice
*/
BEGIN
	SELECT I.ItemName
		,G.GenericName
		,ISNULL(S.BatchNo, '') AS BatchNo
		,S.ExpiryDate
		,ISNULL(S.CostPrice, 0) CostPrice
		,ISNULL(S.SalePrice, 0) SalePrice
		,SUM(ISNULL(SS.AvailableQuantity, 0)) 'StockQty'
		,STR.Name
		,STR.StoreId
	FROM PHRM_MST_Item I
	LEFT JOIN PHRM_MST_Generic G ON I.GenericId = G.GenericId
	LEFT JOIN PHRM_MST_Stock S ON I.ItemId = S.ItemId
	LEFT JOIN PHRM_TXN_StoreStock SS ON S.StockId = SS.StockId
	LEFT JOIN PHRM_MST_Store STR ON SS.StoreId = STR.StoreId
	WHERE S.IsActive = 1
		AND SS.IsActive = 1
		AND (
			STR.StoreId = @StoreId
			OR @StoreId IS NULL
			)
		AND I.IsNarcotic = 1
	GROUP BY S.ItemId
		,G.GenericName
		,I.ItemName
		,S.BatchNo
		,S.ExpiryDate
		,S.CostPrice
		,S.SalePrice
		,S.StockId
		,STR.Name
		,STR.StoreId
	ORDER BY SUM(ISNULL(SS.AvailableQuantity, 0)) DESC
END