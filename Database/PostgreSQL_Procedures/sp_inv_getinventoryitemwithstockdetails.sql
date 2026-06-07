CREATE OR REPLACE FUNCTION sp_inv_getinventoryitemwithstockdetails(

)
RETURNS TABLE (
    "ItemId" INT,
    "ItemName" VARCHAR,
    "Code" VARCHAR,
    "BatchNo" VARCHAR,
    "UOMName" VARCHAR,
    "ItemCategory" VARCHAR,
    "IsFixedAssets" BOOLEAN,
    "ItemType" VARCHAR,
    "Description" TIMESTAMP,
    "StoreId" INT,
    "AvailableQuantity" INT
) AS $$
BEGIN
    /*  
    filename: "sp_inv_getinventorystock"  
    createdby/date: rohit/6jul'23
    Description: To get inventory item with stock details
    Remarks:      
    Change History  
    S.No.    UpdatedBy/Date               Remarks  
    1.       Rohit/6Jul'23               initial script
    */
    
        RETURN QUERY SELECT item.itemid
    	,item.itemname
    	,item.code
    	,stk.batchno
    	,uom.uomname
    	,itemcat.itemcategoryname AS "ItemCategory"
    	,item.isfixedassets
    	,item.itemtype
    	,item.description
    	,strstk.storeid
    	,sum(coalesce(strstk.availablequantity,0)) AS "AvailableQuantity"
    from inv_mst_item item
    inner join inv_mst_itemcategory itemcat on item.itemcategoryid = itemcat.itemcategoryid
    inner join inv_mst_unitofmeasurement uom on item.unitofmeasurementid = uom.uomid
    left join inv_txn_storestock strstk on item.itemid = strstk.itemid
    left join inv_mst_stock stk on strstk.stockid = stk.stockid
    where item.isactive =1
    group by item.itemid
    	,item.itemname
    	,item.code
    	,stk.batchno
    	,uom.uomname
    	,itemcat.itemcategoryname
    	,item.isfixedassets
    	,item.itemtype
    	,item.description
    	,strstk.storeid;
END;
$$ LANGUAGE plpgsql;