CREATE PROCEDURE [dbo].[SP_PHRMReport_DateWisePurchaseReport]
    @FromDate datetime = NULL,
    @ToDate datetime = NULL,
	@SupplierId int = NULL
AS
/*
FileName: SP_PHRMReport_DateWisePurchaseReport '2021-05-13', '2021-05-13'
CreatedBy/date: RAMESH/13-05-2021
Description: To get the Details of goods receipt along with Supplier, Item, GenericName and other parameters.

Changes:
SN       User/Date                              Remarks
1.      Rohit/Ramesh:4Sep'21                  Dont show the Cancelled GR Details
                                              Removing Grouping/sums etc since we need item level data.
2.		Rohit/23Feb'22						  Added new parameter as  SupplierId to filter accordingy with supplierId.
*/


	BEGIN

    IF ( @FromDate IS NOT NULL AND @ToDate IS NOT NULL)
	BEGIN
        SELECT (Cast(ROW_NUMBER() OVER (ORDER BY  gr.GoodReceiptDate)  AS int)) AS SN, 
		gr.GoodReceiptDate, 
		gr.InvoiceNo,
		supplier.SupplierName,
		item.ItemName,
		generic.GenericName,
		grI.BatchNo,
		grI.ExpiryDate,
		IsNULL(grI.GRItemPrice,0) AS PurchaseRate,
        ISNULL (grI.ReceivedQuantity, 0) AS Quantity,
		ROUND(IsNULL(grI.GRPerItemVATAmt,0),2) AS VATAmount,
        ISNULL (grI.FreeQuantity, 0) AS FreeQuantity,
		ROUND(((IsNULL(grI.GRItemPrice,0)*  (ISNULL (grI.ReceivedQuantity, 0))) + IsNULL(grI.GRPerItemVATAmt,0)),2) AS TotalAmount, 
		ROUND(((IsNULL(grI.GRItemPrice,0)*  (ISNULL (grI.ReceivedQuantity, 0)))),2) AS SubTotal
        FROM PHRM_GoodsReceiptItems AS grI INNER JOIN
            PHRM_GoodsReceipt AS gr ON grI.GoodReceiptId = gr.GoodReceiptId INNER JOIN
            PHRM_MST_Supplier AS supplier ON supplier.SupplierId  = gr.SupplierId INNER JOIN
            PHRM_MST_Item AS item ON item.ItemId = grI.ItemId INNER JOIN
            PHRM_MST_Generic AS generic ON generic.GenericId = item.GenericId
        WHERE CONVERT(datetime,gr.GoodReceiptDate) BETWEEN ISNULL(@FromDate,GETDATE()) AND ISNULL(@ToDate,GETDATE())+1 
		AND (gr.SupplierId = @SupplierId OR @SupplierId IS NULL)
		AND  ISNULL(gr.IsCancel,0) !=1 --Exclude items from Cancelled GRs

    END
END