CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_IPD_GetInpatientDeposits]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_IPD_GetInpatientDeposits '2023-06-15',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/15th June 23                Initial Draft of SP to get IPD Billing Deposit Transactions.
2.                 DevN/4th Sept 23                 Remove OutPatient/Inpatient Segregation.
*/
BEGIN
    DECLARE @EmptyTable TABLE (
        Name NVARCHAR(255)
    );

    -- Return the empty table
    SELECT * FROM @EmptyTable;
--Body of this SP has been commented because we are removing outpatient/inpatient segregation..
/*SELECT 
	TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL((SELECT SubLedgerId FROM ACC_MST_SubLedger WHERE LedgerId= InnerTable.LedgerId AND SubLedgerName ='IPD'),0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,0 AS DrCr
	,'BIL_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		DepositId AS ReferenceId
		,'BIL_IPD_Deposit' AS TransactionType
		,deposit.InAmount AS TotalAmount
		,CAST(deposit.CreatedOn AS DATE) AS TransactionDate
		,'IPD Deposit Collection for ' + CONVERT(VARCHAR(100), CAST(deposit.CreatedOn AS DATE)) AS Description
		,(SELECT LedgerId FROM ACC_Ledger 
			WHERE Name ='LCL_PATIENT_DEPOSITS_(LIABILITY)_ADVANCE_FROM_PATIENT') AS LedgerId
	FROM BIL_TXN_Deposit deposit
		WHERE Convert(DATE, deposit.CreatedOn) = @TransactionDate
	AND deposit.ModuleName = 'Billing' 
	AND ISNULL(deposit.IsDepositSync,0) = 0 
	AND deposit.VisitType = 'inpatient'
	AND deposit.TransactionType = 'Deposit'
	) InnerTable
GROUP BY InnerTable.LedgerId
	,TransactionDate
	,Description
	,TransactionType
*/
END