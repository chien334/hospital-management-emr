CREATE OR REPLACE FUNCTION sp_phrmreport_drugcategorywisereport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_category VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "CategoryName" VARCHAR,
    "ItemName" VARCHAR,
    "PatientName" VARCHAR,
    "BatchNo" VARCHAR,
    "Quantity" INT,
    "Price" DECIMAL,
    "TotalAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_drugcategorywisereport"
    createdby/date: rusha/2019-05-12
    description: .
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1        rusha/2019-05-12                     created of the script for displaying report according to drug category
    2.		 naveed/2019-12-13				      updated script for exclude zero quantity items from report
    */
    
    begin
      if ((p_fromdate is not null) and (p_todate is not null) and (p_category is not null))
    	then
    		RETURN QUERY SELECT (invitm.createdon)::date AS "Date",cat.categoryname,invitm.itemname, concat_ws(' ',pat.firstname,pat.middlename,pat.lastname) AS "PatientName",
    		--concat_ws(' ',emp.firstname,emp.middlename,emp.lastname) as providername,		
    		invitm.batchno,invitm.quantity,invitm.price,invitm.totalamount 
    		from phrm_txn_invoiceitems as invitm
    		join phrm_txn_invoice as inv on inv.patientid = invitm.patientid
    		--join emp_employee as emp on inv.providerid = emp.employeeid
    		join phrm_mst_item as itm on invitm.itemid = itm.itemid
    		join phrm_mst_generic as gen on itm.genericid = gen.genericid
    		join phrm_mst_category as cat on gen.categoryid = cat.categoryid
    		join pat_patient as pat on invitm.patientid = pat.patientid
    		where (invitm.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1 and cat.categoryname = p_category and invitm.quantity>0;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;