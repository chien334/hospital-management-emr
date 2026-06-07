CREATE OR REPLACE FUNCTION sp_report_inventory_substoregetallbasedonstoreid(
    p_storeid INT DEFAULT NULL,
    p_itemid INT DEFAULT NULL
)
RETURNS TABLE (
    "StoreId" INT,
    "Name" VARCHAR,
    "TotalQuantity" INT,
    "TotalValue" DECIMAL,
    "TotalConsumed" TIMESTAMP
) AS $$
BEGIN
    /*
     filename: "sp_report_inventory_substoregetallbasedonstoreid"
     created: 3mar'20 <Sanjit>
     Description: To Get All The Details of GoodRecipt of the inventory
     Remarks: 
     Change History
     S.No.    Date/User              Change          Remarks
     1.      3Mar'20/sanjit         created          
     2.      20jul'20/Sanjesh       ItemRate Mismatch fix
     3.		10Aug'20/sanjit			updated stock value to be taken from price of stock table
    */
    begin
        RETURN QUERY SELECT str.storeid, str.name, 
    		sum(stk.availablequantity) AS "TotalQuantity",
    		sum(stk.availablequantity*(coalesce(stk.price,0))) AS "TotalValue",
    		coalesce((select sum(dispatchedquantity)  from inv_txn_dispatchitems),0) AS "TotalConsumed"
    	from inv_txn_stock stk
    	join inv_txn_goodsreceiptitems gritm on gritm.goodsreceiptitemid = stk.goodsreceiptitemid
    	join phrm_mst_store str on str.storeid = 1
    	where	case
    				when p_itemid>0 and p_itemid = stk.itemid then 1
    				when p_storeid>0 and p_storeid = 1 then 1
    				when p_storeid=0 and p_itemid = 0 then 1
    			end = 1
    	group by str.storeid,str.name
    union all
    select str.storeid, str.name, 
    		sum(stk.availablequantity) AS "TotalQuantity",
    		sum(coalesce(stk.price,0)*stk.availablequantity) AS "TotalValue",
    		sum(coalesce(consump.quantity,0)) AS "TotalConsumed"
    	from ward_inv_stock stk
    	join phrm_mst_store str on str.storeid = stk.storeid
    	left join ward_inv_consumption consump on consump.storeid = str.storeid and consump.itemid = stk.itemid
    	where	case
    				when p_itemid>0 and p_itemid = stk.itemid then 1
    				when p_storeid>0 and p_storeid = stk.storeid then 1
    				when p_storeid=0 and p_itemid = 0 then 1
    			end = 1
    	group by str.storeid,str.name;
    
      
    end;
END;
$$ LANGUAGE plpgsql;