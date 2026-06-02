CREATE PROCEDURE [dbo].SP_ACC_POST_BIL_GetInternalCreditOrganizationSalesReturn
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_GetInternalCreditOrganizationSalesReturn '2023-06-14',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/13th June 23                Initial Draft of SP to get Billing Credit Sales Return INTERNAL(Medicare) Detail.
*/
BEGIN
SELECT 
	'BIL_Credit_SaleReturn' AS TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(SubTotal) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,0 AS DrCr
	,'BIL_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		BillingTransactionItemId 'ReferenceId'
		,ReturnCreditAmount AS 'SubTotal'
		,CAST(itm.CreatedOn AS DATE) 'TransactionDate'
		,'STAFF MEDICARE -' + CONVERT(VARCHAR(100), CAST(itm.CreatedOn AS DATE)) AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,BTxn.OrganizationId
		,txn.BillingTransactionId
		FROM BIL_TXN_InvoiceReturnItems itm
		JOIN BIL_TXN_InvoiceReturn txn ON itm.BillReturnId = txn.BillReturnId
		JOIN BIL_TXN_BillingTransaction BTxn ON itm.BillingTransactionId = BTxn.BillingTransactionId
	JOIN BIL_CFG_FiscalYears fy  ON txn.FiscalYearId = fy.FiscalYearId  
	JOIN INS_MedicareMember patient ON txn.PatientId = patient.PatientId
	JOIN ACC_Ledger_Mapping map ON map.ReferenceId = patient.MedicareMemberId
	JOIN BIL_MST_Credit_Organization org ON BTxn.OrganizationId = org.OrganizationId
	WHERE txn.BillingTransactionId = itm.BillingTransactionId 
	AND Convert(DATE, itm.CreatedOn) = @TransactionDate
	AND itm.BillingTransactionId IS NOT NULL 
	AND txn.PaymentMode = 'credit'
	AND map.LedgerType = 'MedicareMember'
	AND org.CreditOrganizationCode = 'MEDICARE'
	AND ISNULL(itm.IsCreditBillSyncToAcc, 0) = 0
	) InnerTable
GROUP BY 
	InnerTable.OrganizationId
	,BillingTransactionId
	,LedgerId
	,SubLedgerId
	,TransactionDate
	,Description
END