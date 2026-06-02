/*-- =============================================
-- Author:        <Pratik Mani Lamichhane>
-- Create date: <29 March 2021>
-- Description:    <Handover Receive Transaction Report>
-- Change History-----
S.No.   Date/Author    Remarks
1.     29March'21/Pratik                Initial Draft
2.     25Aug'21/Dev Narayan				some changes done in report
3.     29Sept'21/Sud                    Filtering By Received On rather than VoucherDate.
-- =============================================*/
CREATE PROCEDURE [dbo].[SP_HandoverReceiveTransactionReport] (   
    @FromDate DATE = NULL,
    @ToDate DATE = NULL    
) 
AS
BEGIN
    SELECT handoverTxn.VoucherDate,
    handoverTxn.BankName,handoverTxn.VoucherNumber,handoverTxn.HandoverAmount,handoverTxn.DueAmount,
    handoverTxn.ReceivedById,receiverEmp.FullName 'ReceivedBy',
    d.DepartmentName,handoverEmp.FullName 'UserName',
    handoverTxn.ReceivedOn,handoverTxn.ReceiveRemarks
    FROM BIL_TXN_CashHandover handoverTxn
    JOIN BIL_CFG_Counter counter on counter.CounterId= handoverTxn.CounterId
    JOIN EMP_Employee handoverEmp on handoverEmp.EmployeeId= handoverTxn.HandoverByEmpId
    JOIN EMP_Employee receiverEmp on receiverEmp.EmployeeId= handoverTxn.ReceivedById
    LEFT JOIN MST_Department d on receiverEmp.DepartmentId = d.DepartmentId --and isnull(0,reciverEmp.DepartmentId)
    
    WHERE handoverTxn.IsActive=1 and handoverTxn.ReceivedById is not null 
	    and CONVERT(date,handoverTxn.ReceivedOn) between @FromDate AND @ToDate
    ORDER BY handoverTxn.ReceivedOn DESC
END