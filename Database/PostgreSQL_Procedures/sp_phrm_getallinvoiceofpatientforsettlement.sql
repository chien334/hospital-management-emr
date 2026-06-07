CREATE OR REPLACE FUNCTION sp_phrm_getallinvoiceofpatientforsettlement(
    p_patientid INT DEFAULT 0,
    p_organizationid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
BEGIN
    /*
    filename: sp_phrm_getallinvoiceofpatientforsettlement
    description: to get all the invoices of patiend for settlement by patientid
    remarks: we're returning 4 tables from this StoredProc.
    1. patient info
    2. Credit Invoices and there Return Information
    3. Deposit Information
    4. Provisional Information
    
    Change History
    S.No. 	UpdatedBy/Date 				Remarks
    1. 		Rohit/1,DEC'21 				created sp to get the settlement details for settlement receipt.
    2.      dev narayan 7,june'22       Added Credit Organization Filter.
    3.		Rohit/10May'23				pharmacy deposit table references changes to billing deposit
    */
      
    	open ref1 for select
    		patientid,
    		patientcode,
    		shortname as patientname,
    		firstname,
    		middlename,
    		lastname,
    		gender,
    		dateofbirth,
    		address,
    		phonenumber
    	from pat_patient
    	where patientid=p_patientid;
        return next ref1;
    
    	open ref2 for select 
    		patientid, inv.invoiceid,
    		inv.invoiceprintid as invoiceno,
    		(inv.createon)::date as "invoicedate",
    		coalesce(inv.totalamount,0) as "salesamount", coalesce(ret.returnamount,0) as "returnamount",
    		coalesce(inv.totalamount,0) - coalesce(ret.returnamount,0) as "netamount",
    		phrmreturnidscsv
    
    	from phrm_txn_invoice inv
    	left join (select invoiceid, sum(totalamount) as "returnamount",
    	string_agg(invoicereturnid, ',') as "phrmreturnidscsv"
    	from phrm_txn_invoicereturn
    	where patientid=p_patientid
    	group by invoiceid) ret
    	on inv.invoiceid=ret.invoiceid
    	where
    		inv.patientid=p_patientid and
    	    inv.organizationid = p_organizationid
    		and
    		inv.paymentmode='credit' and inv.bilstatus != 'paid';
        return next ref2;
    
    open ref3 for select 
    coalesce(sum(coalesce(deposit_in,0)),0) as "deposit_in",
    coalesce(sum(coalesce(deposit_out,0)),0) as "deposit_out",
    coalesce(sum(coalesce(deposit_in,0)),0)-coalesce(sum(coalesce(deposit_out,0)),0) as "deposit_balance"
    from
    (
    select patientid, transactiontype,
    case when transactiontype='Deposit' then inamount
    else 0 end as "deposit_in",
    case when transactiontype in('ReturnDeposit','depositdeduct') then outamount
    else 0 end as "deposit_out"
    from bil_txn_deposit
    where patientid=p_patientid
    ) a;
        return next ref3;
    
    open ref4 for select patientid,
    sum(coalesce(totalamount,0)) as "provisionaltotal"
    from phrm_txn_invoiceitems
    where bilitemstatus='provisional'
    and patientid = p_patientid
    group by patientid;
        return next ref4;
END;
$$ LANGUAGE plpgsql;