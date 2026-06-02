CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_IPD_GetInpatientSales]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_IPD_GetInpatientSales '2023-08-18',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/12th June 23                Initial Draft of SP to get IPD Billing Sales.
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
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(SubTotal) AS TotalAmount
	,STRING_AGG(CONVERT(VARCHAR(MAX),ReferenceId), ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,0 AS DrCr
	,'BIL_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		BillingTransactionItemId 'ReferenceId'
		,'BIL_IPD_Sales' TransactionType
		,itm.SubTotal AS 'SubTotal'
		,CAST(txn.CreatedOn AS DATE) 'TransactionDate'
		,'IPD Collection for ' + CONVERT(VARCHAR(100), CAST(txn.CreatedOn AS DATE)) AS Description
		,(
			SELECT dbo.FN_ACC_GetIncomeLedgerId(ServiceDepartmentId, ServiceItemId, @HospitalId,'inpatient')
			) AS LedgerId
		,(
			SELECT dbo.[FN_ACC_GetIncomeSubLedgerId](ServiceDepartmentId, ServiceItemId, @HospitalId,'inpatient')
			) AS SubLedgerId
	FROM BIL_TXN_BillingTransactionItems itm
		,BIL_TXN_BillingTransaction txn
	WHERE txn.BillingTransactionId = itm.BillingTransactionId AND Convert(DATE, txn.CreatedOn) = @TransactionDate
	AND itm.BillingTransactionId IS NOT NULL 
	AND itm.BillingType = 'inpatient' 
	AND ISNULL(itm.IsCashBillSync, 0) = 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
*/
END