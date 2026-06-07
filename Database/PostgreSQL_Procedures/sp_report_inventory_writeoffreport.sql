CREATE OR REPLACE FUNCTION sp_report_inventory_writeoffreport(
    p_itemid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    change history
    s.no.	updatedby/date			remarks
    1.		rusha/ 05-29-2019					created script for writeoff report
    */
    begin
    		if(p_itemid > 0)
    			then
    				open ref1 for select witm.writeoffdate,itm.itemname, witm.batchno, witm.writeoffquantity,witm.itemrate,witm.totalamount, 			
    				unit.uomname,itm.code,
    				concat_ws(' ',emp.firstname,emp.middlename,emp.lastname) as requestedby,witm.remark 
    				from inv_txn_writeoffitems as witm
    				join inv_mst_item as itm on itm.itemid = witm.itemid
    				join emp_employee as emp on emp.employeeid = witm.createdby
    				left join inv_mst_unitofmeasurement unit on itm.unitofmeasurementid = unit.uomid
    				where witm.itemid = p_itemid;
        return next ref1;
    			
            else 
    		    
    				open ref2 for select witm.writeoffdate,itm.itemname, witm.batchno, witm.writeoffquantity,witm.itemrate,witm.totalamount, 
    				unit.uomname,itm.code,
    				concat_ws(' ',emp.firstname,emp.middlename,emp.lastname) as requestedby,witm.remark 
    				from inv_txn_writeoffitems as witm
    				join inv_mst_item as itm on itm.itemid = witm.itemid
    				join emp_employee as emp on emp.employeeid = witm.createdby
    				left join inv_mst_unitofmeasurement unit on itm.unitofmeasurementid = unit.uomid;
        return next ref2;
    			end if; 
    end;
END;
$$ LANGUAGE plpgsql;