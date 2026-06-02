CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetConsumableDispatchMainStoreTransaction]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetConsumableDispatchMainStoreTransaction '2023-06-27',1
 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/27th June 23                 Initial Draft of SP to get pharmacy consumable dispatch (main Store) transactions.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,0 AS DrCr
	,'PHRM_ConsumableDispatch' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		StockTransactionId AS ReferenceId
		,'PHRM_ConsumableDispatch_MainStore' AS TransactionType
		,(stockTxn.CostPrice * stockTxn.OutQty) AS TotalAmount
		,CAST(stockTxn.TransactionDate AS DATE) AS TransactionDate
		,'WARD SUPPLY FOR (' + CONVERT(VARCHAR(100), CAST(stockTxn.TransactionDate AS DATE)) +')' AS Description
		,(SELECT LedgerId FROM ACC_Ledger WHERE Name='IOS_WARD_/_DEPARTMENT_SUPPLY') AS LedgerId
		,0 AS SubLedgerId
	FROM PHRM_TXN_StockTransaction stockTxn
	WHERE CONVERT(DATE, stockTxn.TransactionDate) = @TransactionDate
	AND ISNULL(stockTxn.IsTransferedToAcc,0) = 0 
	AND stockTxn.TransactionType='dispensary-dispatched-item'
	AND stockTxn.OutQty > 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END