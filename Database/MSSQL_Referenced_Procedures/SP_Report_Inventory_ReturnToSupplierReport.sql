/*
Change History
S.No.	UpdatedBy/Date			          Remarks
1.		Dhanashri/ 8-10-2021		 Created Script for Return to Supplier Report
*/
CREATE PROCEDURE [dbo].[SP_Report_Inventory_ReturnToSupplierReport] 
	@FromDate datetime = null,
    @ToDate datetime = null,
	@VendorId int Null = null,
	@ItemId int Null = null,
	@batchNumber nvarchar(200) Null = null,
	@goodReceiptNumber int Null = null,
	@creditNoteNumber int Null = null
AS
BEGIN
		SELECT ven.VendorName,rtv.ReturnDate,itm.ItemName,rtn.BatchNo,gr.GoodsReceiptNo,rtn.Quantity,rtn.ItemRate,
		rtn.CreditNoteNo,rtv.DiscountAmount,rtn.VAT,rtn.TotalAmount,rtn.Remark
		FROM INV_TXN_ReturnToVendorItems AS rtn
		JOIN INV_MST_Vendor AS ven ON ven.VendorId = rtn.VendorId
		JOIN INV_MST_Item AS itm ON itm.ItemId = rtn.ItemId
		JOIN INV_TXN_GoodsReceipt as gr ON gr.GoodsReceiptID = rtn.GoodsReceiptId
		left join INV_TXN_ReturnToVendor rtv on rtn.ReturnToVendorId = rtv.ReturnToVendorId
		WHERE ((CONVERT(date,rtn.CreatedOn) between ISNULL(@FromDate,GETDATE()) and ISNULL(@ToDate,GETDATE())))
		AND ((rtn.VendorId = @VendorId Or @VendorId is null)
		AND (rtn.ItemId = @ItemId Or @ItemId is null)
		AND (rtn.BatchNo = @batchNumber Or @batchNumber is null)
		AND (gr.GoodsReceiptNo = @goodReceiptNumber Or @goodReceiptNumber is null)
		AND (rtn.CreditNoteNo  = @creditNoteNumber Or @creditNoteNumber is null))
END