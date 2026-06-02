CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetSettlementDiscountTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetSettlementDiscountTransactions '2023-06-20',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/20th June 23                Initial Draft of SP to get Pharmacy Settlement Discount Transactions.
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
	,'PHRM_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		SettlementId AS ReferenceId
		,'PHRM_Settlement_Discount' AS TransactionType
		,settlement.DiscountAmount AS TotalAmount
		,CAST(settlement.SettlementDate AS DATE) AS TransactionDate
		,'Free and Concession given during settlement on ' + CONVERT(VARCHAR(100), CAST(settlement.CreatedOn AS DATE)) AS Description
		,(
			SELECT LedgerId
			FROM ACC_Ledger
			WHERE Name = 'EIE_ADMINISTRATION_EXPENSES_TRADE_DISCOUNT'
			) AS LedgerId
		,0 AS SubLedgerId
	FROM BIL_TXN_Settlements settlement
		WHERE Convert(DATE, settlement.SettlementDate) = @TransactionDate
	AND ISNULL(settlement.IsSyncToAcc,0) = 0 
	AND settlement.DiscountAmount > 0
	AND settlement.ModuleName='Dispensary'
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END