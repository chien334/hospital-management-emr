CREATE OR REPLACE FUNCTION sp_report_substorewisesummaryreport(
    p_storeid INT DEFAULT NULL,
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_fiscalyearid INT DEFAULT NULL
)
RETURNS TABLE (
    "ItemId" INT,
    "ItemName" VARCHAR,
    "ItemCategoryName" VARCHAR,
    "SubCategoryName" VARCHAR,
    "Unit" VARCHAR,
    "OpeningQty" INT,
    "OpeningValue" DECIMAL,
    "DispatchedQty" INT,
    "DispatchedValue" DECIMAL,
    "ConsumedQty" TIMESTAMP,
    "ConsumedValue" TIMESTAMP,
    "ClosingQty" INT,
    "ClosingValue" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_substorewisesummaryreport" null, '2022-05-18','2022-05-19',6
    created: 18may'22/Rohit
    Description: To Get Substore Wise Summary Report Data With StoreId,FromDate,ToDate,FiscalYearId.
    Change History
    S.No.    Date/User              Change          Remarks
    1.       11Nov'22/rohit/nirmala                       inital draft
    2.       18nov'22/Rohit								  Removed ReceivedQty, Substore Name Removed (Substore Filer gives the information of 
    													  Substore so no need to show SubStoreName)
    3.		4Jan'22/rohit								  store filter changes 
    */
    
      
    RETURN QUERY SELECT itms.itemid
        ,itms.itemname
        ,cat.itemcategoryname
        ,subcat.subcategoryname
        ,uom.uomname AS "Unit"
        ,coalesce(oi.openingqty, 0) AS "OpeningQty"
        ,coalesce(oi.openingvalue, 0) AS "OpeningValue"
        ,coalesce(di.dispatchedqty, 0) AS "DispatchedQty"
        ,coalesce(di.dispatchedvalue, 0) AS "DispatchedValue"
        ,coalesce(ci.consumedqty, 0) AS "ConsumedQty"
        ,coalesce(ci.consumedvalue, 0) AS "ConsumedValue"
        ,coalesce(oi.openingqty, 0) + coalesce(di.dispatchedqty, 0) - coalesce(ci.consumedqty, 0) AS "ClosingQty"
        ,coalesce(oi.openingvalue, 0) + coalesce(di.dispatchedvalue, 0) - coalesce(ci.consumedvalue, 0) AS "ClosingValue"
    from inv_mst_item itms
    inner join inv_mst_itemcategory cat on itms.itemcategoryid = cat.itemcategoryid
    inner join inv_mst_itemsubcategory subcat on itms.subcategoryid = subcat.subcategoryid
    inner join inv_mst_unitofmeasurement uom on itms.unitofmeasurementid = uom.uomid
    left join (
        select itemid
            ,sum(coalesce(openingqty, 0)) AS "OpeningQty"
            ,sum(coalesce(openingqty, 0) * coalesce(price, 0)) AS "OpeningValue"
        from inv_fiscalyearstock
        where fiscalyearid = p_fiscalyearid
            and (
                storeid = p_storeid
                or p_storeid is null
                )
            and (
                storeid  in (
                    select storeid
                    from phrm_mst_store
                    where category ='substore'
                    )
                )
        group by itemid
        ) oi on itms.itemid = oi.itemid
    left join (
        select itemid
            ,sum(coalesce(inqty, 0)) AS "DispatchedQty"
            ,sum(coalesce(inqty, 0) * coalesce(costprice, 0)) AS "DispatchedValue"
        from inv_txn_stocktransaction
        where transactiontype in ('dispatched-item-to')
            and (transactiondate)::date between p_fromdate
                and p_todate
            and (
                storeid = p_storeid
                or p_storeid is null
                )
            and (
                storeid  in (
                    select storeid
                    from phrm_mst_store
                    where category ='substore'
                    )
                )
        group by itemid
        ) di on itms.itemid = di.itemid
    left join (
        select itemid
            ,sum(coalesce(outqty, 0)) AS "ConsumedQty"
            ,sum(coalesce(outqty, 0) * coalesce(costprice, 0)) AS "ConsumedValue"
        from inv_txn_stocktransaction
        where transactiontype in ('consumption-items')
            and (transactiondate)::date between p_fromdate
                and p_todate
            and (
                storeid = p_storeid
                or p_storeid is null
                )
            and (
                storeid  in (
                    select storeid
                    from phrm_mst_store
                    where category  ='substore'
                    )
                )
        group by itemid
        ) ci on itms.itemid = ci.itemid
    where openingqty > 0
        or dispatchedqty > 0
        or consumedqty > 0
    	order by itemname;
END;
$$ LANGUAGE plpgsql;