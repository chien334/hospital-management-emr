CREATE PROCEDURE [dbo].[SP_Report_DailyCollectionVsHandoverReport]  
(@FromDate DATE, @ToDate DATE)
AS
-- =============================================
-- Author:        <Pratik Mani Lamichhane>
-- Create date: <10 Aug 2021>
-- Description:    <DailyCollection Vs Handover Report>
-- =============================================
BEGIN

 

Select empMst.EmployeeId, emp1.FullName,
        ISNULL(colln.CollectionAmount,0) 'CollectionTillDate', 
        ISNULL(deps.HandoverAmount,0) 'HandoverTillDate',
        ISNULL(colln.CollectionAmount,0)-ISNULL(deps.HandoverAmount,0) 'DueAmount',
        empMst.Dates as [Date]

 

from 
(
    Select * from (Select Distinct EmployeeId from TXN_EmpCashTransaction) employee
    CROSS JOIN (Select * from FN_COMMON_GetAllDatesBetweenRange(@FromDate,@ToDate)) dates
) empMst 

 

LEFT JOIN EMP_Employee emp1  ON empMst.EmployeeId = emp1.EmployeeId 

 

LEFT JOIN
(
    SELECT EmployeeId,
    Sum(ISNULL(InAmount,0)) - Sum(ISNULL(OutAmount,0)) 'CollectionAmount',
    CONVERT(DATE,TransactionDate) as 'CollectionDate'
    FROM TXN_EmpCashTransaction  
    Where  TransactionType !='HandoverGiven' and Convert(Date,TransactionDate) BETWEEN Convert(Date,@FromDate) and Convert(Date,@ToDate)
    Group by EmployeeId,CONVERT(DATE,TransactionDate)
) colln ON empMst.EmployeeId = colln.EmployeeId AND empMst.Dates = CollectionDate

 


 LEFT JOIN
(
    SELECT EmployeeId,
    Sum(Isnull(OutAmount,0)) 'HandoverAmount',
    CONVERT(DATE,TransactionDate) as 'HandoverTransactionDate'
    FROM TXN_EmpCashTransaction  
    Where TransactionType ='HandoverGiven' and Convert(Date,TransactionDate) BETWEEN Convert(Date,@FromDate) and Convert(Date,@ToDate)
    Group by EmployeeId,CONVERT(DATE,TransactionDate)
) deps ON empMst.EmployeeId = deps.EmployeeId AND empMst.Dates = HandoverTransactionDate

 Where ISNULL(colln.CollectionAmount,0) !=0 OR  ISNULL(deps.HandoverAmount,0)!=0
 Order by emp1.FullName
 End