CREATE OR REPLACE FUNCTION sp_dsb_home_deptwiseconsumeritems(
    p_sourcestoreid INT DEFAULT NULL
)
RETURNS TABLE (
    "TargetStoreId" INT,
    "Name" VARCHAR,
    "DispatchedQuantity" INT
) AS $$
BEGIN
    /*
    filename: "sp_dsb_home_deptwiseconsumeritems"
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
      
    	  dis.targetstoreid, 
    	 phrm.name, 
    	 sum( dis.dispatchedquantity ) AS "DispatchedQuantity" 
    	from phrm_mst_store  phrm 
    	join  inv_txn_dispatchitems dis on phrm.storeid = dis.targetstoreid 
    	where 
    	dis.sourcestoreid = p_sourcestoreid 
    	group by
    	phrm.name,dis.targetstoreid
    	order by dispatchedquantity desc limit 10; end if; 
      
    end;
END;
$$ LANGUAGE plpgsql;