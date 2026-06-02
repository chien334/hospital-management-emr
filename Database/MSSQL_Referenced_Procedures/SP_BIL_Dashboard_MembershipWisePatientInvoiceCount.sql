CREATE PROCEDURE SP_BIL_Dashboard_MembershipWisePatientInvoiceCount
@FromDate DATE = '',
@ToDate DATE = ''
/*
FileName: SP_BIL_Dashboard_MembershipWisePatientInvoiceCount 
Execute: Exec SP_BIL_Dashboard_MembershipWisePatientInvoiceCount '2022-12-01','2022-12-31'

CreatedBy/date: Krishna/30thDec'22
Description: This SP will give Membership Wise Patient Invoice Count

Remarks:      
Change History  
S.No.    UpdatedBy/Date               Remarks  
1.       Krishna/30thDec'22           initital draft
*/
AS
BEGIN
	SELECT 
		memb.MembershipTypeName,
		COUNT(BillingTransactionId) 'Total'
	FROM PAT_Patient pat
	INNER JOIN BIL_TXN_BillingTransaction txn
	ON txn.PatientId = pat.PatientId
	INNER JOIN PAT_PatientVisits visit
	ON visit.PatientVisitId = txn.PatientVisitId
	INNER JOIN PAT_CFG_MembershipType memb
	ON memb.MembershipTypeId = pat.MembershipTypeId
	WHERE CONVERT(DATE,txn.CreatedOn) BETWEEN @FromDate AND @ToDate
	GROUP BY memb.MembershipTypeName
END