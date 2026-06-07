CREATE OR REPLACE FUNCTION sp_inv_getstocklistfordispatch(
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "ItemId" INT,
    "ItemName" VARCHAR,
    "Description" TIMESTAMP,
    "ItemCategory" VARCHAR,
    "ItemCode" VARCHAR,
    "ItemUOM" VARCHAR,
    "BatchNo" VARCHAR,
    "AvailableQuantity" INT,
    "CostPrice" DECIMAL,
    "IsFixedAsset" BOOLEAN,
    "BarCodeList" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_inv_getstocklistfordispatch"
    createdby/date: rohit/7may'23
    Description: To get the inventory stock list by StoreId to dispatch
    Remarks:    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       Rohit/7May'23                        created the script
    */
    
    RETURN QUERY SELECT 
        ss.itemid AS "ItemId", 
        i.itemname AS "ItemName", 
        i.description AS "Description", 
        c.itemcategoryname AS "ItemCategory", 
        i.code AS "ItemCode", 
        coalesce(u.uomname, 'N/A') AS "ItemUOM", 
        ssm.batchno AS "BatchNo", 
        sum(ss.availablequantity) AS "AvailableQuantity", 
        ssm.costprice AS "CostPrice", 
        i.isfixedassets AS "IsFixedAsset", 
        (
            (select json_agg(t) from (select fas.barcodenumber as barcodenumber, 
                fas.fixedassetstockid as stockid
            from 
                inv_txn_fixedassetstock as fas 
            where 
                fas.itemid = ss.itemid 
                and fas.isactive = 1 
                and fas.storeid = p_storeid 
                and fas.substoreid is null) as "t")::text
        ) AS "BarCodeList"
    from 
        inv_txn_storestock as ss
        inner join inv_mst_stock as ssm on ss.stockid = ssm.stockid
        inner join inv_mst_item as i on ss.itemid = i.itemid 
        inner join inv_mst_itemcategory as c on i.itemcategoryid = c.itemcategoryid
        left join inv_mst_unitofmeasurement as u on i.unitofmeasurementid = u.uomid 
    where 
        ss.storeid = p_storeid 
        and ss.isactive = 1 
        and ss.availablequantity > 0 
    group by 
        ss.itemid, 
        ssm.batchno, 
        c.itemcategoryname, 
        i.isfixedassets,
        i.itemname, 
        i.description, 
        i.code, 
        u.uomname, 
        ssm.costprice;
END;
$$ LANGUAGE plpgsql;