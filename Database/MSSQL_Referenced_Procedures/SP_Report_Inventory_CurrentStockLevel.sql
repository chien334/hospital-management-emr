CREATE PROCEDURE [dbo].[SP_Report_Inventory_CurrentStockLevel] 
@ItemName VARCHAR(max)=null 



AS
/*
FileName: [SP_Report_Inventory_CurrentStockLevel]
CreatedBy/date: Umed/2017-06-21
Description: to get Details such as Avaliable qty of stock with other data such as Min stock qty , budgeted and item rate of respective Items
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2017-06-21	                   created the script
*/

BEGIN

		If( (@ItemName IS NOT NULL) OR (LEN(@ItemName) > 0) )
				BEGIN
				         
						SELECT DISTINCT itm.ItemName,
							   SUM(stk.AvailableQuantity) AS AvailableQuantity,
								itm.MinStockQuantity,
								itm.BudgetedQuantity, 
								 gdrp.ItemRate
						 FROM INV_TXN_Stock stk
						INNER JOIN INV_MST_Item itm ON itm.ItemId = stk.ItemId 
						INNER JOIN INV_TXN_GoodsReceiptItems gdrp ON gdrp.GoodsReceiptItemId = stk.GoodsReceiptItemId
						WHERE itm.ItemName like '%'+ISNULL(@ItemName,'')+'%'
						GROUP BY itm.ItemName, itm.MinStockQuantity,itm.BudgetedQuantity,itm.StandardRate , gdrp.ItemRate
				END
        ELSE 

		     BEGIN
				         
						SELECT DISTINCT itm.ItemName,
							   SUM(stk.AvailableQuantity) AS AvailableQuantity,
								itm.MinStockQuantity,
								itm.BudgetedQuantity, 
								 gdrp.ItemRate
						 FROM INV_TXN_Stock stk
						INNER JOIN INV_MST_Item itm ON itm.ItemId = stk.ItemId 
						INNER JOIN INV_TXN_GoodsReceiptItems gdrp ON gdrp.GoodsReceiptItemId = stk.GoodsReceiptItemId
						GROUP BY itm.ItemName, itm.MinStockQuantity,itm.BudgetedQuantity,itm.StandardRate , gdrp.ItemRate
				
				END
 
END