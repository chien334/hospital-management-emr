CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetInternalCreditOrganizationSales]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetInternalCreditOrganizationSales '2023-06-19',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/19th June 23                Initial Draft of SP to get pharmacy OPD Credit Sales INTERNAL(Medicare) Detail.
*/
BEGIN
SELECT 
	'PHRM_Credit_Sale' AS TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
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
		InvoiceId 'ReferenceId'
		,invoice.CreditAmount AS TotalAmount
		,CAST(invoice.CreateOn AS DATE) 'TransactionDate'
		,'STAFF MEDICARE -' + CONVERT(VARCHAR(100), CAST(invoice.CreateOn AS DATE)) AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,invoice.OrganizationId
	FROM PHRM_TXN_Invoice invoice
	JOIN INS_MedicareMember patient ON invoice.PatientId = patient.PatientId
	JOIN ACC_Ledger_Mapping map ON map.ReferenceId = patient.MedicareMemberId
	JOIN BIL_MST_Credit_Organization org ON invoice.OrganizationId = org.OrganizationId
	WHERE Convert(DATE, invoice.CreateOn) = @TransactionDate 
	AND invoice.PaymentMode = 'credit'
	AND map.LedgerType = 'MedicareMember'
	AND org.CreditOrganizationCode='MEDICARE'
	AND ISNULL(invoice.IsTransferredToACC, 0) = 0
	) InnerTable
GROUP BY 
	InnerTable.OrganizationId
	,LedgerId
	,SubLedgerId
	,TransactionDate
	,Description
END