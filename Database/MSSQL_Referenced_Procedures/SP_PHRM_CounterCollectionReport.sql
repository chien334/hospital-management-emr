CREATE PROCEDURE [dbo].[SP_PHRM_CounterCollectionReport] 
@FromDate datetime=null,
 @ToDate datetime=null
 AS
 /*
FileName: [SP_PHRM_CounterCollectionReport] '05/01/2018','08/08/2018'
CreatedBy/date: Nagesh/Vikas/2018-07-31
Description: .
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Nagesh/Vikas/2018-08-01	              created the script
2	   Rusha/04-08-2019						  Remove Sum() function to get details of each counter and user		
*/
-- BEGIN
--  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL)) 
--		BEGIN
			
--			select convert(date,inv.CreatedOn) as [Date], usr.UserName as UserName,cnt.CounterName as CounterName, 
--			sum(inv.TotalAmount)as TotalAmount, sum(inv.SubTotal*inv.DiscountPercentage / 100.0) as [DiscountAmount]
--			 from PHRM_TXN_InvoiceItems inv
--				join RBAC_User usr
--				on inv.CreatedBy=usr.EmployeeId
--				join PHRM_MST_Counter cnt on inv.CounterId=cnt.CounterId
--				where CONVERT(date,inv.CreatedOn) Between ISNULL(@FromDate,GETDATE()) AND ISNULL(@ToDate,GETDATE())+1
--			    group by  UserName,CounterName,convert(date,inv.CreatedOn)
--				order by [Date]
					
--		End
--End

BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL)) 
    BEGIN
	select [Date], CounterName,UserName, TotalAmount, ReturnAmount as ReturnedAmount, TotalAmount-ReturnAmount as NetAmount, 
	DiscountAmount
	from ( 
          SELECT convert(date,inv.CreateOn) as [Date], phrmCnt.CounterName,usr.UserName,inv.PaidAmount as TotalAmount, 0 as ReturnAmount,inv.DiscountAmount as DiscountAmount
            FROM [PHRM_TXN_Invoice] inv
              INNER JOIN RBAC_User usr
             on inv.CreatedBy=usr.EmployeeId  
			 left Join PHRM_TXN_InvoiceItems as item
			  on inv.InvoiceId= item.InvoiceId
			 INNER JOIN PHRM_MST_Counter phrmCnt
			 on item.CounterId = phrmCnt.CounterId    
              where  convert(datetime, inv.CreateOn)   BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1 
              group by convert(date,inv.CreateOn),UserName, CounterName,inv.PaidAmount,inv.DiscountAmount
			  
			  union all
			 
			  select convert(date,invRet.CreatedOn) as [Date], phrmCnt.CounterName, usr.UserName, 0 as TotalAmount,invRet.TotalAmount as ReturnAmount, (-(invRet.DiscountPercentage/100)*invRet.SubTotal ) as DiscountPercentage
			  From[PHRM_TXN_InvoiceReturnItems] invRet
			  INNER JOIN RBAC_User usr
			  on invRet.CreatedBy = usr.EmployeeId
			  INNER JOIN PHRM_MST_Counter phrmCnt
			 on invRet.CounterId = phrmCnt.CounterId  
			  where convert(datetime, invRet.CreatedOn)   BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
			  group by convert(date,invRet.CreatedOn),UserName, CounterName,invRet.TotalAmount,invRet.DiscountPercentage,invRet.SubTotal
			  )	  tabletotal
			  Group BY [Date], UserName, CounterName,TotalAmount, ReturnAmount, DiscountAmount
      End
End