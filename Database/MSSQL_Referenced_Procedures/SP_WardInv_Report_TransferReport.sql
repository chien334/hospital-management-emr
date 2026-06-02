CREATE PROCEDURE [dbo].[SP_WardInv_Report_TransferReport]  		
	@FromDate datetime=null,
	@ToDate datetime=null,
	@StoreId int = null
AS
/*
FileName: [SP_WardInv_Report_TransferReport]
CreatedBy/date: Rusha/06-05-2019
Description: To get the details of stock transfer from ward to inventory 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks

*/

BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL))
		BEGIN
			SELECT CONVERT(date,trans.CreatedOn) AS [Date],dep.DepartmentName,itm.ItemName,trans.Quantity,trans.Remarks, trans.CreatedBy 
			FROM WARD_INV_Transaction AS trans
			JOIN WARD_INV_Stock AS stk ON stk.StockId = trans.StockId
			JOIN MST_Department AS dep ON dep.DepartmentId = stk.DepartmentId
			JOIN INV_MST_Item AS itm ON itm.ItemId = stk.ItemId		
			WHERE stk.StoreId = @StoreId and CONVERT(date, trans.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
		END	
END