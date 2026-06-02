CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_CREDIT_GetInternalCreditOrganizationSalesReturn]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_CREDIT_GetInternalCreditOrganizationSalesReturn '2023-06-19',1
 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/19th June 23                Initial Draft of SP to get OPD (CREDIT) Pharmacy Sales Return (Medicare).
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
	,'PHRM_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		InvoiceReturnId AS ReferenceId
		,'PHRM_OPD_CREDIT_Sales_Return' TransactionType
		,retInvoice.ReturnCreditAmount AS TotalAmount
		,CAST(retInvoice.CreatedOn AS DATE) AS TransactionDate
		,'OP SALE Return (STAFF MEDICARE) Cedit Note Ref. No.(CR-PH-' + CONVERT(VARCHAR(20),retInvoice.CreditNoteID)  + ') for ' + CONVERT(VARCHAR(100), CAST(retInvoice.CreatedOn AS DATE)) AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
	FROM PHRM_TXN_InvoiceReturn retInvoice
	JOIN INS_MedicareMember patient ON retInvoice.PatientId = patient.PatientId
	JOIN ACC_Ledger_Mapping map ON map.ReferenceId = patient.MedicareMemberId
	JOIN BIL_MST_Credit_Organization org ON retInvoice.OrganizationId = org.OrganizationId
	WHERE CONVERT(DATE, retInvoice.CreatedOn) = @TransactionDate
	AND retInvoice.PaymentMode = 'credit' 
	AND ISNULL(retInvoice.IsTransferredToACC, 0) = 0
	AND retInvoice.PaymentMode = 'credit'
	AND map.LedgerType = 'MedicareMember'
	AND org.CreditOrganizationCode = 'MEDICARE'
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.ReferenceId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END