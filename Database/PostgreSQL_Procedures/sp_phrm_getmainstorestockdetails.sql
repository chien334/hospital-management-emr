CREATE OR REPLACE FUNCTION sp_phrm_getmainstorestockdetails(
    p_showstockfromallstores BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (
    "StockId" INT,
    "ItemId" INT,
    "ItemName" VARCHAR,
    "ItemCode" VARCHAR,
    "StoreId" INT,
    "StoreName" VARCHAR,
    "UOMName" VARCHAR,
    "GenericId" INT,
    "GenericName" VARCHAR,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "CostPrice" DECIMAL,
    "SalePrice" DECIMAL,
    "AvailableQuantity" INT,
    "IsInsuranceApplicable" BOOLEAN,
    "BarcodeNumber" VARCHAR,
    "RackNo" VARCHAR
) AS $$
DECLARE
    v_phrm_mainstoreid INT := (Select  StoreId from PHRM_MST_Store where Category='store' AND  SubCategory= 'pharmacy' LIMIT 1);
BEGIN
    /*
    sp name: sp_phrm_getmainstorestockdetails
    author: sanjit raj shakya
    createdon: 22 dec, 2021
    remarks: created to replace linq query in api getmainstorestock in pharmacycontroller
    execution: exec sp_phrm_getmainstorestockdetails p_showstockfromallstores = true
     change history
     s.no.    date/user              change          remarks-
     1.      sanjit/22 dec'21                       inital draft
     2.      Ramesh/27 Dec'21                       changed innerjoin to leftjoin of stockbarcode with mst stock 
     3.      rohit/5jul'22                          Make group by in SubQuery
     4.      Nirmala/20Dec'22                       add rack no
     5.      rohit/13feb'23						MRP-> SalePrice
     6.      Rohit/Sud/04Apr'23                 removed hardcoding of mainstore and take from phrm_mst_store's column values 
                                                 ( where Category='store' AND  SubCategory= 'pharmacy')
    */
    BEGIN
    
    
    IF (v_phrm_mainstoreid IS NULL)
    THEN
      RAISE EXCEPTION 'pharmacy mainstore not configured in stores table.';
    end if;
    
    	RETURN QUERY SELECT ss.stockid
    		,ss.itemid
    		,i.itemname
    		,i.itemcode
    		,store.storeid
    		,store.name AS "StoreName"
    		,u.uomname
    		,g.genericid
    		,g.genericname
    		,s.batchno
    		,s.expirydate
    		,s.costprice
    		,s.saleprice
    		,coalesce(ss.availablequantity, 0) AS "AvailableQuantity"
    		,i.isinsuranceapplicable
    		,sb.barcodeid AS "BarcodeNumber"
    		,r.rackno
    	from (
    		select storeid
    			,stockid
    			,itemid
    			,sum(availablequantity) AS "AvailableQuantity"
    		from phrm_txn_storestock
    		where isactive = 1
    		group by storeid
    			,stockid
    			,itemid
    		) ss
    	inner join phrm_mst_stock s on ss.stockid = s.stockid
    	inner join phrm_mst_item i on ss.itemid = i.itemid
    		and s.itemid = i.itemid
    	left join phrm_map_itemtorack m on i.itemid = m.itemid
    		and ss.storeid = m.storeid
    	left join phrm_mst_rack r on r.rackid = m.rackid
    	inner join phrm_mst_generic g on i.genericid = g.genericid
    	inner join phrm_mst_unitofmeasurement u on i.uomid = u.uomid
    	inner join phrm_mst_store store on ss.storeid = store.storeid
    	left join phrm_mst_stockbarcode sb on s.barcodeid = sb.barcodeid
    	where (
    			p_showstockfromallstores = true
    			   or store.storeid =  v_phrm_mainstoreid
    			)
    	order by i.itemname;
    end;
END;
$$ LANGUAGE plpgsql;