CREATE PROCEDURE dbo.SP_Opening_Stock_Valuation_Report
@TillDate DATE = NULL
AS
-- ===========================================================================
-- Author:		Rohit
-- Create date: 10Apr'22
-- Description: generated inventory opening stock valuation report
-- Example : EXECUTE SP_Opening_Stock_Valuation_Report '2022-04-10'
-- ===========================================================================
/* Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rohit/10Apr'22	                Created initial Script
*/
BEGIN
    SELECT store.StoreId,store.Name AS StoreName, ISNULL(stxn.PurchaseValue,0) 'PurchaseValue'
    FROM PHRM_MST_Store store
    LEFT JOIN 
    (
        SELECT str.StoreId, 
        CONVERT(money, SUM(ISNULL(stxn.InQty,0) * ISNULL(stxn.CostPrice,0)) - sum(ISNULL(stxn.OutQty,0) * ISNULL(stxn.CostPrice,0))) 'PurchaseValue'
        FROM INV_TXN_StockTransaction stxn
            JOIN PHRM_MST_Store str ON stxn.StoreId = str.StoreId
            JOIN INV_MST_Item itm ON itm.ItemId = stxn.ItemId
        WHERE ISNULL(stxn.IsActive,0) = 1 AND CONVERT(DATE,stxn.TransactionDate) < @TillDate
        GROUP BY str.StoreId
    ) stxn
    ON store.StoreId = stxn.StoreId
    WHERE store.Category IN ('substore') OR store.SubCategory ='inventory'
	UNION
	SELECT 0 AS 'StoreId','Total' AS StoreName, stxn.PurchaseValue
    FROM 
    (
        SELECT 
        CONVERT(money, SUM(ISNULL(stxn.InQty,0) * ISNULL(stxn.CostPrice,0)) - sum(ISNULL(stxn.OutQty,0) * ISNULL(stxn.CostPrice,0))) 'PurchaseValue'
        FROM INV_TXN_StockTransaction stxn
        WHERE ISNULL(stxn.IsActive,0) = 1 AND CONVERT(DATE,stxn.TransactionDate) < @TillDate
    ) stxn
END