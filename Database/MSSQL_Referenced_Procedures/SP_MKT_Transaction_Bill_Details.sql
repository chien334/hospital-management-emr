CREATE PROCEDURE [dbo].[SP_MKT_Transaction_Bill_Details] 
@BillingTransactionId INT
AS
/* 
exec [SP_MKT_Transaction_Bill_Details] '2208'
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Bibek/2023-08-08                   Created initial script 
*/

BEGIN
    SELECT 
        itms.BillingTransactionId,
        itms.ItemName,
        itms.Quantity,
        ISNULL(retItms.RetQty, 0) AS 'RetQuantity',
        itms.Quantity - ISNULL(retItms.RetQty, 0) AS 'NetQuantity',
        itms.TotalAmount,
        ISNULL(retItms.RetTotalAmount, 0) AS 'RetTotalAmount',
        itms.TotalAmount - ISNULL(retItms.RetTotalAmount, 0) AS 'NetTotalAmount'
    FROM (
        SELECT * 
        FROM BIL_TXN_BillingTransactionItems
        WHERE BillingTransactionId = @BillingTransactionId
    ) itms
    LEFT JOIN (
        SELECT 
            BillingTransactionItemId,
            SUM(ISNULL(RetTotalAmount, 0)) AS 'RetTotalAmount', 
            SUM(ISNULL(RetQuantity, 0)) AS 'RetQty'
        FROM BIL_TXN_InvoiceReturnItems 
        GROUP BY BillingTransactionItemId
    ) retItms ON itms.BillingTransactionItemId = retItms.BillingTransactionItemId
END