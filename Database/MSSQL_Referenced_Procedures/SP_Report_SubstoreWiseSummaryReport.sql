CREATE PROCEDURE [dbo].[SP_Report_SubstoreWiseSummaryReport]
     @StoreId INT = NULL
    ,@FromDate DATE = NULL
    ,@ToDate DATE = NULL
	,@FiscalYearId INT=NULL
	
AS
/*
FileName: [SP_Report_SubstoreWiseSummaryReport] null, '2022-05-18','2022-05-19',6
Created: 18May'22/Rohit
Description: To Get Substore Wise Summary Report Data With StoreId,FromDate,ToDate,FiscalYearId.
Change History
S.No.    Date/User              Change          Remarks
1.       11Nov'22/Rohit/Nirmala                       inital draft
2.       18Nov'22/Rohit								  Removed ReceivedQty, Substore Name Removed (Substore Filer gives the information of 
													  Substore so no need to show SubStoreName)
3.		4Jan'22/Rohit								  Store filter changes 
*/
BEGIN
  
SELECT itms.ItemId
    ,itms.ItemName
    ,cat.ItemCategoryName
    ,subcat.SubCategoryName
    ,uom.UOMName 'Unit'
    ,ISNULL(OI.OpeningQty, 0) 'OpeningQty'
    ,ISNULL(OI.OpeningValue, 0) 'OpeningValue'
    ,ISNULL(DI.DispatchedQty, 0) 'DispatchedQty'
    ,ISNULL(DI.DispatchedValue, 0) 'DispatchedValue'
    ,ISNULL(CI.ConsumedQty, 0) 'ConsumedQty'
    ,ISNULL(CI.ConsumedValue, 0) 'ConsumedValue'
    ,ISNULL(OI.OpeningQty, 0) + ISNULL(DI.DispatchedQty, 0) - ISNULL(CI.ConsumedQty, 0) 'ClosingQty'
    ,ISNULL(OI.OpeningValue, 0) + ISNULL(DI.DispatchedValue, 0) - ISNULL(CI.ConsumedValue, 0) 'ClosingValue'
FROM INV_MST_Item itms
INNER JOIN INV_MST_ItemCategory cat ON itms.ItemCategoryId = cat.ItemCategoryId
INNER JOIN INV_MST_ItemSubCategory subcat ON itms.SubCategoryId = subcat.SubCategoryId
INNER JOIN INV_MST_UnitOfMeasurement uom ON itms.UnitOfMeasurementId = uom.UOMId
LEFT JOIN (
    SELECT ItemId
        ,SUM(ISNULL(OpeningQty, 0)) 'OpeningQty'
        ,SUM(IsNull(OpeningQty, 0) * IsNull(Price, 0)) 'OpeningValue'
    FROM INV_FiscalYearStock
    WHERE FiscalYearId = @FiscalYearId
        AND (
            StoreId = @StoreId
            OR @StoreId IS NULL
            )
        AND (
            StoreId  IN (
                SELECT StoreId
                FROM PHRM_MST_Store
                WHERE Category ='substore'
                )
            )
    GROUP BY ItemId
    ) OI ON itms.ItemId = OI.ItemId
LEFT JOIN (
    SELECT ItemId
        ,SUM(Isnull(InQty, 0)) 'DispatchedQty'
        ,SUM(IsNull(InQty, 0) * IsNull(CostPrice, 0)) 'DispatchedValue'
    FROM INV_TXN_StockTransaction
    WHERE TransactionType IN ('dispatched-item-to')
        AND CONVERT(DATE, TransactionDate) BETWEEN @FromDate
            AND @ToDate
        AND (
            StoreId = @StoreId
            OR @StoreId IS NULL
            )
        AND (
            StoreId  IN (
                SELECT StoreId
                FROM PHRM_MST_Store
                WHERE Category ='substore'
                )
            )
    GROUP BY ItemId
    ) DI ON itms.ItemId = DI.ItemId
LEFT JOIN (
    SELECT ItemId
        ,SUM(Isnull(OutQty, 0)) 'ConsumedQty'
        ,SUM(IsNull(OutQty, 0) * IsNull(CostPrice, 0)) 'ConsumedValue'
    FROM INV_TXN_StockTransaction
    WHERE TransactionType IN ('consumption-items')
        AND CONVERT(DATE, TransactionDate) BETWEEN @FromDate
            AND @ToDate
        AND (
            StoreId = @StoreId
            OR @StoreId IS NULL
            )
        AND (
            StoreId  IN (
                SELECT StoreId
                FROM PHRM_MST_Store
                WHERE Category  ='substore'
                )
            )
    GROUP BY ItemId
    ) CI ON itms.ItemId = CI.ItemId
WHERE OpeningQty > 0
    OR DispatchedQty > 0
    OR ConsumedQty > 0
	ORDER BY ItemName 
END