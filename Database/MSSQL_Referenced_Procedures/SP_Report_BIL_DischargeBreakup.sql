CREATE PROCEDURE [dbo].[SP_Report_BIL_DischargeBreakup] 
@PatientVisitId int=null 
,@PatientId INT
AS
/*
FileName: [SP_Report_BIL_DischargeBreakup]
CreatedBy/date: Nagesh/2018-07-21
Description: Get billing details for discharge bill breakup for patient by visit id or patientId
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Nagesh/2018-07-21          Created need finalize for some improvements later
2		nagesh/2018/08/20			updated as per dinesh sir guidance and hams requirement
3		Salakha/2019/09/09			updated to exclude cancelled billig items
*/

BEGIN
BEGIN 
If(@PatientId IS NOT NULL)
BEGIN
Declare @FromDate DateTime, @ToDate DateTime
SELECT  @FromDate=AdmissionDate, @ToDate=DischargeDate
FROM ADT_PatientAdmission
WHERE PatientVisitId=@PatientVisitId

;With BilDischargeCTE as
  (
 select bti.BillingTransactionItemId,dept.DepartmentName, 
bti.ServiceDepartmentName,
bti.PaidDate as billDate, 
bti.ItemName as [description],
bti.Quantity as qty,
bti.subtotal as amount,
bti.DiscountAmount as discount,
bti.TaxableAmount as subTotal,
bti.Tax as vat
,bti.TotalAmount as total
 from BIL_TXN_BillingTransactionItems bti
 join BIL_MST_ServiceDepartment sdept
 on sdept.ServiceDepartmentId=bti.ServiceDepartmentId
 join MST_Department dept
 on dept.DepartmentId=sdept.DepartmentId
--If user misses to Select RequestedByDr. in Billing Page, then PatiengVisitId Comes as Null,
--in that case we've to take from CreatedOn Field.---
 where PatientId=@PatientId and  ( bti.PatientVisitId=@PatientVisitId OR  bti.CreatedOn Between @FromDate and @ToDate ) and bti.BillStatus !='cancel' and bti.BillStatus !='adtCancel'     
) select 
Case 
WHEN [DepartmentName]='ADMINISTRATION' and ServiceDepartmentName !='CONSUMEABLES' THEN 'ADMINISTRATIVE'
when ServiceDepartmentName='CONSUMEABLES' then 'CONSUMEABLES'
WHEN [DepartmentName]='OT' and [DepartmentName]!='' THEN 'OT'
when [Description]='BED CHARGES' then 'BED'
when [Description]='INDOOR-DOCTOR''S VISIT FEE (PER DAY)' then 'DOCTOR AND NURSING CARE'
when [DepartmentName]='MEDICINE' then 'MEDICINE'
WHEN [DepartmentName]='SURGERY' then 'SURGERY'
ELSE DepartmentName
END
AS departmentName,
billDate,[description],qty,amount,discount,subTotal,vat,total 
from BilDischargeCTE 
END
END  
END