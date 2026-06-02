CREATE PROCEDURE [dbo].[SP_ACC_POST_INV_GetConsumptionCentralStoreTransaction]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_INV_GetConsumptionCentralStoreTransaction '2023-10-04',3

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/15th Oct 23                 Initial Draft of SP to get inventory consumption transactions for central store.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(CONVERT(VARCHAR(MAX),ReferenceId), ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,0 AS DrCr
	,'INV_Consumption' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		StockTransactionId AS ReferenceId
		,'INV_Consumption_CentralStore' AS TransactionType
		,(stockTxn.CostPrice * stockTxn.OutQty) AS TotalAmount
		,CAST(stockTxn.TransactionDate AS DATE) AS TransactionDate
		, 'Inventory Consumption For (' + CONVERT(VARCHAR(100), CAST(stockTxn.TransactionDate AS DATE)) +')' AS Description
		,(SELECT LedgerId FROM ACC_Ledger WHERE Name='ACA_MERCHANDISE_INVENTORYMERCHANDISE_INVENTORY') AS LedgerId
		,0 AS SubLedgerId
	FROM INV_TXN_StockTransaction stockTxn
	JOIN INV_MST_Item item ON stockTxn.ItemId = item.ItemId
	WHERE CONVERT(DATE, stockTxn.TransactionDate) = @TransactionDate
	AND ISNULL(stockTxn.IsTransferredToACC,0) = 0 
	AND stockTxn.TransactionType='consumption-items'
	AND item.ItemType='Consumables'
	AND ISNULL(item.IsFixedAssets,0) = 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END