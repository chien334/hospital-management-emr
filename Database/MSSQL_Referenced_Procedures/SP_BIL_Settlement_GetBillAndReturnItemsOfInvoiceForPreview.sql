CREATE PROCEDURE [dbo].[SP_BIL_Settlement_GetBillAndReturnItemsOfInvoiceForPreview] 
		@BillingTransactionId INT = 0
		
AS
/*
FileName: [SP_BIL_Settlement_GetBillAndReturnItemsOfInvoiceForPreview]
CreatedBy/date: Sud/2021-11-18
Description: Gets InvoiceInfo, CreditNote Info, InvoiceItems and CreditNoteItems for Preview in settlement page. 
Notes      : We're returning 4 tables with individual informations, these will be filtered in Client side as required.
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Sud/2021-11-18   					  Initial Draft
2.		Krishna/21stApril'23				  Change ItemId to IntegrationItemId
*/
BEGIN

	select txn.InvoiceNo,txn.InvoiceCode, CONVERT(Date,txn.CreatedOn) 'InvoiceDate',
		 txn.SubTotal, txn.DiscountAmount, txn.TotalAmount
		from BIL_TXN_BillingTransaction txn
	where txn.BillingTransactionId = @BillingTransactionId

	select txnItm.ItemId, txnItm.ItemName, txnItm.Quantity, txnItm.Price,
	   txnItm.SubTotal,txnItm.DiscountAmount,txnItm.TotalAmount
		from BIL_TXN_BillingTransactionItems txnItm 
	where txnItm.BillingTransactionId = @BillingTransactionId

	select BillReturnId, CreditNoteNumber, CONVERT(date,CreatedOn) 'ReturnDate' 
	from  BIL_TXN_InvoiceReturn 
	where BillingTransactionId = @BillingTransactionId

	select BillReturnId, IntegrationItemId, ItemName, RetQuantity, Price, RetSubTotal, RetDiscountAmount, RetTotalAmount
	from BIL_TXN_InvoiceReturnItems 
	where BillingTransactionId = @BillingTransactionId
END