/*
CreatedDate:---
FileName: [SP_Report_Inventory_InventoryValuation] 
Description: To get the Details of report Inventory Valuation
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.                                         created the script
2.	  Rohit/20Jan'22					   Added ItemCategory,Specification,BarCodes
*/
CREATE PROCEDURE [dbo].[SP_Report_Inventory_InventoryValuation]

AS
BEGIN
    /* 
here we take item rate from INV_TXN_GoodsReceiptItems and its  available quantity from INV_TXN_Stock 
and then calculate amount for the item.
*/
    SELECT
        A.ItemName,
        A.UOMName,
        A.Code,
        ROUND((SUM(A.Amt)/SUM(A.Qty)),2) Rate,
        SUM(A.Qty) Quantity,
        SUM(A.Amt) Amount,
        A.ItemCategory,
        A.GRItemSpecification AS Specification,
       STRING_AGG(A.BarCodeNumber,', ')  'BarCodes'
    FROM
        (
	SELECT
            Itm.ItemName,
            grItm.ItemRate, stk.AvailableQuantity Qty,
            grItm.ItemRate * stk.AvailableQuantity Amt,
            unit.UOMName,
            Itm.Code,
            grItm.GRItemSpecification,
            grItm.ItemCategory,
            fas.BarCodeNumber
        FROM INV_TXN_Stock stk
            JOIN INV_TXN_GoodsReceiptItems grItm ON stk.GoodsReceiptItemId = grItm.GoodsReceiptItemId
            JOIN INV_MST_Item Itm ON stk.ItemId = Itm.ItemId
            JOIN INV_TXN_FixedAssetStock fas ON stk.ItemId =fas.ItemId
            LEFT JOIN INV_MST_UnitOfMeasurement unit ON itm.UnitOfMeasurementId = unit.UOMId
        WHERE stk.AvailableQuantity > 0
) A
    GROUP BY A.ItemName,A.UOMName,A.Code,A.ItemCategory,A.GRItemSpecification

END