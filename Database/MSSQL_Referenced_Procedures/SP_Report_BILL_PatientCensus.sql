--Altering SP_Report_BILL_PatientCensus SP
--changed ProviderId to PerformerId and ProviderName to PerformerName
-- =============================================  
-- Author/Date:  RAMAVTAR/03Aug2018  
-- Description:  report shows doctor-department wise income and patient's count  
-- =============================================  
CREATE PROCEDURE [dbo].[SP_Report_BILL_PatientCensus] -- [SP_Report_BILL_PatientCensus] '2019-1-20','2019-02-05',NULL,24  
 @FromDate DATETIME = NULL,  
 @ToDate DATETIME = NULL,  
 @PerformerId int = NULL,  
 @DepartmentId int = NULL  
AS  
/*  
Change History  
S.No.    UpdatedBy/Date     Remarks  
1  Ramavtar/03Aug'18   created the script  
2  Ramavtar/9Aug'18  getting summary of deposit, and deposit-return (as table 3),  
        excluding entry where billstatus == cancel and for return items we are not including its amount in totalcollection  
3.      sud  --     updated after creating common function.   
4.      dinesh /14thSep'18      grouped and  merged the labcharges and miscellaneous to the respective single view header   
5.  ramavtar/05Oct'18  getting provider name from employee table instead of txn table  
6.  ramavtar/03Dec'18  revamp of SP -> as per new requirement  
7.  ramavtar/05Dec'18  filter more case of paid/credit bills  
8.  ramavtar/13Dec'18  taking quantity  
9.      Dinesh/05th_Feb'19      Doctor Department Department included in report to segregate doctors according to department  
10.     Dev/24th_Jan'22         Change NoDoctor to Unassgined in case no doctor is selected
11.		Krishna/9thJun'22		changed ProviderId to PerformerId and ProviderName to PerformerName
*/  
BEGIN  
 SELECT   
  tbl.Performer,  
  tbl.ServiceDepartmentName,  
  tbl.totC1,  
  tbl.retC1,  
  tbl.totA1,  
  tbl.retA1,  
  tbl.totC2,  
  tbl.totA2,  
  tbl.totC3,  
  tbl.retC3,  
  tbl.totA3,  
  tbl.retA3,  
  (tbl.totC1 - tbl.retC1) + (tbl.totC3 - tbl.retC3) AS 'totTC',  
  (tbl.totA1 - tbl.retA1) + (tbl.totA3 - tbl.retA3) AS 'totTA'   
 FROM (  
 SELECT   
  ISNULL(fn.PerformerName,'Unassigned') AS 'Performer',  
  fn.ServiceDepartmentName,  
  SUM(CASE  
    WHEN fn.BillStatus = 'paid' AND vm.ProvisionalDate IS NULL AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL) THEN fn.Quantity  
    WHEN fn.BillStatus = 'credit' AND vm.ProvisionalDate IS NULL THEN fn.Quantity  
    WHEN fn.BillStatus = 'return' AND vm.ProvisionalDate IS NULL AND ((fn.PaymentMode = 'credit' AND fn.CreditDate IS NOT NULL) OR (fn.PaymentMode != 'credit' AND fn.PaidDate IS NOT NULL)) THEN fn.Quantity  
    ELSE 0  
   END) AS 'totC1',  
  SUM(CASE  
    WHEN fn.BillStatus = 'return' AND vm.ProvisionalDate IS NULL THEN fn.Quantity ELSE 0  
   END) AS 'retC1',  
  SUM(CASE   
    WHEN vm.ProvisionalDate IS NULL AND fn.BillStatus = 'paid' AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL) THEN fn.PaidAmount  
    WHEN vm.ProvisionalDate IS NULL AND fn.BillStatus = 'credit' THEN fn.CreditAmount  
    WHEN vm.ProvisionalDate IS NULL AND fn.BillStatus = 'return' AND ((fn.PaymentMode = 'credit' AND fn.CreditDate IS NOT NULL) OR (fn.PaymentMode != 'credit' AND fn.PaidDate IS NOT NULL)) THEN fn.ReturnAmount  
    ELSE 0  
   END) AS 'totA1',  
  SUM(CASE  
    WHEN fn.BillStatus = 'return' AND vm.ProvisionalDate IS NULL THEN fn.ReturnAmount  
    ELSE 0  
   END) AS 'retA1',  
  SUM(CASE  
    WHEN fn.BillStatus = 'provisional' THEN fn.Quantity  
    ELSE 0  
   END) AS 'totC2',  
  SUM(CASE   
    WHEN fn.BillStatus = 'provisional' THEN fn.ProvisionalAmount   
    ELSE 0   
   END) AS 'totA2',  
  SUM(CASE   
    WHEN fn.BillStatus = 'credit' AND vm.ProvisionalDate IS NOT NULL THEN fn.Quantity  
    WHEN fn.BillStatus = 'paid' AND vm.ProvisionalDate IS NOT NULL AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL) THEN fn.Quantity  
    WHEN fn.BillStatus = 'return' AND vm.ProvisionalDate IS NOT NULL AND ((fn.PaymentMode = 'credit' AND fn.CreditDate IS NOT NULL) OR (fn.PaymentMode != 'credit' AND fn.PaidDate IS NOT NULL))  THEN fn.Quantity  
    ELSE 0  
   END) AS 'totC3',  
  SUM(CASE  
    WHEN fn.BillStatus = 'return' AND vm.ProvisionalDate IS NOT NULL  
    THEN fn.Quantity ELSE 0   
   END) AS 'retC3',  
  SUM(CASE  
    WHEN fn.BillStatus = 'paid' AND vm.ProvisionalDate IS NOT NULL AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL) THEN fn.PaidAmount  
    WHEN fn.BillStatus = 'credit' AND vm.ProvisionalDate IS NOT NULL THEN fn.CreditAmount  
    WHEN fn.BillStatus = 'return' AND vm.ProvisionalDate IS NOT NULL AND ((fn.PaymentMode = 'credit' AND fn.CreditDate IS NOT NULL) OR (fn.PaymentMode != 'credit' AND fn.PaidDate IS NOT NULL)) THEN fn.ReturnAmount  
    ELSE 0  
   END) AS 'totA3',  
  SUM(CASE  
    WHEN fn.BillStatus = 'return' AND vm.ProvisionalDate IS NOT NULL THEN fn.ReturnAmount  
    ELSE 0  
   END) AS 'retA3'  
  --,  
  --SUM(CASE  
  --  WHEN fn.BillStatus = 'paid' OR fn.BillStatus = 'credit' THEN 1 ELSE 0   
  -- END) AS 'totTC',  
  --SUM(CASE   
  --  WHEN fn.BillStatus = 'paid' THEN fn.PaidAmount  
  --  WHEN fn.BillStatus = 'credit' THEN fn.CreditAmount  
  --  ELSE 0  
  -- END) AS 'totTA'  
 FROM FN_BIL_GetTxnItemsInfoWithDateSeparation_PatientCensus(@FromDate,@ToDate) fn  
 JOIN VW_BIL_TxnItemsInfoWithDateSeparation vm ON fn.BillingTransactionItemId = vm.BillingTransactionItemId  
 WHERE ISNULL(@PerformerId,ISNULL(fn.PerformerId,0)) = ISNULL(fn.PerformerId,0)  
 and ISNULL(@DepartmentId,ISNULL(fn.DepartmentId,0))= ISNULL(fn.DepartmentId,0)  
 GROUP BY fn.PerformerName,fn.ServiceDepartmentName,fn.DepartmentId  
 --ORDER BY 1,2  
 ) tbl  
 order by tbl.Performer,tbl.ServiceDepartmentName  
  
SELECT Distinct dep.AdvanceReceived,dep.AdvanceSettled,prov.Provisional,prov.Unpaid   
FROM   
(  
 SELECT  
  SUM(ISNULL(AdvanceReceived, 0)) 'AdvanceReceived',  
  SUM(ISNULL(AdvanceSettled, 0)) 'AdvanceSettled'  
 FROM [FN_BIL_GetDepositNProvisionalBetnDateRange] (@FromDate, @ToDate)  
) dep,  
(  
   Select SUM(ProvisionalAmount-CancelledAmount) 'Provisional',  
       SUM(CreditAmount) 'Unpaid'  
    from  [dbo].[FN_BIL_GetTxnItemsInfoWithDateSeparation_PatientCensus](@FromDate, @ToDate)  
)prov  
END