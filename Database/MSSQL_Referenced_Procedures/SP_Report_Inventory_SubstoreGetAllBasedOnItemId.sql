CREATE PROCEDURE [dbo].[SP_Report_Inventory_SubstoreGetAllBasedOnItemId]
  @StoreId int = null,
  @ItemId int = null
  AS
/*
 FileName: [SP_Report_Inventory_SubstoreGetAllBasedOnItemId]
 Created: 3Mar'20 <Sanjit>
 Description: To Get All The Details of GoodRecipt of the inventory
 Remarks: 
 Change History
 S.No.    Date/User              Change          Remarks
 1.      3Mar'20/sanjit         created          
 2.		10Aug'20/sanjit			updated stock value to be taken from price of stock table
*/
BEGIN
    Select Z.ItemId,itm.ItemName,Sum(Z.TotalQuantity)'TotalQuantity',Sum(Z.TotalValue)'TotalValue',SUM(Z.TotalConsumed)'TotalConsumed'	from
	(select stk.ItemId, 
			sum(stk.AvailableQuantity) 'TotalQuantity',
			sum(ISNULL(stk.Price,0) * stk.AvailableQuantity) 'TotalValue',
			0 'TotalConsumed'
		from INV_TXN_Stock stk
		WHERE	CASE
				WHEN @ItemId>0 and @ItemId = stk.ItemId THEN 1
				WHEN @StoreId>0 and @StoreId = 1 THEN 1
				WHEN @StoreId=0 and @ItemId = 0 Then 1
			END = 1
		group by stk.ItemId
	union all
	select stk.ItemId,
			sum(AvailableQuantity) 'TotalQuantity',
			sum(ISNULL(stk.Price,0)*AvailableQuantity) 'TotalValue',
			sum(ISNULL(consump.Quantity,0)) 'TotalConsumed' 
		from WARD_INV_Stock stk
		left join WARD_INV_Consumption consump on consump.StoreId = stk.StoreId and consump.ItemId = stk.ItemId
		WHERE	CASE
					WHEN @ItemId>0 and @ItemId = stk.ItemId THEN 1
					WHEN @StoreId>0 and @StoreId = stk.StoreId THEN 1
					WHEN @StoreId=0 and @ItemId = 0 Then 1
				END = 1
		group by stk.ItemId) AS Z
join INV_MST_Item itm on itm.ItemId = Z.ItemId
group by Z.ItemId,itm.ItemName
order by SUM(Z.TotalQuantity) desc

  
END