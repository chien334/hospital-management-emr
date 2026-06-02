CREATE PROCEDURE [dbo].[SP_PHRM_CashCollectionSummaryReport]  --- [SP_PHRM_CashCollectionSummaryReport] '03/23/2020','05/23/2021'
@FromDate datetime=null,
 @ToDate datetime=null, 
  @StoreId int = null
 AS
 /*
FileName: [[SP_PHRM_CashCollectionSummaryReport]]
CreatedBy/date: Dinesh 2nd Sept 2019 
Description: .
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Dinesh 2nd Sept 2019                created the script
2		Ashish 14th Jan 2020				fix bug Provisional credit invoice amount showing  --if transaction is Provisional and paymenttype is credit then entry into settlement tbl  	
3       Shankar 17th March 2020	            deducted from deposit amount was showing in user collection which is fixed here on.
4       Ramesh/Sanjit 5th May 2021          Added StoreId as a parameter for selected Store Details
5		Ramesh/Sanjit 7th Sep, 2021			Invoice Return Payment Mode filter added.
*/
 BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL)) 
    BEGIN
	select tabletotal.[Date], tabletotal.UserName, sum(tabletotal.TotalAmount) as TotalAmount, sum(tabletotal.ReturnAmount) as ReturnedAmount, sum((tabletotal.TotalAmount+tabletotal.DepositAmount)-(tabletotal.ReturnAmount+tabletotal.DepositReturn)) as NetAmount, sum(tabletotal.DiscountAmount) as DiscountAmount, sum(tabletotal.DepositAmount) as DepositAmount, sum(tabletotal.DepositReturn) as DepositReturn, ISNULL(S.Name,'') as StoreName
	from ( 
          SELECT convert(date,inv.CreateOn) as [Date] ,usr.UserName,sum(inv.PaidAmount)as TotalAmount, 0 as ReturnAmount,sum(inv.DiscountAmount) as DiscountAmount,  0 as DepositAmount, 0 as DepositReturn, inv.StoreId as StoreId
            FROM [PHRM_TXN_Invoice] inv
              INNER JOIN RBAC_User usr
             on inv.CreatedBy=usr.EmployeeId      
              where  (convert(datetime, inv.CreateOn)   BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1 ) and inv.BilStatus='paid' and inv.SettlementId is null and inv.DepositDeductAmount=0 and (inv.StoreId = @StoreId OR @StoreId is NULL)
              group by convert(date,inv.createon),UserName, StoreId
			  
			 
			  union all 
			    SELECT convert(date,stl.CreatedOn) as [Date] ,usr.UserName,sum(stl.PayableAmount)as TotalAmount, 0 as ReturnAmount,sum(stl.DiscountAmount) as DiscountAmount,  0 as DepositAmount, 0 as DepositReturn, NULL as StoreId
            FROM [PHRM_TXN_Settlement] stl
              INNER JOIN RBAC_User usr
             on stl.CreatedBy=usr.EmployeeId
              where  (convert(datetime, stl.CreatedOn)   BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1 ) and (@StoreId is NULL)
              group by convert(date,stl.CreatedOn),UserName
			  
			  union all
			  select convert(date,invRet.CreatedOn) as [Date], usr.UserName, 0 as TotalAmount,sum(invRet.TotalAmount ) as ReturnAmount,  sum(DiscountAmount) as DiscountAmount, 0 as DepositAmount, 0 as DepositReturn,invRet.StoreId as StoreId
			  From[PHRM_TXN_InvoiceReturn] invRet
			  INNER JOIN RBAC_User usr
			  on invRet.CreatedBy = usr.EmployeeId
			  where convert(datetime, invRet.CreatedOn)   BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1 
					and invRet.PaymentMode != 'credit'
					and invRet.InvoiceId is not null and (invRet.StoreId = @StoreId OR @StoreId is NULL)
			  group by convert(date,invRet.CreatedOn),UserName, StoreId

			  union all
			  select convert(date,depo.CreatedOn) as [Date], usr.UserName, 0 as TotalAmount, 0 as ReturnAmount, 0 as DiscountAmount, sum(depo.DepositAmount) as DepositAmount, 0 as DepositReturn,depo.StoreId as StoreId
			  From PHRM_Deposit as depo
			  INNER JOIN RBAC_User as usr
			  on depo.CreatedBy = usr.EmployeeId
			  where convert(datetime, depo.CreatedOn)   BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1 and depo.DepositType = 'deposit' and (depo.StoreId = @StoreId OR @StoreId is NULL)
			  group by convert(date, depo.CreatedOn), UserName, StoreId

			  union all
			  select convert(date,depo.CreatedOn) as [Date], usr.UserName, 0 as TotalAmount, 0 as ReturnAmount, 0 as DiscountAmount, 0 as DepositAmount, sum(depo.DepositAmount) as DepositReturn,depo.StoreId as StoreId
			  From PHRM_Deposit as depo
			  INNER JOIN RBAC_User as usr
			  on depo.CreatedBy = usr.EmployeeId
			  where convert(datetime, depo.CreatedOn)   BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1 and depo.DepositType ='depositreturn' and (depo.StoreId = @StoreId OR @StoreId IS NULL)
			  group by convert(date, depo.CreatedOn), UserName, StoreId


			  )	  tabletotal
			  left join PHRM_MST_Store S ON tabletotal.StoreId = S.StoreId
			  Group BY [Date], UserName, S.Name
      End
End