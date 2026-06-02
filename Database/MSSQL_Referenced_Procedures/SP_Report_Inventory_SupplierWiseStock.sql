/*
FileName: [SP_Report_Inventory_SupplierWiseStock] 
CreatedBy/date: Aniket/02-10-2021
Description: To get the Details of Supplier Wise Stock Report
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Aniket/02-10-2021                    created the script
2.	  Aniket/20-10-2021                    updated Opening and Closing stock
3.	  Sanjit/28-10-2021					   revised the changes (correction of opening and closing quantity logic)
4.    Rohit/15-11-2021					   Changed the parameter sequence (Item wise and Store wise filter was not working.)
*/
CREATE PROCEDURE [dbo].[SP_Report_Inventory_SupplierWiseStock] 
	@FromDate DATETIME,
	@ToDate DATETIME,
	@VendorId INT = NULL,
	@StoreId INT = NULL,
	@ItemId INT = NULL
AS
BEGIN
	-- to check if the hospital uses dispatch or consumption method to finish the stock
	DECLARE @ConsumptionOrDispatch VARCHAR(1000) = (SELECT ParameterValue FROM CORE_CFG_Parameters WHERE ParameterName = 'ConsumptionOrDispatchForReports' and ParameterGroupName = 'Inventory') 

	SELECT 
		ISNULL(gr.OpeningQty,0) as OpeningStock, 
		V.VendorName as VendorName,
		C.ItemCategoryName as Category,
		SC.SubCategoryName as SubCategory,
		I.Code as ItemCode,
		I.ItemName as ItemName,
		str.Name as StoreName,
		ISNULL(gr.PurchaseQty,0) as PurchaseQty,
		gr.BatchNO as BatchNo,
		gr.ExpiryDate as ExpiryDate,
		ISNULL(gr.ConsumedQty,0) as ConsumedQty,
		CASE WHEN gr.WriteOffQty > 0 THEN CONVERT(varchar(800), -gr.WriteOffQty) + ' (write-off) ' Else '' END +
		CASE WHEN gr.PurchaseReturnQty > 0 THEN CONVERT(varchar(800), -gr.PurchaseReturnQty) + ' (purchase-return) ' Else '' END +
		CASE WHEN gr.StkManageQty > 0 THEN CONVERT(varchar(800), gr.StkManageQty) + ' (stock-manage)' Else '' END
		as OtherQtyTxn,
		ISNULL(gr.OpeningQty,0) + ISNULL(gr.PurchaseQty,0) - ISNULL(gr.ConsumedQty,0) - ISNULL(gr.WriteOffQty,0) - ISNULL(gr.PurchaseReturnQty,0) + ISNULL(gr.StkManageQty,0) ClosingStock
	FROM 
		INV_MST_Item I
		CROSS JOIN INV_MST_Vendor V
		CROSS JOIN PHRM_MST_Store str
		INNER JOIN INV_MST_ItemCategory C ON I.ItemCategoryId = C.ItemCategoryId
		INNER JOIN INV_MST_ItemSubCategory SC ON I.SubCategoryId = SC.SubCategoryId
		INNER JOIN 
		(
			SELECT 
				X.StoreId, X.ItemId, X.BatchNo, X.ExpiryDate, X.VendorId, SUM(X.OpeningQty) as OpeningQty, SUM(X.PurchaseQty) as PurchaseQty, SUM(X.ConsumedQty) as ConsumedQty, SUM(X.WriteOffQty) as WriteOffQty, SUM(X.PurchaseReturnQty) as PurchaseReturnQty, SUM(StkManageQty) as StkManageQty
			FROM
			(
				--to calculate the opening quantity, we take the goods receipts upto the from date provided
				SELECT GR.StoreId, GRI.ItemId, S.BatchNo, S.ExpiryDate, GR.VendorId, SUM(ISNULL(ST.InQty,0)) - SUM(ISNULL(ST.OutQty,0)) as OpeningQty, 0 as PurchaseQty, 0 as ConsumedQty, 0 as WriteOffQty, 0 as PurchaseReturnQty, 0 as StkManageQty
				FROM
					INV_TXN_GoodsReceiptItems GRI 
					INNER JOIN INV_TXN_GoodsReceipt GR ON GRI.GoodsReceiptId = GR.GoodsReceiptId
					INNER JOIN INV_MST_Stock S ON GRI.StockId = S.StockId
					INNER JOIN INV_TXN_StockTransaction ST ON S.StockId = ST.StockId
				WHERE CONVERT(date, ST.TransactionDate) <= @FromDate AND
				--used StockTxn Date instead of GRDate since calculation of Opening depends on StkTxn Date. Taking GR Date may bring unwanted data in the output				
					(GR.VendorId = @VendorId OR @VendorId IS NULL) AND
					(GRI.ItemId = @ItemId OR @ItemId IS NULL) AND
					(GR.StoreId = @StoreId OR @StoreId IS NULL)
				GROUP BY GR.StoreId, GRI.ItemId, S.BatchNo, S.ExpiryDate, GR.VendorId

				UNION ALL

				--to calculate the purchased, consumed and closing quantity, we take the goods receipts from the provided date range
				SELECT	
					GR.StoreId, GRI.ItemId, S.BatchNo, S.ExpiryDate, GR.VendorId, 
					0 as OpeningQty, 
					SUM( 
						CASE 
							WHEN ST.TransactionType IN ('gr-item','goodreceipt-items') THEN ST.InQty 
							WHEN ST.TransactionType = 'cancel-gr-items' THEN -ST.OutQty 
							ELSE 0 
						END
					   ) as PurchaseQty, 
					SUM( 
							CASE
								WHEN @ConsumptionOrDispatch = 'consumption' AND ST.TransactionType = 'consumption-items' THEN ST.OutQty
								WHEN @ConsumptionOrDispatch != 'consumption' AND ST.TransactionType IN ('dispatched-item-from','dispatched-item') THEN ST.OutQty
								ELSE 0
							END
						) as ConsumedQty,			   
					SUM(
							CASE
								WHEN ST.TransactionType = 'writeoff-items' THEN ST.OutQty
								ELSE 0
							END
					   ) as WriteOffQty,
					SUM(
							CASE
								WHEN ST.TransactionType = 'returntovendor-items' THEN ST.OutQty
								ELSE 0
							END
					   ) as PurchaseReturnQty,
					SUM(
							CASE
								WHEN ST.TransactionType IN ('stock-managed-item','fy-managed-item') AND ST.InQty > 0 THEN ST.InQty
								WHEN ST.TransactionType IN ('stock-managed-item','fy-managed-item') AND ST.OutQty > 0 THEN -ST.OutQty
								ELSE 0
							END
					   ) as StkManageQty

				FROM
					INV_TXN_GoodsReceiptItems GRI 
					INNER JOIN INV_TXN_GoodsReceipt GR ON GRI.GoodsReceiptId = GR.GoodsReceiptId
					INNER JOIN INV_MST_Stock S ON GRI.StockId = S.StockId
					INNER JOIN INV_TXN_StockTransaction ST ON S.StockId = ST.StockId
				WHERE CONVERT(date, ST.TransactionDate) BETWEEN @FromDate AND @ToDate AND
				--used StockTxn Date instead of GRDate since calculation of Opening depends on StkTxn Date. Taking GR Date may bring unwanted data in the output			
					(GR.VendorId = @VendorId OR @VendorId IS NULL) AND
					(GRI.ItemId = @ItemId OR @ItemId IS NULL) AND
					(GR.StoreId = @StoreId OR @StoreId IS NULL)
				GROUP BY GR.StoreId, GRI.ItemId, S.BatchNo, S.ExpiryDate, GR.VendorId
			) X
			-- If a same item with same batch and expiry date was supplied from same vendor, then report will show them as a single row, hence the group by is used as below
			GROUP BY X.StoreId, X.ItemId, X.BatchNo, X.ExpiryDate, X.VendorId
		)
		gr ON I.ItemId = gr.ItemId AND V.VendorId = gr.VendorId AND str.StoreId = gr.StoreId
	WHERE (ISNULL(gr.OpeningQty,0) != 0 OR ISNULL(gr.PurchaseQty,0) != 0 OR ISNULL(gr.ConsumedQty,0) != 0)
	ORDER BY ISNULL(gr.PurchaseQty,0) DESC
END