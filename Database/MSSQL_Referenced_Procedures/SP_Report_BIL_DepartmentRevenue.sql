--Altering SP_Report_BIL_DepartmentRevenue SP
 --changed RquesyedById to PrescriberId
-- =============================================  
-- Author/Date:    NageshBB-Ajay/23Jan'19  
-- Description:    show department wise revenue details  
-- Remarks:   
--revenue department select cases   
--outpatient CASES   
--== == == == == == == == == == == == == ==  
--#1  
--  iF BillingType = 'outpatient' & & REQUESTED BY NULL Revenue for -> DepartmentId (Parent of ServiceDepartmentId)  
--#2  
--  IF BillingType = 'outpatient' & & REQUESTED BY NOT NULL Revenue for -> BilDeptIdByRequestedBy inpatient   
   
--inpatient CASES   
--== == == == == == == == == == == == == ==  
--#3  
--  If BillingType = 'inpatient' & & RequestedBy is Not Null then Revenue for -> BilDeptIdByRequestedBy  
--#4  
--  If BillingType = 'inpatient' & & RequestedBy is NULL Revenue for -> AdtDocDepartmentId  
  
--[SP_Report_BIL_DepartmentRevenue] '2019-01-14','2019-01-22'  
-- =============================================  
CREATE PROCEDURE [dbo].[SP_Report_BIL_DepartmentRevenue]  
  @FromDate DATETIME = NULL,  
  @ToDate DATETIME = NULL  
AS  
/*  
Change History  
—------------------------------------------------------—  
S.No.    UpdatedBy/Date						Remarks  
—------------------------------------------------------—  
1.    NageshBB-Ajay/23 Jan 2019           created sp  
2.    Krishna/8thJun'22					  changed RquesyedById to PrescriberId
—------------------------------------------------------—  
*/  
BEGIN  
SELECT   
reportData.DepartmentId,  
d.DepartmentName,  
sd.ServiceDepartmentId,  
sd.ServiceDepartmentName,     
reportData.ItemName,  
SUM(ISNULL(reportData.SubTotal, 0)) 'SubTotal',  
SUM(ISNULL(reportData.DiscountAmount, 0)) AS 'Discount',  
SUM(ISNULL(reportData.ReturnAmount, 0)) AS 'Refund',  
SUM(ISNULL(reportData.TotalAmount, 0) - ISNULL(reportData.ReturnAmount, 0)) AS 'NetTotal'  
FROM   
 (SELECT  
  (CASE  
   WHEN   
    f.BillingType='outpatient' AND bi.PrescriberId IS NULL  
   THEN d.DepartmentId  
   WHEN   
    (f.BillingType='outpatient' OR f.BillingType='inpatient') AND bi.PrescriberId IS NOT NULL  
   THEN (SELECT DepartmentId FROM EMP_Employee WHERE EmployeeId = bi.PrescriberId)  
   WHEN   
    f.BillingType='inpatient' AND bi.PrescriberId IS NULL   
   THEN (SELECT ee.DepartmentId  FROM ADT_PatientAdmission ad  
     JOIN EMP_Employee ee ON ad.AdmittingDoctorId = ee.EmployeeId  
     WHERE PatientVisitId = bi.PatientVisitId AND PatientId = bi.PatientId)  
  END) AS DepartmentId,  
 f.*  
 FROM dbo.FN_BIL_GetTxnItemsInfoWithDateSeparation(@FromDate, @ToDate) f  
 JOIN BIL_TXN_BillingTransactionItems bi ON f.BillingTransactionItemId = bi.BillingTransactionItemId  
 JOIN BIL_MST_ServiceDepartment sd ON sd.ServiceDepartmentId = f.ServiceDepartmentId  
 JOIN MST_Department d  ON d.DepartmentId = sd.DepartmentId) AS reportData  
JOIN BIL_MST_ServiceDepartment sd ON reportData.ServiceDepartmentId=sd.ServiceDepartmentId  
JOIN MST_Department d ON reportData.DepartmentId=d.DepartmentId  
WHERE reportData.BillStatus != 'cancelled'   
      AND reportData.BillStatus != 'provisional'  
      AND (reportData.PaymentMode != 'credit' OR reportData.CreditDate IS NOT NULL)  
    GROUP BY   
    reportData.DepartmentId,  
    d.DepartmentName,  
    sd.ServiceDepartmentId,  
    sd.ServiceDepartmentName,    
    reportData.ItemName  
  
  ORDER BY 2  
END