CREATE PROCEDURE [dbo].[SP_Report_Inventory_ComparePoAndGR]

AS
BEGIN

	BEGIN
		select ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS SNo, itm.ItemName, vendor.VendorName, pitms.CreatedOn,pitms.Quantity,(gitms.ReceivedQuantity + gitms.FreeQuantity) RecevivedQuantity, gitms.CreatedOn Receivedon, gr.GoodsReceiptID, gr.PurchaseOrderId
  	,unit.UOMName,Itm.Code
 from INV_TXN_GoodsReceipt gr
 join INV_TXN_GoodsReceiptItems gitms on gitms.GoodsReceiptId = gr.GoodsReceiptId
 join INV_TXN_PurchaseOrderItems pitms on pitms.PurchaseOrderId = gr.PurchaseOrderId 
 join INV_MST_Item itm on gitms.ItemId = itm.ItemId
 join INV_MST_Vendor vendor on vendor.VendorId = gr.VendorId
				left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
 where gitms.ItemId = pitms.ItemId and gr.IsCancel = 0
 order by gr.PurchaseOrderId desc

	END
END