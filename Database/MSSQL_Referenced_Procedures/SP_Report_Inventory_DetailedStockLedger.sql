CREATE PROCEDURE [dbo].[SP_Report_Inventory_DetailedStockLedger] 
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @ItemId INT = NULL,
    @StoreId INT = NULL

AS
/*
FileName: SP_Report_Inventory_DetailedStockLedger '2021-05-13', '2021-09-13', null, null
CreatedBy/date: Rajib/20-07-2021
Description: SP to get the Stock Detail Ledger for Inventory.
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Ramesh/29-08-2021                    corrected for Txn type and StoreId for Dispatch
2.		 Rohit/31Mar22						  ItemName is fetched.
3.		 Rohit/9Jun'22						  ItemId is filter (mistake: before it was directly checking as null)
*/
    -- body of the stored procedure
    -- Drop the table if it already exists
    IF OBJECT_ID('tempDB..#TempTxnsTable', 'U') IS NOT NULL
    DROP TABLE #TempTxnsTable

    SELECT TXNS.* , CONVERT(FLOAT, 0) 'BalanceQty', CONVERT(DECIMAL(16,4),0) 'BalanceRate' , CONVERT(DECIMAL(16,4),0) 'BalanceAmount'
    INTO #TempTxnsTable
    FROM 
        (
            SELECT   STKT.TransactionDate, ISNULL(STKT.InQty,0) 'ReceiptQty', ISNULL(STKT.CostPrice,0) 'ReceiptRate', ISNULL(STKT.InQty,0) * ISNULL(STKT.CostPrice,0) 'ReceiptAmount',
                    NULL 'IssueQty', NULL 'IssueRate', NULL 'IssueAmount', 
                    GR.GoodsReceiptID 'ReferenceNo', GRI.GRItemSpecification 'Remarks',S.Name as Store, E.FullName 'Username',I.ItemName
            FROM    INV_TXN_StockTransaction STKT JOIN
                    EMP_Employee E ON STKT.CreatedBy = E.EmployeeId LEFT JOIN 
                    INV_TXN_GoodsReceiptItems GRI ON STKT.ReferenceNo = GRI.GoodsReceiptItemId LEFT JOIN
                    INV_TXN_GoodsReceipt GR ON GRI.GoodsReceiptId = GR.GoodsReceiptID JOIN
					PHRM_MST_Store S ON GR.StoreId = S.StoreId
					JOIN INV_MST_Item I ON GRI.ItemId=I.ItemId
            WHERE  STKT.TransactionType IN ('opening-item', 'goodreceipt-items') AND
                    (STKT.ItemId = @ItemId OR @ItemId IS NULL) AND
                    Convert(date,STKT.TransactionDate) BETWEEN @FromDate AND  @ToDate
					AND (STKT.StoreId = @StoreId OR @StoreId IS NULL)

            UNION ALL

            SELECT  STKT.TransactionDate, NULL 'ReceiptQty',NULL 'ReceiptRate',NULL 'ReceiptAmount',
                    ISNULL(STKT.OutQty,0)  'IssueQty',ISNULL(STKT.CostPrice,0) 'IssueRate',ISNULL(STKT.OutQty,0) * ISNULL(STKT.CostPrice,0) 'IssueAmount', 
                    D.DispatchId 'ReferenceNo', D.Remarks 'Remarks',S.Name as Store, ISNULL(E.FullName, 'Not Received') 'Username',I.ItemName
            FROM    INV_TXN_StockTransaction STKT LEFT JOIN 
                    INV_TXN_DispatchItems D ON STKT.ReferenceNo = D.DispatchItemsId LEFT JOIN
                    PHRM_MST_Store S ON D.TargetStoreId = S.StoreId LEFT JOIN
                    EMP_Employee E ON D.ReceivedById = E.EmployeeId
					JOIN INV_MST_Item I ON D.ItemId=I.ItemId
            WHERE  STKT.TransactionType IN ('dispatched-item-from', 'dispatched-item-to') AND
                    (STKT.ItemId = @ItemId OR @ItemId IS NULL) AND
                    Convert(date,STKT.TransactionDate)  BETWEEN @FromDate AND @ToDate
					AND (STKT.StoreId = @StoreId OR @StoreId IS NULL)
        ) TXNS
  ORDER BY TXNS.TransactionDate


    DECLARE @BalanceQty FLOAT = 0;
    DECLARE @BalanceAmount DECIMAL(20,4) = 0;
    WITH TEMPTXNS
    AS
    (
        SELECT  TXNS.TransactionDate, TXNS.ReceiptQty, TXNS.ReceiptRate, TXNS.ReceiptAmount,
                TXNS.IssueQty, TXNS.IssueRate,TXNS.IssueAmount,
                TXNS.BalanceQty, TXNS.BalanceRate, TXNS.BalanceAmount,
                TXNS.ReferenceNo, TXNS.Store, TXNS.Username, TXNS.Remarks,TXNS.ItemName
        FROM #TempTxnsTable TXNS
    )
    UPDATE TEMPTXNS
    SET @BalanceQty = BalanceQty = @BalanceQty + ISNULL(ReceiptQty,-IssueQty),
    BalanceRate = ISNULL(ReceiptRate, IssueRate),
    @BalanceAmount = BalanceAmount = @BalanceAmount + (ISNULL(ReceiptQty, -IssueQty) * ISNULL(ReceiptRate, IssueRate))
    OUTPUT INSERTED.*