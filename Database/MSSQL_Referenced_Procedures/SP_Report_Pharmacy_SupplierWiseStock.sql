CREATE PROCEDURE [dbo].[SP_Report_Pharmacy_SupplierWiseStock] 
    @FromDate DATETIME,
    @ToDate DATETIME,
    @ItemId INT = NULL,
    @StoreId INT = NULL,
    @SupplierId INT = NULL
AS
BEGIN
 SELECT
        ISNULL(gr.OpeningQty,0) as OpeningStock, 
        S.SupplierName as SupplierName,
        --C.CategoryName as Category,
        I.ItemCode as ItemCode,
		G.GenericName as GenericName,
        I.ItemName as ItemName,
        str.Name as StoreName,
        ISNULL(gr.PurchaseQty,0) as PurchaseQty,
        gr.BatchNO as BatchNo,
        gr.ExpiryDate as ExpiryDate,
        ISNULL(gr.SalesQty,0) as SalesQty,
        ISNULL(gr.SalesRetQty,0) as SalesRetQty,
        CASE WHEN gr.WriteOffQty > 0 THEN CONVERT(varchar(800), -gr.WriteOffQty) + ' (write-off) ' Else '' END +
        CASE WHEN gr.PurchaseReturnQty > 0 THEN CONVERT(varchar(800), -gr.PurchaseReturnQty) + ' (purchase-return) ' Else '' END +
        CASE WHEN gr.StkManageQty > 0 THEN CONVERT(varchar(800), gr.StkManageQty) + ' (stock-manage)' Else '' END
        as OtherQtyTxn,
        ISNULL(gr.OpeningQty,0) + ISNULL(gr.PurchaseQty,0) - ISNULL(gr.SalesQty,0) + ISNULL(gr.SalesRetQty,0) - ISNULL(gr.WriteOffQty,0) - ISNULL(gr.PurchaseReturnQty,0) + ISNULL(gr.StkManageQty,0) ClosingStock
    FROM
        PHRM_MST_Item I
        CROSS JOIN PHRM_MST_Supplier S
        CROSS JOIN PHRM_MST_Store str
        JOIN PHRM_MST_Generic G ON I.GenericId = G.GenericId
        INNER JOIN
         (
            SELECT
                X.StoreId, X.ItemId, X.BatchNo, X.ExpiryDate, X.SupplierId, SUM(X.OpeningQty) as OpeningQty, SUM(X.PurchaseQty) as PurchaseQty, SUM(X.SalesQty) as SalesQty,SUM(X.SalesRetQty) as SalesRetQty, SUM(X.WriteOffQty) as WriteOffQty, SUM(X.PurchaseReturnQty) as PurchaseReturnQty, SUM(StkManageQty) as StkManageQty
            FROM
            (
                --to calculate the opening quantity, we take the goods receipts upto the from date provided
                SELECT GR.StoreId, GRI.ItemId, S.BatchNo, S.ExpiryDate, GR.SupplierId, SUM(ISNULL(ST.InQty,0)) - SUM(ISNULL(ST.OutQty,0)) as OpeningQty, 0 as PurchaseQty, 0 as SalesQty, 0 as SalesRetQty,0 as WriteOffQty, 0 as PurchaseReturnQty, 0 as StkManageQty
                FROM
                    PHRM_GoodsReceiptItems GRI 
                    INNER JOIN PHRM_GoodsReceipt GR ON GRI.GoodReceiptItemId = GR.GoodReceiptId
                    INNER JOIN PHRM_MST_Stock S ON GRI.StockId = S.StockId
                    INNER JOIN PHRM_TXN_StockTransaction ST ON S.StockId = ST.StockId
                WHERE CONVERT(date, ST.TransactionDate) <= @FromDate AND
                --used StockTxn Date instead of GRDate since calculation of Opening depends on StkTxn Date. Taking GR Date may bring unwanted data in the output                
                    (GR.SupplierId = @SupplierId OR @SupplierId IS NULL) AND
                    (GRI.ItemId = @ItemId OR @ItemId IS NULL) AND
                    (GR.StoreId = @StoreId OR @StoreId IS NULL) AND
					ISNULL(GRI.IsCancel,0) != 1 --Exclude items from Cancelled GRs
                GROUP BY GR.StoreId, GRI.ItemId, S.BatchNo, S.ExpiryDate, GR.SupplierId
                UNION ALL
                --to calculate the purchased, consumed and closing quantity, we take the goods receipts from the provided date range
                SELECT
                    GR.StoreId, GRI.ItemId, S.BatchNo, S.ExpiryDate, GR.SupplierId, 
                    0 as OpeningQty, 
                    SUM( 
                        CASE 
                            WHEN ST.TransactionType IN ('gr-item') THEN ST.InQty 
                            WHEN ST.TransactionType = 'cancel-gr-items' THEN -ST.OutQty 
                            ELSE 0
                        END
                       ) as PurchaseQty, 
                    SUM( 
                            CASE
                                WHEN ST.TransactionType IN ('sale-item','provisional-sale-item') THEN ST.OutQty
                                WHEN ST.TransactionType IN ('provisiona-cancel-item','provisional-to-sale') THEN -ST.InQty
                                ELSE 0
                            END
                        ) as SalesQty,   
                        SUM( 
                            CASE
                                WHEN ST.TransactionType IN ('sale-returned-item','manual-sales-return') THEN ST.InQty
                                ELSE 0
                            END
                        ) as SalesRetQty, 
                    SUM(
                            CASE
                                WHEN ST.TransactionType = 'write-off-item' THEN ST.OutQty
                                ELSE 0
                            END
                       ) as WriteOffQty,
                         SUM(
                            CASE
                                WHEN ST.TransactionType = 'rts-item' THEN ST.OutQty
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
                    PHRM_GoodsReceiptItems GRI 
                    INNER JOIN PHRM_GoodsReceipt GR ON GRI.GoodReceiptId = GR.GoodReceiptId
                    INNER JOIN PHRM_MST_Stock S ON GRI.StockId = S.StockId
                    INNER JOIN PHRM_TXN_StockTransaction ST ON S.StockId = ST.StockId
                WHERE CONVERT(date, ST.TransactionDate) BETWEEN @FromDate AND @ToDate AND
                --used StockTxn Date instead of GRDate since calculation of Opening depends on StkTxn Date. Taking GR Date may bring unwanted data in the output            
                    (GR.SupplierId = @SupplierId OR @SupplierId IS NULL) AND
                    (GRI.ItemId = @ItemId OR @ItemId IS NULL) AND
                    (GR.StoreId = @StoreId OR @StoreId IS NULL) AND
				    ISNULL(GRI.IsCancel,0) != 1 --Exclude items from Cancelled GRs
                GROUP BY GR.StoreId, GRI.ItemId, S.BatchNo, S.ExpiryDate, GR.SupplierId
            ) X
            -- If a same item with same batch and expiry date was supplied from same vendor, then report will show them as a single row, hence the group by is used as below
            GROUP BY X.StoreId, X.ItemId, X.BatchNo, X.ExpiryDate, X.SupplierId
        )
        gr ON I.ItemId = gr.ItemId AND S.SupplierId = gr.SupplierId AND str.StoreId = gr.StoreId
    WHERE (ISNULL(gr.OpeningQty,0) != 0 OR ISNULL(gr.PurchaseQty,0) != 0 OR ISNULL(gr.SalesQty,0) != 0 OR ISNULL(gr.SalesRetQty,0)!=0)
    ORDER BY ISNULL(gr.PurchaseQty,0) DESC
END