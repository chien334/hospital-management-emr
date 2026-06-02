CREATE PROCEDURE [dbo].[SP_ACC_POST_INV_GetGoodReceiptReturnVendorTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_INV_GetGoodReceiptReturnVendorTransactions '2023-06-22',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/22th June 23                 Initial Draft of SP to get inventory good receipt return (vendor) Transactions.
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
	,'INV_PurchaseReturn' AS BaseTransactionType
	,ReturnToVendorId AS TransactionRefNo
FROM (
	SELECT 
		ReturnToVendorId AS ReferenceId
		,'INV_GoodReceiptReturn_Vendor' AS TransactionType
		,(grReturn.TotalAmount) AS TotalAmount
		,CAST(grReturn.CreatedOn AS DATE) AS TransactionDate
		,'CRN: ' + CONVERT(VARCHAR(30),grReturn.CreditNoteId) + ' (' + CONVERT(VARCHAR(100), CAST(grReturn.CreatedOn AS DATE)) +')' +'/' + vendor.VendorName  AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,grReturn.ReturnToVendorId
	FROM INV_TXN_ReturnToVendor grReturn
	JOIN ACC_Ledger_Mapping map ON grReturn.VendorId = map.ReferenceId
	JOIN INV_MST_Vendor vendor ON grReturn.VendorId = vendor.VendorId
		WHERE Convert(DATE, grReturn.ReturnDate) = @TransactionDate
	AND ISNULL(grReturn.IsTransferredToAcc,0) = 0 
	AND map.LedgerType='inventoryvendor'
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
	,InnerTable.ReturnToVendorId
END