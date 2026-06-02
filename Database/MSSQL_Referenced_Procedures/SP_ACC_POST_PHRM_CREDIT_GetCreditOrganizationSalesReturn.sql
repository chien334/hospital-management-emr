CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_CREDIT_GetCreditOrganizationSalesReturn]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_CREDIT_GetCreditOrganizationSalesReturn '2023-06-19',1
 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/19th June 23                Initial Draft of SP to get Pharmacy outpatient Credit Sales return Detail(Credit Organization).
*/
BEGIN
SELECT 
	'PHRM_OPD_CREDIT_Sale_Return' AS TransactionType
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
		,retInvoice.ReturnCreditAmount AS TotalAmount
		,CAST(retInvoice.CreatedOn AS DATE) AS TransactionDate
		,Convert(VARCHAR(20),patient.PatientCode) + '-' + patient.ShortName + '-CLAIMCODE-'+ CONVERT(VARCHAR(20),ISNULL(retInvoice.ClaimCode,'')) + '-' + CONVERT(VARCHAR(100),CAST(retInvoice.CreatedOn AS DATE)) AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,retInvoice.OrganizationId
		,retInvoice.InvoiceReturnId
	FROM PHRM_TXN_InvoiceReturn retInvoice
	JOIN ACC_Ledger_Mapping map ON map.ReferenceId = retInvoice.OrganizationId
	JOIN BIL_CFG_FiscalYears fy  ON retInvoice.FiscalYearId = fy.FiscalYearId  
	JOIN PAT_Patient patient ON retInvoice.PatientId = patient.PatientId
	JOIN BIL_MST_Credit_Organization org ON retInvoice.OrganizationId = org.OrganizationId
	WHERE CONVERT(DATE, retInvoice.CreatedOn) = @TransactionDate
	AND retInvoice.PaymentMode = 'credit'
	AND map.LedgerType = 'creditorganization'
	AND org.CreditOrganizationCode <> 'MEDICARE'
	AND ISNULL(retInvoice.IsTransferredToACC, 0) = 0
	--AND retInvoice.VisitType='outpatient'
	) InnerTable
GROUP BY 
	InnerTable.OrganizationId
	,InvoiceReturnId
	,LedgerId
	,SubLedgerId
	,TransactionDate
	,Description
END