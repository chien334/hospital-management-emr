CREATE OR REPLACE FUNCTION sp_monthlywisepurchaseordervsgoodsreceiptvalue(
    p_sourcestoreid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    v_datetimenow DATE := CURRENT_TIMESTAMP;
    v_datetimeoneyearbefore DATE := DATEADD(YEAR, - 1, v_datetimenow);
BEGIN
    /*
    filename: "sp_monthlywisepurchaseordervsgoodsreceiptvalue"
    createdby/date: rohit/2dec'22
    Description: To get Monthlywise Purchase Order vs GoodReceiptValue.
    Remarks:
    To Execute: Exec SP_MonthlyWisePurchaseOrdervsGoodsReceiptValue null
    NOTE:  
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       ROHIT/2Dec'22						created
    2		rohit/7dec'22						Round off the value up to 3 decimal
    
    */
    
    	
    	
    
    	OPEN ref1 FOR SELECT purchase.TxnDisplayDate
    		,PurchaseValue
    		,GoodsReceiptValue
    		,TotalDispatchValue
    	FROM (
    		SELECT ((EXTRACT(YEAR FROM PoDate))::VARCHAR || '-' || (EXTRACT(MONTH FROM PoDate))::VARCHAR || '-01')::TIMESTAMP AS TxnDate
    			,to_char(PoDate, 'yyyy') || '-' || SUBSTRING(trim(to_char(PoDate, 'month')), 1, 3) AS TxnDisplayDate
    			,ROUND(COALESCE(SUM(TotalAmount), 0),3) AS PurchaseValue
    		FROM INV_TXN_PurchaseOrder
    		WHERE COALESCE(POStatus, 'cancelled') IN (
    				'active'
    				,'complete'
    				)
    			AND (
    				StoreId = p_sourcestoreid
    				OR p_sourcestoreid IS NULL
    				)
    			AND (PoDate)::TIMESTAMP >= v_datetimeoneyearbefore
    		GROUP BY ((EXTRACT(YEAR FROM PoDate))::VARCHAR || '-' || (EXTRACT(MONTH FROM PoDate))::VARCHAR || '-01')::TIMESTAMP
    			,to_char(PoDate, 'yyyy') || '-' || SUBSTRING(trim(to_char(PoDate, 'month')), 1, 3)
    		) purchase
    	LEFT JOIN (
    		SELECT ((EXTRACT(YEAR FROM GoodsReceiptDate))::VARCHAR || '-' || (EXTRACT(MONTH FROM GoodsReceiptDate))::VARCHAR || '-01')::TIMESTAMP AS "TxnDate"
    			,to_char(GoodsReceiptDate, 'yyyy') || '-' || SUBSTRING(trim(to_char(GoodsReceiptDate, 'month')), 1, 3) AS TxnDisplayDate
    			,ROUND(COALESCE(SUM(TotalAmount), 0),3) AS GoodsReceiptValue
    		FROM INV_TXN_GoodsReceipt
    		WHERE ReceivedBy IS NOT NULL
    			AND GRStatus != 'cancelled'
    			AND (
    				StoreId = p_sourcestoreid
    				OR p_sourcestoreid IS NULL
    				)
    			AND (GoodsReceiptDate)::TIMESTAMP >= v_datetimeoneyearbefore
    		GROUP BY ((EXTRACT(YEAR FROM GoodsReceiptDate))::VARCHAR || '-' || (EXTRACT(MONTH FROM GoodsReceiptDate))::VARCHAR || '-01')::TIMESTAMP
    			,to_char(GoodsReceiptDate, 'yyyy') || '-' || SUBSTRING(trim(to_char(GoodsReceiptDate, 'month')), 1, 3)
    		) goodReceipt ON purchase.TxnDate = goodReceipt.TxnDate
    		AND purchase.TxnDisplayDate = goodReceipt.TxnDisplayDate
    	LEFT JOIN (
    		SELECT ((EXTRACT(YEAR FROM DispatchedDate))::VARCHAR || '-' || (EXTRACT(MONTH FROM DispatchedDate))::VARCHAR || '-01')::TIMESTAMP AS "TxnDate"
    			,to_char(DispatchedDate, 'yyyy') || '-' || SUBSTRING(trim(to_char(DispatchedDate, 'month')), 1, 3) AS TxnDisplayDate
    			,ROUND(COALESCE(SUM(DispatchedQuantity * CostPrice), 0),3) AS TotalDispatchValue
    		FROM INV_TXN_DispatchItems
    		WHERE (
    				SourceStoreId = p_sourcestoreid
    				OR p_sourcestoreid IS NULL
    				)
    			AND (DispatchedDate)::TIMESTAMP >= v_datetimeoneyearbefore
    		GROUP BY ((EXTRACT(YEAR FROM DispatchedDate))::VARCHAR || '-' || (EXTRACT(MONTH FROM DispatchedDate))::VARCHAR || '-01')::TIMESTAMP
    			,to_char(DispatchedDate, 'yyyy') || '-' || SUBSTRING(trim(to_char(DispatchedDate, 'month')), 1, 3)
    		) dispatch on goodreceipt.txndate = dispatch.txndate
    		and goodreceipt.txndisplaydate = dispatch.txndisplaydate
    	order by purchase.txndate;
        return next ref1;
END;
$$ LANGUAGE plpgsql;