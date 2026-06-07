CREATE OR REPLACE FUNCTION sp_inctv_getfractionitems_bytxnitemid(
    p_billingtansactionitemid INT DEFAULT NULL
)
RETURNS TABLE (
    "*" VARCHAR
) AS $$
BEGIN
    /*
     file: sp_inctv_getfractionitems_bytxnitemid
     description: to get the fractions for current billingtransactionitemid.
     conditions/checks: 
     remarks: 
     change history:
     s.no.    changedate/by       remarks
     1.      10apr'20/sud          initial draft 
    */
    
     
    --table:1 -- get fraction information---
    RETURN QUERY SELECT * from inctv_txn_incentivefractionitem
    where billingtransactionitemid=p_billingtansactionitemid;
END;
$$ LANGUAGE plpgsql;