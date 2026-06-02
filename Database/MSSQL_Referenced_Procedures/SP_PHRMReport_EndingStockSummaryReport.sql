CREATE PROCEDURE [dbo].[SP_PHRMReport_EndingStockSummaryReport]  
	     @ItemName varchar(200) = null
		 
AS
/*
FileName: [SP_PHRMReport_EndingStockSummaryReport]
CreatedBy/date: Umed/2018-02-22
Description: To get the Details Such As ItemName, ItemCode, AvailableQty, PurchaseRate, PurchaseValue, of Each Item Selected By User on that ItemPrice
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2018-02-22	                 created the script
                                    (To get the Details Such As ItemName, ItemCode, AvailableQty, PurchaseRate, PurchaseValue, of Each Item Selected By User on that ItemPrice)
2       Umed/2018-02-23             Modified SP i.e Added Batch No 
*/

BEGIN

 IF (@ItemName IS NOT NULL)
	 BEGIN
		
			Select (Cast(ROW_NUMBER() OVER (ORDER BY  t1.ItemName)  as int)) as SN, 
			      t1.ItemName, itm.ItemCode, t1.AvailableQuantity as Quantity, t1.BatchNo, t1.GRItemPrice AS PurchaseRate ,
				   (t1.AvailableQuantity*t1.GRItemPrice) as PurchaseValue
				  From PHRM_GoodsReceiptItems t1
				  inner join PHRM_MST_Item itm on itm.ItemId= t1.ItemId
				  inner join PHRM_Stock stk on stk.ItemId = itm.ItemId
				   where t1.ItemName  like '%'+ISNULL(@ItemName,'')+'%'  
				  group by t1.ItemName,itm.ItemCode,t1.BatchNo, t1.GRItemPrice,t1.AvailableQuantity
			     
			       
	 END
End