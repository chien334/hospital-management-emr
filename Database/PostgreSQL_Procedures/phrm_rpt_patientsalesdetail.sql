CREATE OR REPLACE FUNCTION phrm_rpt_patientsalesdetail(
    p_fromdate TIMESTAMP DEFAULT '2021-01-01',
    p_todate TIMESTAMP DEFAULT '2022-01-01',
    p_counterid INT DEFAULT NULL,
    p_userid INT DEFAULT NULL,
    p_storeid INT DEFAULT NULL,
    p_patientid INT DEFAULT NULL
)
RETURNS TABLE (
    "X.*" VARCHAR
) AS $$
BEGIN
    -- =============================================
    -- author:		sanjit
    -- create date: 17jun'21
    -- Description: generated patientwise sales report
    -- =============================================
    /* Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.       sanjit/17Jun'21          			cretated script
    2.		 rohit/25jul'22						Date is Converted
    3        Rohit/13Feb'23						mrp-> saleprice
    */
    
    	-- body of the stored procedure
    	RETURN QUERY SELECT x.*
    	from (
    		select 'Sale' as type
    			,i.createon as "date"
    			,i.invoiceid
    			,i.invoiceprintid
    			,pat.patientcode as "hospitalno"
    			,pat.firstname || ' ' || coalesce(pat.middlename || ' ', '') || pat.lastname as "patientname"
    			,pat.shortname
    			,gen.genericname
    			,itm.itemcode
    			,itm.itemname
    			,ii.batchno
    			,ii.expirydate
    			,ii.price
    			,ii.saleprice
    			,ii.quantity
    			,pat.ins_nshinumber
    			,i.claimcode
    			,ii.subtotal
    			,ii.totalamount
    			,e.fullname as "createdbyname"
    			,c.countername
    		from phrm_txn_invoiceitems ii
    		join phrm_mst_item itm on ii.itemid = itm.itemid
    		join phrm_mst_generic gen on itm.genericid = gen.genericid
    		join phrm_txn_invoice i on ii.invoiceid = i.invoiceid
    		join pat_patient pat on i.patientid = pat.patientid
    		join emp_employee e on i.createdby = e.employeeid
    		join phrm_mst_counter c on i.counterid = c.counterid
    		where (i.createon)::date between p_fromdate
    				and p_todate
    			and (
    				i.patientid = p_patientid
    				or p_patientid is null
    				)
    			and (
    				i.counterid = p_counterid
    				or p_counterid is null
    				)
    			and (
    				i.createdby = p_userid
    				or p_userid is null
    				)
    			and (
    				i.storeid = p_storeid
    				or p_storeid is null
    				)
    		
    		union all
    		
    		select 'Sales Refund' as type
    			,i.createdon as "date"
    			,i.invoiceid
    			,i.creditnoteid
    			,pat.patientcode as "hospitalno"
    			,pat.firstname || ' ' || coalesce(pat.middlename || ' ', '') || pat.lastname as "patientname"
    			,pat.shortname
    			,gen.genericname
    			,itm.itemcode
    			,itm.itemname
    			,ii.batchno
    			,iitm.expirydate
    			,ii.price
    			,ii.saleprice
    			,ii.returnedqty as quantity
    			,pat.ins_nshinumber
    			,i.claimcode
    			,ii.subtotal
    			,ii.totalamount
    			,e.fullname as "createdbyname"
    			,c.countername
    		from phrm_txn_invoicereturnitems ii
    		join phrm_mst_item itm on ii.itemid = itm.itemid
    		join phrm_mst_generic gen on itm.genericid = gen.genericid
    		join phrm_txn_invoicereturn i on ii.invoicereturnid = i.invoicereturnid
    		join phrm_txn_invoiceitems iitm on ii.invoiceitemid = iitm.invoiceitemid
    		join pat_patient pat on i.patientid = pat.patientid
    		join emp_employee e on i.createdby = e.employeeid
    		join phrm_mst_counter c on i.counterid = c.counterid
    		where (i.createdon)::date between p_fromdate
    				and p_todate
    			and (
    				i.patientid = p_patientid
    				or p_patientid is null
    				)
    			and (
    				i.counterid = p_counterid
    				or p_counterid is null
    				)
    			and (
    				i.createdby = p_userid
    				or p_userid is null
    				)
    			and (
    				i.storeid = p_storeid
    				or p_storeid is null
    				)
    		) x
    	order by x."date";
END;
$$ LANGUAGE plpgsql;