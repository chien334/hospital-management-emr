CREATE OR REPLACE FUNCTION sp_inventory_issueditemlistreport(
    p_fromdate DATE,
    p_todate DATE,
    p_fiscalyearid INT DEFAULT NULL,
    p_itemid INT DEFAULT NULL,
    p_substoreid INT DEFAULT NULL,
    p_mainstoreid INT DEFAULT NULL,
    p_employeeid INT DEFAULT NULL,
    p_subcategoryid INT DEFAULT NULL
)
RETURNS TABLE (
    "DispatchNo" VARCHAR,
    "SubStoreName" VARCHAR,
    "SubCategoryName" VARCHAR,
    "ItemName" VARCHAR,
    "Unit" VARCHAR,
    "Quantity" INT,
    "IssuedDate" TIMESTAMP,
    "EmployeeName" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_inventory_issueditemlistreport"  '2022-04-1','2022-04-7',5,null,null,7,null
    createdby/date: rohit/7thapr'22
    Description: To get the Dispatch Item Detail Report from MainStore to Substore
    Remarks:    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.		Rohit/7thApr'22					created iniitial script
    2.		rohit/19aug'22					Fetched SubCategoryName
    3.		Rohit/8Sept'23					fetched dispatchno as referenceno (previously dispatchitemid is fetched as referenceno)
    */
    
    	RETURN QUERY SELECT di.dispatchno AS "DispatchNo"
    		,s.name AS "SubStoreName"
    		,itmsubcat.subcategoryname
    		,itm.itemname
    		,uom.uomname AS "Unit"
    		,di.dispatchedquantity AS "Quantity"
    		,(di.dispatcheddate)::date AS "IssuedDate"
    		,emp.fullname AS "EmployeeName"
    	from inv_txn_dispatchitems di
    	join inv_mst_item itm on di.itemid = itm.itemid
    	join inv_mst_itemsubcategory itmsubcat on itm.subcategoryid = itmsubcat.subcategoryid
    	join inv_mst_unitofmeasurement uom on itm.unitofmeasurementid = uom.uomid
    	join phrm_mst_store s on di.targetstoreid = s.storeid
    	join emp_employee emp on di.createdby = emp.employeeid
    	where (
    			di.itemid = p_itemid
    			or p_itemid is null
    			)
    		and (
    			di.createdby = p_employeeid
    			or p_employeeid is null
    			)
    		and (
    			di.targetstoreid = p_substoreid
    			or p_substoreid is null
    			)
    		and (
    			itmsubcat.subcategoryid = p_subcategoryid
    			or p_subcategoryid is null
    			)
    		and (di.dispatcheddate)::date between (p_fromdate)::date
    			and (p_todate)::date
    		and di.fiscalyearid = p_fiscalyearid
    		and di.sourcestoreid = p_mainstoreid
    	order by di.dispatchitemsid desc;
END;
$$ LANGUAGE plpgsql;