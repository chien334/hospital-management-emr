CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_GetDiscounts]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_GetDiscounts '2023-07-03',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/12th June 23                Initial Draft of SP to get Discount Detail.
2.                 DevN/29th Aug 23                 STRING_AGG() function unable to hold large set of data.. 
							                        so added CONVERT(VARCHAR(MAX)) to fix it.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(DiscountAmount) AS TotalAmount
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
		,'BIL_Discount' TransactionType
		,itm.DiscountAmount AS DiscountAmount
		,CAST(CASE WHEN itm.BillingType = 'inpatient' THEN CONVERT(DATE, txn.CreatedOn) 
			ELSE CONVERT(DATE,itm.CreatedOn) END AS DATE) 'TransactionDate'
		,'Free and concession given for ' + CONVERT(VARCHAR(100), CAST(CASE WHEN itm.BillingType = 'inpatient' THEN CONVERT(DATE, txn.CreatedOn) 
			 ELSE CONVERT(DATE,itm.CreatedOn) END AS DATE)) AS Description
		,(
			SELECT LedgerId
			FROM ACC_Ledger
			WHERE Name = 'EIE_ADMINISTRATION_EXPENSES_TRADE_DISCOUNT'
			) AS LedgerId
		,0 AS SubLedgerId
	FROM BIL_TXN_BillingTransactionItems itm
		 JOIN BIL_TXN_BillingTransaction txn ON itm.BillingTransactionId = txn.BillingTransactionId
	WHERE 
	@TransactionDate =
	CASE WHEN itm.BillingType = 'inpatient' THEN CONVERT(DATE, txn.CreatedOn) 
	 ELSE CONVERT(DATE,itm.CreatedOn) END
	AND itm.BillingTransactionId IS NOT NULL 
	AND (ISNULL(itm.IsCashBillSync, 0) = 0 OR ISNULL(itm.IsCreditBillSync,0) = 0 )
	AND itm.DiscountAmount > 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END