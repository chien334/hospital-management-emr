CREATE PROCEDURE [dbo].[SP_InventoryDashboardStatistics] 
@SourceStoreId INT = NULL
AS
/*
FileName: [SP_InventoryDashboardStatistics]
CreatedBy/date: ROHIT/2Dec'22
Description: to get dashboard statistics of the home dashboards. these are used to fill labels.
Remarks:  
NOTE:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1       ROHIT/2Dec'22               created
2.		ROHIT/13Dec'22				ReceivedBy Not Null is checked for GoodReceipt
*/
BEGIN
	SELECT TotalPurchaseRequestQuantity
		,TotalPurchaseRequestQuantityToday
		,TotalPurchaseRequestQuantityYesterday
		,TotalPurchaseOrderQuantity
		,TotalPurchaseOrderQuantityToday
		,TotalPurchaseOrderQuantityYesterday
		,TotalGoodReceiptQuantity
		,TotalGoodReceiptQuantityToday
		,TotalGoodReceiptQuantityYesterday
		,TotalDispatchQuantity
		,TotalDispatchQuantityToday
		,TotalDispatchQuantityYesterday
	FROM (
		SELECT ROUND(ISNULL(SUM(pri.RequestedQuantity), 0), 3) 'TotalPurchaseRequestQuantity'
		FROM INV_TXN_PurchaseRequest pr
		INNER JOIN INV_TXN_PurchaseRequestItems pri ON pr.PurchaseRequestId = pri.PurchaseRequestId
		WHERE (
				pr.StoreId = @SourceStoreId
				OR @SourceStoreId IS NULL
				)
				AND pr.RequestStatus != 'withdrawn'
		) pr_Total
		,(
			SELECT ROUND(ISNULL(SUM(pri.RequestedQuantity), 0), 3) 'TotalPurchaseRequestQuantityToday'
			FROM INV_TXN_PurchaseRequest pr
			INNER JOIN INV_TXN_PurchaseRequestItems pri ON pr.PurchaseRequestId = pri.PurchaseRequestId
			WHERE (
					pr.StoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
					AND pr.RequestStatus != 'withdrawn'
				AND CONVERT(DATE, pr.RequestDate) = CONVERT(DATE, GETDATE())
			) pr_Today
		,(
			SELECT ROUND(ISNULL(SUM(pri.RequestedQuantity), 0), 3) 'TotalPurchaseRequestQuantityYesterday'
			FROM INV_TXN_PurchaseRequest pr
			INNER JOIN INV_TXN_PurchaseRequestItems pri ON pr.PurchaseRequestId = pri.PurchaseRequestId
			WHERE (
					pr.StoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
					AND pr.RequestStatus != 'withdrawn'
				AND CONVERT(DATE, pr.RequestDate) = DATEADD(DAY, - 1, CONVERT(DATE, GETDATE()))
			) pr_Yesterday
		,(
			SELECT ROUND(ISNULL(SUM(poi.Quantity), 0), 3) 'TotalPurchaseOrderQuantity'
			FROM INV_TXN_PurchaseOrder po
			INNER JOIN INV_TXN_PurchaseOrderItems poi ON po.PurchaseOrderId = poi.PurchaseOrderId
			WHERE poi.IsActive != 0
				AND (
					StoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
			) po
		,(
			SELECT ROUND(ISNULL(SUM(poi.Quantity), 0), 3) 'TotalPurchaseOrderQuantityToday'
			FROM INV_TXN_PurchaseOrder po
			INNER JOIN INV_TXN_PurchaseOrderItems poi ON po.PurchaseOrderId = poi.PurchaseOrderId
			WHERE poi.IsActive != 0
				AND CONVERT(DATE, po.CreatedOn) = CONVERT(DATE, GETDATE())
				AND (
					StoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
			) po_Today
		,(
			SELECT ROUND(ISNULL(SUM(poi.Quantity), 0), 3) 'TotalPurchaseOrderQuantityYesterday'
			FROM INV_TXN_PurchaseOrder po
			INNER JOIN INV_TXN_PurchaseOrderItems poi ON po.PurchaseOrderId = poi.PurchaseOrderId
			WHERE poi.IsActive != 0
				AND CONVERT(DATE, po.CreatedOn) = DATEADD(DAY, - 1, CONVERT(DATE, GETDATE()))
				AND (
					StoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
			) po_Yesterday
		,(
			SELECT ROUND(ISNULL(SUM(gri.ReceivedQuantity + gri.FreeQuantity), 0), 3) 'TotalGoodReceiptQuantity'
			FROM INV_TXN_GoodsReceipt gr
			INNER JOIN INV_TXN_GoodsReceiptItems gri ON gr.GoodsReceiptID = gri.GoodsReceiptId
			WHERE gri.IsActive != 0 AND gr.ReceivedBy IS NOT NULL
			AND gr.IsCancel!=1
				AND (
					StoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
			) gr
		,(
			SELECT ROUND(ISNULL(SUM(gri.ReceivedQuantity + gri.FreeQuantity), 0), 3) 'TotalGoodReceiptQuantityToday'
			FROM INV_TXN_GoodsReceipt gr
			INNER JOIN INV_TXN_GoodsReceiptItems gri ON gr.GoodsReceiptID = gri.GoodsReceiptId
			WHERE gri.IsActive != 0 AND gr.ReceivedBy IS NOT NULL
				AND gr.IsCancel!=1
				AND CONVERT(DATE, gr.ReceivedOn) = CONVERT(DATE, GETDATE())
				AND (
					StoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
			) gr_Today
		,(
			SELECT ROUND(ISNULL(SUM(gri.ReceivedQuantity + gri.FreeQuantity), 0), 3) 'TotalGoodReceiptQuantityYesterday'
			FROM INV_TXN_GoodsReceipt gr
			INNER JOIN INV_TXN_GoodsReceiptItems gri ON gr.GoodsReceiptID = gri.GoodsReceiptId
			WHERE gri.IsActive != 0 AND gr.ReceivedBy IS NOT NULL
				AND gr.IsCancel!=1
				AND CONVERT(DATE, gr.ReceivedOn) = DATEADD(DAY, - 1, CONVERT(DATE, GETDATE()))
				AND (
					StoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
			) gr_Yesterday
		,(
			SELECT ROUND(ISNULL(SUM(di.DispatchedQuantity), 0), 3) 'TotalDispatchQuantity'
			FROM INV_TXN_DispatchItems di
			WHERE (
					SourceStoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
			) dispatch
		,(
			SELECT ROUND(ISNULL(SUM(di.DispatchedQuantity), 0), 3) 'TotalDispatchQuantityToday'
			FROM INV_TXN_DispatchItems di
			WHERE (
					SourceStoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
				AND CONVERT(DATE, DispatchedDate) = CONVERT(DATE, GETDATE())
			) dispatch_Today
		,(
			SELECT ROUND(ISNULL(SUM(di.DispatchedQuantity), 0), 3) 'TotalDispatchQuantityYesterday'
			FROM INV_TXN_DispatchItems di
			WHERE (
					SourceStoreId = @SourceStoreId
					OR @SourceStoreId IS NULL
					)
				AND CONVERT(DATE, DispatchedDate) = DATEADD(DAY, - 1, CONVERT(DATE, GETDATE()))
			) dispatch_Yesterday
END