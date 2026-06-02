CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetCreditOrganizationSales]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetCreditOrganizationSales '2023-06-18',1
 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/18th June 23                Initial Draft of SP to get Pharmacy outpatient Credit Sales Detail(Credit Organization).
*/
BEGIN
SELECT 
	'PHRM_OPD_Credit_Sale' AS TransactionType
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
		InvoiceId AS ReferenceId
		,invoice.TotalAmount AS TotalAmount
		,CAST(invoice.CreateOn AS DATE) AS TransactionDate
		,Convert(VARCHAR(20),patient.PatientCode) + '-' + patient.ShortName + '-CLAIMCODE-'+ CONVERT(VARCHAR(20),ISNULL(invoice.ClaimCode,'')) + '-' + fy.FiscalYearFormatted+'-PH'+Convert(VARCHAR(20),invoice.InvoiceId) AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,invoice.OrganizationId
		,invoice.InvoiceId
	FROM PHRM_TXN_Invoice invoice
	JOIN ACC_Ledger_Mapping map ON map.ReferenceId = invoice.OrganizationId
	JOIN BIL_CFG_FiscalYears fy  ON invoice.FiscalYearId = fy.FiscalYearId  
	JOIN PAT_Patient patient ON invoice.PatientId = patient.PatientId
	JOIN BIL_MST_Credit_Organization org ON invoice.OrganizationId = org.OrganizationId
	WHERE CONVERT(DATE, invoice.CreateOn) = @TransactionDate
	AND invoice.PaymentMode = 'credit'
	AND map.LedgerType = 'creditorganization'
	AND org.CreditOrganizationCode <> 'MEDICARE'
	AND ISNULL(invoice.IsTransferredToACC, 0) = 0
	--AND invoice.VisitType='outpatient'
	) InnerTable
GROUP BY 
	InnerTable.OrganizationId
	,InvoiceId
	,LedgerId
	,SubLedgerId
	,TransactionDate
	,Description
END