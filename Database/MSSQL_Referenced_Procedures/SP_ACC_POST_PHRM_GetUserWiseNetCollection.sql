CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetUserWiseNetCollection]
	@TransactionDate DATE,
	@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetUserWiseNetCollection '2023-06-18',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/18th June 23                Stored Procedure to get Userwise pharmacy cash collection for Post To Accounting.
*/
BEGIN
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
	SELECT 'PHRM_UserWiseNetCollection' AS TransactionType
		,(
			SELECT LedgerId
			FROM ACC_Ledger
			WHERE Name = 'ACA_CASH_IN_HAND_CASH'
			) AS LedgerId
		,0 AS SubLedgerId
		,ISNULL(SUM(InAmount) - SUM(OutAmount), 0) AS TotalAmount
		,STRING_AGG(CashTxnId,',') AS ReferenceIdCSV
		,CAST(TransactionDate AS DATE) AS TransactionDate
		,'PHARMACY/CASH COLLECTION ON-' + CONVERT(VARCHAR(100), CAST(TransactionDate AS DATE)) AS Description
		,1 AS DisplaySequence
		,'PHRM_Income_Voucher' AS BaseTransactionType
	FROM PHRM_EmployeeCashTransaction txn
	WHERE CONVERT(DATE, TransactionDate) = @TransactionDate 
	AND ISNULL(IsTransferredToAcc,0) = 0 
	AND TransactionType IN (
			'CashSales'
			,'Deposit'
			,'SalesReturn'
			,'ReturnDeposit'
			,'depositdeduct'
			,'CashDiscountGiven'
			,'CollectionFromReceivable'
			)
	GROUP BY CAST(TransactionDate AS DATE)
		) InnerData
END