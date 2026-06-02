CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetConsumableDispatchReturnSubStoreTransaction]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetConsumableDispatchReturnSubStoreTransaction '2023-06-27',1
 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/27th June 23                 Initial Draft of SP to get pharmacy consumable dispatch return (Sub Store) transactions.
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
	,'PHRM_ConsumableDispatchReturn' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		StockTransactionId AS ReferenceId
		,'PHRM_ConsumableDispatchReturn_SubStore' AS TransactionType
		,(stockTxn.CostPrice * stockTxn.OutQty) AS TotalAmount
		,CAST(stockTxn.TransactionDate AS DATE) AS TransactionDate
		,'WARD SUPPLY RETURN FOR (' + CONVERT(VARCHAR(100), CAST(stockTxn.TransactionDate AS DATE)) +')' AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
	FROM PHRM_TXN_StockTransaction stockTxn
	JOIN ACC_Ledger_Mapping map ON stockTxn.StoreId = map.ReferenceId
	WHERE CONVERT(DATE, stockTxn.TransactionDate) = @TransactionDate
	AND ISNULL(stockTxn.IsTransferedToAcc,0) = 0 
	AND map.LedgerType='PharmacyConsumption'
	AND stockTxn.TransactionType='transfer-item'
	AND stockTxn.OutQty > 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END