CREATE PROCEDURE [dbo].[SP_PHRM_SaleReturnReport] 
@FromDate datetime=null,
@ToDate datetime=null
AS
 /*
FileName:[SP_PHRM_SaleReturnReport]
CreatedBy/date: Vikas/2018-08-06
Description: .
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Vikas/2018-08-06                       created the script
2.     VIKAS/2019-01-02               report doesnt shown correctly so changes in script. 
3.     Rusha/2019-04-09             report doesnot show quantity so add return quantity
4.     Rusha/2019-07-03             report doesnot showing correct amount so updated script
5.     Abhishek/2019-07-03             report doesnot showing correct amount so updated script
*/
 BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL)) 
    BEGIN
          select convert(date,invr.CreatedOn) as[Date],convert(date, inv.CreateOn) as [InvDate], 
           inv.InvoicePrintId,usr.UserName,
            pat.FirstName+' '+ ISNULL( pat.MiddleName,'')+' '+pat.LastName  as PatientName,
          sum(invr.TotalAmount) as TotalAmount, sum(inv.DiscountAmount) as Discount, Sum(invr.ReturnedQty) as Quantity
            from [PHRM_TXN_Invoice]inv
           join [PHRM_TXN_InvoiceReturnItems]invr
              on inv.InvoiceId=invr.InvoiceId
          join RBAC_User usr
              on usr.EmployeeId=invr.CreatedBy 
          join PAT_Patient pat
              on pat.PatientId=inv.PatientId
                where  convert(date, invr.CreatedOn)   BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())
                
          group by convert(date,inv.CreateOn), convert(date, invr.CreatedOn),usr.UserName, 
          pat.FirstName,pat.MiddleName,pat.LastName, inv.InvoicePrintId
          order by convert(date,invr.CreatedOn) desc

  End
End