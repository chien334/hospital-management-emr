CREATE OR REPLACE FUNCTION phrm_rpt_stocksummary2(
    p_tilldate DATE DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    -- =============================================
    -- author:		sanjit
    -- create date: 18/06/2021
    -- description: generated stock summary (2nd) report
    -- example : execute phrm_rpt_stocksummary2 '2021-06-20'
    -- =============================================
    /* change history
    s.no.    updatedby/date                        remarks
    1.		sanjit/02/09/2021		converted timestamp to date for p_tilldate
    2        rohit/13feb'23						MRP-> SalePrice
    */
    
    	-- body of the stored procedure
    	OPEN ref1 FOR SELECT store.Name AS StoreName
    		,stxn.PurchaseValue
    		,stxn.SalesValue
    	FROM PHRM_MST_Store store
    	LEFT JOIN (
    		SELECT str.StoreId
    			,(SUM(COALESCE(stxn.InQty, 0) * COALESCE(stxn.CostPrice, 0)) - sum(COALESCE(stxn.OutQty, 0) * COALESCE(stxn.CostPrice, 0)))::MONEY AS "PurchaseValue"
    			,(SUM(COALESCE(stxn.InQty, 0) * COALESCE(stxn.SalePrice, 0)) - sum(COALESCE(stxn.OutQty, 0) * COALESCE(stxn.SalePrice, 0)))::MONEY AS "SalesValue"
    		FROM PHRM_TXN_StockTransaction stxn
    		JOIN PHRM_MST_Store str ON stxn.StoreId = str.StoreId
    		JOIN PHRM_MST_Item itm ON itm.ItemId = stxn.ItemId
    		WHERE COALESCE(stxn.IsActive, 0) = 1
    			AND (stxn.TransactionDate)::DATE < p_tilldate
    		GROUP BY str.StoreId
    		) stxn ON store.StoreId = stxn.StoreId
    	WHERE store.Category IN ('dispensary')
    		OR store.SubCategory = 'pharmacy'
    	
    	UNION
    	
    	SELECT 'total' as storename
    		,stxn.purchasevalue
    		,stxn.salesvalue
    	from (
    		select (sum(coalesce(stxn.inqty, 0) * coalesce(stxn.costprice, 0)) - sum(coalesce(stxn.outqty, 0) * coalesce(stxn.costprice, 0)))::money as "purchasevalue"
    			,(sum(coalesce(stxn.inqty, 0) * coalesce(stxn.saleprice, 0)) - sum(coalesce(stxn.outqty, 0) * coalesce(stxn.saleprice, 0)))::money as "salesvalue"
    		from phrm_txn_stocktransaction stxn
    		where coalesce(stxn.isactive, 0) = 1
    			and (stxn.transactiondate)::date < p_tilldate
    		) stxn;
        return next ref1;
END;
$$ LANGUAGE plpgsql;