CREATE OR REPLACE FUNCTION sp_acc_rpt_getgroupstatementdata(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_hospitalid INT,
    p_openingfiscalyearid INT,
    p_ledgergroupid INT
)
RETURNS TABLE (
    "Particular" VARCHAR,
    "LedgerId" INT,
    "Code" VARCHAR,
    "OpeningDr" VARCHAR,
    "OpeningCr" VARCHAR,
    "TransactionDr" TIMESTAMP,
    "TransactionCr" TIMESTAMP,
    "OpeningTotal" DECIMAL,
    "OpeningType" VARCHAR,
    "ClosingDr" VARCHAR,
    "ClosingCr" VARCHAR,
    "ClosingTotal" DECIMAL,
    "ClosingType" VARCHAR
) AS $$
DECLARE
    v_openingbalancefromdate TIMESTAMP := (
			SELECT  StartDate
			FROM ACC_MST_FiscalYears
			WHERE FiscalYearId = p_openingfiscalyearid LIMIT 1
			);
    v_openingbalancetodate TIMESTAMP := (
			SELECT p_fromdate - 1
			);
BEGIN
    /* ***********************************************************************
    filename: "sp_acc_rpt_getgroupstatementdata"  
    createdby/date: nageshbb/03 jan 2021
    description: this sp return group statement reprot data. all are ledgers under selected ledgergroup
    with opening, txn, closing balance details. 
    s.no.    updatedby/date                        remarks
    1.      nageshbb:03jan2021                      sp script created for get group statement report data
    2.      dev narayan 26'March'23                 added isverified filter in acc_transactions table.
    3.      devn 4th july'23                        Added FiscalyearId filter in ledgerbalancehistory table.
    ************************************************************************ */
    --Exec "SP_ACC_RPT_GetGroupStatementData" 3,2,1
    
    	
    	
    
    	RETURN QUERY SELECT led.LedgerName AS "Particular"
    		,led.LedgerId
    		,led.Code
    		,OuterTable.OpeningDr
    		,OuterTable.OpeningCr
    		,OuterTable.TransactionDr
    		,OuterTable.TransactionCr
    		,0 AS "OpeningTotal"
    		,'' AS "OpeningType"
    		,(OpeningDr + TransactionDr) AS "ClosingDr"
    		,(OpeningCr + TransactionCr) AS "ClosingCr"
    		,0 AS "ClosingTotal"
    		,'' AS "ClosingType"
    	from acc_ledger led
    	join acc_ledgerbalancehistory lbh on lbh.ledgerid = led.ledgerid
    	join (
    		--here we will get actual opening balance for every ledger from below query (opening bal + txn as openign balance)
    		--also we will get transaction dr and cr balance within date
    		select ledgerid
    			,sum(openingdramount) + sum(openingtxndramount) AS "OpeningDr"
    			,sum(openingcramount) + sum(openingcramount) AS "OpeningCr"
    			,sum(txndramount) AS "TransactionDr"
    			,sum(txncramount) AS "TransactionCr"
    		from (
    			--get ledger opening balance from ledger balance history table
    			select led1.ledgerid
    				,case 
    					when coalesce(lbh1.openingdrcr, 1) = 1
    						then coalesce(lbh1.openingbalance, 0)
    					else 0
    					end as openingdramount
    				,case 
    					when lbh1.openingdrcr = 0
    						then coalesce(lbh1.openingbalance, 0)
    					else 0
    					end as openingcramount
    				,0 as openingtxndramount
    				,0 as openingtxncramount
    				,0 as txndramount
    				,0 as txncramount
    			from acc_ledger led1
    			join acc_ledgerbalancehistory lbh1 on led1.ledgerid = lbh1.ledgerid and led1.hospitalid = lbh1.hospitalid
    			where lbh1.hospitalid = p_hospitalid and lbh1.fiscalyearid = p_openingfiscalyearid and led1.isactive = 1 and led1.ledgergroupid = p_ledgergroupid
    			
    			union
    			
    			--get balance from transaction table from opening fiscal year start date to fromdate-1
    			select ti.ledgerid
    				,0 as openingdramount
    				,0 as openingcramount
    				,case 
    					when ti.drcr = 1
    						then coalesce(ti.amount, 0)
    					else 0
    					end as openingtxndramount
    				,case 
    					when ti.drcr = 0
    						then coalesce(ti.amount, 0)
    					else 0
    					end as openingtxncramount
    				,0 as txndramount
    				,0 as txncramount
    			from acc_transactions t
    			join acc_transactionitems ti on t.transactionid = ti.transactionid
    			join acc_ledger led2 on led2.ledgerid = ti.ledgerid
    			where t.hospitalid = p_hospitalid and (
    					(t.transactiondate)::date between (v_openingbalancefromdate)::date
    						and (v_openingbalancetodate)::date
    					) and led2.isactive = 1 and led2.ledgergroupid = p_ledgergroupid and t.isverified = 1
    			
    			union
    			
    			--get transaction dr and cr amount between from date and to date
    			select ti1.ledgerid
    				,0 as openingdramount
    				,0 as openingcramount
    				,0 as openingtxndramount
    				,0 as openingtxncramount
    				,case 
    					when ti1.drcr = 1
    						then coalesce(ti1.amount, 0)
    					else 0
    					end as txndramount
    				,case 
    					when ti1.drcr = 0
    						then coalesce(ti1.amount, 0)
    					else 0
    					end as txncramount
    			from acc_transactions t1
    			join acc_transactionitems ti1 on t1.transactionid = ti1.transactionid
    			join acc_ledger led3 on led3.ledgerid = ti1.ledgerid
    			where t1.hospitalid = p_hospitalid and (
    					(t1.transactiondate)::date between (p_fromdate)::date
    						and (p_todate)::date
    					) and led3.isactive = 1 and led3.ledgergroupid = p_ledgergroupid and t1.isverified = 1
    			) as innertbl
    		group by ledgerid
    		) as outertable on outertable.ledgerid = led.ledgerid
    	where lbh.hospitalid = p_hospitalid and led.isactive = 1 and led.ledgergroupid = p_ledgergroupid and lbh.fiscalyearid = p_openingfiscalyearid
    	order by led.ledgerid;
END;
$$ LANGUAGE plpgsql;