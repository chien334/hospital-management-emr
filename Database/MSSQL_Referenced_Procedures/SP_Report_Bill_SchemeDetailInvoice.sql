CREATE PROCEDURE SP_Report_Bill_SchemeDetailInvoice
    @FromDate DATE = '',
    @ToDate DATE = '',
    @Memberships VARCHAR(1000) = '',
    @Ranks VARCHAR(500) = '',
    @Users VARCHAR(1000) = ''
AS

/*  
FileName: [SP_Report_Bill_SchemeDetailInvoice]  
Execute: Exec SP_Report_Bill_SchemeDetailInvoice '2022-09-01', '2022-12-06', '7,6,5,9,8,4','CON,SI,HC,AHC,SHC,ASI','1,51,66,45,47,46,44'
CreatedBy/date: Krishna/6thDec
Description: Scheme wise Detail Invoice level report
Remarks:      
Change History  
S.No.    UpdatedBy/Date               Remarks  
1.       Krishna/6thDec'22           initital draft
*/

BEGIN
   SELECT * FROM (
SELECT
    txn.CreatedOn 'Date',
    NULL AS 'ReferenceReceiptNo',
    CONCAT(txn.InvoiceCode,'-',txn.InvoiceNo) 'ReceiptNo',
    Case WHEN txn.PaymentMode ='credit' THEN 'CreditSales'
    ELSE 'CashSales' END AS 'BillingType',
    txn.TransactionType 'VisitType',
    pat.PatientCode 'HospitalNo',
    pat.ShortName 'PatientName',
    pat.Rank 'Rank',
    mem.MembershipTypeName 'Membership',
    txn.SubTotal 'SubTotal',
    txn.DiscountAmount 'Discount',
    txn.TotalAmount 'Total',
    emp.FullName 'User',
    txn.Remarks 'Remarks'
FROM BIL_TXN_BillingTransaction txn
INNER JOIN pat_patient pat
              ON txn.patientid = pat.patientid
      INNER JOIN emp_employee emp
              ON txn.createdby = emp.employeeid
      INNER JOIN pat_cfg_membershiptype mem
              ON pat.membershiptypeid = mem.membershiptypeid
      INNER JOIN (SELECT value AS 'MembershipTypeId'
                  FROM   String_split(@Memberships, ',')) membership
              ON mem.membershiptypeid = membership.membershiptypeid
      INNER JOIN (SELECT value AS 'Ranks'
                  FROM   String_split(@Ranks, ',')) ran
              ON pat.rank = ran.ranks
      INNER JOIN (SELECT value AS 'UserId'
                  FROM   String_split(@Users, ',')) us
              ON us.userid = txn.createdby
WHERE  CONVERT(DATE, txn.createdon) BETWEEN @FromDate AND @ToDate

UNION ALL 

SELECT
	ret.CreatedOn 'Date',
    CONCAT(txn.InvoiceCode,'-',txn.InvoiceNo) AS 'ReferenceReceiptNo',
    CONCAT('CR','-',ret.CreditNoteNumber) 'ReceiptNo',
    Case WHEN txn.PaymentMode ='credit' THEN 'ReturnCreditSales'
    ELSE 'ReturnCashSales' END AS 'BillingType',
    txn.TransactionType 'VisitType',
    pat.PatientCode 'HospitalNo',
    pat.ShortName 'PatientName',
    pat.Rank 'Rank',
    mem.MembershipTypeName 'Membership',
    ret.SubTotal 'SubTotal',
    ret.DiscountAmount 'Discount',
    ret.TotalAmount 'Total',
    emp.FullName 'User',
    ret.Remarks 'Remarks'
FROM BIL_TXN_InvoiceReturn ret
	INNER JOIN BIL_TXN_BillingTransaction txn
			  ON ret.BillingTransactionId = txn.BillingTransactionId
	INNER JOIN pat_patient pat
              ON ret.patientid = pat.patientid
    INNER JOIN emp_employee emp
            ON ret.createdby = emp.employeeid
    INNER JOIN pat_cfg_membershiptype mem
            ON pat.membershiptypeid = mem.membershiptypeid
    INNER JOIN (SELECT value AS 'MembershipTypeId'
                FROM   String_split(@Memberships, ',')) membership
            ON pat.membershiptypeid = membership.membershiptypeid
    INNER JOIN (SELECT value AS 'Ranks'
                FROM   String_split(@Ranks, ',')) ran
            ON pat.Rank = ran.ranks
    INNER JOIN (SELECT value AS 'UserId'
                FROM   String_split(@Users, ',')) us
              ON us.userid = ret.createdby
WHERE  CONVERT(DATE, ret.createdon) BETWEEN @FromDate AND @ToDate

) tbl
ORDER BY tbl.Date DESC
END