CREATE OR REPLACE FUNCTION sp_phrmreport_expiryreport(
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
    filename: "sp_phrmreport_expiryreport"
    createdby/date: abhishek/2018-05-06
    description: to get the expired products details such as itemname, itemcode, availableqty,expirydate,batchno of each item selected by user datewise
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/04-03-2019						updated inout quantity
    2.		vikas/07-06-2019						update table name, get data from phrm_dispensarystock table
    3.      naveed/13-12-2019                       convert expiry date to varchar for showing well format date while export
    4.		bikash/12-01-2020						items with generic name as surgical removed.
    5.      sanjit/ramesh/10-05-2021                show the stocks expiry selecting available stores.also date filter added.
    6.      sanjit/10-06-2021                       removed dispensary stock part and calculated from store stock table (pharmacy stock redesign impact analysis)
    7.      ramesh/13-03-2021                       supplier name is added in the report.
    8.		rohit/2feb'22							Added filter to get only expired and nearly expired item(3 month)
    9       Rohit/13Feb'23						    mrp-> saleprice
    */
    
    	RETURN QUERY SELECT (
    			cast(row_number() over (
    					order by x.itemname
    					) as int)
    			) AS "SN"
    		,x.*
    	from (
    		select t1.itemid
    			,t1.batchno
    			,t1.expirydate
    			,t1.saleprice
    			,t1.costprice
    			,item.itemname
    			,generic.genericname
    			,sum(t2.availablequantity) as availablequantity
    			,store.name
    			,coalesce(supplier.suppliername, '') as suppliername
    		from phrm_mst_stock as t1
    		inner join phrm_txn_storestock as t2 on t1.stockid = t2.stockid
    		left join phrm_goodsreceiptitems as gri on t2.storestockid = gri.storestockid
    		left join phrm_goodsreceipt as gr on gri.goodreceiptid = gr.goodreceiptid
    		left join phrm_mst_supplier supplier on gr.supplierid = supplier.supplierid
    		inner join phrm_mst_item as item on item.itemid = t1.itemid
    		inner join phrm_mst_generic as generic on generic.genericid = item.genericid
    		inner join phrm_mst_store as store on store.storeid = t2.storeid
    		where (
    				t1.itemid = p_itemid
    				or p_itemid is null
    				)
    			and (
    				t2.storeid = p_storeid
    				or p_storeid is null
    				)
    			and (t1.expirydate)::date between p_fromdate
    				and (dateadd(month, 3, p_todate))::date
    			and (t2.availablequantity > 0)
    			and (generic.genericname not like '%SURGICAL%')
    		group by t1.itemid
    			,t1.batchno
    			,t1.expirydate
    			,t1.saleprice
    			,t1.costprice
    			,item.itemname
    			,generic.genericname
    			,store.name
    			,supplier.suppliername
    		) as x;
END;
$$ LANGUAGE plpgsql;