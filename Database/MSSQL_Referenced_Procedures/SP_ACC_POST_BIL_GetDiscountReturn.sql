CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_GetDiscountReturn]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_GetDiscountReturn '2023-06-14',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/14th June 23                Initial Draft of SP to get Billing Discount Return Detail
*/
BEGIN
SELECT 
	'BIL_Discount_Return' AS TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(ReturnDiscountAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,0 AS DrCr
	,'BIL_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		BillReturnItemId AS ReferenceId
		,RetDiscountAmount AS ReturnDiscountAmount
		,CAST(itm.CreatedOn AS DATE) AS TransactionDate
		,'Free and concession return for ' + CONVERT(VARCHAR(100), CAST(itm.CreatedOn AS DATE)) AS Description
		,(
			SELECT LedgerId
			FROM ACC_Ledger
			WHERE Name = 'EIE_ADMINISTRATION_EXPENSES_TRADE_DISCOUNT'
			) AS LedgerId
		,0 AS SubLedgerId
		FROM BIL_TXN_InvoiceReturnItems itm
		JOIN BIL_TXN_InvoiceReturn txn ON itm.BillReturnId = txn.BillReturnId
	WHERE Convert(DATE, itm.CreatedOn) = @TransactionDate
	AND itm.BillingTransactionId IS NOT NULL 
	AND (ISNULL(itm.IsCreditBillSyncToAcc, 0) = 0 OR ISNULL(itm.IsCreditBillSyncToAcc,0) = 0)
	AND itm.RetDiscountAmount > 0
	) InnerTable
GROUP BY 
	LedgerId
	,SubLedgerId
	,TransactionDate
	,Description
END