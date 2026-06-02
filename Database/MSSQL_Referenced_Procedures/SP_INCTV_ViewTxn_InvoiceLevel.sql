--Start: Pratik- 11March, 2020---



-- start: pratik -17MArch 2020---



CREATE PROCEDURE [dbo].[SP_INCTV_ViewTxn_InvoiceLevel] --SP_INCTV_ViewTxn_InvoiceLevel '2020-02-06','2020-03-06',0
	( @FromDate DATETIME = NULL,
      @ToDate DATETIME = NULL,
      @EmployeeId INT=NULL)
AS
/*
 File: SP_INCTV_ViewTxn_InvoiceLevel
 Description: 
 Conditions/Checks: 
        

 Remarks: Needs Revision.
 Change History:
 S.No.    ChangeDate/By       Remarks
 1.      24Jan'20/Pratik          Initial Draft (Needs Revision)
 
*/
BEGIN

select
pat.PatientId, pat.FirstName+' '+ISNULL(pat.MiddleName+' ','')+pat.LastName 'PatientName', pat.PatientCode,

 fyear.FiscalYearFormatted +'-'+ bilTxn.InvoiceCode + cast(bilTxn.InvoiceNo as varchar(20)) AS 'InvoiceNo' 
, bilTxn.CreatedOn 'TransactionDate', bilTxn.TotalAmount, biltxn.BillingTransactionId

from BIL_TXN_BillingTransaction bilTxn, BIL_CFG_FiscalYears fyear, PAT_Patient pat
where 
	bilTxn.FiscalYearId=fyear.FiscalYearId 
	and bilTxn.PatientId=pat.PatientId
	AND Convert(Date,bilTxn.CreatedOn) Between @FromDate AND @ToDate
	and ISNULL(bilTxn.ReturnStatus,0) = 0


END