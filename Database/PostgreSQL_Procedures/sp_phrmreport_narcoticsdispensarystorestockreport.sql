CREATE OR REPLACE FUNCTION sp_phrmreport_narcoticsdispensarystorestockreport(
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "ItemName" VARCHAR,
    "GenericName" VARCHAR,
    "BatchNo" VARCHAR,
    "ExpiryDate" TIMESTAMP,
    "CostPrice" DECIMAL,
    "SalePrice" DECIMAL,
    "StockQty" INT,
    "Name" VARCHAR,
    "StoreId" INT
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_narcoticsdispensarystorestockreport"
    createdby/date: ashish/12-02-2020
    description: to get the stock value of both dispensary and store wise for narcotics stock report
    change history
    s.no.    updatedby/date                        remarks
    1      sanjit/ramesh/25jul21        updated after stock refactoring 
    2      rohit/6thapr22				added storeid to fetch storeid
    3      rusha/21thjuly22				added generic name in column
    4      rohit/13feb'23				MRP-> SalePrice
    */
    
    	RETURN QUERY SELECT I.ItemName
    		,G.GenericName
    		,COALESCE(S.BatchNo, '') AS "BatchNo"
    		,s.expirydate
    		,coalesce(s.costprice, 0) AS "CostPrice"
    		,coalesce(s.saleprice, 0) AS "SalePrice"
    		,sum(coalesce(ss.availablequantity, 0)) AS "StockQty"
    		,str.name
    		,str.storeid
    	from phrm_mst_item i
    	left join phrm_mst_generic g on i.genericid = g.genericid
    	left join phrm_mst_stock s on i.itemid = s.itemid
    	left join phrm_txn_storestock ss on s.stockid = ss.stockid
    	left join phrm_mst_store str on ss.storeid = str.storeid
    	where s.isactive = 1
    		and ss.isactive = 1
    		and (
    			str.storeid = p_storeid
    			or p_storeid is null
    			)
    		and i.isnarcotic = 1
    	group by s.itemid
    		,g.genericname
    		,i.itemname
    		,s.batchno
    		,s.expirydate
    		,s.costprice
    		,s.saleprice
    		,s.stockid
    		,str.name
    		,str.storeid
    	order by sum(coalesce(ss.availablequantity, 0)) desc;
END;
$$ LANGUAGE plpgsql;