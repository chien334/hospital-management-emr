CREATE OR REPLACE FUNCTION sp_phrmreport_batchstockreport(
    p_itemname VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "SN" VARCHAR,
    "ItemId" INT,
    "BatchNo" VARCHAR,
    "ItemName" VARCHAR,
    "GenericName" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "TotalQty" INT,
    "SalePrice" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_batchstockreport"
    createdby/date: umed/2018-02-22
    description: to get the details such as itemtypename, itemcode, availableqty,expirydate,batchno, purchaserate, purchasevalue, salesrate, salesvale of each item selected by user batchwise
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2018-02-22	                 created the script
    										(to get the details such as itemtypename, itemcode, availableqty,expirydate,batchno, purchaserate, purchasevalue, salesrate, salesvale of each item selected by user batchwise)
    2       umed/2018-02-23					modified sp i.e correction in saleprice and salevalue field 
    										(previously i am getting salevale= saleqty*price but write is salevalue= availqty*price and added isnull on some attribute)
    3		rusha/2019-04-10				modify batch report showing stocks according to batchwise 
    4		vikas/2019-06-07				modify table name phrm_stocktxnitem to phrm_dispensarstock, get data from phrm_dispensarystock table
    5.		naveed/2019-12-13				updated script for exclude zero quantity items from report
    6.      rohit/13feb'23						MRP-> SalePrice
    */
    BEGIN
    	IF (p_itemname IS NOT NULL)
    	THEN
    		RETURN QUERY SELECT (
    				CAST(ROW_NUMBER() OVER (
    						ORDER BY itm.ItemName
    						) AS INT)
    				) AS "SN"
    			,stk.ItemId
    			,stk.BatchNo
    			,itm.ItemName
    			,gen.GenericName
    			,stk.ExpiryDate
    			,stk.AvailableQuantity AS "TotalQty"
    			,stk.SalePrice
    		FROM PHRM_DispensaryStock AS stk
    		JOIN PHRM_MST_Item AS itm ON stk.ItemId = itm.ItemId
    		JOIN PHRM_MST_Generic gen ON itm.GenericId = gen.GenericId
    		WHERE BatchNo LIKE '%' || COALESCE(p_itemname, '') || '%'
    			and stk.availablequantity > 0
    		group by stk.itemid
    			,stk.batchno
    			,itm.itemname
    			,stk.saleprice
    			,gen.genericname
    			,stk.expirydate
    			,stk.availablequantity;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;