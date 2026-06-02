CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetSettlementTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetSettlementTransactions '2023-06-20',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/20th June 23                Initial Draft of SP to get Pharmacy Settlement Transactions.
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
	,0 AS DrCr
	,'PHRM_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		SettlementId AS ReferenceId
		,'PHRM_Settlement' AS TransactionType
		,settlement.CollectionFromReceivable AS TotalAmount
		,CAST(settlement.SettlementDate AS DATE) AS TransactionDate
		,'PHRM-Credit Invoices Settled On ' + CONVERT(VARCHAR(100), CAST(settlement.CreatedOn AS DATE)) AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
	FROM BIL_TXN_Settlements settlement
	JOIN ACC_Ledger_Mapping map ON settlement.OrganizationId = map.ReferenceId
		WHERE Convert(DATE, settlement.SettlementDate) = @TransactionDate
	AND ISNULL(settlement.IsSyncToAcc,0) = 0 
	AND map.LedgerType = 'creditorganization'
	AND settlement.ModuleName='Dispensary'
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END