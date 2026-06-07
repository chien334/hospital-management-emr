CREATE OR REPLACE FUNCTION phrm_narcoticsdailysalesreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_itemid INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "InvoicePrintId" INT,
    "InvoiceId" INT,
    "ItemId" INT,
    "ItemName" VARCHAR,
    "GenericName" VARCHAR,
    "BatchNo" VARCHAR,
    "Quantity" INT,
    "SalePrice" DECIMAL,
    "Price" DECIMAL,
    "TotalAmount" DECIMAL,
    "CreatedOn" TIMESTAMP,
    "PatientName" VARCHAR,
    "DoctorName" VARCHAR,
    "NMCNumber" VARCHAR
) AS $$
BEGIN
    /*
    filename: "phrm_narcoticsdailysalesreport"
    createdby/date: rohit/1feb'22
    Description: To get the narcotics daily sales information 
    Remarks:    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       Rohit/1Feb'22                        created the script
    2       rohit/28apr'22                       Do not show Return Narcotics sale(updated)
    3       Rusha/21thJuly22				     Added Generic name in column
    4.		Rohit/13Feb'23						mrp-> saleprice
    */
    
    	RETURN QUERY SELECT invoiceprintid
    		,invoiceid
    		,itemid
    		,itemname
    		,genericname
    		,batchno
    		,quantity
    		,saleprice
    		,price
    		,totalamount
    		,createdon
    		,patientname
    		,doctorname
    		,nmcnumber
    	from (
    		select inv.invoiceprintid
    			,inv.invoiceid
    			,mstitm.itemid
    			,mstitm.itemname
    			,gen.genericname
    			,invitm.batchno
    			,invitm.quantity - coalesce(retitm.returnedqty, 0) AS "Quantity"
    			,invitm.saleprice
    			,invitm.price
    			,invitm.totalamount - coalesce(retitm.returntotal, 0) AS "TotalAmount"
    			,inv.createon AS "CreatedOn"
    			,pet.firstname || ' ' || coalesce(pet.middlename, '') || ' ' || pet.lastname AS "PatientName"
    			,e.fullname AS "DoctorName"
    			,e.medcertificationno AS "NMCNumber"
    		from phrm_txn_invoiceitems invitm
    		left join (
    			select invretitm.invoiceitemid
    				,sum(coalesce(invretitm.returnedqty, 0)) as "returnedqty"
    				,sum(coalesce(invretitm.totalamount, 0)) as "returntotal"
    			from phrm_txn_invoicereturnitems invretitm
    			group by invretitm.invoiceitemid
    			) retitm on invitm.invoiceitemid = retitm.invoiceitemid
    		inner join phrm_txn_invoice inv on invitm.invoiceid = inv.invoiceid
    		inner join phrm_mst_item mstitm on invitm.itemid = mstitm.itemid
    		left join phrm_mst_generic gen on mstitm.genericid = gen.genericid
    		inner join pat_patient pet on inv.patientid = pet.patientid
    		inner join emp_employee emp on inv.createdby = emp.employeeid
    		left join emp_employee e on inv.prescriberid = e.employeeid
    		where mstitm.isnarcotic = 1
    			and (
    				(inv.createon)::date between p_fromdate
    					and p_todate
    				)
    			and (
    				invitm.itemid = p_itemid
    				or p_itemid is null
    				)
    			and (
    				inv.storeid = p_storeid
    				or p_storeid is null
    				)
    		) tbl
    	where quantity > 0
    	order by invoiceid desc;
END;
$$ LANGUAGE plpgsql;