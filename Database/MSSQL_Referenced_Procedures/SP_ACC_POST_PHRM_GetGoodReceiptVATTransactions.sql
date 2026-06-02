CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetGoodReceiptVATTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetGoodReceiptVATTransactions '2023-06-21',1
 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/21th June 23                Initial Draft of SP to get Pharmacy good receipt (VAT) Transactions.
*/
BEGIN
SELECT 
	TransactionType
	,ISNULL(LedgerId,0) AS LedgerId
	,ISNULL((SELECT TOP (1) SubLedgerId FROM ACC_MST_SubLedger WHERE LedgerId = InnerTable.LedgerId AND IsDefault = 1),0) AS SubLedgerId
	,SUM(TotalAmount) AS TotalAmount
	,STRING_AGG(ReferenceId, ',') AS ReferenceIdCSV
	,TransactionDate AS TransactionDate
	,Description
	,1 AS DisplaySequence
	,1 AS DrCr
	,'PHRM_Purchase' AS BaseTransactionType
	,GoodReceiptId AS TransactionRefNo
FROM (
	SELECT 
		GoodReceiptId AS ReferenceId
		,'PHRM_GoodReceipt_VAT' AS TransactionType
		,(gr.VATAmount) AS TotalAmount
		,CAST(gr.CreatedOn AS DATE) AS TransactionDate
		,'Pharmacy GRN: ' + CONVERT(VARCHAR(30),gr.GoodReceiptPrintId) +' for-' + CONVERT(VARCHAR(100), CAST(gr.CreatedOn AS DATE)) + '/' + UPPER(gr.TransactionType) +' Purchase.'  AS Description
		,(select LedgerId from ACC_Ledger where Name='ACA_VAT_13%_PAYABLE') AS LedgerId
		,0 AS SubLedgerId
		,gr.GoodReceiptId
	FROM PHRM_GoodsReceipt gr
		WHERE Convert(DATE, gr.CreatedOn) = @TransactionDate
	AND ISNULL(gr.IsTransferredToACC,0) = 0 
	AND gr.VATAmount > 0
	AND gr.IsCancel = 0
	--AND gr.TransactionType='credit'
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
	,InnerTable.GoodReceiptId
END