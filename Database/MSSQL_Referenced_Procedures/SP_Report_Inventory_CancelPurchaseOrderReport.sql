CREATE PROCEDURE [dbo].[SP_Report_Inventory_CancelPurchaseOrderReport] 
@FromDate DateTime=null,
@ToDate DateTime=null

AS
/*
FileName: [SP_Report_Inventory_CancelPurchaseOrderReport] '2022-09-07','2022-09-07'
CreatedBy/date: Shankar/2019-09-26
Description: report for cancelled PO in inventory
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		NageshBB/13 Sep 2020			column list updated for cancel po
2.		Rusha/07th Sep 2022				Reflect employee name in Cancelledby and formatted date
*/
BEGIN
--PO Id, PO-Date, VendorName, TotalAmount, CancelledDate, CancelledBy, CancelRemarks
		If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL or LEN(@FromDate)>=0 OR LEN(@ToDate)>=0)
				BEGIN
					SELECT  
					po.PurchaseOrderId,
					po.PoDate as PoDate,							
					v.VendorName,							
					po.TotalAmount,
					po.CancelledOn,
					empCancel.FullName as 'CancelledBy',
					po.CancelRemarks
					FROM    INV_TXN_PurchaseOrder po
					INNER JOIN INV_MST_Vendor v on v.VendorId = po.VendorId	
					INNER JOIN EMP_Employee empCancel on empCancel.EmployeeId = po.CancelledBy
				    WHERE 
					CONVERT(date,po.CancelledOn) BETWEEN ISNULL(@FromDate,GETDATE()) and ISNULL(@ToDate,GETDATE())
			     	and po.IsCancel = 1							
				END
END