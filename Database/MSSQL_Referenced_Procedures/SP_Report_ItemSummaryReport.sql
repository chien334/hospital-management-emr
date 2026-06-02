/*
File: SP_Report_ItemSummaryReport
Author:     20April'20/Pratik 
Description:  To get Items item summary report

Change History
S.No.   Date/Author           Remarks
1.     20April'20/Pratik   Initial Draft
2. Sud:23Apr'20            Correction in TotalQty and ReturnStatus
3. Krishna:19thOct'22	   SP revised handling Return conditions 
*/

CREATE PROCEDURE [dbo].[SP_Report_ItemSummaryReport]  --EXEC SP_Report_ItemSummaryReport '2020-03-01','2020-03-17'
  @FromDate date = NULL,
  @ToDate date = NULL
AS
BEGIN
	select 
tbl1.ServiceDepartmentName,
tbl1.ItemName,
SUM(ISNULL(tbl1.SubTotal,0)) -  SUM(ISNULL(tbl2.RetSubTotal,0))'SubTotal',
SUM(ISNULL(tbl1.TotalQuantity,0)) - SUM(ISNULL(tbl2.RetQuantity,0)) 'TotalQty',
SUM(ISNULL(tbl1.TotalAmount,0)) - SUM(ISNULL(tbl2.RetTotalAmount,0)) 'TotalAmount',
SUM(ISNULL(tbl1.DiscountAmount,0)) - SUM(ISNULL(tbl2.RetDiscountAmount,0)) 'DiscountAmount'
from(
select 
itms.ServiceDepartmentName,
itms.ItemName,
SUM(ISNULL(itms.SubTotal,0))'Subtotal',
SUM(ISNULL(itms.Quantity,0)) 'TotalQuantity',
SUM(ISNULL(itms.TotalAmount,0)) 'TotalAmount',
SUM(ISNULL(itms.DiscountAmount,0)) 'DiscountAmount'
from BIL_TXN_BillingTransactionItems itms
join BIL_TXN_BillingTransaction txn
on itms.BillingTransactionId = txn.BillingTransactionId
where 
Convert(Date,txn.CreatedOn) Between @FromDate AND @ToDate
AND (itms.BillStatus='paid' or itms.BillStatus='unpaid')
group by itms.ServiceDepartmentName, itms.ItemName
) tbl1
left join(
select ItemName, SUM(ISNULL(RetSubTotal,0))'RetSubTotal',
		    SUM(ISNULL(RetTotalAmount,0))'RetTotalAmount', SUM(ISNULL(RetQuantity,0))'RetQuantity', SUM(ISNULL(RetDiscountAmount,0)) 'RetDiscountAmount'	from BIL_TXN_InvoiceReturnItems 
			where Convert(Date,CreatedOn) Between @FromDate AND @ToDate
			GROUP BY ItemName
			) tbl2
			on tbl1.ItemName = tbl2.ItemName
group by tbl1.ServiceDepartmentName,tbl1.ItemName
order by tbl1.ServiceDepartmentName,tbl1.ItemName

END