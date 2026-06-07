CREATE OR REPLACE FUNCTION sp_acc_rpt_getprofitandlossdata(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_hospitalid INT
)
RETURNS TABLE (
    "LedgerId" INT,
    "PrimaryGroup" VARCHAR,
    "LedgerName" VARCHAR,
    "COA" VARCHAR,
    "LedgerGroupName" VARCHAR,
    "Code" VARCHAR,
    "DRAmount" DECIMAL,
    "CRAmount" DECIMAL
) AS $$
DECLARE
    v_revenue VARCHAR := (
				SELECT FN_ACC_GetNameByCode('001', p_hospitalid)
				);
    v_expenses VARCHAR := (
				SELECT FN_ACC_GetNameByCode('002', p_hospitalid)
				);
    v_fiscalyearid INT := (
				SELECT  FiscalYearId
				FROM ACC_MST_FiscalYears
				WHERE HospitalId = p_hospitalid
					AND p_fromdate BETWEEN (StartDate)::DATE
						AND (EndDate)::DATE LIMIT 1
				);
    v_hospitalshortname VARCHAR := (
				SELECT  HospitalShortName
				FROM ACC_MST_Hospital LIMIT 1
				);
    v_hospidforopening INT := 0;
BEGIN
    /************************************************************************
      filename: "[sp_acc_rpt_getprofitandlossdata"]
      createdby/date: nagesh /12'June2020
      Description: get records for profit & Loss report of accounting
      Change History
      S.No.    UpdatedBy/Date                        Remarks
      1       Nagesh /12'june2020            created script for get profit and loss report records
      2.      sud/nagesh: 20jun'20           Added HospitalId for Phrm-Separation
      3.      Sud/Nagesh: 25Feb'21           added mid-fiscalyear logic for p&l report correction
                                             if our software started from mid-fisc year, we need to take also the
    								         opening balance of revenue and expenses ledgers.
      4.	  nageshbb: 17july2021			 get codedetails table values using function. added function here
      5.	  nageshbb: 06aug2021			 added query to get all revenue and expense ledger. client side logic will show or hide records with 0 amount
      6.      dev narayan 26'March'23        added isverified filter in acc_transactions table.
      *************************************************************************/
    begin
    	if (
    			p_fromdate is not null
    			and p_todate is not null
    			)
    	then
    		
    		
    		
    		
    		
    
    		--mid fiscal year logic only for charak as of 25thfeb2021--
    		-- we can add other hospital in below if-condition as required--
    		--this will work properly for all hospitals, we just have to add more hospitalname and fiscalyear ids. 
    		if (
    				(
    					v_hospitalshortname = 'CHARAK'
    					and v_fiscalyearid = 2
    					)
    				)
    		then
    			v_hospidforopening := p_hospitalid;
    		end if;
    
    		RETURN QUERY SELECT a.ledgerid
    			,a.primarygroup
    			,a.ledgername
    			,a.coa
    			,a.ledgergroupname
    			,a.code
    			,sum(coalesce(a.dramount, 0)) AS "DRAmount"
    			,sum(coalesce(a.cramount, 0)) AS "CRAmount"
    		from (
    			select l.ledgerid
    				,pg.primarygroupname AS "PrimaryGroup"
    				,l.ledgername
    				,lg.coa
    				,lg.ledgergroupname
    				,l.code
    				,sum(txnitm.dramount) AS "DRAmount"
    				,sum(txnitm.cramount) AS "CRAmount"
    			from acc_transactions txn
    			inner join (
    				select transactionid
    					,ledgerid
    					,case 
    						when drcr = 1
    							then amount
    						else 0
    						end AS "DRAmount"
    					,case 
    						when drcr = 0
    							then amount
    						else 0
    						end AS "CRAmount"
    				from acc_transactionitems
    				where hospitalid = p_hospitalid
    				) txnitm on txn.transactionid = txnitm.transactionid
    			inner join acc_ledger l on txnitm.ledgerid = l.ledgerid
    			inner join acc_mst_ledgergroup lg on l.ledgergroupid = lg.ledgergroupid
    			inner join acc_mst_chartofaccounts coa on coa.chartofaccountid = lg.coaid
    			inner join acc_mst_primarygroup pg on pg.primarygroupid = coa.primarygroupid
    				and pg.primarygroupname in (
    					v_revenue
    					,v_expenses
    					)
    			where l.hospitalid = p_hospitalid
    				and lg.hospitalid = p_hospitalid
    				and (txn.transactiondate)::date between (p_fromdate)::date
    					and (p_todate)::date
    				and txn.isverified = 1
    			group by l.ledgerid
    				,pg.primarygroupname
    				,l.ledgername
    				,lg.coa
    				,lg.ledgergroupname
    				,l.code
    			
    			union all
    			
    			-- below function gives exact same columns as above select query--
    			select *
    			from "fn_acc_getopeningbalanceforpnl_midyear"(v_hospidforopening, v_fiscalyearid, v_revenue, v_expenses)
    			--nageshbb:06 aug 2021: get all revenue and expense ledgers for show on client
    			--client side we have logic to shwo 0 amount ledger or not
    			
    			union all
    			
    			select l.ledgerid
    				,pg.primarygroupname AS "PrimaryGroup"
    				,l.ledgername
    				,coa.chartofaccountname AS "COA"
    				,lg.ledgergroupname
    				,l.code
    				,0 AS "DRAmount"
    				,0 AS "CRAmount"
    			from acc_ledger l
    			inner join acc_mst_ledgergroup lg on l.ledgergroupid = lg.ledgergroupid
    			inner join acc_mst_chartofaccounts coa on coa.chartofaccountid = lg.coaid
    			inner join acc_mst_primarygroup pg on pg.primarygroupid = coa.primarygroupid
    				and pg.primarygroupname in (
    					v_revenue
    					,v_expenses
    					)
    				and l.hospitalid = p_hospitalid
    			) a
    		group by a.ledgerid
    			,a.primarygroup
    			,a.ledgername
    			,a.coa
    			,a.ledgergroupname
    			,a.code;
    	end if; -- end of if
    end; -- end of sp
END;
$$ LANGUAGE plpgsql;