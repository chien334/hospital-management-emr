CREATE PROCEDURE [dbo].[SP_ACC_POST_INV_GetGoodReceiptPurchaseTransactions]
	@TransactionDate DATE
	,@HospitalId INT
AS
/*
 exec SP_ACC_POST_INV_GetGoodReceiptPurchaseTransactions '2023-06-22',1
 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/22th June 23                Initial Draft of SP to get inventory good receipt (purchase) Transactions.
2.                 DevN/29th Oct 23                 Include VatAmount depending on Parameter whether hospital is vatregistered or not.
*/
BEGIN
Declare @VatParam VARCHAR(10),@IsVatRegistered BIT
Set @VatParam = (SELECT ParameterValue 
                                 FROM CORE_CFG_Parameters 
								 WHERE ParameterGroupName ='Accounting' and ParameterName='VatRegisteredHospital');
SET @IsVatRegistered = IIF(@VatParam = 'true', 1, 0)
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
	,'INV_Purchase' AS BaseTransactionType
	,GoodsReceiptID AS TransactionRefNo
FROM (
	SELECT 
		GoodsReceiptID AS ReferenceId
		,'INV_GoodReceipt_Purchase' AS TransactionType
		,CASE WHEN @IsVatRegistered = 1 THEN (gr.TotalAmount - gr.VATTotal) ELSE gr.TotalAmount END AS TotalAmount
		,CAST(gr.CreatedOn AS DATE) AS TransactionDate
		,'Inventory GRN: ' + CONVERT(VARCHAR(30),gr.GoodsReceiptNo) +' for-' + CONVERT(VARCHAR(100), CAST(gr.GoodsReceiptDate AS DATE)) + '/' + UPPER(gr.PaymentMode) +' Purchase.' AS Description
		,(select LedgerId from ACC_Ledger where Name='ACA_MERCHANDISE_INVENTORYMERCHANDISE_INVENTORY') AS LedgerId
		,0 AS SubLedgerId
		,gr.GoodsReceiptID
	FROM INV_TXN_GoodsReceipt gr
		WHERE Convert(DATE, gr.GoodsReceiptDate) = @TransactionDate
	AND ISNULL(gr.IsTransferredToACC,0) = 0 
	AND gr.IsCancel != 1
	) InnerTable
GROUP BY InnerTable.LedgerId
	,InnerTable.SubLedgerId
	,TransactionDate
	,Description
	,TransactionType
	,InnerTable.GoodsReceiptID
END