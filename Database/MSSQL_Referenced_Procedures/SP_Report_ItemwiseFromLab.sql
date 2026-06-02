CREATE PROCEDURE [dbo].[SP_Report_ItemwiseFromLab] 
  @FromDate Date=null,
  @ToDate Date=null  
AS
/*
FileName: [SP_Report_ItemwiseFromLab] '2019-10-09','2019-10-09'
CreatedBy/date: Dinesh/2019-09-22
Description: to get the total count and amount of individual Tests along with service Department Name
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Dinesh 2019-09-22          To get the count of Tests from Lab daywise
*/

BEGIN
If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
  BEGIN 
      select x.ServiceDepartmentName, x.ItemName,Sum(Quantity) 'Unit',Sum(TotalAmount) 'TotalAmount' from (
SELECT
case when bt.ItemName like '%ECHO%' then 'ECHO'
 ELSE bt.ItemName END as ItemName ,
--ELSE ISNULL (' ',0) END 'SD',
sd.ServiceDepartmentName 'ServiceDepartmentName',
    SUM(ISNULL(bt.Quantity, 0))  'Quantity',
    SUM(ISNULL(bt.TotalAmount, 0)) 'TotalAmount'
  FROM BIL_MST_ServiceDepartment sd 
  join BIL_TXN_BillingTransactionItems bt on sd.ServiceDepartmentId= bt.ServiceDepartmentId
  left join BIL_TXN_InvoiceReturnItems ret on bt.BillingTransactionItemId=ret.BillingTransactionItemId
  WHERE  ret.BillingTransactionItemId IS NULL and bt.BillStatus!='cancel' and
  convert(date,bt.CreatedOn) between CONVERT(DATE,@FromDate) and CONVERT(DATE,@ToDate) and sd.IntegrationName like 'LAB'
  group by bt.ItemName,sd.IntegrationName,sd.ServiceDepartmentName
  )as x
  --where x.ItemName !='Unknown'
  group by x.ItemName,x.ServiceDepartmentName
  order by Unit desc
  END  
END