CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_OPD_GetOutpatientSalesReturn]
	 @TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_OPD_GetOutpatientSalesReturn '2023-06-15',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/13th June 23                Initial Draft of SP to get OPD Billing Sale Return.
2.                 DevN/4th Sept 23                 Remove OutPatient/Inpatient Segregation.
*/
BEGIN
	SELECT TransactionType
		,ISNULL(LedgerId, 0) AS LedgerId
		,ISNULL(SubLedgerId, 0) AS SubLedgerId
		,SUM(SubTotal) AS TotalAmount
		,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
		,TransactionDate AS TransactionDate
		,Description
		,1 AS DisplaySequence
		,1 AS DrCr
		,'BIL_Income_Voucher' AS BaseTransactionType
		,1 AS TransactionRefNo
	FROM (
		SELECT itm.BillReturnItemId AS ReferenceId
			,'BIL_OPD_SaleReturn' TransactionType
			,itm.RetSubTotal AS 'SubTotal'
			,CAST(itm.CreatedOn AS DATE) 'TransactionDate'
			,'Service Sale Refund for ' + CONVERT(VARCHAR(100), CAST(itm.CreatedOn AS DATE)) AS Description
			,(
				SELECT dbo.FN_ACC_GetIncomeLedgerId(ServiceDepartmentId, ServiceItemId, @HospitalId, 'outpatient')
				) AS LedgerId
			,(
				SELECT dbo.[FN_ACC_GetIncomeSubLedgerId](ServiceDepartmentId, ServiceItemId, @HospitalId, 'outpatient')
				) AS SubLedgerId
		FROM BIL_TXN_InvoiceReturnItems itm
		JOIN BIL_TXN_InvoiceReturn txn ON itm.BillReturnId = txn.BillReturnId
		WHERE txn.BillReturnId = itm.BillReturnId AND Convert(DATE, txn.CreatedOn) = @TransactionDate AND ISNULL(itm.IsCashBillSyncToAcc, 0) = 0
		--AND itm.BillingType = 'outpatient'
		) InnerTable
	GROUP BY InnerTable.LedgerId
		,InnerTable.SubLedgerId
		,TransactionDate
		,Description
		,TransactionType
END