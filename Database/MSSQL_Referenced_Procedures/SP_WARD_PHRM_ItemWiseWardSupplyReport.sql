CREATE PROCEDURE SP_WARD_PHRM_ItemWiseWardSupplyReport
@FromDate DATE =NULL,
@ToDate DATE=NULL,
@WardId INT = NULL,
@ItemId INT =NULL
AS
-- =============================================
-- Author:		Rohit
-- Create date: 23/06/2023
-- Description: generate item wise ward supply report which shows dispatch, consumption and balance value of Ward.
-- =============================================
/* Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rohit/23Jun'23		Initial Script
*/
BEGIN

--ItemWise Ward Supply--------
SELECT store.Name 'WardName'
	,disitm.DispatchId AS IssueNo
	,disitm.DispatchedDate AS IssueDate
	,req.RequisitionNo
	,itm.ItemName
	,itm.ItemCode
	,disitm.ExpiryDate
	,disitm.BatchNo
	,dispBy.FullName AS SupplyBy
	,disitm.DispatchedQuantity
	,disitm.CostPrice
	,ROUND(disitm.DispatchedQuantity * disitm.CostPrice, 4) AS DispatchValue
	,recvBy.FullName AS ReceivedBy
	,ISNULL(consumetxn.OutQty, 0) - ISNULL(consumerettxn.InQty, 0) AS ConsumedQuantity
	,ROUND(disitm.CostPrice * (ISNULL(consumetxn.OutQty, 0) - ISNULL(consumerettxn.InQty, 0)), 4) AS ConsumedValue
	,disitm.DispatchedQuantity - ISNULL(consumetxn.OutQty, 0) AS BalanceQuantity
	,ROUND((disitm.DispatchedQuantity * disitm.CostPrice) - (disitm.CostPrice * ISNULL(consumetxn.OutQty, 0)), 4) AS BalanceValue
FROM PHRM_StoreDispatchItems disitm
INNER JOIN PHRM_StoreRequisition req ON disitm.RequisitionId = req.RequisitionId
INNER JOIN PHRM_MST_Store store ON disitm.TargetStoreId = store.StoreId
	AND store.Category = 'substore'
INNER JOIN PHRM_MST_Item itm ON disitm.ItemId = itm.ItemId
INNER JOIN EMP_Employee dispBy ON disitm.CreatedBy = dispBy.EmployeeId
LEFT JOIN EMP_Employee recvBy ON disitm.ReceivedById = recvBy.EmployeeId
INNER JOIN PHRM_TXN_StockTransaction distxn ON disitm.DispatchItemsId = distxn.ReferenceNo
	AND distxn.TransactionType = 'dispensary-dispatched-item'
LEFT JOIN (
	SELECT ItemId
		,BatchNo
		,ExpiryDate
		,StockId
		,SUM(OutQty) AS OutQty
	FROM PHRM_TXN_StockTransaction stktxn
	INNER JOIN PHRM_MST_Store s ON stktxn.StoreId = s.StoreId
		AND s.Category = 'substore'
	WHERE TransactionType = 'pat-consumption-item'
		AND InQty = 0
	GROUP BY ItemId
		,BatchNo
		,ExpiryDate
		,StockId
	) consumetxn ON distxn.ItemId = consumetxn.ItemId
	AND distxn.BatchNo = consumetxn.BatchNo
	AND distxn.ExpiryDate = consumetxn.ExpiryDate
	AND distxn.StockId = consumetxn.StockId
LEFT JOIN (
	SELECT ItemId
		,BatchNo
		,ExpiryDate
		,StockId
		,SUM(InQty) AS InQty
	FROM PHRM_TXN_StockTransaction stktxn
	INNER JOIN PHRM_MST_Store s ON stktxn.StoreId = s.StoreId
		AND s.Category = 'substore'
	WHERE TransactionType = 'ret-pat-consumption-item'AND OutQty = 0
	GROUP BY ItemId,BatchNo,ExpiryDate,StockId
	) consumerettxn ON distxn.ItemId = consumerettxn.ItemId
	AND consumetxn.BatchNo = consumerettxn.BatchNo
	AND consumetxn.ExpiryDate = consumerettxn.ExpiryDate
	AND consumetxn.StockId = consumerettxn.StockId
	WHERE (disitm.TargetStoreId =@WardId OR @WardId IS NULL)
		AND (disitm.ItemId =@ItemId OR @ItemId IS NULL)
		AND (CONVERT(DATE,disitm.DispatchedDate) BETWEEN @FromDate AND @ToDate)

--ItemWise WardSupply Summary----------
SELECT WardName
	,SUM(CASE 
			WHEN DispatchValue IS NOT NULL
				THEN DispatchValue
			ELSE 0
			END) AS DispatchValue
	,SUM(CASE 
			WHEN ConsumedValue IS NOT NULL
				THEN ConsumedValue
			ELSE 0
			END) AS ConsumedValue
	,SUM(CASE 
			WHEN BalanceValue IS NOT NULL
				THEN BalanceValue
			ELSE 0
			END) AS BalanceValue
FROM (
	SELECT store.Name 'WardName'
		,disitm.DispatchId AS IssueNo
		,disitm.DispatchedDate AS IssueDate
		,req.RequisitionNo
		,itm.ItemName
		,itm.ItemCode
		,disitm.ExpiryDate
		,disitm.BatchNo
		,dispBy.FullName AS SupplyBy
		,disitm.DispatchedQuantity
		,disitm.CostPrice
		,ROUND(disitm.DispatchedQuantity * disitm.CostPrice, 4) AS DispatchValue
		,recvBy.FullName AS ReceivedBy
		,ISNULL(consumetxn.OutQty, 0) - ISNULL(consumerettxn.InQty, 0) AS ConsumedQuantity
		,ROUND(disitm.CostPrice * (ISNULL(consumetxn.OutQty, 0) - ISNULL(consumerettxn.InQty, 0)), 4) AS ConsumedValue
		,disitm.DispatchedQuantity - ISNULL(consumetxn.OutQty, 0) AS BalanceQuantity
		,ROUND((disitm.DispatchedQuantity * disitm.CostPrice) - (disitm.CostPrice * ISNULL(consumetxn.OutQty, 0)), 4) AS BalanceValue
	FROM PHRM_StoreDispatchItems disitm
	INNER JOIN PHRM_StoreRequisition req ON disitm.RequisitionId = req.RequisitionId
	INNER JOIN PHRM_MST_Store store ON disitm.TargetStoreId = store.StoreId
		AND store.Category = 'substore'
	INNER JOIN PHRM_MST_Item itm ON disitm.ItemId = itm.ItemId
	INNER JOIN EMP_Employee dispBy ON disitm.CreatedBy = dispBy.EmployeeId
	LEFT JOIN EMP_Employee recvBy ON disitm.ReceivedById = recvBy.EmployeeId
	INNER JOIN PHRM_TXN_StockTransaction distxn ON disitm.DispatchItemsId = distxn.ReferenceNo
		AND distxn.TransactionType = 'dispensary-dispatched-item'
	LEFT JOIN (
		SELECT ItemId
			,BatchNo
			,ExpiryDate
			,StockId
			,SUM(OutQty) AS OutQty
		FROM PHRM_TXN_StockTransaction stktxn
		INNER JOIN PHRM_MST_Store s ON stktxn.StoreId = s.StoreId
			AND s.Category = 'substore'
		WHERE TransactionType = 'pat-consumption-item'AND InQty = 0
		GROUP BY ItemId,BatchNo,ExpiryDate,StockId
		) consumetxn ON distxn.ItemId = consumetxn.ItemId
		AND distxn.BatchNo = consumetxn.BatchNo
		AND distxn.ExpiryDate = consumetxn.ExpiryDate
		AND distxn.StockId = consumetxn.StockId
	LEFT JOIN (
		SELECT ItemId
			,BatchNo
			,ExpiryDate
			,StockId
			,SUM(InQty) AS InQty
		FROM PHRM_TXN_StockTransaction stktxn
		INNER JOIN PHRM_MST_Store s ON stktxn.StoreId = s.StoreId
			AND s.Category = 'substore'
		WHERE TransactionType = 'ret-pat-consumption-item'
			AND OutQty = 0
		GROUP BY ItemId
			,BatchNo
			,ExpiryDate
			,StockId
		) consumerettxn ON distxn.ItemId = consumerettxn.ItemId
		AND consumetxn.BatchNo = consumerettxn.BatchNo
		AND consumetxn.ExpiryDate = consumerettxn.ExpiryDate
		AND consumetxn.StockId = consumerettxn.StockId
		WHERE (disitm.TargetStoreId =@WardId OR @WardId IS NULL)
		AND (disitm.ItemId =@ItemId OR @ItemId IS NULL)
		AND (CONVERT(DATE,disitm.DispatchedDate) BETWEEN @FromDate AND @ToDate)
	) AS subquery
GROUP BY WardName
END