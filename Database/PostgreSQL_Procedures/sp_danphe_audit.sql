/****** Object:  StoredProcedure [dbo].[SP_Danphe_Audit]    Script Date: 28-01-2019 17:16:46 ******/
CREATE OR REPLACE FUNCTION sp_danphe_audit(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_table_name VARCHAR DEFAULT NULL,
    p_username VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "*" VARCHAR
) AS $$
BEGIN
    /*
    change history
    s.no.    updatedby/date					remarks
    1.		rajesh/23jan'19			     Created 
    2.      Rajesh/28Jan'19				 updated    
    */
    
    --if (p_fromdate is not null) or (p_todate is not null) or (p_table_name is not null) or (p_username is not null)
    
    RETURN QUERY SELECT *
    from "danpheadmin"."fn_danphe_audit"() tbl1
        inner join "audittrail_danpheemr"."rbac_user" tbl2
    	on tbl1.changedbyusername = tbl2.username
    	where (  
            (tbl1.inserteddate)::date between (p_fromdate)::date 
         and (p_todate)::date 
       and tbl1.table_name = p_table_name and tbl2.username = p_username );
END;
$$ LANGUAGE plpgsql;