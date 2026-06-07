CREATE OR REPLACE FUNCTION sp_lab_update_test_smsstatus(
    p_requistionids VARCHAR DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    DROP TABLE IF EXISTS v_reqidtbl;
    CREATE TEMP TABLE v_reqidtbl (
        RequisitionId int
    );
    
    	
    	insert into v_reqidtbl
    	select value from string_split(p_requistionids, ',') where rtrim(value) <> '';
    
    	update lab_testrequisition
    	set issmssend = 1
    	where requisitionid in (select requisitionid from v_reqidtbl);
END;
$$ LANGUAGE plpgsql;