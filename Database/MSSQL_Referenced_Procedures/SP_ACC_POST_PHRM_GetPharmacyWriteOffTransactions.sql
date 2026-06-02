CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetPharmacyWriteOffTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetPharmacyWriteOffTransactions '2023-06-27',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/27th June 23                Initial Draft of SP to get pharmacy writeoff transactions.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(CASE WHEN DrCr = 0 THEN (SELECT LedgerId FROM ACC_Ledger WHERE Name='IOS_WARD_/_DEPARTMENT_SUPPLY')
		ELSE (SELECT LedgerId FROM ACC_Ledger WHERE Name='EHC_CONSUMABLE_:_PHARMACY') END ,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,DrCr AS DrCr
	,'PHRM_WriteOff' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		WriteOffId AS ReferenceId
		,'PHRM_WriteOffItems' AS TransactionType
		,(wr.TotalAmount) AS TotalAmount
		,CAST(wr.CreatedOn AS DATE) AS TransactionDate
		,'PHARMACY WRITE-OFF ITEMS FOR :' + '(' + CONVERT(VARCHAR(100), CAST(wr.CreatedOn AS DATE)) +')'  AS Description
		,0 AS LedgerId
		,0 AS SubLedgerId
		,CONVERT(bit, DebitCredit.value) AS DrCr
	FROM PHRM_WriteOff wr
	CROSS JOIN (
		SELECT value
		FROM STRING_SPLIT('0,1', ',')
	) AS DebitCredit
		WHERE Convert(DATE, wr.CreatedOn) = @TransactionDate
	AND ISNULL(wr.IsTransferredToACC,0) = 0 
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
	,InnerTable.DrCr
	ORDER BY InnerTable.DrCr DESC
END