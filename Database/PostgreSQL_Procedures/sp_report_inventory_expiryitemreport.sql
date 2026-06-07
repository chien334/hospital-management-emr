CREATE OR REPLACE FUNCTION sp_report_inventory_expiryitemreport(
    p_itemid INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL,
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "x.*" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_report_inventory_expiryitemreport" 
    created: 08oct'21/Swapnil
    Description: To get report data with ItemId,StoreId,FromDate,ToDate.
    Change History
    S.No.    Date/User              Change          Remarks
    1.	     06Oct'21/swapnil		                  inital draft
    */
    
    
    	RETURN QUERY SELECT (cast(row_number() over (order by  x.itemname)  as int)) AS "SN", x.*
    	from
    		(
    			select t1.itemid, t1.batchno, t1.expirydate, t1.mrp, t1.costprice, item.itemname, sum(t2.availablequantity) as availablequantity, store.name, coalesce(vendor.vendorname, '') as vendorname
    			from inv_mst_stock as t1 inner join
    			inv_txn_storestock as t2 on t1.stockid = t2.stockid left join
    			inv_txn_goodsreceiptitems as gri on t2.storestockid = gri.stockid left join
    			inv_txn_goodsreceipt as gr on gri.goodsreceiptid = gr.goodsreceiptid left join
    			inv_mst_vendor vendor on gr.vendorid = vendor.vendorid inner join
    			inv_mst_item as item on item.itemid = t1.itemid inner join
    			phrm_mst_store as store on store.storeid = t2.storeid
    			where  (t1.itemid = p_itemid or p_itemid is null) and (t2.storeid = p_storeid or p_storeid is null)
    			and (t1.expirydate)::date between p_fromdate and p_todate and (t2.availablequantity > 0)
    		group by t1.itemid, t1.batchno, t1.expirydate, t1.mrp,t1.costprice, item.itemname, store.name, vendor.vendorname
    		)
    	as x;
END;
$$ LANGUAGE plpgsql;