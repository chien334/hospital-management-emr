CREATE PROCEDURE [dbo].[SP_ACC_RPT_GetTrialBalanceData] @FromDate DATETIME
	,@ToDate DATETIME
	,@HospitalId INT
	,@OpeningFiscalYearId INT
AS
--EXEC [dbo].[SP_ACC_RPT_GetTrialBalanceData] @FromDate = '2020-07-08  18:00:21.657', @ToDate ='2020-07-09 18:00:21.657', @HospitalId=3, @OpeningFiscalYearId=3
/************************************************************************
	FileName: [SP_ACC_RPT_GetTrialBalanceData]
	CreatedBy/date: Nagesh /11'June2020
	Description: get records for trail balance report of accounting
	Change History
	S.No.    UpdatedBy/Date                        Remarks
	1       Nagesh /11'June2020						created script for get trial balance records
	2.      Sud/Nagesh: 20Jun'20					Added HospitalId for Phrm separation
	3.		Nagesh/Vikas: 07Jul'20					changed script for opening balance as per fiscalYearId and input openingFiscalYearId 
	4.		Nagesh: 09 Jul 2020						fixed issue of opening balance after fiscal year closed and reopened
	5.      Dev Narayan 26'March'23                 Added IsVerified filter in ACC_Transactions table.
	*************************************************************************/
BEGIN
	IF (
			@FromDate IS NOT NULL
			AND @ToDate IS NOT NULL
			)
	BEGIN
		--here we are getting plain records all grouping and data modification as per need we will do in controller 
		--using linq we will do all modification this will return plain records only
		--Now we are getting ledger opening balance from ledger table later we will update sp
		--and we will get data from ledger balance history table 
		DECLARE @fiscalYearStartDate DATETIME

		SET @fiscalYearStartDate = (
				SELECT TOP 1 StartDate
				FROM ACC_MST_FiscalYears
				WHERE HospitalId = @HospitalId
					AND FiscalYearId = @OpeningFiscalYearId
				)

		SELECT ledInfo.PrimaryGroup
			,ledInfo.COA
			,ledInfo.LedgerGroupName
			,ledInfo.LedgerName
			,ledInfo.LedgerId
			,ledInfo.Code
			,OpeningBalDr
			,OpeningBalCr
			,ISNULL(OpeningDr, 0) AS 'OpeningDr'
			,ISNULL(OpeningCr, 0) AS 'OpeningCr'
			,ISNULL(CurrentDr, 0) AS 'CurrentDr'
			,ISNULL(CurrentCr, 0) AS 'CurrentCr'
		FROM (
			SELECT l.LedgerId
				,l.LedgerName
				,l.Code
				,lg.PrimaryGroup
				,lg.COA
				,lg.LedgerGroupName
				,CASE 
					WHEN lbh.OpeningDrCr = 1
						THEN lbh.OpeningBalance
					ELSE 0
					END AS 'OpeningBalDr'
				,CASE 
					WHEN lbh.OpeningDrCr = 0
						THEN lbh.OpeningBalance
					ELSE 0
					END AS 'OpeningBalCr'
			FROM ACC_LedgerBalanceHistory lbh
			JOIN ACC_Ledger l ON lbh.LedgerId = l.LedgerId
			INNER JOIN ACC_MST_LedgerGroup lg ON l.LedgerGroupId = lg.LedgerGroupId
			WHERE lbh.HospitalId = @HospitalId
				AND lbh.FiscalYearId = @OpeningFiscalYearId
			) ledInfo
		LEFT JOIN (
			SELECT LedgerId
				,SUM(OpeningDr) AS 'OpeningDr'
				,SUM(OpeningCr) 'OpeningCr'
				,SUM(CurrentDr) AS 'CurrentDr'
				,SUM(CurrentCr) 'CurrentCr'
			FROM (
				SELECT ti.LedgerId
					,(
						CASE 
							WHEN ti.DrCr = 1
								AND convert(DATE, t.TransactionDate) < convert(DATE, @FromDate)
								THEN ISNULL(ti.Amount, 0)
							ELSE 0
							END
						) AS OpeningDr
					,(
						CASE 
							WHEN ti.DrCr = 0
								AND convert(DATE, t.TransactionDate) < convert(DATE, @FromDate)
								THEN ISNULL(ti.Amount, 0)
							ELSE 0
							END
						) AS OpeningCr
					,(
						CASE 
							WHEN ti.DrCr = 1
								AND convert(DATE, t.TransactionDate) >= convert(DATE, @FromDate)
								THEN ISNULL(ti.Amount, 0)
							ELSE 0
							END
						) CurrentDr
					,(
						CASE 
							WHEN ti.DrCr = 0
								AND convert(DATE, t.TransactionDate) >= convert(DATE, @FromDate)
								THEN ISNULL(ti.Amount, 0)
							ELSE 0
							END
						) CurrentCr
				FROM ACC_TransactionItems ti
				INNER JOIN ACC_Transactions t ON ti.TransactionId = t.TransactionId
				WHERE t.HospitalId = @HospitalId
					AND convert(DATE, t.TransactionDate) BETWEEN convert(DATE, @fiscalYearStartDate)
						AND convert(DATE, @ToDate)
					AND t.IsVerified = 1
				) A
			GROUP BY LedgerId
			) ledTxnDetails ON ledInfo.LedgerId = ledTxnDetails.LedgerId
		ORDER BY ledInfo.LedgerName
	END
END