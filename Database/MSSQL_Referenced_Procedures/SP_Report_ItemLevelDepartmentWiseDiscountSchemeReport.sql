Create PROCEDURE [dbo].[SP_Report_ItemLevelDepartmentWiseDiscountSchemeReport] -- [SP_Report_ItemLevelDepartmentWiseDiscountSchemeReport] '2021-06-23','2021-09-23'
		@BillingTransactionId int = null,
		@MembershipTypeId int = null,
        @ServiceDepartmentId int = null
AS
/*
FileName: [SP_Report_ItemLevelDepartmentWiseDiscountSchemeReport]
CreatedBy/date: Aniket/2021-10-06
Description: to get the Item Level Scheme Wise Discount Report for the hospital
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Aniket/2021-10-06					Created the Script
*/
BEGIN
			  		Select * from 
(
Select   	
memb.MembershipTypeId as MembershipTypeId, 
memb.MembershipTypeName, 
memb.CommunityName,
PaymentMode,
ItemName,
BillingTransactionId,
serv.ServiceDepartmentName as ServiceDepartmentName,
serv.ServiceDepartmentId as ServiceDepartmentId,
CashTotalAmount 'CashAmount',
CreditTotalAmount 'CreditAmount',
ISNULL(sales.TotalAmount,0) AS 'TotalAmount',
--ISNULL(sales.Subtotal,0) AS SalesSubtotal, 
ISNULL(sales.DiscountAmount,0) AS 'TotalDiscount', 
ISNULL(sales.TotalAmount,0) - ISNULL(NetRefundAmount,0) 'NetAmount',
sales.TotalQuantity,
DiscountRefund,
NetRefundAmount
from 
PAT_CFG_MembershipType  memb
Left Join 
(
Select itm.DiscountSchemeId,
itm.ServiceDepartmentId,
itm.ItemName,
SUM(itm.SubTotal) 'Subtotal',
SUM(ISNULL(itm.DiscountAmount,0)) 'DiscountAmount',
SUM(itm.TotalAmount) 'TotalAmount',
SUM(itm.Quantity) 'TotalQuantity',
txn.PaymentMode as 'PaymentMode',
txn.BillingTransactionId as 'BillingTransactionId',
ISNULL(retItm.RetTotalAmount,0) AS 'NetRefundAmount',
ISNULL(retItm.RetDiscountAmount,0) AS 'DiscountRefund',
SUM( (Case WHen txn.PaymentMode ='cash' then itm.TotalAmount
ELSE 0 END )) AS CashTotalAmount,
SUM( (Case WHen txn.PaymentMode ='credit' then itm.TotalAmount
ELSE 0 END )) AS CreditTotalAmount

from BIL_TXN_BillingTransaction txn
    Left join BIL_TXN_BillingTransactionItems itm on txn.BillingTransactionId = itm.BillingTransactionId
	Left join BIL_TXN_InvoiceReturnItems retItm 
on itm.BillingTransactionItemId = retItm.BillingTransactionItemId
Group by itm.DiscountSchemeId,itm.ServiceDepartmentId,itm.ItemName,PaymentMode, txn.BillingTransactionId,retItm.RetTotalAmount,retItm.RetDiscountAmount
) sales
ON memb.MembershipTypeId= sales.DiscountSchemeId 
  
join BIL_MST_ServiceDepartment serv on sales.ServiceDepartmentId= serv.ServiceDepartmentId

)tbl

Where ( 
        --ISNULL(SalesSubtotal,0) !=0
        ISNULL(CashAmount,0) !=0
    OR  ISNULL(CreditAmount,0) !=0
    OR  ISNULL(TotalAmount,0) !=0
    OR  ISNULL(TotalDiscount,0) !=0
    OR  ISNULL(NetRefundAmount,0) !=0  
    OR  ISNULL(DiscountRefund,0) !=0
    )
	AND ((MembershipTypeId = @MembershipTypeId Or @MembershipTypeId is null) AND (ServiceDepartmentId = @ServiceDepartmentId Or @ServiceDepartmentId is null) AND (BillingTransactionId = @BillingTransactionId Or @BillingTransactionId is null))
END