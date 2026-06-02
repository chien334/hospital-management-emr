CREATE PROCEDURE SP_BIL_Dashboard_RankWisePatientInvoiceCount
@FromDate DATE = '',
@ToDate DATE = ''
/*
FileName: SP_BIL_Dashboard_RankWisePatientInvoiceCount 
Execute: Exec SP_BIL_Dashboard_RankWisePatientInvoiceCount '2022-12-01','2022-12-31'

CreatedBy/date: Krishna/30thDec'22
Description: This SP will give Rank Wise Patient Invoice Count

Remarks:      
Change History  
S.No.    UpdatedBy/Date               Remarks  
1.       Krishna/30thDec'22           initital draft
*/
AS
BEGIN
	SELECT 
		Rank,
		COUNT(BillingTransactionId) 'Total'
	FROM PAT_Patient pat
	INNER JOIN BIL_TXN_BillingTransaction txn
	ON txn.PatientId = pat.PatientId
	INNER JOIN PAT_PatientVisits visit
	ON visit.PatientVisitId = txn.PatientVisitId
	WHERE Rank is not null AND Rank != ''
	AND CONVERT(DATE,txn.CreatedOn) BETWEEN @FromDate AND @ToDate
	GROUP BY Rank
END