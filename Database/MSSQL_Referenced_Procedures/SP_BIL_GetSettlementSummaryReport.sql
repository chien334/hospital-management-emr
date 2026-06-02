CREATE PROCEDURE SP_BIL_GetSettlementSummaryReport @FromDate DATE, @ToDate DATE
AS
/*
FileName: [SP_BIL_GetSettlementSummaryReport]
CreatedBy/date: KRISHNA/2021-11-22
Description: To get the credit settlement summary.
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Krishna/2021-11-22						created SP to get the credit settlement summary
*/
BEGIN

SELECT 
	sett.PatientId, 
	pat.ShortName AS 'PatientName', 
	pat.PatientCode AS 'HospitalNo',
	pat.Gender,
	pat.PhoneNumber AS 'ContactNo',
	pat.DateOfBirth,
	SUM(ISNULL(CollectionFromReceivable,0)) 'CollnFromReceivable',
	SUM(ISNULL(DiscountAmount,0)) 'CashDiscountGiven',
	SUM(ISNULL(DiscountReturnAmount,0)) 'CashDiscReturn'
FROM BIL_TXN_Settlements sett INNER JOIN PAT_Patient pat
	ON sett.PatientId = pat.PatientId
WHERE CONVERT(Date,sett.CreatedOn) Between @FromDate and @ToDate
	GROUP BY sett.PatientId,pat.ShortName, pat.PatientCode,
			pat.Gender,pat.PhoneNumber, pat.DateOfBirth
END