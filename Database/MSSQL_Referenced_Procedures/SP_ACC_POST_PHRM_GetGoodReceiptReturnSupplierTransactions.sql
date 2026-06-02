CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetGoodReceiptReturnSupplierTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetGoodReceiptReturnSupplierTransactions '2023-06-21',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/21th June 23                Initial Draft of SP to get Pharmacy good receipt return (supplier) Transactions.
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
	,'PHRM_PurchaseReturn' AS BaseTransactionType
	,ReturnToSupplierId AS TransactionRefNo
FROM (
	SELECT 
		ReturnToSupplierId AS ReferenceId
		,'PHRM_GoodReceiptReturn_Supplier' AS TransactionType
		,(grReturn.TotalAmount) AS TotalAmount
		,CAST(grReturn.CreatedOn AS DATE) AS TransactionDate
		,'CRN: ' + CONVERT(VARCHAR(30),grReturn.CreditNotePrintId) + ' (' + CONVERT(VARCHAR(100), CAST(grReturn.CreatedOn AS DATE)) +')' + ' Ref. GRN: ' + CONVERT(VARCHAR(30),grReturn.GoodReceiptId) + '/' + supplier.SupplierName  AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,grReturn.ReturnToSupplierId
	FROM PHRM_ReturnToSupplier grReturn
	JOIN ACC_Ledger_Mapping map ON grReturn.SupplierId = map.ReferenceId
	JOIN PHRM_MST_Supplier supplier ON grReturn.SupplierId = supplier.SupplierId
		WHERE Convert(DATE, grReturn.ReturnDate) = @TransactionDate
	AND ISNULL(grReturn.IsTransferredToACC,0) = 0 
	AND map.LedgerType='pharmacysupplier'
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
	,InnerTable.ReturnToSupplierId
END