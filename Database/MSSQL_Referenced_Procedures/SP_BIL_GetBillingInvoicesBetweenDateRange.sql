CREATE PROCEDURE [dbo].[SP_BIL_GetBillingInvoicesBetweenDateRange] 
		@FromDate Date=NULL,
		@ToDate DATE=NULL
AS
/*
FileName: SP_BIL_GetBillingInvoicesBetweenDateRange
CreatedBy/date: Sud/29Mar'21
Description:Get Invoice Details for Billing-> Duplicate Print 

Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Sud/29Mar'21                         Initial Draft
*/
BEGIN
SET @FromDate= ISNULL(@FromDate,Convert(Date,GetDate()))
SET @ToDate= ISNULL(@ToDate,Convert(Date,GetDate()))

Select  pat.PatientId, 
		pat.PatientCode, 
		pat.ShortName, 
		pat.Gender, 
		pat.DateOfBirth,
		txn.PaidDate AS 'PaidDate',
		txn.CreatedOn AS 'TransactionDate',
		txn.TotalAmount,
		txn.BillingTransactionId,
		txn.InvoiceNo 'InvoiceNumber',
		txn.InvoiceCode,
		fy.FiscalYearFormatted AS FiscalYear,
		txn.FiscalYearId,
		txn.InvoiceCode+Convert(Varchar(20),txn.InvoiceNo) AS 'InvoiceNumFormatted',
		pat.PhoneNumber,
		txn.IsInsuranceBilling,
		txn.OrganizationId,
		crOrg.OrganizationName,
		txn.PaymentMode

from BIL_TXN_BillingTransaction txn INNER JOIN PAT_Patient pat
     on txn.PatientId=pat.PatientId
inner join BIL_CFG_FiscalYears fy
     on txn.FiscalYearId = fy.FiscalYearId
left join BIL_MST_Credit_Organization crOrg 
    on txn.OrganizationId = crOrg.OrganizationId

WHERE 
Convert(Date,txn.CreatedOn) BETWEEN @FromDate and @ToDate 
Order by txn.FiscalYearId DESC, txn.InvoiceNo DESC 
END