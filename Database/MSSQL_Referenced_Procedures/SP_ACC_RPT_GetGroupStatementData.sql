CREATE PROCEDURE [dbo].[SP_ACC_RPT_GetGroupStatementData] @FromDate DATETIME
	,@ToDate DATETIME
	,@HospitalId INT
	,@OpeningFiscalYearId INT
	,@LedgerGroupId INT
AS
/* ***********************************************************************
FileName: [SP_ACC_RPT_GetGroupStatementData]  
CreatedBy/date: NageshBB/03 Jan 2021
Description: This sp return group statement reprot data. All are ledgers under selected ledgergroup
with opening, txn, closing balance details. 
S.No.    UpdatedBy/Date                        Remarks
1.      NageshBB:03Jan2021                      SP Script created for get group statement report data
2.      Dev Narayan 26'March'23                 Added IsVerified filter in ACC_Transactions table.
3.      DevN 4th July'23                        Added FiscalyearId filter in ledgerbalancehistory table.
************************************************************************ */
--Exec [dbo].[SP_ACC_RPT_GetGroupStatementData] 3,2,1
BEGIN
	DECLARE @OpeningBalanceFromDate DATETIME = (
			SELECT TOP 1 StartDate
			FROM ACC_MST_FiscalYears
			WHERE FiscalYearId = @OpeningFiscalYearId
			)
	DECLARE @OpeningBalanceToDate DATETIME = (
			SELECT @FromDate - 1
			)

	SELECT led.LedgerName AS Particular
		,led.LedgerId
		,led.Code
		,OuterTable.OpeningDr
		,OuterTable.OpeningCr
		,OuterTable.TransactionDr
		,OuterTable.TransactionCr
		,0 AS OpeningTotal
		,'' AS OpeningType
		,(OpeningDr + TransactionDr) AS ClosingDr
		,(OpeningCr + TransactionCr) AS ClosingCr
		,0 AS ClosingTotal
		,'' AS ClosingType
	FROM ACC_Ledger led
	JOIN ACC_LedgerBalanceHistory lbh ON lbh.LedgerId = led.LedgerId
	JOIN (
		--here we will get actual opening balance for every ledger from below query (Opening bal + Txn as Openign Balance)
		--also we will get transaction dr and cr balance within date
		SELECT LedgerId
			,sum(OpeningDrAmount) + sum(OpeningTxnDrAmount) AS OpeningDr
			,sum(OpeningCrAmount) + sum(OpeningCrAmount) AS OpeningCr
			,sum(TxnDrAmount) AS TransactionDr
			,sum(TxnCrAmount) AS TransactionCr
		FROM (
			--get ledger opening balance from ledger balance history table
			SELECT led1.LedgerId
				,CASE 
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
				,0 AS TxnDrAmount
				,0 AS TxnCrAmount
			FROM ACC_Ledger led1
			JOIN ACC_LedgerBalanceHistory lbh1 ON led1.LedgerId = lbh1.LedgerId AND led1.HospitalId = lbh1.HospitalId
			WHERE lbh1.HospitalId = @HospitalId AND lbh1.FiscalYearId = @OpeningFiscalYearId AND led1.IsActive = 1 AND led1.LedgerGroupId = @LedgerGroupId
			
			UNION
			
			--get balance from transaction table from opening fiscal year start date to FromDate-1
			SELECT ti.LedgerId
				,0 AS OpeningDrAmount
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
				,0 AS TxnDrAmount
				,0 AS TxnCrAmount
			FROM ACC_Transactions t
			JOIN ACC_TransactionItems ti ON t.TransactionId = ti.TransactionId
			JOIN ACC_Ledger led2 ON led2.LedgerId = ti.LedgerId
			WHERE t.HospitalId = @HospitalId AND (
					convert(DATE, t.TransactionDate) BETWEEN convert(DATE, @OpeningBalanceFromDate)
						AND convert(DATE, @OpeningBalanceToDate)
					) AND led2.IsActive = 1 AND led2.LedgerGroupId = @LedgerGroupId AND t.IsVerified = 1
			
			UNION
			
			--get transaction dr and cr amount between from date and to date
			SELECT ti1.LedgerId
				,0 AS OpeningDrAmount
				,0 AS OpeningCrAmount
				,0 AS OpeningTxnDrAmount
				,0 AS OpeningTxnCrAmount
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
			WHERE t1.HospitalId = @HospitalId AND (
					convert(DATE, t1.TransactionDate) BETWEEN convert(DATE, @FromDate)
						AND convert(DATE, @ToDate)
					) AND led3.IsActive = 1 AND led3.LedgerGroupId = @LedgerGroupId AND t1.IsVerified = 1
			) AS innerTbl
		GROUP BY LedgerId
		) AS OuterTable ON OuterTable.LedgerId = led.LedgerId
	WHERE lbh.HospitalId = @HospitalId AND led.IsActive = 1 AND led.LedgerGroupId = @LedgerGroupId AND lbh.FiscalYearId = @OpeningFiscalYearId
	ORDER BY led.LedgerId
END