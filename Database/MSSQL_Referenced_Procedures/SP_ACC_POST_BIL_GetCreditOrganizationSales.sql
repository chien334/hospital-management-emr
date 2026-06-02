CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_GetCreditOrganizationSales]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_GetCreditOrganizationSales '2023-10-08',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/13th June 23                Initial Draft of SP to get Billing Credit Sales Detail.
*/
BEGIN
SELECT 
	'BIL_Credit_Sale' AS TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(CONVERT(VARCHAR(MAX),ReferenceId), ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,1 AS DrCr
	,'BIL_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		BillingTransactionItemId 'ReferenceId'
		,CASE WHEN itm.CoPaymentCreditAmount > 0 THEN itm.CoPaymentCreditAmount
			ELSE itm.TotalAmount END AS TotalAmount
		,CAST(txn.CreatedOn AS DATE) 'TransactionDate'
		,'Credit sale ON - '+CONVERT(VARCHAR(100), CAST(txn.CreatedOn AS DATE)) AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,txn.OrganizationId
	FROM BIL_TXN_BillingTransactionItems itm
	JOIN BIL_TXN_BillingTransaction txn ON itm.BillingTransactionId = txn.BillingTransactionId
	JOIN ACC_Ledger_Mapping map ON map.ReferenceId = txn.OrganizationId
	JOIN BIL_CFG_FiscalYears fy  ON txn.FiscalYearId = fy.FiscalYearId  
	JOIN PAT_Patient patient ON txn.PatientId = patient.PatientId
	JOIN BIL_MST_Credit_Organization org ON txn.OrganizationId = org.OrganizationId
	WHERE Convert(DATE, txn.CreatedOn) = @TransactionDate
	AND itm.BillingTransactionId IS NOT NULL 
	AND txn.PaymentMode = 'credit'
	AND map.LedgerType = 'creditorganization'
	AND org.CreditOrganizationCode <> 'MEDICARE'
	AND ISNULL(itm.IsCreditBillSync, 0) = 0
	) InnerTable
GROUP BY 
	InnerTable.OrganizationId
	,LedgerId
	,SubLedgerId
	,TransactionDate
	,Description
END