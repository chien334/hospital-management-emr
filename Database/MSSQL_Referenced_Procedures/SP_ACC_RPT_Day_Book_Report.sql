CREATE     PROCEDURE [dbo].[SP_ACC_RPT_Day_Book_Report]
	-- Add the parameters for the stored procedure here
	@FromDate DATETIME
	,@ToDate DATETIME
	,@LedgerId INT
	,@HospitalId INT
	,@OpeningFiscalYearId INT
AS
-- =============================================
-- Author:		<Author, Dev Narayan Chaudhary>
-- Create date: <Create Date, 15th Aug 2022 >
-- Description:	<Description, This Stored Procedure Returns Data For Day Book Report In Accounting Module. >
-- =============================================
/* ***********************************************************************
  FileName: [SP_ACC_RPT_Day_Book_Report]
  --exec [SP_ACC_RPT_Day_Book_Report] '2022-07-27','2022-07-27',2,1,6
  S.No.    UpdatedBy/Date                        Remarks
  1.      Dev Narayan 15'Aug'22               SP Script created for day book report data
  2.      Dev Narayan 26'March'23             Added IsVerified filter in ACC_Transactions table.
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
					AND led1.LedgerId = @LedgerId
				
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
					AND led2.LedgerId = @LedgerId
					AND t.IsVerified = 1
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
						AND led1.LedgerId = @LedgerId
					
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
						AND led2.LedgerId = @LedgerId
						AND t.IsVerified = 1
					) AS innerTbl
				)

		DELETE TOP (1)
		FROM #UnclosedFiscalYear
	END

	SELECT SUM(Balance) AS OpeningBalance
	FROM #YearlyOpeningBalance

	DROP TABLE #UnclosedFiscalYear

	DROP TABLE #YearlyOpeningBalance

	SELECT InnerData.LedgerId
		,InnerData.VoucherNumber
		,InnerData.TransactionDate
		,InnerData.VoucherId
		,CASE 
			WHEN ISNULL(InnerData.DrCr, 0) = 1
				THEN sum(Amount)
			ELSE 0
			END AS 'DrAmount'
		,CASE 
			WHEN ISNULL(InnerData.DrCr, 0) = 0
				THEN sum(Amount)
			ELSE 0
			END AS 'CrAmount'
	FROM (
		SELECT item.LedgerId
			,item.DrCr
			,item.Amount
			,txn.TransactionDate
			,txn.VoucherId
			,txn.VoucherNumber
		FROM ACC_TransactionItems item
		JOIN ACC_Transactions txn ON item.TransactionId = txn.TransactionId
		WHERE Convert(DATE, txn.TransactionDate) BETWEEN convert(DATE, @FromDate)
				AND convert(DATE, @ToDate)
			AND txn.TransactionId IN (
				SELECT TransactionId
				FROM ACC_TransactionItems
				WHERE LedgerId = @LedgerId
				)
			AND LedgerId <> @LedgerId
			AND txn.IsVerified = 1
		) AS InnerData
	GROUP BY InnerData.LedgerId
		,InnerData.DrCr
		,InnerData.VoucherNumber
		,InnerData.VoucherId
		,InnerData.TransactionDate
END