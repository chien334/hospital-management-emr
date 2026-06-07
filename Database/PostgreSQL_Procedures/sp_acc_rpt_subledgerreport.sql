CREATE OR REPLACE FUNCTION sp_acc_rpt_subledgerreport(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_hospitalid INT,
    p_openingfiscalyearid INT,
    p_subledgerids VARCHAR
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
      filename: "sp_acc_rpt_subledgerreport"
      --exec sp_acc_rpt_subledgerreport '2022-12-01','2022-12-22',3,6,'67,68,69'
      drop procedure "sp_acc_rpt_subledgerreport"
      s.no.    updatedby/date                        remarks
      1.      dev narayan 22'Dec'22               sp script created for subledger report
      2.      dev narayan 26'March'23             added isverified filter in acc_txn_subledgerrecords table.
      ************************************************************************ */
    begin
    	
    
    	
    
    	drop table if exists temp_unclosedfiscalyear;create temp table temp_unclosedfiscalyear (
    		fiscalyearid int
    		);
    	drop table if exists temp_yearlyopeningbalance;create temp table temp_yearlyopeningbalance (balance int ,subledgerid int,ledgerid int);
    
    	insert into temp_yearlyopeningbalance (balance,subledgerid, ledgerid)
    	select row.openingbalance,row.subledgerid, row.ledgerid from (
    			select coalesce(sum(coalesce(openingdramount, 0)) + sum(coalesce(openingtxndramount, 0)) - sum(coalesce(openingcramount, 0)) - sum(coalesce(openingtxncramount, 0)), 0) as openingbalance
    				,subledgerid as subledgerid
    				,ledgerid
    			from (
    				--get subledger opening balance from subledger balance history table
    				select case 
    						when coalesce(lbh.openingdrcr, 1) = 1
    							then coalesce(lbh.openingbalance, 0)
    						else 0
    						end as openingdramount
    					,case 
    						when lbh.openingdrcr = 0
    							then coalesce(lbh.openingbalance, 0)
    						else 0
    						end as openingcramount
    					,0 as openingtxndramount
    					,0 as openingtxncramount
    					, subled.subledgerid
    					,subled.ledgerid
    				from acc_ledger led
    				join acc_mst_subledger subled on led.ledgerid = subled.ledgerid
    				join acc_subledgerbalancehistory lbh on subled.subledgerid = lbh.subledgerid
    					and subled.hospitalid = lbh.hospitalid
    				where lbh.hospitalid = p_hospitalid
    					and lbh.fiscalyearid = p_openingfiscalyearid
    					and led.isactive = 1
    					and subled.isactive = 1
    					and subled.subledgerid in (
    						select *
    						from string_split(p_subledgerids, ',')
    						)
    				
    				union all
    				
    				--get balance from transaction table from opening fiscal year start date to fromdate-1
    				select 0 as openingdramount
    					,0 as openingcramount
    					,coalesce(txn.dramount,0) as openingtxndramount
    					,coalesce(txn.cramount,0) as openingtxncramount
    					,subled.subledgerid
    					,subled.ledgerid
    				from acc_txn_subledgerrecords txn
    				join acc_mst_subledger subled on txn.subledgerid = subled.subledgerid
    				where txn.hospitalid = p_hospitalid
    					and (
    						(txn.voucherdate)::date between (v_openingbalancefromdate)::date
    							and (v_openingbalancetodate)::date
    						)
    					and subled.isactive = 1
    					and txn.isverified = 1
    					and txn.subledgerid in (
    						select *
    						from string_split(p_subledgerids, ',')
    						)
    				) as innertbl
    				group by innertbl.subledgerid,innertbl.ledgerid
    			) as row;
    
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
    		insert into temp_yearlyopeningbalance (balance,subledgerid,ledgerid)
    		select row.openingbalance, row.subledgerid, row.ledgerid from  (
    				select coalesce(sum(coalesce(openingdramount, 0)) + sum(coalesce(openingtxndramount, 0)) - sum(coalesce(openingcramount, 0)) - sum(coalesce(openingtxncramount, 0)), 0) as openingbalance
    					,subledgerid as subledgerid
    					,ledgerid
    				from (
    					--get ledger opening balance from ledger balance history table
    					select case 
    							when coalesce(lbh.openingdrcr, 1) = 1
    								then coalesce(lbh.openingbalance, 0)
    							else 0
    							end as openingdramount
    						,case 
    							when lbh.openingdrcr = 0
    								then coalesce(lbh.openingbalance, 0)
    							else 0
    							end as openingcramount
    						,0 as openingtxndramount
    						,0 as openingtxncramount
    						,subled.subledgerid
    						,subled.ledgerid
    				from acc_ledger led
    				join acc_mst_subledger subled on led.ledgerid = subled.ledgerid
    				join acc_subledgerbalancehistory lbh on subled.subledgerid = lbh.subledgerid
    						and subled.hospitalid = lbh.hospitalid
    					where lbh.hospitalid = p_hospitalid
    						and lbh.fiscalyearid = (
    							select  fiscalyearid
    							from temp_unclosedfiscalyear limit 1
    							)
    						and led.isactive = 1
    						and subled.isactive = 1
    						and subled.subledgerid in (
    							select *
    							from string_split(p_subledgerids, ',')
    							)
    					
    					union all
    					
    					--get balance from transaction table from opening fiscal year start date to fromdate-1
    					select 0 as openingdramount
    						,0 as openingcramount
    						,coalesce(txn.dramount,0) as openingtxndramount
    						,coalesce(txn.cramount,0) as openingtxncramount
    						,subled.subledgerid
    						,subled.ledgerid
    				from acc_txn_subledgerrecords txn
    				join acc_mst_subledger subled on txn.subledgerid = subled.subledgerid
    					where txn.hospitalid = p_hospitalid
    						and (
    							(txn.voucherdate)::date between ((
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
    						and subled.isactive = 1
    						and txn.isverified = 1
    						and txn.subledgerid in (
    							select *
    							from string_split(p_subledgerids, ',')
    							)
    					) as innertbl
    					group by innertbl.subledgerid,innertbl.ledgerid
    				) as row;
    
    		delete from temp_unclosedfiscalyear where ctid = (select ctid from temp_unclosedfiscalyear limit 1);
    	end loop;
    
    	open ref1 for select sum(balance) as openingbalance, subledgerid ,ledgerid
    	from temp_yearlyopeningbalance
    	group by subledgerid,ledgerid;
        return next ref1;
    
    	drop table if exists temp_unclosedfiscalyear;
    
    	drop table if exists temp_yearlyopeningbalance;
    
    	open ref2 for select data.ledgerid
    		,data.subledgerid
    		,data.transactiondate
    		,data.voucherid
    		,data.vouchernumber
    		,sum(data.txndramount) as "dramount"
    		,sum(data.txncramount) as "cramount"
    	from (
    		select txn.ledgerid
    			,txn.subledgerid
    			,(txn.voucherdate)::date as "transactiondate"
    			,txn.voucherno as "vouchernumber"
    			,txn.vouchertype as "voucherid"
    			,coalesce(txn.dramount,0) as txndramount
    			,coalesce(txn.cramount,0) as txncramount
    		from acc_mst_subledger subled 
    		join acc_txn_subledgerrecords txn on subled.subledgerid = txn.subledgerid
    		where txn.hospitalid = p_hospitalid
    			and (
    				(txn.voucherdate)::date between (p_fromdate)::date
    					and (p_todate)::date
    				)
    			and subled.isactive = 1
    			and txn.isverified = 1
    			and txn.subledgerid in (
    				select *
    				from string_split(p_subledgerids, ',')
    				)
    		) as data
    	group by data.transactiondate
    		,data.ledgerid
    		,data.subledgerid
    		,data.voucherid
    		,data.vouchernumber;
        return next ref2;
    end;
END;
$$ LANGUAGE plpgsql;