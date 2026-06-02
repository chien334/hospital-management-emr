CREATE PROCEDURE [dbo].[SP_ACC_POST_PHRM_GetGoodReceiptSupplierTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_PHRM_GetGoodReceiptSupplierTransactions '2023-06-20',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/21th June 23                Initial Draft of SP to get Pharmacy  good receipt Transactions.
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
	,'PHRM_Purchase' AS BaseTransactionType
	,GoodReceiptId AS TransactionRefNo
FROM (
	SELECT 
		GoodReceiptId AS ReferenceId
		,'PHRM_GoodReceipt_Supplier' AS TransactionType
		,(gr.TotalAmount) AS TotalAmount
		,CAST(gr.CreatedOn AS DATE) AS TransactionDate
		,'PO:' + CONVERT(VARCHAR(20),ISNULL(gr.PurchaseOrderId,0)) + '('+ CONVERT(VARCHAR(100), CAST(gr.SupplierBillDate AS DATE))+')'+' / GRN: ' + CONVERT(VARCHAR(30),gr.GoodReceiptPrintId) + '(' + CONVERT(VARCHAR(100), CAST(gr.CreatedOn AS DATE)) +') /' + supplier.SupplierName + '/' + UPPER(gr.TransactionType) +' Purchase.'  AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,gr.GoodReceiptId
	FROM PHRM_GoodsReceipt gr
	JOIN ACC_Ledger_Mapping map ON gr.SupplierId = map.ReferenceId
	JOIN PHRM_MST_Supplier supplier ON gr.SupplierId = supplier.SupplierId
		WHERE Convert(DATE, gr.CreatedOn) = @TransactionDate
	AND ISNULL(gr.IsTransferredToACC,0) = 0 
	AND map.LedgerType='pharmacysupplier'
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