CREATE PROCEDURE [dbo].[SP_PHRM_RPT_GetStockSummary] @FiscalYearId INT
	,@FromDate DATE
	,@ToDate DATE
	,@StoreId INT
AS
/************************************************************************
FileName: [SP_PHRM_RPT_GetStockSummary] 4, '
CreatedBy/date: Sanjit/15Jun21
Description: Get Pharmacy stock summary report data
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Sanjit/15Jun21						script created 
2		Sanjit/21Jul21						all amount rounded to two decimal point
3       Ramesh/10Aug'21                     store wise filter added
4		Sanjit/Sud/30Aug'21					a. Added calculation for Stock Transfers. 
											b. used new function to get closing on previous day
5.      Sud:12Jul'22                        Corrected Closing Formula for WithProvisional
6.       Rohit/13Feb'23						MRP-> SalePrice
*************************************************************************/
BEGIN
	DECLARE @FyStartDate DATE = (
			SELECT TOP 1 CONVERT(DATE, StartDate)
			FROM PHRM_CFG_FiscalYears
			WHERE FiscalYearId = @FiscalYearId
			)
	DECLARE @ClosingDate DATE = DATEADD(DAY, - 1, @FromDate) -- Closing should be calculated on Previous Day

	SELECT stkMaster.StockId
		,store.StoreId
		,store.Name AS 'StoreName'
		,I.ItemId
		,G.GenericName
		,I.ItemName
		,I.ItemCode
		,U.UOMName
		,stkMaster.BatchNo
		,stkMaster.ExpiryDate
		,stkMaster.CostPrice
		,stkMaster.SalePrice
		,SUM(ISNULL(prevDayClosing.ClosingQty, 0)) AS 'OpeningQty'
		,ROUND(SUM(ISNULL(prevDayClosing.ClosingValue, 0)), 2) AS 'OpeningValue'
		,SUM(ISNULL(prevDayClosing.ClosingQty_WithProvisional, 0)) AS 'OpeningQty_WithProvisional'
		,ROUND(SUM(ISNULL(prevDayClosing.ClosingValue_WithProvisional, 0)), 2) AS 'OpeningValue_WithProvisional'
		,SUM(ISNULL(txnsBetnRange.PurchaseQty, 0)) AS 'PurchaseQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.PurchaseValue, 0)), 2) AS 'PurchaseValue'
		,SUM(ISNULL(txnsBetnRange.PurchaseReturnQty, 0)) AS 'PurchaseReturnQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.PurchaseReturnValue, 0)), 2) AS 'PurchaseReturnValue'
		,SUM(ISNULL(txnsBetnRange.SalesQty, 0)) AS 'SalesQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.SalesValue, 0)), 2) AS 'SalesValue'
		,SUM(ISNULL(txnsBetnRange.SalesReturnQty, 0)) AS 'SaleReturnQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.SalesReturnValue, 0)), 2) AS 'SaleReturnValue'
		,SUM(ISNULL(txnsBetnRange.ProvisionalQty, 0)) AS 'ProvisionalQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.ProvisionalValue, 0)), 2) AS 'ProvisionalValue'
		,SUM(ISNULL(txnsBetnRange.WriteOffQty, 0)) AS 'WriteOffQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.WriteOffValue, 0)), 2) AS 'WriteOffValue'
		,SUM(ISNULL(txnsBetnRange.ConsumptionQty, 0)) AS 'ConsumptionQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.ConsumptionValue, 0)), 2) AS 'ConsumptionValue'
		,SUM(ISNULL(txnsBetnRange.StockManageOutQty, 0)) AS 'StockManageOutQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.StockManageOutValue, 0)), 2) AS 'StockManageOutValue'
		,SUM(ISNULL(txnsBetnRange.StockManageInQty, 0)) AS 'StockManageInQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.StockManageInValue, 0)), 2) AS 'StockManageInValue'
		,SUM(ISNULL(txnsBetnRange.TransferInQty, 0)) AS 'TransferInQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.TransferInValue, 0)), 2) AS 'TransferInValue'
		,SUM(ISNULL(txnsBetnRange.TransferOutQty, 0)) AS 'TransferOutQty'
		,ROUND(SUM(ISNULL(txnsBetnRange.TransferOutValue, 0)), 2) AS 'TransferOutValue'
		,SUM(ISNULL(prevDayClosing.ClosingQty_WithProvisional, 0)) + SUM(ISNULL(txnsBetnRange.PurchaseQty, 0)) - SUM(ISNULL(txnsBetnRange.PurchaseReturnQty, 0)) - SUM(ISNULL(txnsBetnRange.SalesQty, 0)) + SUM(ISNULL(txnsBetnRange.SalesReturnQty, 0)) - SUM(ISNULL(txnsBetnRange.ProvisionalQty, 0)) - SUM(ISNULL(txnsBetnRange.WriteOffQty, 0)) - SUM(ISNULL(txnsBetnRange.ConsumptionQty, 0)) + SUM(ISNULL(txnsBetnRange.StockManageInQty, 0)) - SUM(ISNULL(txnsBetnRange.StockManageOutQty, 0)) + SUM(ISNULL(txnsBetnRange.TransferInQty, 0)) - SUM(ISNULL(txnsBetnRange.TransferOutQty, 0)) AS 'ClosingQty_WithProvisional'
		,ROUND(SUM(ISNULL(prevDayClosing.ClosingValue_WithProvisional, 0)) + SUM(ISNULL(txnsBetnRange.PurchaseValue, 0)) - SUM(ISNULL(txnsBetnRange.PurchaseReturnValue, 0)) - SUM(ISNULL(txnsBetnRange.SalesValue, 0)) + SUM(ISNULL(txnsBetnRange.SalesReturnValue, 0)) - SUM(ISNULL(txnsBetnRange.ProvisionalValue, 0)) - SUM(ISNULL(txnsBetnRange.WriteOffValue, 0)) - SUM(ISNULL(txnsBetnRange.ConsumptionValue, 0)) + SUM(ISNULL(txnsBetnRange.StockManageInValue, 0)) - SUM(ISNULL(txnsBetnRange.StockManageOutValue, 0)) + SUM(ISNULL(txnsBetnRange.TransferInValue, 0)) - SUM(ISNULL(txnsBetnRange.TransferOutValue, 0)), 2) AS 'ClosingValue_WithProvisional'
		,SUM(ISNULL(prevDayClosing.ClosingQty, 0)) + SUM(ISNULL(txnsBetnRange.PurchaseQty, 0)) - SUM(ISNULL(txnsBetnRange.PurchaseReturnQty, 0)) - SUM(ISNULL(txnsBetnRange.SalesQty, 0)) + SUM(ISNULL(txnsBetnRange.SalesReturnQty, 0)) - SUM(ISNULL(txnsBetnRange.WriteOffQty, 0)) - SUM(ISNULL(txnsBetnRange.ConsumptionQty, 0)) + SUM(ISNULL(txnsBetnRange.StockManageInQty, 0)) - SUM(ISNULL(txnsBetnRange.StockManageOutQty, 0)) + SUM(ISNULL(txnsBetnRange.TransferInQty, 0)) - SUM(ISNULL(txnsBetnRange.TransferOutQty, 0)) AS 'ClosingQty'
		,ROUND(SUM(ISNULL(prevDayClosing.ClosingValue, 0)) + SUM(ISNULL(txnsBetnRange.PurchaseValue, 0)) - SUM(ISNULL(txnsBetnRange.PurchaseReturnValue, 0)) - SUM(ISNULL(txnsBetnRange.SalesValue, 0)) + SUM(ISNULL(txnsBetnRange.SalesReturnValue, 0)) - SUM(ISNULL(txnsBetnRange.WriteOffValue, 0)) - SUM(ISNULL(txnsBetnRange.ConsumptionValue, 0)) + SUM(ISNULL(txnsBetnRange.StockManageInValue, 0)) - SUM(ISNULL(txnsBetnRange.StockManageOutValue, 0)) + SUM(ISNULL(txnsBetnRange.TransferInValue, 0)) - SUM(ISNULL(txnsBetnRange.TransferOutValue, 0)), 2) AS 'ClosingValue'
	FROM PHRM_MST_Item I
	INNER JOIN PHRM_MST_Generic G ON I.GenericId = G.GenericId
	INNER JOIN PHRM_MST_UnitOfMeasurement U ON I.UOMId = U.UOMId
	INNER JOIN PHRM_MST_Stock stkMaster ON I.ItemId = stkMaster.ItemId
	INNER JOIN PHRM_MST_Store store ON store.Category IN ('dispensary')
		OR store.SubCategory = 'pharmacy'
	--for prevDayClosing part, we take closing from previous day as opening for today.
	LEFT JOIN (
		SELECT *
		FROM FN_RPT_PHRM_GetClosingStockDetailsOnGivenDate(@FiscalYearId, @FyStartDate, @ClosingDate)
		) prevDayClosing ON prevDayClosing.StockId = stkMaster.StockId
		AND store.StoreId = prevDayClosing.StoreId
	--for current year part
	LEFT JOIN (
		SELECT *
		FROM [FN_RPT_PHRM_GetItemStockTxnsBetnDateRange](@FromDate, @ToDate)
		) txnsBetnRange ON stkMaster.StockId = txnsBetnRange.StockId
		AND store.StoreId = txnsBetnRange.StoreId
	--> If @StoreId is NULL, then show stocks of all stores, else show stocks of given store
	WHERE (
			store.StoreId = @StoreId
			OR @StoreId IS NULL
			)
	GROUP BY stkMaster.StockId
		,store.StoreId
		,store.Name
		,I.ItemId
		,G.GenericName
		,I.ItemName
		,I.ItemCode
		,U.UOMName
		,stkMaster.BatchNo
		,stkMaster.ExpiryDate
		,stkMaster.CostPrice
		,stkMaster.SalePrice
	ORDER BY I.ItemName
		,store.StoreId
END