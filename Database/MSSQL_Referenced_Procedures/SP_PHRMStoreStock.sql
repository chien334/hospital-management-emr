CREATE PROCEDURE [dbo].[SP_PHRMStoreStock] @Status VARCHAR(200) = NULL
AS
/*
FileName: [SP_PHRMStore]
CreatedBy/date: Shankar/04-03-2019
Description: To get the Details of store Items
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rusha/04-08-2019						Add From and to Date for date filter
2.		Sanjit/04-09-2019						StoreName has been added.
3.      Shankar/04-15-2019                      IsActive added.
4.		Rusha/05-23-2019						Remove From and to Date for date filter and handled quantity not equals to zero
5.		Rusha/06-11-2019						Updated script
6.		Naveed/24-11-2019						Get GR CreatedOn date as Date in Store details List
7.		Ramavtar/04-Jan-2020					Filtered out Quantity > 0
8.		Sanjit/03-Jan-2020						Generic Name added.
9.      Sanjesh/19-Aug-2020                     GoodReceiptId added.
10.     Sanjesh/26-Nov-2020                     Filtered out Quantity >= 0
11.     Shankar/21-Dec-2020						GoodReceiptPrintId included
12      Rohit/13Feb'23						    MRP-> SalePrice
*/
BEGIN
	IF (@Status IS NOT NULL)
	BEGIN
		SELECT x1.ItemName
			,x1.GenericName
			,x1.BatchNo
			,x1.ExpiryDate
			,Round(x1.SalePrice, 2, 0) AS SalePrice
			,x1.GoodReceiptId
			,(
				SELECT CreatedOn
				FROM PHRM_GoodsReceiptItems
				WHERE GoodReceiptItemId = x1.GoodsReceiptItemId
				) AS 'Date'
			,SUM(FInQty + InQty - FOutQty - OutQty) AS 'AvailableQty'
			,x1.StoreName
			,x1.ItemId
			,x1.StoreId
			,x1.GoodsReceiptItemId
			,x1.Price
			,x1.GoodReceiptPrintId
		FROM (
			SELECT stk.ItemName
				,gen.GenericName
				,stk.BatchNo
				,stk.ExpiryDate
				,stk.SalePrice
				,stk.StoreName
				,stk.StoreId
				,stk.ItemId
				,stk.GoodsReceiptItemId
				,stk.Price
				,gritm.GoodReceiptId
				,gr.GoodReceiptPrintId
				,SUM(CASE 
						WHEN stk.InOut = 'in'
							THEN stk.Quantity
						ELSE 0
						END) AS 'InQty'
				,SUM(CASE 
						WHEN stk.InOut = 'out'
							THEN stk.Quantity
						ELSE 0
						END) AS 'OutQty'
				,SUM(CASE 
						WHEN stk.InOut = 'in'
							THEN stk.FreeQuantity
						ELSE 0
						END) AS 'FInQty'
				,SUM(CASE 
						WHEN stk.InOut = 'out'
							THEN stk.FreeQuantity
						ELSE 0
						END) AS 'FOutQty'
			FROM [dbo].[PHRM_StoreStock] AS stk
			JOIN PHRM_GoodsReceiptItems AS gritm ON gritm.GoodReceiptItemId = stk.GoodsReceiptItemId
			JOIN PHRM_GoodsReceipt AS gr ON gr.GoodReceiptId = gritm.GoodReceiptId
			JOIN PHRM_MST_Item AS itm ON stk.ItemId = itm.ItemId
			JOIN PHRM_MST_Generic gen ON itm.GenericId = gen.GenericId
			GROUP BY stk.ItemName
				,gen.GenericName
				,stk.BatchNo
				,stk.ExpiryDate
				,stk.SalePrice
				,stk.StoreName
				,stk.StoreId
				,stk.ItemId
				,stk.GoodsReceiptItemId
				,stk.Price
				,gritm.GoodReceiptId
				,gr.GoodReceiptPrintId
			) AS x1
		WHERE (
				@Status = x1.ItemName
				OR x1.ItemName LIKE '%' + ISNULL(@Status, '') + '%'
				)
		GROUP BY x1.ItemName
			,x1.GenericName
			,x1.BatchNo
			,x1.ExpiryDate
			,x1.SalePrice
			,x1.StoreName
			,x1.ItemId
			,x1.StoreId
			,x1.GoodsReceiptItemId
			,x1.Price
			,x1.GoodReceiptId
			,x1.GoodReceiptPrintId
		HAVING SUM(FInQty + InQty - FOutQty - OutQty) >= 0 -- filtering out quantity >= 0
		ORDER BY x1.ItemName
	END
END