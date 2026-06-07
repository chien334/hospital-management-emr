CREATE OR REPLACE FUNCTION sp_phrmstorestock(
    p_status VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "ItemName" VARCHAR,
    "GenericName" VARCHAR,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "SalePrice" DECIMAL,
    "GoodReceiptId" INT,
    "Date" TIMESTAMP,
    "AvailableQty" INT,
    "StoreName" VARCHAR,
    "ItemId" INT,
    "StoreId" INT,
    "GoodsReceiptItemId" INT,
    "Price" DECIMAL,
    "GoodReceiptPrintId" INT
) AS $$
BEGIN
    /*
    filename: "sp_phrmstore"
    createdby/date: shankar/04-03-2019
    description: to get the details of store items
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/04-08-2019						add from and to date for date filter
    2.		sanjit/04-09-2019						storename has been added.
    3.      shankar/04-15-2019                      isactive added.
    4.		rusha/05-23-2019						remove from and to date for date filter and handled quantity not equals to zero
    5.		rusha/06-11-2019						updated script
    6.		naveed/24-11-2019						get gr createdon date AS "Date" in store details list
    7.		ramavtar/04-jan-2020					filtered out quantity > 0
    8.		sanjit/03-jan-2020						generic name added.
    9.      sanjesh/19-aug-2020                     goodreceiptid added.
    10.     sanjesh/26-nov-2020                     filtered out quantity >= 0
    11.     shankar/21-dec-2020						goodreceiptprintid included
    12      rohit/13feb'23						    MRP-> SalePrice
    */
    BEGIN
    	IF (p_status IS NOT NULL)
    	THEN
    		RETURN QUERY SELECT x1.ItemName
    			,x1.GenericName
    			,x1.BatchNo
    			,x1.ExpiryDate
    			,Round(x1.SalePrice, 2, 0) AS "SalePrice"
    			,x1.GoodReceiptId
    			,(
    				SELECT CreatedOn
    				FROM PHRM_GoodsReceiptItems
    				WHERE GoodReceiptItemId = x1.GoodsReceiptItemId
    				) AS "Date"
    			,SUM(FInQty + InQty - FOutQty - OutQty) AS "AvailableQty"
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
    						END) AS "InQty"
    				,SUM(CASE 
    						WHEN stk.InOut = 'out'
    							THEN stk.Quantity
    						ELSE 0
    						END) AS "OutQty"
    				,SUM(CASE 
    						WHEN stk.InOut = 'in'
    							THEN stk.FreeQuantity
    						ELSE 0
    						END) AS "FInQty"
    				,SUM(CASE 
    						WHEN stk.InOut = 'out'
    							THEN stk.FreeQuantity
    						ELSE 0
    						END) AS "FOutQty"
    			FROM "PHRM_StoreStock" AS stk
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
    				p_status = x1.ItemName
    				OR x1.ItemName LIKE '%' || COALESCE(p_status, '') || '%'
    				)
    		group by x1.itemname
    			,x1.genericname
    			,x1.batchno
    			,x1.expirydate
    			,x1.saleprice
    			,x1.storename
    			,x1.itemid
    			,x1.storeid
    			,x1.goodsreceiptitemid
    			,x1.price
    			,x1.goodreceiptid
    			,x1.goodreceiptprintid
    		having sum(finqty + inqty - foutqty - outqty) >= 0 -- filtering out quantity >= 0
    		order by x1.itemname;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;