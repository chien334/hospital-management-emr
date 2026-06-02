CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_GetSchemeRefundTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_GetSchemeRefundTransactions '2023-06-16',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/16th June 23                Initial Draft of SP to get Scheme Refund Transactions.
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
	,1 AS DrCr
	,'BIL_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		txn.SchemeRefundId AS ReferenceId
		,'Scheme_Refund' AS TransactionType
		,txn.RefundAmount AS TotalAmount
		,CAST(txn.CreatedOn AS DATE) AS TransactionDate
		,'Scheme Refund To: ' + patient.ShortName + ', On: ' + CONVERT(VARCHAR(100), CAST(txn.CreatedOn AS DATE)) AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,txn.SchemeId
		,txn.PatientId
	FROM BIL_TXN_SchemeRefund txn
	JOIN PAT_Patient patient ON txn.PatientId = patient.PatientId
	JOIN 
	(SELECT scheme.SchemeId,ISNULL(scheme.DefaultCreditOrganizationId,1) AS DefaultCreditOrganizationId FROM BIL_CFG_Scheme scheme) AS scheme
	ON txn.SchemeId = scheme.SchemeId
	JOIN BIL_MST_Credit_Organization org ON scheme.DefaultCreditOrganizationId = org.OrganizationId
	JOIN ACC_Ledger_Mapping map ON org.OrganizationId = map.ReferenceId

		WHERE Convert(DATE, txn.CreatedOn) = @TransactionDate
	AND ISNULL(txn.IsTransferredToAcc,0) = 0 
	AND map.LedgerType = 'creditorganization'
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,InnerTable.schemeId
	,InnerTable.PatientId
	,TransactionDate
	,Description
	,TransactionType
END