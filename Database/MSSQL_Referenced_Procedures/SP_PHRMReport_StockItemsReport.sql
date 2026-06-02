CREATE PROCEDURE [dbo].[SP_PHRMReport_StockItemsReport]  
	     @ItemName varchar(200) 
AS
/*
FileName: [SP_PHRMReport_StockItemsReport]
CreatedBy/date: Umed/2018-02-21
Description: To get the Details Such As PurchaseQty, PurchaseValue, SalesQty, SalesVale of Each Items With Its Item Code
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2018-02-21	                 created the script
                                         (get the Details Such As PurchaseQty, PurchaseValue, SalesQty, SalesVale of Each Items With Its Item Code)

*/

BEGIN

 IF (@ItemName IS NOT NULL)
 BEGIN
		
				
		SELECT (Cast(ROW_NUMBER() OVER (ORDER BY  x.ItemCode)  as int)) as SN,
			  x.ItemName,x.ItemCode,x.AvailableQuantity AS Qty,PurchaseValue,SalesValue 
	   FROM 
			(
			 Select t1.ItemName, itm.ItemCode,itm.ItemId,stk.AvailableQuantity ,Sum((GRItemPrice* ReceivedQuantity)) as PurchaseValue
			 From PHRM_GoodsReceiptItems t1
			 inner join PHRM_MST_Item itm on itm.ItemId= t1.ItemId
			 inner join PHRM_Stock stk on stk.ItemId = itm.ItemId
			 group by t1.ItemName,itm.ItemCode,itm.ItemId,stk.AvailableQuantity
			 ) AS X
		FULL OUTER JOIN 
			(
			Select t2.ItemName,itm.ItemCode,  stk.AvailableQuantity  ,Sum((Price* Quantity)) as SalesValue
		   From PHRM_TXN_InvoiceItems t2
		   inner join PHRM_MST_Item itm on itm.ItemId= t2.ItemId
		   inner join PHRM_Stock stk on stk.ItemId = itm.ItemId
		   group by t2.ItemName,itm.ItemCode,stk.AvailableQuantity
		   ) AS Y
		ON x.ItemName = y.ItemName
		where x.ItemName  like '%'+ISNULL(@ItemName,'')+'%' 

END

End