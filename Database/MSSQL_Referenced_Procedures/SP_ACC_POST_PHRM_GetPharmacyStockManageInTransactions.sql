CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetPharmacyStockManageInTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetPharmacyStockManageInTransactions '2023-06-27',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/27th June 23                Initial Draft of SP to get pharmacy StockManageIn transactions.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(CASE WHEN DrCr = 1 THEN (SELECT LedgerId FROM ACC_Ledger WHERE Name='IOS_WARD_/_DEPARTMENT_SUPPLY')
		ELSE (SELECT LedgerId FROM ACC_Ledger WHERE Name='EHC_CONSUMABLE_:_PHARMACY') END ,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,DrCr AS DrCr
	,'PHRM_StockManageIn' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		StockTransactionId AS ReferenceId
		,'PHRM_StockManageItem' AS TransactionType
		,(stockTxn.CostPrice * stockTxn.InQty) AS TotalAmount
		,CAST(stockTxn.TransactionDate AS DATE) AS TransactionDate
		,'PHARMACY STOCK MANAGE IN FOR : ' + '(' + CONVERT(VARCHAR(100), CAST(stockTxn.TransactionDate AS DATE)) +')'  AS Description
		,0 AS LedgerId
		,0 AS SubLedgerId
		,CONVERT(bit, DebitCredit.value) AS DrCr
	FROM PHRM_TXN_StockTransaction stockTxn
	CROSS JOIN (
		SELECT value
		FROM STRING_SPLIT('1,0', ',')
	) AS DebitCredit
		WHERE Convert(DATE, stockTxn.TransactionDate) = @TransactionDate
	AND ISNULL(stockTxn.IsTransferedToAcc,0) = 0 
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