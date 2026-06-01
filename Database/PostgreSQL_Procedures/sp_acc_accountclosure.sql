CREATE OR REPLACE FUNCTION sp_acc_accountclosure(
    p_currentfiscalyearid INT,
    p_nextfiscalyearid INT,
    p_hospitalid INT
)
RETURNS INT AS $$
DECLARE
    v_ledgercount INT := 0;
    v_assets VARCHAR(50);
    v_liabilities VARCHAR(50);
    v_retainearnledgername VARCHAR(50);
    v_revenue VARCHAR(50);
    v_expenses VARCHAR(50);
    v_retainearnledid INT;
    v_netprofit DOUBLE PRECISION := 0;
    v_netprofit_drcr BOOLEAN := TRUE;
    v_re_openingbalance DOUBLE PRECISION := 0;
    v_re_opening_drcr BOOLEAN := TRUE;
    v_retainearn_drcr BOOLEAN := TRUE;
    v_retainearn_balance DOUBLE PRECISION := 0;
    v_expdr DOUBLE PRECISION := 0;
    v_expcr DOUBLE PRECISION := 0;
    v_revdr DOUBLE PRECISION := 0;
    v_revcr DOUBLE PRECISION := 0;
BEGIN
    IF (p_currentfiscalyearid IS NOT NULL AND p_nextfiscalyearid IS NOT NULL) THEN
        -- Step 0: check ledger balance history has ledgers for current fiscal year.
        SELECT COUNT("LedgerId") INTO v_ledgercount 
        FROM "ACC_LedgerBalanceHistory" 
        WHERE "HospitalId" = p_hospitalid AND "FiscalYearId" = p_currentfiscalyearid;
        
        IF (v_ledgercount = 0) THEN
            INSERT INTO "ACC_LedgerBalanceHistory" ("FiscalYearId", "LedgerId", "OpeningBalance", "OpeningDrCr", "ClosingBalance", "ClosingDrCr", "CreatedBy", "CreatedOn", "HospitalId")
            SELECT p_currentfiscalyearid, "LedgerId", "OpeningBalance", "DrCr", 0, TRUE, 1, CURRENT_TIMESTAMP, p_hospitalid 
            FROM "ACC_Ledger";
        END IF;

        -- Step 1: Insert subledger balance history records
        INSERT INTO "ACC_SubLedgerBalanceHistory" ("FiscalYearId", "SubLedgerId", "OpeningBalance", "OpeningDrCr", "ClosingBalance", "ClosingDrCr", "CreatedBy", "CreatedOn", "HospitalId")
        SELECT p_currentfiscalyearid, "SubLedgerId", "OpeningBalance", "DrCr", 0, TRUE, 1, CURRENT_TIMESTAMP, p_hospitalid 
        FROM "ACC_MST_SubLedger"
        WHERE "SubLedgerId" NOT IN (
            SELECT "SubLedgerId" 
            FROM "ACC_SubLedgerBalanceHistory" 
            WHERE "FiscalYearId" = p_currentfiscalyearid AND "HospitalId" = p_hospitalid
        );

        -- Step 2: delete all ledger list from Ledger_BalanceHistory table for NextFiscalYearId
        DELETE FROM "ACC_LedgerBalanceHistory" 
        WHERE "FiscalYearId" = p_nextfiscalyearid AND "HospitalId" = p_hospitalid;

        -- Step 3: Delete all subledger form ACC_SubLedgerBalanceHistory table for NextFiscalYearId
        DELETE FROM "ACC_SubLedgerBalanceHistory"
        WHERE "FiscalYearId" = p_nextfiscalyearid AND "HospitalId" = p_hospitalid;

        -- Step 4: Update closing balance of CurrentFiscalYear as 0
        UPDATE "ACC_LedgerBalanceHistory" 
        SET "ClosingBalance" = 0, "ClosingDrCr" = TRUE 
        WHERE "FiscalYearId" = p_currentfiscalyearid AND "HospitalId" = p_hospitalid;

        -- Step 5: Update closing balance of CurrentFiscalYear as 0 in ACC_SubLedgerBalanceHistory
        UPDATE "ACC_SubLedgerBalanceHistory"
        SET "ClosingBalance" = 0, "ClosingDrCr" = TRUE
        WHERE "FiscalYearId" = p_currentfiscalyearid AND "HospitalId" = p_hospitalid;

        -- Step 6: calculate current fiscal year closing balance with ledgerid
        CREATE TEMP TABLE IF NOT EXISTS temp_current_fy_close_balance (
            ledgerid INT NOT NULL UNIQUE,
            balance DOUBLE PRECISION,
            drcr BOOLEAN,
            hospitalid INT
        );
        TRUNCATE temp_current_fy_close_balance;

        INSERT INTO temp_current_fy_close_balance (ledgerid, balance, drcr, hospitalid)
        SELECT 
            "LedgerId",
            CASE WHEN Dr > Cr THEN Dr - Cr ELSE Cr - Dr END AS balance,
            CASE WHEN Dr > Cr THEN TRUE ELSE FALSE END AS drcr,
            "HospitalId"
        FROM (
            SELECT l."LedgerId",
                CASE WHEN l."DrCr" = TRUE THEN COALESCE(l."OpeningBalance", 0) + COALESCE(TxnDetails.DrAmount, 0) ELSE COALESCE(TxnDetails.DrAmount, 0) END AS Dr,
                CASE WHEN l."DrCr" = FALSE THEN COALESCE(l."OpeningBalance", 0) + COALESCE(TxnDetails.CrAmount, 0) ELSE COALESCE(TxnDetails.CrAmount, 0) END AS Cr,
                l."HospitalId"
            FROM "ACC_Ledger" l 
            LEFT JOIN (
                SELECT "LedgerId", SUM(DrAmount) AS DrAmount, SUM(CrAmount) AS CrAmount
                FROM (
                    SELECT "LedgerId", 
                           CASE WHEN "DrCr" = TRUE THEN "Amount" ELSE 0 END AS DrAmount, 
                           CASE WHEN "DrCr" = FALSE THEN "Amount" ELSE 0 END AS CrAmount
                    FROM "ACC_TransactionItems" ti 
                    JOIN "ACC_Transactions" t ON t."TransactionId" = ti."TransactionId"  
                    WHERE t."FiscalYearId" = p_currentfiscalyearid AND t."HospitalId" = p_hospitalid
                ) ledTxn 
                GROUP BY "LedgerId"
            ) TxnDetails ON TxnDetails."LedgerId" = l."LedgerId"
            WHERE l."HospitalId" = p_hospitalid
        ) a;

        -- Step 7: calculate current fiscal year closing balance with for each subledger
        CREATE TEMP TABLE IF NOT EXISTS temp_subledger_current_fy_close_balance (
            subledgerid INT NOT NULL UNIQUE,
            balance DOUBLE PRECISION,
            drcr BOOLEAN,
            hospitalid INT
        );
        TRUNCATE temp_subledger_current_fy_close_balance;

        INSERT INTO temp_subledger_current_fy_close_balance (subledgerid, balance, drcr, hospitalid)
        SELECT 
            "SubLedgerId",
            CASE WHEN Dr > Cr THEN Dr - Cr ELSE Cr - Dr END AS balance,
            CASE WHEN Dr > Cr THEN TRUE ELSE FALSE END AS drcr,
            "HospitalId"
        FROM (
            SELECT subLedger."SubLedgerId",
                CASE WHEN subLedger."DrCr" = TRUE THEN COALESCE(subLedger."OpeningBalance", 0) + COALESCE(TxnDetails.DrAmount, 0) ELSE COALESCE(TxnDetails.DrAmount, 0) END AS Dr,
                CASE WHEN subLedger."DrCr" = FALSE THEN COALESCE(subLedger."OpeningBalance", 0) + COALESCE(TxnDetails.CrAmount, 0) ELSE COALESCE(TxnDetails.CrAmount, 0) END AS Cr,
                subLedger."HospitalId"
            FROM "ACC_MST_SubLedger" subLedger
            LEFT JOIN (
                SELECT "SubLedgerId", SUM("DrAmount") AS DrAmount, SUM("CrAmount") AS CrAmount, "HospitalId"
                FROM "ACC_TXN_SubledgerRecords" 
                WHERE "FiscalYearId" = p_currentfiscalyearid AND "HospitalId" = p_hospitalid
                GROUP BY "SubLedgerId", "HospitalId"
            ) TxnDetails ON TxnDetails."SubLedgerId" = subLedger."SubLedgerId"
            WHERE subLedger."HospitalId" = p_hospitalid
        ) a;

        -- Step 8: Update closing balance of current fiscal Year in ACC_LedgerBalanceHistory
        UPDATE "ACC_LedgerBalanceHistory" bh
        SET "ClosingBalance" = bt.balance, "ClosingDrCr" = bt.drcr
        FROM temp_current_fy_close_balance bt 
        WHERE bt.ledgerid = bh."LedgerId" AND bt.hospitalid = bh."HospitalId"
          AND bh."FiscalYearId" = p_currentfiscalyearid AND bh."HospitalId" = p_hospitalid;

        -- Step 9: Update closing balance of current fiscal Year in ACC_SubLedgerBalanceHistory
        UPDATE "ACC_SubLedgerBalanceHistory" bh
        SET "ClosingBalance" = bt.balance, "ClosingDrCr" = bt.drcr
        FROM temp_subledger_current_fy_close_balance bt 
        WHERE bt.subledgerid = bh."SubLedgerId" AND bt.hospitalid = bh."HospitalId"
          AND bh."FiscalYearId" = p_currentfiscalyearid AND bh."HospitalId" = p_hospitalid;

        -- Step 10: Insert all Ledgers with Next FiscalYearId into ACC_LedgerBalanceHistory
        INSERT INTO "ACC_LedgerBalanceHistory" ("FiscalYearId", "LedgerId", "OpeningBalance", "OpeningDrCr", "CreatedBy", "CreatedOn", "HospitalId")		
        SELECT p_nextfiscalyearid, ledgerid, 0, TRUE, 1, CURRENT_TIMESTAMP, hospitalid
        FROM temp_current_fy_close_balance 
        WHERE hospitalid = p_hospitalid;

        -- Step 11: Insert all subledger with Next FiscalYearId into ACC_SubLedgerBalanceHistory
        INSERT INTO "ACC_SubLedgerBalanceHistory" ("FiscalYearId", "SubLedgerId", "OpeningBalance", "OpeningDrCr", "CreatedBy", "CreatedOn", "HospitalId")		
        SELECT p_nextfiscalyearid, subledgerid, 0, TRUE, 1, CURRENT_TIMESTAMP, hospitalid
        FROM temp_subledger_current_fy_close_balance 
        WHERE hospitalid = p_hospitalid;

        -- Step 12: Update Next fiscal year assets and liability opening balance
        v_assets := fn_acc_getnamebycode('008', p_hospitalid);
        v_liabilities := fn_acc_getnamebycode('009', p_hospitalid);
        
        UPDATE "ACC_LedgerBalanceHistory" bh
        SET "OpeningBalance" = bt.balance, "OpeningDrCr" = bt.drcr
        FROM temp_current_fy_close_balance bt 
        WHERE bt.ledgerid = bh."LedgerId" AND bt.hospitalid = bh."HospitalId"
          AND bh."FiscalYearId" = p_nextfiscalyearid 
          AND bt.ledgerid IN (
              SELECT "LedgerId" 
              FROM "ACC_Ledger" l 
              WHERE "LedgerGroupId" IN (
                  SELECT "LedgerGroupId" 
                  FROM "ACC_MST_LedgerGroup"
                  WHERE "HospitalId" = p_hospitalid AND "PrimaryGroup" IN (v_assets, v_liabilities)
              ) AND l."HospitalId" = p_hospitalid
          );

        -- Step 13: Update Next fiscal year subledger opening balance
        UPDATE "ACC_SubLedgerBalanceHistory" bh
        SET "OpeningBalance" = bt.balance, "OpeningDrCr" = bt.drcr
        FROM temp_subledger_current_fy_close_balance bt 
        WHERE bt.subledgerid = bh."SubLedgerId" AND bt.hospitalid = bh."HospitalId"
          AND bh."FiscalYearId" = p_nextfiscalyearid 
          AND bh."SubLedgerId" NOT IN (
              SELECT "SubLedgerId"
              FROM "ACC_MST_SubLedger"
              WHERE "LedgerId" IN (
                  SELECT "LedgerId"
                  FROM "ACC_Ledger"
                  WHERE "LedgerGroupId" IN (
                      SELECT "LedgerGroupId"
                      FROM "ACC_MST_LedgerGroup"
                      WHERE "PrimaryGroup" = 'EXPENSES'
                  )
              )
          );

        -- Step 14: Forward Net Profit as Retain Earning for next fiscal year
        v_retainearnledgername := fn_acc_getnamebycode('016', p_hospitalid);
        v_revenue := fn_acc_getnamebycode('001', p_hospitalid);
        v_expenses := fn_acc_getnamebycode('002', p_hospitalid);

        -- Calculate Expense Dr
        SELECT COALESCE(SUM(balance), 0) INTO v_expdr
        FROM temp_current_fy_close_balance
        WHERE drcr = TRUE AND ledgerid IN (
            SELECT l1."LedgerId" 
            FROM "ACC_Ledger" l1 
            JOIN "ACC_MST_LedgerGroup" lg ON l1."LedgerGroupId" = lg."LedgerGroupId"
            WHERE l1."HospitalId" = p_hospitalid AND lg."HospitalId" = p_hospitalid AND lg."PrimaryGroup" = 'Expenses'
        );

        -- Calculate Expense Cr
        SELECT COALESCE(SUM(balance), 0) INTO v_expcr
        FROM temp_current_fy_close_balance
        WHERE drcr = FALSE AND ledgerid IN (
            SELECT l1."LedgerId" 
            FROM "ACC_Ledger" l1 
            JOIN "ACC_MST_LedgerGroup" lg ON l1."LedgerGroupId" = lg."LedgerGroupId"
            WHERE l1."HospitalId" = p_hospitalid AND lg."HospitalId" = p_hospitalid AND lg."PrimaryGroup" = 'Expenses'
        );

        -- Calculate Revenue Dr
        SELECT COALESCE(SUM(balance), 0) INTO v_revdr
        FROM temp_current_fy_close_balance
        WHERE drcr = TRUE AND ledgerid IN (
            SELECT l."LedgerId" 
            FROM "ACC_Ledger" l 
            JOIN "ACC_MST_LedgerGroup" lg ON l."LedgerGroupId" = lg."LedgerGroupId"
            WHERE l."HospitalId" = p_hospitalid AND lg."HospitalId" = p_hospitalid AND lg."PrimaryGroup" = 'Revenue'
        );

        -- Calculate Revenue Cr
        SELECT COALESCE(SUM(balance), 0) INTO v_revcr
        FROM temp_current_fy_close_balance
        WHERE drcr = FALSE AND ledgerid IN (
            SELECT l."LedgerId" 
            FROM "ACC_Ledger" l 
            JOIN "ACC_MST_LedgerGroup" lg ON l."LedgerGroupId" = lg."LedgerGroupId"
            WHERE l."HospitalId" = p_hospitalid AND lg."HospitalId" = p_hospitalid AND lg."PrimaryGroup" = 'Revenue'
        );

        v_expdr := v_expdr - v_expcr;
        v_revcr := v_revcr - v_revdr;

        IF (v_expdr > v_revcr) THEN
            v_netprofit := v_expdr - v_revcr;
            v_netprofit_drcr := TRUE;
        ELSE
            v_netprofit := v_revcr - v_expdr;
            v_netprofit_drcr := FALSE;
        END IF;

        SELECT "LedgerId" INTO v_retainearnledid 
        FROM "ACC_Ledger" 
        WHERE "LedgerName" = v_retainearnledgername AND "HospitalId" = p_hospitalid 
        LIMIT 1;

        IF (v_retainearnledid IS NOT NULL) THEN
            SELECT "OpeningBalance", "OpeningDrCr" INTO v_re_openingbalance, v_re_opening_drcr
            FROM "ACC_LedgerBalanceHistory" 
            WHERE "FiscalYearId" = p_nextfiscalyearid AND "HospitalId" = p_hospitalid AND "LedgerId" = v_retainearnledid
            LIMIT 1;

            IF (v_netprofit_drcr = v_re_opening_drcr) THEN
                v_retainearn_drcr := v_netprofit_drcr;
                v_retainearn_balance := v_netprofit + v_re_openingbalance;
            ELSIF (v_netprofit > v_re_openingbalance) THEN
                v_retainearn_drcr := v_netprofit_drcr;
                v_retainearn_balance := v_netprofit - v_re_openingbalance;
            ELSE
                v_retainearn_drcr := v_re_opening_drcr;
                v_retainearn_balance := v_re_openingbalance - v_netprofit;
            END IF;

            UPDATE "ACC_LedgerBalanceHistory" 
            SET "OpeningBalance" = v_retainearn_balance, "OpeningDrCr" = v_retainearn_drcr
            WHERE "LedgerId" = v_retainearnledid AND "FiscalYearId" = p_nextfiscalyearid AND "HospitalId" = p_hospitalid;
        END IF;

        -- Step 15: Update LedgerOpening Balance of Ledger table
        UPDATE "ACC_Ledger" l
        SET "OpeningBalance" = bh."OpeningBalance", "DrCr" = bh."OpeningDrCr"
        FROM "ACC_LedgerBalanceHistory" bh
        WHERE l."LedgerId" = bh."LedgerId"
          AND bh."FiscalYearId" = p_nextfiscalyearid AND bh."HospitalId" = p_hospitalid;

        -- Step 16: Update LedgerOpening Balance of SubLedgerTable table
        UPDATE "ACC_MST_SubLedger" sl
        SET "OpeningBalance" = bh."OpeningBalance", "DrCr" = bh."OpeningDrCr"
        FROM "ACC_SubLedgerBalanceHistory" bh
        WHERE sl."SubLedgerId" = bh."SubLedgerId"
          AND bh."FiscalYearId" = p_nextfiscalyearid AND bh."HospitalId" = p_hospitalid;

        -- Step 17: Update current fiscal year make IsClosed=true
        UPDATE "ACC_MST_FiscalYears" 
        SET "IsClosed" = TRUE
        WHERE "FiscalYearId" = p_currentfiscalyearid;

        -- Drop temp tables
        DROP TABLE temp_current_fy_close_balance;
        DROP TABLE temp_subledger_current_fy_close_balance;
    END IF;

    RETURN 1;
END;
$$ LANGUAGE plpgsql;
