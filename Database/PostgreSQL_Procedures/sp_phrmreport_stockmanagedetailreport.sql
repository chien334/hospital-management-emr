CREATE OR REPLACE FUNCTION sp_phrmreport_stockmanagedetailreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ItemName" VARCHAR,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "Quantity" INT,
    "Remark" VARCHAR,
    "InOut" VARCHAR,
    "SalePrice" DECIMAL,
    "Price" DECIMAL,
    "TotalAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: sp_phrmreport_stockmanagedetailreport
    createdby/date:salakha/18/09/2018
    description: .
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       salakha/18/09/2018	                     created the script
    2.      vikas/2019-01-02						 modify sp for stock management remark.
    3.		rusha/2019-03-05						 add saleprice,price and total amt of stock
    4.		naveed/2019-12-13						 updated script for exclude zero quantity items
    5.		rusha/ 2020-07-24						old script used to show dispensary and store item manage but now only from store
    												item can be manage, so now report will show only list of those items manage in store only 
    6.     sanjesh/2021-05-11                       order by storestockid for stock management data
    7.     rohit/13feb'23						    MRP-> SalePrice
    */
    BEGIN
    	IF (
    			(p_fromdate IS NOT NULL)
    			AND (p_todate IS NOT NULL)
    			)
    	THEN
    		RETURN QUERY SELECT (stkMng.CreatedOn)::DATE AS "Date"
    			,itm.ItemName
    			,stkMng.BatchNo
    			,stkMng.ExpiryDate
    			,stkMng.Quantity
    			,stkMng.Remark
    			,CASE 
    				WHEN stkMng.InOut = 'in'
    					THEN 'stock added'
    				ELSE 'stock deducted'
    				END AS "InOut"
    			,stkMng.SalePrice
    			,stkMng.Price
    			,Round(stkMng.SalePrice * stkMng.Quantity, 2, 0) AS "TotalAmount"
    		FROM PHRM_StoreStock stkMng
    		INNER JOIN PHRM_MST_Item itm ON itm.ItemId = stkMng.ItemId
    		WHERE (stkMng.CreatedOn)::TIMESTAMP BETWEEN COALESCE(p_fromdate, CURRENT_TIMESTAMP)
    				AND COALESCE(p_todate, CURRENT_TIMESTAMP) + 1
    			AND stkMng.Quantity > 0
    			AND stkMng.TransactionType = 'stockmanage'
    		order by stkmng.storestockid desc;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;