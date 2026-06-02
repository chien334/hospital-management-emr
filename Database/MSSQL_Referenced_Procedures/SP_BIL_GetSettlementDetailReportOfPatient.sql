CREATE PROCEDURE SP_BIL_GetSettlementDetailReportOfPatient @FromDate Date , @ToDate Date , @PatientId int = 0
AS
/*
FileName: [SP_BIL_GetSettlementDetailReportOfPatient]
CreatedBy/date: KRISHNA/2021-11-23
Description: To get the credit settlement Detail View.
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Krishna/2021-11-23						created SP to get the credit settlement View Detail
*/
BEGIN
--PATIENT INFORMATION--
SELECT PatientId,
		ShortName 'PatientName',
		PatientCode 'HospitalNo',
		Gender,
		DateOfBirth
from PAT_Patient 
WHERE PatientId = @PatientId

--COLLECTION FROM RECEIVABLE--
SELECT 
	sett.PatientId, 
	CONVERT(DATE,sett.SettlementDate) 'SettlementDate',
	sett.SettlementReceiptNo,
	txn.InvoiceNo,
	txn.InvoiceCode,
	CONVERT(DATE,txn.CreatedOn) 'InvoiceDate',
	ISNULL(txn.TotalAmount,0) 'SalesAmount',
	ISNULL(ret.RetTotalAmount,0) 'ReturnTotalAmount',
	ISNULL(txn.TotalAmount,0) - ISNULL(ret.RetTotalAmount,0) 'Receivable',
	ISNULL(sett.DiscountAmount,0) 'CashDiscount'

FROM BIL_TXN_Settlements sett INNER JOIN PAT_Patient pat
	ON sett.PatientId = pat.PatientId
	left join BIL_TXN_BillingTransaction txn ON sett.SettlementId = txn.SettlementId
	left join 
			(SELECT SettlementId, BillingTransactionId, 
			SUM(ISNULL(TotalAmount,0)) 'RetTotalAmount'
			FROM BIL_TXN_InvoiceReturn 
			WHERE SettlementId Is Not Null
			--where PatientId = @PatientId
			GROUP BY SettlementId , BillingTransactionId) ret
			ON sett.SettlementId = ret.SettlementId and txn.BillingTransactionId = ret.BillingTransactionId
WHERE CONVERT(DATE,sett.CreatedOn) Between @FromDate and @ToDate and sett.PatientId = @PatientId
		and ISNULL(sett.CollectionFromReceivable,0) != 0 -- need only settlement

--RETURN TO RECEIVABLE--
SELECT 
	sett.SettlementReceiptNo, 
	CONVERT(DATE, sett.CreatedOn) 'SettlementDate',
	ret.CreditNoteNumber,
	CONVERT(DATE, ret.CreatedOn) 'ReturnDate',
	ISNULL(ret.TotalAmount,0) 'ReturnTotalAmount',
	ret.RefInvoiceNum,
	ret.InvoiceCode,
	sett.DiscountReturnAmount
FROM BIL_TXN_Settlements sett inner join
BIL_TXN_InvoiceReturn ret ON sett.SettlementId = ret.SettlementId
WHERE CONVERT(DATE,sett.CreatedOn) Between @FromDate and @ToDate and sett.PatientId = @PatientId
	and LOWER(ret.BillStatus) = 'paid' -- need only returns done after settlement

--GET CASH DISCOUNT--
SELECT SUM(ISNULL(DiscountAmount,0)) 'CashDiscount' FROM BIL_TXN_Settlements 
WHERE CONVERT(DATE,CreatedOn) Between @FromDate and @ToDate and PatientId = @PatientId
		and ISNULL(CollectionFromReceivable,0) != 0

END