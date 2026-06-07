CREATE OR REPLACE FUNCTION sp_report_inventory_substoregetallbasedonitemid(
    p_storeid INT DEFAULT NULL,
    p_itemid INT DEFAULT NULL
)
RETURNS TABLE (
    "ItemId" INT,
    "ItemName" VARCHAR,
    "TotalQuantity" INT,
    "TotalValue" DECIMAL,
    "TotalConsumed" TIMESTAMP
) AS $$
BEGIN
    /*
     filename: "sp_report_inventory_substoregetallbasedonitemid"
     created: 3mar'20 <Sanjit>
     Description: To Get All The Details of GoodRecipt of the inventory
     Remarks: 
     Change History
     S.No.    Date/User              Change          Remarks
     1.      3Mar'20/sanjit         created          
     2.		10aug'20/sanjit			updated stock value to be taken from price of stock table
    */
    
        RETURN QUERY SELECT z.itemid,itm.itemname,sum(z.totalquantity) AS "TotalQuantity",sum(z.totalvalue) AS "TotalValue",sum(z.totalconsumed) AS "TotalConsumed"	from
    	(select stk.itemid, 
    			sum(stk.availablequantity) AS "TotalQuantity",
    			sum(coalesce(stk.price,0) * stk.availablequantity) AS "TotalValue",
    			0 AS "TotalConsumed"
    		from inv_txn_stock stk
    		where	case
    				when p_itemid>0 and p_itemid = stk.itemid then 1
    				when p_storeid>0 and p_storeid = 1 then 1
    				when p_storeid=0 and p_itemid = 0 then 1
    			end = 1
    		group by stk.itemid
    	union all
    	select stk.itemid,
    			sum(availablequantity) AS "TotalQuantity",
    			sum(coalesce(stk.price,0)*availablequantity) AS "TotalValue",
    			sum(coalesce(consump.quantity,0)) AS "TotalConsumed" 
    		from ward_inv_stock stk
    		left join ward_inv_consumption consump on consump.storeid = stk.storeid and consump.itemid = stk.itemid
    		where	case
    					when p_itemid>0 and p_itemid = stk.itemid then 1
    					when p_storeid>0 and p_storeid = stk.storeid then 1
    					when p_storeid=0 and p_itemid = 0 then 1
    				end = 1
    		group by stk.itemid) as z
    join inv_mst_item itm on itm.itemid = z.itemid
    group by z.itemid,itm.itemname
    order by sum(z.totalquantity) desc;
END;
$$ LANGUAGE plpgsql;