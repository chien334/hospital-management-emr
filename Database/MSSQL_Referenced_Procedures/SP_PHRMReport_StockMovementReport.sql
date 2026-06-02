CREATE PROCEDURE [dbo].[SP_PHRMReport_StockMovementReport]
	     @ItemName varchar(200) = null
AS
/*
FileName: [SP_PHRMReport_StockMovementReport]
CreatedBy/date: Umed/2018-02-21
Description: To get the Details Such As PurchaseQty,PurchaseRate, PurchaseValue, SalesQty,SalesRate, SalesVale of Each Items With Its Item Code
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2018-02-21	                 created the script
                                         (To get the Details Such As PurchaseQty,PurchaseRate, PurchaseValue, SalesQty,SalesRate, SalesVale of Each Items With Its Item Code)

*/

BEGIN

 IF (@ItemName IS NOT NULL)
	 BEGIN
		
			SELECT (Cast(ROW_NUMBER() OVER (ORDER BY  x.ItemCode)  as int)) as SN,
				   x.ItemName,x.ItemCode,PurchaseQty,PurchaseRate,PurchaseValue,SalesQty,SalesRate ,SalesValue 
			FROM 
				(
				  Select t1.ItemName, itm.ItemCode, Sum(ReceivedQuantity) as PurchaseQty, t1.GRItemPrice AS PurchaseRate ,Sum((GRItemPrice* ReceivedQuantity)) as PurchaseValue
				  From PHRM_GoodsReceiptItems t1
				  inner join PHRM_MST_Item itm on itm.ItemId= t1.ItemId
				  group by t1.ItemName,itm.ItemCode,t1.GRItemPrice
				) AS X
			FULL OUTER JOIN 
				(
				  Select t2.ItemName,itm.ItemCode,  Sum(Quantity) as SalesQty , Price as SalesRate ,Sum((Price* Quantity)) as SalesValue
				  From PHRM_TXN_InvoiceItems t2
				  inner join PHRM_MST_Item itm on itm.ItemId= t2.ItemId
				  group by t2.ItemName,itm.ItemCode,Price 
				) AS Y
			  ON x.ItemName = y.ItemName
			 where x.ItemName  like '%'+ISNULL(@ItemName,'')+'%' 
	 END
End