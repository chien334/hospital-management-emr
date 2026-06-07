CREATE OR REPLACE FUNCTION sp_dsb_home_subcategorywiseinventorystockvalue(
    p_sourcestoreid INT DEFAULT NULL
)
RETURNS TABLE (
    "SubCategoryId" INT,
    "SubCategoryName" VARCHAR,
    "AvailableQuantity" INT
) AS $$
BEGIN
    /*
    filename: "sp_dsb_home_subcategorywiseinventorystockvalue"
    createdby/date: rajib/2022-sept-13
    description: to get dashboard statistics of the home dashboards. these are used to fill labels.
    remarks:  
    note:  
    change history
    s.no.    updatedby/date                        remarks
    1       rajib/2022-sept-13               created
    
    */
    begin
    			 if ((p_sourcestoreid is not null) )
    	
    		then RETURN QUERY SELECT  
    				
    				isub.subcategoryid, 
    				isub.subcategoryname, 
    				sum(stck.availablequantity) AS "AvailableQuantity" 
    		from  inv_txn_storestock stck 
    				join inv_mst_item item on stck.itemid = item.itemid 
    				join inv_mst_itemsubcategory isub on item.subcategoryid = isub.subcategoryid 
    				where 
    				stck.storeid = p_sourcestoreid
    		group by 
    			isub.subcategoryname,isub.subcategoryid
    		 order by 
    			availablequantity desc limit 10; end if; 
    end;
END;
$$ LANGUAGE plpgsql;