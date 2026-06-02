--End-Section: Alter and Update EngNepali date table and it's data----





--Start-Section: Alter Procedures of TotalItemBill and DailySales(userCollection) Reports---


CREATE PROCEDURE [dbo].[SP_Report_BILL_TotalItemsBill]    
        @FromDate DATE = NULL,
  @ToDate DATE = NULL,
  @billingType varchar(20)='all',
  @ServiceDepartmentName VARCHAR(200) = null,
  @ItemName VARCHAR(200) = null,
  @PerformerId INT=null,
  @PrescriberId INT=null
AS
/*  
FileName: [sp_Report_TotalItemsBill]  
CreatedBy/date: Sud:20Aug'21  
Description: To get details of sales and returnsales at item level  
Remarks:      
Change History  
S.No.    UpdatedBy/Date               Remarks  
1.       Sud:20Aug'21                 Complete re-write as per new logic  
2.       Dev/24th_Jan'22         Change NoDoctor to Unassgined in case no doctor is selected  
3.       Krishna/9thJun'22      changed RequestedBy to PrescriberId and ProviderId to PerformerId
4.       Krishna/18thAUG'22     Performer and Prescriber null condition revised 
5.		 Krishna/19thOct'22		PerformedId changed to PrescriberId in Where condition
6.       Sud:26Jun'23           Added NepaliMonthName and EngMonthName in select query.
*/
BEGIN
Declare @IsInsurance BIT;
 IF(LOWER(@billingType)='insurance')
BEGIN
 SET @IsInsurance = 1;
END  
ELSE IF(LOWER(@billingType)='normal')
BEGIN
 SET @IsInsurance = 0;
END  
ELSE IF(LOWER(@billingType)='all')
BEGIN
 SET @IsInsurance = NULL;
END 

--sud: 26Jun'23-- joining with EngNepDateMapped table to get NepaliMonth and English Month Name
Select nepDate.NepMonthName,
nepDate.EngMonthShortName 'EngMonthName',
itmDetails.*
from
(
 Select
  Convert(Date,txn.CreatedOn) 'TransactionDate',
     txn.InvoiceCode+'-'+Convert(varchar(20),txn.InvoiceNo) 'ReceiptNo',
  Case WHEN txn.PaymentMode ='credit' THEN 'CreditSales'
   ELSE 'CashSales' END AS BillingType,
        txnItm.VisitType 'VisitType',
  p.PatientCode 'HospitalNumber',
  p.ShortName 'PatientName',
  srv.ServiceDepartmentName,
  txnItm.ItemName,
  txnItm.Price,
  txnItm.Quantity,
  txnItm.SubTotal 'SubTotal',
  txnItm.DiscountAmount 'DiscountAmount',
  txnItm.TotalAmount 'TotalAmount',
  txnItm.PerformerId,
  txnItm.PrescriberId,
  CASE WHEN  ISNULL(txnItm.PerformerId,0)=0 THEN 'Unassigned'
   ELSE empAssign.FullName END AS Performer,
  CASE WHEN  ISNULL(txnItm.PrescriberId,0)=0 THEN 'SELF'
   ELSE empRef.FullName END AS PrescriberName,
  txnItm.Remarks 'Remarks',
  'NA' AS 'ReferenceReceiptNo',
  empUsr.FullName AS 'UserName',
  ISNULL(memb.MembershipTypeName,'General') 'DiscountScheme',  --if not found then it's General  
  Case WHEN ISNULL(txn.IsInsuranceBilling,0)=1 THEN 'YES'
       ELSE 'NO' END AS IsInsurance  
 From  BIL_TXN_BillingTransaction txn   
   INNER JOin BIL_TXN_BillingTransactionItems txnItm on txn.BillingTransactionId = txnItm.BillingTransactionId  
   INNER JOIN BIL_MST_ServiceDepartment srv ON txnItm.ServiceDepartmentId=srv.ServiceDepartmentId  
   INNER JOIN  PAT_Patient P  on txn.PatientId =p.PatientId  
   INNER JOIN EMP_Employee empUsr ON empUsr.EmployeeId = txn.CreatedBy   
   LEFT JOIN EMP_Employee empRef on empRef.EmployeeId = txnItm.PrescriberId  
   LEFT JOIN EMP_Employee empAssign on empAssign.EmployeeId = txnItm.PerformerId  
   LEFT JOIN PAT_CFG_MembershipType memb on txnItm.DiscountSchemeId=memb.MembershipTypeId  
 where  Convert(Date, txn.CreatedOn) between @FromDate and @Todate
  and  (ISNULL(@IsInsurance, ISNULL(txn.IsInsuranceBilling, 0)) = ISNULL(txn.IsInsuranceBilling, 0))
  AND (srv.ServiceDepartmentName LIKE '%' + ISNULL(@ServiceDepartmentName, srv.ServiceDepartmentName) + '%')
        AND (txnItm.ItemName LIKE '%' + ISNULL(@ItemName, txnItm.ItemName) + '%')
 UNION ALL
 Select
  Convert(Date,ret.CreatedOn) 'TransactionDate',
     'CRN-'+Convert(varchar(20),ret.CreditNoteNumber) 'CreditNoteNumber',
  Case WHEN ret.PaymentMode ='credit' THEN 'ReturnCreditSales'
   ELSE 'ReturnCashSales' END AS BillingType,
        retItm.VisitType 'VisitType',
  p.PatientCode 'HospitalNumber',
  p.ShortName 'PatientName',
  srv.ServiceDepartmentName,
  retItm.ItemName,
  retItm.Price,
  retItm.RetQuantity,
  retItm.RetSubTotal 'SubTotal',
  retItm.RetDiscountAmount 'DiscountAmount',
  retItm.RetTotalAmount 'TotalAmount',
  retItm.PerformerId,
  retItm.PrescriberId,
  CASE WHEN  ISNULL(retItm.PerformerId,0)=0 THEN 'Unassigned'
   ELSE empAssign.FullName END AS Performer,
  CASE WHEN  ISNULL(retItm.PrescriberId,0)=0 THEN 'SELF'
   ELSE empRef.FullName END AS PrescriberName,
  retItm.RetRemarks 'Remarks',
  ret.InvoiceCode+'-'+Convert(varchar(20),ret.RefInvoiceNum) AS 'ReferenceReceiptNo',
  empUsr.FullName AS 'UserName',
  ISNULL(memb.MembershipTypeName,'General') 'DiscountScheme',  --if not found then it's General  
  Case WHEN ISNULL(ret.IsInsuranceBilling,0)=1 THEN 'YES'
       ELSE 'NO' END AS IsInsurance  
 From  BIL_TXN_InvoiceReturn ret   
   INNER JOin BIL_TXN_InvoiceReturnItems retItm on ret.BillReturnId = retItm.BillReturnId  
   INNER JOIN BIL_MST_ServiceDepartment srv ON retItm.ServiceDepartmentId=srv.ServiceDepartmentId  
   INNER JOIN  PAT_Patient P  on ret.PatientId =p.PatientId  
   INNER JOIN EMP_Employee empUsr ON empUsr.EmployeeId = ret.CreatedBy   
   LEFT JOIN EMP_Employee empRef on empRef.EmployeeId = retItm.PrescriberId  
   LEFT JOIN EMP_Employee empAssign on empAssign.EmployeeId = retItm.PerformerId  
   LEFT JOIN PAT_CFG_MembershipType memb on retItm.DiscountSchemeId=memb.MembershipTypeId  
 WHERE  Convert(Date, ret.CreatedOn) between @FromDate and @Todate
 AND  (ISNULL(@IsInsurance, ISNULL(ret.IsInsuranceBilling, 0)) = ISNULL(ret.IsInsuranceBilling, 0))
 AND (srv.ServiceDepartmentName LIKE '%' + ISNULL(@ServiceDepartmentName, srv.ServiceDepartmentName) + '%')
    AND (retItm.ItemName LIKE '%' + ISNULL(@ItemName, retItm.ItemName) + '%')
) itmDetails 
INNER JOIN EngNepaliDateMapped nepDate 
    ON itmDetails.TransactionDate =  nepDate.EngFullDate 
Where
      ISNULL(itmDetails.PerformerId,0) = ISNULL(@PerformerId, ISNULL(itmDetails.PerformerId,0))
      OR ISNULL(itmDetails.PrescriberId,0) = ISNULL(@PrescriberId, ISNULL(itmDetails.PrescriberId,0))
Order by TransactionDate--, HospitalNumber
END