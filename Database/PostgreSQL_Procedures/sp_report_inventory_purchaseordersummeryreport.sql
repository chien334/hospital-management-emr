CREATE OR REPLACE FUNCTION sp_report_inventory_purchaseordersummeryreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "PONumber" TIMESTAMP,
    "VendorName" VARCHAR,
    "ItemCode" VARCHAR,
    "ItemName" VARCHAR,
    "ItemType" VARCHAR,
    "SubCategory" VARCHAR,
    "Quantity" INT,
    "StandardRate" DECIMAL,
    "VAT" VARCHAR,
    "TotalAmount" DECIMAL,
    "Remarks" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_report_inventory_purchaseordersummeryreport"
    createdby/date: umed/2017-06-23
    description: to get details such as item name,total qty,received qty,pending qty, with expected due date of delivery between given date input
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2017-06-23	                   created the script
    2       shankar/2019-09-16                 edited script to add iscancel
    3.      dhanashri/2021-10-28               updated as per new requirement
    */
    begin
    
    	if(p_fromdate is not null or p_todate is not null)
    		then
    			RETURN QUERY SELECT 
    				(po.podate)::date AS "Date" ,
    				po.ponumber AS "PONumber",
    				ven.vendorname,
    				msitm.code AS "ItemCode",
    				msitm.itemname AS "ItemName",
    				ic.itemcategoryname AS "ItemType",
    				isc.subcategoryname AS "SubCategory",
    				poitm.quantity AS "Quantity", 
    				poitm.standardrate AS "StandardRate",
    				poitm.vatamount AS "VAT", 
    				poitm.totalamount AS "TotalAmount",
    				case
    					when len(ltrim(rtrim(coalesce(poitm.remark,'')))) > 0 then poitm.remark
    					else po.poremark
    				end AS "Remarks"
    			from 
    				inv_txn_purchaseorderitems poitm
    				inner join inv_txn_purchaseorder po on poitm.purchaseorderid =po.purchaseorderid
    				inner join inv_mst_vendor as ven on ven.vendorid = po.vendorid
    				inner join inv_mst_item msitm on msitm.itemid = poitm.itemid
    				left join inv_mst_itemsubcategory isc on isc.subcategoryid = msitm.subcategoryid
    				left join inv_mst_itemcategory ic on ic.itemcategoryid = msitm.itemcategoryid
    			where 
    				(po.podate)::date between p_fromdate and p_todate
    				and (po.storeid = p_storeid or p_storeid is null)
    				-- check for po active status 
    				and coalesce(po.iscancel, 0) = 0 and coalesce(poitm.isactive, 1) != 0 and poitm.poitemstatus != 'cancelled'
    			order by po.podate desc;
    		end if;
    end;
END;
$$ LANGUAGE plpgsql;