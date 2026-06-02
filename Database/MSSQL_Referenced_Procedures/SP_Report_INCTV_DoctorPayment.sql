CREATE PROCEDURE [dbo].[SP_Report_INCTV_DoctorPayment] --EXEC SP_Report_INCTV_DoctorPayment '2019-07-20','2020-3-31'
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL
AS
/*-- Author: Pratik/31March'20
-- Description:	To get Incentive payment reports at doctor level for given date range
--Change History:
S.No.  Author/Date                   Remarks
1.    Pratik/31March'20              Initial Draft
2.	  Ashish/29April'20				add two clm Voucher no. & remarks for get in report.
3.    Pratik/13Dec'21               Adding Doctor PAN number field in Incentive report

*/
BEGIN
  SELECT Convert(Date,PaymentDate) 'PaymentDate',
  emp.FullName 'ReceiverName',emp.PANNumber, payinfo.ReceiverId,PaymentInfoId,
  ISNULL(payinfo.TotalAmount,0) 'TotalAmount',
  ISNULL(payinfo.TDSAmount,0) 'TDSAmount',
  ISNULL(payinfo.NetPayAmount,0) 'NetPayAmount',
  ISNULL(payinfo.AdjustedAmount,0) 'AdjustedAmount',
  ISNULL(payinfo.VoucherNumber,0) 'VoucherNumber',
  ISNULL(payinfo.Remarks,0) 'Remarks',
  (select FullName from EMP_Employee where EmployeeId=payinfo.CreatedBy) as 'CreatedBy'
  from
  INCTV_TXN_PaymentInfo payinfo
  join EMP_Employee emp
  on emp.EmployeeId=payinfo.ReceiverId

  WHERE Isnull(payinfo.IsActive,0)=1
	    AND Convert(Date,payinfo.PaymentDate) Between @FromDate AND @ToDate  

END