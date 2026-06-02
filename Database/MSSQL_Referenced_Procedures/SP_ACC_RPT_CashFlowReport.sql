CREATE PROCEDURE [dbo].[SP_ACC_RPT_CashFlowReport]
	-- Add the parameters for the stored procedure here
	@FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	,@FiscalYearId INT = NULL
	,@HospitalId INT
AS
-- exec [SP_ACC_RPT_CashFlowReport] '2022-07-10','2022-10-21',5,1


 /* -------------------------------------------------------------------------
  S.No.    UpdatedBy/Date                        Remarks
  1.      Dev Narayan 21 Oct'22              SP Script created for cash flow report data
  2.      Dev Narayan 26'March'23            Added IsVerified filter in ACC_Transactions table.
  ************************************************************************ */
BEGIN
	DECLARE @LedgerIds NVARCHAR(MAX) = (
			SELECT STRING_AGG(CAST(LedgerId AS NVARCHAR(MAX)), ',')
			FROM ACC_Ledger
			WHERE LedgerGroupId = (
					SELECT LedgerGroupId
					FROM ACC_MST_LedgerGroup
					WHERE Name = 'ACA_CASH_IN_HAND'
					)
			)
	DECLARE @OpeningBalanceFromDate DATETIME = (
			SELECT TOP 1 StartDate
			FROM ACC_MST_FiscalYears
			WHERE FiscalYearId = @FiscalYearId
			)
	DECLARE @OpeningBalanceToDate DATETIME = (
			SELECT @FromDate - 1
			)

	IF OBJECT_ID('tempdb.dbo.#UnclosedFiscalYear', 'U') IS NOT NULL
	BEGIN
		DROP TABLE #UnclosedFiscalYear;
	END

	CREATE TABLE #UnclosedFiscalYear (
		FiscalYearId INT
		,
		)

	IF OBJECT_ID('tempdb.dbo.#YearlyOpeningBalance', 'U') IS NOT NULL
	BEGIN
		DROP TABLE #YearlyOpeningBalance;
	END

	CREATE TABLE #YearlyOpeningBalance (Balance INT)

	INSERT INTO #YearlyOpeningBalance (Balance)
	SELECT (
			SELECT ISNULL(sum(ISNULL(OpeningDrAmount, 0)) + sum(ISNULL(OpeningTxnDrAmount, 0)) - sum(ISNULL(OpeningCrAmount, 0)) - sum(ISNULL(OpeningTxnCrAmount, 0)), 0) AS OpeningBalance
			FROM (
				--get ledger opening balance from ledger balance history table
				SELECT CASE 
						WHEN ISNULL(lbh1.OpeningDrCr, 1) = 1
							THEN IsNULL(lbh1.OpeningBalance, 0)
						ELSE 0
						END AS OpeningDrAmount
					,CASE 
						WHEN lbh1.OpeningDrCr = 0
							THEN IsNULL(lbh1.OpeningBalance, 0)
						ELSE 0
						END AS OpeningCrAmount
					,0 AS OpeningTxnDrAmount
					,0 AS OpeningTxnCrAmount
				FROM ACC_Ledger led1
				JOIN ACC_LedgerBalanceHistory lbh1 ON led1.LedgerId = lbh1.LedgerId
					AND led1.HospitalId = lbh1.HospitalId
				WHERE lbh1.HospitalId = @HospitalId
					AND lbh1.FiscalYearId = @FiscalYearId
					AND led1.IsActive = 1
					AND led1.LedgerId IN (
						SELECT *
						FROM STRING_SPLIT(@LedgerIds, ',')
						)
				
				UNION ALL
				
				--get balance from transaction table from opening fiscal year start date to FromDate-1
				SELECT 0 AS OpeningDrAmount
					,0 AS OpeningCrAmount
					,CASE 
						WHEN ti.DrCr = 1
							THEN ISNULL(ti.Amount, 0)
						ELSE 0
						END AS OpeningTxnDrAmount
					,CASE 
						WHEN ti.DrCr = 0
							THEN ISNULL(ti.Amount, 0)
						ELSE 0
						END AS OpeningTxnCrAmount
				FROM ACC_Transactions t
				JOIN ACC_TransactionItems ti ON t.TransactionId = ti.TransactionId
				JOIN ACC_Ledger led2 ON led2.LedgerId = ti.LedgerId
				WHERE t.HospitalId = @HospitalId
					AND (
						convert(DATE, t.TransactionDate) BETWEEN convert(DATE, @OpeningBalanceFromDate)
							AND convert(DATE, @OpeningBalanceToDate)
						)
					AND led2.IsActive = 1
					AND t.IsVerified = 1
					AND led2.LedgerId IN (
						SELECT *
						FROM STRING_SPLIT(@LedgerIds, ',')
						)
				) AS innerTbl
			)

	INSERT INTO #UnclosedFiscalYear (FiscalYearId)
	SELECT (
			SELECT FiscalYearId
			FROM ACC_MST_FiscalYears
			WHERE IsActive = 1
				AND IsClosed = 0
				AND StartDate < (
					SELECT StartDate
					FROM ACC_MST_FiscalYears
					WHERE StartDate <= @FromDate
						AND EndDate >= @FromDate
					)
			)

	WHILE (
			(
				SELECT count(*)
				FROM #UnclosedFiscalYear
				) > 0
			)
	BEGIN
		INSERT INTO #YearlyOpeningBalance (Balance)
		SELECT (
				SELECT ISNULL(sum(ISNULL(OpeningDrAmount, 0)) + sum(ISNULL(OpeningTxnDrAmount, 0)) - sum(ISNULL(OpeningCrAmount, 0)) - sum(ISNULL(OpeningTxnCrAmount, 0)), 0) AS OpeningBalance
				FROM (
					--get ledger opening balance from ledger balance history table
					SELECT CASE 
							WHEN ISNULL(lbh1.OpeningDrCr, 1) = 1
								THEN IsNULL(lbh1.OpeningBalance, 0)
							ELSE 0
							END AS OpeningDrAmount
						,CASE 
							WHEN lbh1.OpeningDrCr = 0
								THEN IsNULL(lbh1.OpeningBalance, 0)
							ELSE 0
							END AS OpeningCrAmount
						,0 AS OpeningTxnDrAmount
						,0 AS OpeningTxnCrAmount
					FROM ACC_Ledger led1
					JOIN ACC_LedgerBalanceHistory lbh1 ON led1.LedgerId = lbh1.LedgerId
						AND led1.HospitalId = lbh1.HospitalId
					WHERE lbh1.HospitalId = @HospitalId
						AND lbh1.FiscalYearId = (
							SELECT TOP (1) FiscalYearId
							FROM #UnclosedFiscalYear
							)
						AND led1.IsActive = 1
						AND led1.LedgerId IN (
							SELECT *
							FROM STRING_SPLIT(@LedgerIds, ',')
							)
					
					UNION ALL
					
					--get balance from transaction table from opening fiscal year start date to FromDate-1
					SELECT 0 AS OpeningDrAmount
						,0 AS OpeningCrAmount
						,CASE 
							WHEN ti.DrCr = 1
								THEN ISNULL(ti.Amount, 0)
							ELSE 0
							END AS OpeningTxnDrAmount
						,CASE 
							WHEN ti.DrCr = 0
								THEN ISNULL(ti.Amount, 0)
							ELSE 0
							END AS OpeningTxnCrAmount
					FROM ACC_Transactions t
					JOIN ACC_TransactionItems ti ON t.TransactionId = ti.TransactionId
					JOIN ACC_Ledger led2 ON led2.LedgerId = ti.LedgerId
					WHERE t.HospitalId = @HospitalId
						AND (
							convert(DATE, t.TransactionDate) BETWEEN convert(DATE, (
											SELECT StartDate
											FROM ACC_MST_FiscalYears
											WHERE FiscalYearId = (
													SELECT TOP (1) FiscalYearId
													FROM #UnclosedFiscalYear
													)
											))
								AND convert(DATE, (
											SELECT EndDate
											FROM ACC_MST_FiscalYears
											WHERE FiscalYearId = (
													SELECT TOP (1) FiscalYearId
													FROM #UnclosedFiscalYear
													)
											))
							)
						AND led2.IsActive = 1
						AND t.IsVerified = 1
						AND led2.LedgerId IN (
							SELECT *
							FROM STRING_SPLIT(@LedgerIds, ',')
							)
					) AS innerTbl
				)

		DELETE TOP (1)
		FROM #UnclosedFiscalYear
	END

	SELECT SUM(Balance) AS OpeningBalance
	FROM #YearlyOpeningBalance

	DROP TABLE #UnclosedFiscalYear

	DROP TABLE #YearlyOpeningBalance

	SELECT pmGroup.PrimaryGroupName
		,(
			SELECT coa.ChartOfAccountName AS 'COA'
				,(
					SELECT outerledGroup.LedgerGroupName, outerledGroup.COA
						,(
							SELECT led.LedgerName
								,ledGroup.LedgerGroupName
								,ledGroup.LedgerGroupId
								,led.Code
								,SUM(CASE 
										WHEN Item.DrCr = 1
											THEN item.Amount
										ELSE 0
										END) AS 'Amountdr'
								,SUM(CASE 
										WHEN Item.DrCr = 0
											THEN item.Amount
										ELSE 0
										END) AS 'Amountcr',
										ledGroup.COA
							FROM ACC_Transactions txn
							JOIN ACC_TransactionItems item ON txn.TransactionId = item.TransactionId
							JOIN ACC_Ledger led ON item.LedgerId = led.LedgerId
							JOIN ACC_MST_LedgerGroup ledGroup ON led.LedgerGroupId = ledGroup.LedgerGroupId
							WHERE CONVERT(DATE, txn.TransactionDate) >= @FromDate
								AND CONVERT(DATE, txn.TransactionDate) <= @ToDate
								AND ledGroup.LedgerGroupName = outerledGroup.LedgerGroupName
								AND ledGroup.COA = outerledGroup.COA
								AND txn.IsVerified = 1
							GROUP BY led.LedgerName
								,ledGroup.LedgerGroupName
								,led.Code
								,item.DrCr
								,ledGroup.LedgerGroupId
								,ledGroup.COA
							FOR JSON PATH
							) AS LedgersList
					FROM ACC_MST_LedgerGroup outerledGroup
					WHERE outerledGroup.COA = coa.ChartOfAccountName
					GROUP BY outerledGroup.LedgerGroupName,outerledGroup.COA
					FOR JSON PATH
					) AS LedgerGroupList
			FROM ACC_MST_ChartOfAccounts coa
			JOIN ACC_MST_PrimaryGroup pg ON coa.PrimaryGroupId = pg.PrimaryGroupId
			WHERE pmGroup.PrimaryGroupName = pg.PrimaryGroupName
			GROUP BY coa.ChartOfAccountName
			FOR JSON PATH
			) AS COAList
	FROM ACC_MST_PrimaryGroup pmGroup
	GROUP BY pmGroup.PrimaryGroupName
	FOR JSON PATH
END