CREATE OR REPLACE FUNCTION sp_acc_rpt_cash_bankbookreport(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_hospitalid INT,
    p_openingfiscalyearid INT,
    p_ledgerids VARCHAR
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
    /* ***********************************************************************
      filename: "sp_acc_rpt_cash_bankbookreport"
      --exec sp_acc_rpt_cash_bankbookreport '2022-07-27','2022-07-27',1,6,'2'
      drop procedure "sp_acc_rpt_cash / bankbookreport"
      s.no.    updatedby/date                        remarks
      1.      dev narayan 25'July'22                  sp script created for cash/bank book report data
      2.      dev narayan 26'March'23                 added isverified filter in acc_transactions table.
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
    					and led1.ledgerid in (
    						select *
    						from string_split(p_ledgerids, ',')
    						)
    				
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
    					and t.isverified = 1
    					and led2.ledgerid in (
    						select *
    						from string_split(p_ledgerids, ',')
    						)
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
    						and led1.ledgerid in (
    							select *
    							from string_split(p_ledgerids, ',')
    							)
    					
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
    						and t.isverified = 1
    						and led2.ledgerid in (
    							select *
    							from string_split(p_ledgerids, ',')
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
    
    	open ref2 for select data.ledgerid
    		,data.transactiondate
    		,data.voucherid
    		,data.vouchernumber
    		,sum(data.txndramount) as "dramount"
    		,sum(data.txncramount) as "cramount"
    	from (
    		select ti1.ledgerid
    			,(t1.transactiondate)::date as "transactiondate"
    			,t1.vouchernumber
    			,t1.voucherid
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
    		where t1.hospitalid = p_hospitalid
    			and (
    				(t1.transactiondate)::date between (p_fromdate)::date
    					and (p_todate)::date
    				)
    			and led3.isactive = 1
    			and t1.isverified = 1
    			and ti1.ledgerid in (
    				select *
    				from string_split(p_ledgerids, ',')
    				)
    		) as data
    	group by data.transactiondate
    		,data.ledgerid
    		,data.voucherid
    		,data.vouchernumber;
        return next ref2;
    end;
END;
$$ LANGUAGE plpgsql;