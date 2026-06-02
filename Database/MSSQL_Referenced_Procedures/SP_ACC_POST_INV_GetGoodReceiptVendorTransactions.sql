CREATE PROCEDURE [dbo].[SP_ACC_POST_INV_GetGoodReceiptVendorTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_INV_GetGoodReceiptVendorTransactions '2023-06-22',1

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/22th June 23                 Initial Draft of SP to get inventory good receipt (Vendor Detail) Transactions.
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
	,'INV_Purchase' AS BaseTransactionType
	,GoodsReceiptID AS TransactionRefNo
FROM (
	SELECT 
		GoodsReceiptID AS ReferenceId
		,'INV_GoodReceipt_Vendor' AS TransactionType
		,(gr.TotalAmount) AS TotalAmount
		,CAST(gr.CreatedOn AS DATE) AS TransactionDate
		,'PO:' + CONVERT(VARCHAR(20),ISNULL(gr.PurchaseOrderId,0)) + '('+ CONVERT(VARCHAR(100), CAST(gr.VendorBillDate AS DATE))+')'+' / GRN: ' + CONVERT(VARCHAR(30),gr.GoodsReceiptNo) + '(' + CONVERT(VARCHAR(100), CAST(gr.CreatedOn AS DATE)) +') /' + vendor.VendorName + '/' + UPPER(gr.PaymentMode) +' Purchase.' AS Description
		,map.LedgerId AS LedgerId
		,map.SubLedgerId AS SubLedgerId
		,gr.GoodsReceiptID
	FROM INV_TXN_GoodsReceipt gr
	JOIN ACC_Ledger_Mapping map ON gr.VendorId = map.ReferenceId
	JOIN INV_MST_Vendor vendor ON gr.VendorId = vendor.VendorId
		WHERE Convert(DATE, gr.CreatedOn) = @TransactionDate
	AND ISNULL(gr.IsTransferredToACC,0) = 0 
	AND map.LedgerType='inventoryvendor'
	AND gr.IsCancel != 1
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
	,InnerTable.GoodsReceiptID
END