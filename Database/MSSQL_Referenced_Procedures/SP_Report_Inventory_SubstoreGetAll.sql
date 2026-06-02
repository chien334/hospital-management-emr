CREATE PROCEDURE [dbo].[SP_Report_Inventory_SubstoreGetAll]
  @StoreId int = null,
  @ItemId int = null
  AS
/*
 FileName: SP_Report_Inventory_SubstoreGetAll
 Created: 12Dec'19 <Sanjit>
 Description: To Get All The Details of GoodRecipt of the inventory
 Remarks: 
 Change History
 S.No.    Date/User              Change          Remarks
 1.      3Mar'20/sanjit         created          
 2.		10Aug'20/sanjit			updated stock value to be taken from price of stock table
*/
BEGIN
  BEGIN
    select SUM(Z.TotalQuantity)'TotalQuantity',
	SUM(Z.TotalValue)'TotalValue',
	SUM(Z.ExpiryQuantity)'ExpiryQuantity',
	SUM(Z.ExpiryValue)'ExpiryValue' 
	from
		((select stk.ItemId, 
				sum(stk.AvailableQuantity) 'TotalQuantity',
				sum(ISNULL(stk.Price,0)*stk.AvailableQuantity) 'TotalValue',
				0 'ExpiryQuantity',
				0'ExpiryValue'
			from INV_TXN_Stock stk
			WHERE	CASE
						WHEN @ItemId>0 and @ItemId = stk.ItemId THEN 1
						WHEN @StoreId>0 and @StoreId = 1 THEN 1
						WHEN @StoreId=0 and @ItemId = 0 Then 1
					END = 1
			group by stk.ItemId)
		union all
			(select stk.ItemId, 
				0'TotalQuantity',
				0'TotalValue',
				sum(stk.AvailableQuantity) 'ExpiredQuantity',
				sum(ISNULL(stk.Price,0)*stk.AvailableQuantity) 'ExpiredValue'
			from INV_TXN_Stock stk
			where stk.ExpiryDate < GetDATE() AND	
			CASE
				WHEN @ItemId>0 and @ItemId = stk.ItemId THEN 1
				WHEN @StoreId>0 and @StoreId = 1 THEN 1
				WHEN @StoreId=0 and @ItemId = 0 Then 1
					END = 1
			group by stk.ItemId)
		union all
			(select ItemId,
				sum(AvailableQuantity) 'TotalQuantity',
				sum(ISNULL(stk.Price,0)*AvailableQuantity) 'TotalValue',
				0 'ExpiryQuantity',
				0'ExpiryValue'  
			from WARD_INV_Stock stk
			WHERE	CASE
						WHEN @ItemId>0 and @ItemId = stk.ItemId THEN 1
						WHEN @StoreId>0 and @StoreId = stk.StoreId THEN 1
						WHEN @StoreId=0 and @ItemId = 0 Then 1
					END = 1
			group by ItemId)
		union all
			(select ItemId,
				0'TotalQuantity',
				0'TotalValue',
				sum(stk.AvailableQuantity) 'ExpiryQuantity',
				sum(ISNULL(stk.Price,0)*stk.AvailableQuantity) 'ExpiryValue'  
			from WARD_INV_Stock stk
			where stk.ExpiryDate<GetDate()
			AND CASE
						WHEN @ItemId>0 and @ItemId = stk.ItemId THEN 1
						WHEN @StoreId>0 and @StoreId = stk.StoreId THEN 1
						WHEN @StoreId=0 and @ItemId = 0 Then 1
					END = 1
			group by ItemId)) 
	as Z

  END
END