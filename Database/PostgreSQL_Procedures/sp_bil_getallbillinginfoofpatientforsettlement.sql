CREATE OR REPLACE FUNCTION sp_bil_getallbillinginfoofpatientforsettlement(
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
    filename: "sp_bil_getallbillinginfoofpatientforsettlement"
    createdby/date: krishna/2021-11-17
    description: to get the billing information of patient for settlement like (credit,deposit,provisional.....)
    change history
    s.no.    updatedby/date                        remarks
    1.		krishna/2021-11-17					created sp to get the billing information for settlement.
    2.		krishna/2022-02-03					added credit organization parameter to get organization wise data..
    3.		krishna/2023-04-21					change deposittype to transactiontype
    4.		krishna/2023-04-24					add pharmacycredit invoices in this list
    */
    
    
    	open ref1 for select
    		patientid,
    		patientcode as hospitalno,
    		shortname as patientname,
    		gender,
    		dateofbirth
    
    	from pat_patient
    	where patientid=p_patientid;
        return next ref1;
    
    
    	open ref2 for select 
    		patientid, 
    		inv.billingtransactionid as "transactionid",
    		inv.invoiceno,
    		inv.invoicecode,
    		(inv.createdon)::date as "invoicedate",
    		coalesce(inv.totalamount,0) as "salesamount", coalesce(ret.returnamount,0) as "returnamount",
    		coalesce(inv.totalamount,0) - coalesce(ret.returnamount,0) as "netamount",
    		billreturnidscsv,
    		'Billing' as "invoiceof"
    
    	from 
    		bil_txn_billingtransaction inv  
    	left join 
    		(select billingtransactionid, 
    		sum(totalamount) as "returnamount",
    		string_agg(billreturnid, ',') as "billreturnidscsv"
    	from 
    		bil_txn_invoicereturn 
    	where patientid=p_patientid
    	group by 
    		billingtransactionid) ret on inv.billingtransactionid=ret.billingtransactionid
    	where
    		inv.organizationid = p_organizationid and
    		inv.patientid=p_patientid and
    		inv.paymentmode='credit' and inv.billstatus != 'paid' 
    		and coalesce(inv.isinsurancebilling,0) = 0 --excluding insurances invoices.
    	
    	union all
    
    	select 
    		patientid, 
    		inv.invoiceid as "transactionid",
    		inv.invoiceprintid as "invoiceno",
    		'PH' as "invoicecode",
    		(inv.createon)::date as "invoicedate",
    		coalesce(inv.totalamount,0) as "salesamount", coalesce(ret.returnamount,0) as "returnamount",
    		coalesce(inv.totalamount,0) - coalesce(ret.returnamount,0) as "netamount",
    		billreturnidscsv,
    		'Pharmacy' as "invoiceof"
    
    	from 
    		phrm_txn_invoice inv 
    	left join 
    		(select invoiceid, 
    		sum(totalamount) as "returnamount",
    		string_agg(invoicereturnid, ',') as "billreturnidscsv"
    	from 
    		phrm_txn_invoicereturn
    	where patientid=p_patientid
    	group by 
    		invoiceid) ret on inv.invoiceid=ret.invoiceid
    	where
    		inv.organizationid = p_organizationid and
    		inv.patientid=p_patientid and
    		inv.paymentmode='credit' and inv.bilstatus != 'paid';
        return next ref2; 
    
    	open ref3 for select 
    		sum(coalesce(deposit_in,0)) as "deposit_in",
    		sum(coalesce(deposit_out,0)) as "deposit_out",
    		sum(coalesce(deposit_in,0))-sum(coalesce(deposit_out,0)) as "deposit_balance"
    	from
    	(
    		select patientid, transactiontype,
    		case when transactiontype='Deposit' then inamount
    		else 0 end as "deposit_in",
    		case when transactiontype in ('ReturnDeposit','depositdeduct') then outamount
    		else 0 end as "deposit_out"
    		from bil_txn_deposit
    		where patientid=p_patientid and organizationorpatient = 'patient'
    	) a;
        return next ref3;
    
    	open ref4 for select 
    		patientid,
    		sum(coalesce(totalamount,0)) as "provisionaltotal"
    	from 
    		bil_txn_billingtransactionitems 
    	where lower(billstatus)='provisional'
    		and coalesce(isinsurance,0)=0
    		and lower(billingtype) != 'inpatient'
    		and patientid = p_patientid
    	group by patientid;
        return next ref4;
END;
$$ LANGUAGE plpgsql;