CREATE OR REPLACE FUNCTION sp_phrm_rpt_getstocksummary(
    p_fiscalyearid INT,
    p_fromdate DATE,
    p_todate DATE,
    p_storeid INT
)
RETURNS TABLE (
    "StockId" INT,
    "StoreId" INT,
    "StoreName" VARCHAR,
    "ItemId" INT,
    "GenericName" VARCHAR,
    "ItemName" VARCHAR,
    "ItemCode" VARCHAR,
    "UOMName" VARCHAR,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "CostPrice" DECIMAL,
    "SalePrice" DECIMAL,
    "OpeningQty" INT,
    "OpeningValue" DECIMAL,
    "OpeningQty_WithProvisional" TIMESTAMP,
    "OpeningValue_WithProvisional" TIMESTAMP,
    "PurchaseQty" INT,
    "PurchaseValue" DECIMAL,
    "PurchaseReturnQty" INT,
    "PurchaseReturnValue" DECIMAL,
    "SalesQty" INT,
    "SalesValue" DECIMAL,
    "SaleReturnQty" INT,
    "SaleReturnValue" DECIMAL,
    "ProvisionalQty" TIMESTAMP,
    "ProvisionalValue" TIMESTAMP,
    "WriteOffQty" INT,
    "WriteOffValue" DECIMAL,
    "ConsumptionQty" TIMESTAMP,
    "ConsumptionValue" TIMESTAMP,
    "StockManageOutQty" INT,
    "StockManageOutValue" DECIMAL,
    "StockManageInQty" INT,
    "StockManageInValue" DECIMAL,
    "TransferInQty" INT,
    "TransferInValue" DECIMAL,
    "TransferOutQty" INT,
    "TransferOutValue" DECIMAL,
    "ClosingQty_WithProvisional" TIMESTAMP,
    "ClosingValue_WithProvisional" TIMESTAMP,
    "ClosingQty" INT,
    "ClosingValue" DECIMAL
) AS $$
DECLARE
    v_fystartdate DATE := (
			SELECT  (StartDate)::DATE
			FROM PHRM_CFG_FiscalYears
			WHERE FiscalYearId = p_fiscalyearid LIMIT 1
			);
    v_closingdate DATE := DATEADD(DAY, - 1, p_fromdate);
BEGIN
    /************************************************************************
    filename: "sp_phrm_rpt_getstocksummary" 4, '
    CreatedBy/date: Sanjit/15Jun21
    Description: Get Pharmacy stock summary report data
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       Sanjit/15Jun21						script created 
    2		Sanjit/21Jul21						all amount rounded to two decimal point
    3       Ramesh/10Aug'21                     store wise filter added
    4		sanjit/sud/30aug'21					a. Added calculation for Stock Transfers. 
    											b. used new function to get closing on previous day
    5.      Sud:12Jul'22                        corrected closing formula for withprovisional
    6.       rohit/13feb'23						MRP-> SalePrice
    *************************************************************************/
    
    	
    	 -- Closing should be calculated on Previous Day
    
    	RETURN QUERY SELECT stkMaster.StockId
    		,store.StoreId
    		,store.Name AS "StoreName"
    		,I.ItemId
    		,G.GenericName
    		,I.ItemName
    		,I.ItemCode
    		,U.UOMName
    		,stkMaster.BatchNo
    		,stkMaster.ExpiryDate
    		,stkMaster.CostPrice
    		,stkMaster.SalePrice
    		,SUM(COALESCE(prevDayClosing.ClosingQty, 0)) AS "OpeningQty"
    		,ROUND(SUM(COALESCE(prevDayClosing.ClosingValue, 0)), 2) AS "OpeningValue"
    		,SUM(COALESCE(prevDayClosing.ClosingQty_WithProvisional, 0)) AS "OpeningQty_WithProvisional"
    		,ROUND(SUM(COALESCE(prevDayClosing.ClosingValue_WithProvisional, 0)), 2) AS "OpeningValue_WithProvisional"
    		,SUM(COALESCE(txnsBetnRange.PurchaseQty, 0)) AS "PurchaseQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.PurchaseValue, 0)), 2) AS "PurchaseValue"
    		,SUM(COALESCE(txnsBetnRange.PurchaseReturnQty, 0)) AS "PurchaseReturnQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.PurchaseReturnValue, 0)), 2) AS "PurchaseReturnValue"
    		,SUM(COALESCE(txnsBetnRange.SalesQty, 0)) AS "SalesQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.SalesValue, 0)), 2) AS "SalesValue"
    		,SUM(COALESCE(txnsBetnRange.SalesReturnQty, 0)) AS "SaleReturnQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.SalesReturnValue, 0)), 2) AS "SaleReturnValue"
    		,SUM(COALESCE(txnsBetnRange.ProvisionalQty, 0)) AS "ProvisionalQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.ProvisionalValue, 0)), 2) AS "ProvisionalValue"
    		,SUM(COALESCE(txnsBetnRange.WriteOffQty, 0)) AS "WriteOffQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.WriteOffValue, 0)), 2) AS "WriteOffValue"
    		,SUM(COALESCE(txnsBetnRange.ConsumptionQty, 0)) AS "ConsumptionQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.ConsumptionValue, 0)), 2) AS "ConsumptionValue"
    		,SUM(COALESCE(txnsBetnRange.StockManageOutQty, 0)) AS "StockManageOutQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.StockManageOutValue, 0)), 2) AS "StockManageOutValue"
    		,SUM(COALESCE(txnsBetnRange.StockManageInQty, 0)) AS "StockManageInQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.StockManageInValue, 0)), 2) AS "StockManageInValue"
    		,SUM(COALESCE(txnsBetnRange.TransferInQty, 0)) AS "TransferInQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.TransferInValue, 0)), 2) AS "TransferInValue"
    		,SUM(COALESCE(txnsBetnRange.TransferOutQty, 0)) AS "TransferOutQty"
    		,ROUND(SUM(COALESCE(txnsBetnRange.TransferOutValue, 0)), 2) AS "TransferOutValue"
    		,SUM(COALESCE(prevDayClosing.ClosingQty_WithProvisional, 0)) + SUM(COALESCE(txnsBetnRange.PurchaseQty, 0)) - SUM(COALESCE(txnsBetnRange.PurchaseReturnQty, 0)) - SUM(COALESCE(txnsBetnRange.SalesQty, 0)) + SUM(COALESCE(txnsBetnRange.SalesReturnQty, 0)) - SUM(COALESCE(txnsBetnRange.ProvisionalQty, 0)) - SUM(COALESCE(txnsBetnRange.WriteOffQty, 0)) - SUM(COALESCE(txnsBetnRange.ConsumptionQty, 0)) || SUM(COALESCE(txnsBetnRange.StockManageInQty, 0)) - SUM(COALESCE(txnsBetnRange.StockManageOutQty, 0)) || SUM(COALESCE(txnsBetnRange.TransferInQty, 0)) - SUM(COALESCE(txnsBetnRange.TransferOutQty, 0)) AS "ClosingQty_WithProvisional"
    		,ROUND(SUM(COALESCE(prevDayClosing.ClosingValue_WithProvisional, 0)) + SUM(COALESCE(txnsBetnRange.PurchaseValue, 0)) - SUM(COALESCE(txnsBetnRange.PurchaseReturnValue, 0)) - SUM(COALESCE(txnsBetnRange.SalesValue, 0)) + SUM(COALESCE(txnsBetnRange.SalesReturnValue, 0)) - SUM(COALESCE(txnsBetnRange.ProvisionalValue, 0)) - SUM(COALESCE(txnsBetnRange.WriteOffValue, 0)) - SUM(COALESCE(txnsBetnRange.ConsumptionValue, 0)) || SUM(COALESCE(txnsBetnRange.StockManageInValue, 0)) - SUM(COALESCE(txnsBetnRange.StockManageOutValue, 0)) || SUM(COALESCE(txnsBetnRange.TransferInValue, 0)) - SUM(COALESCE(txnsBetnRange.TransferOutValue, 0)), 2) AS "ClosingValue_WithProvisional"
    		,SUM(COALESCE(prevDayClosing.ClosingQty, 0)) + SUM(COALESCE(txnsBetnRange.PurchaseQty, 0)) - SUM(COALESCE(txnsBetnRange.PurchaseReturnQty, 0)) - SUM(COALESCE(txnsBetnRange.SalesQty, 0)) + SUM(COALESCE(txnsBetnRange.SalesReturnQty, 0)) - SUM(COALESCE(txnsBetnRange.WriteOffQty, 0)) - SUM(COALESCE(txnsBetnRange.ConsumptionQty, 0)) || SUM(COALESCE(txnsBetnRange.StockManageInQty, 0)) - SUM(COALESCE(txnsBetnRange.StockManageOutQty, 0)) || SUM(COALESCE(txnsBetnRange.TransferInQty, 0)) - SUM(COALESCE(txnsBetnRange.TransferOutQty, 0)) AS "ClosingQty"
    		,ROUND(SUM(COALESCE(prevDayClosing.ClosingValue, 0)) + SUM(COALESCE(txnsBetnRange.PurchaseValue, 0)) - SUM(COALESCE(txnsBetnRange.PurchaseReturnValue, 0)) - SUM(COALESCE(txnsBetnRange.SalesValue, 0)) + SUM(COALESCE(txnsBetnRange.SalesReturnValue, 0)) - SUM(COALESCE(txnsBetnRange.WriteOffValue, 0)) - SUM(COALESCE(txnsBetnRange.ConsumptionValue, 0)) || SUM(COALESCE(txnsBetnRange.StockManageInValue, 0)) - SUM(COALESCE(txnsBetnRange.StockManageOutValue, 0)) || SUM(COALESCE(txnsBetnRange.TransferInValue, 0)) - SUM(COALESCE(txnsBetnRange.TransferOutValue, 0)), 2) AS "ClosingValue"
    	FROM PHRM_MST_Item I
    	INNER JOIN PHRM_MST_Generic G ON I.GenericId = G.GenericId
    	INNER JOIN PHRM_MST_UnitOfMeasurement U ON I.UOMId = U.UOMId
    	INNER JOIN PHRM_MST_Stock stkMaster ON I.ItemId = stkMaster.ItemId
    	INNER JOIN PHRM_MST_Store store ON store.Category IN ('dispensary')
    		OR store.SubCategory = 'pharmacy'
    	--for prevdayclosing part, we take closing from previous day as opening for today.
    	left join (
    		select *
    		from fn_rpt_phrm_getclosingstockdetailsongivendate(p_fiscalyearid, v_fystartdate, v_closingdate)
    		) prevdayclosing on prevdayclosing.stockid = stkmaster.stockid
    		and store.storeid = prevdayclosing.storeid
    	--for current year part
    	left join (
    		select *
    		from "fn_rpt_phrm_getitemstocktxnsbetndaterange"(p_fromdate, p_todate)
    		) txnsbetnrange on stkmaster.stockid = txnsbetnrange.stockid
    		and store.storeid = txnsbetnrange.storeid
    	--> if p_storeid is null, then show stocks of all stores, else show stocks of given store
    	where (
    			store.storeid = p_storeid
    			or p_storeid is null
    			)
    	group by stkmaster.stockid
    		,store.storeid
    		,store.name
    		,i.itemid
    		,g.genericname
    		,i.itemname
    		,i.itemcode
    		,u.uomname
    		,stkmaster.batchno
    		,stkmaster.expirydate
    		,stkmaster.costprice
    		,stkmaster.saleprice
    	order by i.itemname
    		,store.storeid;
END;
$$ LANGUAGE plpgsql;