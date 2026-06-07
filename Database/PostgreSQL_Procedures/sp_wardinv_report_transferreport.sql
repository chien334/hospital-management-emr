CREATE OR REPLACE FUNCTION sp_wardinv_report_transferreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "DepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "Quantity" INT,
    "Remarks" VARCHAR,
    "CreatedBy" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardinv_report_transferreport"
    createdby/date: rusha/06-05-2019
    description: to get the details of stock transfer from ward to inventory 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    
    */
    
    begin
      if ((p_fromdate is not null) and (p_todate is not null))
    		then
    			RETURN QUERY SELECT (trans.createdon)::date AS "Date",dep.departmentname,itm.itemname,trans.quantity,trans.remarks, trans.createdby 
    			from ward_inv_transaction as trans
    			join ward_inv_stock as stk on stk.stockid = trans.stockid
    			join mst_department as dep on dep.departmentid = stk.departmentid
    			join inv_mst_item as itm on itm.itemid = stk.itemid		
    			where stk.storeid = p_storeid and (trans.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1;
    		end if;	
    end;
END;
$$ LANGUAGE plpgsql;