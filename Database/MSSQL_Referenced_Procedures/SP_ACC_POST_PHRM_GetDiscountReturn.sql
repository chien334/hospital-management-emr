CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetDiscountReturn]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetDiscountReturn '2023-06-19',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/19th June 23                Initial Draft of SP to get pharmacy Discount Return Detail.
*/
BEGIN
SELECT 
	'PHRM_Discount_Return' AS TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL(SubLedgerId,0) AS SubLedgerId
	,SUM(ReturnDiscountAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,0 AS DrCr
	,'PHRM_Income_Voucher' AS BaseTransactionType
	,1 AS TransactionRefNo
FROM (
	SELECT 
		InvoiceReturnId AS ReferenceId
		,DiscountAmount AS ReturnDiscountAmount
		,CAST(retInvoice.CreatedOn AS DATE) AS TransactionDate
		,'Free and concession return for ' + CONVERT(VARCHAR(100), CAST(retInvoice.CreatedOn AS DATE)) AS Description
		,(
			SELECT LedgerId
			FROM ACC_Ledger
			WHERE Name = 'EIE_ADMINISTRATION_EXPENSES_TRADE_DISCOUNT'
			) AS LedgerId
		,0 AS SubLedgerId
		FROM PHRM_TXN_InvoiceReturn retInvoice
	WHERE Convert(DATE, retInvoice.CreatedOn) = @TransactionDate
	AND ISNULL(retInvoice.IsTransferredToACC, 0) = 0 
	AND retInvoice.DiscountAmount > 0
	) InnerTable
GROUP BY 
	LedgerId
	,SubLedgerId
	,TransactionDate
	,Description
END