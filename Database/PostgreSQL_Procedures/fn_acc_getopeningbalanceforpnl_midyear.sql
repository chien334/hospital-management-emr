CREATE OR REPLACE FUNCTION fn_acc_getopeningbalanceforpnl_midyear(
    p_hospitalid INT,
    p_fiscalyearid INT,
    p_revenue VARCHAR,
    p_expenses VARCHAR
)
RETURNS TABLE (
    ledgerid INT,
    primarygroup VARCHAR,
    ledgername VARCHAR,
    coa VARCHAR,
    ledgergroupname VARCHAR,
    code VARCHAR,
    dramount DECIMAL,
    cramount DECIMAL
) AS $$
BEGIN
    IF (p_hospitalid > 0) THEN
        RETURN QUERY
        SELECT 
            l.ledgerid,
            lg.primarygroup AS primarygroup,
            l.ledgername,
            lg.coa AS coa,
            lg.ledgergroupname,
            l.code,
            CASE WHEN COALESCE(lbh.openingdrcr, TRUE) = TRUE THEN lbh.openingbalance ELSE 0 END::DECIMAL AS dramount,
            CASE WHEN COALESCE(lbh.openingdrcr, TRUE) = FALSE THEN lbh.openingbalance ELSE 0 END::DECIMAL AS cramount
        FROM acc_ledgerbalancehistory lbh
        JOIN acc_ledger l ON lbh.ledgerid = l.ledgerid AND lbh.hospitalid = l.hospitalid
        JOIN acc_mst_ledgergroup lg ON l.ledgergroupid = lg.ledgergroupid AND l.hospitalid = lg.hospitalid
        WHERE lbh.hospitalid = p_hospitalid
          AND lbh.fiscalyearid = p_fiscalyearid
          AND lg.primarygroup IN (p_revenue, p_expenses);
    ELSE
        -- Return empty
        RETURN;
    END IF;
END;
$$ LANGUAGE plpgsql;
