CREATE   PROCEDURE [dbo].[SP_ACC_RPT_Cash_BankBookReport]
	 @FromDate DATETIME
	,@ToDate DATETIME
	,@HospitalId INT
	,@OpeningFiscalYearId INT
	,@LedgerIds VARCHAR(400)
AS
/* ***********************************************************************
  FileName: [SP_ACC_RPT_Cash_BankBookReport]
  --exec SP_ACC_RPT_Cash_BankBookReport '2022-07-27','2022-07-27',1,6,'2'
  drop procedure [dbo].[SP_ACC_RPT_Cash / BankBookReport]
  S.No.    UpdatedBy/Date                        Remarks
  1.      Dev Narayan 25'July'22                  SP Script created for cash/bank book report data
  2.      Dev Narayan 26'March'23                 Added IsVerified filter in ACC_Transactions table.
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
					AND lbh1.FiscalYearId = @OpeningFiscalYearId
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

	SELECT data.LedgerId
		,data.TransactionDate
		,data.VoucherId
		,data.VoucherNumber
		,sum(data.TxnDrAmount) AS 'DrAmount'
		,sum(data.TxnCrAmount) AS 'CrAmount'
	FROM (
		SELECT ti1.LedgerId
			,Convert(DATE, t1.TransactionDate) AS 'TransactionDate'
			,t1.VoucherNumber
			,t1.VoucherId
			,CASE 
				WHEN ti1.DrCr = 1
					THEN ISNULL(ti1.Amount, 0)
				ELSE 0
				END AS TxnDrAmount
			,CASE 
				WHEN ti1.DrCr = 0
					THEN ISNULL(ti1.Amount, 0)
				ELSE 0
				END AS TxnCrAmount
		FROM ACC_Transactions t1
		JOIN ACC_TransactionItems ti1 ON t1.TransactionId = ti1.TransactionId
		JOIN ACC_Ledger led3 ON led3.LedgerId = ti1.LedgerId
		WHERE t1.HospitalId = @HospitalId
			AND (
				convert(DATE, t1.TransactionDate) BETWEEN convert(DATE, @FromDate)
					AND convert(DATE, @ToDate)
				)
			AND led3.IsActive = 1
			AND t1.IsVerified = 1
			AND ti1.LedgerId IN (
				SELECT *
				FROM STRING_SPLIT(@LedgerIds, ',')
				)
		) AS data
	GROUP BY data.TransactionDate
		,data.LedgerId
		,data.VoucherId
		,data.VoucherNumber
END