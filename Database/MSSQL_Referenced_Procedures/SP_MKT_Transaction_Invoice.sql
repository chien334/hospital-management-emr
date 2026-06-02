CREATE PROCEDURE [dbo].[SP_MKT_Transaction_Invoice] @FromDate DATE
	,@ToDate DATE
AS
/* 
exec [SP_MKT_Transaction_Invoice] '2023-04-07','2023-08-08'
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Bibek/2023-08-08                   Created initial script 
*/
BEGIN
SELECT 
		 BT.BillingTransactionId
		,BT.CreatedOn
		,BT.InvoiceNo
		,pat.PatientCode
		,PV.PatientVisitId
		,pat.PatientId
		,pat.ShortName
		,BT.FiscalYearId
		, CONCAT( FY.FiscalYearFormatted, '-', BT.InvoiceCode,BT.InvoiceNo) AS InvoiceNoFormatted
		,CONCAT (pat.Age,'/',pat.Gender) AS Age
		,pat.Gender
		,BT.TotalAmount
		,ISNULL(BT.RetTotalAmount,0) AS 'ReturnCashAmount'
		,ISNULL(BT.TotalAmount,0) - ISNULL(BT.RetTotalAmount,0) AS NetAmount
		,COUNT(RC.BillingTransactionId) AS ReferralCount
	    FROM (SELECT txn.BillingTransactionId, txn.CreatedOn, InvoiceNo, txn.TotalAmount, ret.RetTotalAmount, txn.PatientId, txn.PatientVisitId, txn.FiscalYearId, txn.InvoiceCode FROM (
				SELECT * FROM BIL_TXN_BillingTransaction WHERE CONVERT(date, CreatedOn) BETWEEN @FromDate AND @ToDate) txn
				LEFT JOIN (SELECT BillingTransactionId, SUM(ISNULL(TotalAmount,0)) 'RetTotalAmount' FROM BIL_TXN_InvoiceReturn
				GROUP BY BillingTransactionId) ret ON txn.BillingTransactionId = ret.BillingTransactionId) BT
    LEFT JOIN (SELECT * FROM MKT_TXN_ReferralCommission WHERE IsActive = 1) RC on RC.BillingTransactionId = BT.BillingTransactionId
	INNER JOIN PAT_Patient pat ON BT.PatientId = pat.PatientId
	INNER JOIN PAT_PatientVisits PV ON BT.PatientVisitId = PV.PatientVisitId
	INNER JOIN BIL_CFG_FiscalYears FY ON BT.FiscalYearId= FY.FiscalYearId
	
	GROUP BY BT.BillingTransactionId
		,BT.CreatedOn
		,BT.InvoiceNo
		,pat.PatientCode
		,PV.PatientVisitId
		,pat.PatientId
		,pat.ShortName
		,pat.Age
		,pat.Gender,
		BT.FiscalYearId
		,BT.TotalAmount
		,BT.RetTotalAmount,
		BT.InvoiceCode,
		FY.FiscalYearFormatted,
		InvoiceNoFormatted
	ORDER BY BT.CreatedOn DESC
END