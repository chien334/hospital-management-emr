CREATE PROCEDURE [dbo].[SP_Report_HandoverDetailReport]  ---Exec SP_Report_HandoverDetailReport '2021-06-16','2021-08-09', 28
(@FromDate DATE, @ToDate DATE, @EmployeeId INT)
AS
-- =============================================
-- Author:		<Pratik Mani Lamichhane>
-- Create date: <10 Aug 2021>
-- Description:	<Handover Detail Report>
-- =============================================
BEGIN
select handoverTxn.BankName,handoverTxn.VoucherNumber,
	handoverTxn.HandoverAmount, handoverTxn.DueAmount, 
	d.DepartmentName,handoverTxn.CreatedOn 'HandoverDate',
	handoverTxn.HandoverByEmpId, handoverEmp.FullName 'UserName',
	handoverTxn.ReceivedById,receiverEmp.FullName 'ReceivedBy',
	handoverTxn.ReceivedOn,handoverTxn.ReceiveRemarks,
	counter.CounterName
	from BIL_TXN_CashHandover handoverTxn

	join BIL_CFG_Counter counter on counter.CounterId= handoverTxn.CounterId
	join EMP_Employee handoverEmp on handoverEmp.EmployeeId= handoverTxn.HandoverByEmpId
	join EMP_Employee receiverEmp on receiverEmp.EmployeeId= handoverTxn.ReceivedById
	left join MST_Department d on receiverEmp.DepartmentId = d.DepartmentId 
	
	where handoverTxn.IsActive=1 
	and CONVERT(date,handoverTxn.CreatedOn) between @FromDate AND @ToDate
	and	handoverTxn.HandoverByEmpId = @EmployeeId
		
 End