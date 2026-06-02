CREATE PROCEDURE [dbo].[SP_ACC_POST_BIL_GetUserWiseNetCollection]
	@TransactionDate DATE,
	@HospitalId INT
AS
/*
 exec SP_ACC_POST_BIL_GetUserWiseNetCollection '2023-06-16',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/11th June 23                Stored Procedure to get Userwise billing cash collection for Post To Accounting.
2.                 DevN/29th Oct 23                 Paymentmode wise cash collection segregation.
*/
BEGIN
SELECT * FROM (
SELECT 
	InnerData.TransactionType AS TransactionType
	,ISNULL(InnerData.LedgerId,0) AS LedgerId
	,InnerData.SubLedgerId AS SubLedgerId
	,ABS(InnerData.TotalAmount) AS TotalAmount
	,InnerData.ReferenceIdCSV AS ReferenceIdCSV
	,InnerData.TransactionDate AS TransactionDate
	,InnerData.Description AS Description
	,InnerData.DisplaySequence AS DisplaySequence
	,InnerData.BaseTransactionType AS BaseTransactionType
	,CASE WHEN InnerData.TotalAmount >= 0 THEN 1
	ELSE 0 END AS DrCr
	,1 AS TransactionRefNo
	FROM(
	SELECT 'BIL_UserWiseNetCollection' AS TransactionType
		,map.LedgerId AS LedgerId
		,ISNULL(map.SubLedgerId,0) AS SubLedgerId
		,ISNULL(SUM(InAmount) - SUM(OutAmount), 0) AS TotalAmount
		,STRING_AGG(CONVERT(VARCHAR(MAX),CashTxnId),',') AS ReferenceIdCSV
		,CAST(TransactionDate AS DATE) AS TransactionDate
		,'BILLING/CASH COLLECTION ON-' + CONVERT(VARCHAR(100), CAST(TransactionDate AS DATE)) AS Description
		,1 AS DisplaySequence
		,'BIL_Income_Voucher' AS BaseTransactionType
	FROM TXN_EmpCashTransaction txn
	JOIN ACC_Ledger_Mapping map ON txn.PaymentModeSubCategoryId = map.ReferenceId
	WHERE CONVERT(DATE, TransactionDate) = @TransactionDate
	AND map.LedgerType = 'paymentmodes'
	AND IsTransferredToAcc = 0 AND TransactionType IN (
			'CashSales'
			,'Deposit'
			,'SalesReturn'
			,'ReturnDeposit'
			,'depositdeduct'
			,'CashDiscountGiven'
			,'CollectionFromReceivable'
			,'SchemeRefund'
			)
	GROUP BY CAST(TransactionDate AS DATE),LedgerId,SubLedgerId
		) InnerData
		) GroupedData WHERE GroupedData.TotalAmount > 0
END