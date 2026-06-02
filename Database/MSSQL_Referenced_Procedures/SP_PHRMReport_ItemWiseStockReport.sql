CREATE PROCEDURE [dbo].[SP_PHRMReport_ItemWiseStockReport]  
	
AS
/*
FileName: [SP_PHRMReport_ItemWiseStockReport]
CreatedBy/date: Umed/2017-11-23
Description: To get the itemwise Stock quantity with Stock Value
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2017-11-23	                     created the script
2       Umed/2017-11-28                     Modify because we have drop the stockIn table 
                                          and now available qty is get from GrItms Tables
*/

BEGIN
     SELECT  itm.ItemName,ittyp.ItemTypeName ,ISNULL(SUM(gritm.AvailableQuantity),0) AS StockQuantity ,
            ISNULL(SUM(gritm.AvailableQuantity *gritm.GRItemPrice),0) AS StockValue
	 FROM  PHRM_GoodsReceiptItems gritm 
	 INNER JOIN PHRM_MST_Item itm ON itm.ItemId = gritm.ItemId
	 INNER JOIN PHRM_MST_ItemType ittyp ON ittyp.ItemTypeId = itm.ItemTypeId
	 GROUP BY itm.ItemName,ittyp.ItemTypeName
	 
	 
End