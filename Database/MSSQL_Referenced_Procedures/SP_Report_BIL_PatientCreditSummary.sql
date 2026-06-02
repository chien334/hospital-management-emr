CREATE PROCEDURE [dbo].[SP_Report_BIL_PatientCreditSummary] 
@FromDate Date=null ,
@ToDate Date=null	
AS
/*
FileName: [dbo].[SP_Report_BIL_PatientCreditSummary] '2018-01-01', '2019-03-05'
CreatedBy/date: Umed/20-07-2017
Description: to get Sum of Total Amount collected of each patient Between Given Dates 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/20-07-2017	                   created the script
2        Umed/25-07-2017                   added lasttxndate and done sum of totalamt and added SN
3.		Ramavtar/05June'18				changed whole script for Credit Summary -- still need review and changes in this report
4.		Dinesh/21st Feb'19					Date filter added includng date, Remarks and Invoice No
5.      Shankar/13th Feb'20                Added subtotal, discount amount and credit organization.
*/
BEGIN
If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
	BEGIN 
    
SELECT
  (CAST(ROW_NUMBER() OVER (ORDER BY pat.PatientCode) AS int)) AS SN,
  txn.CreatedOn,
  txn.PatientId,
  pat.PatientCode,
  pat.FirstName + ' ' + ISNULL(pat.MiddleName + ' ', '') + pat.LastName 'PatientName',
  txn.InvoiceNo,
  txn.Remarks,
  org.OrganizationName,
  txn.DiscountAmount,
  txn.SubTotal,
  SUM(txn.TotalAmount) 'TotalAmount'
FROM BIL_TXN_BillingTransaction txn
JOIN BIL_MST_Credit_Organization org
  ON txn.OrganizationId = org.OrganizationId
JOIN PAT_Patient pat
  ON txn.PatientId = pat.PatientId
WHERE txn.BillStatus = 'unpaid'
AND ISNULL(txn.ReturnStatus, 0) != 1 and CONVERT(date,txn.CreatedOn) between @FromDate and @ToDate
GROUP BY txn.PatientId,
         pat.PatientCode,
         pat.FirstName,
         pat.LastName,
         pat.MiddleName,
		 txn.InvoiceNo,
		 txn.Remarks,
		 txn.CreatedOn,
		 org.OrganizationName,
		 txn.DiscountAmount,
		 txn.SubTotal
		 
END
END