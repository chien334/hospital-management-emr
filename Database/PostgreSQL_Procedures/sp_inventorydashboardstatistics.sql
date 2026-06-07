CREATE OR REPLACE FUNCTION sp_inventorydashboardstatistics(
    p_sourcestoreid INT DEFAULT NULL
)
RETURNS TABLE (
    "TotalPurchaseRequestQuantity" INT,
    "TotalPurchaseRequestQuantityToday" INT,
    "TotalPurchaseRequestQuantityYesterday" INT,
    "TotalPurchaseOrderQuantity" INT,
    "TotalPurchaseOrderQuantityToday" INT,
    "TotalPurchaseOrderQuantityYesterday" INT,
    "TotalGoodReceiptQuantity" INT,
    "TotalGoodReceiptQuantityToday" INT,
    "TotalGoodReceiptQuantityYesterday" INT,
    "TotalDispatchQuantity" INT,
    "TotalDispatchQuantityToday" INT,
    "TotalDispatchQuantityYesterday" INT
) AS $$
BEGIN
    /*
    filename: "sp_inventorydashboardstatistics"
    createdby/date: rohit/2dec'22
    Description: to get dashboard statistics of the home dashboards. these are used to fill labels.
    Remarks:  
    NOTE:  
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       ROHIT/2Dec'22               created
    2.		rohit/13dec'22				ReceivedBy Not Null is checked for GoodReceipt
    */
    
    	RETURN QUERY SELECT TotalPurchaseRequestQuantity
    		,TotalPurchaseRequestQuantityToday
    		,TotalPurchaseRequestQuantityYesterday
    		,TotalPurchaseOrderQuantity
    		,TotalPurchaseOrderQuantityToday
    		,TotalPurchaseOrderQuantityYesterday
    		,TotalGoodReceiptQuantity
    		,TotalGoodReceiptQuantityToday
    		,TotalGoodReceiptQuantityYesterday
    		,TotalDispatchQuantity
    		,TotalDispatchQuantityToday
    		,TotalDispatchQuantityYesterday
    	FROM (
    		SELECT ROUND(COALESCE(SUM(pri.RequestedQuantity), 0), 3) AS "TotalPurchaseRequestQuantity"
    		FROM INV_TXN_PurchaseRequest pr
    		INNER JOIN INV_TXN_PurchaseRequestItems pri ON pr.PurchaseRequestId = pri.PurchaseRequestId
    		WHERE (
    				pr.StoreId = p_sourcestoreid
    				OR p_sourcestoreid IS NULL
    				)
    				AND pr.RequestStatus != 'withdrawn'
    		) pr_Total
    		,(
    			SELECT ROUND(COALESCE(SUM(pri.RequestedQuantity), 0), 3) AS "TotalPurchaseRequestQuantityToday"
    			FROM INV_TXN_PurchaseRequest pr
    			INNER JOIN INV_TXN_PurchaseRequestItems pri ON pr.PurchaseRequestId = pri.PurchaseRequestId
    			WHERE (
    					pr.StoreId = p_sourcestoreid
    					OR p_sourcestoreid IS NULL
    					)
    					AND pr.RequestStatus != 'withdrawn'
    				AND (pr.RequestDate)::DATE = (CURRENT_TIMESTAMP)::DATE
    			) pr_Today
    		,(
    			SELECT ROUND(COALESCE(SUM(pri.RequestedQuantity), 0), 3) AS "TotalPurchaseRequestQuantityYesterday"
    			FROM INV_TXN_PurchaseRequest pr
    			INNER JOIN INV_TXN_PurchaseRequestItems pri ON pr.PurchaseRequestId = pri.PurchaseRequestId
    			WHERE (
    					pr.StoreId = p_sourcestoreid
    					OR p_sourcestoreid IS NULL
    					)
    					AND pr.RequestStatus != 'withdrawn'
    				and (pr.requestdate)::date = dateadd(day, - 1, (current_timestamp)::date)
    			) pr_yesterday
    		,(
    			select round(coalesce(sum(poi.quantity), 0), 3) AS "TotalPurchaseOrderQuantity"
    			from inv_txn_purchaseorder po
    			inner join inv_txn_purchaseorderitems poi on po.purchaseorderid = poi.purchaseorderid
    			where poi.isactive != 0
    				and (
    					storeid = p_sourcestoreid
    					or p_sourcestoreid is null
    					)
    			) po
    		,(
    			select round(coalesce(sum(poi.quantity), 0), 3) AS "TotalPurchaseOrderQuantityToday"
    			from inv_txn_purchaseorder po
    			inner join inv_txn_purchaseorderitems poi on po.purchaseorderid = poi.purchaseorderid
    			where poi.isactive != 0
    				and (po.createdon)::date = (current_timestamp)::date
    				and (
    					storeid = p_sourcestoreid
    					or p_sourcestoreid is null
    					)
    			) po_today
    		,(
    			select round(coalesce(sum(poi.quantity), 0), 3) AS "TotalPurchaseOrderQuantityYesterday"
    			from inv_txn_purchaseorder po
    			inner join inv_txn_purchaseorderitems poi on po.purchaseorderid = poi.purchaseorderid
    			where poi.isactive != 0
    				and (po.createdon)::date = dateadd(day, - 1, (current_timestamp)::date)
    				and (
    					storeid = p_sourcestoreid
    					or p_sourcestoreid is null
    					)
    			) po_yesterday
    		,(
    			select round(coalesce(sum(gri.receivedquantity + gri.freequantity), 0), 3) AS "TotalGoodReceiptQuantity"
    			from inv_txn_goodsreceipt gr
    			inner join inv_txn_goodsreceiptitems gri on gr.goodsreceiptid = gri.goodsreceiptid
    			where gri.isactive != 0 and gr.receivedby is not null
    			and gr.iscancel!=1
    				and (
    					storeid = p_sourcestoreid
    					or p_sourcestoreid is null
    					)
    			) gr
    		,(
    			select round(coalesce(sum(gri.receivedquantity + gri.freequantity), 0), 3) AS "TotalGoodReceiptQuantityToday"
    			from inv_txn_goodsreceipt gr
    			inner join inv_txn_goodsreceiptitems gri on gr.goodsreceiptid = gri.goodsreceiptid
    			where gri.isactive != 0 and gr.receivedby is not null
    				and gr.iscancel!=1
    				and (gr.receivedon)::date = (current_timestamp)::date
    				and (
    					storeid = p_sourcestoreid
    					or p_sourcestoreid is null
    					)
    			) gr_today
    		,(
    			select round(coalesce(sum(gri.receivedquantity + gri.freequantity), 0), 3) AS "TotalGoodReceiptQuantityYesterday"
    			from inv_txn_goodsreceipt gr
    			inner join inv_txn_goodsreceiptitems gri on gr.goodsreceiptid = gri.goodsreceiptid
    			where gri.isactive != 0 and gr.receivedby is not null
    				and gr.iscancel!=1
    				and (gr.receivedon)::date = dateadd(day, - 1, (current_timestamp)::date)
    				and (
    					storeid = p_sourcestoreid
    					or p_sourcestoreid is null
    					)
    			) gr_yesterday
    		,(
    			select round(coalesce(sum(di.dispatchedquantity), 0), 3) AS "TotalDispatchQuantity"
    			from inv_txn_dispatchitems di
    			where (
    					sourcestoreid = p_sourcestoreid
    					or p_sourcestoreid is null
    					)
    			) dispatch
    		,(
    			select round(coalesce(sum(di.dispatchedquantity), 0), 3) AS "TotalDispatchQuantityToday"
    			from inv_txn_dispatchitems di
    			where (
    					sourcestoreid = p_sourcestoreid
    					or p_sourcestoreid is null
    					)
    				and (dispatcheddate)::date = (current_timestamp)::date
    			) dispatch_today
    		,(
    			select round(coalesce(sum(di.dispatchedquantity), 0), 3) AS "TotalDispatchQuantityYesterday"
    			from inv_txn_dispatchitems di
    			where (
    					sourcestoreid = p_sourcestoreid
    					or p_sourcestoreid is null
    					)
    				and (dispatcheddate)::date = dateadd(day, - 1, (current_timestamp)::date)
    			) dispatch_yesterday;
END;
$$ LANGUAGE plpgsql;