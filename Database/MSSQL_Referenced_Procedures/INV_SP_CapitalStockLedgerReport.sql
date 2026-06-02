CREATE PROCEDURE [dbo].[INV_SP_CapitalStockLedgerReport] 
    @FromDate DATETIME = NULL,
    @ToDate DATETIME = NULL,
    @ItemId INT = NULL,
    @StoreId INT = NULL,
	@FiscalYearId INT= NULL
AS

Declare @FyStartDate datetime=(select top 1 Convert(Date,StartDate) from INV_CFG_FiscalYears where FiscalYearId=@FiscalYearId)
 Declare @DispatchOrConsumption varchar(20)=(Select top 1 ParameterValue from CORE_CFG_Parameters Where ParameterGroupName='Inventory' and ParameterName='ConsumptionOrDispatchForReports')
 Declare @ToDateForOpening Date = DATEADD(DAY, -1, @FromDate)  --ToDateforOpening = FromDate-1
/*
FileName: INV_SP_CapitalStockLedgerReport '2021-01-30', '2022-03-30',1916,7,5
CreatedBy/date: Rohit/2022-03-29
Description: SP to get the Capital Stock Ledger for Inventory.
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Rohit/2022-03-30                   Created initial script
2.		 Rohit/2022-07-12					RoundOff is done in OpeningQty, ReceiptQty and DispatchQty
											Fix: ReferenceNo is taken as GoodReceiptNo, DispatchNo
*/
    IF OBJECT_ID('tempDB..#TempTxnsTable', 'U') IS NOT NULL
    DROP TABLE #TempTxnsTable

    SELECT TXNS.* , CONVERT(FLOAT, 0) 'BalanceQty', CONVERT(DECIMAL(16,4),0) 'BalanceRate' , CONVERT(DECIMAL(16,4),0) 'BalanceAmount'
    INTO #TempTxnsTable
    FROM 
        (
				SELECT NULL 'TransactionDate',NULL 'ReceiptQty', NULL 'ReceiptRate',NULL 'ReceiptAmount',NULL 'IssueQty', NULL 'IssueRate', NULL 'IssueAmount', NULL 'ReferenceNo', 'opening-item' 'Remarks',StoreName as Store, NULL 'Username', ROUND(OpeningQty,4) 'OpeningQty',ISNULL(ReceiptRate,0) 'OpeningRate',OpeningValue 'OpeningValue',NULL 'Specification',NULL 'VendorName',NULL 'Code'
				from	FN_INV_Opening_Stock_Details(@FiscalYearId, @FyStartDate, @ToDateForOpening, @DispatchOrConsumption)
				where ItemId=@ItemId

			UNION ALL

            SELECT   STKT.TransactionDate, ROUND(ISNULL(STKT.InQty,0),4) 'ReceiptQty', ISNULL(STKT.CostPrice,0) 'ReceiptRate', ROUND(ISNULL(STKT.InQty,0) * ISNULL(STKT.CostPrice,0),4) 'ReceiptAmount',
                    NULL 'IssueQty', NULL 'IssueRate', NULL 'IssueAmount', 
                    GR.GoodsReceiptNo 'ReferenceNo', GRI.GRItemSpecification 'Remarks',S.Name as Store, E.FullName 'Username', NULL 'OpeningQty',NULL 'OpeningRate',NULL 'OpeningValue',GRI.GRItemSpecification 'Specification',V.VendorName 'VendorName',I.Code 'Code'
            FROM    INV_TXN_StockTransaction STKT JOIN
                    EMP_Employee E ON STKT.CreatedBy = E.EmployeeId LEFT JOIN 
                    INV_TXN_GoodsReceiptItems GRI ON STKT.ReferenceNo = GRI.GoodsReceiptItemId LEFT JOIN
                    INV_TXN_GoodsReceipt GR ON GRI.GoodsReceiptId = GR.GoodsReceiptID JOIN
					INV_MST_Vendor V ON GR.VendorId=V.VendorId JOIN
					PHRM_MST_Store S ON GR.StoreId = S.StoreId JOIN
					INV_MST_Item I ON STKT.ItemId=I.ItemId
            WHERE  STKT.TransactionType IN ('opening-item', 'goodreceipt-items','cancelled-donated-item') AND
                    STKT.ItemId = @ItemId AND
                    Convert(date,STKT.TransactionDate) BETWEEN @FromDate AND  @ToDate
					AND STKT.StoreId = @StoreId

            UNION ALL

            SELECT  STKT.TransactionDate, NULL 'ReceiptQty',NULL 'ReceiptRate',NULL 'ReceiptAmount',
                    ROUND(ISNULL(STKT.OutQty,0),4)  'IssueQty',ISNULL(STKT.CostPrice,0) 'IssueRate',ROUND(ISNULL(STKT.OutQty,0) * ISNULL(STKT.CostPrice,0),4) 'IssueAmount', 
                    D.DispatchNo 'ReferenceNo', D.Remarks 'Remarks',S.Name as Store, ISNULL(E.FullName, 'Not Received') 'Username', NULL 'OpeningQty',NULL 'OpeningRate',NULL 'OpeningValue',D.Specification 'Specification', NULL 'VendorName',I.Code 'Code'
            FROM    INV_TXN_StockTransaction STKT LEFT JOIN 
                    INV_TXN_DispatchItems D ON STKT.ReferenceNo = D.DispatchItemsId LEFT JOIN
                    PHRM_MST_Store S ON D.TargetStoreId = S.StoreId LEFT JOIN
                    EMP_Employee E ON D.ReceivedById = E.EmployeeId JOIN
					INV_MST_Item I ON STKT.ItemId=I.ItemId
            WHERE  STKT.TransactionType IN ('dispatched-item-from', 'dispatched-item-to') AND
                    STKT.ItemId =  @ItemId AND
                    Convert(date,STKT.TransactionDate)  BETWEEN @FromDate AND @ToDate
					AND STKT.StoreId = @StoreId

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
                TXNS.ReferenceNo, TXNS.Store, TXNS.Username, TXNS.Remarks,OpeningQty,OpeningRate,OpeningValue,Specification, VendorName,Code
        FROM #TempTxnsTable TXNS
    )
    UPDATE TEMPTXNS
    SET @BalanceQty = BalanceQty = @BalanceQty + ISNULL(ISNULL(ReceiptQty,-IssueQty),OpeningQty),
    BalanceRate = ISNULL(ISNULL(ReceiptRate, IssueRate),OpeningRate),
    @BalanceAmount = BalanceAmount = @BalanceAmount + (ISNULL(ISNULL(ReceiptQty, -IssueQty),OpeningQty) * ISNULL(ISNULL(ReceiptRate, IssueRate),OpeningRate))
    OUTPUT INSERTED.*

--Table 2 : For Fetching Item Details like Name,UOM and SubCategory and JinsiKhataNo-----------------------------------------------------------------------------------

	SELECT mstitm.ItemName
	,uom.UOMName
	,fy.FiscalYearName
	,subCat.SubCategoryName
	,mstitm.RegisterPageNumber
FROM INV_MST_Item mstitm
LEFT JOIN INV_TXN_GoodsReceiptItems gri ON mstitm.ItemId = gri.ItemId
JOIN INV_TXN_GoodsReceipt gr ON gri.GoodsReceiptId=gr.GoodsReceiptID
JOIN INV_MST_UnitOfMeasurement uom ON mstitm.UnitOfMeasurementId = uom.UOMId
JOIN INV_CFG_FiscalYears fy ON gr.FiscalYearId = fy.FiscalYearId
JOIN INV_MST_ItemSubCategory subCat ON mstitm.SubCategoryId = subCat.SubCategoryId
WHERE mstitm.ItemId = @ItemId
	AND fy.FiscalYearId = @FiscalYearId