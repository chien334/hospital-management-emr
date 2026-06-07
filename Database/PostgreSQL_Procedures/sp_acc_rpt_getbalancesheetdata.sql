CREATE OR REPLACE FUNCTION sp_acc_rpt_getbalancesheetdata(
    p_todate TIMESTAMP,
    p_hospitalid INT,
    p_fiscalyearid INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_fromdate TIMESTAMP;
    v_revenue VARCHAR := (
				SELECT FN_ACC_GetNameByCode('001', p_hospitalid)
				);
    v_expenses VARCHAR := (
				SELECT FN_ACC_GetNameByCode('002', p_hospitalid)
				);
BEGIN
    --exec "sp_acc_rpt_getbalancesheetdata" v_fromdate = '2020-06-11 18:00:21.657', p_todate ='2020-06-11 18:00:21.657'
    /************************************************************************
      filename: "sp_acc_rpt_getbalancesheetdata"
      createdby/date: nagesh /12'June2020
      Description: get records for balance sheet report of accounting
      Change History
      S.No.    UpdatedBy/Date                        Remarks
      1     Nagesh /12'june2020           created script for get balance sheet report records
      2     sud sir/13'June 2020          updated for get table 2 with NetProfit details
      3.	NageshBB: 17July2021		  get codeDetails table values using function. added function here
      4.    Dev Narayan 26'march'23       added isverified filter in acc_transactions table.
      *************************************************************************/
    begin
    	if (p_todate is not null)
    	then
    		
    
    		v_fromdate := (
    				select startdate
    				from acc_mst_fiscalyears
    				where hospitalid = p_hospitalid
    					and isactive = 1
    					and fiscalyearid = p_fiscalyearid
    				);
    
    		--table:1 get balance sheet details---          
    		open ref1 for select ledinfo.ledgerid
    			,primarygroup
    			,ledgername
    			,coa
    			,ledgergroupname
    			,code
    			,openingbalancedr
    			,openingbalancecr
    			,coalesce(led_totdr, 0) as "dramount"
    			,coalesce(led_totcr, 0) as "cramount"
    		from (
    			select l.ledgerid
    				,l.ledgername
    				,l.code
    				,l.ledgergroupid
    				,lg.primarygroup
    				,lg.coa
    				,lg.ledgergroupname
    				,case 
    					when lbh.openingdrcr = 1
    						then lbh.openingbalance
    					else 0
    					end as "openingbalancedr"
    				,case 
    					when lbh.openingdrcr = 0
    						then lbh.openingbalance
    					else 0
    					end as "openingbalancecr"
    			--from acc_ledger  l inner join acc_mst_ledgergroup lg  --nageshbb-03jul updated for opening balance as per fiscal year
    			from acc_ledgerbalancehistory lbh
    			join acc_ledger l on lbh.ledgerid = l.ledgerid
    			inner join acc_mst_ledgergroup lg on l.ledgergroupid = lg.ledgergroupid
    			where lbh.hospitalid = p_hospitalid
    				and lbh.fiscalyearid = p_fiscalyearid
    			) ledinfo
    		left join (
    			select ledgerid
    				,sum(dramount) as "led_totdr"
    				,sum(cramount) as "led_totcr"
    			from (
    				select txn.transactionid
    					,ledgerid
    					,case 
    						when drcr = 1
    							then amount
    						else 0
    						end as dramount
    					,case 
    						when drcr = 0
    							then amount
    						else 0
    						end as cramount
    				from acc_transactionitems txnitm
    				inner join acc_transactions txn on txnitm.transactionid = txn.transactionid
    				where txn.hospitalid = p_hospitalid
    					and (txn.transactiondate)::date between (v_fromdate)::date
    						and (p_todate)::date
    					and txn.isverified = 1
    				) a
    			group by ledgerid
    			) ledtxndetails on ledinfo.ledgerid = ledtxndetails.ledgerid
    		order by ledinfo.ledgername;
        return next ref1;
    
    		--table2: get netprofit and loss ---
    		
    		
    
    		open ref2 for select sum(revenuebalance) - sum(expensebalance) as "netprofitnloss"
    		from (
    			select case 
    					when primarygroup = v_revenue
    						then totaldramount - totalcramount
    					else 0
    					end as "expensebalance"
    				,case 
    					when primarygroup = v_expenses
    						then totalcramount - totaldramount
    					else 0
    					end as "revenuebalance"
    			from (
    				select ledgrp.primarygroup
    					,sum(led.dramount) as "totaldramount"
    					,sum(led.cramount) as "totalcramount"
    				from
    					--  (		select   ledgerid,ledgergroupid,
    					-- 		case when drcr=1 then openingbalance else 0 end as dramount,
    					-- 		case when drcr=0 then openingbalance else 0 end as cramount,
    					-- 		hospitalid 
    					-- 		from  acc_ledger  where hospitalid=p_hospitalid)   led 
    					(
    					select lbh.ledgerid
    						,l.ledgergroupid
    						,case 
    							when lbh.openingdrcr = 1
    								then lbh.openingbalance
    							else 0
    							end as dramount
    						,case 
    							when lbh.openingdrcr = 0
    								then lbh.openingbalance
    							else 0
    							end as cramount
    						,lbh.hospitalid
    					from acc_ledgerbalancehistory lbh
    					join acc_ledger l on lbh.ledgerid = l.ledgerid
    					where lbh.hospitalid = p_hospitalid
    						and lbh.fiscalyearid = p_fiscalyearid
    					) led
    				inner join acc_mst_ledgergroup ledgrp on led.ledgergroupid = ledgrp.ledgergroupid
    				where led.hospitalid = p_hospitalid
    					and ledgrp.hospitalid = p_hospitalid
    					and ledgrp.primarygroup in (
    						v_revenue
    						,v_expenses
    						)
    				group by ledgrp.primarygroup
    				
    				union all
    				
    				--query:2.2-- get profit&loss on transaction amounts
    				select lg.primarygroup
    					,sum(txnitm.dramount) as "totaldramount"
    					,sum(txnitm.cramount) as "totalcramount"
    				from acc_transactions txn
    				inner join (
    					select transactionid
    						,ledgerid
    						,case 
    							when drcr = 1
    								then amount
    							else 0
    							end as dramount
    						,case 
    							when drcr = 0
    								then amount
    							else 0
    							end as cramount
    					from acc_transactionitems
    					where hospitalid = p_hospitalid
    					) txnitm on txn.transactionid = txnitm.transactionid
    				inner join acc_ledger l on txnitm.ledgerid = l.ledgerid
    				inner join acc_mst_ledgergroup lg on l.ledgergroupid = lg.ledgergroupid
    					and lg.primarygroup in (
    						v_revenue
    						,v_expenses
    						)
    				where txn.hospitalid = p_hospitalid
    					and l.hospitalid = p_hospitalid
    					and (txn.transactiondate)::date between (v_fromdate)::date
    						and (p_todate)::date
    					and txn.isverified = 1
    				group by lg.primarygroup
    				) a
    			) b;
        return next ref2;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;