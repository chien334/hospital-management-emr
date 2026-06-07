CREATE OR REPLACE FUNCTION sp_wardinv_report_requisitiondispatchreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "RequisitionDate" TIMESTAMP,
    "DispatchDate" TIMESTAMP,
    "ItemName" VARCHAR,
    "SubCategoryName" VARCHAR,
    "SubCategoryId" INT,
    "RequestQty" INT,
    "ReceivedQuantity" INT,
    "PendingQuantity" INT,
    "DispatchedQuantity" INT,
    "Remark" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardinv_report_requisitiondispatchreport"
    createdby/date: rusha/06-04-2019
    description: to get stock details of requisition and dispatch from ward to inventory
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.
    2.		rohit/10oct'22							StoreId change to RequestFromStoreId and Join condition Fixed
    3.		Rohit/31Oct'22							requisitiondate and dispatcheddate fetched instead of createdon
    4.		rohit/6dec'22							subcategoryname and subcategory fetched to add frontend filter
    */
    
    	RETURN QUERY SELECT (req.requisitiondate)::date AS "RequisitionDate"
    		,(disitm.dispatcheddate)::date AS "DispatchDate"
    		,itm.itemname
    		,sc.subcategoryname
    		,sc.subcategoryid
    		,reqitm.quantity AS "RequestQty"
    		,reqitm.receivedquantity
    		,reqitm.pendingquantity
    		,disitm.dispatchedquantity
    		,reqitm.remark
    	from inv_txn_requisitionitems as reqitm
    	join inv_txn_requisition as req on req.requisitionid = reqitm.requisitionid
    	left join inv_txn_dispatchitems as disitm on disitm.requisitionitemid = reqitm.requisitionitemid
    	join inv_mst_item as itm on itm.itemid = reqitm.itemid
    	inner join inv_mst_itemsubcategory sc on itm.subcategoryid = sc.subcategoryid
    	where req.requestfromstoreid = p_storeid
    		and (req.requisitiondate)::date between p_fromdate
    			and p_todate;
END;
$$ LANGUAGE plpgsql;