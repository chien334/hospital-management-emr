CREATE PROCEDURE SP_BIL_Dashboard_CardSummary
/*
FileName: SP_BIL_Dashboard_CardSummary
Execute: Exec SP_BIL_Dashboard_CardSummary

CreatedBy/date: Krishna/30thDec'22
Description: This SP will give the Card Summary for Billing Dashboard
Table 1: Patient Report
Table 2: Income Report
Table 3: Bill Return Report

Remarks:      
Change History  
S.No.    UpdatedBy/Date               Remarks  
1.       Krishna/30thDec'22           initital draft
*/
AS
BEGIN
    --table1: PatientReport
	DECLARE @FromDateForWeekly DATE, @ToDateForWeekly DATE;
	SET @FromDateForWeekly = DATEADD(DAY, -DATEPART(dw,GETDATE())+1, GETDATE())
	SET @ToDateForWeekly = GETDATE()
	
		SELECT 
		*
		FROM(
		SELECT 
			'Total_Today' AS 'Period',
			COUNT(ISNULL(txn.BillingTransactionId,0)) 'TotalPatientsCount'
		FROM BIL_TXN_BillingTransaction txn
		INNER JOIN PAT_Patient pat
		ON txn.PatientId = pat.PatientId
		LEFT JOIN PAT_PatientVisits visit
		ON visit.ParentVisitId = txn.PatientVisitId
		WHERE CONVERT(DATE, txn.CreatedOn) = CONVERT(DATE,GETDATE())
		
		UNION ALL
		
		SELECT 
			'Total_Weekly' AS 'Period',
			COUNT(ISNULL(txn.BillingTransactionId,0)) 'TotalPatientsCount'
		FROM BIL_TXN_BillingTransaction txn
		INNER JOIN PAT_Patient pat
		ON txn.PatientId = pat.PatientId
		LEFT JOIN PAT_PatientVisits visit
		ON visit.ParentVisitId = txn.PatientVisitId
		WHERE CONVERT(DATE, txn.CreatedOn) BETWEEN @FromDateForWeekly AND @ToDateForWeekly
		
		UNION ALL
		
		SELECT 
			'Total_Monthly' AS 'Period',
			COUNT(ISNULL(txn.BillingTransactionId,0)) 'TotalPatientsCount'
		FROM BIL_TXN_BillingTransaction txn
		INNER JOIN PAT_Patient pat
		ON txn.PatientId = pat.PatientId
		LEFT JOIN PAT_PatientVisits visit
		ON visit.ParentVisitId = txn.PatientVisitId
		WHERE YEAR(txn.CreatedOn) = YEAR(GETDATE()) AND MONTH(txn.CreatedOn) = MONTH(GETDATE())
		)tbl
		PIVOT(
			SUM(TotalPatientsCount)
			FOR Period IN([Total_Today], [Total_Weekly], [Total_Monthly])
		)patient_report
	
		SELECT * FROM (
		SELECT 
			'Total_Today' AS 'Period',
			ISNULL((SUM(ISNULL(InAmount,0)) - SUM(ISNULL(OutAmount, 0))),0) 'TotalIncome'
		FROM TXN_EmpCashTransaction
		WHERE CONVERT(DATE,TransactionDate) = CONVERT(DATE,GETDATE())
		
		UNION ALL
		
		SELECT 
			'Total_Weekly' AS 'Period',
			ISNULL((SUM(ISNULL(InAmount,0)) - SUM(ISNULL(OutAmount, 0))),0) 'TotalIncome'
		FROM TXN_EmpCashTransaction
		WHERE CONVERT(DATE,TransactionDate) BETWEEN @FromDateForWeekly AND @ToDateForWeekly
		
		UNION ALL
		
		SELECT 
			'Total_Monthly' AS 'Period',
			ISNULL((SUM(ISNULL(InAmount,0)) - SUM(ISNULL(OutAmount, 0))),0) 'TotalIncome'
		FROM TXN_EmpCashTransaction
		WHERE  YEAR(TransactionDate) = YEAR(GETDATE()) AND MONTH(TransactionDate) = MONTH(GETDATE())
		)tbl
		PIVOT(
			SUM(TotalIncome)
			FOR Period IN ([Total_Today], [Total_Weekly], [Total_Monthly])
		)income_report
	
		SELECT * FROM (
		SELECT 
			'Total_Today' AS 'Period',
			COUNT(ret.BillReturnId) 'TotalBillsReturnCount'
		FROM BIL_TXN_InvoiceReturn ret
		INNER JOIN PAT_Patient pat
		ON ret.PatientId = pat.PatientId
		WHERE CONVERT(DATE,ret.CreatedOn) = CONVERT(DATE,GETDATE())
		
		UNION ALL
		
		SELECT 
			'Total_Weekly' AS 'Period',
			COUNT(ret.BillReturnId) 'TotalBillsReturnCount'
		FROM BIL_TXN_InvoiceReturn ret
		INNER JOIN PAT_Patient pat
		ON ret.PatientId = pat.PatientId
		WHERE CONVERT(DATE, ret.CreatedOn) BETWEEN @FromDateForWeekly AND @ToDateForWeekly
		
		UNION ALL
		
		SELECT 
			'Total_Monthly' AS 'Period',
			COUNT(ret.BillReturnId) 'TotalBillsReturnCount'
		FROM BIL_TXN_InvoiceReturn ret
		INNER JOIN PAT_Patient pat
		ON ret.PatientId = pat.PatientId
		WHERE YEAR(ret.CreatedOn) = YEAR(GETDATE()) AND MONTH(ret.CreatedOn) = MONTH(GETDATE())
		) tbl
		PIVOT(
			SUM(TotalBillsReturnCount)
			FOR Period IN ([Total_Today], [Total_Weekly], [Total_Monthly])
		)billreturn_report
	END