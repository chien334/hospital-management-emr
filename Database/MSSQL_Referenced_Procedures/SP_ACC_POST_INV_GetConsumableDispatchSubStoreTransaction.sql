CREATE PROCEDURE [dbo].[SP_ACC_POST_INV_GetConsumableDispatchSubStoreTransaction]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_INV_GetConsumableDispatchSubStoreTransaction '2023-06-26',1
 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/26th June 23                 Initial Draft of SP to get inventory consumable dispatch (Sub Store) transactions.
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
	,1 AS DrCr
	,'INV_ConsumableDispatch' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		StockTransactionId AS ReferenceId
		,'INV_ConsumableDispatch_SubStore' AS TransactionType
		,(stockTxn.CostPrice * stockTxn.InQty) AS TotalAmount
		,CAST(stockTxn.TransactionDate AS DATE) AS TransactionDate
		, 'STORE ALLOCATION FOR (' + CONVERT(VARCHAR(100), CAST(stockTxn.TransactionDate AS DATE)) +')' AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
	FROM INV_TXN_StockTransaction stockTxn
	JOIN INV_MST_Item item ON stockTxn.ItemId = item.ItemId
	JOIN ACC_Ledger_Mapping map ON stockTxn.StoreId = map.ReferenceId
	WHERE CONVERT(DATE, stockTxn.TransactionDate) = @TransactionDate
	AND ISNULL(stockTxn.IsTransferredToACC,0) = 0 
	AND map.LedgerType='InventoryConsumption'
	AND stockTxn.TransactionType='dispatched-item-to'
	AND item.IsFixedAssets = 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END