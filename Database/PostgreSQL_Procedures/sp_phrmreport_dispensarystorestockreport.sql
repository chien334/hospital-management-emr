CREATE OR REPLACE FUNCTION sp_phrmreport_dispensarystorestockreport(
    p_status VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "ItemName" VARCHAR,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "SalePrice" DECIMAL,
    "StockQty" INT,
    "StoreName" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_dispensarystorestockreport"
    createdby/date: rusha/2019-04-10
    description: to get the stock value of both dispensary and store wise
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.       rusha/06-11-2019						updated script for dispensary and store stock item
    2.		 naveed/13-12-2019						updated script for exclude zero quantity items from report
    3.       sanjit/11-06-2021                      updated script to handle stock redesign. script uses same table for dispensary and store
    4.       rohit/13feb'23						    MRP-> SalePrice
    */
    
    	RETURN QUERY SELECT I.ItemName
    		,S.BatchNo
    		,S.ExpiryDate
    		,S.SalePrice
    		,SUM(SS.AvailableQuantity) AS "StockQty"
    		,STR.Name AS "StoreName"
    	FROM PHRM_TXN_StoreStock SS
    	INNER JOIN PHRM_MST_Stock S ON SS.StockId = S.StockId
    	INNER JOIN PHRM_MST_Item I ON SS.ItemId = I.ItemId
    	INNER JOIN PHRM_MST_Store STR ON SS.StoreId = STR.StoreId
    	WHERE SS.AvailableQuantity > 0
    		AND (
    			p_status = 'all'
    			OR (
    				p_status = 'store'
    				AND STR.Category = 'store'
    				)
    			OR (
    				p_status = 'dispensary'
    				AND STR.Category = 'dispensary'
    				)
    			)
    	group by ss.itemid
    		,i.itemname
    		,s.batchno
    		,s.expirydate
    		,s.saleprice
    		,str.name;
END;
$$ LANGUAGE plpgsql;