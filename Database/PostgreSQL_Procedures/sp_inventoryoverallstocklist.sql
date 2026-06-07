CREATE OR REPLACE FUNCTION sp_inventoryoverallstocklist(
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "ItemId" INT,
    "ItemCategoryId" INT,
    "ItemName" VARCHAR,
    "AvailQuantity" INT,
    "StoreId" INT,
    "MinQuantity" INT,
    "ItemCode" VARCHAR,
    "ItemType" VARCHAR,
    "IsColdStorageApplicable" BOOLEAN,
    "SubCategoryName" VARCHAR,
    "UOMId" INT,
    "UOMName" VARCHAR,
    "IsFixedAssets" BOOLEAN
) AS $$
BEGIN
    /*
    filename: sp_inventoryoverallstocklist 
    createdby/date: rohit/2022-06-10
    description: sp to get overall stock for inventory by storeid.(used: inventory->stock->list)
    remarks: getting total available quantity at itemlevel. batch,expiry,cost etc seperation is not there.
    change history
    s.no.    updatedby/date                        remarks
    1        rohit/2022-06-10                   created initial script
    2		 rohit/2022-07-29					round off the available quantity
    */
    
        RETURN QUERY SELECT mstitem.itemid
    	,mstitem.itemcategoryid
    	,mstitem.itemname
    	,ss.availablequantity AS "AvailQuantity"
        ,ss.storeid
    	,mstitem.minstockquantity AS "MinQuantity"
    	,mstitem.code AS "ItemCode"
    	,mstitem.itemtype
    	,mstitem.iscoldstorageapplicable
    	,sub.subcategoryname
    	,unit.uomid
    	,unit.uomname
    	,mstitem.isfixedassets
    from inv_mst_item mstitem
    inner join (
    	select itemid
            ,storeid
    		,round(sum(availablequantity),4) as "availablequantity"
    	from inv_txn_storestock
    	group by itemid,storeid
    	) ss on ss.itemid = mstitem.itemid
    inner join inv_mst_itemsubcategory sub on sub.subcategoryid = mstitem.subcategoryid
    inner join inv_mst_unitofmeasurement unit on unit.uomid = mstitem.unitofmeasurementid
    where ss.storeid=p_storeid
    order by mstitem.itemname;
END;
$$ LANGUAGE plpgsql;