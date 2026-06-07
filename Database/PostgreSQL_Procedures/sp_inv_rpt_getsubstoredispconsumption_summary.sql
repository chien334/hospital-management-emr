CREATE OR REPLACE FUNCTION sp_inv_rpt_getsubstoredispconsumption_summary(
    p_storeids VARCHAR DEFAULT NULL,
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "SubCategoryName" VARCHAR,
    "ItemName" VARCHAR,
    "ItemId" INT,
    "Code" VARCHAR,
    "ItemType" VARCHAR,
    "Unit" VARCHAR,
    "DispatchQuantity" INT,
    "DispatchValue" DECIMAL,
    "ConsumptionQuantity" TIMESTAMP,
    "ConsumptionValue" TIMESTAMP
) AS $$
BEGIN
    DROP TABLE IF EXISTS v_storeidtbl;
    CREATE TEMP TABLE v_storeidtbl (
        StoreId int
    );
    /*
    change history
    s.no.    updatedby/date          remarks
    1    anjana/12/18/2020        initial draft
    2	 sud/01/05/2021			  made corrections 
    */
     
     
     
      
      insert into v_storeidtbl
      select value from string_split(p_storeids, ',') where rtrim(value) <> '';
      
       RETURN QUERY SELECT 
           sub.subcategoryname,
          itm.itemname, 
          itm.itemid,
          itm.code,
          itm.itemtype,
          unit.uomname AS "Unit",
          dis.dispatchquantity,
          dis.dispatchvalue,
          con.consumptionquantity,
          con.consumptionvalue
        from 
    	inv_mst_item itm 
    	  inner join inv_mst_itemsubcategory sub on itm.subcategoryid = sub.subcategoryid
    	  left join  inv_mst_unitofmeasurement unit on itm.unitofmeasurementid = unit.uomid 
          left join ( select itemid, sum(quantity) AS "DispatchQuantity", sum(coalesce(price,0)*coalesce(quantity,0)) AS "DispatchValue" 
    	        from ward_inv_transaction txn
    			where transactiontype = 'dispatched-items' 
                      and (transactiondate)::date between coalesce(p_fromdate, (current_timestamp)::date) and coalesce(p_todate, (current_timestamp)::date) 
    				  and txn.storeid in (select storeid from v_storeidtbl)
    			group by itemid
    			) dis 
    			on itm.itemid = dis.itemid
    
         left join ( select itemid, sum(quantity) AS "ConsumptionQuantity", sum(coalesce(price,0)*coalesce(quantity,0)) AS "ConsumptionValue" 
    	      from ward_inv_transaction  txn
    		  where transactiontype = 'consumption-items' 
    		        and (transactiondate)::date between coalesce(p_fromdate, (current_timestamp)::date) and coalesce(p_todate, (current_timestamp)::date) 
    		       and txn.storeid in (select storeid from v_storeidtbl)
    		  group by itemid )con 
    		  on itm.itemid = con.itemid
       
         where (
    	  coalesce(dis.dispatchquantity,0) !=0 
    	  or coalesce(con.consumptionquantity,0) !=0 
    	)
    
        order by sub.subcategoryname, itm.itemname;
END;
$$ LANGUAGE plpgsql;