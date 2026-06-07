CREATE OR REPLACE FUNCTION sp_ward_phrm_itemwisewardsupplyreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_wardid INT DEFAULT NULL,
    p_itemid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    -- =============================================
    -- author:		rohit
    -- create date: 23/06/2023
    -- description: generate item wise ward supply report which shows dispatch, consumption and balance value of ward.
    -- =============================================
    /* change history
    s.no.    updatedby/date                        remarks
    1.		rohit/23jun'23		Initial Script
    */
    
    
    --ItemWise Ward Supply--------
    OPEN ref1 FOR SELECT store.Name AS "WardName"
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
    	,COALESCE(consumetxn.OutQty, 0) - COALESCE(consumerettxn.InQty, 0) AS ConsumedQuantity
    	,ROUND(disitm.CostPrice * (COALESCE(consumetxn.OutQty, 0) - COALESCE(consumerettxn.InQty, 0)), 4) AS ConsumedValue
    	,disitm.DispatchedQuantity - COALESCE(consumetxn.OutQty, 0) AS BalanceQuantity
    	,ROUND((disitm.DispatchedQuantity * disitm.CostPrice) - (disitm.CostPrice * COALESCE(consumetxn.OutQty, 0)), 4) AS BalanceValue
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
    	WHERE (disitm.TargetStoreId =p_wardid OR p_wardid IS NULL)
    		AND (disitm.ItemId =p_itemid OR p_itemid IS NULL)
    		AND ((disitm.DispatchedDate)::DATE BETWEEN p_fromdate AND p_todate);
        RETURN NEXT ref1;
    
    --ItemWise WardSupply Summary----------
    OPEN ref2 FOR SELECT WardName
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
    	SELECT store.Name AS "WardName"
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
    		,COALESCE(consumetxn.OutQty, 0) - COALESCE(consumerettxn.InQty, 0) AS ConsumedQuantity
    		,ROUND(disitm.CostPrice * (COALESCE(consumetxn.OutQty, 0) - COALESCE(consumerettxn.InQty, 0)), 4) AS ConsumedValue
    		,disitm.DispatchedQuantity - COALESCE(consumetxn.OutQty, 0) AS BalanceQuantity
    		,ROUND((disitm.DispatchedQuantity * disitm.CostPrice) - (disitm.CostPrice * COALESCE(consumetxn.OutQty, 0)), 4) AS BalanceValue
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
    			and outqty = 0
    		group by itemid
    			,batchno
    			,expirydate
    			,stockid
    		) consumerettxn on distxn.itemid = consumerettxn.itemid
    		and consumetxn.batchno = consumerettxn.batchno
    		and consumetxn.expirydate = consumerettxn.expirydate
    		and consumetxn.stockid = consumerettxn.stockid
    		where (disitm.targetstoreid =p_wardid or p_wardid is null)
    		and (disitm.itemid =p_itemid or p_itemid is null)
    		and ((disitm.dispatcheddate)::date between p_fromdate and p_todate)
    	) as subquery
    group by wardname;
        return next ref2;
END;
$$ LANGUAGE plpgsql;