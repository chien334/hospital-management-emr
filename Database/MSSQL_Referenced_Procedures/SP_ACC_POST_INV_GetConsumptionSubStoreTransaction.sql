CREATE PROCEDURE [dbo].[SP_ACC_POST_INV_GetConsumptionSubStoreTransaction]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_INV_GetConsumptionSubStoreTransaction '2023-10-04',3
 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/26th June 23                 Initial Draft of SP to get inventory consumption (Sub Store/SubCategory for CHARAK) transactions.
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
	,1 AS DrCr
	,'INV_Consumption' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		StockTransactionId AS ReferenceId
		,'INV_Consumption_SubStore' AS TransactionType
		,(stockTxn.CostPrice * stockTxn.OutQty) AS TotalAmount
		,CAST(stockTxn.TransactionDate AS DATE) AS TransactionDate
		, 'Inventory Consumption For (' + CONVERT(VARCHAR(100), CAST(stockTxn.TransactionDate AS DATE)) +')' AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
	FROM INV_TXN_StockTransaction stockTxn
	JOIN INV_MST_Item item ON stockTxn.ItemId = item.ItemId
	JOIN INV_MST_ItemSubCategory category ON item.SubCategoryId = category.SubCategoryId
	JOIN ACC_Ledger_Mapping map ON category.SubCategoryId = map.ReferenceId
	WHERE CONVERT(DATE, stockTxn.TransactionDate) = @TransactionDate
	AND ISNULL(stockTxn.IsTransferredToACC,0) = 0 
	AND map.LedgerType='inventorysubcategory'
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