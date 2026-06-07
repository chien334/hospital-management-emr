CREATE OR REPLACE FUNCTION sp_bil_getpatientpastbills(
    p_patientid INT DEFAULT NULL,
    p_maxpastdays INT DEFAULT NULL
)
RETURNS TABLE (
    "CreatedOn" TIMESTAMP,
    "InvoiceNumber" VARCHAR,
    "ItemId" INT,
    "ServiceDepartmentId" INT,
    "ServiceDepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "TotalAmount" DECIMAL,
    "BillStatus" VARCHAR,
    "UserFirstName" VARCHAR,
    "User" VARCHAR,
    "ServiceItemId" INT
) AS $$
BEGIN
    /*
    filename: exec sp_bil_getpatientpastbills
    createdby/date: sud/anish/2019-06-19
    description: get patient's Billing Items of Last N days, Exclude Cancelled Items. 
    Used in Billing Transaction page (for Checkbox)
    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.      Sud/Anish/19June'19                     created.
    2.      pratik/sud: 17 april'20                  Added ItemId and ServiceDepartmentId in select, 
                                                   excluded returned items, correction in username(now taking from emp.FullName 
    3.      Dev Narayan /1 Oct'21                   alter procedure so that it will not show the returned bills.
    4.		bibek/krishna,14thmay'23				Add ServiceItemId in a select query
    */
    BEGIN
    
    IF( p_maxpastdays IS NULL)
       THEN p_maxpastdays := 7; END IF;  -- we're taking past 7 days entry for now..
    
      RETURN QUERY SELECT 
    	itm.createdon,
    	txn.invoicecode || (txn.invoiceno)::varchar AS "InvoiceNumber",
    	itm.itemid,
    	itm.servicedepartmentid,
        itm.servicedepartmentname,
    	itm.itemname,
    	itm.totalamount,
    	itm.billstatus,
    	emp.firstname AS "UserFirstName",
    	emp.fullname AS "User",
    	itm.serviceitemid
      from bil_txn_billingtransactionitems itm 
    	left join bil_txn_billingtransaction txn
        on itm.billingtransactionid=txn.billingtransactionid
        join emp_employee emp 
        on itm.createdby=emp.employeeid
       where  itm.patientid=p_patientid
    	and itm.billstatus !='cancel'
    	and itm.quantity!=coalesce((select sum(retquantity) from bil_txn_invoicereturnitems where billingtransactionitemid = itm.billingtransactionitemid),0)
    	 and  datediff(day,itm.createdon,current_timestamp)  <= p_maxpastdays
      order by itm.createdon desc;
    end; -- end of sp
END;
$$ LANGUAGE plpgsql;