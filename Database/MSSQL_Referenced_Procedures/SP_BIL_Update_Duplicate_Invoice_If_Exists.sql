-- =============================================
-- Author:		<Anish Bhattarai>
-- Create date: <15 July, 2021>
-- Description:	<Temporary Solution to handle Issue of same Invoice Number by Checking for Duplication and Updating after Transaction is Committed>
-- =============================================
CREATE PROCEDURE [dbo].[SP_BIL_Update_Duplicate_Invoice_If_Exists]
	@fiscalYearId INT,
	@billingTransactionId INT,
	@invoiceNumber INT
AS
BEGIN
 EXEC('DISABLE TRIGGER TRG_BillingTransaction_RestrictBillAlter ON BIL_TXN_BillingTransaction');  
   
--If  Exists then this means Duplication has occurred
	IF(EXISTS(SELECT * FROM BIL_TXN_BillingTransaction WHERE (BillingTransactionId != @billingTransactionId) AND (InvoiceNo = @invoiceNumber) AND (FiscalYearId = @fiscalYearId))) 
		BEGIN
			DECLARE @latestInvoiceNumber INT
			--Get the latest Invoice Number of that Fiscal Year and Update in the Invoice Number of that Bill_Transaction and Deposit Remarks
			SET @latestInvoiceNumber = (SELECT MAX(InvoiceNo)+1 FROM BIL_TXN_BillingTransaction WHERE FiscalYearId=@fiscalYearId)
			UPDATE BIL_TXN_BillingTransaction SET InvoiceNo=@latestInvoiceNumber WHERE BillingTransactionId = @billingTransactionId
			UPDATE BIL_TXN_Deposit SET Remarks=REPLACE(Remarks,@invoiceNumber,@latestInvoiceNumber) WHERE BillingTransactionId = @billingTransactionId
			SELECT @latestInvoiceNumber as LatestInvoiceNumber
		END
	ELSE
		BEGIN 
			SELECT @invoiceNumber as LatestInvoiceNumber
		END

EXEC('ENABLE TRIGGER TRG_BillingTransaction_RestrictBillAlter ON BIL_TXN_BillingTransaction');
END