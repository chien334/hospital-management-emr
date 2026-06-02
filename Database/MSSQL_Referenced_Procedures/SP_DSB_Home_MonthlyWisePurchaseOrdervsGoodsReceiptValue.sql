CREATE PROCEDURE [dbo].[SP_DSB_Home_MonthlyWisePurchaseOrdervsGoodsReceiptValue]

 @SourceStoreId INT = NULL
AS
/*
FileName: [SP_DSB_Home_MonthlyWisePurchaseOrdervsGoodsReceiptValue]
CreatedBy/date: Rajib/2022-Sept-13
Description: to get dashboard statistics of the home dashboards. these are used to fill labels.
Remarks:  
NOTE:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Rajib/2022-Sept-16               created

*/
BEGIN
IF ((@SourceStoreId IS NOT NULL) )
DECLARE @DateTimeNow DATETIME2(3) = GETDATE();
DECLARE @DateTimeOneYearBefore DATETIME2(3) = DATEADD(YEAR, -1, @DateTimeNow)

SELECT 
	--purchase.TxnDate, 
	purchase.TxnDisplayDate, 
	PurchaseValue,
	GoodsArrivalValue,
	GoodsReceiptValue
FROM
(
	SELECT 
		CONVERT(Datetime2(3), CONVERT(VARCHAR(4), YEAR(PoDate)) + '-' + CONVERT(VARCHAR(2), MONTH(PoDate)) + '-01') as TxnDate, 
		DATENAME(yyyy, PoDate) + '-' + SUBSTRING( DATENAME(month,PoDate), 1, 3) as TxnDisplayDate, 
		SUM(TotalAmount) as PurchaseValue
	FROM 
		INV_TXN_PurchaseOrder
	WHERE 
		ISNULL(POStatus,'cancelled') IN ('active', 'complete')  AND
		StoreId = @SourceStoreId
		AND CONVERT( Datetime, PoDate) >= @DateTimeOneYearBefore
	GROUP BY 
		CONVERT(Datetime2(3), CONVERT(VARCHAR(4), YEAR(PoDate)) + '-' + CONVERT(VARCHAR(2), MONTH(PoDate)) + '-01'), 
		DATENAME(yyyy, PoDate) + '-' + SUBSTRING( DATENAME(month,PoDate), 1, 3)
) purchase
 LEFT JOIN 
(
	SELECT 
		CONVERT(Datetime2(3), CONVERT(VARCHAR(4), YEAR(GoodsArrivalDate)) + '-' + CONVERT(VARCHAR(2), MONTH(GoodsArrivalDate)) + '-01') TxnDate,
		DATENAME(yyyy, GoodsArrivalDate) + '-' + SUBSTRING( DATENAME(month,GoodsArrivalDate), 1, 3) as TxnDisplayDate, 
		SUM(TotalAmount) as GoodsArrivalValue
	FROM 
		INV_TXN_GoodsReceipt
	WHERE 
		GRStatus != 'cancelled' AND
		StoreId = @SourceStoreId AND
		CONVERT( Datetime, GoodsArrivalDate) >= @DateTimeOneYearBefore
	GROUP BY 
		CONVERT(Datetime2(3), CONVERT(VARCHAR(4), YEAR(GoodsArrivalDate)) + '-' + CONVERT(VARCHAR(2), MONTH(GoodsArrivalDate)) + '-01'), 
		DATENAME(yyyy, GoodsArrivalDate) + '-' + SUBSTRING( DATENAME(month,GoodsArrivalDate), 1, 3)
)goodarrival
ON  purchase.TxnDate = goodarrival.TxnDate AND purchase.TxnDisplayDate = goodarrival.TxnDisplayDate
LEFT JOIN
(
	SELECT 
		CONVERT(Datetime2(3), CONVERT(VARCHAR(4), YEAR(GoodsReceiptDate)) + '-' + CONVERT(VARCHAR(2), MONTH(GoodsReceiptDate)) + '-01') TxnDate,
		DATENAME(yyyy, GoodsReceiptDate) + '-' + SUBSTRING( DATENAME(month,GoodsReceiptDate), 1, 3) as TxnDisplayDate, 
		SUM(TotalAmount) as GoodsReceiptValue
	FROM 
		INV_TXN_GoodsReceipt
	WHERE 
		ReceivedBy IS NOT NULL AND
		GRStatus != 'cancelled' AND
		StoreId = @SourceStoreId AND
		CONVERT( Datetime, GoodsReceiptDate) >= @DateTimeOneYearBefore
	GROUP BY 
		CONVERT(Datetime2(3), CONVERT(VARCHAR(4), YEAR(GoodsReceiptDate)) + '-' + CONVERT(VARCHAR(2), MONTH(GoodsReceiptDate)) + '-01'), 
		DATENAME(yyyy, GoodsReceiptDate) + '-' + SUBSTRING( DATENAME(month,GoodsReceiptDate), 1, 3)
) goodReceipt 
ON  purchase.TxnDate = goodReceipt.TxnDate AND purchase.TxnDisplayDate = goodReceipt.TxnDisplayDate
ORDER BY purchase.TxnDate


END