CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_OPD_GetOutpatientDepositReturns]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_OPD_GetOutpatientDepositReturns '2023-06-15',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/15th June 23                Initial Draft of SP to get OPD Billing Deposit(Return + DepositDeduct) Transactions.
2.                 DevN/4th Sept 23                 Remove OutPatient/Inpatient Segregation.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL((SELECT SubLedgerId FROM ACC_MST_SubLedger WHERE LedgerId= InnerTable.LedgerId AND SubLedgerName ='OPD'),0) AS SubLedgerId
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
		DepositId AS ReferenceId
		,'BIL_OPD_DepositAdjustment' AS TransactionType
		,deposit.OutAmount AS TotalAmount
		,CAST(deposit.CreatedOn AS DATE) AS TransactionDate
		,'Deposit Adjusted for ' + CONVERT(VARCHAR(100), CAST(deposit.CreatedOn AS DATE)) AS Description
		,(SELECT LedgerId FROM ACC_Ledger 
			WHERE Name ='LCL_PATIENT_DEPOSITS_(LIABILITY)_ADVANCE_FROM_PATIENT') AS LedgerId
	FROM BIL_TXN_Deposit deposit
		WHERE Convert(DATE, deposit.CreatedOn) = @TransactionDate
	AND deposit.ModuleName = 'Billing' 
	AND ISNULL(deposit.IsDepositSync,0) = 0 
	--AND deposit.VisitType = 'outpatient'
	AND deposit.TransactionType IN('ReturnDeposit','depositdeduct')
	) InnerTable
GROUP BY InnerTable.LedgerId
	,TransactionDate
	,Description
	,TransactionType
END