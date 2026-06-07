CREATE OR REPLACE FUNCTION phrm_rpt_salesstatementreport(
    p_fromdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    p_todate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
RETURNS TABLE (
    "Name" VARCHAR,
    "SalesValue" DECIMAL,
    "SalesCostValue" DECIMAL,
    "SalesReturnValue" DECIMAL,
    "SalesReturnCostValue" DECIMAL,
    "Balance" DECIMAL
) AS $$
BEGIN
    -- =============================================
    -- author:		sanjit
    -- create date: 17/06/2021
    -- description: generated sales statement report
    -- =============================================
    /* change history
    s.no.    updatedby/date                        remarks
    1.       sanjit/ramesh/26thjuly'21           total amount mismatch corrected
    2.		 Rohit/25Jul'22						 date is converted
    3        rohit/13feb'23						MRP-> SalePrice
    */
    
    	-- body of the stored procedure
    	RETURN QUERY SELECT str.Name
    		,(SUM(COALESCE(stk.OutQty, 0) * COALESCE(stk.SalePrice, 0)))::MONEY AS "SalesValue"
    		,(SUM(COALESCE(stk.OutQty, 0) * COALESCE(stk.CostPrice, 0)))::MONEY AS "SalesCostValue"
    		,(SUM(COALESCE(Stk.InQty, 0) * COALESCE(stk.SalePrice, 0)))::MONEY AS "SalesReturnValue"
    		,(SUM(COALESCE(Stk.InQty, 0) * COALESCE(Stk.CostPrice, 0)))::MONEY AS "SalesReturnCostValue"
    		,((SUM(COALESCE(stk.OutQty, 0) * COALESCE(stk.SalePrice, 0)))::MONEY - (SUM(COALESCE(stk.OutQty, 0) * COALESCE(stk.CostPrice, 0)))::MONEY) - ((SUM(COALESCE(stk.InQty, 0) * COALESCE(stk.SalePrice, 0)))::MONEY - (SUM(COALESCE(Stk.InQty, 0) * COALESCE(Stk.CostPrice, 0)))::MONEY) AS "Balance"
    	FROM PHRM_TXN_StockTransaction stk
    	INNER JOIN PHRM_MST_Store str ON str.StoreId = stk.StoreId
    	WHERE stk.IsActive = 1
    		AND stk.TransactionType IN (
    			'sale-item'
    			,'sale-returned-item'
    			,'manual-sales-return'
    			,'provisional-sale-item'
    			,'provisiona-cancel-item'
    			)
    		AND (stk.CreatedOn)::DATE BETWEEN p_fromdate
    			AND p_todate
    	GROUP BY stk.StoreId
    		,str.Name
    	
    	UNION
    	
    	SELECT 'total'
    		,(SUM(COALESCE(stk.OutQty, 0) * COALESCE(stk.SalePrice, 0)))::MONEY AS "SalesValue"
    		,(SUM(COALESCE(stk.OutQty, 0) * COALESCE(stk.CostPrice, 0)))::MONEY AS "SalesCostValue"
    		,(SUM(COALESCE(Stk.InQty, 0) * COALESCE(stk.SalePrice, 0)))::MONEY AS "SalesReturnValue"
    		,(SUM(COALESCE(Stk.InQty, 0) * COALESCE(Stk.CostPrice, 0)))::MONEY AS "SalesReturnCostValue"
    		,(SUM(COALESCE(stk.OutQty, 0) * COALESCE(stk.SalePrice, 0)))::MONEY - (SUM(COALESCE(stk.OutQty, 0) * COALESCE(stk.CostPrice, 0)))::MONEY - ((SUM(COALESCE(stk.InQty, 0) * COALESCE(stk.SalePrice, 0)))::MONEY - (SUM(COALESCE(Stk.InQty, 0) * COALESCE(Stk.CostPrice, 0)))::MONEY) AS "Balance"
    	FROM PHRM_TXN_StockTransaction stk
    	INNER JOIN PHRM_MST_Store str ON str.StoreId = stk.StoreId
    	WHERE stk.IsActive = 1
    		AND stk.TransactionType IN (
    			'sale-item'
    			,'sale-returned-item'
    			,'manual-sales-return'
    			,'provisional-sale-item'
    			,'provisiona-cancel-item'
    			)
    		and (stk.createdon)::date between p_fromdate
    			and p_todate;
END;
$$ LANGUAGE plpgsql;