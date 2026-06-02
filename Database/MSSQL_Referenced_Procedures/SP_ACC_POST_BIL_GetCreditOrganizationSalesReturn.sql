CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_GetCreditOrganizationSalesReturn]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_GetCreditOrganizationSalesReturn '2023-10-10',3

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/13th June 23                Initial Draft of SP to get Billing Credit Sales Return Detail.
2.                 DevN/12th Oct 23                 Get BillReturnInvoice Amount for Co-payment scenerio.
*/
BEGIN
SELECT 
	'BIL_Credit_SaleReturn' AS TransactionType
	,ISNULL(InnerTable.LedgerId,0) AS LedgerId
	,ISNULL(InnerTable.SubLedgerId,0) AS SubLedgerId
	,InnerTable.SubTotal AS TotalAmount
	,InnerTable.ReferenceId AS ReferenceIdCSV
	,InnerTable.TransactionDate AS TransactionDate
	,InnerTable.Description
	,1 AS DisplaySequence
	,0 AS DrCr
	,'BIL_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		STRING_AGG(CONVERT(VARCHAR(MAX),BillReturnItemId), ',') 'ReferenceId'
		,CASE WHEN txn.ReturnCreditAmount > 0 THEN txn.ReturnCreditAmount ELSE txn.TotalAmount END AS 'SubTotal'
		,CAST(txn.CreatedOn AS DATE) 'TransactionDate'
		,'Credit sale return ON - '+CONVERT(VARCHAR(100), CAST(txn.CreatedOn AS DATE)) AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,txn.OrganizationId
		FROM 
		BIL_TXN_InvoiceReturn txn 
		JOIN BIL_TXN_InvoiceReturnItems items ON txn.BillReturnId = items.BillReturnId 
	JOIN ACC_Ledger_Mapping map ON map.ReferenceId = txn.OrganizationId
	JOIN BIL_CFG_FiscalYears fy  ON txn.FiscalYearId = fy.FiscalYearId  
	JOIN PAT_Patient patient ON txn.PatientId = patient.PatientId
	JOIN BIL_MST_Credit_Organization org ON txn.OrganizationId = org.OrganizationId
	WHERE Convert(DATE, txn.CreatedOn) = @TransactionDate
	AND txn.BillingTransactionId IS NOT NULL 
	AND txn.PaymentMode = 'credit'
	AND map.LedgerType = 'creditorganization'
	AND org.CreditOrganizationCode <> 'MEDICARE'
	AND ISNULL(items.IsCreditBillSyncToAcc, 0) = 0
	GROUP BY txn.BillReturnId,txn.CreatedOn,LedgerId,SubLedgerId,txn.OrganizationId,ReturnCreditAmount,TotalAmount
	) InnerTable
END