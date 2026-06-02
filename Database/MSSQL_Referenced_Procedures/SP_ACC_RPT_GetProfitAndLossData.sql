CREATE PROCEDURE [dbo].[SP_ACC_RPT_GetProfitAndLossData] @FromDate DATETIME
	,@ToDate DATETIME
	,@HospitalId INT
AS
/************************************************************************
  FileName: [[SP_ACC_RPT_GetProfitAndLossData]]
  CreatedBy/date: Nagesh /12'June2020
  Description: get records for profit & Loss report of accounting
  Change History
  S.No.    UpdatedBy/Date                        Remarks
  1       Nagesh /12'June2020            created script for get profit and loss report records
  2.      Sud/Nagesh: 20Jun'20           Added HospitalId for Phrm-Separation
  3.      Sud/Nagesh: 25Feb'21           Added Mid-FiscalYear logic for P&L Report Correction
                                         If our software started from Mid-Fisc Year, we need to take also the
								         Opening Balance of Revenue and Expenses Ledgers.
  4.	  NageshBB: 17July2021			 get codeDetails table values using function. added function here
  5.	  NageshBB: 06Aug2021			 added query to get all revenue and expense ledger. client side logic will show or hide records with 0 amount
  6.      Dev Narayan 26'March'23        Added IsVerified filter in ACC_Transactions table.
  *************************************************************************/
BEGIN
	IF (
			@FromDate IS NOT NULL
			AND @ToDate IS NOT NULL
			)
	BEGIN
		DECLARE @Revenue VARCHAR(50) = (
				SELECT dbo.FN_ACC_GetNameByCode('001', @HospitalId)
				)
		DECLARE @Expenses VARCHAR(50) = (
				SELECT dbo.FN_ACC_GetNameByCode('002', @HospitalId)
				)
		DECLARE @FiscalYearId INT = (
				SELECT TOP (1) FiscalYearId
				FROM ACC_MST_FiscalYears
				WHERE HospitalId = @HospitalId
					AND @FromDate BETWEEN Convert(DATE, StartDate)
						AND Convert(DATE, EndDate)
				)
		DECLARE @HospitalShortName VARCHAR(200) = (
				SELECT TOP (1) HospitalShortName
				FROM ACC_MST_Hospital
				)
		DECLARE @HospIdForOpening INT = 0

		--Mid fiscal year Logic only for Charak as of 25thFeb2021--
		-- we can add other hospital in below IF-Condition as required--
		--This will work properly for all hospitals, we just have to add more hospitalname and fiscalyear ids. 
		IF (
				(
					@HospitalShortName = 'CHARAK'
					AND @FiscalYearId = 2
					)
				)
		BEGIN
			SET @HospIdForOpening = @HospitalId
		END

		SELECT A.LedgerId
			,A.PrimaryGroup
			,A.LedgerName
			,A.COA
			,A.LedgerGroupName
			,A.Code
			,SUM(ISNULL(A.DrAmount, 0)) 'DRAmount'
			,SUM(ISNULL(A.CRAmount, 0)) 'CRAmount'
		FROM (
			SELECT l.LedgerId
				,pg.PrimaryGroupName AS PrimaryGroup
				,l.LedgerName
				,lg.COA
				,lg.LedgerGroupName
				,l.Code
				,SUM(txnItm.DrAmount) 'DRAmount'
				,SUM(txnItm.CrAmount) 'CRAmount'
			FROM ACC_Transactions txn
			INNER JOIN (
				SELECT TransactionId
					,LedgerId
					,CASE 
						WHEN DrCr = 1
							THEN Amount
						ELSE 0
						END AS DrAmount
					,CASE 
						WHEN DrCr = 0
							THEN Amount
						ELSE 0
						END AS CrAmount
				FROM ACC_TransactionItems
				WHERE HospitalId = @HospitalId
				) txnItm ON txn.TransactionId = txnItm.TransactionId
			INNER JOIN ACC_Ledger l ON txnItm.LedgerId = l.LedgerId
			INNER JOIN ACC_MST_LedgerGroup lg ON l.LedgerGroupId = lg.LedgerGroupId
			INNER JOIN ACC_MST_ChartOfAccounts coa ON coa.ChartOfAccountId = lg.COAId
			INNER JOIN ACC_MST_PrimaryGroup pg ON pg.PrimaryGroupId = coa.PrimaryGroupId
				AND pg.PrimaryGroupName IN (
					@Revenue
					,@Expenses
					)
			WHERE l.HospitalId = @HospitalId
				AND lg.HospitalId = @HospitalId
				AND convert(DATE, txn.TransactionDate) BETWEEN convert(DATE, @FromDate)
					AND convert(DATE, @ToDate)
				AND txn.IsVerified = 1
			GROUP BY l.LedgerId
				,pg.PrimaryGroupName
				,l.LedgerName
				,lg.COA
				,lg.LedgerGroupName
				,l.Code
			
			UNION ALL
			
			-- below function gives exact same columns as above select query--
			SELECT *
			FROM [FN_ACC_GetOpeningBalanceForPnL_MidYear](@HospIdForOpening, @FiscalYearId, @Revenue, @Expenses)
			--NageshBB:06 aug 2021: get all revenue and expense ledgers for show on client
			--client side we have logic to shwo 0 amount ledger or not
			
			UNION ALL
			
			SELECT l.LedgerId
				,pg.PrimaryGroupName AS PrimaryGroup
				,l.LedgerName
				,coa.ChartOfAccountName AS COA
				,lg.LedgerGroupName
				,l.Code
				,0 AS DRAmount
				,0 AS CRAmount
			FROM ACC_Ledger l
			INNER JOIN ACC_MST_LedgerGroup lg ON l.LedgerGroupId = lg.LedgerGroupId
			INNER JOIN ACC_MST_ChartOfAccounts coa ON coa.ChartOfAccountId = lg.COAId
			INNER JOIN ACC_MST_PrimaryGroup pg ON pg.PrimaryGroupId = coa.PrimaryGroupId
				AND pg.PrimaryGroupName IN (
					@Revenue
					,@Expenses
					)
				AND l.HospitalId = @HospitalId
			) A
		GROUP BY A.LedgerId
			,A.PrimaryGroup
			,A.LedgerName
			,A.COA
			,A.LedgerGroupName
			,A.Code
	END -- end of IF
END -- end of SP