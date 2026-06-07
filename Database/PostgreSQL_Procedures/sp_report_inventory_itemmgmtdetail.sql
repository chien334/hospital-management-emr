CREATE OR REPLACE FUNCTION sp_report_inventory_itemmgmtdetail(

)
RETURNS TABLE (
    "ItemName" VARCHAR,
    "CreatedBy" VARCHAR,
    "CreatedOn" TIMESTAMP,
    "ModifiedBy" VARCHAR,
    "ModifiedOn" TIMESTAMP
) AS $$
BEGIN
    
        begin
    	
    	RETURN QUERY SELECT 	
    	 itm.itemname,
    	 usr.username AS "CreatedBy",
    	 itm.createdon,
    	 usr1.username AS "ModifiedBy",
    	 itm.modifiedon  
    	 from inv_mst_item itm
    	left join  rbac_user usr on itm.createdby= usr.userid
    	left join  rbac_user usr1 on itm.modifiedby = usr1.userid;
       end;
END;
$$ LANGUAGE plpgsql;