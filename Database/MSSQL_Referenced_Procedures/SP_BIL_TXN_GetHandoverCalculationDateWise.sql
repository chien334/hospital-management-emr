Create PRocedure [dbo].[SP_BIL_TXN_GetHandoverCalculationDateWise] --EXEC SP_BIL_TXN_GetHandoverCalculationDateWise '2020-02-16','2020-02-16'
(@FromDate DATE, @ToDate DATE)
AS
/*
 File: SP_BIL_TXN_GetHandoverCalculationDateWise
 Details: To get total handover given amount and received amount by user on particular date range.
 Change History:
 S.No.   Date/Author           Remarks
 1.      16Feb'20/Sud          Initial Draft (Needs Revision)
*/
BEGIN

Select EmployeeId, HandOverDate, SUM(GivenAmount) 'GivenAmount', SUM(ReceivedAmount) 'ReceivedAmount'
FROM

(
 Select EmployeeID, HandoverDate 
, Case WHEN HandOverType='HandoverGiven' THEN HandoverAmount
   ELSE 0 END AS GivenAmount
,  Case WHEN HandOverType='HandoverReceived' THEN HandoverAmount
   ELSE 0 END AS ReceivedAmount

From 
(
SELECT 'HandoverGiven' AS 'HandOverType', Convert(Date,CreatedOn) 'HandoverDate', UserId 'EmployeeID', SUM(HandoverAmount) 'HandoverAmount'
FROM BIL_MST_Handover
Group By Convert(Date,CreatedOn),UserId 
UNION ALL
SELECT 'HandoverReceived' AS 'HandOverType', Convert(Date,CreatedOn) 'HandoverDate', HandoverUserId 'EmployeeID', SUM(HandoverAmount) 'HandoverAmount'
FROM BIL_MST_Handover
Group By Convert(Date,CreatedOn),HandoverUserId 
) b
Where HandoverAmount !=0
 AND HandoverDate BETWEEN Convert(Date,@FromDate) and Convert(Date,@ToDate)

) overall

Group By EmployeeId, HandOverDate

Order by HandoverDate, EmployeeID

END