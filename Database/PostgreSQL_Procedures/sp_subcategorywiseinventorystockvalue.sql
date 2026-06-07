CREATE OR REPLACE FUNCTION sp_subcategorywiseinventorystockvalue(
    p_sourcestoreid INT DEFAULT NULL
)
RETURNS TABLE (
    "SubCategoryName" VARCHAR,
    "AvailableQuantity" INT,
    "TotalStockValue" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_subcategorywiseinventorystockvalue"
    createdby/date: rohit/2dec'22
    Description: To get subcategory wise inventory stock value 
    Remarks:  
    NOTE:  
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       ROHIT/2Dec'22							 created
    */
    
    	RETURN QUERY SELECT isub.subcategoryname
    		,round(sum(stck.availablequantity), 3) AS "AvailableQuantity"
    		,round(sum(stck.availablequantity * stck.costprice), 3) AS "TotalStockValue"
    	from inv_txn_storestock stck
    	join inv_mst_item item on stck.itemid = item.itemid
    	join inv_mst_itemsubcategory isub on item.subcategoryid = isub.subcategoryid
    	where (
    			stck.storeid = p_sourcestoreid
    			or p_sourcestoreid is null
    			)
    	group by isub.subcategoryname
    	order by availablequantity desc;
END;
$$ LANGUAGE plpgsql;