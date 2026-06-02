CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_IPD_CREDIT_GetInpatientCreditSaleReturn]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_IPD_CREDIT_GetInpatientCreditSaleReturn '2023-06-19',1
 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/19th June 23                Initial Draft of SP to get IPD (CREDIT) Pharmacy Sales Return.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL((SELECT SubLedgerId FROM ACC_MST_SubLedger WHERE LedgerId = InnerTable.LedgerId AND SubLedgerName = 'CREDIT'),0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,1 AS DrCr
	,'PHRM_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		InvoiceReturnId AS ReferenceId
		,'PHRM_IPD_CREDIT_Sales_Return' TransactionType
		,retInvoice.SubTotal AS TotalAmount
		,CAST(retInvoice.CreatedOn AS DATE) AS TransactionDate
		,'IP SALE Return Cedit Note Ref. No.(CR-PH-' + CONVERT(VARCHAR(20),retInvoice.CreditNoteID)  + ') for ' + CONVERT(VARCHAR(100), CAST(retInvoice.CreatedOn AS DATE)) AS Description
		,(
			SELECT LedgerId
			FROM ACC_Ledger
			WHERE Name = 'RDI_SALES_SALES-PHARMACY'
			) AS LedgerId
		,0 AS SubLedgerId
	FROM PHRM_TXN_InvoiceReturn retInvoice
	WHERE 
	Convert(DATE, retInvoice.CreatedOn) = @TransactionDate
	AND retInvoice.PaymentMode = 'credit' 
	AND retInvoice.VisitType = 'inpatient' 
	AND ISNULL(retInvoice.IsTransferredToACC, 0) = 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END