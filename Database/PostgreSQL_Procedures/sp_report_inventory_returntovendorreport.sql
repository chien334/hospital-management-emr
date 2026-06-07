CREATE OR REPLACE FUNCTION sp_report_inventory_returntovendorreport(
    p_vendorid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    change history
    s.no.	updatedby/date			remarks
    1.		rusha/ 05-29-2019					created script for return to vendor report
    */
    
    begin
    		if(p_vendorid > 0)
    			then
    				open ref1 for select rtn.createdon,ven.vendorname,rtn.creditnoteno,itm.itemname, rtn.quantity,rtn.itemrate,rtn.totalamount,
    				rtn.remark,concat_ws(' ',emp.firstname,emp.middlename,emp.lastname) as returnedby,
    				unit.uomname,itm.code
    				from inv_txn_returntovendoritems as rtn
    				join inv_mst_vendor as ven on ven.vendorid = rtn.vendorid
    				join emp_employee as emp on emp.employeeid = rtn.createdby
    				join inv_mst_item as itm on itm.itemid = rtn.itemid
    				left join inv_mst_unitofmeasurement unit on itm.unitofmeasurementid = unit.uomid
    				where rtn.vendorid = p_vendorid;
        return next ref1;
    			
            else 
    		    
    				open ref2 for select rtn.createdon,ven.vendorname,rtn.creditnoteno,itm.itemname, rtn.quantity,rtn.itemrate,rtn.totalamount,
    				rtn.remark,concat_ws(' ',emp.firstname,emp.middlename,emp.lastname) as returnedby,
    				unit.uomname,itm.code
    				from inv_txn_returntovendoritems as rtn
    				join inv_mst_vendor as ven on ven.vendorid = rtn.vendorid
    				join emp_employee as emp on emp.employeeid = rtn.createdby
    				join inv_mst_item as itm on itm.itemid = rtn.itemid
    				left join inv_mst_unitofmeasurement unit on itm.unitofmeasurementid = unit.uomid;
        return next ref2;
    			end if; 
    end;
END;
$$ LANGUAGE plpgsql;