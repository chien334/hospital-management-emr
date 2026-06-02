CREATE PROCEDURE [dbo].[SP_Report_Inventory_PurchaseSummary]
@FromDate DateTime=null,
@ToDate DateTime=null,
@VendorId int=null
AS
/*
FileName: [SP_Report_Inventory_PurchaseSummary] '2021-09-07','2021-09-14'
Example to Execute:
	EXECUTE SP_Report_Inventory_PurchaseSummary '2021-09-07','2021-09-14'
CreatedBy/date: NageshBB/16 Sep 2020
Description: get records for inventory purchase summary report
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		NageshBB/16 Sep 2020		created sp for get records for inventory purchase summary report
2.		Sanjit/14Sep21				added OtherCharges in the Report
3.		NageshBB/19 Sep 2021		changes for filter data with vendor id and add vendor bill date in result
4.      Rusha/07th Sep 2022         remove category id 
*/
BEGIN
	If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
	BEGIN
		if( ISNULL(@VendorId,0) > 0) --if vendor id is not provided then 
		BEGIN
				SELECT 			
				    gr.GoodsReceiptID,	gr.GoodsReceiptNo,	CONVERT(CHAR(16), gr.GoodsReceiptDate, 21) as GoodsReceiptDate,
					gr.PurchaseOrderId,	v.VendorName,	v.ContactNo,gr.BillNo,gr.SubTotal,gr.DiscountAmount,gr.VATTotal,
					gr.OtherCharges + (Select Sum(OtherCharge) from INV_TXN_GoodsReceiptItems WHERE GoodsReceiptID = gr.GoodsReceiptID) as OtherCharges,
					gr.TotalAmount,	gr.PaymentMode,	gr.Remarks,CONVERT(CHAR(16), gr.CreatedOn, 21) as CreatedOn,
					CONVERT(CHAR(16), gr.VendorBillDate, 21) as VendorBillDate
				FROM INV_TXN_GoodsReceipt gr
					INNER JOIN INV_MST_Vendor v ON v.VendorId=gr.VendorId
				WHERE
					CONVERT( date,gr.GoodsReceiptDate ) BETWEEN convert( date, @FromDate) and convert( date, @ToDate)
					AND gr.IsCancel !=1 and gr.VendorId =@VendorId	
						
		END
		ELSE
		BEGIN
				SELECT 			
				    gr.GoodsReceiptID,	gr.GoodsReceiptNo,	CONVERT(CHAR(16), gr.GoodsReceiptDate, 21) as GoodsReceiptDate,
					gr.PurchaseOrderId,	v.VendorName,	v.ContactNo,gr.BillNo,gr.SubTotal,gr.DiscountAmount,gr.VATTotal,
					gr.OtherCharges + (Select Sum(OtherCharge) from INV_TXN_GoodsReceiptItems WHERE GoodsReceiptID = gr.GoodsReceiptID) as OtherCharges,
					gr.TotalAmount,	gr.PaymentMode,	gr.Remarks,CONVERT(CHAR(16), gr.CreatedOn, 21) as CreatedOn,
					CONVERT(CHAR(16), gr.VendorBillDate, 21) as VendorBillDate
				FROM INV_TXN_GoodsReceipt gr
					INNER JOIN INV_MST_Vendor v ON v.VendorId=gr.VendorId
				WHERE
				     CONVERT( date,gr.GoodsReceiptDate ) BETWEEN convert( date, @FromDate) and convert( date, @ToDate)
					 AND gr.IsCancel !=1
		END
	END	
END