CREATE OR REPLACE FUNCTION sp_report_inventory_substoregetall(
    p_storeid INT DEFAULT NULL,
    p_itemid INT DEFAULT NULL
)
RETURNS TABLE (
    "TotalQuantity" INT,
    "TotalValue" DECIMAL,
    "ExpiryQuantity" INT,
    "ExpiryValue" DECIMAL
) AS $$
BEGIN
    /*
     filename: sp_report_inventory_substoregetall
     created: 12dec'19 <Sanjit>
     Description: To Get All The Details of GoodRecipt of the inventory
     Remarks: 
     Change History
     S.No.    Date/User              Change          Remarks
     1.      3Mar'20/sanjit         created          
     2.		10aug'20/sanjit			updated stock value to be taken from price of stock table
    */
    
      begin
        RETURN QUERY SELECT sum(z.totalquantity) AS "TotalQuantity",
    	sum(z.totalvalue) AS "TotalValue",
    	sum(z.expiryquantity) AS "ExpiryQuantity",
    	sum(z.expiryvalue) AS "ExpiryValue" 
    	from
    		((select stk.itemid, 
    				sum(stk.availablequantity) AS "TotalQuantity",
    				sum(coalesce(stk.price,0)*stk.availablequantity) AS "TotalValue",
    				0 AS "ExpiryQuantity",
    				0 AS "ExpiryValue"
    			from inv_txn_stock stk
    			where	case
    						when p_itemid>0 and p_itemid = stk.itemid then 1
    						when p_storeid>0 and p_storeid = 1 then 1
    						when p_storeid=0 and p_itemid = 0 then 1
    					end = 1
    			group by stk.itemid)
    		union all
    			(select stk.itemid, 
    				0 AS "TotalQuantity",
    				0 AS "TotalValue",
    				sum(stk.availablequantity) as "expiredquantity",
    				sum(coalesce(stk.price,0)*stk.availablequantity) as "expiredvalue"
    			from inv_txn_stock stk
    			where stk.expirydate < current_timestamp and	
    			case
    				when p_itemid>0 and p_itemid = stk.itemid then 1
    				when p_storeid>0 and p_storeid = 1 then 1
    				when p_storeid=0 and p_itemid = 0 then 1
    					end = 1
    			group by stk.itemid)
    		union all
    			(select itemid,
    				sum(availablequantity) AS "TotalQuantity",
    				sum(coalesce(stk.price,0)*availablequantity) AS "TotalValue",
    				0 AS "ExpiryQuantity",
    				0 AS "ExpiryValue"  
    			from ward_inv_stock stk
    			where	case
    						when p_itemid>0 and p_itemid = stk.itemid then 1
    						when p_storeid>0 and p_storeid = stk.storeid then 1
    						when p_storeid=0 and p_itemid = 0 then 1
    					end = 1
    			group by itemid)
    		union all
    			(select itemid,
    				0 AS "TotalQuantity",
    				0 AS "TotalValue",
    				sum(stk.availablequantity) AS "ExpiryQuantity",
    				sum(coalesce(stk.price,0)*stk.availablequantity) AS "ExpiryValue"  
    			from ward_inv_stock stk
    			where stk.expirydate<current_timestamp
    			and case
    						when p_itemid>0 and p_itemid = stk.itemid then 1
    						when p_storeid>0 and p_storeid = stk.storeid then 1
    						when p_storeid=0 and p_itemid = 0 then 1
    					end = 1
    			group by itemid)) 
    	as z;
    
      end;
END;
$$ LANGUAGE plpgsql;