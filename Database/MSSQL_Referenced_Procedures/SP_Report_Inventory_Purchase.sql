-- =============================================
-- Author:    <Author,,Name>
-- Create date: <Create Date,,>
-- Description:  <Description,,>
-- Shankar/2019-09-16  Edited script for IsCancel
-- Sanjit/2020-01-22   Date Format change
-- =============================================
CREATE PROCEDURE [dbo].[SP_Report_Inventory_Purchase]

AS
BEGIN

      BEGIN
            select itm.ItemName, vendor.VendorName,vendor.ContactNo,  FORMAT (pitms.CreatedOn, 'dd MMM yyyy, hh:mm tt ') as CreatedOn,(gitms.ReceivedQuantity + gitms.FreeQuantity) TotalQuantity,pitms.StandardRate, PO.TotalAmount,gr.Discount
  	,unit.UOMName,Itm.Code
 from INV_TXN_GoodsReceipt gr   
 join INV_TXN_GoodsReceiptItems gitms on gitms.GoodsReceiptId = gr.GoodsReceiptId
 join INV_TXN_PurchaseOrderItems pitms on pitms.PurchaseOrderId = gr.PurchaseOrderId 
 join INV_MST_Item itm on gitms.ItemId = itm.ItemId
 join INV_TXN_PurchaseOrder PO on PO.PurchaseOrderId = pitms.PurchaseOrderId
 join INV_MST_Vendor vendor on vendor.VendorId = gr.VendorId
left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
 where gitms.ItemId = pitms.ItemId AND gr.IsCancel = 0
 order by gr.PurchaseOrderId desc

        END
END