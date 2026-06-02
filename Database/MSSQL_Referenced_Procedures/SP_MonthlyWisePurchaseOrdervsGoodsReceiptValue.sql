CREATE PROCEDURE [dbo].[SP_MonthlyWisePurchaseOrdervsGoodsReceiptValue] 
@SourceStoreId INT = NULL
AS
/*
FileName: [SP_MonthlyWisePurchaseOrdervsGoodsReceiptValue]
CreatedBy/date: ROHIT/2Dec'22
Description: To get Monthlywise Purchase Order vs GoodReceiptValue.
Remarks:
To Execute: Exec SP_MonthlyWisePurchaseOrdervsGoodsReceiptValue null
NOTE:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1       ROHIT/2Dec'22						created
2		ROHIT/7Dec'22						Round off the value up to 3 decimal

*/
BEGIN
	DECLARE @DateTimeNow DATETIME2(3) = GETDATE();
	DECLARE @DateTimeOneYearBefore DATETIME2(3) = DATEADD(YEAR, - 1, @DateTimeNow)

	SELECT purchase.TxnDisplayDate
		,PurchaseValue
		,GoodsReceiptValue
		,TotalDispatchValue
	FROM (
		SELECT CONVERT(DATETIME2(3), CONVERT(VARCHAR(4), YEAR(PoDate)) + '-' + CONVERT(VARCHAR(2), MONTH(PoDate)) + '-01') AS TxnDate
			,DATENAME(yyyy, PoDate) + '-' + SUBSTRING(DATENAME(month, PoDate), 1, 3) AS TxnDisplayDate
			,ROUND(ISNULL(SUM(TotalAmount), 0),3) AS PurchaseValue
		FROM INV_TXN_PurchaseOrder
		WHERE ISNULL(POStatus, 'cancelled') IN (
				'active'
				,'complete'
				)
			AND (
				StoreId = @SourceStoreId
				OR @SourceStoreId IS NULL
				)
			AND CONVERT(DATETIME, PoDate) >= @DateTimeOneYearBefore
		GROUP BY CONVERT(DATETIME2(3), CONVERT(VARCHAR(4), YEAR(PoDate)) + '-' + CONVERT(VARCHAR(2), MONTH(PoDate)) + '-01')
			,DATENAME(yyyy, PoDate) + '-' + SUBSTRING(DATENAME(month, PoDate), 1, 3)
		) purchase
	LEFT JOIN (
		SELECT CONVERT(DATETIME2(3), CONVERT(VARCHAR(4), YEAR(GoodsReceiptDate)) + '-' + CONVERT(VARCHAR(2), MONTH(GoodsReceiptDate)) + '-01') TxnDate
			,DATENAME(yyyy, GoodsReceiptDate) + '-' + SUBSTRING(DATENAME(month, GoodsReceiptDate), 1, 3) AS TxnDisplayDate
			,ROUND(ISNULL(SUM(TotalAmount), 0),3) AS GoodsReceiptValue
		FROM INV_TXN_GoodsReceipt
		WHERE ReceivedBy IS NOT NULL
			AND GRStatus != 'cancelled'
			AND (
				StoreId = @SourceStoreId
				OR @SourceStoreId IS NULL
				)
			AND CONVERT(DATETIME, GoodsReceiptDate) >= @DateTimeOneYearBefore
		GROUP BY CONVERT(DATETIME2(3), CONVERT(VARCHAR(4), YEAR(GoodsReceiptDate)) + '-' + CONVERT(VARCHAR(2), MONTH(GoodsReceiptDate)) + '-01')
			,DATENAME(yyyy, GoodsReceiptDate) + '-' + SUBSTRING(DATENAME(month, GoodsReceiptDate), 1, 3)
		) goodReceipt ON purchase.TxnDate = goodReceipt.TxnDate
		AND purchase.TxnDisplayDate = goodReceipt.TxnDisplayDate
	LEFT JOIN (
		SELECT CONVERT(DATETIME2(3), CONVERT(VARCHAR(4), YEAR(DispatchedDate)) + '-' + CONVERT(VARCHAR(2), MONTH(DispatchedDate)) + '-01') TxnDate
			,DATENAME(yyyy, DispatchedDate) + '-' + SUBSTRING(DATENAME(month, DispatchedDate), 1, 3) AS TxnDisplayDate
			,ROUND(ISNULL(SUM(DispatchedQuantity * CostPrice), 0),3) AS TotalDispatchValue
		FROM INV_TXN_DispatchItems
		WHERE (
				SourceStoreId = @SourceStoreId
				OR @SourceStoreId IS NULL
				)
			AND CONVERT(DATETIME, DispatchedDate) >= @DateTimeOneYearBefore
		GROUP BY CONVERT(DATETIME2(3), CONVERT(VARCHAR(4), YEAR(DispatchedDate)) + '-' + CONVERT(VARCHAR(2), MONTH(DispatchedDate)) + '-01')
			,DATENAME(yyyy, DispatchedDate) + '-' + SUBSTRING(DATENAME(month, DispatchedDate), 1, 3)
		) dispatch ON goodReceipt.TxnDate = dispatch.TxnDate
		AND goodReceipt.TxnDisplayDate = dispatch.TxnDisplayDate
	ORDER BY purchase.TxnDate
END