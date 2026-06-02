--Altering SP_Report_BIL_PAT_PackageSalesDetail SP
--changed RequestedBy to PrescriberId
CREATE PROCEDURE [dbo].[SP_Report_BIL_PAT_PackageSalesDetail]   
 @FromDate datetime=null,  
 @ToDate datetime=null    
AS  
/*  
FileName: [SP_Report_BIL_PAT_PackageSalesDetail] '2017-10-09','2019-11-29'   
CreatedBy/date: Sanjit 12-2-2019  
Description: To get the Details of Package Sale from Billing  
Remarks:      
Change History  
S.No.    UpdatedBy/Date                        Remarks  
1.  
2.		Krishna/9thJun'22					changed RequestedBy to PrescriberId
3.		Krishna/15thDec'22					Date filter issue fixed, removed +1 from todate
*/  
  
BEGIN  
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL))  
  BEGIN  
   SELECT Distinct btx.BillingTransactionId AS BillingTransactionId, CONCAT(btx.InvoiceCode,btx.InvoiceNo) AS InvoiceNo, CONVERT(date,btx.CreatedOn) AS IssuedDate,btx.PatientId,btx.PatientVisitId, pat.PatientCode AS HospitalNo,   
   CONCAT_WS(' ',pat.FirstName, pat.MiddleName,pat.LastName) AS PatientName,  
   pat.age+ '/' + substring(pat.Gender, 1, 1) as 'AgeSex',btx.PackageName,btx.TotalAmount As Price  
   ,ISNULL(emp.FullName,'SELF') AS RequestedBy  
   FROM BIL_TXN_BillingTransaction AS btx  
   Join BIL_TXN_BillingTransactionItems AS btxItm ON btx.BillingTransactionId = btxItm.BillingTransactionId  
   JOIN PAT_Patient AS pat ON pat.PatientId = btx.PatientId  
   Left JOIN EMP_Employee AS emp ON emp.EmployeeId = btxItm.PrescriberId  
   WHERE btx.PackageId>0 
   and CONVERT(date, btx.CreatedOn) BETWEEN ISNULL(CONVERT(DATE,@FromDate),CONVERT(DATE,GETDATE()))  
   AND ISNULL(CONVERT(DATE,@ToDate),CONVERT(DATE,GETDATE()))
   ORDER By BillingTransactionId desc  
  END   
END