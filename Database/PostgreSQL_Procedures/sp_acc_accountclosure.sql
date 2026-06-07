CREATE OR REPLACE FUNCTION sp_acc_accountclosure(
    p_currentfiscalyearid INT,
    p_nextfiscalyearid INT,
    p_hospitalid INT
)
RETURNS void AS $$
DECLARE
    v_ledgercount INT := 0;
    v_assets VARCHAR := (select FN_ACC_GetNameByCode('008',p_hospitalid)'008');
    v_liabilities VARCHAR := (select FN_ACC_GetNameByCode('009',p_hospitalid));
    v_retainearnledgername VARCHAR := (select FN_ACC_GetNameByCode('016',p_hospitalid));
    v_revenue VARCHAR := (select FN_ACC_GetNameByCode('001',p_hospitalid));
    v_expenses VARCHAR := (FN_ACC_GetNameByCode('002',p_hospitalid));
    v_retainearnledid INT := (select LedgerId from ACC_Ledger where LedgerName=v_retainearnledgername);
    v_retainearndrcr BOOLEAN;
    v_retainearnbalance FLOAT;
BEGIN
    DROP TABLE IF EXISTS v_tblcurrentfiscalyearclosebalance;
    CREATE TEMP TABLE v_tblcurrentfiscalyearclosebalance (
        LedgerId INT Not null unique, Balance float, DrCr BOOLEAN, hospitalId int
    );
    DROP TABLE IF EXISTS v_subledgertblcurrentfiscalyearclosebalance;
    CREATE TEMP TABLE v_subledgertblcurrentfiscalyearclosebalance (
        SubLedgerId INT Not null unique, Balance float, DrCr BOOLEAN, hospitalId int
    );
    DROP TABLE IF EXISTS v_tblnetprofit;
    CREATE TEMP TABLE v_tblnetprofit (
        NetProfit float, DrCr BOOLEAN
    );
    DROP TABLE IF EXISTS v_tblretainearningopening;
    CREATE TEMP TABLE v_tblretainearningopening (
        OpeningBalance float, DrCr BOOLEAN
    );
    --exec "sp_acc_accountclosure" p_currentfiscalyearid = 2, p_nextfiscalyearid =3, p_hospitalid=3
    	
    	/************************************************************************
    	filename: "sp_acc_accountclosure"
    	createdby/date: nagesh /19'June2020
    	Description: sp will close current fiscal year. add closing balance and forward closing for next fiscal year as opening balance
    	Change History
    	S.No.    UpdatedBy/Date                        Remarks
    	1       Nagesh /19'june2020						created script for account closure task
    	2.      sud/nagesh:20jun'20						HospitalId added for Phrm-Acc Separation
    	3.		Nagesh/02Jul'20							sp changes for account closure task working
    	4.		nagesh/12jul'2020						sp changes for next fiscal year opening balance Dr to cr issue resolution AND Retain Earning balance updation
    													we will forward NetProfit into Retain Earning
        5.		Vikas/NageshBB:14th Jul 2020:			added ledgers into current fiscal year if not existed.
    	6.		Nagesh: 15 Jul 2020						fix for account close NetProfit forward to Retain Earning logic 
    													Normally Expense always Dr and Revenue always Cr but in some case expenses may be Cr and Revenue Dr
    													Now i've fixed for this case . this knoledge and conditions explained by sagar sir
        7.		nageshbb: 17july2021					get codedetails table values using function. added function here
    	8.      dev narayan : 20 dec' 22                Calculation for Subledger added while closing fiscal year.
    												    we calculate closing balance of each subledger and forward those 
    													balance as opening for next fiscal year except subledgers under the
    													group expenses. For expense opening balance for next fiscal year will be 0.
    	*************************************************************************/
    	BEGIN
    	
    		IF(p_currentfiscalyearid IS NOT NULL AND p_nextfiscalyearid IS NOT NULL) 
    		THEN				  
    	    --step 0 - check ledger balance history has ledgers for current fiscal year.
    				-- if there is no ledger for current fiscal year then we need to insert.
    		
    		
    		v_ledgercount := (select COUNT(LedgerId) from ACC_LedgerBalanceHistory where HospitalId=p_hospitalid and FiscalYearId=p_currentfiscalyearid);		
    		if(v_ledgercount=0)
    		THEN
    			insert into ACC_LedgerBalanceHistory (FiscalYearId,LedgerId,OpeningBalance,OpeningDrCr,ClosingBalance,ClosingDrCr,CreatedBy,CreatedOn,HospitalId)
    			select p_currentfiscalyearid, LedgerId,OpeningBalance,DrCr,0,1,1,CURRENT_TIMESTAMP,p_hospitalid from ACC_Ledger;
    		END IF;
    
    		--step 1 --INSERT INTO subledgerbalnce history record for those subledger which are in 
    				 -- subledger master table but are not found in subledgerbalance table.
    
    		INSERT INTO ACC_SubLedgerBalanceHistory (FiscalYearId,SubLedgerId,OpeningBalance,OpeningDrCr,ClosingBalance,ClosingDrCr,CreatedBy,CreatedOn,HospitalId)
    			SELECT p_currentfiscalyearid, SubLedgerId, OpeningBalance, DrCr,0,1,1,CURRENT_TIMESTAMP,p_hospitalid FROM ACC_MST_SubLedger 
    			WHERE SubLedgerId NOT IN (SELECT SubLedgerId FROM ACC_SubLedgerBalanceHistory WHERE FiscalYearId = p_currentfiscalyearid AND HospitalId = p_hospitalid);
    
    		--Step 2- delete all ledger list from Ledger_BalanceHistory table for NextFiscalYearId		
    		delete from ACC_LedgerBalanceHistory 
    		where FiscalYearId=p_nextfiscalyearid and HospitalId=p_hospitalid;
    
    		--Step 3  --Delete all subledger form ACC_SubLedgerBalanceHistory table for NextFiscalYearId
    
    		DELETE FROM ACC_SubLedgerBalanceHistory
    			WHERE FiscalYearId = p_nextfiscalyearid AND HospitalId = p_hospitalid;
    		
    		--Step 4- Update closing balance of CurrentFiscalYear as 0
    		Update ACC_LedgerBalanceHistory 
    		set ClosingBalance=0, ClosingDrCr=1 
    		where FiscalYearId=p_currentfiscalyearid  and HospitalId=p_hospitalid;
    
    		--Step 5 -- Update closing balance of CurrentFiscalYear as 0 in ACC_SubLedgerBalanceHistory table
    
    		UPDATE ACC_SubLedgerBalanceHistory
    			SET ClosingBalance = 0, ClosingDrCr = 1
    			WHERE FiscalYearId = p_currentfiscalyearid AND HospitalId = p_hospitalid;
    
    		--Step 6-calculate current fiscal year closing balance with ledgerid
    		
    		Insert into v_tblcurrentfiscalyearclosebalance(LedgerId, Balance, DrCr, hospitalId)
    		select 		
    		 LedgerId,
    		 Case WHEN Dr>Cr THEN Dr-Cr  ELSE Cr-Dr END AS Balance,
    		 Case WHEN Dr>Cr THEN 1  ELSE 0 END AS DrCr	,
    		 HospitalId	
    		 from 
    		 (
    			 select l.LedgerId,
    			 Case WHEN DrCr=1 THEN COALESCE(OpeningBalance,0)+COALESCE(DrAmount,0)  ELSE COALESCE(DrAmount,0) END AS Dr,
    			 Case WHEN DrCr=0 THEN  COALESCE(OpeningBalance,0)+COALESCE(CrAmount,0) ELSE COALESCE(CrAmount,0) END AS Cr,
    			 l.HospitalId
    			 from ACC_Ledger l 
    			 left join
    			 (
    						 select LedgerId, sum(DrAmount) AS "DrAmount", sum(CrAmount) AS "CrAmount"
    						 from 
    						 (
    								 select LedgerId, Case WHEN DrCr=1 THEN Amount ELSE 0 END AS DrAmount, Case WHEN DrCr=0 THEN Amount ELSE 0 END AS CrAmount
    								 from ACC_TransactionItems ti join ACC_Transactions t on t.TransactionId=ti.TransactionId  
    								 where t.FiscalYearId=p_currentfiscalyearid and  t.HospitalId=p_hospitalid
    						 ) ledTxn group by LedgerId
    			  )TxnDetails 
    			  on TxnDetails.LedgerId=l.LedgerId and l.HospitalId=p_hospitalid
    
    			) a;		
    		
    		--Step 7-calculate current fiscal year closing balance with for each subledger
    
    		
    		Insert into v_subledgertblcurrentfiscalyearclosebalance(SubLedgerId, Balance, DrCr, hospitalId)
    		select 		
    		 SubLedgerId,
    		 Case WHEN Dr>Cr THEN Dr-Cr  ELSE Cr-Dr END AS Balance,
    		 Case WHEN Dr>Cr THEN 1  ELSE 0 END AS DrCr	,
    		 HospitalId	
    		 from 
    		 (
    			 select subLedger.SubLedgerId,
    			 Case WHEN DrCr=1 THEN COALESCE(OpeningBalance,0)+COALESCE(DrAmount,0)  ELSE COALESCE(DrAmount,0) END AS Dr,
    			 Case WHEN DrCr=0 THEN  COALESCE(OpeningBalance,0)+COALESCE(CrAmount,0) ELSE COALESCE(CrAmount,0) END AS Cr,
    			 subLedger.HospitalId
    			 from ACC_MST_SubLedger subLedger
    			 left join
    			 (
    				 select SubLedgerId, sum(DrAmount) AS "DrAmount", sum(CrAmount) AS "CrAmount",HospitalId
    				 FROM ACC_TXN_SubledgerRecords WHERE
    				 FiscalYearId=p_currentfiscalyearid AND HospitalId=p_hospitalid
    				 GROUP BY SubLedgerId,HospitalId
    
    			  )TxnDetails 
    			  on TxnDetails.SubLedgerId=subLedger.SubLedgerId
    
    			) a;
    
    		--Step 8 --Update closing balance of current fiscal Year
    		Update ACC_LedgerBalanceHistory 
    		set ClosingBalance=bt.Balance, ClosingDrCr=bt.DrCr		
    		from v_tblcurrentfiscalyearclosebalance bt join ACC_LedgerBalanceHistory bh on bt.LedgerId=bh.LedgerId and bt.hospitalId = bh.HospitalId	
    		where FiscalYearId=p_currentfiscalyearid	and  bh.HospitalId = p_hospitalid; 
    
    		--Step 9 --Update closing balance of current fiscal Year for each subledger
    
    		Update ACC_SubLedgerBalanceHistory 
    		set ClosingBalance=bt.Balance, ClosingDrCr=bt.DrCr		
    		from v_subledgertblcurrentfiscalyearclosebalance bt 
    		JOIN ACC_SubLedgerBalanceHistory bh on bt.SubLedgerId=bh.SubLedgerId and bt.hospitalId = bh.HospitalId	
    		where FiscalYearId=p_currentfiscalyearid	and  bh.HospitalId = p_hospitalid; 
    
    		--Step 10- INSERT INTO all Ledgers with Next FiscalYearId into ACC_LedgerBalanceHistory, Here default opening balance is 0
    		Insert into  ACC_LedgerBalanceHistory (FiscalYearId, LedgerId, OpeningBalance, OpeningDrCr,CreatedBy, CreatedOn, HospitalId)		
    		select p_nextfiscalyearid, LedgerId,0,1,1 as CreatedBy, CURRENT_TIMESTAMP as CreatedOn, hospitalId
    		from v_tblcurrentfiscalyearclosebalance where HospitalId=p_hospitalid;
    
    		--Step 11- INSERT INTO all subledger with Next FiscalYearId into ACC_SubLedgerBalanceHistory, Here default opening balance is 0
    
    		Insert into  ACC_SubLedgerBalanceHistory (FiscalYearId, SubLedgerId, OpeningBalance, OpeningDrCr,CreatedBy, CreatedOn, HospitalId)		
    		select p_nextfiscalyearid, SubLedgerId,0,1,1 as CreatedBy, CURRENT_TIMESTAMP as CreatedOn, hospitalId
    		from v_subledgertblcurrentfiscalyearclosebalance where HospitalId=p_hospitalid;
    
    		--Step 12 - Update Next fiscal year assets and liability opening balance from current fiscal year closing balance
    		 	
    		 
    		
    		 update ACC_LedgerBalanceHistory
    		 set OpeningBalance=bt.Balance, OpeningDrCr=bt.DrCr
    		 from v_tblcurrentfiscalyearclosebalance bt join ACC_LedgerBalanceHistory bh on bt.LedgerId=bh.LedgerId and bt.hospitalId=bh.HospitalId
    		 where FiscalYearId=p_nextfiscalyearid  
    		 and bt.LedgerId in
    		 (
    			   select LedgerId from ACC_Ledger l where LedgerGroupId in ( select LedgerGroupId from ACC_MST_LedgerGroup
    			   where HospitalId=p_hospitalid and PrimaryGroup in (v_assets, v_liabilities)) and l.HospitalId=p_hospitalid			                       
    		 );		
    
    
    		 --Step 13 - Update Next fiscal year subledger opening balance from current fiscal year closing balance except
    		          --for the those subledger under ledgergroup expenses.
    		 UPDATE ACC_SubLedgerBalanceHistory
    		 set OpeningBalance=bt.Balance, OpeningDrCr=bt.DrCr
    		 from v_subledgertblcurrentfiscalyearclosebalance bt join ACC_SubLedgerBalanceHistory bh on bt.SubLedgerId=bh.SubLedgerId and bt.hospitalId=bh.HospitalId
    		 where FiscalYearId=p_nextfiscalyearid AND bh.SubLedgerId NOT IN (
    		 SELECT SubLedgerId
    		 FROM ACC_MST_SubLedger
             WHERE LedgerId NOT IN (
    		 SELECT LedgerId
    		 FROM ACC_Ledger
    		 WHERE LedgerGroupId IN (
    				SELECT LedgerGroupId
    				FROM ACC_MST_LedgerGroup
    				WHERE PrimaryGroup = 'expenses'
    				)
    		    )
    		 );
    		 
    		 --Step 14 -Forward Net Profit as Retain Earning for next fiscal year
    		 		
    		 
    		 
    		 --revenue always Cr and Expenses alway Dr
    		 
    		 
    			 insert into v_tblnetprofit(NetProfit, DrCr)				
    			 select case when ExpDr > RevCr then ExpDr-RevCr else RevCr-ExpDr end AS "NetProfit",
    			 case when ExpDr > RevCr then 1 else 0 end AS "DrCr" from
    			 (
    			select (ExpDr-ExpCr)as ExpDr, (RevCr-RevDr) AS "RevCr" from (
    			select  
    			COALESCE((select sum(balance) as Expense from v_tblcurrentfiscalyearclosebalance where DrCr=1 and  LedgerId in  
    				(
    					select l1.Ledgerid from   ACC_Ledger l1 
    					join ACC_MST_LedgerGroup lg on l1.LedgerGroupId=lg.LedgerGroupId
    					where l1.HospitalId=p_hospitalid AND lg.HospitalId=p_hospitalid AND PrimaryGroup in ('expenses')
    				) 
    			),0) as ExpDr,
    			COALESCE((select sum(balance) as Expense from v_tblcurrentfiscalyearclosebalance where DrCr=0 and  LedgerId in  
    				(
    					select l1.Ledgerid from   ACC_Ledger l1 
    					join ACC_MST_LedgerGroup lg on l1.LedgerGroupId=lg.LedgerGroupId
    					where l1.HospitalId=p_hospitalid AND lg.HospitalId=p_hospitalid AND PrimaryGroup in ('expenses')
    				) 
    			),0) as ExpCr,
    			COALESCE((select sum(balance) as Revenue	from v_tblcurrentfiscalyearclosebalance  where DrCr=1 and  LedgerId in  
    				(
    					select l.Ledgerid from   ACC_Ledger l 
    					join ACC_MST_LedgerGroup lg on l.LedgerGroupId=lg.LedgerGroupId
    					where l.HospitalId=p_hospitalid AND lg.HospitalId=p_hospitalid AND PrimaryGroup in ('revenue')
    				)
    			),0) as RevDr,
    			COALESCE((select sum(balance) as Revenue	from v_tblcurrentfiscalyearclosebalance  where DrCr=0 and  LedgerId in  
    				(
    					select l.Ledgerid from   ACC_Ledger l 
    					join ACC_MST_LedgerGroup lg on l.LedgerGroupId=lg.LedgerGroupId
    					where l.HospitalId=p_hospitalid AND lg.HospitalId=p_hospitalid AND PrimaryGroup in ('revenue')
    				)
    			),0) as revcr
    			)a) b;
    		
    
    		 	
    		 
    
    		 insert into v_tblretainearningopening (openingbalance, drcr)
    		 select openingbalance,openingdrcr from acc_ledgerbalancehistory where fiscalyearid=p_nextfiscalyearid and hospitalid=p_hospitalid and ledgerid=v_retainearnledid;
    		 
    		 
    			if((select  drcr from v_tblnetprofit limit 1) = (select  drcr from v_tblretainearningopening limit 1))				
    				then  
    				  v_retainearndrcr := (select  drcr from v_tblnetprofit limit 1);
    				  v_retainearnbalance := (select  netprofit from v_tblnetprofit limit 1)+ (select  openingbalance from v_tblretainearningopening limit 1);				   
    				  
    				elsif((select  netprofit from v_tblnetprofit limit 1) > (select  openingbalance from v_tblretainearningopening limit 1))									
    				then  
    					v_retainearndrcr := (select  drcr from v_tblnetprofit limit 1);
    					v_retainearnbalance := (select  netprofit from v_tblnetprofit limit 1)- (select  openingbalance from v_tblretainearningopening limit 1);				   
    				
    				else
    				
    					v_retainearndrcr := (select  drcr from v_tblretainearningopening limit 1);
    					v_retainearnbalance := (select  openingbalance from v_tblretainearningopening limit 1)-(select  netprofit from v_tblnetprofit limit 1);
    				end if;		 
    		update acc_ledgerbalancehistory 
    		set openingbalance= v_retainearnbalance, openingdrcr=v_retainearndrcr
    		where ledgerid=v_retainearnledid
    		and fiscalyearid=p_nextfiscalyearid and hospitalid=p_hospitalid;
    				
    		--step 15- update ledgeropening balance of ledger table 
    		update acc_ledger set openingbalance=bh.openingbalance, drcr=bh.openingdrcr
    		from acc_ledgerbalancehistory bh join acc_ledger l on l.ledgerid=bh.ledgerid
    		where bh.fiscalyearid=p_nextfiscalyearid and bh.hospitalid=p_hospitalid;
    
    		--step 16- update ledgeropening balance of subledgertable table 
    
    		update acc_mst_subledger set openingbalance=bh.openingbalance, drcr=bh.openingdrcr
    		from acc_subledgerbalancehistory bh join acc_mst_subledger l on l.subledgerid=bh.subledgerid
    		where bh.fiscalyearid=p_nextfiscalyearid and bh.hospitalid=p_hospitalid;
    
    	 --step 17- update current fiscal year make isclosed=true
           update acc_mst_fiscalyears set isclosed=1
           where fiscalyearid=p_currentfiscalyearid;
    		end if;		
    	end;
END;
$$ LANGUAGE plpgsql;