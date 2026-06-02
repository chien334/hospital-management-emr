CREATE PROCEDURE [dbo].[SP_ACC_POST_INV_GetGoodReceiptReturnVATTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_INV_GetGoodReceiptReturnVATTransactions '2023-06-22',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/22th June 23                Initial Draft of SP to get inventory good receipt return (VAT) Transactions.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL((SELECT TOP (1) SubLedgerId FROM ACC_MST_SubLedger WHERE LedgerId = InnerTable.LedgerId AND IsDefault = 1),0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,0 AS DrCr
	,'INV_PurchaseReturn' AS BaseTransactionType
	,ReturnToVendorId AS TransactionRefNo
FROM (
	SELECT 
		ReturnToVendorId AS ReferenceId
		,'INV_GoodReceiptReturn_VAT' AS TransactionType
		,(grReturn.VATTotal) AS TotalAmount
		,CAST(grReturn.CreatedOn AS DATE) AS TransactionDate
		,'CRN: ' + CONVERT(VARCHAR(30),grReturn.CreditNoteId) +' for-' + CONVERT(VARCHAR(100), CAST(grReturn.CreatedOn AS DATE)) AS Description
		,(select LedgerId from ACC_Ledger where Name='LCL_DUTIES_AND_TAXES_VAT') AS LedgerId
		,0 AS SubLedgerId
		,grReturn.ReturnToVendorId
	FROM INV_TXN_ReturnToVendor grReturn
		WHERE Convert(DATE, grReturn.ReturnDate) = @TransactionDate
	AND ISNULL(grReturn.IsTransferredToAcc,0) = 0 
	AND grReturn.VATTotal > 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
	,InnerTable.ReturnToVendorId
END