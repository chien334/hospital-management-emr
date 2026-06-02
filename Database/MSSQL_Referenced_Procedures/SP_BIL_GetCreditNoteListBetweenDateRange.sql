Create PROCEDURE [dbo].[SP_BIL_GetCreditNoteListBetweenDateRange] 
		@FromDate Date=NULL,
		@ToDate DATE=NULL
AS
/*
FileName: SP_BIL_GetCreditNoteListBetweenDateRange
Description: To get list of credit notes for duplicate print.

Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Sud,Pratik/1May'21                 Initial Draft
*/
BEGIN
Select  pat.PatientId, 
		pat.PatientCode, 
		pat.ShortName, 
		pat.Gender, 
		pat.DateOfBirth,
		pat.PhoneNumber,
		crn.CreatedOn AS 'CRNDate',
		crn.RefInvoiceNum,
		crn.TotalAmount,
		crn.InvoiceCode,
		fy.FiscalYearFormatted AS FiscalYear,
		crn.FiscalYearId,
		crn.CreditNoteNumber,
		crn.Remarks,
		crn.BillingTransactionId,
		crn.BillReturnId

from  BIL_TXN_InvoiceReturn crn INNER JOIN PAT_Patient pat
     on crn.PatientId=pat.PatientId
inner join BIL_CFG_FiscalYears fy
     on crn.FiscalYearId = fy.FiscalYearId

WHERE 
Convert(Date,crn.CreatedOn) BETWEEN @FromDate and @ToDate 
Order by crn.BillReturnId DESC
END