CREATE PROCEDURE [dbo].[SP_Report_BILL_CounterNUsersCollectionDaily]
		@FromDate Datetime=null ,
		@ToDate DateTime=null
AS
/*
FileName: [SP_Report_BILL_CounterCollection]
CreatedBy/date: dinesh/2017-07-09
Description: to get countercollection between given range..
Remarks:
 * Removed usage of FN_BILL_GetCounterNUserCollectionDaily after CashTransactionTable is introduced..
 * we can remove above function if above doesn't have any other dependencies.. 

Change History
S.No.    UpdatedBy/Date                        Remarks
1       dinesh/2017-07-09	                   created
2        sudarshan/2017-07-15                 modified to re-use this SP for both Counter and UserCollections
3       sud/29May'18                        updated as per new billing structure
4.      sud/5May'21                         Updated after adding EMPCashTransaction table structure. 
5.      Sud/13Jun'21                        Excluding HandoverGiven amount from deduction.
*/
BEGIN
	SELECT CONVERT(Date,TransactionDate) 'BillDate' 
	, cash.EmployeeId, emp.FullName 'EmployeeName',
	SUM(ISNULL(InAmount,0)- ISNULL(OutAmount,0)) 'UserDayCollection'
	FROM TXN_EmpCashTransaction cash INNER JOIN EMP_Employee emp 
	   on cash.EmployeeId=emp.EmployeeId
	Where CONVERT(Date,TransactionDate) BETWEEN @FromDate and @ToDate
	AND TransactionType NOT IN ('HandoverGiven') -- add other txntype here as required.

	Group by CONVERT(Date,TransactionDate), cash.EmployeeId, emp.FullName

	SELECT CONVERT(Date,TransactionDate) 'BillDate' 
	, cash.CounterID, cntr.CounterName,
	SUM(ISNULL(InAmount,0)- ISNULL(OutAmount,0)) 'CounterDayCollection'
	FROM TXN_EmpCashTransaction cash INNER JOIN BIL_CFG_Counter cntr 
	   on cash.CounterID=cntr.CounterId
	Where CONVERT(Date,TransactionDate) BETWEEN @FromDate and @ToDate
	AND TransactionType NOT IN ('HandoverGiven') -- add other txntype here as required.
	Group by CONVERT(Date,TransactionDate), cash.CounterID, cntr.CounterName

END