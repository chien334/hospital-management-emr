CREATE PROCEDURE SP_Report_BILL_Invoice_Return_Detail @BillReturnId int null
AS

/*
FileName: [SP_Report_BILL_Invoice_Return_Detail]
CreatedBy/date: Krishna/27-10-2021
Description: This SP will give details of Returned items on the return bill report grid after view details is clicked and BillReturnId is passed to this SP.
Remarks:   
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Krishna/27-10-2021                created the script

*/

BEGIN

	SELECT 
		rtItm.ItemName, 
		txnItm.Quantity,
		rtItm.RetQuantity,
		rtItm.RetSubTotal,
		rtItm.RetDiscountAmount,
		rtItm.RetTotalAmount
		FROM BIL_TXN_InvoiceReturnItems rtItm 
		JOIN BIL_TXN_BillingTransactionItems txnItm ON rtItm.BillingTransactionItemId = txnItm.BillingTransactionItemId 
		WHERE rtItm.BillReturnId = @BillReturnId;
	END