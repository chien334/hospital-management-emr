/*
  FileName: [SP_MAT_RPT_GetMaternityPaymentDetails] 
  CreatedBy/date: Swapnil/19-11-2021
  Execute SP : exec [SP_MAT_RPT_GetMaternityPaymentDetails] '2022-01-01','2022-03-25'
  Description: To get the Details of  Maternity Payment Details Report
  Remarks:    
  Change History
  S.No.    UpdatedBy/Date                        Remarks
  1.    Swapnil/19-11-2021                   created the script
  2.    Aniket/21-11-2021                    added patientpaymentId d.PatientPaymentId and updated InAmount instead of OutAmount and vise versa 
  3.    Dev Narayan/31-03-2022               Enhancement of report
  */
  CREATE PROCEDURE [dbo].[SP_MAT_RPT_GetMaternityPaymentDetails]
  @FromDate datetime = null, 
  @ToDate datetime = null, 
  @UserId int = 0 
  AS
  BEGIN
  IF (
    (@FromDate IS NOT NULL) 
    AND (@ToDate IS NOT NULL)
  ) 
SET 
  @UserId = ISNULL(@UserId, 0) BEGIN 
select 
  SUM(
    ISNULL(d.PaidAmount, 0)
  ) - SUM(
    ISNULL(d.ReturnAmount, 0)
  ) as 'NetPaidAmount', 
  SUM(
    ISNULL(d.PaidAmount, 0)
  ) 'PaidToPatient', 
  SUM(
    ISNULL(d.ReturnAmount, 0)
  ) 'ReturnedFromPatient', 
  d.PatientPaymentId as 'PatientPaymentId' 
from 
  (
    select 
      case when mtp.TransactionType = 'MaternityAllowance' then mtp.OutAmount end as 'PaidAmount', 
      case when mtp.TransactionType = 'MaternityAllowanceReturn' then mtp.InAmount end as 'ReturnAmount', 
      mtp.PatientPaymentId 
    from 
      MAT_TXN_PatientPayments mtp 
    WHERE 
      (
        CONVERT(date, mtp.CreatedOn) BETWEEN CONVERT(date, @FromDate) 
        AND CONVERT(date, @ToDate)
      ) 
      AND mtp.TransactionType in (
        'MaternityAllowance', 'MaternityAllowanceReturn'
      ) 
      AND (
        mtp.CreatedBy = @UserId 
        or @UserId = 0
      )
  ) as d 
Group by 
  d.PatientPaymentId 
select 
  mtp.ReceiptNo, 
  mtp.CreatedOn, 
  case when mtp.TransactionType = 'MaternityAllowance' then 'Maternity Allowance' else 'Maternity Allowance Return' end as 'TransactionType', 
  p.ShortName, 
  p.PatientCode as 'HospitalNo', 
  p.Age, 
  p.Gender, 
  e.FullName, 
  mtp.PatientPaymentId as 'PatientPaymentId', 
  case when mtp.TransactionType = 'MaternityAllowance' then mtp.OutAmount else 0 end as 'Amount', 
  case when mtp.TransactionType = 'MaternityAllowanceReturn' then mtp.InAmount else 0 end as 'ReturnAmount' 
from 
  MAT_TXN_PatientPayments mtp 
  join EMP_Employee e on mtp.CreatedBy = e.EmployeeId 
  join PAT_Patient p on mtp.PatientId = p.PatientId 
WHERE 
  (
    CONVERT(date, mtp.CreatedOn) BETWEEN CONVERT(date, @FromDate) 
    AND CONVERT(date, @ToDate)
  ) 
  and mtp.TransactionType in (
    'MaternityAllowance', 'MaternityAllowanceReturn'
  ) 
  AND (
    mtp.CreatedBy = @UserId 
    OR @UserId = 0
  ) 
 END 
END