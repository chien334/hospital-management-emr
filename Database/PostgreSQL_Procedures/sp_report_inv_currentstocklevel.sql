CREATE OR REPLACE FUNCTION sp_report_inv_currentstocklevel(
    p_storeids VARCHAR DEFAULT NULL,
    p_showzeroquantity BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    "StoreId" INT,
    "StoreName" VARCHAR,
    "ItemType" VARCHAR,
    "SubCategoryName" VARCHAR,
    "ItemId" INT,
    "Code" VARCHAR,
    "ItemName" VARCHAR,
    "AvailableQuantity" INT,
    "StockValue" DECIMAL
) AS $$
BEGIN
    /*
    execution example:
    	exec sp_report_inv_currentstocklevel p_storeids='7,8'
    	exec sp_report_inv_currentstocklevel p_storeids='13', p_showzeroquantity = false
    change history
    s.no.    updatedby/date					remarks
    1		nageshbb/22 sep 2020			updated script for get subcategory name column
    2		nageshbb/08 dec 2020			updated script for fix wrong storeid get issue resolution when main storeid is not there
    3       sanjit/ramesh/rohit/9thsep'21   updated after Inv Stock refactoring
    4     Sanjit/Sud:10Jun'22               removed union with fixedassettables since we've now taken all stocks in same table.
    */
    
    	RETURN QUERY SELECT 
    		store.StoreId,
    		store.Name AS "StoreName",
    		itm.ItemType,
    		subCat.SubCategoryName,
    		itm.ItemId,
    		itm.Code, 
    		itm.ItemName,
    		SUM(storeStk.AvailableQuantity) AS "AvailableQuantity",
    		SUM(storeStk.AvailableQuantity * stkMaster.CostPrice) AS "StockValue"
    	FROM INV_TXN_StoreStock storeStk
    		INNER JOIN INV_MST_Stock stkMaster on storeStk.StockId = stkMaster.StockId
    		INNER JOIN PHRM_MST_Store store on storeStk.StoreId = store.StoreId
    		INNER JOIN INV_MST_Item itm on storeStk.ItemId = itm.ItemId
    		INNER JOIN INV_MST_ItemSubCategory subCat on subCat.SubCategoryId = itm.SubCategoryId
    	WHERE 
    		stkMaster.IsActive = 1 
    		AND storeStk.StoreId IN (SELECT value FROM STRING_SPLIT(p_storeids, ',') WHERE RTRIM(value) <> '')
    	group by
    		itm.itemtype,
    		subcat.subcategoryname,
    		itm.itemid,
    		itm.code, 
    		itm.itemname,
    		store.storeid,
    		store.name
    	having
    		sum(storestk.availablequantity) > 0 or p_showzeroquantity = true; --to disable quantity filter if showzeroquantity is true
END;
$$ LANGUAGE plpgsql;