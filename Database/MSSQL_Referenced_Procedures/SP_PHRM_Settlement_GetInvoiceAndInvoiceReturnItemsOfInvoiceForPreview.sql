CREATE PROCEDURE [dbo].[SP_PHRM_Settlement_GetInvoiceAndInvoiceReturnItemsOfInvoiceForPreview] @invoiceId INT = 0
AS
/*
FileName: SP_PHRM_Settlement_GetInvoiceAndInvoiceReturnItemsOfInvoiceForPreview 2397
Description: To get all invoice and return invoice items details  of patient for Settlement preview
Remarks: We're returning 4 tables from this StoredProc.
1. INVOICE information
2. Invoice Items Information
3. CreditNote Information
4. CreditNote Items Information

Change History
S.No. 	UpdatedBy/Date 				Remarks
1. 		Rohit/1,DEC'21 				Created SP to get the settlement details for settlement receipt.
2.      Rohit/13Feb'23						MRP-> SalePrice
*/
BEGIN
	SELECT inv.InvoicePrintId 'InvoiceNo'
		,CONVERT(DATE, inv.CreateOn) 'InvoiceDate'
		,inv.SubTotal
		,inv.DiscountAmount
		,inv.TotalAmount
	FROM PHRM_TXN_Invoice inv
	WHERE inv.InvoiceId = @invoiceId

	SELECT txnItm.ItemId
		,txnItm.ItemName
		,txnItm.Quantity
		,txnItm.SalePrice
		,txnItm.SubTotal
		,txnItm.TotalDisAmt 'DiscountAmount'
		,txnItm.TotalAmount
	FROM PHRM_TXN_InvoiceItems txnItm
	WHERE txnItm.InvoiceId = @invoiceId

	SELECT InvoiceReturnId
		,CreditNoteID
		,CONVERT(DATE, CreatedOn) 'ReturnDate'
	FROM PHRM_TXN_InvoiceReturn
	WHERE InvoiceId = @invoiceId

	SELECT retItm.InvoiceReturnId
		,mstItm.ItemName
		,retItm.ReturnedQty
		,retItm.SalePrice
		,retItm.SubTotal
		,retItm.DiscountAmount
		,retItm.TotalAmount
	FROM PHRM_TXN_InvoiceReturnItems retItm
	INNER JOIN PHRM_MST_Item mstItm ON retItm.ItemId = mstItm.ItemId
	WHERE retItm.InvoiceId = @invoiceId
END