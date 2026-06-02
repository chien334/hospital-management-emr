CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetDiscounts]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetDiscounts '2023-06-18',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/18th June 23                Initial Draft of SP to get Pharmacy sale Discount Detail.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(DiscountAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,1 AS DrCr
	,'PHRM_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		InvoiceId 'ReferenceId'
		,'PHRM_Discount' TransactionType
		,invoice.DiscountAmount AS DiscountAmount
		,CONVERT(DATE, invoice.CreateOn)  AS TransactionDate
		,'Free and concession given for ' + CONVERT(VARCHAR(100),CAST(invoice.CreateOn AS DATE)) AS Description
		,(
			SELECT LedgerId
			FROM ACC_Ledger
			WHERE Name = 'EIE_ADMINISTRATION_EXPENSES_TRADE_DISCOUNT'
			) AS LedgerId
		,0 AS SubLedgerId
	FROM PHRM_TXN_Invoice invoice
	WHERE CONVERT(DATE,invoice.CreateOn) = @TransactionDate
	AND (ISNULL(invoice.IsTransferredToACC, 0) = 0)
	AND invoice.DiscountAmount > 0
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
END