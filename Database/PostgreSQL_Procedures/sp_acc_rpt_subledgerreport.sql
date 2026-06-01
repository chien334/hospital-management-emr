CREATE OR REPLACE FUNCTION sp_acc_rpt_subledgerreport(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_hospitalid INT,
    p_openingfiscalyearid INT,
    p_subledgerids VARCHAR
) RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'ref1';
    ref2 refcursor := 'ref2';
    v_openingbalancefromdate TIMESTAMP;
    v_openingbalancetodate TIMESTAMP;
    v_fiscalyearid_loop INT;
    v_subledger_id_list INT[];
BEGIN
    -- Parse comma separated subledger IDs to integer array
    v_subledger_id_list := string_to_array(p_subledgerids, ',')::int[];

    SELECT startdate INTO v_openingbalancefromdate 
    FROM acc_mst_fiscalyears 
    WHERE fiscalyearid = p_openingfiscalyearid 
    LIMIT 1;

    v_openingbalancetodate := p_fromdate - INTERVAL '1 day';

    -- Create temp tables
    CREATE TEMP TABLE IF NOT EXISTS temp_unclosed_fiscal_year (
        fiscalyearid INT
    );
    TRUNCATE temp_unclosed_fiscal_year;

    CREATE TEMP TABLE IF NOT EXISTS temp_yearly_opening_balance (
        balance DECIMAL,
        subledgerid INT,
        ledgerid INT
    );
    TRUNCATE temp_yearly_opening_balance;

    -- First Insert: Yearly Opening Balance for p_openingfiscalyearid
    INSERT INTO temp_yearly_opening_balance (balance, subledgerid, ledgerid)
    SELECT COALESCE(SUM(COALESCE(openingdramount, 0)) + SUM(COALESCE(openingtxndramount, 0)) - SUM(COALESCE(openingcramount, 0)) - SUM(COALESCE(openingtxncramount, 0)), 0)::DECIMAL AS balance
         , subledgerid
         , ledgerid
    FROM (
        -- 1. Subledger opening balance from SubLedger balance history table
        SELECT CASE 
                WHEN COALESCE(lbh.openingdrcr, TRUE) = TRUE
                    THEN COALESCE(lbh.openingbalance, 0)
                ELSE 0
                END AS openingdramount
            , CASE 
                WHEN COALESCE(lbh.openingdrcr, TRUE) = FALSE
                    THEN COALESCE(lbh.openingbalance, 0)
                ELSE 0
                END AS openingcramount
            , 0::DECIMAL AS openingtxndramount
            , 0::DECIMAL AS openingtxncramount
            , subLed.subledgerid
            , subLed.ledgerid
        FROM acc_ledger led
        JOIN acc_mst_subledger subLed ON led.ledgerid = subLed.ledgerid
        JOIN acc_subledgerbalancehistory lbh ON subLed.subledgerid = lbh.subledgerid AND subLed.hospitalid = lbh.hospitalid
        WHERE lbh.hospitalid = p_hospitalid
            AND lbh.fiscalyearid = p_openingfiscalyearid
            AND led.isactive = TRUE
            AND subLed.isactive = TRUE
            AND subLed.subledgerid = ANY(v_subledger_id_list)
        
        UNION ALL
        
        -- 2. Balance from transaction table from opening fiscal year start date to FromDate-1
        SELECT 0::DECIMAL AS openingdramount
            , 0::DECIMAL AS openingcramount
            , COALESCE(txn.dramount, 0)::DECIMAL AS openingtxndramount
            , COALESCE(txn.cramount, 0)::DECIMAL AS openingtxncramount
            , subLed.subledgerid
            , subLed.ledgerid
        FROM acc_txn_subledgerrecords txn
        JOIN acc_mst_subledger subLed ON txn.subledgerid = subLed.subledgerid
        WHERE txn.hospitalid = p_hospitalid
            AND (txn.voucherdate::DATE BETWEEN v_openingbalancefromdate::DATE AND v_openingbalancetodate::DATE)
            AND subLed.isactive = TRUE
            AND txn.isverified = TRUE
            AND txn.subledgerid = ANY(v_subledger_id_list)
    ) innerTbl
    GROUP BY innerTbl.subledgerid, innerTbl.ledgerid;

    -- Insert unclosed fiscal years before FromDate
    INSERT INTO temp_unclosed_fiscal_year (fiscalyearid)
    SELECT fiscalyearid
    FROM acc_mst_fiscalyears
    WHERE isactive = TRUE
        AND isclosed = FALSE
        AND startdate < (
            SELECT startdate
            FROM acc_mst_fiscalyears
            WHERE startdate <= p_fromdate
                AND enddate >= p_fromdate
            LIMIT 1
        );

    -- Loop through unclosed fiscal years
    FOR v_fiscalyearid_loop IN SELECT fiscalyearid FROM temp_unclosed_fiscal_year LOOP
        INSERT INTO temp_yearly_opening_balance (balance, subledgerid, ledgerid)
        SELECT COALESCE(SUM(COALESCE(openingdramount, 0)) + SUM(COALESCE(openingtxndramount, 0)) - SUM(COALESCE(openingcramount, 0)) - SUM(COALESCE(openingtxncramount, 0)), 0)::DECIMAL AS balance
             , subledgerid
             , ledgerid
        FROM (
            SELECT CASE 
                    WHEN COALESCE(lbh.openingdrcr, TRUE) = TRUE
                        THEN COALESCE(lbh.openingbalance, 0)
                    ELSE 0
                    END AS openingdramount
                , CASE 
                    WHEN COALESCE(lbh.openingdrcr, TRUE) = FALSE
                        THEN COALESCE(lbh.openingbalance, 0)
                    ELSE 0
                    END AS openingcramount
                , 0::DECIMAL AS openingtxndramount
                , 0::DECIMAL AS openingtxncramount
                , subLed.subledgerid
                , subLed.ledgerid
            FROM acc_ledger led
            JOIN acc_mst_subledger subLed ON led.ledgerid = subLed.ledgerid
            JOIN acc_subledgerbalancehistory lbh ON subLed.subledgerid = lbh.subledgerid AND subLed.hospitalid = lbh.hospitalid
            WHERE lbh.hospitalid = p_hospitalid
                AND lbh.fiscalyearid = v_fiscalyearid_loop
                AND led.isactive = TRUE
                AND subLed.isactive = TRUE
                AND subLed.subledgerid = ANY(v_subledger_id_list)
            
            UNION ALL
            
            SELECT 0::DECIMAL AS openingdramount
                , 0::DECIMAL AS openingcramount
                , COALESCE(txn.dramount, 0)::DECIMAL AS openingtxndramount
                , COALESCE(txn.cramount, 0)::DECIMAL AS openingtxncramount
                , subLed.subledgerid
                , subLed.ledgerid
            FROM acc_txn_subledgerrecords txn
            JOIN acc_mst_subledger subLed ON txn.subledgerid = subLed.subledgerid
            WHERE txn.hospitalid = p_hospitalid
                AND (
                    txn.voucherdate::DATE BETWEEN (
                                    SELECT startdate
                                    FROM acc_mst_fiscalyears
                                    WHERE fiscalyearid = v_fiscalyearid_loop
                                    LIMIT 1
                                    )::DATE
                        AND (
                                    SELECT enddate
                                    FROM acc_mst_fiscalyears
                                    WHERE fiscalyearid = v_fiscalyearid_loop
                                    LIMIT 1
                                    )::DATE
                    )
                AND subLed.isactive = TRUE
                AND txn.isverified = TRUE
                AND txn.subledgerid = ANY(v_subledger_id_list)
        ) innerTbl
        GROUP BY innerTbl.subledgerid, innerTbl.ledgerid;
    END LOOP;

    -- Return Table 1: Opening balance per subledger
    OPEN ref1 FOR
    SELECT SUM(balance)::DECIMAL AS OpeningBalance, subledgerid AS SubLedgerId, ledgerid AS LedgerId
    FROM temp_yearly_opening_balance
    GROUP BY subledgerid, ledgerid;
    RETURN NEXT ref1;

    -- Return Table 2: Transaction Details
    OPEN ref2 FOR
    SELECT data.ledgerid AS LedgerId
        , data.subledgerid AS SubLedgerId
        , data.transactiondate AS TransactionDate
        , data.voucherid AS VoucherId
        , data.vouchernumber AS VoucherNumber
        , SUM(data.txndramount)::DECIMAL AS DrAmount
        , SUM(data.txncramount)::DECIMAL AS CrAmount
    FROM (
        SELECT txn.ledgerid
            , txn.subledgerid
            , txn.voucherdate::DATE AS transactiondate
            , txn.voucherno AS vouchernumber
            , txn.vouchertype AS voucherid
            , COALESCE(txn.dramount, 0)::DECIMAL AS txndramount
            , COALESCE(txn.cramount, 0)::DECIMAL AS txncramount
        FROM acc_mst_subledger subLed 
        JOIN acc_txn_subledgerrecords txn ON subLed.subledgerid = txn.subledgerid
        WHERE txn.hospitalid = p_hospitalid
            AND (txn.voucherdate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
            AND subLed.isactive = TRUE
            AND txn.isverified = TRUE
            AND txn.subledgerid = ANY(v_subledger_id_list)
        ) data
    GROUP BY data.transactiondate
        , data.ledgerid
        , data.subledgerid
        , data.voucherid
        , data.vouchernumber;
    RETURN NEXT ref2;

    -- Cleanup temp tables
    DROP TABLE temp_unclosed_fiscal_year;
    DROP TABLE temp_yearly_opening_balance;
END;
$$ LANGUAGE plpgsql;
