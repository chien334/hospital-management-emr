CREATE OR REPLACE FUNCTION sp_acc_getallemployee_ledgerlist(
    p_hospitalid INT
)
RETURNS TABLE (
    ledgerid INT,
    employeeid INT,
    ledgername VARCHAR,
    ledgercode VARCHAR,
    ledgergroupname VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT led.ledgerid, consLedMap.referenceid AS employeeid,
           led.ledgername, led.code AS ledgercode, ledGrp.ledgergroupname
    FROM acc_ledger led
    JOIN acc_mst_ledgergroup ledGrp ON led.ledgergroupid = ledGrp.ledgergroupid
    JOIN (
        SELECT * 
        FROM acc_ledger_mapping 
        WHERE ledgertype = 'consultant' AND hospitalid = p_hospitalid
    ) consLedMap ON led.ledgerid = consLedMap.ledgerid
    WHERE led.hospitalid = p_hospitalid 
      AND ledGrp.hospitalid = p_hospitalid;
END;
$$ LANGUAGE plpgsql;
