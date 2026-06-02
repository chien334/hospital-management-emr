CREATE PROCEDURE [dbo].[SP_ACC_RPT_GetBalanceSheetData] @ToDate DATETIME
	,@HospitalId INT
	,@FiscalYearId INT
AS
--EXEC [dbo].[SP_ACC_RPT_GetBalanceSheetData] @FromDate = '2020-06-11 18:00:21.657', @ToDate ='2020-06-11 18:00:21.657'
/************************************************************************
  FileName: [SP_ACC_RPT_GetBalanceSheetData]
  CreatedBy/date: Nagesh /12'June2020
  Description: get records for balance sheet report of accounting
  Change History
  S.No.    UpdatedBy/Date                        Remarks
  1     Nagesh /12'June2020           created script for get balance sheet report records
  2     Sud sir/13'June 2020          updated for get table 2 with NetProfit details
  3.	NageshBB: 17July2021		  get codeDetails table values using function. added function here
  4.    Dev Narayan 26'March'23       Added IsVerified filter in ACC_Transactions table.
  *************************************************************************/
BEGIN
	IF (@ToDate IS NOT NULL)
	BEGIN
		DECLARE @FromDate DATETIME

		SET @FromDate = (
				SELECT StartDate
				FROM ACC_MST_FiscalYears
				WHERE HospitalId = @HospitalId
					AND IsActive = 1
					AND FiscalYearId = @FiscalYearId
				)

		--Table:1 Get Balance Sheet Details---          
		SELECT ledInfo.LedgerId
			,PrimaryGroup
			,LedgerName
			,COA
			,LedgerGroupName
			,Code
			,OpeningBalanceDr
			,OpeningBalanceCr
			,ISNULL(Led_TotDr, 0) AS 'DRAmount'
			,ISNULL(Led_TotCr, 0) AS 'CRAmount'
		FROM (
			SELECT l.LedgerId
				,l.LedgerName
				,l.Code
				,l.ledgergroupid
				,lg.PrimaryGroup
				,lg.COA
				,lg.LedgerGroupName
				,CASE 
					WHEN lbh.OpeningDrCr = 1
						THEN lbh.OpeningBalance
					ELSE 0
					END AS 'OpeningBalanceDr'
				,CASE 
					WHEN lbh.OpeningDrCr = 0
						THEN lbh.OpeningBalance
					ELSE 0
					END AS 'OpeningBalanceCr'
			--from ACC_Ledger  l INNER JOIN ACC_MST_LedgerGroup lg  --NageshBB-03Jul updated for opening balance as per fiscal year
			FROM ACC_LedgerBalanceHistory lbh
			JOIN ACC_Ledger l ON lbh.LedgerId = l.LedgerId
			INNER JOIN ACC_MST_LedgerGroup lg ON l.LedgerGroupId = lg.LedgerGroupId
			WHERE lbh.HospitalId = @HospitalId
				AND lbh.FiscalYearId = @FiscalYearId
			) ledInfo
		LEFT JOIN (
			SELECT LedgerId
				,SUM(DrAmount) AS 'Led_TotDr'
				,SUM(CrAmount) 'Led_TotCr'
			FROM (
				SELECT txn.TransactionId
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
				FROM ACC_TransactionItems txnItm
				INNER JOIN ACC_Transactions txn ON txnItm.TransactionId = txn.TransactionId
				WHERE txn.HospitalId = @HospitalId
					AND convert(DATE, txn.TransactionDate) BETWEEN convert(DATE, @FromDate)
						AND convert(DATE, @ToDate)
					AND txn.IsVerified = 1
				) A
			GROUP BY LedgerId
			) ledTxnDetails ON ledInfo.LedgerId = ledTxnDetails.LedgerId
		ORDER BY ledInfo.LedgerName

		--Table2: Get NetProfit and Loss ---
		DECLARE @Revenue VARCHAR(50) = (
				SELECT dbo.FN_ACC_GetNameByCode('001', @HospitalId)
				)
		DECLARE @Expenses VARCHAR(50) = (
				SELECT dbo.FN_ACC_GetNameByCode('002', @HospitalId)
				)

		SELECT SUM(RevenueBalance) - SUM(ExpenseBalance) 'NetProfitNLoss'
		FROM (
			SELECT CASE 
					WHEN PrimaryGroup = @Revenue
						THEN TotalDrAmount - TotalCrAmount
					ELSE 0
					END AS 'ExpenseBalance'
				,CASE 
					WHEN PrimaryGroup = @Expenses
						THEN TotalCrAmount - TotalDrAmount
					ELSE 0
					END AS 'RevenueBalance'
			FROM (
				SELECT ledGrp.PrimaryGroup
					,SUM(led.DrAmount) 'TotalDrAmount'
					,SUM(led.CrAmount) 'TotalCrAmount'
				FROM
					--  (		Select   LedgerId,LedgergroupId,
					-- 		Case WHEN DrCr=1 THEN OpeningBalance ELSE 0 END AS DrAmount,
					-- 		Case WHEN DrCr=0 THEN OpeningBalance ELSE 0 END AS CrAmount,
					-- 		HospitalId 
					-- 		from  ACC_Ledger  where HospitalId=@HospitalId)   led 
					(
					SELECT lbh.LedgerId
						,l.LedgergroupId
						,CASE 
							WHEN lbh.OpeningDrCr = 1
								THEN lbh.OpeningBalance
							ELSE 0
							END AS DrAmount
						,CASE 
							WHEN lbh.OpeningDrCr = 0
								THEN lbh.OpeningBalance
							ELSE 0
							END AS CrAmount
						,lbh.HospitalId
					FROM ACC_LedgerBalanceHistory lbh
					JOIN ACC_Ledger l ON lbh.LedgerId = l.LedgerId
					WHERE lbh.HospitalId = @HospitalId
						AND lbh.FiscalYearId = @FiscalYearId
					) led
				INNER JOIN ACC_MST_LedgerGroup ledGrp ON led.LedgerGroupId = ledGrp.LedgerGroupId
				WHERE led.HospitalId = @HospitalId
					AND ledGrp.hospitalid = @HospitalId
					AND ledGrp.PrimaryGroup IN (
						@Revenue
						,@Expenses
						)
				GROUP BY ledGrp.PrimaryGroup
				
				UNION ALL
				
				--Query:2.2-- Get Profit&Loss on Transaction Amounts
				SELECT lg.PrimaryGroup
					,SUM(txnItm.DrAmount) 'TotalDrAmount'
					,SUM(txnItm.CrAmount) 'TotalCrAmount'
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
					AND lg.PrimaryGroup IN (
						@Revenue
						,@Expenses
						)
				WHERE txn.HospitalId = @HospitalId
					AND l.HospitalId = @HospitalId
					AND convert(DATE, txn.TransactionDate) BETWEEN convert(DATE, @FromDate)
						AND convert(DATE, @ToDate)
					AND txn.IsVerified = 1
				GROUP BY lg.PrimaryGroup
				) A
			) B
	END
END