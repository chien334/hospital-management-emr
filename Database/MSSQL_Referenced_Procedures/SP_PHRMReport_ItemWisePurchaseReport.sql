CREATE PROCEDURE [dbo].[SP_PHRMReport_ItemWisePurchaseReport]
    @FromDate Date = NULL,
    @ToDate Date = NULL,
    @ItemId int = NULL,
    @InvoiceNo varchar(50) = NULL,
    @GoodsReceiptNo int = NULL,
	@SupplierId INT=NULL
AS
/*
FileName: [SP_PHRMReport_ItemWisePurchaseReport]  --- [SP_PHRMReport_ItemWisePurchaseReport] '2021-01-01','2021-12-01', 3,null,null
CreatedBy/Date: Ramesh/2021-05-11
Description: To get the Details of Supplier, GoodsReceiptDate, GR No, Rate, VAT Amount and TotalAmount of the Selected Item by User.

Changes:
SN       User/Date                              Remarks
1.      Sud/Sanjit/Ramesh:4Sep'21             Using this function for Supplier as well.
                                              Removing Grouping/sums etc since we need item level data.
2.   	Sud/Sanjit:15Jun'22					  Itemwise purchase report now references IsCancel from GR Item Table instead of GR Table.


*/
  BEGIN

    SELECT 
	grItems.ItemId, 
	gen.GenericName, 
	item.ItemName,
	grItems.BatchNo, 
	Convert(Date,grItems.ExpiryDate) ExpiryDate,
	supplier.SupplierName, 
	Convert(Date,gr.GoodReceiptDate) GoodReceiptDate, 
	gr.InvoiceNo, 
	gr.GoodReceiptPrintId AS GoodsReceiptNo, 
	IsNULL(grItems.GRItemPrice,0) AS PurchaseRate, 
	ISNULL(grItems.GrPerItemVATAmt,0) AS VATAmount, 
	ISNULL(grItems.ReceivedQuantity,0) AS ReceivedQuantity, 
		ISNULL(grItems.SubTotal,0) AS SubTotal, 
	ISNULL(grItems.TotalAmount,0) AS TotalAmount

    FROM PHRM_GoodsReceiptItems AS grItems INNER JOIN
        PHRM_GoodsReceipt AS gr ON gr.GoodReceiptId = grItems.GoodReceiptId INNER JOIN
        PHRM_MST_Item AS item ON item.ItemId = grItems.ItemId INNER JOIN
        PHRM_MST_Generic AS gen ON gen.GenericId = item.GenericId INNER JOIN
        PHRM_MST_Supplier AS supplier ON gr.SupplierId = supplier.SupplierId
    WHERE  
	   ISNULL(grItems.IsCancel,0) !=1 --Exclude items from Cancelled GRs
	   AND (grItems.ItemId = @ItemId OR @ItemId IS NULL) 
	   AND CONVERT(Date,gr.GoodReceiptDate) BETWEEN @FromDate AND @ToDate 
       AND (gr.GoodReceiptPrintId = @GoodsReceiptNo OR @GoodsReceiptNo IS NULL)
	   -- this is special case 'null' was coming from frontend.. Pls don't remove that check.. 
	   AND (gr.InvoiceNo = @InvoiceNo OR @InvoiceNo IS NULL OR LOWER (@InvoiceNo) = 'null' ) 
       AND (gr.SupplierId = @SupplierId OR @SupplierId IS NULL)
END