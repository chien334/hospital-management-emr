--Altering SP_Report_BILL_DailyMISReport SP
--changed ProviderId to PerformerId and ProviderName to PerformerName
CREATE PROCEDURE [dbo].[SP_Report_BILL_DailyMISReport] --'2018-07-27','2018-07-27'  
@FromDate datetime = NULL,  
@ToDate datetime = NULL  
AS  
/*  
FileName: SP_Report_BILL_DailyMISReport  
Change History  
S.No.    UpdatedBy/Date  Remarks  
1       Ramavtar/2018-08-30     created the script  
2       Sud/2018-08-30          revised for provisional and billstatus  
3  Ajay/2018-12-12   getting data for SummaryView  
4  Ajay/2018-12-14   getting data from [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report]  
5  Ram/Ajay 17Dec2018  corrected calculation 
6  Krishna/9thJun'22	changed ProviderId to PerformerId and ProviderName to PerformerName
*/  
BEGIN  
  ;  
  WITH BilTxnItemsCTE  
  AS (SELECT  
    bil.BillingTransactionItemId,  
    pat.PatientCode AS HospitalNo,  
    pat.FirstName + ' ' + ISNULL(pat.MiddleName + ' ', '') + pat.LastName AS PatientName,  
    bil.PerformerName,  
    dept.DepartmentName,  
    bil.ServiceDepartmentName,  
    CONVERT(varchar(25), @FromDate) + '-to-' + CONVERT(varchar(25), @ToDate) 'billDate',  
    --ISNULL(bil.PaidDate,bil.CreatedDate) AS billDate,  
    bil.ItemName AS [description],  
    bil.Price,  
    bil.Quantity AS qty,  
    bil.SubTotal AS subTotal,  
    bil.DiscountAmount AS discount,  
    ISNULL(bil.ReturnAmount, 0) AS ReturnAmount,  
    bil.TotalAmount AS total,  
    bil.BillStatus, --sud:30Aug'18  
    bil.ProvisionalAmount AS 'ProvisionalAmount',--sud:30Aug'18 (We'll need this as well)  
    ISNULL(bil.BillingType, 'OutPatient')  
    AS BillingType  
  FROM (SELECT  
    *  
  FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate)) bil  
  JOIN PAT_Patient pat  
    ON bil.PatientId = pat.PatientId  
  JOIN BIL_MST_ServiceDepartment sdept  
    ON sdept.ServiceDepartmentId = bil.ServiceDepartmentId  
  JOIN MST_Department dept  
    ON dept.DepartmentId = sdept.DepartmentId  
  --WHERE bil.CreatedDate BETWEEN @FromDate AND @ToDate  
  )  
  SELECT  
    CASE  
      WHEN [DepartmentName] = 'ADMINISTRATION' AND  
        ServiceDepartmentName != 'CONSUMEABLES' THEN 'ADMINISTRATIVE'  
      WHEN ServiceDepartmentName = 'CONSUMEABLES' THEN 'CONSUMEABLES'  
      WHEN [DepartmentName] = 'OT' AND  
        [DepartmentName] != '' THEN 'OT'  
      WHEN [Description] = 'BED CHARGES' THEN 'BED'  
      WHEN [Description] = 'INDOOR-DOCTOR''S VISIT FEE (PER DAY)' THEN 'DOCTOR AND NURSING CARE'  
      WHEN [DepartmentName] = 'MEDICINE' THEN 'MEDICINE'  
      WHEN [DepartmentName] = 'SURGERY' THEN 'SURGERY'  
      ELSE DepartmentName  
    END AS departmentName,  
    HospitalNo 'hospitalNo',  
    PatientName 'patientName',  
    PerformerName 'performerName',  
    BillingType,  
    description 'itemName',  
    Price 'price',  
    qty 'quantity',  
    subTotal 'subTotal',  
    discount 'discount',  
    ReturnAmount 'return',  
    ISNULL(total, 0) - ISNULL(ReturnAmount, 0) 'netTotal',  
    BillStatus 'billStatus',  
    ProvisionalAmount AS 'provisional'  
  FROM BilTxnItemsCTE  
  ORDER BY departmentName ASC, BillingType DESC, PatientName ASC  
  
 SELECT  
  ISNULL(fn.PerformerId, 0) 'PerformerId',--PerformerId  
  ISNULL(fn.PerformerName, 'NoDoctor') 'PerformerName',--PerformerName  
  COUNT(  
   CASE  
    WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.PatientId  
    WHEN fn.BillStatus != 'return' THEN fn.PatientId  
   END) - COUNT(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.PatientId END) 'Count',  
  SUM(  
   CASE  
    WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.PaidAmount  
    WHEN fn.BillStatus != 'return' THEN fn.PaidAmount  
    ELSE 0  
   END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.ReturnAmount ELSE 0 END) 'TotalAmount'  
 FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate) fn  
 JOIN [VW_BIL_TxnItemsInfoWithDateSeparation_MIS_Report] vw ON fn.BillingTransactionItemId = vw.BillingTransactionItemId  
 WHERE fn.ItemName = 'Consultation Charge'  
  AND fn.BillStatus != 'provisional'  
  AND fn.BillStatus != 'cancelled'  
  AND fn.BillStatus != 'credit'  
  --AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL)  
 GROUP BY fn.PerformerId,  
  fn.PerformerName  
 ORDER BY 2  
  
 SELECT  
  fn.ItemName 'ItemName',  
  SUM(  
   CASE  
    WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.Qty_Temp  
    WHEN fn.BillStatus != 'return' THEN fn.Qty_Temp  
    ELSE 0  
   END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.Qty_Temp ELSE 0 END) 'Count',  
  SUM(  
   CASE  
    WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.PaidAmount  
    WHEN fn.BillStatus != 'return' THEN fn.PaidAmount  
    ELSE 0  
   END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.ReturnAmount ELSE 0 END) 'TotalAmount'  
 FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate) fn  
 JOIN [VW_BIL_TxnItemsInfoWithDateSeparation_MIS_Report] vw ON fn.BillingTransactionItemId = vw.BillingTransactionItemId  
 WHERE fn.ItemName LIKE '%Health Card%'  
  AND fn.BillStatus != 'provisional'  
  AND fn.BillStatus != 'cancelled'  
  AND fn.BillStatus != 'credit'  
  --AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL)  
 GROUP BY fn.ItemName  
  
 SELECT  
  VisitType,  
  ai.ServiceDepartmentName,  
  SUM([Count]) 'Count',  
  SUM([TotalAmount]) 'TotalAmount'  
 FROM (  
  SELECT  
   CASE  
    WHEN fn.visitType = 'inpatient' THEN 'IPD'  
    WHEN fn.visitType = 'outpatient' THEN 'OPD'  
    ELSE fn.VisitType  
   END AS VisitType,  
   fn.ServiceDepartmentName,  
   SUM(CASE  
    WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.Qty_Temp  
    WHEN fn.BillStatus != 'return' THEN fn.Qty_Temp  
    ELSE 0  
   END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.Qty_Temp ELSE 0 END) 'Count',  
   SUM(CASE  
    WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.PaidAmount  
    WHEN fn.BillStatus != 'return' THEN fn.PaidAmount  
    ELSE 0  
   END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.ReturnAmount ELSE 0 END) 'TotalAmount'  
  FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate) fn  
   INNER JOIN BIL_MST_ServiceDepartment sd ON fn.ServiceDepartmentId = sd.ServiceDepartmentId  
   JOIN [VW_BIL_TxnItemsInfoWithDateSeparation_MIS_Report] vw ON fn.BillingTransactionItemId = vw.BillingTransactionItemId  
  WHERE sd.IntegrationName = 'LAB'  
   AND fn.BillStatus != 'cancelled'  
   AND fn.BillStatus != 'provisional'  
   AND fn.BillStatus != 'credit'  
   --AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL)  
  GROUP BY fn.VisitType,  
           fn.ServiceDepartmentName  
 ) ai  
 GROUP BY ai.ServiceDepartmentName,  
           VisitType  
  UNION ALL  
  SELECT  
    ' ',  
    'Total',  
    SUM(  
  CASE  
   WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.Qty_Temp  
   WHEN fn.BillStatus != 'return' THEN fn.Qty_Temp  
   ELSE 0  
   END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.Qty_Temp ELSE 0 END) 'Total Count',  
 SUM(  
  CASE  
   WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.PaidAmount  
   WHEN fn.BillStatus != 'return' THEN fn.PaidAmount  
   ELSE 0  
  END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.ReturnAmount ELSE 0 END) 'TotalAmount'  
  FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate) fn  
 INNER JOIN BIL_MST_ServiceDepartment sd ON fn.ServiceDepartmentId = sd.ServiceDepartmentId  
 JOIN [VW_BIL_TxnItemsInfoWithDateSeparation_MIS_Report] vw ON fn.BillingTransactionItemId = vw.BillingTransactionItemId  
  WHERE sd.IntegrationName = 'LAB'  
 AND fn.BillStatus != 'cancelled'  
 AND fn.BillStatus != 'provisional'  
 AND fn.BillStatus != 'credit'  
 --AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL)  
  ORDER BY VisitType  
  
 SELECT  
  CASE  
   WHEN bt.visitType = 'inpatient' THEN 'IPD'  
   WHEN bt.visitType = 'outpatient' THEN 'OPD'  
   ELSE bt.VisitType  
  END AS VisitType,  
  bt.ServiceDepartmentName,  
  SUM(CASE  
   WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.Qty_Temp  
   WHEN fn.BillStatus != 'return' THEN fn.Qty_Temp  
   ELSE 0  
  END) - SUM(CASE WHEN fn.BillStatus = 'return' AND bt.PaidDate IS NOT NULL THEN fn.Qty_Temp ELSE 0 END) 'Count',  
  SUM(CASE  
   WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.PaidAmount  
   WHEN fn.BillStatus != 'return' THEN fn.PaidAmount  
   ELSE 0  
  END) - SUM(CASE WHEN fn.BillStatus = 'return' AND bt.PaidDate IS NOT NULL THEN fn.ReturnAmount ELSE 0 END) 'TotalAmount'  
 FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate) fn  
  INNER JOIN BIL_TXN_BillingTransactionItems bt ON fn.BillingTransactionItemId = bt.BillingTransactionItemId  
  INNER JOIN BIL_MST_ServiceDepartment sd ON bt.ServiceDepartmentId = sd.ServiceDepartmentId  
 WHERE sd.IntegrationName = 'Radiology'  
  AND fn.BillStatus != 'cancelled'  
  AND fn.BillStatus != 'provisional'  
  AND fn.BillStatus != 'credit'  
  --AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL)  
 GROUP BY bt.VisitType,  
  bt.ServiceDepartmentName  
  UNION ALL  
 SELECT  
  ' ',  
  'Total',  
  SUM(CASE  
   WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.Qty_Temp  
   WHEN fn.BillStatus != 'return' THEN fn.Qty_Temp  
   ELSE 0  
  END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.Qty_Temp ELSE 0 END) 'Total Count',  
  SUM(CASE  
   WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.PaidAmount  
   WHEN fn.BillStatus != 'return' THEN fn.PaidAmount  
   ELSE 0  
  END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.ReturnAmount ELSE 0 END) 'TotalAmount'  
 FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate) fn  
  INNER JOIN BIL_MST_ServiceDepartment sd ON fn.ServiceDepartmentId = sd.ServiceDepartmentId  
  JOIN [VW_BIL_TxnItemsInfoWithDateSeparation_MIS_Report] vw ON fn.BillingTransactionItemId = vw.BillingTransactionItemId  
 WHERE sd.IntegrationName = 'Radiology'  
  AND fn.BillStatus != 'cancelled'  
  AND fn.BillStatus != 'provisional'  
  AND fn.BillStatus != 'credit'  
  --AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL)  
 ORDER BY VisitType  
  
 SELECT  
  x.ItemName,  
  SUM(Quantity) 'Unit',  
  SUM(TotalAmount) 'TotalAmount'  
 FROM (  
  SELECT  
   CASE  
     WHEN fn.ItemName LIKE '%ECHO%' THEN 'ECHO'  
     WHEN fn.ItemName LIKE '%TMT%' THEN 'TMT'  
     WHEN fn.ItemName LIKE '%ECG%' THEN 'ECG'  
     WHEN fn.ItemName LIKE '%Holter%' THEN 'Holter'  
     ELSE 'Unknown'  
   END AS ItemName,  
   SUM(CASE  
     WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.Qty_Temp  
     WHEN fn.BillStatus != 'return' THEN fn.Qty_Temp  
     ELSE 0  
   END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.Qty_Temp ELSE 0 END) 'Quantity',  
   SUM(CASE  
     WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.PaidAmount  
     WHEN fn.BillStatus != 'return' THEN fn.PaidAmount  
     ELSE 0  
   END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.ReturnAmount ELSE 0 END) 'TotalAmount'  
  FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate) fn  
  JOIN [VW_BIL_TxnItemsInfoWithDateSeparation_MIS_Report] vw ON fn.BillingTransactionItemId = vw.BillingTransactionItemId  
  WHERE fn.BillStatus != 'cancelled'  
   AND fn.BillStatus != 'provisional'  
   AND fn.BillStatus != 'credit'  
   --AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL)  
  GROUP BY fn.ItemName  
 ) AS x  
 WHERE x.ItemName != 'Unknown'  
 GROUP BY x.ItemName  
  
 SELECT  
  fn.PerformerId,  
  fn.PerformerName,  
  dept.DepartmentName,  
  fn.ItemName,  
  SUM(  
   CASE   
    WHEN fn.BillStatus = 'return' AND  ((fn.PaymentMode = 'credit' AND fn.CreditDate IS NOT NULL) OR (fn.PaymentMode != 'credit' AND fn.PaidDate IS NOT NULL)) THEN fn.Quantity  
    WHEN fn.BillStatus != 'return' THEN fn.Qty_Temp  
    ELSE 0  
   END) - SUM(CASE WHEN fn.BillStatus = 'return' THEN fn.Qty_Temp ELSE 0 END) 'Quantity',  
  SUM(CASE WHEN fn.BillStatus = 'provisional' THEN fn.ProvisionalAmount ELSE 0 END) 'Prov_Amount',  
  SUM(CASE WHEN fn.BillStatus = 'credit' THEN fn.CreditAmount ELSE 0 END) 'Credit_Amount',  
  SUM(  
   CASE  
    WHEN fn.BillStatus = 'return' AND ((fn.PaymentMode = 'credit' AND fn.CreditDate IS NOT NULL) OR (fn.PaymentMode != 'credit' AND fn.PaidDate IS NOT NULL)) THEN fn.Total_Temp  
    WHEN fn.BillStatus != 'return' THEN fn.Total_Temp  
    ELSE 0   
   END) - SUM(CASE WHEN fn.BillStatus = 'return' THEN fn.ReturnAmount ELSE 0 END) 'TotalAmount'  
 FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate) fn  
  INNER JOIN EMP_Employee emp ON fn.PerformerId = emp.EmployeeId  
  INNER JOIN MST_Department dept ON emp.DepartmentId = dept.DepartmentId  
 WHERE fn.ItemName LIKE '%operation%'  
  AND fn.BillStatus != 'cancelled'  
  AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL OR fn.BillStatus = 'provisional')  
 GROUP BY fn.PerformerId,  
  fn.PerformerName,  
  dept.DepartmentName,  
  fn.ItemName,  
  fn.ServiceDepartmentName  
  
  SELECT  
   x.ItemName,  
   SUM(Quantity) 'Unit',  
   SUM(TotalAmount) 'TotalAmount'  
  FROM (  
   SELECT  
    CASE  
     WHEN fn.ItemName LIKE '%labor%' THEN 'LABOR Normal'  
     WHEN fn.ItemName LIKE '%LSCS%' THEN 'LABOR LSCS'  
     ELSE 'Unknown'  
    END AS ItemName,  
    SUM(  
     CASE  
      WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.Qty_Temp  
      WHEN fn.BillStatus != 'return' THEN fn.Qty_Temp  
      ELSE 0  
     END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.Qty_Temp ELSE 0 END) 'Quantity',  
    SUM(  
     CASE  
      WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.PaidAmount  
      WHEN fn.BillStatus != 'return' THEN fn.PaidAmount ELSE 0  
     END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.ReturnAmount ELSE 0 END) 'TotalAmount'  
   FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate) fn  
   JOIN [VW_BIL_TxnItemsInfoWithDateSeparation_MIS_Report] vw ON fn.BillingTransactionItemId = vw.BillingTransactionItemId  
   WHERE fn.BillStatus != 'cancelled'  
    AND fn.BillStatus != 'provisional'  
    AND fn.BillStatus != 'credit'  
    --AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL)  
   GROUP BY fn.ItemName  
  ) AS x  
  WHERE x.ItemName != 'Unknown'  
  GROUP BY x.ItemName  
  
 SELECT  
     'No. of Admssions' AS 'PatientType',  
  COUNT(patientAdmissionId) 'Count'  
 FROM ADT_PatientAdmission  
 WHERE CONVERT(date, AdmissionDate) BETWEEN @FromDate AND @ToDate  
    
 UNION ALL  
 SELECT  
  'No. of Discharges',  
  COUNT(patientAdmissionId)  
 FROM ADT_PatientAdmission  
 WHERE CONVERT(date, DischargeDate) BETWEEN @FromDate AND @ToDate  
  AND DischargeDate IS NOT NULL  
  
 UNION ALL  
 SELECT  
     'Total No. of Admitted Patient' AS 'PatientType',  
  COUNT(patientAdmissionId) 'Count'  
 FROM ADT_PatientAdmission  
 WHERE  Convert(date,DischargeDate) is null and AdmissionStatus = 'admitted'  
  
 SELECT  
  x.ItemName,  
  SUM(Quantity) 'Unit',  
  SUM(TotalAmount) 'TotalAmount'  
 FROM (  
  SELECT  
   CASE  
    WHEN fn.ItemName LIKE '%ECHO%' THEN 'ECHO'  
    WHEN fn.ItemName LIKE '%TMT%' THEN 'TMT'  
    WHEN fn.ItemName LIKE '%ECG%' THEN 'ECG'  
    WHEN fn.ItemName LIKE '%Holter%' THEN 'Holter'  
    WHEN fn.ItemName LIKE '%CONSULTATION%' THEN 'OPD'  
    WHEN fn.ItemName LIKE '%Health Card%' THEN 'Health Card'  
    WHEN sd.IntegrationName LIKE 'LAB' THEN 'LABS'  
    WHEN sd.IntegrationName LIKE 'RADIOLOGY' THEN 'RADIOLOGY'  
    WHEN fn.ItemName LIKE '%Operation%' THEN 'OPERATION CHARGES'  
    ELSE 'Hospital Other Charges'  
   END AS ItemName,  
   SUM(  
    CASE  
     WHEN fn.BillStatus = 'return' AND  fn.PaidDate IS NOT NULL THEN fn.Qty_Temp  
     WHEN fn.BillStatus != 'return' THEN fn.Qty_Temp  
     ELSE 0  
    END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.Qty_Temp ELSE 0 END) 'Quantity',  
   SUM(  
    CASE  
     WHEN fn.BillStatus = 'return' AND fn.PaidDate IS NOT NULL THEN fn.PaidAmount  
     WHEN fn.BillStatus != 'return' THEN fn.PaidAmount  
     ELSE 0  
    END) - SUM(CASE WHEN fn.BillStatus = 'return' AND vw.PaidDate IS NOT NULL THEN fn.ReturnAmount ELSE 0 END) 'TotalAmount'  
  FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation_MIS_Report](@FromDate, @ToDate) fn  
  INNER JOIN BIL_MST_ServiceDepartment sd ON sd.ServiceDepartmentId = fn.ServiceDepartmentId  
  JOIN [VW_BIL_TxnItemsInfoWithDateSeparation_MIS_Report] vw ON fn.BillingTransactionItemId = vw.BillingTransactionItemId  
  WHERE fn.BillStatus != 'cancelled'  
   AND fn.BillStatus != 'provisional'  
   AND fn.BillStatus != 'credit'  
   --AND (fn.PaymentMode != 'credit' OR fn.CreditDate IS NOT NULL)  
  GROUP BY fn.ItemName,  
   sd.IntegrationName  
 ) AS x  
 GROUP BY x.ItemName  
 UNION ALL  
 SELECT  
  'Earlier Return Amount' 'Item Name',  
  ' ' AS ' ',  
  -SUM(sum.TotalAmount) 'Total Amount'  
 FROM (SELECT  
  DISTINCT  
  (ret.BillReturnId),  
  ret.TotalAmount  
  FROM (SELECT  
  br.CreatedOn 'Ret Date',  
  bt.ItemName,  
  bt.Quantity 'Unit',  
  bt.PaidDate 'PaidDate',  
  br.BillReturnId 'BillReturnId',  
  br.TotalAmount 'TotalAmount'  
 FROM BIL_TXN_InvoiceReturn br  
 INNER JOIN BIL_TXN_BillingTransactionItems bt ON br.BillingTransactionId = bt.BillingTransactionId  
 WHERE CONVERT(date, br.createdon) BETWEEN @FromDate AND @ToDate  
  AND 1 = 2   
  AND CONVERT(date, bt.CreatedOn) != CONVERT(date, br.CreatedOn)) ret) sum  
 UNION ALL  
 SELECT  
  'Advance Received' AS 'ItemName',  
  ' ',  
  ISNULL(SUM(Amount), 0) 'Total Amount'  
 FROM BIL_TXN_Deposit  
 WHERE CONVERT(date, createdon) BETWEEN @FromDate AND @ToDate  
  AND DepositType = 'Deposit'  
 UNION ALL  
 SELECT  
     'Advance Settled' AS 'ItemName',  
  ' ',  
  ISNULL(-SUM(Amount), 0)  
 FROM BIL_TXN_Deposit  
 WHERE CONVERT(date, createdon) BETWEEN @FromDate AND @ToDate  
  AND DepositType = 'depositdeduct'  
 UNION ALL  
 SELECT  
  'Advance Returned' AS 'ItemName',  
  ' ',  
  -ISNULL(SUM(Amount), 0)  
 FROM BIL_TXN_Deposit  
 WHERE CONVERT(date, createdon) BETWEEN @FromDate AND @ToDate  
  AND DepositType = 'ReturnDeposit'  
  
 select   'Total' as Type,sum(Quantity) as Quantity,  sum(TotalAmount-ReturnAmount) as 'TotalAmount'  
 from (   
          SELECT  sum(inv.PaidAmount)as TotalAmount, sum(inv.TotalQuantity) as Quantity ,0 as ReturnAmount, sum(inv.DiscountAmount) as DiscountAmount  
            FROM [PHRM_TXN_Invoice] inv         
              where  convert(date, inv.CreateOn)   BETWEEN @FromDate and @ToDate   
  
     union all  
      
     select  0 as TotalAmount,sum(invRet.Quantity) as RetQuantity,sum(invRet.TotalAmount ) as ReturnAmount,  sum(-(invRet.DiscountPercentage/100)*invRet.SubTotal ) as DiscountPercentage  
     From[PHRM_TXN_InvoiceReturnItems] invRet  
       
     where convert(date, invRet.CreatedOn)  BETWEEN @FromDate and @ToDate and invRet.InvoiceId is not null  
       
     )tabletotal  
END