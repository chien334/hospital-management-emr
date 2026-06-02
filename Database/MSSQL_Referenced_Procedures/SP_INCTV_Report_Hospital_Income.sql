CREATE PROCEDURE [dbo].[SP_INCTV_Report_Hospital_Income] 
	@FromDate DATE = null, 
	@ToDate DATE = null, 
	@ServiceDepartments VARCHAR(1000) = ''
/*  
FileName: SP_INCTV_Report_Hospital_Income  
CreatedBy/date: Krishna/7th,July'22   
Description:  
   - To get details about incentive given on service department level   
   - To get Hospital Income after incentive distribution  
Remarks:        
Change History    
S.No.    UpdatedBy/Date               Change History    
1.     Krishna/7th,July'22            Initial draft  
2.     Krishna/8th,Aug'22             NetSales issue fixed
3.     Krishna/05th,Sept'22           Added Service department filter
*/
AS 
BEGIN
   SELECT
      itms.ServiceDepartmentId,
      itms.ServiceDepartmentName,
      SUM(ISNULL(itms.NetSales, 0)) 'NetSales',
      SUM(ISNULL(inctv.ReferralCommission, 0)) 'ReferralCommission',
      (
         SUM(ISNULL(itms.NetSales, 0)) - SUM(ISNULL(inctv.ReferralCommission, 0))
      )
      AS 'GrossIncome',
      SUM(ISNULL(inctv.OtherIncentive, 0)) 'OtherIncentive',
      (
		(SUM(ISNULL(itms.NetSales, 0)) - SUM(ISNULL(inctv.ReferralCommission, 0))) - SUM(ISNULL(inctv.OtherIncentive, 0))
      )
      AS 'HospitalNetIncome' 
   FROM
      (
         SELECT
            itm.BillingTransactionItemId,
            ServiceDepartmentId,
            SUM(ISNULL(itm.TotalAmount, 0) - ISNULL(retItm.RetAmount, 0)) 'NetSales',
            --Deduct ReturnAmount to get NetSales
            ServiceDepartmentName,
            CONVERT(DATE, txn.CreatedOn) 'InvoiceDate' 
         FROM
            BIL_TXN_BillingTransaction txn 
            INNER JOIN
               BIL_TXN_BillingTransactionItems itm 
               ON itm.BillingTransactionId = txn.BillingTransactionId 
            LEFT JOIN
               (
                  SELECT
                     BillingTransactionId,
                     BillingTransactionItemId,
                     SUM(RetTotalAmount) 'RetAmount' 
                  FROM
                     BIL_TXN_InvoiceReturnItems 
                  GROUP BY
                     BillingTransactionId,
                     BillingTransactionItemId
               )
               retItm 
               ON itm.BillingTransactionItemId = retItm.BillingTransactionItemId 
         WHERE
            CONVERT(DATE, txn.CreatedOn) BETWEEN @FromDate AND @ToDate 
         GROUP BY
            itm.BillingTransactionItemId,
            itm.ServiceDepartmentId,
            itm.ServiceDepartmentName,
            CONVERT(DATE, txn.CreatedOn) 				---End: Get netsales at each billingTransacitonItem level---
      )
      itms 
      LEFT JOIN
         (
            --We need 2 level select query here.
            --1st level to Seggregate Referral and Other Commission at BillingTxnitem + IncentiveType level
            --2nd Level to SUM up that amount again at BillingTxnitem level.
            SELECT
               BillingTransactionItemId,
               SUM(ISNULL(ReferralCommission, 0)) 'ReferralCommission',
               SUM(ISNULL(OtherIncentive, 0)) 'OtherIncentive' 
            FROM
               (
                  SELECT
                     BillingTransactionItemId,
                     IncentiveType,
                     CASE
                        WHEN
                           IncentiveType = 'referral' 
                        THEN
                           SUM(ISNULL(IncentiveAmount, 0)) 
                     END
                     AS 'ReferralCommission', 
                     CASE
                        WHEN
                           (
                              IncentiveType = 'performer' 
                              OR IncentiveType = 'prescriber'
                           )
                        THEN
                           SUM(ISNULL(IncentiveAmount, 0)) 
                     END
                     AS 'OtherIncentive' 
                  FROM
                     INCTV_TXN_IncentiveFractionItem 
                  WHERE
                     ISNULL(IsActive, 0) = 1 
                     AND CONVERT(DATE, TransactionDate) BETWEEN @FromDate AND @ToDate 
                  GROUP BY
                     BillingTransactionItemId, IncentiveType 							---end :1st level query gives BillingTxnItemId, IncentiveType and their respective amounts---
               )
               A 					--End of 2nd Level query for outer grouping
            GROUP BY
               BillingTransactionItemId 
         )
         inctv 
         ON itms.BillingTransactionItemId = inctv.BillingTransactionItemId 
      INNER JOIN
         (
            SELECT
               VALUE AS 'ServiceDepartmentId' 
            FROM
               string_split(@ServiceDepartments, ',')
         )
         serv 
         ON itms.ServiceDepartmentId = serv.ServiceDepartmentId 
   WHERE
      CONVERT(DATE, itms.InvoiceDate) BETWEEN @FromDate AND @ToDate 
   GROUP BY
      itms.ServiceDepartmentName,
      itms.ServiceDepartmentId 
   ORDER BY
      itms.ServiceDepartmentName 
END