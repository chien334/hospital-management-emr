CREATE PROCEDURE [dbo].[SP_INV_RPT_GetInventorySummary]			
    @FiscalYearId int, 
	@FromDate Date, 
	@ToDate Date,
	@StoreId INT=NULL
AS
/************************************************************************
FileName: [SP_INV_RPT_GetInventorySummary]
Description: Get Inventory summary report data for StoreId, ItemId 
Returns: 
        StoreId, StoreName, ItemId, ItemCode, ItemName, ItemType
		,SubCategory, Unit, ItemType
		,OpeningQty, OpeningValue, PurchaseQty, PurchaseValue
		,TransInQty, TransInValue, TransOutQty, TransOutValue
		,ConsumptionQty,ConsumptionValue, StockManageInQty,StockManageInValue
		,StockManageOutQty,StockManageOutValue, ClosingQty,ClosingValue
  
Usage : EXEC SP_INV_RPT_GetInventorySummary 6,'2023-03-01','2023-03-27',NULL
Change History
S.No.    UpdatedBy/Date                        Remarks
3.	 Rohit/7Jun'22								ItemType Filter removed
4.   Sud/9Jun'22                                Added new fields for ClosingQty, ClosingValue with Calculation
5.   Rohit/25Jul'22								ItemType is fetched
6.   Sud/27Mar'23                               Added filter for StoreId, 
                                                Replaced Dispatch by TransIn/TransOut 
*************************************************************************/
BEGIN
  
 Declare @FyStartDate datetime=(select top 1 Convert(Date,StartDate) from INV_CFG_FiscalYears where FiscalYearId=@FiscalYearId)

 Declare @ToDateForOpening Date = DATEADD(DAY, -1, @FromDate)  --ToDateforOpening = FromDate-1

 Select itmsinfo.StoreId,
        itmsInfo.StoreName,
		itmsInfo.ItemId,
		itmsInfo.ItemCode,
		itmsInfo.ItemName,
		itmsinfo.ItemType,
		itmsInfo.SubCategory,
		itmsInfo.Unit,
		itmsInfo.ItemType,
		ISNULL(opening.OpeningQty,0)  AS 'OpeningQty',
		ISNULL(opening.OpeningValue,0) AS  'OpeningValue',
		ISNULL(txnsBetnRange.PurchaseQty,0) AS  'PurchaseQty',
		ISNULL(txnsBetnRange.PurchaseValue,0) AS  'PurchaseValue',
		ISNULL(txnsBetnRange.TransInQty,0) AS  'TransInQty',
		ISNULL(txnsBetnRange.TransInValue,0) AS  'TransInValue',
		ISNULL(txnsBetnRange.TransOutQty,0) AS  'TransOutQty',
		ISNULL(txnsBetnRange.TransOutValue,0) AS  'TransOutValue',
		ISNULL(txnsBetnRange.ConsumptionQty,0) AS  'ConsumptionQty',
		ISNULL(txnsBetnRange.ConsumptionValue,0) AS  'ConsumptionValue',
		ISNULL(txnsBetnRange.StockManageInQty,0) AS  'StockManageInQty',
		ISNULL(txnsBetnRange.StockManageInValue,0) AS  'StockManageInValue',
        ISNULL(txnsBetnRange.StockManageOutQty,0) AS  'StockManageOutQty',
		ISNULL(txnsBetnRange.StockManageOutValue,0) AS  'StockManageOutValue',

		ISNULL(opening.OpeningQty,0) 
			 + ISNULL(txnsBetnRange.PurchaseQty,0)  
			 + ISNULL(txnsBetnRange.TransInQty,0)  
			 - ISNULL(txnsBetnRange.TransOutQty,0) 
			 - ISNULL(txnsBetnRange.ConsumptionQty,0)
			 + ISNULL(txnsBetnRange.StockManageInQty,0)
			 - ISNULL(txnsBetnRange.StockManageOutQty,0)
			  AS 'ClosingQty',
	   
		ISNULL(opening.OpeningValue,0) 
			 + ISNULL(txnsBetnRange.PurchaseValue,0)  
			 + ISNULL(txnsBetnRange.TransInValue,0)  
			 - ISNULL(txnsBetnRange.TransOutValue,0) 
			 - ISNULL(txnsBetnRange.ConsumptionValue,0)
			 + ISNULL(txnsBetnRange.StockManageInValue,0)
			 - ISNULL(txnsBetnRange.StockManageOutValue,0)
			  AS 'ClosingValue'

 From  
 (
  --Table:1--LeftMost table to get the Store and Item Master Details---
  Select Distinct stor.StoreId, stor.Name 'StoreName',
        itm.ItemId, itm.Code 'ItemCode', itm.ItemName, itm.ItemType,  sub.SubCategoryName 'SubCategory', uom.UOMName AS 'Unit'
   from INV_TXN_StoreStock storStk
	INNER JOIN INV_MST_Item itm on storStk.ItemId=itm.ItemId
	INNER JOIN INV_MST_UnitOfMeasurement uom on itm.UnitOfMeasurementId=uom.UOMId
	INNER JOIN PHRM_MST_Store stor ON storStk.StoreId = stor.StoreId
	INNER JOIN INV_MST_ItemSubCategory sub ON itm.SubCategoryId=sub.SubCategoryId
 ) itmsInfo

LEFT JOIN
(
  --This function does Opening+SUM(IN)-SUM(OUT) and gives Opening on the FromDate
    Select * from [FN_RPT_INV_GetItemsOpeningQtyUptoDate](@FiscalYearId, @FyStartDate, @ToDateForOpening)
) opening
ON itmsInfo.ItemId = opening.ItemId  and  itmsInfo.StoreId=opening.StoreId

Left join
(
  --Get transactions from: @FromDate To @ToDate---
  Select * from [FN_RPT_INV_GetItemStockTxnsBetnDateRange](@FromDate, @ToDate)
)
txnsBetnRange
 ON itmsInfo.ItemId = txnsBetnRange.ItemId and itmsInfo.StoreId=txnsBetnRange.StoreId

Where @StoreId is null OR itmsInfo.StoreId = @StoreId

ORder by itmsInfo.StoreName, itmsInfo.SubCategory, itmsInfo.ItemName 
END