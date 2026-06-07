CREATE OR REPLACE FUNCTION sp_report_inventory_dailyitemsdispatchreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "CategoryName" VARCHAR,
    "SubCategory" VARCHAR,
    "ItemName" VARCHAR,
    "Unit" VARCHAR,
    "DispatchedQty" INT,
    "CostPrice" DECIMAL,
    "TotalDispatchedValue" DECIMAL,
    "Substore" VARCHAR,
    "DispatchedDate" TIMESTAMP
) AS $$
BEGIN
    /*
    filename: "sp_report_inventory_dailyitemsdispatchreport" 
    createdby/date: umed/2017-06-21
    description: to get details such as itemnames , total dispatch qty of particular item with total amount generated between given dates along with storename.
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2017-06-21                     created the script
    2       rusha/2019-06-06                    updated the script
    3       ramesh/2020-04-14                   updated the script
    4.		nirmala/rohit						group by with costprice
    */
    	
    		RETURN QUERY SELECT ic.itemcategoryname AS "CategoryName"
    			,isub.subcategoryname AS "SubCategory"
    			,i.itemname AS "ItemName"
    			,u.uomname AS "Unit"
    			,sum(coalesce(d.dispatchedquantity, 0)) AS "DispatchedQty"
    			,d.costprice
    			,sum(coalesce((d.dispatchedquantity * d.costprice), 0)) AS "TotalDispatchedValue"
    			,s.name AS "Substore" 
    			,(d.dispatcheddate)::date AS "DispatchedDate"
    		from inv_txn_dispatchitems d
    		inner join phrm_mst_store as s on d.targetstoreid = s.storeid
    		inner join inv_mst_item as i on i.itemid = d.itemid
    		inner join inv_mst_itemcategory as ic on i.itemcategoryid = ic.itemcategoryid
    		inner join inv_mst_itemsubcategory as isub on i.subcategoryid = isub.subcategoryid
    		left join inv_mst_unitofmeasurement u on i.unitofmeasurementid = u.uomid
    		where (d.dispatcheddate)::date between p_fromdate and p_todate
    			and (
    				d.targetstoreid = p_storeid
    				or p_storeid is null
    				)
    		group by ic.itemcategoryname
    			,isub.subcategoryname
    			,i.itemname
    			,u.uomname
    			,d.costprice
    			,s.name
    			,dispatcheddate
    		order by dispatcheddate desc;
END;
$$ LANGUAGE plpgsql;