--Altering SP_RPT_Bil_EHSBillingReport SP
--changed RequestedBy to PrescriberId and ProviderId to PerformerId
CREATE PROCEDURE [dbo].[SP_RPT_Bil_EHSBillingReport]    
        @FromDate DATE = NULL,  
  @ToDate DATE = NULL,  
  @ServiceDepartmentName VARCHAR(200) = null,  
  @ItemName VARCHAR(200) = null,  
        @UserId Int = null,  
  @PerformerId Int = null,  
  @PrescriberId Int = null  
AS  
/*  
FileName: SP_RPT_Bil_EHSBillingReport  
CreatedBy/date: Pratik:21Nov'2021  
Description:   
Remarks:      
Change History  
S.No.    UpdatedBy/Date               Remarks  
1.       Pratik:21Nov'2021            initial draft  
2.       Pratik:9Dec'2021             Added ProviderId and RequestedBy filter   
*/  
BEGIN  
   
  
Select * from   
  
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
  CASE WHEN  ISNULL(txnItm.PerformerId,0)=0 THEN 'NoDoctor'   
   ELSE empAssign.FullName END AS PerformerName,  
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
     
 where  Convert(Date, txn.CreatedOn) between @FromDate and @Todate and txnItm.PriceCategory='EHS'  
  AND (srv.ServiceDepartmentName LIKE '%' + ISNULL(@ServiceDepartmentName, srv.ServiceDepartmentName) + '%')  
        AND (txnItm.ItemName LIKE '%' + ISNULL(@ItemName, txnItm.ItemName) + '%')  
  AND (ISNULL(@UserId, ISNULL(txn.CreatedBy, 0)) = ISNULL(txn.CreatedBy, 0))  
  AND (ISNULL(@PerformerId, ISNULL(txnItm.PerformerId, 0)) = ISNULL(txnItm.PerformerId, 0))  
  AND (ISNULL(@PrescriberId, ISNULL(txnItm.PrescriberId, 0)) = ISNULL(txnItm.PrescriberId, 0))  
  
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
  CASE WHEN  ISNULL(retItm.PerformerId,0)=0 THEN 'NoDoctor'   
   ELSE empAssign.FullName END AS PerformerName,  
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
  
 WHERE  Convert(Date, ret.CreatedOn) between @FromDate and @Todate and retItm.PriceCategory='EHS'  
 AND (srv.ServiceDepartmentName LIKE '%' + ISNULL(@ServiceDepartmentName, srv.ServiceDepartmentName) + '%')  
    AND (retItm.ItemName LIKE '%' + ISNULL(@ItemName, retItm.ItemName) + '%')    
 AND (ISNULL(@UserId, ISNULL(ret.CreatedBy, 0)) = ISNULL(ret.CreatedBy, 0))  
 AND (ISNULL(@PerformerId, ISNULL(retItm.PerformerId, 0)) = ISNULL(retItm.PerformerId, 0))  
  AND (ISNULL(@PrescriberId, ISNULL(retItm.PrescriberId, 0)) = ISNULL(retItm.PrescriberId, 0))  
  
) itmDetails  
  
  
Order by TransactionDate, HospitalNumber  
  
END