CREATE PROCEDURE [dbo].[SP_Report_Inventory_PurchaseItemsReport] 
	 @FromDate DATE = NULL
	,@ToDate DATE = NULL
	,@FiscalYearId INT = NULL
	,@ItemId INT = NULL
AS
/*
 FileName: [SP_Report_Inventory_PurchaseItemsReport] 
 Created: 9th Sep 2020/VIKAS
 Description: To Get the summary of inventory purchase report
 Remarks: 
 Change History
 S.No.    Date/User              Change          Remarks
 1.		VIKAS:10th Sep2020		Sp for purchase items summary
 2.		NageshBB: 17 sep 2020	updated column list and remove unwanted code, excluing cancel gr
 3.		Rohit/9Jun'22			SP modified to get purchase details with ItemId(before this list of item are checking)
*/
BEGIN
	SELECT CONVERT(DATE, gr.GoodsReceiptDate) AS 'Dates'
		,gr.GoodsReceiptNo
		,v.VendorName
		,sb.SubCategoryName
		,itm.ItemName
		,(gritm.ReceivedQuantity + gritm.FreeQuantity) AS 'TotalQty'
		,gritm.ItemRate
		,gritm.SubTotal
		,gritm.DiscountAmount
		,gritm.VATAmount
		,gritm.TotalAmount
		,gritm.MRP
		,gritm.ItemId
		,itm.ItemType
		,Case
				WHEN gritm.BatchNO IS NOT NULL THEN Concat(gritm.GRItemSpecification,'/'+gritm.BatchNO)
				ELSE gritm.GRItemSpecification
		END 'GRItemSpecification'
		,gr.BillNo
	FROM INV_TXN_GoodsReceipt gr
	JOIN INV_TXN_GoodsReceiptItems gritm ON gr.GoodsReceiptID = gritm.GoodsReceiptId
	JOIN INV_MST_Item itm ON gritm.ItemId = itm.ItemId
	JOIN INV_MST_Vendor v ON v.VendorId = gr.VendorId
	JOIN INV_MST_ItemSubCategory sb ON itm.SubCategoryId = sb.SubCategoryId
	WHERE (
			CONVERT(DATE, gr.GoodsReceiptDate) BETWEEN CONVERT(DATE, @FromDate)
				AND CONVERT(DATE, @ToDate)
			)
		AND gr.IsCancel != 1
		AND (
			itm.ItemId = @ItemId
			OR @ItemId IS NULL
			)
END