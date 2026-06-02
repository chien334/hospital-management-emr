CREATE PROCEDURE [dbo].[SP_Report_Inventory_FixedAssets]  		
	@FromDate datetime=null,
	@ToDate datetime=null		
AS
/*
FileName: [SP_Report_Inventory_FixedAssets]
CreatedBy/date: Rusha/07-05-2019
Description: To get the Details of Fixed assets goods of inventory
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks

*/

BEGIN
  IF ((@FromDate IS NOT NULL) AND (@ToDate IS NOT NULL))
		BEGIN
			DECLARE @inv_name VARCHAR(MAX);
			SET @inv_name='Inventory Store';

			SELECT x.[Date],x.[Name],x.ItemName,x.Qty,x.MRP,SUM(x.Qty * x.MRP) AS TotalAmt ,X.UOMName,X.Code
			FROM (
					SELECT 
						CONVERT(date,gritm.CreatedOn) AS [Date],
						dep.DepartmentName AS [Name],
						itm.ItemName,
						dis.DispatchedQuantity AS Qty,
						gritm.ItemRate AS MRP,
						unit.UOMName,Itm.Code
					FROM INV_TXN_Stock AS stk
						JOIN INV_TXN_GoodsReceiptItems AS gritm ON gritm.GoodsReceiptItemId = stk.GoodsReceiptItemId
						JOIN INV_TXN_DispatchItems AS dis ON stk.ItemId = dis.ItemId
						JOIN INV_MST_Item AS itm ON itm.ItemId = stk.ItemId
						JOIN MST_Department AS dep ON dep.DepartmentId = dis.DepartmentId
						left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
					WHERE 
						itm.ItemType = 'Capital Goods' AND 
						CONVERT(date, gritm.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND 
						ISNULL(@ToDate,GETDATE())+1
					GROUP BY CONVERT(date,gritm.CreatedOn),
						itm.ItemName,dep.DepartmentName,gritm.ItemRate,dis.DispatchedQuantity,unit.UOMName,Itm.Code

					UNION ALL

					SELECT  
						CONVERT(date,gritm.CreatedOn) AS [Date],
						@inv_name AS [Name],
						itm.ItemName,
						SUM(stk.AvailableQuantity) AS Qty,
						gritm.ItemRate AS MRP ,
						unit.UOMName,Itm.Code
					FROM INV_TXN_Stock AS stk
						JOIN INV_MST_Item AS itm on itm.ItemId = stk.ItemId
						JOIN INV_TXN_GoodsReceiptItems as gritm on gritm.GoodsReceiptItemId = stk.GoodsReceiptItemId					
						left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
					WHERE itm.ItemType = 'Capital Goods' AND CONVERT(date, gritm.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
					GROUP BY CONVERT(date,gritm.CreatedOn),itm.ItemName,gritm.ItemRate,unit.UOMName,Itm.Code) x
			GROUP BY x.[Date],x.[Name],x.ItemName,x.Qty,x.MRP,X.UOMName,X.Code

		END	
END