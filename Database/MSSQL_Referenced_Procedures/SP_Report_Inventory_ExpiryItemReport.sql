Create PROCEDURE  [dbo].[SP_Report_Inventory_ExpiryItemReport]
	@ItemId int = NULL,
	@StoreId int = NULL,
	@FromDate Date = NULL,
	@ToDate Date = NULL
AS

/*
FileName: [SP_Report_Inventory_ExpiryItemReport] 
Created: 08Oct'21/Swapnil
Description: To get report data with ItemId,StoreId,FromDate,ToDate.
Change History
S.No.    Date/User              Change          Remarks
1.	     06Oct'21/Swapnil		                  inital draft
*/

BEGIN
	SELECT (Cast(ROW_NUMBER() OVER (ORDER BY  x.ItemName)  AS int)) AS SN, x.*
	FROM
		(
			SELECT t1.ItemId, t1.BatchNo, t1.ExpiryDate, t1.MRP, t1.CostPrice, item.ItemName, SUM(t2.AvailableQuantity) AS AvailableQuantity, store.Name, ISNULL(Vendor.VendorName, '') AS VendorName
			FROM INV_MST_Stock AS t1 INNER JOIN
			INV_TXN_StoreStock AS t2 ON t1.StockId = t2.StockId LEFT JOIN
			INV_TXN_GoodsReceiptItems AS GRI ON t2.StoreStockId = GRI.StockId LEFT JOIN
			INV_TXN_GoodsReceipt AS GR ON GRI.GoodsReceiptId = GR.GoodsReceiptID LEFT JOIN
			INV_MST_Vendor Vendor ON GR.VendorId = Vendor.VendorId INNER JOIN
			INV_MST_Item AS item ON item.ItemId = t1.ItemId INNER JOIN
			PHRM_MST_Store AS store ON store.StoreId = t2.StoreId
			WHERE  (t1.ItemId = @ItemId OR @ItemId IS NULL) AND (t2.StoreId = @StoreId OR @StoreId IS NULL)
			AND CONVERT(Date,t1.ExpiryDate) BETWEEN @FromDate AND @ToDate AND (t2.AvailableQuantity > 0)
		GROUP BY t1.ItemId, t1.BatchNo, t1.ExpiryDate, t1.MRP,t1.CostPrice, item.ItemName, store.Name, Vendor.VendorName
		)
	AS x
END