CREATE PROCEDURE [dbo].[INV_RPT_ExpirableStockReport]
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @ItemId INT = NULL,
	@FiscalYearId INT= NULL
AS
BEGIN
Declare @FyStartDate datetime=(select top 1 Convert(Date,StartDate) from INV_CFG_FiscalYears where FiscalYearId=@FiscalYearId)
 Declare @DispatchOrConsumption varchar(20)=(Select top 1 ParameterValue from CORE_CFG_Parameters Where ParameterGroupName='Inventory' and ParameterName='ConsumptionOrDispatchForReports')

 Declare @ToDateForOpening Date = DATEADD(DAY, -1, @FromDate)  
/*
FileName: INV_RPT_ExpirableStockReport '2022-03-29', '2022-03-29', 122, 5
CreatedBy/date: Rohit/2022-06-06  
Description: SP to get the Expirable Stock  for Inventory.
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Rohit/2022-06-06                   Created initial script
*/
    IF OBJECT_ID('tempDB..#TempTxnsTable', 'U') IS NOT NULL
    DROP TABLE #TempTxnsTable

    SELECT TXNS.* , CONVERT(FLOAT, 0) 'BalanceQty', CONVERT(DECIMAL(16,4),0) 'BalanceRate' , CONVERT(DECIMAL(16,4),0) 'BalanceAmount'
    INTO #TempTxnsTable
    FROM 
        (
				SELECT NULL 'TransactionDate',NULL 'ReceiptQty', NULL 'ReceiptRate',NULL 'ReceiptAmount',NULL 'IssueQty', NULL 'IssueRate', NULL 'IssueAmount', NULL 'ReferenceNo', 'opening-item' 'Remarks',  NULL 'Username', OpeningQty 'OpeningQty',ReceiptRate 'OpeningRate',OpeningValue 'OpeningValue',ExpiryDate
				from	FN_RPT_INV_GetItemsOpeningQtyUptoDateForExpirableStock(@FiscalYearId, @FyStartDate, @ToDateForOpening,@DispatchOrConsumption)
				where ItemId=@ItemId

			UNION ALL

            SELECT   STKT.TransactionDate, ISNULL(STKT.InQty,0) 'ReceiptQty', ISNULL(STKT.CostPrice,0) 'ReceiptRate', 
			     ROUND(ISNULL(STKT.InQty,0) * ISNULL(STKT.CostPrice,0),4) 'ReceiptAmount',
                    NULL 'IssueQty', NULL 'IssueRate', NULL 'IssueAmount', 
                    GR.GoodsReceiptNo 'ReferenceNo', GRI.GRItemSpecification 'Remarks', E.FullName 'Username', 
					NULL 'OpeningQty',NULL 'OpeningRate',NULL 'OpeningValue',STKT.ExpiryDate
            FROM    INV_TXN_StockTransaction STKT INNER JOIN
                    EMP_Employee E ON STKT.CreatedBy = E.EmployeeId INNER JOIN 
                    INV_TXN_GoodsReceiptItems GRI ON STKT.ReferenceNo = GRI.GoodsReceiptItemId INNER JOIN
                    INV_TXN_GoodsReceipt GR ON GRI.GoodsReceiptId = GR.GoodsReceiptID INNER JOIN
					PHRM_MST_Store S ON GR.StoreId = S.StoreId
            WHERE  STKT.TransactionType ='goodreceipt-items'
			        AND   STKT.ItemId = @ItemId 
				    AND Convert(date,STKT.TransactionDate) BETWEEN @FromDate AND  @ToDate

            UNION ALL

			  SELECT   STKT.TransactionDate, ISNULL(STKT.InQty,0) 'ReceiptQty', ISNULL(STKT.CostPrice,0) 'ReceiptRate', 
			     ROUND(ISNULL(STKT.InQty,0) * ISNULL(STKT.CostPrice,0),4) 'ReceiptAmount',
                    NULL 'IssueQty', NULL 'IssueRate', NULL 'IssueAmount', 
                    GR.GoodsReceiptNo 'ReferenceNo', GRI.GRItemSpecification 'Remarks', E.FullName 'Username', 
					NULL 'OpeningQty',NULL 'OpeningRate',NULL 'OpeningValue',STKT.ExpiryDate
            FROM    INV_TXN_StockTransaction STKT INNER JOIN
                    EMP_Employee E ON STKT.CreatedBy = E.EmployeeId INNER JOIN 
                    INV_TXN_GoodsReceiptItems GRI ON STKT.ReferenceNo = GRI.GoodsReceiptItemId INNER JOIN
                    INV_TXN_GoodsReceipt GR ON GRI.GoodsReceiptId = GR.GoodsReceiptID INNER JOIN
					PHRM_MST_Store S ON GR.StoreId = S.StoreId
            WHERE  STKT.TransactionType ='cancel-gr-items'
			        AND   STKT.ItemId = @ItemId 
				    AND Convert(date,STKT.TransactionDate) BETWEEN @FromDate AND  @ToDate

            UNION ALL
            SELECT  STKT.TransactionDate, NULL 'ReceiptQty',NULL 'ReceiptRate',NULL 'ReceiptAmount',
                    ISNULL(STKT.OutQty,0)  'IssueQty',ISNULL(STKT.CostPrice,0) 'IssueRate',ROUND(ISNULL(STKT.OutQty,0) * ISNULL(STKT.CostPrice,0),4) 'IssueAmount', 
                    D.DispatchId 'ReferenceNo', D.Remarks 'Remarks', ISNULL(E.FullName, 'Not Received') 'Username', NULL 'OpeningQty',NULL 'OpeningRate',NULL 'OpeningValue',STKT.ExpiryDate
            FROM    INV_TXN_StockTransaction STKT LEFT JOIN 
                    INV_TXN_DispatchItems D ON STKT.ReferenceNo = D.DispatchItemsId LEFT JOIN
                    PHRM_MST_Store S ON D.TargetStoreId = S.StoreId LEFT JOIN
                    EMP_Employee E ON D.ReceivedById = E.EmployeeId
            WHERE  STKT.TransactionType IN ('dispatched-item-from') AND
                    STKT.ItemId =  @ItemId AND
                    Convert(date,STKT.TransactionDate)  BETWEEN @FromDate AND @ToDate

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
                TXNS.ReferenceNo, TXNS.Username, TXNS.Remarks,OpeningQty,OpeningRate,OpeningValue,TXNS.ExpiryDate
        FROM #TempTxnsTable TXNS
    )
    UPDATE TEMPTXNS
    SET @BalanceQty = BalanceQty = @BalanceQty + ISNULL(ISNULL(ReceiptQty,-IssueQty),OpeningQty),
    BalanceRate = ISNULL(ISNULL(ReceiptRate, IssueRate),OpeningRate),
    @BalanceAmount = BalanceAmount = ISNULL(@BalanceAmount,0) + ((ISNULL(ISNULL(ReceiptQty, -IssueQty),OpeningQty)) * ISNULL(ISNULL(ReceiptRate, IssueRate),OpeningRate))
    OUTPUT INSERTED.*

--Table 2 : For Fetching Item Details like Name,UOM and SubCategory and JinsiKhataNo-----------------------------------------------------------------------------------
SELECT top 1 * from (
SELECT  mstitm.ItemName
	,uom.UOMName
	,gri.GRItemSpecification
	,gri.ItemCategory
	,fy.FiscalYearName
	,subCat.SubCategoryName
	,mstitm.RegisterPageNumber
	,mstitm.ItemId
	,fy.FiscalYearId
	,mstitm.Code
FROM INV_MST_Item mstitm
LEFT JOIN INV_TXN_GoodsReceiptItems gri ON mstitm.ItemId = gri.ItemId
INNER JOIN INV_TXN_GoodsReceipt gr ON gri.GoodsReceiptId=gr.GoodsReceiptID
INNER JOIN INV_CFG_FiscalYears fy ON gr.FiscalYearId = fy.FiscalYearId
LEFT JOIN INV_MST_UnitOfMeasurement uom ON mstitm.UnitOfMeasurementId = uom.UOMId
LEFT JOIN INV_MST_ItemSubCategory subCat ON mstitm.SubCategoryId = subCat.SubCategoryId

UNION

SELECT  mstitm.ItemName
	,uom.UOMName
	,null 'GRItemSpecification'
	,cat.ItemCategoryName
	,fy.FiscalYearName
	,subCat.SubCategoryName
	,mstitm.RegisterPageNumber
	,mstitm.ItemId
	,fy.FiscalYearId
	,mstitm.Code
FROM INV_MST_Item mstitm
INNER JOIN INV_FiscalYearStock fys ON mstitm.ItemId = fys.ItemId
INNER JOIN INV_CFG_FiscalYears fy ON fys.FiscalYearId = fy.FiscalYearId
LEFT JOIN INV_MST_UnitOfMeasurement uom ON mstitm.UnitOfMeasurementId = uom.UOMId
LEFT JOIN INV_MST_ItemSubCategory subCat ON mstitm.SubCategoryId = subCat.SubCategoryId
LEFT JOIN INV_MST_ItemCategory cat on mstitm.ItemCategoryId=cat.ItemCategoryId
)tbl
WHERE ItemId = @ItemId
	AND FiscalYearId = @FiscalYearId

END