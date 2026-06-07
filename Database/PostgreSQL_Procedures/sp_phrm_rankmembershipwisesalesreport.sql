CREATE OR REPLACE FUNCTION sp_phrm_rankmembershipwisesalesreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_ranks VARCHAR DEFAULT NULL,
    p_memberships VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "InvoiceDate" TIMESTAMP,
    "InvoiceNo" VARCHAR,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL,
    "PaymentMode" VARCHAR,
    "Rank" VARCHAR,
    "PatientName" VARCHAR,
    "HospitalNo" VARCHAR,
    "MembershipTypeName" VARCHAR,
    "Store" VARCHAR,
    "User" VARCHAR
) AS $$
BEGIN
    /*
    "sp_phrm_rankmembershipwisesalesreport" '2023-1-12'
    filename: "sp_phrm_rankmembershipwisesalesreport"
    createdby/date:nirmala/2023-1-12
    description: .
    remarks:    a
    change history
    s.no.    updatedby/date                        remarks
    1       nirmala/2023-1-12                created the script for rank-membership-wise-sales report
    */
    
    	RETURN QUERY SELECT invoice.createon AS "InvoiceDate"
    		,invoice.invoiceprintid AS "InvoiceNo"
    		,sum(invoice.subtotal) AS "SubTotal"
    		,sum(invoice.discountamount) AS "DiscountAmount"
    		,sum(invoice.totalamount) AS "TotalAmount"
    		,invoice.paymentmode
    		,coalesce(pat.rank, '') AS "Rank"
    		,pat.shortname AS "PatientName"
    		,pat.patientcode AS "HospitalNo"
    		,mem.membershiptypename
    		,store.name AS "Store"
    		,emp.fullname AS "User"
    	from phrm_txn_invoice invoice
    	inner join pat_patient pat on pat.patientid = invoice.patientid
    	inner join pat_cfg_membershiptype mem on pat.membershiptypeid = mem.membershiptypeid
    	inner join phrm_mst_store store on store.storeid = invoice.storeid
    	inner join emp_employee emp on invoice.createdby = emp.employeeid
    	where pat.rank is not null
    		and (invoice.createon)::date between (p_fromdate)::date
    			and (p_todate)::date
    		and (
    			pat.rank in (
    				select value
    				from string_split(p_ranks, ',')
    				)
    			or p_ranks = ''
    			)
    		and (
    			mem.membershiptypeid in (
    				select value
    				from string_split(p_memberships, ',')
    				)
    			or p_memberships = ''
    			)
    	group by invoice.patientid
    		,invoice.createon
    		,invoice.invoiceprintid
    		,pat.rank
    		,pat.shortname
    		,pat.patientcode
    		,invoice.paymentmode
    		,mem.membershiptypename
    		,store.name
    		,emp.fullname;
END;
$$ LANGUAGE plpgsql;