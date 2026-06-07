CREATE OR REPLACE FUNCTION sp_report_inventory_cancelpurchaseorderreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "PurchaseOrderId" INT,
    "PoDate" TIMESTAMP,
    "VendorName" VARCHAR,
    "TotalAmount" DECIMAL,
    "CancelledOn" TIMESTAMP,
    "CancelledBy" VARCHAR,
    "CancelRemarks" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_report_inventory_cancelpurchaseorderreport" '2022-09-07','2022-09-07'
    createdby/date: shankar/2019-09-26
    description: report for cancelled po in inventory
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		nageshbb/13 sep 2020			column list updated for cancel po
    2.		rusha/07th sep 2022				reflect employee name in cancelledby and formatted date
    */
    begin
    --po id, po-date, vendorname, totalamount, cancelleddate, cancelledby, cancelremarks
    		if(p_fromdate is not null or p_todate is not null or len(p_fromdate)>=0 or len(p_todate)>=0)
    				then
    					RETURN QUERY SELECT  
    					po.purchaseorderid,
    					po.podate AS "PoDate",							
    					v.vendorname,							
    					po.totalamount,
    					po.cancelledon,
    					empcancel.fullname AS "CancelledBy",
    					po.cancelremarks
    					from    inv_txn_purchaseorder po
    					inner join inv_mst_vendor v on v.vendorid = po.vendorid	
    					inner join emp_employee empcancel on empcancel.employeeid = po.cancelledby
    				    where 
    					(po.cancelledon)::date between coalesce(p_fromdate,current_timestamp) and coalesce(p_todate,current_timestamp)
    			     	and po.iscancel = 1;							
    				end if;
    end;
END;
$$ LANGUAGE plpgsql;