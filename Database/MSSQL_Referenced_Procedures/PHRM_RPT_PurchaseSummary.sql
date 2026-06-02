-- Create the stored procedure in the specified schema
CREATE PROCEDURE [dbo].[PHRM_RPT_PurchaseSummary]
    @FromDate DATETIME  = '2021-01-01',
    @ToDate DATETIME = '2022-01-01',
    @StoreId INT = NULL
AS
-- =============================================
-- Author:		Sanjit
-- Create date: 18/06/2021
-- Description: generated purchase summary report
-- example to execute the stored procedure we just created
-- EXECUTE dbo.PHRM_RPT_PurchaseSummary '2021-07-16','2022-07-15'
-- =============================================
/* Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Sanjit/Sud - 2022-06-15		Source table changed from Stock Transaction to GRItem and RTSItem Table
*/
BEGIN
    -- body of the stored procedure
    SELECT ISNULL(purchase.Purchase,0) 'Purchase', ISNULL(purchaseReturn.PurchaseReturn,0) 'PurchaseReturn', ISNULL(purchase.Purchase,0) - ISNULL(purchaseReturn.PurchaseReturn,0) 'Balance'
    FROM (
		
		SELECT SUM(gri.TotalAmount) as Purchase
		FROM PHRM_GoodsReceiptItems gri
			INNER JOIN PHRM_GoodsReceipt gr ON gri.GoodReceiptId = gr.GoodReceiptId
		WHERE ISNULL(gri.IsCancel, 0) != 1 AND 
		CONVERT(Date, gr.GoodReceiptDate) BETWEEN CONVERT(Date, @FromDate) AND CONVERT(Date, @ToDate)
    ) purchase,
    (
		SELECT SUM(rtsi.TotalAmount) as PurchaseReturn
		FROM PHRM_ReturnToSupplierItems rtsi
			INNER JOIN PHRM_ReturnToSupplier rts ON rtsi.ReturnToSupplierId = rts.ReturnToSupplierId
		WHERE CONVERT(Date, rts.ReturnDate) BETWEEN CONVERT(Date, @FromDate) AND CONVERT(Date, @ToDate)
    ) purchaseReturn
END