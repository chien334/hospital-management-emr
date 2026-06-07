CREATE OR REPLACE FUNCTION sp_acc_rpt_day_book_report(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_ledgerid INT,
    p_hospitalid INT,
    p_openingfiscalyearid INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_openingbalancefromdate TIMESTAMP := (
			SELECT  StartDate
			FROM ACC_MST_FiscalYears
			WHERE FiscalYearId = p_openingfiscalyearid LIMIT 1
			);
    v_openingbalancetodate TIMESTAMP := (
			SELECT p_fromdate - 1
			);
BEGIN
    -- =============================================
    -- author:		<author, dev narayan chaudhary>
    -- create date: <create date, 15th aug 2022 >
    -- description:	<description, this stored procedure returns data for day book report in accounting module. >
    -- =============================================
    /* ***********************************************************************
      filename: "sp_acc_rpt_day_book_report"
      --exec "sp_acc_rpt_day_book_report" '2022-07-27','2022-07-27',2,1,6
      s.no.    updatedby/date                        remarks
      1.      dev narayan 15'Aug'22               sp script created for day book report data
      2.      dev narayan 26'March'23             added isverified filter in acc_transactions table.
      ************************************************************************ */
    begin
    	
    	
    
    	drop table if exists temp_unclosedfiscalyear;create temp table temp_unclosedfiscalyear (
    		fiscalyearid int
    		);
    
    	drop table if exists temp_yearlyopeningbalance;create temp table temp_yearlyopeningbalance (balance int);
    
    	insert into temp_yearlyopeningbalance (balance)
    	select (
    			select coalesce(sum(coalesce(openingdramount, 0)) + sum(coalesce(openingtxndramount, 0)) - sum(coalesce(openingcramount, 0)) - sum(coalesce(openingtxncramount, 0)), 0) as openingbalance
    			from (
    				--get ledger opening balance from ledger balance history table
    				select case 
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
    				from acc_ledger led1
    				join acc_ledgerbalancehistory lbh1 on led1.ledgerid = lbh1.ledgerid
    					and led1.hospitalid = lbh1.hospitalid
    				where lbh1.hospitalid = p_hospitalid
    					and lbh1.fiscalyearid = p_openingfiscalyearid
    					and led1.isactive = 1
    					and led1.ledgerid = p_ledgerid
    				
    				union all
    				
    				--get balance from transaction table from opening fiscal year start date to fromdate-1
    				select 0 as openingdramount
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
    				from acc_transactions t
    				join acc_transactionitems ti on t.transactionid = ti.transactionid
    				join acc_ledger led2 on led2.ledgerid = ti.ledgerid
    				where t.hospitalid = p_hospitalid
    					and (
    						(t.transactiondate)::date between (v_openingbalancefromdate)::date
    							and (v_openingbalancetodate)::date
    						)
    					and led2.isactive = 1
    					and led2.ledgerid = p_ledgerid
    					and t.isverified = 1
    				) as innertbl
    			);
    
    	insert into temp_unclosedfiscalyear (fiscalyearid)
    	select (
    			select fiscalyearid
    			from acc_mst_fiscalyears
    			where isactive = 1
    				and isclosed = 0
    				and startdate < (
    					select startdate
    					from acc_mst_fiscalyears
    					where startdate <= p_fromdate
    						and enddate >= p_fromdate
    					)
    			);
    
    	while (
    			(
    				select count(*)
    				from temp_unclosedfiscalyear
    				) > 0
    			)
    	loop
    		insert into temp_yearlyopeningbalance (balance)
    		select (
    				select coalesce(sum(coalesce(openingdramount, 0)) + sum(coalesce(openingtxndramount, 0)) - sum(coalesce(openingcramount, 0)) - sum(coalesce(openingtxncramount, 0)), 0) as openingbalance
    				from (
    					--get ledger opening balance from ledger balance history table
    					select case 
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
    					from acc_ledger led1
    					join acc_ledgerbalancehistory lbh1 on led1.ledgerid = lbh1.ledgerid
    						and led1.hospitalid = lbh1.hospitalid
    					where lbh1.hospitalid = p_hospitalid
    						and lbh1.fiscalyearid = (
    							select  fiscalyearid
    							from temp_unclosedfiscalyear limit 1
    							)
    						and led1.isactive = 1
    						and led1.ledgerid = p_ledgerid
    					
    					union all
    					
    					--get balance from transaction table from opening fiscal year start date to fromdate-1
    					select 0 as openingdramount
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
    					from acc_transactions t
    					join acc_transactionitems ti on t.transactionid = ti.transactionid
    					join acc_ledger led2 on led2.ledgerid = ti.ledgerid
    					where t.hospitalid = p_hospitalid
    						and (
    							(t.transactiondate)::date between ((
    											select startdate
    											from acc_mst_fiscalyears
    											where fiscalyearid = (
    													select  fiscalyearid
    													from temp_unclosedfiscalyear limit 1
    													)
    											))::date
    								and ((
    											select enddate
    											from acc_mst_fiscalyears
    											where fiscalyearid = (
    													select  fiscalyearid
    													from temp_unclosedfiscalyear limit 1
    													)
    											))::date
    							)
    						and led2.isactive = 1
    						and led2.ledgerid = p_ledgerid
    						and t.isverified = 1
    					) as innertbl
    				);
    
    		delete from temp_unclosedfiscalyear where ctid = (select ctid from temp_unclosedfiscalyear limit 1);
    	end loop;
    
    	open ref1 for select sum(balance) as openingbalance
    	from temp_yearlyopeningbalance;
        return next ref1;
    
    	drop table if exists temp_unclosedfiscalyear;
    
    	drop table if exists temp_yearlyopeningbalance;
    
    	open ref2 for select innerdata.ledgerid
    		,innerdata.vouchernumber
    		,innerdata.transactiondate
    		,innerdata.voucherid
    		,case 
    			when coalesce(innerdata.drcr, 0) = 1
    				then sum(amount)
    			else 0
    			end as "dramount"
    		,case 
    			when coalesce(innerdata.drcr, 0) = 0
    				then sum(amount)
    			else 0
    			end as "cramount"
    	from (
    		select item.ledgerid
    			,item.drcr
    			,item.amount
    			,txn.transactiondate
    			,txn.voucherid
    			,txn.vouchernumber
    		from acc_transactionitems item
    		join acc_transactions txn on item.transactionid = txn.transactionid
    		where (txn.transactiondate)::date between (p_fromdate)::date
    				and (p_todate)::date
    			and txn.transactionid in (
    				select transactionid
    				from acc_transactionitems
    				where ledgerid = p_ledgerid
    				)
    			and ledgerid <> p_ledgerid
    			and txn.isverified = 1
    		) as innerdata
    	group by innerdata.ledgerid
    		,innerdata.drcr
    		,innerdata.vouchernumber
    		,innerdata.voucherid
    		,innerdata.transactiondate;
        return next ref2;
    end;
END;
$$ LANGUAGE plpgsql;