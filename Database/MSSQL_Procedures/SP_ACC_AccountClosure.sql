CREATE PROCEDURE [dbo].[SP_ACC_AccountClosure]
			@CurrentFiscalYearId int,
			@NextFiscalYearId int,
			@HospitalId int
	AS
	--EXEC [dbo].[SP_ACC_AccountClosure] @CurrentFiscalYearId = 2, @NextFiscalYearId =3, @HospitalId=3
	
	/************************************************************************
	FileName: [SP_ACC_AccountClosure]
	CreatedBy/date: Nagesh /19'June2020
	Description: sp will close current fiscal year. add closing balance and forward closing for next fiscal year as opening balance
	Change History
	S.No.    UpdatedBy/Date                        Remarks
	1       Nagesh /19'June2020						created script for account closure task
	2.      Sud/Nagesh:20Jun'20						HospitalId added for Phrm-Acc Separation
	3.		Nagesh/02Jul'20							sp changes for account closure task working
	4.		Nagesh/12Jul'2020						sp changes for next fiscal year opening balance Dr to cr issue resolution AND Retain Earning balance updation
													we will forward NetProfit into Retain Earning
    5.		Vikas/NageshBB:14th Jul 2020:			added ledgers into current fiscal year if not existed.
	6.		Nagesh: 15 Jul 2020						fix for account close NetProfit forward to Retain Earning logic 
													Normally Expense always Dr and Revenue always Cr but in some case expenses may be Cr and Revenue Dr
													Now i've fixed for this case . This knoledge and conditions explained by Sagar sir
    7.		NageshBB: 17July2021					get codeDetails table values using function. added function here
	8.      Dev Narayan : 20 Dec' 22                Calculation for Subledger added while closing fiscal year.
												    we calculate closing balance of each subledger and forward those 
													balance as opening for next fiscal year except subledgers under the
													group expenses. For expense opening balance for next fiscal year will be 0.
	*************************************************************************/
	BEGIN
	
		IF(@CurrentFiscalYearId IS NOT NULL AND @NextFiscalYearId IS NOT NULL) 
		BEGIN				  
	    --step 0 - check ledger balance history has ledgers for current fiscal year.
				-- if there is no ledger for current fiscal year then we need to insert.
		
		declare @ledgercount int=0
		set @ledgercount =(select COUNT(LedgerId) from ACC_LedgerBalanceHistory where HospitalId=@HospitalId and FiscalYearId=@CurrentFiscalYearId)		
		if(@ledgercount=0)
		begin
			insert into ACC_LedgerBalanceHistory (FiscalYearId,LedgerId,OpeningBalance,OpeningDrCr,ClosingBalance,ClosingDrCr,CreatedBy,CreatedOn,HospitalId)
			select @CurrentFiscalYearId, LedgerId,OpeningBalance,DrCr,0,1,1,GETDATE(),@HospitalId from ACC_Ledger
		end

		--step 1 --Insert subledgerbalnce history record for those subledger which are in 
				 -- subledger master table but are not found in subledgerbalance table.

		INSERT INTO ACC_SubLedgerBalanceHistory (FiscalYearId,SubLedgerId,OpeningBalance,OpeningDrCr,ClosingBalance,ClosingDrCr,CreatedBy,CreatedOn,HospitalId)
			SELECT @CurrentFiscalYearId, SubLedgerId, OpeningBalance, DrCr,0,1,1,GETDATE(),@HospitalId FROM ACC_MST_SubLedger 
			WHERE SubLedgerId NOT IN (SELECT SubLedgerId FROM ACC_SubLedgerBalanceHistory WHERE FiscalYearId = @CurrentFiscalYearId AND HospitalId = @HospitalId)

		--Step 2- delete all ledger list from Ledger_BalanceHistory table for NextFiscalYearId		
		delete from ACC_LedgerBalanceHistory 
		where FiscalYearId=@NextFiscalYearId and HospitalId=@HospitalId

		--Step 3  --Delete all subledger form ACC_SubLedgerBalanceHistory table for NextFiscalYearId

		DELETE FROM ACC_SubLedgerBalanceHistory
			WHERE FiscalYearId = @NextFiscalYearId AND HospitalId = @HospitalId
		
		--Step 4- Update closing balance of CurrentFiscalYear as 0
		Update ACC_LedgerBalanceHistory 
		set ClosingBalance=0, ClosingDrCr=1 
		where FiscalYearId=@CurrentFiscalYearId  and HospitalId=@HospitalId

		--Step 5 -- Update closing balance of CurrentFiscalYear as 0 in ACC_SubLedgerBalanceHistory table

		UPDATE ACC_SubLedgerBalanceHistory
			SET ClosingBalance = 0, ClosingDrCr = 1
			WHERE FiscalYearId = @CurrentFiscalYearId AND HospitalId = @HospitalId

		--Step 6-calculate current fiscal year closing balance with ledgerid
		DECLARE @TBLCurrentFiscalYearCloseBalance TABLE (LedgerId INT Not null unique, Balance float, DrCr bit, hospitalId int)
		Insert into @TBLCurrentFiscalYearCloseBalance(LedgerId, Balance, DrCr, hospitalId)
		select 		
		 LedgerId,
		 Case WHEN Dr>Cr THEN Dr-Cr  ELSE Cr-Dr END AS Balance,
		 Case WHEN Dr>Cr THEN 1  ELSE 0 END AS DrCr	,
		 HospitalId	
		 from 
		 (
			 select l.LedgerId,
			 Case WHEN DrCr=1 THEN isnull(OpeningBalance,0)+isnull(DrAmount,0)  ELSE isnull(DrAmount,0) END AS Dr,
			 Case WHEN DrCr=0 THEN  isnull(OpeningBalance,0)+IsNULL(CrAmount,0) ELSE IsNULL(CrAmount,0) END AS Cr,
			 l.HospitalId
			 from ACC_Ledger l 
			 left join
			 (
						 select LedgerId, sum(DrAmount) DrAmount, sum(CrAmount) CrAmount
						 from 
						 (
								 select LedgerId, Case WHEN DrCr=1 THEN Amount ELSE 0 END AS DrAmount, Case WHEN DrCr=0 THEN Amount ELSE 0 END AS CrAmount
								 from ACC_TransactionItems ti join ACC_Transactions t on t.TransactionId=ti.TransactionId  
								 where t.FiscalYearId=@CurrentFiscalYearId and  t.HospitalId=@HospitalId
						 ) ledTxn group by LedgerId
			  )TxnDetails 
			  on TxnDetails.LedgerId=l.LedgerId and l.HospitalId=@HospitalId

			) a		
		
		--Step 7-calculate current fiscal year closing balance with for each subledger

		DECLARE @SubLedgerTBLCurrentFiscalYearCloseBalance TABLE (SubLedgerId INT Not null unique, Balance float, DrCr bit, hospitalId int)
		Insert into @SubLedgerTBLCurrentFiscalYearCloseBalance(SubLedgerId, Balance, DrCr, hospitalId)
		select 		
		 SubLedgerId,
		 Case WHEN Dr>Cr THEN Dr-Cr  ELSE Cr-Dr END AS Balance,
		 Case WHEN Dr>Cr THEN 1  ELSE 0 END AS DrCr	,
		 HospitalId	
		 from 
		 (
			 select subLedger.SubLedgerId,
			 Case WHEN DrCr=1 THEN isnull(OpeningBalance,0)+isnull(DrAmount,0)  ELSE isnull(DrAmount,0) END AS Dr,
			 Case WHEN DrCr=0 THEN  isnull(OpeningBalance,0)+IsNULL(CrAmount,0) ELSE IsNULL(CrAmount,0) END AS Cr,
			 subLedger.HospitalId
			 from ACC_MST_SubLedger subLedger
			 left join
			 (
				 select SubLedgerId, sum(DrAmount) DrAmount, sum(CrAmount) CrAmount,HospitalId
				 FROM ACC_TXN_SubledgerRecords WHERE
				 FiscalYearId=@CurrentFiscalYearId AND HospitalId=@HospitalId
				 GROUP BY SubLedgerId,HospitalId

			  )TxnDetails 
			  on TxnDetails.SubLedgerId=subLedger.SubLedgerId

			) a

		--Step 8 --Update closing balance of current fiscal Year
		Update ACC_LedgerBalanceHistory 
		set ClosingBalance=bt.Balance, ClosingDrCr=bt.DrCr		
		from @TBLCurrentFiscalYearCloseBalance bt join ACC_LedgerBalanceHistory bh on bt.LedgerId=bh.LedgerId and bt.hospitalId = bh.HospitalId	
		where FiscalYearId=@CurrentFiscalYearId	and  bh.HospitalId = @HospitalId 

		--Step 9 --Update closing balance of current fiscal Year for each subledger

		Update ACC_SubLedgerBalanceHistory 
		set ClosingBalance=bt.Balance, ClosingDrCr=bt.DrCr		
		from @SubLedgerTBLCurrentFiscalYearCloseBalance bt 
		JOIN ACC_SubLedgerBalanceHistory bh on bt.SubLedgerId=bh.SubLedgerId and bt.hospitalId = bh.HospitalId	
		where FiscalYearId=@CurrentFiscalYearId	and  bh.HospitalId = @HospitalId 

		--Step 10- Insert all Ledgers with Next FiscalYearId into ACC_LedgerBalanceHistory, Here default opening balance is 0
		Insert into  ACC_LedgerBalanceHistory (FiscalYearId, LedgerId, OpeningBalance, OpeningDrCr,CreatedBy, CreatedOn, HospitalId)		
		select @NextFiscalYearId, LedgerId,0,1,1 as CreatedBy, GETDATE() as CreatedOn, hospitalId
		from @TBLCurrentFiscalYearCloseBalance where HospitalId=@HospitalId

		--Step 11- Insert all subledger with Next FiscalYearId into ACC_SubLedgerBalanceHistory, Here default opening balance is 0

		Insert into  ACC_SubLedgerBalanceHistory (FiscalYearId, SubLedgerId, OpeningBalance, OpeningDrCr,CreatedBy, CreatedOn, HospitalId)		
		select @NextFiscalYearId, SubLedgerId,0,1,1 as CreatedBy, GETDATE() as CreatedOn, hospitalId
		from @SubLedgerTBLCurrentFiscalYearCloseBalance where HospitalId=@HospitalId

		--Step 12 - Update Next fiscal year assets and liability opening balance from current fiscal year closing balance
		 declare @Assets varchar(50)=(select dbo.FN_ACC_GetNameByCode('008',@HospitalId)'008')	
		 declare @Liabilities varchar(50)=(select dbo.FN_ACC_GetNameByCode('009',@HospitalId))
		
		 update ACC_LedgerBalanceHistory
		 set OpeningBalance=bt.Balance, OpeningDrCr=bt.DrCr
		 from @TBLCurrentFiscalYearCloseBalance bt join ACC_LedgerBalanceHistory bh on bt.LedgerId=bh.LedgerId and bt.hospitalId=bh.HospitalId
		 where FiscalYearId=@NextFiscalYearId  
		 and bt.LedgerId in
		 (
			   select LedgerId from ACC_Ledger l where LedgerGroupId in ( select LedgerGroupId from ACC_MST_LedgerGroup
			   where HospitalId=@HospitalId and PrimaryGroup in (@Assets, @Liabilities)) and l.HospitalId=@HospitalId			                       
		 )		


		 --Step 13 - Update Next fiscal year subledger opening balance from current fiscal year closing balance except
		          --for the those subledger under ledgergroup expenses.
		 UPDATE ACC_SubLedgerBalanceHistory
		 set OpeningBalance=bt.Balance, OpeningDrCr=bt.DrCr
		 from @SubLedgerTBLCurrentFiscalYearCloseBalance bt join ACC_SubLedgerBalanceHistory bh on bt.SubLedgerId=bh.SubLedgerId and bt.hospitalId=bh.HospitalId
		 where FiscalYearId=@NextFiscalYearId AND bh.SubLedgerId NOT IN (
		 SELECT SubLedgerId
		 FROM ACC_MST_SubLedger
         WHERE LedgerId NOT IN (
		 SELECT LedgerId
		 FROM ACC_Ledger
		 WHERE LedgerGroupId IN (
				SELECT LedgerGroupId
				FROM ACC_MST_LedgerGroup
				WHERE PrimaryGroup = 'EXPENSES'
				)
		    )
		 )
		 
		 --Step 14 -Forward Net Profit as Retain Earning for next fiscal year
		 declare @RetainEarnLedgerName varchar(50)=(select dbo.FN_ACC_GetNameByCode('016',@HospitalId))		
		 declare @Revenue varchar(50)=(select dbo.FN_ACC_GetNameByCode('001',@HospitalId))
		 declare @Expenses varchar(50)=(dbo.FN_ACC_GetNameByCode('002',@HospitalId))
		 --revenue always Cr and Expenses alway Dr
		 Declare @TblNetProfit TABLE (NetProfit float, DrCr bit)
		 
			 insert into @TblNetProfit(NetProfit, DrCr)				
			 select case when ExpDr > RevCr then ExpDr-RevCr else RevCr-ExpDr end NetProfit,
			 case when ExpDr > RevCr then 1 else 0 end DrCr from
			 (
			select (ExpDr-ExpCr)as ExpDr, (RevCr-RevDr) RevCr from (
			select  
			isnull((select sum(balance) as Expense from @TBLCurrentFiscalYearCloseBalance where DrCr=1 and  LedgerId in  
				(
					select l1.Ledgerid from   ACC_Ledger l1 
					join ACC_MST_LedgerGroup lg on l1.LedgerGroupId=lg.LedgerGroupId
					where l1.HospitalId=@HospitalId AND lg.HospitalId=@HospitalId AND PrimaryGroup in ('Expenses')
				) 
			),0) as ExpDr,
			isnull((select sum(balance) as Expense from @TBLCurrentFiscalYearCloseBalance where DrCr=0 and  LedgerId in  
				(
					select l1.Ledgerid from   ACC_Ledger l1 
					join ACC_MST_LedgerGroup lg on l1.LedgerGroupId=lg.LedgerGroupId
					where l1.HospitalId=@HospitalId AND lg.HospitalId=@HospitalId AND PrimaryGroup in ('Expenses')
				) 
			),0) as ExpCr,
			Isnull((select sum(balance) as Revenue	from @TBLCurrentFiscalYearCloseBalance  where DrCr=1 and  LedgerId in  
				(
					select l.Ledgerid from   ACC_Ledger l 
					join ACC_MST_LedgerGroup lg on l.LedgerGroupId=lg.LedgerGroupId
					where l.HospitalId=@HospitalId AND lg.HospitalId=@HospitalId AND PrimaryGroup in ('Revenue')
				)
			),0) as RevDr,
			isnull((select sum(balance) as Revenue	from @TBLCurrentFiscalYearCloseBalance  where DrCr=0 and  LedgerId in  
				(
					select l.Ledgerid from   ACC_Ledger l 
					join ACC_MST_LedgerGroup lg on l.LedgerGroupId=lg.LedgerGroupId
					where l.HospitalId=@HospitalId AND lg.HospitalId=@HospitalId AND PrimaryGroup in ('Revenue')
				)
			),0) as RevCr
			)a) b
		

		 Declare @RetainEarnLedId int= (select LedgerId from ACC_Ledger where LedgerName=@RetainEarnLedgerName)	
		 Declare @TblRetainEarningOpening  table (OpeningBalance float, DrCr bit)

		 insert into @TblRetainEarningOpening (OpeningBalance, DrCr)
		 select OpeningBalance,OpeningDrCr from ACC_LedgerBalanceHistory where FiscalYearId=@NextFiscalYearId and HospitalId=@HospitalId and LedgerId=@RetainEarnLedId
		 
		 Declare @RetainEarnDrCr bit, @RetainEarnBalance float
			IF((select top 1 DrCr from @TblNetProfit) = (select top 1 DrCr from @TblRetainEarningOpening))				
				BEGIN  
				  set @RetainEarnDrCr=(select top 1 DrCr from @TblNetProfit)
				  set @RetainEarnBalance=(select top 1 NetProfit from @TblNetProfit)+ (select top 1 OpeningBalance from @TblRetainEarningOpening)				   
				END  
				ELSE IF((select top 1 NetProfit from @TblNetProfit) > (select top 1 OpeningBalance from @TblRetainEarningOpening))									
				BEGIN  
					set @RetainEarnDrCr=(select top 1 DrCr from @TblNetProfit)
					set @RetainEarnBalance=(select top 1 NetProfit from @TblNetProfit)- (select top 1 OpeningBalance from @TblRetainEarningOpening)				   
				END
				ELSE
				BEGIN
					set @RetainEarnDrCr=(select top 1 DrCr from @TblRetainEarningOpening)
					set @RetainEarnBalance=(select top 1 OpeningBalance from @TblRetainEarningOpening)-(select top 1 NetProfit from @TblNetProfit)
				END		 
		update ACC_LedgerBalanceHistory 
		set OpeningBalance= @RetainEarnBalance, OpeningDrCr=@RetainEarnDrCr
		where LedgerId=@RetainEarnLedId
		and FiscalYearId=@NextFiscalYearId AND HospitalId=@HospitalId
				
		--Step 15- Update LedgerOpening Balance of Ledger table 
		update ACC_Ledger set OpeningBalance=bh.OpeningBalance, DrCr=bh.OpeningDrCr
		from ACC_LedgerBalanceHistory bh join ACC_Ledger l on l.LedgerId=bh.LedgerId
		where bh.FiscalYearId=@NextFiscalYearId and bh.HospitalId=@HospitalId

		--Step 16- Update LedgerOpening Balance of SubLedgerTable table 

		UPDATE ACC_MST_SubLedger set OpeningBalance=bh.OpeningBalance, DrCr=bh.OpeningDrCr
		from ACC_SubLedgerBalanceHistory bh join ACC_MST_SubLedger l on l.SubLedgerId=bh.SubLedgerId
		where bh.FiscalYearId=@NextFiscalYearId and bh.HospitalId=@HospitalId

	 --Step 17- Update current fiscal year make IsClosed=true
       update ACC_MST_FiscalYears set IsClosed=1
       where FiscalYearId=@CurrentFiscalYearId
		END		
	END