CREATE PROCEDURE [dbo].[SP_Report_HandoverSummaryReport]  ---Exec SP_Report_HandoverSummaryReport
@FiscalYrId INT
AS
/* =============================================
-- Author:		<Pratik Mani Lamichhane>
-- Create date: <10 Aug 2021>
-- Description:	<Handover Summary Report>
-- Change History:
1. Sud/27-Oct'21   Added FiscalYearId param to get previous Date's due amount and 
                   changed the calculation accordingly

2. Krishna/13th Jan'22  Added ReceivePendingAmount and TotalDueAmount(EMR:4763)

-- ============================================= */
BEGIN
IF(ISNULL(@FiscalYrId,0)=0)
BEGIN
  SET @FiscalYrId=(Select FiscalYearId from BIL_CFG_FiscalYears where Getdate()>StartYear AND GETDATE()< EndYear)
END

Declare  @FyStartDate DATE, @FyEndDate Date

Select @FyStartDate = Convert(Date,StartYear), @FyEndDate= Convert(Date,EndYear)
from BIL_CFG_FiscalYears
Where FiscalYearId = @FiscalYrId

Select empMst.EmployeeId, emp1.FullName,
    ISNULL(prevFy.Prev_DueAmt,0) 'PreviousDueAmount',
    ISNULL(colln.CollectionAmount,0) 'CollectionTillDate', 
    ISNULL(deps.HandoverAmount,0) 'HandoverTillDate',
    ISNULL(prevFy.Prev_DueAmt,0) + Isnull(colln.CollectionAmount,0)-ISNULL(deps.HandoverAmount,0) 'DueAmount' ,
	ISNULL(hTxn.ReceivePendingAmount,0) 'ReceivePendingAmount',
	(ISNULL(prevFy.Prev_DueAmt,0) + Isnull(colln.CollectionAmount,0)-ISNULL(deps.HandoverAmount,0)) + ISNULL(hTxn.ReceivePendingAmount,0) 'TotalDueAmount'
	

from 
( Select Distinct EmployeeId from TXN_EmpCashTransaction ) empMst 

LEFT JOIN EMP_Employee emp1  ON empMst.EmployeeId = emp1.EmployeeId 

Left join 
(
	Select EmployeeId,
	Sum(Isnull(InAmount,0))- Sum(Isnull(OutAmount,0)) 'Prev_DueAmt'
	from TXN_EmpCashTransaction
	Where Convert(Date,TransactionDate) < Convert(Date, @FyStartDate)
	Group by EmployeeId
)prevFy

ON empMst.EmployeeId=prevFy.EmployeeId


LEFT JOIN
(
    SELECT EmployeeId,
    Sum(ISNULL(InAmount,0)) - Sum(ISNULL(OutAmount,0)) 'CollectionAmount'
    FROM TXN_EmpCashTransaction  
    Where  TransactionType !='HandoverGiven'
	    and Convert(Date,TransactionDate) Between @FyStartDate and @FyEndDate
	    
    Group by EmployeeId
) colln
 ON empMst.EmployeeId = colln.EmployeeId

 LEFT JOIN
(
    SELECT EmployeeId,
    Sum(Isnull(OutAmount,0)) 'HandoverAmount'
    FROM TXN_EmpCashTransaction  
    Where TransactionType ='HandoverGiven'
	and Convert(Date,TransactionDate) Between @FyStartDate and @FyEndDate
    Group by EmployeeId
) deps
 ON empMst.EmployeeId = deps.EmployeeId

 LEFT JOIN 
 (
	SELECT HandoverByEmpId,
	SUM(ISNULL(HandoverAmount,0)) 'ReceivePendingAmount'
	FROM BIL_TXN_CashHandover
	WHERE ReceivedById IS NULL 
	AND Convert(Date,CreatedOn) BETWEEN @FyStartDate AND @FyEndDate
	GROUP BY HandoverByEmpId
 )hTxn
 ON empMst.EmployeeId = hTxn.HandoverByEmpId

 Order by emp1.FullName
 End