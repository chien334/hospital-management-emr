CREATE PROCEDURE [dbo].[SP_Report_Inventory_CancelGoodsReceiptReport]
@FromDate DateTime=null,
@ToDate DateTime=null
AS
/*
FileName: [SP_Report_Inventory_CancelGoodsReceiptReport] '2022-08-29','2022-08-29'
CreatedBy/date: Shankar/2019-09-26
Description: report for cancelled GR in inventory
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		NageshBB/13 Sep 2020			Column list updated for gr cancelled 
2.		Rusha/07th Sep 2022				Reflect employee name in Cancelledby and formatted date 
*/
BEGIN
--GR No, VendorBillDate, VendorName, BillNo, TotalAmount, CancelledDate, CancelledBy, CancelRemarks
		If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL or LEN(@FromDate)>=0 OR LEN(@ToDate)>=0)
				BEGIN
					SELECT  
					gr.GoodsReceiptID,
					gr.GoodsReceiptNo,
					CONVERT(date,gr.GoodsReceiptDate) as GoodsReceiptDate,
					v.VendorName, 
					GR.BillNo,
					gr.TotalAmount,
					gr.CancelledOn,
					empCancel.FullName as 'CancelledBy',
					gr.CancelRemarks
					FROM    INV_TXN_GoodsReceipt gr				
					INNER JOIN INV_MST_Vendor v ON v.VendorId = gr.VendorId
					INNER JOIN EMP_Employee empCancel on empCancel.EmployeeId = gr.CancelledBy
				    WHERE
					CONVERT(date,gr.CancelledOn) BETWEEN ISNULL(@FromDate,GETDATE()) and ISNULL(@ToDate,GETDATE())
			     	and gr.IsCancel = 1										
				END
	
END