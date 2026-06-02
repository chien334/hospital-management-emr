CREATE PROCEDURE SP_Dashboard_PHRM_CardSummaryCalculation
   @FromDate datetime=NULL,
   @ToDate datetime=NULL

AS
 /*
 SP_Dashboard_PHRM_CardSummaryCalculation '2022-10-3','2022-10-31'
FileName: [SP_Dashboard_PHRM_CardSummaryCalculation]
CreatedBy/date: Sanjit/Rohit/2022-12-29
Description: .
Remarks:    A
Change History
S.No.    UpdatedBy/Date                        Remarks
1      Sanjit/Rohit/2022-12-29                 created the script
*/
BEGIN
DECLARE @FromDateMinusOneDay Date = DateAdd(day, -1, @FromDate);
DECLARE @FromDateMinusTwoDays Date = DateAdd(day, -2, @FromDate)
DECLARE @NoOfDaysInGivenRange INT =  DATEDIFF(day, @FromDate, @ToDate) + 1

DECLARE @FiscalYearId INT = (Select FiscalYearId From PHRM_CFG_FiscalYears WHERE @ToDate BETWEEN CONVERT(date, StartDate ) and CONVERT(date, EndDate))
DECLARE @FicalYearStartDate Date = (Select StartDate From PHRM_CFG_FiscalYears WHERE FiscalYearId = @FiscalYearId)

select 'Total' as TransactionType, ISNULL(SUM(SubTotal),0) as TotalAmount
from FN_PHRM_PharmacyTxn_ByBillingType_UserCollection(@FromDate, @ToDate, NULL)
UNION ALL
select 'Cash' as TransactionType, ISNULL(SUM(SubTotal),0) as TotalAmount
from FN_PHRM_PharmacyTxn_ByBillingType_UserCollection(@FromDate, @ToDate, NULL)
where TransactionType IN ('CashInvoice','CashInvoiceReturn')
UNION ALL
select 'Credit' as TransactionType, ISNULL(SUM(SubTotal),0) as TotalAmount
from FN_PHRM_PharmacyTxn_ByBillingType_UserCollection(@FromDate, @ToDate, NULL)
where TransactionType IN ('CreditInvoice','CreditInvoiceReturn')
UNION ALL
select 'PreviousDay' as TransactionType, ISNULL(SUM(SubTotal),0) as TotalAmount
from FN_PHRM_PharmacyTxn_ByBillingType_UserCollection(@FromDateMinusTwoDays, @FromDateMinusOneDay, NULL)
UNION ALL
select 'Average' as TransactionType, ISNULL(SUM(SubTotal),0)/@NoOfDaysInGivenRange as TotalAmount
from FN_PHRM_PharmacyTxn_ByBillingType_UserCollection(@FromDate, @ToDate, NULL)


SELECT 'Total' AS TransactionType, ISNULL(SUM(TotalAmount),0) 'TotalAmount'
FROM PHRM_GoodsReceipt where ISNULL(IsCancel,0 )!=1 
		AND CONVERT(DATE, GoodReceiptDate) BETWEEN @FromDate AND @ToDate

UNION ALL
SELECT 'Cash' AS TransactionType, ISNULL(SUM(TotalAmount),0) 'TotalAmount'
FROM PHRM_GoodsReceipt where ISNULL(IsCancel,0 )!=1 
		AND CONVERT(DATE, GoodReceiptDate) BETWEEN @FromDate AND @ToDate
		AND TransactionType ='cash'

UNION ALL
SELECT 'Credit' AS TransactionType, ISNULL(SUM(TotalAmount),0) 'TotalAmount'
FROM PHRM_GoodsReceipt where ISNULL(IsCancel,0 )!=1 
		AND CONVERT(DATE, GoodReceiptDate) BETWEEN @FromDate AND @ToDate
		AND TransactionType ='credit'

UNION ALL
SELECT 'PreviousDay' AS TransactionType, ISNULL(SUM(TotalAmount),0) 'TotalAmount'
FROM PHRM_GoodsReceipt where ISNULL(IsCancel,0 )!=1 
		AND CONVERT(DATE, GoodReceiptDate) BETWEEN @FromDateMinusTwoDays AND @FromDateMinusOneDay
UNION ALL
SELECT 'Average' AS TransactionType, ISNULL(SUM(TotalAmount),0)/@NoOfDaysInGivenRange 'TotalAmount'
FROM PHRM_GoodsReceipt where ISNULL(IsCancel,0 )!=1 
		AND CONVERT(DATE, GoodReceiptDate) BETWEEN @FromDate AND @ToDate


SELECT 'TotalDispatched' AS TransactionType, ISNULL(SUM(DispatchedQuantity * CostPrice),0) TotalAmount, Count(DispatchedQuantity) as TotalUnit
from PHRM_StoreDispatchItems WHERE DispatchedDate BETWEEN @FromDate AND @ToDate
UNION ALL
SELECT 'PendingRequisition' AS TransactionType, NULL as TotalAmount, COUNT(*) as TotalUnit
from PHRM_StoreRequisition 
WHERE RequisitionStatus IN ('active', 'partial', 'pending') and RequisitionDate BETWEEN @FromDate AND @ToDate 

UNION ALL

SELECT 'NotReceivedRequisition' AS TransactionType, NULL as TotalAmount, COUNT(*)  as TotalUnit
from PHRM_StoreRequisition 
WHERE RequisitionDate BETWEEN @FromDate AND @ToDate 
AND RequisitionId IN
(
	select RequisitionId
	from PHRM_StoreDispatchItems
	where ReceivedById IS NULL
	group by RequisitionId
)

UNION ALL

SELECT 'PreviousDay' AS TransactionType, ISNULL(SUM(DispatchedQuantity * CostPrice),0)  TotalAmount, Count(DispatchedQuantity) as TotalUnit
from PHRM_StoreDispatchItems WHERE DispatchedDate BETWEEN @FromDateMinusTwoDays AND @FromDateMinusOneDay

UNION ALL

SELECT 'Average' AS TransactionType, ISNULL(SUM(DispatchedQuantity * CostPrice),0)/@NoOfDaysInGivenRange  TotalAmount, Count(DispatchedQuantity) as TotalUnit
FROM PHRM_StoreDispatchItems where CONVERT(DATE, DispatchedDate) BETWEEN @FromDate AND @ToDate




select 'Total' AS TransactionType, ISNULL(SUM(ClosingValue),0) 'TotalAmount', ISNULL(SUM(ClosingQty),0) 'TotalUnit'
from FN_RPT_PHRM_GetClosingStockDetailsOnGivenDate(@FiscalYearId, @FicalYearStartDate, @ToDate)
UNION ALL
select 'Narcotic' AS TransactionType, ISNULL(SUM(rptitm.ClosingValue),0) 'TotalAmount', ISNULL(SUM(rptitm.ClosingQty),0) 'TotalUnit'
from FN_RPT_PHRM_GetClosingStockDetailsOnGivenDate(@FiscalYearId, @FicalYearStartDate, @ToDate) rptitm
INNER JOIN PHRM_MST_Item itm on rptitm.ItemId=itm.ItemId
WHERE ISNULL(IsNarcotic,0) =1
UNION ALL
select 'NearlyExpiry' AS TransactionType, ISNULL(SUM(rptitm.ClosingValue),0) 'TotalAmount', ISNULL(SUM(rptitm.ClosingQty),0) 'TotalUnit'
from FN_RPT_PHRM_GetClosingStockDetailsOnGivenDate(@FiscalYearId, @FicalYearStartDate, @ToDate) rptitm
INNER JOIN PHRM_MST_Stock stk on rptitm.StockId=stk.StockId
WHERE CONVERT(DATE,stk.ExpiryDate) BETWEEN @ToDate AND DATEADD(MONTH,3,@ToDate) 
UNION ALL
select 'Expiry' AS TransactionType, ISNULL(SUM(rptitm.ClosingValue),0) 'TotalAmount', ISNULL(SUM(rptitm.ClosingQty),0) 'TotalUnit'
from FN_RPT_PHRM_GetClosingStockDetailsOnGivenDate(@FiscalYearId, @FicalYearStartDate, @ToDate) rptitm
INNER JOIN PHRM_MST_Stock stk on rptitm.StockId=stk.StockId
WHERE CONVERT(DATE,stk.ExpiryDate) < @FromDate
END