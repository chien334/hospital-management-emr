CREATE PROCEDURE [dbo].[SP_PHRMReport_SupplierStockReport]
    @fromDate Date = NULL,
    @toDate Date = NULL,
    @SupplierId int = NULL
AS
/*
FileName: SP_PHRMReport_SupplierStockReport
CreatedBy/date: Rusha/04-07-2019
Description: To get the Details of goods receipt from Supplier such as received qty, rate per qty, and so on
Example: exec SP_PHRMReport_SupplierStockReport '2021-01-01', '2021-12-01',78
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Rusha/04-07-2019	                 To get details of goods receipts from Supplier 
2		 Sanjit/27-05-2020					 added fromDate and toDate in the sp for date filter (EMR-1618)
3        Ramesh/12-05-2021                   SupplierName is replaced by SupplierId and other details like VAT Amt, BatchNo etc were Added
4.		Sanjit/1-09-2021					Conerted @FromDate and @ToDate into Date Type instead of DateTime
5.      Rohit/23Feb'22						Do not show the Cancelled GR Details
*/

	BEGIN

    IF ( @FromDate IS NOT NULL AND @ToDate IS NOT NULL AND @SupplierId IS NOT NULL )
	BEGIN
        SELECT  gr.GoodReceiptDate, supplier.SupplierName, grI.ItemName, grI.BatchNo, grI.ExpiryDate, IsNULL(grI.GRItemPrice,0) AS PurchaseRate,
		    SUM (ISNULL (grI.ReceivedQuantity, 0)) AS ReceivedQuantity, IsNULL(grI.GRPerItemVATAmt,0) AS VATAmount,
            SUM (ISNULL (grI.FreeQuantity, 0)) AS FreeQuantity, ((IsNULL(grI.GRItemPrice,0)* SUM (ISNULL (grI.ReceivedQuantity, 0))) + IsNULL(grI.GRPerItemVATAmt,0)) AS TotalAmount, ((IsNULL(grI.GRItemPrice,0)* SUM (ISNULL (grI.ReceivedQuantity, 0)))) AS SubTotal
        FROM PHRM_GoodsReceiptItems AS grI INNER JOIN
            PHRM_GoodsReceipt AS gr ON grI.GoodReceiptId = gr.GoodReceiptId INNER JOIN
            PHRM_MST_Supplier AS supplier ON supplier.SupplierId  = gr.SupplierId
        WHERE CONVERT(Date, gr.GoodReceiptDate) BETWEEN @fromDate AND @toDate AND gr.SupplierId = @SupplierId AND  ISNULL(gr.IsCancel,0) !=1 --Exclude items from Cancelled GRs

        GROUP BY grI.GoodReceiptId, grI.ItemId, grI.ExpiryDate, grI.BatchNo, grI.GRItemPrice, grI.ItemName, grI.GrPerItemVATAmt, gr.GoodReceiptDate, supplier.SupplierName
    END
  END