CREATE PROCEDURE [dbo].[PHRM_RPT_StockSummary2] @TillDate DATE = NULL
AS
-- =============================================
-- Author:		Sanjit
-- Create date: 18/06/2021
-- Description: generated stock summary (2nd) report
-- Example : EXECUTE dbo.PHRM_RPT_StockSummary2 '2021-06-20'
-- =============================================
/* Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Sanjit/02/09/2021		converted datetime to date for @TillDate
2        Rohit/13Feb'23						MRP-> SalePrice
*/
BEGIN
	-- body of the stored procedure
	SELECT store.Name AS StoreName
		,stxn.PurchaseValue
		,stxn.SalesValue
	FROM PHRM_MST_Store store
	LEFT JOIN (
		SELECT str.StoreId
			,CONVERT(MONEY, SUM(ISNULL(stxn.InQty, 0) * ISNULL(stxn.CostPrice, 0)) - sum(ISNULL(stxn.OutQty, 0) * ISNULL(stxn.CostPrice, 0))) 'PurchaseValue'
			,CONVERT(MONEY, SUM(ISNULL(stxn.InQty, 0) * ISNULL(stxn.SalePrice, 0)) - sum(ISNULL(stxn.OutQty, 0) * ISNULL(stxn.SalePrice, 0))) 'SalesValue'
		FROM PHRM_TXN_StockTransaction stxn
		JOIN PHRM_MST_Store str ON stxn.StoreId = str.StoreId
		JOIN PHRM_MST_Item itm ON itm.ItemId = stxn.ItemId
		WHERE ISNULL(stxn.IsActive, 0) = 1
			AND CONVERT(DATE, stxn.TransactionDate) < @TillDate
		GROUP BY str.StoreId
		) stxn ON store.StoreId = stxn.StoreId
	WHERE store.Category IN ('dispensary')
		OR store.SubCategory = 'pharmacy'
	
	UNION
	
	SELECT 'Total' AS StoreName
		,stxn.PurchaseValue
		,stxn.SalesValue
	FROM (
		SELECT CONVERT(MONEY, SUM(ISNULL(stxn.InQty, 0) * ISNULL(stxn.CostPrice, 0)) - sum(ISNULL(stxn.OutQty, 0) * ISNULL(stxn.CostPrice, 0))) 'PurchaseValue'
			,CONVERT(MONEY, SUM(ISNULL(stxn.InQty, 0) * ISNULL(stxn.SalePrice, 0)) - sum(ISNULL(stxn.OutQty, 0) * ISNULL(stxn.SalePrice, 0))) 'SalesValue'
		FROM PHRM_TXN_StockTransaction stxn
		WHERE ISNULL(stxn.IsActive, 0) = 1
			AND CONVERT(DATE, stxn.TransactionDate) < @TillDate
		) stxn
END