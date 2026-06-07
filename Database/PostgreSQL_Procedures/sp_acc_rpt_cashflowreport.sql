CREATE OR REPLACE FUNCTION sp_acc_rpt_cashflowreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_fiscalyearid INT DEFAULT NULL,
    p_hospitalid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_ledgerids VARCHAR := (
			SELECT STRING_AGG(CAST(LedgerId AS TEXT), ',')
			FROM ACC_Ledger
			WHERE LedgerGroupId = (
					SELECT LedgerGroupId
					FROM ACC_MST_LedgerGroup
					WHERE Name = 'ACA_CASH_IN_HAND'
					)
			);
    v_openingbalancefromdate TIMESTAMP := (
			SELECT  StartDate
			FROM ACC_MST_FiscalYears
			WHERE FiscalYearId = p_fiscalyearid LIMIT 1
			);
    v_openingbalancetodate TIMESTAMP := (
			SELECT p_fromdate - 1
			);
BEGIN
    -- exec "sp_acc_rpt_cashflowreport" '2022-07-10','2022-10-21',5,1
    
    
     /* -------------------------------------------------------------------------
      s.no.    updatedby/date                        remarks
      1.      dev narayan 21 oct'22              SP Script created for cash flow report data
      2.      Dev Narayan 26'march'23            Added IsVerified filter in ACC_Transactions table.
      ************************************************************************ */
    BEGIN
    	
    	
    	
    
    	DROP TABLE IF EXISTS temp_UnclosedFiscalYear;CREATE TEMP TABLE temp_UnclosedFiscalYear (
    		FiscalYearId INT
    		);
    
    	DROP TABLE IF EXISTS temp_YearlyOpeningBalance;CREATE TEMP TABLE temp_YearlyOpeningBalance (Balance INT);
    
    	INSERT INTO temp_YearlyOpeningBalance (Balance)
    	SELECT (
    			SELECT COALESCE(sum(COALESCE(OpeningDrAmount, 0)) + sum(COALESCE(OpeningTxnDrAmount, 0)) - sum(COALESCE(OpeningCrAmount, 0)) - sum(COALESCE(OpeningTxnCrAmount, 0)), 0) AS OpeningBalance
    			FROM (
    				--get ledger opening balance from ledger balance history table
    				SELECT CASE 
    						WHEN COALESCE(lbh1.OpeningDrCr, 1) = 1
    							THEN COALESCE(lbh1.OpeningBalance, 0)
    						ELSE 0
    						END AS OpeningDrAmount
    					,CASE 
    						WHEN lbh1.OpeningDrCr = 0
    							THEN COALESCE(lbh1.OpeningBalance, 0)
    						ELSE 0
    						END AS OpeningCrAmount
    					,0 AS OpeningTxnDrAmount
    					,0 AS OpeningTxnCrAmount
    				FROM ACC_Ledger led1
    				JOIN ACC_LedgerBalanceHistory lbh1 ON led1.LedgerId = lbh1.LedgerId
    					AND led1.HospitalId = lbh1.HospitalId
    				WHERE lbh1.HospitalId = p_hospitalid
    					AND lbh1.FiscalYearId = p_fiscalyearid
    					AND led1.IsActive = 1
    					AND led1.LedgerId IN (
    						SELECT *
    						FROM STRING_SPLIT(v_ledgerids, ',')
    						)
    				
    				UNION ALL
    				
    				--get balance from transaction table from opening fiscal year start date to FromDate-1
    				SELECT 0 AS OpeningDrAmount
    					,0 AS OpeningCrAmount
    					,CASE 
    						WHEN ti.DrCr = 1
    							THEN COALESCE(ti.Amount, 0)
    						ELSE 0
    						END AS OpeningTxnDrAmount
    					,CASE 
    						WHEN ti.DrCr = 0
    							THEN COALESCE(ti.Amount, 0)
    						ELSE 0
    						END AS OpeningTxnCrAmount
    				FROM ACC_Transactions t
    				JOIN ACC_TransactionItems ti ON t.TransactionId = ti.TransactionId
    				JOIN ACC_Ledger led2 ON led2.LedgerId = ti.LedgerId
    				WHERE t.HospitalId = p_hospitalid
    					AND (
    						(t.TransactionDate)::DATE BETWEEN (v_openingbalancefromdate)::DATE
    							AND (v_openingbalancetodate)::DATE
    						)
    					AND led2.IsActive = 1
    					AND t.IsVerified = 1
    					AND led2.LedgerId IN (
    						SELECT *
    						FROM STRING_SPLIT(v_ledgerids, ',')
    						)
    				) AS innerTbl
    			);
    
    	INSERT INTO temp_UnclosedFiscalYear (FiscalYearId)
    	SELECT (
    			SELECT FiscalYearId
    			FROM ACC_MST_FiscalYears
    			WHERE IsActive = 1
    				AND IsClosed = 0
    				AND StartDate < (
    					SELECT StartDate
    					FROM ACC_MST_FiscalYears
    					WHERE StartDate <= p_fromdate
    						AND EndDate >= p_fromdate
    					)
    			);
    
    	WHILE (
    			(
    				SELECT count(*)
    				FROM temp_UnclosedFiscalYear
    				) > 0
    			)
    	LOOP
    		INSERT INTO temp_YearlyOpeningBalance (Balance)
    		SELECT (
    				SELECT COALESCE(sum(COALESCE(OpeningDrAmount, 0)) + sum(COALESCE(OpeningTxnDrAmount, 0)) - sum(COALESCE(OpeningCrAmount, 0)) - sum(COALESCE(OpeningTxnCrAmount, 0)), 0) AS OpeningBalance
    				FROM (
    					--get ledger opening balance from ledger balance history table
    					SELECT CASE 
    							WHEN COALESCE(lbh1.OpeningDrCr, 1) = 1
    								THEN COALESCE(lbh1.OpeningBalance, 0)
    							ELSE 0
    							END AS OpeningDrAmount
    						,CASE 
    							WHEN lbh1.OpeningDrCr = 0
    								THEN COALESCE(lbh1.OpeningBalance, 0)
    							ELSE 0
    							END AS OpeningCrAmount
    						,0 AS OpeningTxnDrAmount
    						,0 AS OpeningTxnCrAmount
    					FROM ACC_Ledger led1
    					JOIN ACC_LedgerBalanceHistory lbh1 ON led1.LedgerId = lbh1.LedgerId
    						AND led1.HospitalId = lbh1.HospitalId
    					WHERE lbh1.HospitalId = p_hospitalid
    						AND lbh1.FiscalYearId = (
    							SELECT  FiscalYearId
    							FROM temp_UnclosedFiscalYear LIMIT 1
    							)
    						AND led1.IsActive = 1
    						AND led1.LedgerId IN (
    							SELECT *
    							FROM STRING_SPLIT(v_ledgerids, ',')
    							)
    					
    					UNION ALL
    					
    					--get balance from transaction table from opening fiscal year start date to FromDate-1
    					SELECT 0 AS OpeningDrAmount
    						,0 AS OpeningCrAmount
    						,CASE 
    							WHEN ti.DrCr = 1
    								THEN COALESCE(ti.Amount, 0)
    							ELSE 0
    							END AS OpeningTxnDrAmount
    						,CASE 
    							WHEN ti.DrCr = 0
    								THEN COALESCE(ti.Amount, 0)
    							ELSE 0
    							END AS OpeningTxnCrAmount
    					FROM ACC_Transactions t
    					JOIN ACC_TransactionItems ti ON t.TransactionId = ti.TransactionId
    					JOIN ACC_Ledger led2 ON led2.LedgerId = ti.LedgerId
    					WHERE t.HospitalId = p_hospitalid
    						AND (
    							(t.TransactionDate)::DATE BETWEEN ((
    											SELECT StartDate
    											FROM ACC_MST_FiscalYears
    											WHERE FiscalYearId = (
    													SELECT  FiscalYearId
    													FROM temp_UnclosedFiscalYear LIMIT 1
    													)
    											))::DATE
    								AND ((
    											SELECT EndDate
    											FROM ACC_MST_FiscalYears
    											WHERE FiscalYearId = (
    													SELECT  FiscalYearId
    													FROM temp_UnclosedFiscalYear LIMIT 1
    													)
    											))::DATE
    							)
    						AND led2.IsActive = 1
    						AND t.IsVerified = 1
    						AND led2.LedgerId IN (
    							SELECT *
    							FROM STRING_SPLIT(v_ledgerids, ',')
    							)
    					) as innertbl
    				);
    
    		delete from temp_unclosedfiscalyear where ctid = (select ctid from temp_unclosedfiscalyear limit 1);
    	end loop;
    
    	open ref1 for select sum(balance) as openingbalance
    	from temp_yearlyopeningbalance;
        return next ref1;
    
    	drop table if exists temp_unclosedfiscalyear;
    
    	drop table if exists temp_yearlyopeningbalance;
    
    	open ref2 for select (select json_agg(t) from (select pmgroup.primarygroupname
    		,(
    			(select json_agg(t) from (select coa.chartofaccountname as "coa"
    				,(
    					(select json_agg(t) from (select outerledgroup.ledgergroupname, outerledgroup.coa
    						,(
    							(select json_agg(t) from (select led.ledgername
    								,ledgroup.ledgergroupname
    								,ledgroup.ledgergroupid
    								,led.code
    								,sum(case 
    										when item.drcr = 1
    											then item.amount
    										else 0
    										end) as "amountdr"
    								,sum(case 
    										when item.drcr = 0
    											then item.amount
    										else 0
    										end) as "amountcr",
    										ledgroup.coa
    							from acc_transactions txn
    							join acc_transactionitems item on txn.transactionid = item.transactionid
    							join acc_ledger led on item.ledgerid = led.ledgerid
    							join acc_mst_ledgergroup ledgroup on led.ledgergroupid = ledgroup.ledgergroupid
    							where (txn.transactiondate)::date >= p_fromdate
    								and (txn.transactiondate)::date <= p_todate
    								and ledgroup.ledgergroupname = outerledgroup.ledgergroupname
    								and ledgroup.coa = outerledgroup.coa
    								and txn.isverified = 1
    							group by led.ledgername
    								,ledgroup.ledgergroupname
    								,led.code
    								,item.drcr
    								,ledgroup.ledgergroupid
    								,ledgroup.coa) as "t")::text
    							) as ledgerslist
    					from acc_mst_ledgergroup outerledgroup
    					where outerledgroup.coa = coa.chartofaccountname
    					group by outerledgroup.ledgergroupname,outerledgroup.coa) as "t")::text
    					) as ledgergrouplist
    			from acc_mst_chartofaccounts coa
    			join acc_mst_primarygroup pg on coa.primarygroupid = pg.primarygroupid
    			where pmgroup.primarygroupname = pg.primarygroupname
    			group by coa.chartofaccountname) as "t")::text
    			) as coalist
    	from acc_mst_primarygroup pmgroup
    	group by pmgroup.primarygroupname) as "t")::text;
        return next ref2;
    end;
END;
$$ LANGUAGE plpgsql;