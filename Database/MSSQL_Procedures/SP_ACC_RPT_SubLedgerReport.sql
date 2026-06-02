CREATE PROCEDURE [dbo].[SP_ACC_RPT_SubLedgerReport]
	 @FromDate DATETIME
	,@ToDate DATETIME
	,@HospitalId INT
	,@OpeningFiscalYearId INT
	,@SubLedgerIds VARCHAR(MAX)
AS
/* ***********************************************************************
  FileName: [SP_ACC_RPT_SubLedgerReport]
  --exec SP_ACC_RPT_SubLedgerReport '2022-12-01','2022-12-22',3,6,'67,68,69'
  drop procedure [dbo].[SP_ACC_RPT_SubLedgerReport]
  S.No.    UpdatedBy/Date                        Remarks
  1.      Dev Narayan 22'Dec'22               SP Script created for SubLedger Report
  2.      Dev Narayan 26'March'23             Added IsVerified filter in ACC_TXN_SubledgerRecords table.
  ************************************************************************ */
BEGIN
	DECLARE @OpeningBalanceFromDate DATETIME = (
			SELECT TOP 1 StartDate
			FROM ACC_MST_FiscalYears
			WHERE FiscalYearId = @OpeningFiscalYearId
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

	CREATE TABLE #YearlyOpeningBalance (Balance INT ,SubLedgerId INT,LedgerId INT)

	INSERT INTO #YearlyOpeningBalance (Balance,SubLedgerId, LedgerId)
	SELECT row.OpeningBalance,row.SubLedgerId, row.LedgerId FROM (
			SELECT ISNULL(sum(ISNULL(OpeningDrAmount, 0)) + sum(ISNULL(OpeningTxnDrAmount, 0)) - sum(ISNULL(OpeningCrAmount, 0)) - sum(ISNULL(OpeningTxnCrAmount, 0)), 0) AS OpeningBalance
				,SubLedgerId AS SubLedgerId
				,LedgerId
			FROM (
				--get Subledger opening balance from SubLedger balance history table
				SELECT CASE 
						WHEN ISNULL(lbh.OpeningDrCr, 1) = 1
							THEN IsNULL(lbh.OpeningBalance, 0)
						ELSE 0
						END AS OpeningDrAmount
					,CASE 
						WHEN lbh.OpeningDrCr = 0
							THEN IsNULL(lbh.OpeningBalance, 0)
						ELSE 0
						END AS OpeningCrAmount
					,0 AS OpeningTxnDrAmount
					,0 AS OpeningTxnCrAmount
					, subLed.SubLedgerId
					,subLed.LedgerId
				FROM ACC_Ledger led
				JOIN ACC_MST_SubLedger subLed ON led.LedgerId = subLed.LedgerId
				JOIN ACC_SubLedgerBalanceHistory lbh ON subLed.SubLedgerId = lbh.SubLedgerId
					AND subLed.HospitalId = lbh.HospitalId
				WHERE lbh.HospitalId = @HospitalId
					AND lbh.FiscalYearId = @OpeningFiscalYearId
					AND led.IsActive = 1
					AND subLed.IsActive = 1
					AND subLed.SubLedgerId IN (
						SELECT *
						FROM STRING_SPLIT(@SubLedgerIds, ',')
						)
				
				UNION ALL
				
				--get balance from transaction table from opening fiscal year start date to FromDate-1
				SELECT 0 AS OpeningDrAmount
					,0 AS OpeningCrAmount
					,ISNULL(txn.DrAmount,0) AS OpeningTxnDrAmount
					,ISNULL(txn.CrAmount,0) AS OpeningTxnCrAmount
					,subLed.SubLedgerId
					,subLed.LedgerId
				FROM ACC_TXN_SubledgerRecords txn
				JOIN ACC_MST_SubLedger subLed ON txn.SubLedgerId = subLed.SubLedgerId
				WHERE txn.HospitalId = @HospitalId
					AND (
						convert(DATE, txn.VoucherDate) BETWEEN convert(DATE, @OpeningBalanceFromDate)
							AND convert(DATE, @OpeningBalanceToDate)
						)
					AND subLed.IsActive = 1
					AND txn.IsVerified = 1
					AND txn.SubLedgerId IN (
						SELECT *
						FROM STRING_SPLIT(@SubLedgerIds, ',')
						)
				) AS innerTbl
				GROUP BY innerTbl.SubLedgerId,innerTbl.LedgerId
			) AS row

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
		INSERT INTO #YearlyOpeningBalance (Balance,SubLedgerId,LedgerId)
		SELECT row.OpeningBalance, row.SubLedgerId, row.LedgerId FROM  (
				SELECT ISNULL(sum(ISNULL(OpeningDrAmount, 0)) + sum(ISNULL(OpeningTxnDrAmount, 0)) - sum(ISNULL(OpeningCrAmount, 0)) - sum(ISNULL(OpeningTxnCrAmount, 0)), 0) AS OpeningBalance
					,SubLedgerId AS SubLedgerId
					,LedgerId
				FROM (
					--get ledger opening balance from ledger balance history table
					SELECT CASE 
							WHEN ISNULL(lbh.OpeningDrCr, 1) = 1
								THEN IsNULL(lbh.OpeningBalance, 0)
							ELSE 0
							END AS OpeningDrAmount
						,CASE 
							WHEN lbh.OpeningDrCr = 0
								THEN IsNULL(lbh.OpeningBalance, 0)
							ELSE 0
							END AS OpeningCrAmount
						,0 AS OpeningTxnDrAmount
						,0 AS OpeningTxnCrAmount
						,subLed.SubLedgerId
						,subLed.LedgerId
				FROM ACC_Ledger led
				JOIN ACC_MST_SubLedger subLed ON led.LedgerId = subLed.LedgerId
				JOIN ACC_SubLedgerBalanceHistory lbh ON subLed.SubLedgerId = lbh.SubLedgerId
						AND subLed.HospitalId = lbh.HospitalId
					WHERE lbh.HospitalId = @HospitalId
						AND lbh.FiscalYearId = (
							SELECT TOP (1) FiscalYearId
							FROM #UnclosedFiscalYear
							)
						AND led.IsActive = 1
						AND subLed.IsActive = 1
						AND subLed.SubLedgerId IN (
							SELECT *
							FROM STRING_SPLIT(@SubLedgerIds, ',')
							)
					
					UNION ALL
					
					--get balance from transaction table from opening fiscal year start date to FromDate-1
					SELECT 0 AS OpeningDrAmount
						,0 AS OpeningCrAmount
						,ISNULL(txn.DrAmount,0) AS OpeningTxnDrAmount
						,ISNULL(txn.CrAmount,0) AS OpeningTxnCrAmount
						,subLed.SubLedgerId
						,subLed.LedgerId
				FROM ACC_TXN_SubledgerRecords txn
				JOIN ACC_MST_SubLedger subLed ON txn.SubLedgerId = subLed.SubLedgerId
					WHERE txn.HospitalId = @HospitalId
						AND (
							convert(DATE, txn.VoucherDate) BETWEEN convert(DATE, (
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
						AND subLed.IsActive = 1
						AND txn.IsVerified = 1
						AND txn.SubLedgerId IN (
							SELECT *
							FROM STRING_SPLIT(@SubLedgerIds, ',')
							)
					) AS innerTbl
					GROUP BY innerTbl.SubLedgerId,innerTbl.LedgerId
				) AS row

		DELETE TOP (1)
		FROM #UnclosedFiscalYear
	END

	SELECT SUM(Balance) AS OpeningBalance, SubLedgerId ,LedgerId
	FROM #YearlyOpeningBalance
	GROUP BY SubLedgerId,LedgerId

	DROP TABLE #UnclosedFiscalYear

	DROP TABLE #YearlyOpeningBalance

	SELECT data.LedgerId
		,data.SubLedgerId
		,data.TransactionDate
		,data.VoucherId
		,data.VoucherNumber
		,sum(data.TxnDrAmount) AS 'DrAmount'
		,sum(data.TxnCrAmount) AS 'CrAmount'
	FROM (
		SELECT txn.LedgerId
			,txn.SubLedgerId
			,Convert(DATE, txn.VoucherDate) AS 'TransactionDate'
			,txn.VoucherNo AS 'VoucherNumber'
			,txn.VoucherType AS 'VoucherId'
			,ISNULL(txn.DrAmount,0) AS TxnDrAmount
			,ISNULL(txn.CrAmount,0) AS TxnCrAmount
		FROM ACC_MST_SubLedger subLed 
		JOIN ACC_TXN_SubledgerRecords txn ON subLed.SubLedgerId = txn.SubLedgerId
		WHERE txn.HospitalId = @HospitalId
			AND (
				convert(DATE, txn.VoucherDate) BETWEEN convert(DATE, @FromDate)
					AND convert(DATE, @ToDate)
				)
			AND subLed.IsActive = 1
			AND txn.IsVerified = 1
			AND txn.SubLedgerId IN (
				SELECT *
				FROM STRING_SPLIT(@SubLedgerIds, ',')
				)
		) AS data
	GROUP BY data.TransactionDate
		,data.LedgerId
		,data.SubLedgerId
		,data.VoucherId
		,data.VoucherNumber
END