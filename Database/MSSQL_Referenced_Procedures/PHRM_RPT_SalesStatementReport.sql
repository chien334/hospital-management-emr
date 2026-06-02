CREATE PROCEDURE [dbo].[PHRM_RPT_SalesStatementReport] @FromDate DATETIME = GETDATE
	,@ToDate DATETIME = GETDATE
AS
-- =============================================
-- Author:		Sanjit
-- Create date: 17/06/2021
-- Description: generated sales statement report
-- =============================================
/* Change History
S.No.    UpdatedBy/Date                        Remarks
1.       sanjit/ramesh/26thJuly'21           total amount mismatch corrected
2.		 Rohit/25Jul'22						 Date is Converted
3        Rohit/13Feb'23						MRP-> SalePrice
*/
BEGIN
	-- body of the stored procedure
	SELECT str.Name
		,CONVERT(MONEY, SUM(ISNULL(stk.OutQty, 0) * ISNULL(stk.SalePrice, 0))) 'SalesValue'
		,CONVERT(MONEY, SUM(ISNULL(stk.OutQty, 0) * ISNULL(stk.CostPrice, 0))) 'SalesCostValue'
		,CONVERT(MONEY, SUM(ISNULL(Stk.InQty, 0) * ISNULL(stk.SalePrice, 0))) 'SalesReturnValue'
		,CONVERT(MONEY, SUM(ISNULL(Stk.InQty, 0) * ISNULL(Stk.CostPrice, 0))) 'SalesReturnCostValue'
		,(CONVERT(MONEY, SUM(ISNULL(stk.OutQty, 0) * ISNULL(stk.SalePrice, 0))) - CONVERT(MONEY, SUM(ISNULL(stk.OutQty, 0) * ISNULL(stk.CostPrice, 0)))) - (CONVERT(MONEY, SUM(ISNULL(stk.InQty, 0) * ISNULL(stk.SalePrice, 0))) - CONVERT(MONEY, SUM(ISNULL(Stk.InQty, 0) * ISNULL(Stk.CostPrice, 0)))) 'Balance'
	FROM PHRM_TXN_StockTransaction stk
	INNER JOIN PHRM_MST_Store str ON str.StoreId = stk.StoreId
	WHERE stk.IsActive = 1
		AND stk.TransactionType IN (
			'sale-item'
			,'sale-returned-item'
			,'manual-sales-return'
			,'provisional-sale-item'
			,'provisiona-cancel-item'
			)
		AND Convert(DATE, stk.CreatedOn) BETWEEN @FromDate
			AND @ToDate
	GROUP BY stk.StoreId
		,str.Name
	
	UNION
	
	SELECT 'Total'
		,CONVERT(MONEY, SUM(ISNULL(stk.OutQty, 0) * ISNULL(stk.SalePrice, 0))) 'SalesValue'
		,CONVERT(MONEY, SUM(ISNULL(stk.OutQty, 0) * ISNULL(stk.CostPrice, 0))) 'SalesCostValue'
		,CONVERT(MONEY, SUM(ISNULL(Stk.InQty, 0) * ISNULL(stk.SalePrice, 0))) 'SalesReturnValue'
		,CONVERT(MONEY, SUM(ISNULL(Stk.InQty, 0) * ISNULL(Stk.CostPrice, 0))) 'SalesReturnCostValue'
		,CONVERT(MONEY, SUM(ISNULL(stk.OutQty, 0) * ISNULL(stk.SalePrice, 0))) - CONVERT(MONEY, SUM(ISNULL(stk.OutQty, 0) * ISNULL(stk.CostPrice, 0))) - (CONVERT(MONEY, SUM(ISNULL(stk.InQty, 0) * ISNULL(stk.SalePrice, 0))) - CONVERT(MONEY, SUM(ISNULL(Stk.InQty, 0) * ISNULL(Stk.CostPrice, 0)))) 'Balance'
	FROM PHRM_TXN_StockTransaction stk
	INNER JOIN PHRM_MST_Store str ON str.StoreId = stk.StoreId
	WHERE stk.IsActive = 1
		AND stk.TransactionType IN (
			'sale-item'
			,'sale-returned-item'
			,'manual-sales-return'
			,'provisional-sale-item'
			,'provisiona-cancel-item'
			)
		AND Convert(DATE, stk.CreatedOn) BETWEEN @FromDate
			AND @ToDate
END