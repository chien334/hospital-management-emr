CREATE OR REPLACE FUNCTION sp_inctv_viewtxn_invoiceitemlevel(
    p_billingtansactionid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
     file: sp_inctv_viewtxn_invoiceitemlevel
     description: to get transaction item level details and fraction info
     remarks: we're returning 2 tables from here
     Change History:
     S.No.    ChangeDate/By					Remarks
     1.      24Jan'20/pratik          initial draft (needs revision)
     2.      16feb'20/Sud			  Rewrite after change in logic.. 
     3.      11June2020/Pratik		  GroupDistribution Impacts on Existing Functionalities 
     4.      14Aug2023/Nirmala        Fetch ServiceItemId And IntegrationItemId
     5.		 22ndSept'23/krishna	  read pricecategory 
    */
    
    	--table:1 -- get billingtransactionitem information---
    	OPEN ref1 FOR SELECT 
    	    itms."PatientId",
    		itms."BillingTransactionItemId",
    		itms."BillingTransactionId",
    		itms."IntegrationItemId",
    		itms."ItemName",
    		itms."Quantity",
    		itms."Price",
    		itms."SubTotal",
    		itms."DiscountAmount",
    		itms."TotalAmount",
    		itms."ServiceItemId",
    		pricecat."PriceCategoryId",
    		pricecat."PriceCategoryName"
    	FROM (
    	    SELECT 
    	        "PatientId",
    	        "BillingTransactionItemId",
    	        "BillingTransactionId", 
    	        "IntegrationItemId", 
    	        "ItemName", 
    	        "Quantity",
    			"Price", 
    			"SubTotal", 
    			"DiscountAmount", 
    			"TotalAmount", 
    			"ServiceItemId", 
    			"PriceCategoryId"
    		FROM "BIL_TXN_BillingTransactionItems"
    	    WHERE "BillingTransactionId" = p_billingtansactionid
    	) itms
    	INNER JOIN "BIL_CFG_PriceCategory" pricecat ON itms."PriceCategoryId" = pricecat."PriceCategoryId";
        RETURN NEXT ref1;
    
    	--table:2 -- get fraction information---
    	OPEN ref2 FOR SELECT *
    	FROM "INCTV_TXN_IncentiveFractionItem"
    	WHERE "BillingTransactionId" = p_billingtansactionid;
        RETURN NEXT ref2;
END;
$$ LANGUAGE plpgsql;