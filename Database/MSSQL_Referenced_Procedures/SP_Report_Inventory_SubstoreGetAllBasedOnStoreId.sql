CREATE PROCEDURE [dbo].[SP_Report_Inventory_SubstoreGetAllBasedOnStoreId]
  @StoreId int = null,
  @ItemId int = null
  AS
/*
 FileName: [SP_Report_Inventory_SubstoreGetAllBasedOnStoreId]
 Created: 3Mar'20 <Sanjit>
 Description: To Get All The Details of GoodRecipt of the inventory
 Remarks: 
 Change History
 S.No.    Date/User              Change          Remarks
 1.      3Mar'20/sanjit         created          
 2.      20Jul'20/Sanjesh       ItemRate Mismatch fix
 3.		10Aug'20/sanjit			updated stock value to be taken from price of stock table
*/
BEGIN
    SELECT str.StoreId, str.Name, 
		sum(stk.AvailableQuantity) 'TotalQuantity',
		sum(stk.AvailableQuantity*(Isnull(stk.Price,0))) 'TotalValue',
		ISNULL((select SUM(DispatchedQuantity)  from INV_TXN_DispatchItems),0) 'TotalConsumed'
	from INV_TXN_Stock stk
	join INV_TXN_GoodsReceiptItems gritm on gritm.GoodsReceiptItemId = stk.GoodsReceiptItemId
	join PHRM_MST_Store str on str.StoreId = 1
	WHERE	CASE
				WHEN @ItemId>0 and @ItemId = stk.ItemId THEN 1
				WHEN @StoreId>0 and @StoreId = 1 THEN 1
				WHEN @StoreId=0 and @ItemId = 0 Then 1
			END = 1
	group by str.StoreId,str.Name
UNION ALL
SELECT str.StoreId, str.Name, 
		sum(stk.AvailableQuantity) 'TotalQuantity',
		SUM(ISNULL(stk.Price,0)*stk.AvailableQuantity) 'TotalValue',
		SUM(ISNULL(consump.Quantity,0))'TotalConsumed'
	from WARD_INV_Stock stk
	join PHRM_MST_Store str on str.StoreId = stk.StoreId
	left join WARD_INV_Consumption consump on consump.StoreId = str.StoreId and consump.ItemId = stk.ItemId
	WHERE	CASE
				WHEN @ItemId>0 and @ItemId = stk.ItemId THEN 1
				WHEN @StoreId>0 and @StoreId = stk.StoreId THEN 1
				WHEN @StoreId=0 and @ItemId = 0 Then 1
			END = 1
	group by str.StoreId,str.Name

  
END