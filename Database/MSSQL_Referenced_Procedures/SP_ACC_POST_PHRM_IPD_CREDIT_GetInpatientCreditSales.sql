CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_IPD_CREDIT_GetInpatientCreditSales]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_IPD_CREDIT_GetInpatientCreditSales '2023-06-19',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/19th June 23                Initial Draft of SP to get IPD (CREDIT) Pharmacy Sales.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL((SELECT SubLedgerId FROM ACC_MST_SubLedger WHERE LedgerId = InnerTable.LedgerId AND SubLedgerName = 'CREDIT'),0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,'IP SALE Invoice Ref. No.(' + STRING_AGG('PH-'+ CONVERT(VARCHAR(100),InnerTable.InvoicePrintId),',') + ') for ' + CONVERT(VARCHAR(100), CAST(InnerTable.TransactionDate AS DATE)) AS Description

	,1 AS DisplaySequence
	,0 AS DrCr
	,'PHRM_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		InvoiceId 'ReferenceId'
		,'PHRM_IPD_CREDIT_Sales' TransactionType
		,invoice.SubTotal AS TotalAmount
		,CAST(invoice.CreateOn AS DATE) AS TransactionDate
		,NULL AS Description
		,(
			SELECT LedgerId
			FROM ACC_Ledger
			WHERE Name = 'RDI_SALES_SALES-PHARMACY'
			) AS LedgerId
		,0 AS SubLedgerId
		,invoice.InvoicePrintId
	FROM PHRM_TXN_Invoice invoice
	WHERE 
	Convert(DATE, invoice.CreateOn) = @TransactionDate
	AND invoice.PaymentMode = 'credit' 
	AND invoice.VisitType = 'inpatient' 
	AND ISNULL(invoice.IsTransferredToACC, 0) = 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END