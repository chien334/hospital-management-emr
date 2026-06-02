CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetGoodReceiptReturnVATTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetGoodReceiptReturnVATTransactions '2023-06-21',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/21th June 23                Initial Draft of SP to get Pharmacy good receipt return (VAT) Transactions.
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
	,'PHRM_PurchaseReturn' AS BaseTransactionType
	,ReturnToSupplierId AS TransactionRefNo
FROM (
	SELECT 
		ReturnToSupplierId AS ReferenceId
		,'PHRM_GoodReceiptReturn_VAT' AS TransactionType
		,(grReturn.VATAmount) AS TotalAmount
		,CAST(grReturn.CreatedOn AS DATE) AS TransactionDate
		,'CRN: ' + CONVERT(VARCHAR(30),grReturn.CreditNotePrintId) +' for-' + CONVERT(VARCHAR(100), CAST(grReturn.CreatedOn AS DATE)) AS Description
		,(select LedgerId from ACC_Ledger where Name='ACA_VAT_13%_PAYABLE') AS LedgerId
		,0 AS SubLedgerId
		,grReturn.ReturnToSupplierId
	FROM PHRM_ReturnToSupplier grReturn
		WHERE Convert(DATE, grReturn.ReturnDate) = @TransactionDate
	AND ISNULL(grReturn.IsTransferredToACC,0) = 0 
	AND grReturn.VATAmount > 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
	,InnerTable.ReturnToSupplierId
END