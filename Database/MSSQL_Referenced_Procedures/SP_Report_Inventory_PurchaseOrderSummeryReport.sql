CREATE PROCEDURE [dbo].[SP_Report_Inventory_PurchaseOrderSummeryReport] 
@FromDate DateTime=NULL,
@ToDate DateTime=NULL,
@StoreId INT = NULL

AS
/*
FileName: [SP_Report_Inventory_PurchaseOrderSummeryReport]
CreatedBy/date: Umed/2017-06-23
Description: to get Details such as Item Name,Total Qty,Received qty,pending qty, with expected Due Date of delivery Between Given Date input
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2017-06-23	                   created the script
2       Shankar/2019-09-16                 Edited script to add IsCancel
3.      Dhanashri/2021-10-28               Updated as per new requirement
*/
BEGIN

	If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
		BEGIN
			SELECT 
				CONVERT(date,po.PoDate) as [Date] ,
				po.PONumber as PONumber,
				ven.VendorName,
				msitm.Code as ItemCode,
				msitm.ItemName as ItemName,
				ic.ItemCategoryName as ItemType,
				isc.SubCategoryName as SubCategory,
				poitm.Quantity as Quantity, 
				poitm.StandardRate as StandardRate,
				poitm.VATAmount as VAT, 
				poitm.TotalAmount as TotalAmount,
				CASE
					WHEN LEN(LTRIM(RTRIM(ISNULL(poitm.Remark,'')))) > 0 THEN poitm.Remark
					ELSE po.PORemark
				END as Remarks
			FROM 
				INV_TXN_PurchaseOrderItems poitm
				INNER JOIN INV_TXN_PurchaseOrder po ON poitm.PurchaseOrderId =po.PurchaseOrderId
				INNER JOIN INV_MST_Vendor AS ven ON ven.VendorId = po.VendorId
				INNER JOIN INV_MST_Item msitm ON msitm.ItemId = poitm.ItemId
				LEFT JOIN INV_MST_ItemSubCategory isc ON isc.SubCategoryId = msitm.SubCategoryId
				LEFT JOIN INV_MST_ItemCategory ic ON ic.ItemCategoryId = msitm.ItemCategoryId
			WHERE 
				CONVERT(date,po.PoDate) between @FromDate and @ToDate
				AND (po.StoreId = @StoreId Or @StoreId is null)
				-- check for po active status 
				AND ISNULL(po.IsCancel, 0) = 0 AND ISNULL(poitm.IsActive, 1) != 0 AND poitm.POItemStatus != 'cancelled'
			ORDER BY po.PoDate DESC
		END
END