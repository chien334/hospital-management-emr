/****** Object:  StoredProcedure [dbo].[SP_Danphe_Audit_List]    Script Date: 28-01-2019 17:52:57 ******/
CREATE OR REPLACE FUNCTION sp_danphe_audit_list(

)
RETURNS TABLE (
    "Table_Name" VARCHAR
) AS $$
BEGIN
    /*
    change history
    s.no.    updatedby/date					remarks
    1.		rajesh/28jan'19			     created 
    
    */
    
    
    RETURN QUERY SELECT  distinct table_name from "fn_danphe_audit"();
END;
$$ LANGUAGE plpgsql;