CREATE PROCEDURE [dbo].[SP_FRC_GetTotalFractionByDoctor]
@FromDate Date=null ,
@ToDate Date=null	
AS
BEGIN
If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
BEGIN
 Select   ISNULL(emp.Salutation+' ','')+ emp.FirstName+ISNULL(' '+emp.MiddleName,'')+' '+ emp.LastName 'DoctorName',
 emp.EmployeeId,
 billingItems.ItemName,
 billingItems.TotalAmount as 'Price',
 frac.FinalAmount as 'FractionAmount',
 frac.CreatedOn from FRC_FractionCalculation frac
join BIL_TXN_BillingTransactionItems billingItems on frac.BillTxnItemId= billingItems.BillingTransactionItemId
join EMP_Employee emp on emp.EmployeeId= frac.DoctorId
where CONVERT(date,frac.CreatedOn) between @FromDate and @ToDate
order by frac.CreatedOn
END
END