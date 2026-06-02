CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_GetInternalCreditOrganizationSales]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_GetInternalCreditOrganizationSales '2023-06-26',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/13th June 23                Initial Draft of SP to get Billing Credit Sales INTERNAL(Medicare) Detail.
*/
BEGIN
SELECT 
	'BIL_Credit_Sale' AS TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,1 AS DrCr
	,'BIL_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		BillingTransactionItemId 'ReferenceId'
		,CASE WHEN itm.IsCoPayment = 1 AND itm.CoPaymentCreditAmount > 0 THEN itm.CoPaymentCreditAmount
			ELSE itm.TotalAmount END AS TotalAmount
		,CAST(itm.CreatedOn AS DATE) 'TransactionDate'
		,'STAFF MEDICARE -' + CONVERT(VARCHAR(100), CAST(itm.CreatedOn AS DATE)) AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,txn.OrganizationId
		,txn.BillingTransactionId
	FROM BIL_TXN_BillingTransactionItems itm
	JOIN BIL_TXN_BillingTransaction txn ON itm.BillingTransactionId = txn.BillingTransactionId
	JOIN INS_MedicareMember patient ON txn.PatientId = patient.PatientId
	JOIN ACC_Ledger_Mapping map ON map.ReferenceId = patient.MedicareMemberId
	JOIN BIL_MST_Credit_Organization org ON txn.OrganizationId = org.OrganizationId
	WHERE txn.BillingTransactionId = itm.BillingTransactionId AND Convert(DATE, itm.CreatedOn) = @TransactionDate
	AND itm.BillingTransactionId IS NOT NULL 
	AND txn.PaymentMode = 'credit'
	AND map.LedgerType = 'MedicareMember'
	AND org.CreditOrganizationCode='MEDICARE'
	AND ISNULL(itm.IsCreditBillSync, 0) = 0
	) InnerTable
GROUP BY 
	InnerTable.OrganizationId
	,BillingTransactionId
	,LedgerId
	,SubLedgerId
	,TransactionDate
	,Description
END