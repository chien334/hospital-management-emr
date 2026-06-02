CREATE PROCEDURE [dbo].[SP_ACC_POST_INV_GetInventoryStockManageInTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_INV_GetInventoryStockManageInTransactions '2023-06-27',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/27th June 23                Initial Draft of SP to get Inventory StockManageIn transactions.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(CASE WHEN DrCr = 1 THEN (SELECT LedgerId FROM ACC_Ledger WHERE Name='ACA_INVENTORY_INVENTORY-HOSPITAL')
		ELSE (SELECT LedgerId FROM ACC_Ledger WHERE Name='EDE_COST_OF_GOODS_CONSUMED_COGC') END ,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,DrCr AS DrCr
	,'INV_StockManageIn' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		StockTransactionId AS ReferenceId
		,'INV_StockManageItem' AS TransactionType
		,(stockTxn.CostPrice * stockTxn.InQty) AS TotalAmount
		,CAST(stockTxn.TransactionDate AS DATE) AS TransactionDate
		,'INVENTORY STOCK MANAGE IN FOR : ' + '(' + CONVERT(VARCHAR(100), CAST(stockTxn.TransactionDate AS DATE)) +')'  AS Description
		,0 AS LedgerId
		,0 AS SubLedgerId
		,CONVERT(bit, DebitCredit.value) AS DrCr
	FROM INV_TXN_StockTransaction stockTxn
	CROSS JOIN (
		SELECT value
		FROM STRING_SPLIT('1,0', ',')
	) AS DebitCredit
		WHERE Convert(DATE, stockTxn.TransactionDate) = @TransactionDate
	AND ISNULL(stockTxn.IsTransferredToACC,0) = 0 
	AND TransactionType = 'stock-managed-item'
	AND InQty > 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
	,InnerTable.DrCr
ORDER BY InnerTable.DrCr DESC
END